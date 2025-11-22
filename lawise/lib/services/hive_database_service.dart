import 'package:hive_flutter/hive_flutter.dart';
import '../models/case_model.dart';

class HiveDatabaseService {
  static const String _casesBoxName = 'cases';
  static const String _syncStatusBoxName = 'sync_status';
  
  late Box<CaseModel> _casesBox;
  late Box<String> _syncStatusBox;
  
  static final HiveDatabaseService _instance = HiveDatabaseService._internal();
  factory HiveDatabaseService() => _instance;
  HiveDatabaseService._internal();

  Future<void> initialize() async {
    try {
      // For web, Hive.initFlutter() is already called in main.dart
      // For mobile, we would initialize here if needed
      
      // Register adapters (already done in main.dart)
      // Hive.registerAdapter(CaseModelAdapter());
      
      // Open boxes
      _casesBox = await Hive.openBox<CaseModel>(_casesBoxName);
      _syncStatusBox = await Hive.openBox<String>(_syncStatusBoxName);
      
      print('Hive database initialized successfully');
    } catch (e) {
      print('Error initializing Hive database: $e');
      
      // Handle schema migration issues by clearing incompatible data
      if (e.toString().contains('type \'Null\' is not a subtype of type \'String\'')) {
        print('Detected schema migration issue. Clearing local data...');
        await _clearIncompatibleData();
        
        // Retry opening boxes after clearing
        _casesBox = await Hive.openBox<CaseModel>(_casesBoxName);
        _syncStatusBox = await Hive.openBox<String>(_syncStatusBoxName);
        print('Hive database reinitialized after migration');
      } else {
        // Create empty boxes as fallback for other errors
        _casesBox = await Hive.openBox<CaseModel>(_casesBoxName);
        _syncStatusBox = await Hive.openBox<String>(_syncStatusBoxName);
      }
    }
  }
  
  // Clear incompatible data during schema migration
  Future<void> _clearIncompatibleData() async {
    try {
      // Delete the box files to clear incompatible data
      await Hive.deleteBoxFromDisk(_casesBoxName);
      await Hive.deleteBoxFromDisk(_syncStatusBoxName);
      print('Cleared incompatible Hive data');
    } catch (e) {
      print('Error clearing incompatible data: $e');
    }
  }

  // Case CRUD Operations
  Future<void> saveCase(CaseModel caseModel) async {
    await _casesBox.put(caseModel.id, caseModel);
    print('Case saved locally: ${caseModel.title}');
  }

  Future<void> updateCase(CaseModel caseModel) async {
    await _casesBox.put(caseModel.id, caseModel);
    print('Case updated locally: ${caseModel.title}');
  }

  Future<void> deleteCase(String caseId) async {
    await _casesBox.delete(caseId);
    print('Case deleted locally: $caseId');
  }

  CaseModel? getCase(String caseId) {
    return _casesBox.get(caseId);
  }

  List<CaseModel> getAllCases() {
    return _casesBox.values.toList();
  }

  List<CaseModel> getUnsyncedCases() {
    return _casesBox.values.where((caseModel) => !caseModel.isSynced).toList();
  }

  Stream<List<CaseModel>> watchCases() {
    return _casesBox.watch().map((_) => _casesBox.values.toList());
  }

  Stream<List<CaseModel>> watchUnsyncedCases() {
    return _casesBox.watch().map((_) => 
      _casesBox.values.where((caseModel) => !caseModel.isSynced).toList()
    );
  }

  // Sync Status Operations
  Future<void> markCaseAsSynced(String caseId) async {
    final caseModel = _casesBox.get(caseId);
    if (caseModel != null) {
      final updatedCase = caseModel.copyWith(isSynced: true);
      await _casesBox.put(caseId, updatedCase);
      print('Case marked as synced: $caseId');
    }
  }

  Future<void> markCaseAsUnsynced(String caseId) async {
    final caseModel = _casesBox.get(caseId);
    if (caseModel != null) {
      final updatedCase = caseModel.copyWith(isSynced: false);
      await _casesBox.put(caseId, updatedCase);
      print('Case marked as unsynced: $caseId');
    }
  }

  // Search and Filter Operations
  List<CaseModel> searchCases(String query) {
    if (query.isEmpty) return _casesBox.values.toList();
    
    final lowerQuery = query.toLowerCase();
    return _casesBox.values.where((caseModel) =>
      caseModel.title.toLowerCase().contains(lowerQuery) ||
      caseModel.caseNumber.toLowerCase().contains(lowerQuery) ||
      caseModel.plaintiff.toLowerCase().contains(lowerQuery) ||
      caseModel.defendant.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  List<CaseModel> filterCasesByStatus(CaseStatus status) {
    return _casesBox.values.where((caseModel) => caseModel.status == status).toList();
  }

  List<CaseModel> getCasesByDateRange(DateTime startDate, DateTime endDate) {
    return _casesBox.values.where((caseModel) =>
      caseModel.hearingDate.isAfter(startDate) && 
      caseModel.hearingDate.isBefore(endDate)
    ).toList();
  }

  // Database Management
  Future<void> clearAllData() async {
    await _casesBox.clear();
    await _syncStatusBox.clear();
    print('All local data cleared');
  }

  Future<void> close() async {
    await _casesBox.close();
    await _syncStatusBox.close();
    print('Hive database closed');
  }

  // Statistics
  int get totalCases => _casesBox.length;
  int get syncedCases => _casesBox.values.where((c) => c.isSynced).length;
  int get unsyncedCases => _casesBox.values.where((c) => !c.isSynced).length;
}
