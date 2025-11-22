import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import '../models/case_model.dart';
import '../services/hive_database_service.dart';
import '../services/connectivity_service.dart';
import '../services/file_service.dart';

class CaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  final HiveDatabaseService _hiveService = HiveDatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final FileService _fileService = FileService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Initialize repository
  Future<void> initialize() async {
    await _hiveService.initialize();
    await _fileService.initialize();
    await _connectivityService.initialize();
  }

  // Hybrid data stream that merges offline and online data
  Stream<List<CaseModel>> getCasesStream() async* {
    if (currentUserId == null) {
      yield [];
      return;
    }

    // Step 1: Emit local Hive data immediately (instant display, works offline)
    final localCases = _hiveService.getAllCases();
    yield localCases;

    // Step 2: If internet is available, subscribe to Firestore changes
    if (_connectivityService.isConnected) {
      yield* _firestore
          .collection('cases')
          .where('ownerId', isEqualTo: currentUserId)
          .snapshots()
          .asyncMap((snapshot) async {
            final remoteCases = snapshot.docs
                .map((doc) => CaseModel.fromMap(doc.data()))
                .toList();

            // Step 3: Merge remote data with local Hive data
            await _mergeRemoteData(remoteCases);
            
            // Return merged data from Hive
            return _hiveService.getAllCases();
          });
    }
  }

  // Merge remote Firestore data with local Hive data
  Future<void> _mergeRemoteData(List<CaseModel> remoteCases) async {
    final localCases = _hiveService.getAllCases();
    final localCaseIds = localCases.map((c) => c.id).toSet();
    final remoteCaseIds = remoteCases.map((c) => c.id).toSet();

    // Update existing cases and add new ones
    for (final remoteCase in remoteCases) {
      final existingLocalCase = localCases.firstWhere(
        (localCase) => localCase.id == remoteCase.id,
        orElse: () => remoteCase,
      );

      if (existingLocalCase.id == remoteCase.id) {
        // Case exists locally - update if remote is newer
        if (remoteCase.updatedAt.isAfter(existingLocalCase.updatedAt)) {
          final updatedCase = remoteCase.copyWith(isSynced: true);
          await _hiveService.saveCase(updatedCase);
        }
      } else {
        // New case from remote - add to local storage
        final newCase = remoteCase.copyWith(isSynced: true);
        await _hiveService.saveCase(newCase);
      }
    }

    // Remove cases that no longer exist remotely (unless they're local-only)
    for (final localCase in localCases) {
      if (!remoteCaseIds.contains(localCase.id) && localCase.isSynced) {
        // Case was deleted remotely, remove from local storage
        await _hiveService.deleteCase(localCase.id);
      }
    }
  }

  // Create a new case (offline-first)
  Future<bool> createCase(CaseModel caseModel) async {
    try {
      // Always save locally first with isSynced = false
      final localCase = caseModel.copyWith(isSynced: false);
      await _hiveService.saveCase(localCase);
      
      // Try to sync immediately if online
      if (_connectivityService.isConnected) {
        await _syncCaseToFirebase(caseModel);
      }
      
      return true;
    } catch (e) {
      print('Error creating case: $e');
      return false;
    }
  }

  // Update an existing case
  Future<bool> updateCase(CaseModel caseModel) async {
    try {
      // Update locally first with isSynced = false
      final updatedCase = caseModel.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      await _hiveService.updateCase(updatedCase);
      
      // Try to sync immediately if online
      if (_connectivityService.isConnected) {
        await _syncCaseToFirebase(updatedCase);
      }
      
      return true;
    } catch (e) {
      print('Error updating case: $e');
      return false;
    }
  }

  // Delete a case
  Future<bool> deleteCase(String caseId) async {
    try {
      // Delete locally first
      await _hiveService.deleteCase(caseId);
      
      // Try to delete from Firebase if online
      if (_connectivityService.isConnected) {
        await _deleteCaseFromFirebase(caseId);
      }
      
      return true;
    } catch (e) {
      print('Error deleting case: $e');
      return false;
    }
  }

  // Get a single case by ID (local first, then Firebase if needed)
  Future<CaseModel?> getCaseById(String caseId) async {
    // Try local first
    CaseModel? caseModel = _hiveService.getCase(caseId);
    
    // If not found locally and online, try Firebase
    if (caseModel == null && _connectivityService.isConnected) {
      caseModel = await _getCaseFromFirebase(caseId);
      if (caseModel != null) {
        // Save to local storage
        await _hiveService.saveCase(caseModel);
      }
    }
    
    return caseModel;
  }

  // Search cases (local search for instant results)
  Future<List<CaseModel>> searchCases(String query) async {
    return _hiveService.searchCases(query);
  }

  // Get cases filtered by status
  Stream<List<CaseModel>> getCasesByStatus(CaseStatus status) {
    return getCasesStream().map((cases) => 
      cases.where((c) => c.status == status).toList()
    );
  }

  // Get today's hearings
  Stream<List<CaseModel>> getTodayHearings() {
    return getCasesStream().map((cases) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return cases.where((c) => 
        c.hearingDate.isAfter(startOfDay) && 
        c.hearingDate.isBefore(endOfDay)
      ).toList();
    });
  }

  // Get active cases (In Progress)
  Stream<List<CaseModel>> getActiveCases() {
    return getCasesStream().map((cases) => 
      cases.where((c) => c.status == CaseStatus.inProgress).toList()
    );
  }

  // Sync all unsynced cases
  Future<void> syncUnsyncedCases() async {
    if (!_connectivityService.isConnected) return;
    
    try {
      final unsyncedCases = _hiveService.getUnsyncedCases();
      
      for (final caseModel in unsyncedCases) {
        await _syncCaseToFirebase(caseModel);
      }
      
      print('Synced ${unsyncedCases.length} cases');
    } catch (e) {
      print('Error syncing cases: $e');
    }
  }

  // Sync a single case to Firebase
  Future<void> _syncCaseToFirebase(CaseModel caseModel) async {
    try {
      // Upload attachments first
      final attachmentUrls = await _uploadAttachments(caseModel.attachmentPaths);
      
      // Create case data for Firebase
      final caseData = caseModel.copyWith(
        attachmentUrls: attachmentUrls,
        isSynced: true,
        updatedAt: DateTime.now(),
      );
      
      // Save to Firestore
      await _firestore
          .collection('cases')
          .doc(caseData.id)
          .set(caseData.toMap());
      
      // Update local sync status
      await _hiveService.markCaseAsSynced(caseData.id);
      
      print('Case synced to Firebase: ${caseData.title}');
    } catch (e) {
      print('Error syncing case to Firebase: $e');
      // Mark as unsynced if sync failed
      await _hiveService.markCaseAsUnsynced(caseModel.id);
    }
  }

  // Upload attachments to Firebase Storage
  Future<List<String>> _uploadAttachments(List<String> attachmentPaths) async {
    final List<String> urls = [];
    
    for (final path in attachmentPaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final fileName = 'attachments/${currentUserId}/${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
          final ref = _storage.ref().child(fileName);
          
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          urls.add(url);
          
          print('Attachment uploaded: $fileName');
        }
      } catch (e) {
        print('Error uploading attachment: $e');
      }
    }
    
    return urls;
  }

  // Get case from Firebase
  Future<CaseModel?> _getCaseFromFirebase(String caseId) async {
    try {
      final doc = await _firestore
          .collection('cases')
          .doc(caseId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        if (data['ownerId'] == currentUserId) {
          return CaseModel.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      print('Error getting case from Firebase: $e');
      return null;
    }
  }

  // Delete case from Firebase
  Future<void> _deleteCaseFromFirebase(String caseId) async {
    try {
      await _firestore
          .collection('cases')
          .doc(caseId)
          .delete();
      
      print('Case deleted from Firebase: $caseId');
    } catch (e) {
      print('Error deleting case from Firebase: $e');
    }
  }

  // Pull latest data from Firebase (for initial sync)
  Future<void> pullLatestData() async {
    if (!_connectivityService.isConnected) return;
    
    try {
      final snapshot = await _firestore
          .collection('cases')
          .where('ownerId', isEqualTo: currentUserId)
          .get();
      
      for (final doc in snapshot.docs) {
        final caseModel = CaseModel.fromMap(doc.data());
        await _hiveService.saveCase(caseModel);
      }
      
      print('Pulled ${snapshot.docs.length} cases from Firebase');
    } catch (e) {
      print('Error pulling latest data: $e');
    }
  }

  // Get sync statistics
  Map<String, int> getSyncStatistics() {
    return {
      'total': _hiveService.totalCases,
      'synced': _hiveService.syncedCases,
      'unsynced': _hiveService.unsyncedCases,
    };
  }

  // Watch unsynced cases
  Stream<List<CaseModel>> watchUnsyncedCases() {
    return _hiveService.watchUnsyncedCases();
  }

  // Check if case exists remotely
  Future<bool> caseExistsRemotely(String caseId) async {
    if (!_connectivityService.isConnected) return false;
    
    try {
      final doc = await _firestore
          .collection('cases')
          .doc(caseId)
          .get();
      
      return doc.exists;
    } catch (e) {
      print('Error checking remote case existence: $e');
      return false;
    }
  }
}
