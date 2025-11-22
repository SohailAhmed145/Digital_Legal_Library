import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/law_library_model.dart';

// State for law library
class LawLibraryState {
  final List<LawDocument> documents;
  final List<LawCategory> categories;
  final List<LawDocument> filteredDocuments;
  final String searchQuery;
  final String selectedCategory;
  final bool isLoading;
  final String? errorMessage;

  LawLibraryState({
    required this.documents,
    required this.categories,
    required this.filteredDocuments,
    required this.searchQuery,
    required this.selectedCategory,
    required this.isLoading,
    this.errorMessage,
  });

  LawLibraryState copyWith({
    List<LawDocument>? documents,
    List<LawCategory>? categories,
    List<LawDocument>? filteredDocuments,
    String? searchQuery,
    String? selectedCategory,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LawLibraryState(
      documents: documents ?? this.documents,
      categories: categories ?? this.categories,
      filteredDocuments: filteredDocuments ?? this.filteredDocuments,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Provider for law library state
final lawLibraryProvider = StateNotifierProvider<LawLibraryNotifier, LawLibraryState>((ref) {
  return LawLibraryNotifier();
});

// Notifier for law library operations
class LawLibraryNotifier extends StateNotifier<LawLibraryState> {
  LawLibraryNotifier() : super(LawLibraryState(
    documents: [],
    categories: [],
    filteredDocuments: [],
    searchQuery: '',
    selectedCategory: 'All',
    isLoading: false,
  )) {
    _initializeData();
  }

  void _initializeData() {
    state = state.copyWith(
      documents: MockLawLibraryData.mockDocuments,
      categories: MockLawLibraryData.mockCategories,
      filteredDocuments: MockLawLibraryData.mockDocuments,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void setSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _applyFilters();
  }

  void _applyFilters() {
    List<LawDocument> filtered = state.documents;

    // Apply category filter
    if (state.selectedCategory != 'All' && state.selectedCategory.isNotEmpty) {
      if (state.selectedCategory == 'Laws') {
        // Filter by document types that are laws
        filtered = filtered.where((doc) => 
          doc.documentType == 'Act' || 
          doc.documentType == 'Code' || 
          doc.documentType == 'Constitution' ||
          doc.documentType == 'Ordinance'
        ).toList();
      } else if (state.selectedCategory == 'Documents') {
        // Filter by document types that are documents
        filtered = filtered.where((doc) => 
          doc.documentType == 'Document' || 
          doc.documentType == 'Report' ||
          doc.documentType == 'Judgment' ||
          doc.documentType == 'Notification'
        ).toList();
      } else {
        // Filter by specific category name
        filtered = filtered.where((doc) => doc.category == state.selectedCategory).toList();
      }
    }
    // If no category is selected or 'All' is selected, show all documents (no filtering by category)

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        final query = state.searchQuery.toLowerCase();
        return doc.title.toLowerCase().contains(query) ||
               doc.description.toLowerCase().contains(query) ||
               doc.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    state = state.copyWith(filteredDocuments: filtered);
  }

  void toggleBookmark(String documentId) {
    final updatedDocuments = state.documents.map((doc) {
      if (doc.id == documentId) {
        return doc.copyWith(isBookmarked: !doc.isBookmarked);
      }
      return doc;
    }).toList();

    state = state.copyWith(documents: updatedDocuments);
    _applyFilters();
  }

  List<LawDocument> getBookmarkedDocuments() {
    return state.documents.where((doc) => doc.isBookmarked).toList();
  }

  List<LawDocument> getDocumentsByCategory(String category) {
    return state.documents.where((doc) => doc.category == category).toList();
  }

  List<LawDocument> getRecentDocuments({int limit = 5}) {
    final sorted = List<LawDocument>.from(state.documents);
    sorted.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return sorted.take(limit).toList();
  }

  // Refresh library data
  void refreshLibrary() {
    _initializeData();
  }

  List<LawDocument> getPopularDocuments({int limit = 5}) {
    final sorted = List<LawDocument>.from(state.documents);
    sorted.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return sorted.take(limit).toList();
  }

  void refreshData() {
    _initializeData();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedCategory: 'All',
      filteredDocuments: state.documents,
    );
  }
}

// Provider for filtered documents
final filteredLawDocumentsProvider = Provider<List<LawDocument>>((ref) {
  final state = ref.watch(lawLibraryProvider);
  return state.filteredDocuments;
});

// Provider for categories
final lawCategoriesProvider = Provider<List<LawCategory>>((ref) {
  final state = ref.watch(lawLibraryProvider);
  return state.categories;
});

// Provider for bookmarked documents
final bookmarkedDocumentsProvider = Provider<List<LawDocument>>((ref) {
  final notifier = ref.read(lawLibraryProvider.notifier);
  return notifier.getBookmarkedDocuments();
});

// Provider for recent documents
final recentDocumentsProvider = Provider<List<LawDocument>>((ref) {
  final notifier = ref.read(lawLibraryProvider.notifier);
  return notifier.getRecentDocuments();
});

// Provider for popular documents
final popularDocumentsProvider = Provider<List<LawDocument>>((ref) {
  final notifier = ref.read(lawLibraryProvider.notifier);
  return notifier.getPopularDocuments();
});
