import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/law_library_provider.dart';
import '../../../models/law_library_model.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../widgets/profile_image_widget.dart';
import '../../../widgets/detail_bottom_sheet.dart';
import '../settings/settings_screen.dart';
import '../../../utils/responsive_utils.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;
  final int? initialTabIndex;

  const LibraryScreen({
    super.key,
    this.initialSearchQuery,
    this.initialTabIndex,
  });

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });

    if (widget.initialTabIndex != null) {
      _tabController.index = widget.initialTabIndex!.clamp(0, _tabController.length - 1);
      _selectedTabIndex = _tabController.index;
    }

    final initQuery = widget.initialSearchQuery;
    if (initQuery != null && initQuery.isNotEmpty) {
      _searchController.text = initQuery;
      _onSearchChanged(initQuery);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(lawLibraryProvider.notifier).setSearchQuery(query);
  }

  void _onCategoryChanged(String category) {
    ref.read(lawLibraryProvider.notifier).setSelectedCategory(category);
  }

  void _toggleBookmark(String documentId) {
    ref.read(lawLibraryProvider.notifier).toggleBookmark(documentId);
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(filteredLawDocumentsProvider);
    final categories = ref.watch(lawCategoriesProvider);
    final selectedCategory = ref.watch(lawLibraryProvider).selectedCategory;
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Section
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingL - AppTheme.spacingXS)),
              child: Column(
                children: [
                  // App Logo and User Profile Row
                  Row(
                    children: [
                      // App Logo
                      Text(
                        'Legal Library',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: ResponsiveUtils.getFontSize(context, 32),
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      // User Profile & Notifications
                      Row(
                        children: [
                          // Notification Bell
                          Container(
                            padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
                            decoration: BoxDecoration(
                              color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
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
                          SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.radiusM)),
                          // User Avatar
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            child: ProfileImageWidget(
                              size: ResponsiveUtils.getSpacing(context, 40),
                              borderWidth: 2,
                              showBorder: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingL - AppTheme.spacingXS)),
                  
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 16)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: ResponsiveUtils.getSpacing(context, 10),
                          offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: currentLanguage == 'urdu' ? 'قوانین، دستاویزات تلاش کریں...' : 'Search laws, documents...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getFontSize(context, 16),
                          color: isDarkMode ? Colors.grey[400] : const Color(0xFF9E9E9E),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDarkMode ? Colors.grey[400] : const Color(0xFF9E9E9E),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getSpacing(context, 20),
                          vertical: ResponsiveUtils.getSpacing(context, 16),
                        ),
                      ),
                      style: GoogleFonts.inter(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Tabs
            Container(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingL - AppTheme.spacingXS)),
              child: Row(
                children: [
                  _buildFilterTab('All', selectedCategory == 'All'),
                  SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
                  _buildFilterTab('Laws', selectedCategory == 'Laws'),
                  SizedBox(width: ResponsiveUtils.getSpacing(context, 16)),
                  _buildFilterTab('Documents', selectedCategory == 'Documents'),
                ],
              ),
            ),

            SizedBox(height: ResponsiveUtils.getSpacing(context, 20)),

            // Main Content
            Expanded(
              child: _buildLibraryContent(documents, categories),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isSelected) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    
    // Translate filter labels
    String translatedLabel = label;
    if (currentLanguage == 'urdu') {
      switch (label) {
        case 'All':
          translatedLabel = 'سب';
          break;
        case 'Laws':
          translatedLabel = 'قوانین';
          break;
        case 'Documents':
          translatedLabel = 'دستاویزات';
          break;
      }
    }
    
    return GestureDetector(
      onTap: () => _onCategoryChanged(label == 'All' ? 'All' : label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingL - AppTheme.spacingXS), vertical: ResponsiveUtils.getSpacing(context, AppTheme.radiusM)),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 20)),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : (isDarkMode ? Colors.grey[600]! : const Color(0xFFE0E0E0)),
            width: ResponsiveUtils.getSpacing(context, 1),
          ),
        ),
        child: Text(
          translatedLabel,
          style: GoogleFonts.inter(
            fontSize: ResponsiveUtils.getFontSize(context, 14),
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : (isDarkMode ? Colors.white : const Color(0xFF757575)),
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryContent(List<LawDocument> documents, List<LawCategory> categories) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    final selectedCategory = ref.watch(lawLibraryProvider).selectedCategory;
    
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh library data
        ref.read(lawLibraryProvider.notifier).refreshLibrary();
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Categories Horizontal List
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, 20)),
            child: Text(
              currentLanguage == 'urdu' ? 'اقسام' : 'Categories',
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getFontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
          
          SizedBox(
            height: ResponsiveUtils.getCardHeight(context, 50),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingL - AppTheme.spacingXS)),
              itemCount: categories.length + 1, // +1 for 'All' option
              itemBuilder: (context, index) {
                if (index == 0) {
                  // 'All' category chip
                  return Padding(
                    padding: EdgeInsets.only(right: ResponsiveUtils.getSpacing(context, AppTheme.radiusM)),
                    child: _buildAllCategoryChip(),
                  );
                }
                final category = categories[index - 1];
                return Padding(
                  padding: EdgeInsets.only(right: index < categories.length ? ResponsiveUtils.getSpacing(context, 12) : 0),
                  child: _buildCategoryChip(category),
                );
              },
            ),
          ),

          SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingXL)),

          // Documents List
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, 20)),
            child: Text(
              selectedCategory == 'All' 
                ? (currentLanguage == 'urdu' ? 'تمام دستاویزات' : 'All Documents')
                : (currentLanguage == 'urdu' ? '$selectedCategory دستاویزات' : '$selectedCategory Documents'),
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getFontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, 16)),
          
          if (documents.isEmpty)
            _buildEmptyState()
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, 20)),
              child: Column(
                children: documents.map((document) => _buildDocumentCard(document)).toList(),
              ),
            ),
          
          SizedBox(height: ResponsiveUtils.getSpacing(context, 32)),
        ],
      ),
      ),
    );
  }

  Widget _buildAllCategoryChip() {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    final selectedCategory = ref.watch(lawLibraryProvider).selectedCategory;
    final isSelected = selectedCategory == 'All';
    
    return GestureDetector(
      onTap: () => _onCategoryChanged('All'),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingM), vertical: ResponsiveUtils.getSpacing(context, AppTheme.radiusM)),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppTheme.primaryColor
            : (isDarkMode ? AppTheme.darkSurfaceColor : Colors.white),
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 25)),
          border: isSelected 
            ? null
            : Border.all(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                width: ResponsiveUtils.getSpacing(context, 1),
              ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: ResponsiveUtils.getSpacing(context, 8),
              offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.all_inclusive,
              color: isSelected 
                ? Colors.white
                : AppTheme.primaryColor,
              size: ResponsiveUtils.getIconSize(context, 18),
            ),
            SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
            Text(
              currentLanguage == 'urdu' ? 'تمام' : 'All',
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getFontSize(context, 14),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                  ? Colors.white
                  : (isDarkMode ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(LawCategory category) {
    final isDarkMode = ref.watch(themeProvider);
    final selectedCategory = ref.watch(lawLibraryProvider).selectedCategory;
    final color = Color(int.parse(category.colorHex.replaceAll('#', '0xFF')));
    final icon = _getIconFromName(category.iconName);
    final isSelected = selectedCategory == category.name;
    
    return GestureDetector(
      onTap: () => _onCategoryChanged(category.name),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, 16), vertical: ResponsiveUtils.getSpacing(context, 12)),
        decoration: BoxDecoration(
          color: isSelected 
            ? color
            : (isDarkMode ? AppTheme.darkSurfaceColor : Colors.white),
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 25)),
          border: isSelected 
            ? null
            : Border.all(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                width: 1,
              ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: ResponsiveUtils.getSpacing(context, 8),
              offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected 
                ? Colors.white
                : color,
              size: ResponsiveUtils.getIconSize(context, 18),
            ),
            SizedBox(width: ResponsiveUtils.getSpacing(context, 8)),
            Text(
              category.name,
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getFontSize(context, 14),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                  ? Colors.white
                  : (isDarkMode ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(LawCategory category) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    final selectedCategory = ref.watch(lawLibraryProvider).selectedCategory;
    final color = Color(int.parse(category.colorHex.replaceAll('#', '0xFF')));
    final icon = _getIconFromName(category.iconName);
    final isSelected = selectedCategory == category.name;
    
    return GestureDetector(
      onTap: () => _onCategoryChanged(category.name),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
            ? color.withValues(alpha: 0.1)
            : (isDarkMode ? AppTheme.darkSurfaceColor : Colors.white),
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 16)),
          border: isSelected 
            ? Border.all(color: color, width: ResponsiveUtils.getSpacing(context, 2))
            : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: ResponsiveUtils.getSpacing(context, 10),
              offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: ResponsiveUtils.getSpacing(context, 48),
              height: ResponsiveUtils.getSpacing(context, 48),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
              ),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveUtils.getIconSize(context, 24),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.radiusM)),
            Text(
              category.name,
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getFontSize(context, 14),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, 4)),
            Text(
              currentLanguage == 'urdu' 
                ? '${category.documentCount} دستاویزات'
                : '${category.documentCount} docs',
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getFontSize(context, 12),
                color: isDarkMode ? Colors.grey[300] : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(LawDocument document) {
    final isDarkMode = ref.watch(themeProvider);
    
    return GestureDetector(
      onTap: () => BottomSheetHelper.showLawDetails(context, document),
      child: Container(
        margin: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
        padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingL - AppTheme.spacingXS)),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: ResponsiveUtils.getSpacing(context, 10),
              offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveUtils.getFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
                  Text(
                    document.description,
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveUtils.getFontSize(context, 14),
                      color: isDarkMode ? Colors.grey[300] : const Color(0xFF757575),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, 8), vertical: ResponsiveUtils.getSpacing(context, 4)),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
                        ),
                        child: Text(
                          document.documentType,
                          style: GoogleFonts.inter(
                            fontSize: ResponsiveUtils.getFontSize(context, 12),
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.getSpacing(context, 8)),
                      Text(
                        _getTimeAgo(document.lastUpdated),
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getFontSize(context, 12),
                          color: isDarkMode ? Colors.grey[400] : const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _toggleBookmark(document.id),
              icon: Icon(
                document.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: document.isBookmarked ? AppTheme.primaryColor : (isDarkMode ? Colors.grey[400] : const Color(0xFF9E9E9E)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books,
            size: ResponsiveUtils.getIconSize(context, 80),
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, 16)),
          Text(
            currentLanguage == 'urdu' ? 'کوئی دستاویز نہیں ملی' : 'No documents found',
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getFontSize(context, 20),
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.grey[600],
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, 8)),
          Text(
            currentLanguage == 'urdu' 
              ? 'اپنی تلاش یا فلٹرز کو ایڈجسٹ کرنے کی کوشش کریں'
              : 'Try adjusting your search or filters',
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getFontSize(context, 16),
              color: isDarkMode ? Colors.grey[300] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'balance':
        return Icons.balance;
      case 'gavel':
        return Icons.gavel;
      case 'business':
        return Icons.business;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'home':
        return Icons.home;
      case 'eco':
        return Icons.eco;
      case 'work':
        return Icons.work;
      case 'account_balance':
        return Icons.account_balance;
      default:
        return Icons.description;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final currentLanguage = ref.read(languageProvider);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return currentLanguage == 'urdu' 
        ? '${difference.inDays} دن پہلے'
        : '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return currentLanguage == 'urdu' 
        ? '${difference.inHours} گھنٹے پہلے'
        : '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return currentLanguage == 'urdu' 
        ? '${difference.inMinutes} منٹ پہلے'
        : '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return currentLanguage == 'urdu' ? 'ابھی ابھی' : 'Just now';
    }
  }
  
  Widget _buildDefaultAvatar(bool isDarkMode) {
    return Container(
      color: isDarkMode ? AppTheme.darkBackgroundColor : const Color(0xFFE0E0E0),
      child: Icon(
        Icons.person,
        color: isDarkMode ? Colors.grey[400] : const Color(0xFF757575),
        size: ResponsiveUtils.getIconSize(context, 20),
      ),
    );
  }
}
