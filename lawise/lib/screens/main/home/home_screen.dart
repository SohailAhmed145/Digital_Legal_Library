import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lawise/models/case_model.dart';
import 'package:lawise/providers/case_provider.dart';
import 'package:lawise/providers/language_provider.dart';
import 'package:lawise/providers/theme_provider.dart';
import 'package:lawise/providers/user_profile_provider.dart';
import 'package:lawise/services/practice_area_service.dart';
import 'package:lawise/providers/law_library_provider.dart';
import 'package:lawise/models/law_library_model.dart';
import 'package:lawise/theme/app_theme.dart';
import 'package:lawise/utils/responsive_utils.dart';
import 'package:lawise/widgets/enhanced_card.dart';
import 'package:lawise/widgets/profile_image_widget.dart';
import 'package:lawise/controllers/case_controller.dart';
import 'package:lawise/screens/main/settings/settings_screen.dart';
import 'package:lawise/screens/main/cases/case_detail_screen.dart';
import 'package:lawise/screens/main/library/library_screen.dart';
import 'package:lawise/screens/main/practice_area_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize data loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(caseControllerProvider.notifier).refreshCases();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _liveResultsHideTimer?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    
    return Scaffold(
      body: _buildHomeContent(context, currentLanguage),
    );
  }

  Widget _buildHomeContent(BuildContext context, String currentLanguage) {
    final caseState = ref.watch(caseControllerProvider);
    final quickAccessAreas = ref.watch(quickAccessAreasProvider);
    final isDarkMode = ref.watch(themeProvider);
    
    // Filter active cases
    final activeCases = caseState.cases.where((case_) => 
      case_.status == CaseStatus.inProgress
    ).take(3).toList();
    
    // Get today's hearings
    final todayHearings = caseState.todayHearings;
    
    return RefreshIndicator(
        onRefresh: () async {
          ref.read(caseControllerProvider.notifier).refreshCases();
        },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(isDarkMode, currentLanguage),
            
            // Search Bar Section
            _buildSearchBarSection(isDarkMode, currentLanguage),
            
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getSpacing(context, 16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingL)),
                  
                  // Welcome Section
                  _buildWelcomeSection(currentLanguage),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingXL)),
                  
                  // Statistics Dashboard
                  _buildStatisticsSection(caseState, currentLanguage),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Featured Legal Resources
                  _buildFeaturedResourcesSection(currentLanguage),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Today's Schedule
                  if (todayHearings.isNotEmpty) ...[
                    _buildTodayScheduleSection(todayHearings, currentLanguage),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingXL)),
                  ],
                  
                  // Quick Access Practice Areas
                  _buildQuickAccessSection(quickAccessAreas, currentLanguage),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Recent Activity
                  _buildRecentActivitySection(activeCases, currentLanguage),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingXXL)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDarkMode, String currentLanguage) {
    final userProfile = ref.watch(userProfileProvider);
    
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingL)),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // App Logo
            Text(
              'Legal Library',
              style: GoogleFonts.playfairDisplay(
                fontSize: ResponsiveUtils.getFontSize(context, 28),
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
                letterSpacing: ResponsiveUtils.getSpacing(context, 1.0),
              ),
            ),
            const Spacer(),
            // Notifications and Profile
            Row(
              children: [
                // Notification Bell
                Container(
                  padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: ResponsiveUtils.getSpacing(context, 10),
                        offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: isDarkMode ? Colors.white : const Color(0xFF424242),
                    size: ResponsiveUtils.getIconSize(context, 20),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
                // User Avatar
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: ResponsiveUtils.getIconSize(context, 40),
                    height: ResponsiveUtils.getIconSize(context, 40),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 20)),
                      border: Border.all(
                        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white, 
                        width: 2
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 18)),
                      child: userProfile != null
                          ? ProfileImageWidget(size: ResponsiveUtils.getIconSize(context, 36))
                          : Container(
                              color: AppTheme.primaryColor,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: ResponsiveUtils.getIconSize(context, 20),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String currentLanguage) {
    final isDarkMode = ref.watch(themeProvider);
    final userProfile = ref.watch(userProfileProvider);
    final userName = userProfile?.fullName ?? 'User';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentLanguage == 'urdu' 
            ? 'خوش آمدید، $userName'
            : 'Welcome back, $userName',
          style: GoogleFonts.inter(
            fontSize: ResponsiveUtils.getFontSize(context, 24),
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
        Text(
          currentLanguage == 'urdu' 
            ? 'آج آپ کے قانونی کام کا خلاصہ'
            : 'Here\'s your legal work overview for today',
          style: GoogleFonts.inter(
            fontSize: ResponsiveUtils.getFontSize(context, 16),
            color: isDarkMode ? Colors.white70 : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(dynamic caseState, String currentLanguage) {
    final isDarkMode = ref.watch(themeProvider);
    final totalCases = caseState.cases.length;
    final activeCases = caseState.cases.where((c) => c.status == CaseStatus.inProgress).length;
    final todayHearings = caseState.todayHearings.length;
    final unsyncedCases = caseState.unsyncedCases.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentLanguage == 'urdu' ? 'آج کا خلاصہ' : 'Today\'s Overview',
          style: GoogleFonts.inter(
            fontSize: ResponsiveUtils.getFontSize(context, 20),
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: currentLanguage == 'urdu' ? 'کل کیسز' : 'Total Cases',
                value: totalCases.toString(),
                icon: Icons.folder,
                color: AppTheme.primaryColor,
                isDarkMode: isDarkMode,
              ),
            ),
            SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
            Expanded(
              child: _buildStatCard(
                title: currentLanguage == 'urdu' ? 'فعال کیسز' : 'Active Cases',
                value: activeCases.toString(),
                icon: Icons.trending_up,
                color: Colors.green,
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: currentLanguage == 'urdu' ? 'آج کی سماعت' : 'Today\'s Hearings',
                value: todayHearings.toString(),
                icon: Icons.schedule,
                color: Colors.orange,
                isDarkMode: isDarkMode,
              ),
            ),
            SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
            Expanded(
              child: _buildStatCard(
                title: currentLanguage == 'urdu' ? 'غیر محفوظ' : 'Unsynced',
                value: unsyncedCases.toString(),
                icon: Icons.sync_problem,
                color: Colors.red,
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return EnhancedCard(
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: ResponsiveUtils.getIconSize(context, 24),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getFontSize(context, 24),
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getFontSize(context, 12),
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
            ),
          ),

          // Hide suggestions shortly after focus leaves the search field
          Focus(
            focusNode: _searchFocusNode,
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                _liveResultsHideTimer?.cancel();
                final hasQuery = _searchController.text.trim().isNotEmpty;
                if (hasQuery && (_liveCaseResults.isNotEmpty || _liveLawResults.isNotEmpty || _liveAreaResults.isNotEmpty)) {
                  if (mounted) {
                    setState(() {
                      _showLiveResults = true;
                    });
                  }
                }
              } else {
                _liveResultsHideTimer?.cancel();
                _liveResultsHideTimer = Timer(const Duration(milliseconds: 250), () {
                  if (!mounted) return;
                  setState(() {
                    _showLiveResults = false;
                  });
                });
              }
            },
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarSection(bool isDarkMode, String currentLanguage) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingL)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
              borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: currentLanguage == 'urdu' 
                    ? 'قانونی وسائل تلاش کریں...'
                    : 'Search legal resources...',
                prefixIcon: Icon(
                  Icons.search,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
                suffixIcon: Icon(
                  Icons.filter_list,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingM),
                  vertical: ResponsiveUtils.getSpacing(context, AppTheme.spacingM),
                ),
                hintStyle: GoogleFonts.inter(
                  color: isDarkMode ? Colors.white60 : Colors.grey[500],
                ),
              ),
              style: GoogleFonts.inter(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              textInputAction: TextInputAction.search,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                final trimmed = value.trim();
                if (trimmed.isEmpty) {
                  setState(() {
                    _showLiveResults = false;
                    _liveCaseResults = [];
                    _liveLawResults = [];
                    _liveAreaResults = [];
                  });
                  _searchDebounce?.cancel();
                  _liveResultsHideTimer?.cancel();
                  return;
                }
                _scheduleLiveSearch(trimmed);
              },
              onSubmitted: (query) {
                final trimmed = query.trim();
                if (trimmed.isNotEmpty) {
                  setState(() {
                    _showLiveResults = false;
                  });
                  _performGlobalSearch(trimmed);
                }
              },
            ),
          ),

          if (_showLiveResults) ...[
            SizedBox(height: ResponsiveUtils.getSpacing(context, 8)),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_liveCaseResults.isNotEmpty) ...[
                      Text(
                        'Cases',
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getFontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, 6)),
                      ..._liveCaseResults.take(5).map((c) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.folder_open, color: AppTheme.primaryColor),
                            title: Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveUtils.getFontSize(context, 13),
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                              ),
                            ),
                            subtitle: Text(
                              '${c.caseNumber} • ${c.plaintiff} vs ${c.defendant}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveUtils.getFontSize(context, 11),
                                color: isDarkMode ? Colors.white70 : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _showLiveResults = false;
                              });
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CaseDetailScreen(caseId: c.id),
                                ),
                              );
                            },
                          )),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, 10)),
                    ],

                    if (_liveLawResults.isNotEmpty) ...[
                      Text(
                        'Laws & Documents',
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getFontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, 6)),
                      ..._liveLawResults.take(5).map((doc) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                            title: Text(
                              doc.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveUtils.getFontSize(context, 13),
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                              ),
                            ),
                            subtitle: Text(
                              doc.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveUtils.getFontSize(context, 11),
                                color: isDarkMode ? Colors.white70 : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _showLiveResults = false;
                              });
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => LibraryScreen(
                                    initialSearchQuery: doc.title,
                                    initialTabIndex: 0,
                                  ),
                                ),
                              );
                            },
                          )),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, 10)),
                    ],

                    if (_liveAreaResults.isNotEmpty) ...[
                      Text(
                        'Practice Areas',
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getFontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, 6)),
                      ..._liveAreaResults.take(5).map((area) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.local_library_outlined, color: AppTheme.primaryColor),
                            title: Text(
                              area.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveUtils.getFontSize(context, 13),
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                              ),
                            ),
                            subtitle: Text(
                              area.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveUtils.getFontSize(context, 11),
                                color: isDarkMode ? Colors.white70 : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _showLiveResults = false;
                              });
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PracticeAreaDetailScreen(practiceArea: area.name),
                                ),
                              );
                            },
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _performGlobalSearch(String query) async {
    final lowerQuery = query.toLowerCase();

    // Cases
    final caseState = ref.read(caseControllerProvider);
    final List<CaseModel> caseResults = caseState.cases.where((c) {
      return c.title.toLowerCase().contains(lowerQuery) ||
          c.caseNumber.toLowerCase().contains(lowerQuery) ||
          c.plaintiff.toLowerCase().contains(lowerQuery) ||
          c.defendant.toLowerCase().contains(lowerQuery) ||
          c.court.toLowerCase().contains(lowerQuery) ||
          (c.notes?.toLowerCase().contains(lowerQuery) ?? false) ||
          (c.lastNotePreview?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    // Laws / Documents
    final lawState = ref.read(lawLibraryProvider);
    final List<LawDocument> lawResults = lawState.documents.where((doc) {
      return doc.title.toLowerCase().contains(lowerQuery) ||
          doc.description.toLowerCase().contains(lowerQuery) ||
          doc.category.toLowerCase().contains(lowerQuery) ||
          doc.documentType.toLowerCase().contains(lowerQuery) ||
          doc.tags.any((t) => t.toLowerCase().contains(lowerQuery)) ||
          doc.content.toLowerCase().contains(lowerQuery);
    }).toList();

    // Practice Areas
    final areasAsync = ref.read(quickAccessAreasProvider);
    final List<PracticeAreaData> areasList =
        areasAsync.hasValue ? (areasAsync.value ?? <PracticeAreaData>[]) : <PracticeAreaData>[];
    final List<PracticeAreaData> areaResults = areasList.where((area) {
      return area.name.toLowerCase().contains(lowerQuery) ||
          area.description.toLowerCase().contains(lowerQuery);
    }).toList();

    _showSearchResultsSheet(query, caseResults, lawResults, areaResults);
  }

  Timer? _searchDebounce;
  Timer? _liveResultsHideTimer;
  bool _showLiveResults = false;
  List<CaseModel> _liveCaseResults = [];
  List<LawDocument> _liveLawResults = [];
  List<PracticeAreaData> _liveAreaResults = [];

  void _scheduleLiveSearch(String query) {
    _searchDebounce?.cancel();
    _liveResultsHideTimer?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _computeLiveResults(query);
    });
  }

  void _computeLiveResults(String query) {
    final lowerQuery = query.toLowerCase();

    final caseState = ref.read(caseControllerProvider);
    final caseResults = caseState.cases.where((c) {
      return c.title.toLowerCase().contains(lowerQuery) ||
          c.caseNumber.toLowerCase().contains(lowerQuery) ||
          c.plaintiff.toLowerCase().contains(lowerQuery) ||
          c.defendant.toLowerCase().contains(lowerQuery) ||
          c.court.toLowerCase().contains(lowerQuery) ||
          (c.notes?.toLowerCase().contains(lowerQuery) ?? false) ||
          (c.lastNotePreview?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    final lawState = ref.read(lawLibraryProvider);
    final lawResults = lawState.documents.where((doc) {
      return doc.title.toLowerCase().contains(lowerQuery) ||
          doc.description.toLowerCase().contains(lowerQuery) ||
          doc.category.toLowerCase().contains(lowerQuery) ||
          doc.documentType.toLowerCase().contains(lowerQuery) ||
          doc.tags.any((t) => t.toLowerCase().contains(lowerQuery)) ||
          doc.content.toLowerCase().contains(lowerQuery);
    }).toList();

    final areasAsync = ref.read(quickAccessAreasProvider);
    final List<PracticeAreaData> areasList =
        areasAsync.hasValue ? (areasAsync.value ?? <PracticeAreaData>[]) : <PracticeAreaData>[];
    final areaResults = areasList.where((area) {
      return area.name.toLowerCase().contains(lowerQuery) ||
          area.description.toLowerCase().contains(lowerQuery);
    }).toList();

    setState(() {
      _liveCaseResults = caseResults;
      _liveLawResults = lawResults;
      _liveAreaResults = areaResults;
      _showLiveResults = caseResults.isNotEmpty || lawResults.isNotEmpty || areaResults.isNotEmpty;
    });
  }

  void _showSearchResultsSheet(
    String query,
    List<CaseModel> caseResults,
    List<LawDocument> lawResults,
    List<PracticeAreaData> areaResults,
  ) {
    final isDarkMode = ref.read(themeProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: ResponsiveUtils.getSpacing(context, 16),
            right: ResponsiveUtils.getSpacing(context, 16),
            top: ResponsiveUtils.getSpacing(context, 16),
            bottom: MediaQuery.of(context).viewInsets.bottom + ResponsiveUtils.getSpacing(context, 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.search, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search results for "$query"',
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getFontSize(context, 18),
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (caseResults.isNotEmpty) ...[
                        Text(
                          'Cases (${caseResults.length})',
                          style: GoogleFonts.inter(
                            fontSize: ResponsiveUtils.getFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...caseResults.take(8).map((c) => ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              leading: const Icon(Icons.folder_open, color: AppTheme.primaryColor),
                              title: Text(
                                c.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: ResponsiveUtils.getFontSize(context, 14),
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                                ),
                              ),
                              subtitle: Text(
                                '${c.caseNumber} • ${c.plaintiff} vs ${c.defendant}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: ResponsiveUtils.getFontSize(context, 12),
                                  color: isDarkMode ? Colors.white70 : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                                ),
                              ),
                            )),
                        const SizedBox(height: 16),
                      ],

                      if (lawResults.isNotEmpty) ...[
                        Text(
                          'Laws & Documents (${lawResults.length})',
                          style: GoogleFonts.inter(
                            fontSize: ResponsiveUtils.getFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...lawResults.take(8).map((doc) => ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              leading: const Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                              title: Text(
                                doc.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: ResponsiveUtils.getFontSize(context, 14),
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                                ),
                              ),
                              subtitle: Text(
                                doc.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: ResponsiveUtils.getFontSize(context, 12),
                                  color: isDarkMode ? Colors.white70 : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                                ),
                              ),
                            )),
                        const SizedBox(height: 16),
                      ],

                      if (areaResults.isNotEmpty) ...[
                        Text(
                          'Practice Areas (${areaResults.length})',
                          style: GoogleFonts.inter(
                            fontSize: ResponsiveUtils.getFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...areaResults.take(8).map((area) => ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              leading: const Icon(Icons.local_library_outlined, color: AppTheme.primaryColor),
                              title: Text(
                                area.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: ResponsiveUtils.getFontSize(context, 14),
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                                ),
                              ),
                              subtitle: Text(
                                area.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: ResponsiveUtils.getFontSize(context, 12),
                                  color: isDarkMode ? Colors.white70 : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                                ),
                              ),
                            )),
                        const SizedBox(height: 8),
                      ],

                      if (caseResults.isEmpty && lawResults.isEmpty && areaResults.isEmpty) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No results found',
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveUtils.getFontSize(context, 14),
                                color: isDarkMode ? Colors.white70 : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturedResourcesSection(String currentLanguage) {
    final isDarkMode = ref.watch(themeProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getSpacing(context, 16),
          ),
          child: Text(
            currentLanguage == 'urdu' ? 'نمایاں قانونی وسائل' : 'Featured Legal Resources',
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
        SizedBox(
          height: ResponsiveUtils.getCardHeight(context, 200),
          width: MediaQuery.of(context).size.width,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getSpacing(context, 16),
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              final resources = [
                {
                  'title': currentLanguage == 'urdu' ? 'آئینی قانون' : 'Constitutional Law',
                  'icon': Icons.account_balance,
                  'color': Colors.blue,
                  'description': currentLanguage == 'urdu' ? '50+ مضامین' : '50+ Articles'
                },
                {
                  'title': currentLanguage == 'urdu' ? 'فوجداری قانون' : 'Criminal Law',
                  'icon': Icons.gavel,
                  'color': Colors.red,
                  'description': currentLanguage == 'urdu' ? '75+ کیسز' : '75+ Cases'
                },
                {
                  'title': currentLanguage == 'urdu' ? 'کاروباری قانون' : 'Business Law',
                  'icon': Icons.business,
                  'color': Colors.green,
                  'description': currentLanguage == 'urdu' ? '30+ گائیڈز' : '30+ Guides'
                },
                {
                  'title': currentLanguage == 'urdu' ? 'خاندانی قانون' : 'Family Law',
                  'icon': Icons.family_restroom,
                  'color': Colors.purple,
                  'description': currentLanguage == 'urdu' ? '40+ وسائل' : '40+ Resources'
                },
                {
                  'title': currentLanguage == 'urdu' ? 'املاک قانون' : 'Property Law',
                  'icon': Icons.home,
                  'color': Colors.orange,
                  'description': currentLanguage == 'urdu' ? '25+ دستاویز' : '25+ Documents'
                },
              ];
              
              final resource = resources[index];
              return Container(
                width: MediaQuery.of(context).size.width * 0.4,
                margin: EdgeInsets.only(
                  right: index < resources.length - 1 ? ResponsiveUtils.getSpacing(context, 12) : 0,
                ),
                child: _buildFeaturedResourceCard(
                  title: resource['title'] as String,
                  icon: resource['icon'] as IconData,
                  color: resource['color'] as Color,
                  description: resource['description'] as String,
                  isDarkMode: isDarkMode,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedResourceCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required bool isDarkMode,
  }) {
    return EnhancedCard(
      onTap: () {
        // Navigate to resource detail
      },
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 16)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(
                ResponsiveUtils.getSpacing(context, 8),
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, 8),
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveUtils.getIconSize(context, 24),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveUtils.getFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtils.getSpacing(context, 4)),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveUtils.getFontSize(context, 12),
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = ref.watch(themeProvider);
    
    return EnhancedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayScheduleSection(List<dynamic> hearings, String currentLanguage) {
    final isDarkMode = ref.watch(themeProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentLanguage == 'urdu' ? 'آج کا شیڈول' : 'Today\'s Schedule',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full schedule
              },
              child: Text(
                currentLanguage == 'urdu' ? 'سب دیکھیں' : 'View All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Column(
          children: hearings.take(3).map((hearing) => 
            _buildScheduleCard(hearing, currentLanguage)
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(dynamic hearing, String currentLanguage) {
    final isDarkMode = ref.watch(themeProvider);
    
    return EnhancedCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.schedule,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hearing.toString(), // Replace with actual hearing title
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentLanguage == 'urdu' ? 'آج 10:00 AM' : 'Today at 10:00 AM',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection(AsyncValue<List<PracticeAreaData>> quickAccessAreas, String currentLanguage) {
    final isDarkMode = ref.watch(themeProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getSpacing(context, 16),
          ),
          child: Text(
            currentLanguage == 'urdu' ? 'پریکٹس ایریاز' : 'Practice Areas',
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
        quickAccessAreas.when(
          data: (areas) => _buildQuickAccessGrid(areas, currentLanguage),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getSpacing(context, 16),
            ),
            child: Text(
              currentLanguage == 'urdu' ? 'ڈیٹا لوڈ کرنے میں خرابی' : 'Error loading data',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessGrid(List<PracticeAreaData> areas, String currentLanguage) {
    return SizedBox(
      height: ResponsiveUtils.getCardHeight(context, 240),
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getSpacing(context, 16),
        ),
        itemCount: areas.length,
        itemBuilder: (context, index) {
          return Container(
            width: ResponsiveUtils.getHorizontalCardWidth(context),
            margin: EdgeInsets.only(
              right: index < areas.length - 1 ? ResponsiveUtils.getSpacing(context, AppTheme.spacingM) : 0,
            ),
            child: _buildDynamicPracticeAreaCard(areas[index], index, currentLanguage),
          );
        },
      ),
    );
  }

  Widget _buildDynamicPracticeAreaCard(PracticeAreaData area, int index, String currentLanguage) {
    final isDarkMode = ref.watch(themeProvider);
    
    // Dynamic colors and icons for different practice areas
    final cardData = _getPracticeAreaCardData(area.name, index);
    
    return EnhancedCard(
      onTap: () {
        // Navigate to practice area detail
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardData['primaryColor'].withValues(alpha: 0.1),
              cardData['secondaryColor'].withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardData['primaryColor'].withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardData['secondaryColor'].withValues(alpha: 0.1),
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingL)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getHorizontalCardWidth(context) - ResponsiveUtils.getSpacing(context, AppTheme.spacingL) * 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon and badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 12)),
                          decoration: BoxDecoration(
                            color: cardData['primaryColor'].withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
                          ),
                          child: Icon(
                            cardData['icon'],
                            color: cardData['primaryColor'],
                            size: ResponsiveUtils.getIconSize(context, 28),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getSpacing(context, 8),
                              vertical: ResponsiveUtils.getSpacing(context, 4),
                            ),
                            decoration: BoxDecoration(
                              color: cardData['secondaryColor'].withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 8)),
                            ),
                            child: Text(
                              currentLanguage == 'urdu' ? 'فعال' : 'Active',
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveUtils.getFontSize(context, 10),
                                fontWeight: FontWeight.w600,
                                color: cardData['secondaryColor'],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
                    // Title
                    Text(
                      area.name,
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getFontSize(context, 18),
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
                    // Description
                    Text(
                      _getPracticeAreaDescription(area.name, currentLanguage),
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getFontSize(context, 12),
                        color: isDarkMode ? Colors.white70 : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
                    // Stats row
                    Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: ResponsiveUtils.getIconSize(context, 16),
                          color: cardData['primaryColor'],
                        ),
                        SizedBox(width: ResponsiveUtils.getSpacing(context, 4)),
                        Flexible(
                          child: Text(
                            '${(index + 1) * 15}+ ${currentLanguage == 'urdu' ? 'وسائل' : 'Resources'}',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveUtils.getFontSize(context, 11),
                              fontWeight: FontWeight.w500,
                              color: cardData['primaryColor'],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(child: SizedBox()),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: ResponsiveUtils.getIconSize(context, 14),
                          color: isDarkMode ? Colors.white60 : Colors.grey[600],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getPracticeAreaCardData(String areaName, int index) {
    final cardConfigs = [
      {
        'primaryColor': Colors.blue,
        'secondaryColor': Colors.lightBlue,
        'icon': Icons.account_balance,
      },
      {
        'primaryColor': Colors.red,
        'secondaryColor': Colors.pink,
        'icon': Icons.gavel,
      },
      {
        'primaryColor': Colors.green,
        'secondaryColor': Colors.lightGreen,
        'icon': Icons.business,
      },
      {
        'primaryColor': Colors.purple,
        'secondaryColor': Colors.deepPurple,
        'icon': Icons.family_restroom,
      },
      {
        'primaryColor': Colors.orange,
        'secondaryColor': Colors.deepOrange,
        'icon': Icons.home,
      },
    ];
    
    return cardConfigs[index % cardConfigs.length];
  }

  String _getPracticeAreaDescription(String areaName, String currentLanguage) {
    if (currentLanguage == 'urdu') {
      return 'تفصیلی قانونی رہنمائی اور وسائل';
    }
    return 'Comprehensive legal guidance and resources';
  }







  Widget _buildRecentActivitySection(List<CaseModel> recentCases, String currentLanguage) {
    final isDarkMode = ref.watch(themeProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentLanguage == 'urdu' ? 'حالیہ سرگرمی' : 'Recent Activity',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all activities
              },
              child: Text(
                currentLanguage == 'urdu' ? 'سب دیکھیں' : 'View All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Column(
          children: recentCases.take(3).map((caseModel) => 
            _buildRecentActivityCard(caseModel, currentLanguage)
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard(CaseModel caseModel, String currentLanguage) {
    final isDarkMode = ref.watch(themeProvider);
    
    return EnhancedCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      onTap: () {
        // Navigate to case detail
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.update,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caseModel.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppTheme.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentLanguage == 'urdu' ? 'حالیہ اپ ڈیٹ' : 'Recently updated',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
             _formatDate(caseModel.createdAt),
             style: GoogleFonts.inter(
               fontSize: 12,
               color: isDarkMode ? Colors.white60 : AppTheme.onSurfaceColor.withValues(alpha: 0.6),
             ),
           ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '$difference days ago';
    }
  }
}