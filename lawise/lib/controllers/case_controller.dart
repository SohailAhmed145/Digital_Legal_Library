import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/case_model.dart';
import '../repositories/case_repository.dart';
import '../services/connectivity_service.dart';
import '../services/file_service.dart';
import 'package:uuid/uuid.dart';

// Case Repository Provider
final caseRepositoryProvider = Provider<CaseRepository>((ref) {
  return CaseRepository();
});

// Connectivity Service Provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

// File Service Provider
final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});

// Case State
class CaseState {
  final List<CaseModel> cases;
  final List<CaseModel> filteredCases;
  final List<CaseModel> todayHearings;
  final List<CaseModel> activeCases;
  final List<CaseModel> unsyncedCases;
  final bool isLoading;
  final String? errorMessage;
  final CaseStatus? statusFilter;
  final String searchQuery;
  final bool isOnline;
  final Map<String, int> syncStatistics;

  CaseState({
    this.cases = const [],
    this.filteredCases = const [],
    this.todayHearings = const [],
    this.activeCases = const [],
    this.unsyncedCases = const [],
    this.isLoading = false,
    this.errorMessage,
    this.statusFilter,
    this.searchQuery = '',
    this.isOnline = true,
    this.syncStatistics = const {},
  });

  CaseState copyWith({
    List<CaseModel>? cases,
    List<CaseModel>? filteredCases,
    List<CaseModel>? todayHearings,
    List<CaseModel>? activeCases,
    List<CaseModel>? unsyncedCases,
    bool? isLoading,
    String? errorMessage,
    CaseStatus? statusFilter,
    String? searchQuery,
    bool? isOnline,
    Map<String, int>? syncStatistics,
  }) {
    return CaseState(
      cases: cases ?? this.cases,
      filteredCases: filteredCases ?? this.filteredCases,
      todayHearings: todayHearings ?? this.todayHearings,
      activeCases: activeCases ?? this.activeCases,
      unsyncedCases: unsyncedCases ?? this.unsyncedCases,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isOnline: isOnline ?? this.isOnline,
      syncStatistics: syncStatistics ?? this.syncStatistics,
    );
  }
}

// Case Controller
class CaseController extends StateNotifier<CaseState> {
  final CaseRepository _repository;
  final ConnectivityService _connectivityService;
  final FileService _fileService;
  final _uuid = const Uuid();

  CaseController(this._repository, this._connectivityService, this._fileService) 
      : super(CaseState()) {
    _initialize();
  }

