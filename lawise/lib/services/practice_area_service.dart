import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/case_model.dart';
import '../models/law_library_model.dart';
import '../repositories/case_repository.dart';
import '../providers/law_library_provider.dart';

class PracticeAreaData {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String colorHex;
  final int caseCount;
  final int documentCount;
  final List<CaseModel> recentCases;
  final List<LawDocument> relatedDocuments;
  final bool isFeatured;
  final DateTime lastActivity;

  PracticeAreaData({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.colorHex,
    required this.caseCount,
    required this.documentCount,
    required this.recentCases,
    required this.relatedDocuments,
    required this.isFeatured,
    required this.lastActivity,
  });

  PracticeAreaData copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? colorHex,
    int? caseCount,
    int? documentCount,
    List<CaseModel>? recentCases,
    List<LawDocument>? relatedDocuments,
    bool? isFeatured,
    DateTime? lastActivity,
  }) {
    return PracticeAreaData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      caseCount: caseCount ?? this.caseCount,
      documentCount: documentCount ?? this.documentCount,
      recentCases: recentCases ?? this.recentCases,
      relatedDocuments: relatedDocuments ?? this.relatedDocuments,
      isFeatured: isFeatured ?? this.isFeatured,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}

class PracticeAreaService {
  final CaseRepository _caseRepository;
  
  PracticeAreaService(this._caseRepository);

  // Get practice areas with real data integration
  Future<List<PracticeAreaData>> getPracticeAreas(List<LawCategory> lawCategories) async {
    final allCases = await _caseRepository.getCasesStream().first;
    final practiceAreas = <PracticeAreaData>[];

    for (final category in lawCategories) {
      // Get cases for this practice area
      final categoryCases = allCases.where((case_) => 
        case_.category.toLowerCase() == category.name.toLowerCase()
      ).toList();

      // Get recent cases (last 30 days)
      final recentCases = categoryCases.where((case_) => 
        case_.updatedAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))
      ).toList();

      // Sort by most recent activity
      recentCases.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // Get related documents from law library
      final relatedDocuments = MockLawLibraryData.mockDocuments
          .where((doc) => doc.category == category.name)
          .take(5)
          .toList();

      // Determine if this area should be featured (has recent activity)
      final isFeatured = recentCases.isNotEmpty || categoryCases.length >= 3;

      // Get last activity date
      final lastActivity = categoryCases.isNotEmpty 
          ? categoryCases.map((c) => c.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b)
          : DateTime.now().subtract(const Duration(days: 365));

      practiceAreas.add(PracticeAreaData(
        id: category.id,
        name: category.name,
        description: category.description,
        iconName: category.iconName,
        colorHex: category.colorHex,
        caseCount: categoryCases.length,
        documentCount: relatedDocuments.length,
        recentCases: recentCases.take(3).toList(),
        relatedDocuments: relatedDocuments,
        isFeatured: isFeatured,
        lastActivity: lastActivity,
      ));
    }

    // Sort by activity and case count
    practiceAreas.sort((a, b) {
      // Featured areas first
      if (a.isFeatured && !b.isFeatured) return -1;
      if (!a.isFeatured && b.isFeatured) return 1;
      
      // Then by recent activity
      final activityComparison = b.lastActivity.compareTo(a.lastActivity);
      if (activityComparison != 0) return activityComparison;
      
      // Finally by case count
      return b.caseCount.compareTo(a.caseCount);
    });

    return practiceAreas;
  }

  // Get featured practice areas (top 2)
  Future<List<PracticeAreaData>> getFeaturedPracticeAreas(List<LawCategory> lawCategories) async {
    final allAreas = await getPracticeAreas(lawCategories);
    return allAreas.where((area) => area.isFeatured).take(2).toList();
  }

  // Get practice areas for horizontal scroll
  Future<List<PracticeAreaData>> getHorizontalPracticeAreas(List<LawCategory> lawCategories) async {
    final allAreas = await getPracticeAreas(lawCategories);
    // Skip the first 2 featured areas and take next 3-5
    return allAreas.skip(2).take(3).toList();
  }

  // Get quick access practice areas (remaining areas)
  Future<List<PracticeAreaData>> getQuickAccessAreas(List<LawCategory> lawCategories) async {
    final allAreas = await getPracticeAreas(lawCategories);
    // Skip the first 5 areas and take remaining
    return allAreas.skip(5).toList();
  }

  // Get practice area statistics
  Future<Map<String, dynamic>> getPracticeAreaStats() async {
    final allCases = await _caseRepository.getCasesStream().first;
    final totalAreas = CaseCategories.categories.length;
    final activeAreas = CaseCategories.categories.where((category) => 
      allCases.any((case_) => case_.category == category)
    ).length;
    
    final totalCases = allCases.length;
    final activeCases = allCases.where((case_) => 
      case_.status == CaseStatus.inProgress
    ).length;

    return {
      'totalAreas': totalAreas,
      'activeAreas': activeAreas,
      'totalCases': totalCases,
      'activeCases': activeCases,
      'totalDocuments': MockLawLibraryData.mockDocuments.length,
    };
  }

  // Search practice areas
  Future<List<PracticeAreaData>> searchPracticeAreas(String query, List<LawCategory> lawCategories) async {
    final allAreas = await getPracticeAreas(lawCategories);
    final queryLower = query.toLowerCase();
    
    return allAreas.where((area) => 
      area.name.toLowerCase().contains(queryLower) ||
      area.description.toLowerCase().contains(queryLower)
    ).toList();
  }
}

// Provider for practice area service
final practiceAreaServiceProvider = Provider<PracticeAreaService>((ref) {
  final caseRepository = ref.watch(caseRepositoryProvider);
  return PracticeAreaService(caseRepository);
});

// Provider for case repository
final caseRepositoryProvider = Provider<CaseRepository>((ref) {
  return CaseRepository();
});

// Provider for practice areas data
final practiceAreasProvider = FutureProvider<List<PracticeAreaData>>((ref) async {
  final service = ref.watch(practiceAreaServiceProvider);
  final lawCategories = ref.watch(lawCategoriesProvider);
  return service.getPracticeAreas(lawCategories);
});

// Provider for featured practice areas
final featuredPracticeAreasProvider = FutureProvider<List<PracticeAreaData>>((ref) async {
  final service = ref.watch(practiceAreaServiceProvider);
  final lawCategories = ref.watch(lawCategoriesProvider);
  return service.getFeaturedPracticeAreas(lawCategories);
});

// Provider for horizontal practice areas
final horizontalPracticeAreasProvider = FutureProvider<List<PracticeAreaData>>((ref) async {
  final service = ref.watch(practiceAreaServiceProvider);
  final lawCategories = ref.watch(lawCategoriesProvider);
  return service.getHorizontalPracticeAreas(lawCategories);
});

// Provider for quick access areas
final quickAccessAreasProvider = FutureProvider<List<PracticeAreaData>>((ref) async {
  final service = ref.watch(practiceAreaServiceProvider);
  final lawCategories = ref.watch(lawCategoriesProvider);
  return service.getQuickAccessAreas(lawCategories);
});

// Provider for practice area statistics
final practiceAreaStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(practiceAreaServiceProvider);
  return service.getPracticeAreaStats();
});