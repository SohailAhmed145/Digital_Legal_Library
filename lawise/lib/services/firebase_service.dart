import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/case_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseStorage _storage;

  Future<void> initialize() async {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      print('FirebaseService initialized successfully');
    } catch (e) {
      print('Error initializing FirebaseService: $e');
      rethrow;
    }
  }

  // Getter methods with null safety
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  // Authentication Methods
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // User Management
  Future<void> createUserProfile(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.id)
        .set(user.toMap());
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.id)
        .update(user.toMap());
  }

  // Case Management
  Future<void> createCase(CaseModel caseModel) async {
    await _firestore
        .collection('cases')
        .doc(caseModel.id)
        .set(caseModel.toMap());
  }

  Future<void> updateCase(CaseModel caseModel) async {
    await _firestore
        .collection('cases')
        .doc(caseModel.id)
        .update(caseModel.toMap());
  }

  Future<void> deleteCase(String caseId) async {
    await _firestore
        .collection('cases')
        .doc(caseId)
        .delete();
  }

  Stream<List<CaseModel>> getCasesStream(String userId) {
    return _firestore
        .collection('cases')
        .where('ownerId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CaseModel.fromMap(doc.data()!))
            .toList());
  }

  Future<CaseModel?> getCase(String caseId) async {
    final doc = await _firestore
        .collection('cases')
        .doc(caseId)
        .get();
    
    if (doc.exists) {
      return CaseModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Chat Management - Placeholder methods (models not yet implemented)
  Future<void> createChatConversation(dynamic conversation) async {
    // TODO: Implement when ChatConversation model is created
    print('Chat conversation creation not yet implemented');
  }

  Future<void> addChatMessage(dynamic message) async {
    // TODO: Implement when ChatMessage model is created
    print('Chat message addition not yet implemented');
  }

  Stream<List<dynamic>> getChatMessagesStream(String conversationId) {
    // TODO: Implement when ChatMessage model is created
    return Stream.value([]);
  }

  Stream<List<dynamic>> getChatConversationsStream(String userId) {
    // TODO: Implement when ChatMessage model is created
    return Stream.value([]);
  }

  // Notifications - Placeholder methods (models not yet implemented)
  Future<void> createNotification(dynamic notification) async {
    // TODO: Implement when NotificationModel is created
    print('Notification creation not yet implemented');
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Stream<List<dynamic>> getNotificationsStream(String userId) {
    // TODO: Implement when NotificationModel is created
    return Stream.value([]);
  }

  // Law Library - Placeholder methods (models not yet implemented)
  Future<void> createLawDocument(dynamic document) async {
    // TODO: Implement when LawDocument model is created
    print('Law document creation not yet implemented');
  }

  Future<void> updateLawDocument(dynamic document) async {
    // TODO: Implement when LawDocument model is created
    print('Law document update not yet implemented');
  }

  Stream<List<dynamic>> getLawDocumentsStream() {
    // TODO: Implement when LawDocument model is created
    return Stream.value([]);
  }

  Stream<List<dynamic>> getLawDocumentsByCategoryStream(dynamic category) {
    // TODO: Implement when LawDocument model is created
    return Stream.value([]);
  }

  // File Storage
  Future<String> uploadFile(String path, List<int> bytes) async {
    final ref = _storage.ref().child(path);
    await ref.putData(Uint8List.fromList(bytes));
    return await ref.getDownloadURL();
  }

  Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }

  // Search
  Future<List<CaseModel>> searchCases(String query, String userId) async {
    final snapshot = await _firestore
        .collection('cases')
        .where('ownerId', isEqualTo: userId)
        .get();
    
    final cases = snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data()!))
        .toList();
    
    return cases.where((caseModel) =>
        caseModel.title.toLowerCase().contains(query.toLowerCase()) ||
        caseModel.caseNo.toLowerCase().contains(query.toLowerCase()) ||
        caseModel.plaintiff.toLowerCase().contains(query.toLowerCase()) ||
        caseModel.defendant.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<List<dynamic>> searchLawDocuments(String query) async {
    // TODO: Implement when LawDocument model is created
    print('Law document search not yet implemented');
    return [];
  }
}