  // Initialize controller
  Future<void> _initialize() async {
    try {
      // Initialize repository
      await _repository.initialize();
      
      // Pull latest data from Firebase immediately
      await _repository.pullLatestData();
      
      // Listen to connectivity changes
      _connectivityService.connectionStatus.listen((isOnline) {
        state = state.copyWith(isOnline: isOnline);
        
        if (isOnline) {
          // Try to sync unsynced cases when back online
          _syncUnsyncedCases();
          // Also pull latest data when coming back online
          _repository.pullLatestData();
        }
      });
      
      // Initialize cases using the hybrid stream
      _initializeCases();
      
      // Update sync statistics
      _updateSyncStatistics();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to initialize: $e',
        isLoading: false,
      );
    }
  }

  // Initialize cases using the hybrid data stream
  void _initializeCases() {
    // Watch all cases from the hybrid stream
    _repository.getCasesStream().listen(
      (cases) {
        state = state.copyWith(
          cases: cases,
          filteredCases: _applyFilters(cases, state.statusFilter, state.searchQuery),
        );
        _updateDerivedLists(cases);
        _updateSyncStatistics();
      },
      onError: (error) {
        state = state.copyWith(
          errorMessage: error.toString(),
          isLoading: false,
        );
      },
    );

    // Watch unsynced cases separately
    _repository.watchUnsyncedCases().listen(
      (unsyncedCases) {
        state = state.copyWith(unsyncedCases: unsyncedCases);
      },
      onError: (error) {
        print('Error loading unsynced cases: $error');
      },
    );
  }

  // Update derived lists
  void _updateDerivedLists(List<CaseModel> cases) {
    // Update today's hearings
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final todayHearings = cases.where((c) =>
      c.hearingDate.isAfter(startOfDay) && 
      c.hearingDate.isBefore(endOfDay)
    ).toList();

    // Update active cases
    final activeCases = cases.where((c) => c.status == CaseStatus.inProgress).toList();

    state = state.copyWith(
      todayHearings: todayHearings,
      activeCases: activeCases,
    );
  }

  // Update sync statistics
  void _updateSyncStatistics() {
    final stats = _repository.getSyncStatistics();
    state = state.copyWith(syncStatistics: stats);
  }

  // Apply filters to cases
  List<CaseModel> _applyFilters(
    List<CaseModel> cases,
    CaseStatus? statusFilter,
    String searchQuery,
  ) {
    List<CaseModel> filtered = cases;

    // Apply status filter
    if (statusFilter != null) {
      filtered = filtered.where((caseModel) => caseModel.status == statusFilter).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((caseModel) =>
          caseModel.title.toLowerCase().contains(query) ||
          caseModel.plaintiff.toLowerCase().contains(query) ||
          caseModel.defendant.toLowerCase().contains(query) ||
          caseModel.caseNumber.toLowerCase().contains(query)).toList();
    }

    return filtered;
  }

  // Set status filter
  void setStatusFilter(CaseStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      filteredCases: _applyFilters(state.cases, status, state.searchQuery),
    );
  }

  // Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      filteredCases: _applyFilters(state.cases, state.statusFilter, query),
    );
  }

  // Create a new case
  Future<bool> createCase({
    required String title,
    required String plaintiff,
    required String defendant,
    required String caseNumber,
    required String court,
    String category = 'Civil Law',
    required DateTime hearingDate,
    required CaseStatus status,
    String? notes,
    List<String> attachmentPaths = const [],
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final currentUser = _repository.currentUserId;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final newCase = CaseModel(
        id: _uuid.v4(),
        title: title,
        plaintiff: plaintiff,
        defendant: defendant,
        caseNumber: caseNumber,
        court: court,
        category: category,
        hearingDate: hearingDate,
        status: status,
        notes: notes,
        attachmentPaths: attachmentPaths,
        ownerId: currentUser,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false, // Will be synced when online
      );

      final success = await _repository.createCase(newCase);
      
      if (success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to create case',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // Update an existing case
  Future<bool> updateCase(CaseModel caseModel) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final updatedCase = caseModel.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false, // Will be synced when online
      );

      final success = await _repository.updateCase(updatedCase);
      
      if (success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to update case',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // Delete a case
  Future<bool> deleteCase(String caseId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final success = await _repository.deleteCase(caseId);
      
      if (success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to delete case',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // Get a single case by ID
  Future<CaseModel?> getCaseById(String caseId) async {
    try {
      return await _repository.getCaseById(caseId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  // Search cases
  Future<List<CaseModel>> searchCases(String query) async {
    try {
      return await _repository.searchCases(query);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return [];
    }
  }

  // Pick and save files
  Future<List<String>> pickAndSaveFiles() async {
    try {
      final results = await _fileService.pickFiles();
      final List<String> savedPaths = [];
      
      for (final result in results) {
        for (final file in result.files) {
          if (_fileService.isValidFile(file)) {
            final savedPath = await _fileService.saveFileToLocal(file);
            if (savedPath != null) {
              savedPaths.add(savedPath);
            }
          }
        }
      }
      
      return savedPaths;
    } catch (e) {
      print('Error picking files: $e');
      return [];
    }
  }

  // Sync unsynced cases
  Future<void> _syncUnsyncedCases() async {
    if (!state.isOnline) return;
    
    try {
      await _repository.syncUnsyncedCases();
      _updateSyncStatistics();
    } catch (e) {
      print('Error syncing cases: $e');
    }
  }

  // Manual sync
  Future<void> syncCases() async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.syncUnsyncedCases();
      _updateSyncStatistics();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sync failed: $e',
      );
    }
  }

  // Pull latest data from Firebase
  Future<void> pullLatestData() async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.pullLatestData();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to pull latest data: $e',
      );
    }
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  // Refresh cases
  void refreshCases() {
    _initializeCases();
  }
}

// Providers
final caseControllerProvider = StateNotifierProvider<CaseController, CaseState>((ref) {
  final repository = ref.watch(caseRepositoryProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final fileService = ref.watch(fileServiceProvider);
  return CaseController(repository, connectivityService, fileService);
});

final casesProvider = Provider<List<CaseModel>>((ref) {
  return ref.watch(caseControllerProvider).cases;
});

final filteredCasesProvider = Provider<List<CaseModel>>((ref) {
  return ref.watch(caseControllerProvider).filteredCases;
});

final todayHearingsProvider = Provider<List<CaseModel>>((ref) {
  return ref.watch(caseControllerProvider).todayHearings;
});

final activeCasesProvider = Provider<List<CaseModel>>((ref) {
  return ref.watch(caseControllerProvider).activeCases;
});

final unsyncedCasesProvider = Provider<List<CaseModel>>((ref) {
  return ref.watch(caseControllerProvider).unsyncedCases;
});

final caseIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(caseControllerProvider).isLoading;
});

final caseErrorProvider = Provider<String?>((ref) {
  return ref.watch(caseControllerProvider).errorMessage;
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(caseControllerProvider).isOnline;
});

final syncStatisticsProvider = Provider<Map<String, int>>((ref) {
  return ref.watch(caseControllerProvider).syncStatistics;
});
