import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/case_model.dart';
import '../services/firebase_service.dart';

class SampleDataService {
  static final SampleDataService _instance = SampleDataService._internal();
  factory SampleDataService() => _instance;
  SampleDataService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Creates sample cases in Firebase for the current user
  Future<void> createSampleCases() async {
    if (currentUserId == null) {
      print('No user logged in, cannot create sample cases');
      return;
    }

    try {
      // Check if cases already exist for this user
      final existingCases = await _firestore
          .collection('cases')
          .where('ownerId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (existingCases.docs.isNotEmpty) {
        print('Sample cases already exist for user');
        return;
      }

      final sampleCases = _generateSampleCases();
      
      for (final caseModel in sampleCases) {
        await _firebaseService.createCase(caseModel);
        print('Created sample case: ${caseModel.title}');
      }

      print('Successfully created ${sampleCases.length} sample cases');
    } catch (e) {
      print('Error creating sample cases: $e');
    }
  }

  /// Generates a list of sample cases
  List<CaseModel> _generateSampleCases() {
    final now = DateTime.now();
    final userId = currentUserId!;

    return [
      CaseModel(
        id: 'case_001_${userId}',
        title: 'Property Dispute - Commercial Plaza',
        plaintiff: 'Ahmed Construction Ltd.',
        defendant: 'City Development Authority',
        caseNumber: 'CIV/2024/001',
        court: 'Lahore High Court',
        hearingDate: now.add(const Duration(days: 15)),
        status: CaseStatus.inProgress,
        notes: 'Commercial property dispute regarding building permits and zoning violations. Client claims wrongful demolition notice.',
        category: 'Property Law',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 2)),
        ownerId: userId,
        isSynced: true,
        lastNotePreview: 'Meeting with client scheduled for next week to review documents.',
      ),
      CaseModel(
        id: 'case_002_${userId}',
        title: 'Employment Termination Case',
        plaintiff: 'Sarah Khan',
        defendant: 'TechCorp Solutions',
        caseNumber: 'LAB/2024/045',
        court: 'Labor Court',
        hearingDate: now.add(const Duration(days: 8)),
        status: CaseStatus.inProgress,
        notes: 'Wrongful termination case. Employee claims discrimination and seeks compensation for unlawful dismissal.',
        category: 'Labor Law',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 1)),
        ownerId: userId,
        isSynced: true,
        lastNotePreview: 'Gathering evidence of discriminatory practices.',
      ),
      CaseModel(
        id: 'case_003_${userId}',
        title: 'Contract Breach - Software Development',
        plaintiff: 'Digital Solutions Inc.',
        defendant: 'StartupTech Ltd.',
        caseNumber: 'COM/2024/078',
        court: 'Civil Court',
        hearingDate: now.add(const Duration(days: 22)),
        status: CaseStatus.draft,
        notes: 'Breach of software development contract. Client failed to deliver project on time and within specifications.',
        category: 'Corporate Law',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 1)),
        ownerId: userId,
        isSynced: true,
        lastNotePreview: 'Reviewing contract terms and penalty clauses.',
      ),
      CaseModel(
        id: 'case_004_${userId}',
        title: 'Family Custody Dispute',
        plaintiff: 'Fatima Ali',
        defendant: 'Hassan Ali',
        caseNumber: 'FAM/2024/012',
        court: 'Family Court',
        hearingDate: now.add(const Duration(days: 5)),
        status: CaseStatus.inProgress,
        notes: 'Child custody case following divorce proceedings. Seeking joint custody arrangement.',
        category: 'Family Law',
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        ownerId: userId,
        isSynced: true,
        lastNotePreview: 'Mediation session scheduled for tomorrow.',
      ),
      CaseModel(
        id: 'case_005_${userId}',
        title: 'Tax Evasion Investigation',
        plaintiff: 'Federal Board of Revenue',
        defendant: 'Global Imports Ltd.',
        caseNumber: 'TAX/2024/156',
        court: 'Banking Court',
        hearingDate: now.add(const Duration(days: 30)),
        status: CaseStatus.closed,
        notes: 'Tax evasion case resolved through settlement. Company agreed to pay penalties and back taxes.',
        category: 'Tax Law',
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 7)),
        ownerId: userId,
        isSynced: true,
        lastNotePreview: 'Case closed successfully with settlement agreement.',
      ),
      CaseModel(
        id: 'case_006_${userId}',
        title: 'Banking Fraud Investigation',
        plaintiff: 'National Bank of Pakistan',
        defendant: 'Muhammad Tariq',
        caseNumber: 'BANK/2024/089',
        court: 'Banking Court',
        hearingDate: now.add(const Duration(days: 12)),
        status: CaseStatus.inProgress,
        notes: 'Investigation into fraudulent loan applications and document forgery.',
        category: 'Banking Law',
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        ownerId: userId,
        isSynced: true,
        lastNotePreview: 'Forensic audit report received from bank.',
      ),
    ];
  }

  /// Clears all sample cases for the current user
  Future<void> clearSampleCases() async {
    if (currentUserId == null) return;

    try {
      final cases = await _firestore
          .collection('cases')
          .where('ownerId', isEqualTo: currentUserId)
          .get();

      final batch = _firestore.batch();
      for (final doc in cases.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('Cleared ${cases.docs.length} sample cases');
    } catch (e) {
      print('Error clearing sample cases: $e');
    }
  }
}