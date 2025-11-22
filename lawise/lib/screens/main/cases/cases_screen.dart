import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../controllers/case_controller.dart';
import '../../../models/case_model.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../widgets/profile_image_widget.dart';
import '../../../widgets/enhanced_card.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../utils/responsive_utils.dart';
import '../settings/settings_screen.dart';
import 'add_case_screen.dart';

class CasesScreen extends ConsumerStatefulWidget {
  const CasesScreen({super.key});

  @override
  ConsumerState<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends ConsumerState<CasesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  CaseStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final casesAsync = ref.watch(casesProvider);
    final isLoading = ref.watch(caseIsLoadingProvider);
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Section
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 20)),
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
                            padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 8)),
                            decoration: BoxDecoration(
                              color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                              borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
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
                          SizedBox(width: ResponsiveUtils.getSpacing(context, 12)),
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
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, 20)),
                  
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 16)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: ResponsiveUtils.getSpacing(context, 10),
                          offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: currentLanguage == 'urdu' ? 'کیسز تلاش کریں...' : 'Search cases...',
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

            // Main Content
            Expanded(
              child: isLoading && casesAsync.isEmpty
                  ? _buildLoadingState(context)
                  : _buildCasesContent(context, casesAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCasesContent(BuildContext context, List<CaseModel> cases) {
    final isLoading = ref.watch(caseIsLoadingProvider);
    
    // Filter cases based on search query and status
    final filteredCases = cases.where((case_) {
      final matchesSearch = _searchQuery.isEmpty ||
          case_.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          case_.caseNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          case_.plaintiff.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          case_.defendant.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _selectedStatus == null || case_.status == _selectedStatus;
      
      return matchesSearch && matchesStatus;
    }).toList();

    if (filteredCases.isEmpty && !isLoading) {
      return _buildEmptyState();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: SingleChildScrollView(
        key: ValueKey('cases_loaded_${cases.length}'),
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Status Filter Chips
          if (cases.isNotEmpty) ...[
            SizedBox(
              height: ResponsiveUtils.getSpacing(context, 40),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStatusChip(null, 'All'),
                  SizedBox(width: ResponsiveUtils.getSpacing(context, 12)),
                  ...CaseStatus.values.map((status) => Padding(
                    padding: EdgeInsets.only(right: ResponsiveUtils.getSpacing(context, 12)),
                    child: _buildStatusChip(status, status.displayName),
                  )),
                ],
              ),
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, 20)),
          ],

            // Cases List
            ...filteredCases.map((case_) => _buildCaseCard(context, case_)),
            SizedBox(height: ResponsiveUtils.getSpacing(context, 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(CaseStatus? status, String label) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    final isSelected = _selectedStatus == status;
    
    // Translate status labels
    String translatedLabel = label;
    if (currentLanguage == 'urdu') {
      switch (label) {
        case 'All':
          translatedLabel = 'سب';
          break;
        case 'Draft':
          translatedLabel = 'ڈرافٹ';
          break;
        case 'In Progress':
          translatedLabel = 'جاری';
          break;
        case 'Closed':
          translatedLabel = 'بند';
          break;
      }
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = isSelected ? null : status;
        });
      },
      child: AnimatedContainer(
        duration: AppTheme.animationFast,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingM),
          vertical: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : (isDarkMode ? AppTheme.darkSurfaceColor : Colors.white),
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, AppTheme.radiusXL)),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : (isDarkMode ? Colors.grey[600]! : const Color(0xFFE0E0E0)),
            width: ResponsiveUtils.getSpacing(context, isSelected ? 2 : 1),
          ),
          boxShadow: isSelected ? AppTheme.shadowMedium : AppTheme.shadowLight,
        ),
        child: Text(
          translatedLabel,
          style: GoogleFonts.inter(
            fontSize: ResponsiveUtils.getFontSize(context, 14),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildCaseCard(BuildContext context, CaseModel case_) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddCaseScreen(caseToEdit: case_),
          ),
        );
      },
      child: EnhancedCard(
        margin: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
        padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  case_.title,
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingM),
                  vertical: ResponsiveUtils.getSpacing(context, AppTheme.spacingXS)
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(case_.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, AppTheme.radiusXL)),
                ),
                child: Text(
                  case_.status.displayName,
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getFontSize(context, 12),
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(case_.status),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
          Text(
            currentLanguage == 'urdu' ? 'کیس #${case_.caseNumber}' : 'Case #${case_.caseNumber}',
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getFontSize(context, 14),
              color: isDarkMode ? Colors.grey[300] : const Color(0xFF757575),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: ResponsiveUtils.getIconSize(context, 16),
                color: isDarkMode ? Colors.grey[400] : const Color(0xFF9E9E9E),
              ),
              SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.spacingXS)),
              Text(
                currentLanguage == 'urdu' 
                  ? 'اگلی سماعت: ${_formatDate(case_.hearingDate)}'
                  : 'Next Hearing: ${_formatDate(case_.hearingDate)}',
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getFontSize(context, 14),
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
          Wrap(
            spacing: ResponsiveUtils.getSpacing(context, 8),
            runSpacing: ResponsiveUtils.getSpacing(context, 8),
            children: [
              _buildCategoryChip(case_.category, _getCategoryColor(case_.category)),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: ResponsiveUtils.getIconSize(context, 16),
                color: isDarkMode ? Colors.grey[400] : const Color(0xFF9E9E9E),
              ),
              SizedBox(width: ResponsiveUtils.getSpacing(context, 6)),
              Text(
                currentLanguage == 'urdu' 
                  ? 'آخری اپ ڈیٹ: ${_getTimeAgo(case_.updatedAt)}'
                  : 'Last updated: ${_getTimeAgo(case_.updatedAt)}',
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getFontSize(context, 12),
                  color: isDarkMode ? Colors.grey[400] : const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddCaseScreen(caseToEdit: case_),
                    ),
                  );
                },
                icon: Icon(
                  Icons.edit,
                  color: AppTheme.primaryColor,
                  size: ResponsiveUtils.getIconSize(context, 20),
                ),
                tooltip: currentLanguage == 'urdu' ? 'ترمیم' : 'Edit',
              ),
              IconButton(
                onPressed: () => _showDeleteConfirmation(case_),
                icon: Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: ResponsiveUtils.getIconSize(context, 20),
                ),
                tooltip: currentLanguage == 'urdu' ? 'حذف' : 'Delete',
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildCategoryChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getSpacing(context, 12),
        vertical: ResponsiveUtils.getSpacing(context, 6)
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 16)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: ResponsiveUtils.getFontSize(context, 12),
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loading status chips
          SizedBox(
            height: ResponsiveUtils.getSpacing(context, 40),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(4, (index) => 
                Container(
                  margin: EdgeInsets.only(right: ResponsiveUtils.getSpacing(context, 12)),
                  child: ShimmerLoading(
                    child: Container(
                      width: 80 + (index * 20).toDouble(),
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, 20)),
          
          // Animated loading text
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0.3, end: 1.0),
            builder: (context, opacity, child) {
              return AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(milliseconds: 500),
                child: Text(
                  currentLanguage == 'urdu' 
                      ? 'کیسز لوڈ ہو رہے ہیں...' 
                      : 'Loading your cases...',
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getFontSize(context, 16),
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, 16)),
          
          // Shimmer case cards with staggered animation
          ...List.generate(5, (index) => 
            TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: const ShimmerCaseCard(),
                  ),
                );
              },
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getSpacing(context, 100)),
        ],
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
            Icons.folder_open,
            size: ResponsiveUtils.getIconSize(context, 80),
            color: isDarkMode ? Colors.grey[600] : const Color(0xFFE0E0E0),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, 20)),
          Text(
            currentLanguage == 'urdu' ? 'کوئی کیس نہیں ملا' : 'No Cases Found',
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getFontSize(context, 24),
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF757575),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, 8)),
          Text(
            currentLanguage == 'urdu' 
              ? 'اپنا پہلا کیس بنانے سے شروع کریں'
              : 'Start by creating your first case',
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getFontSize(context, 16),
              color: isDarkMode ? Colors.grey[300] : const Color(0xFF9E9E9E),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, 24)),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddCaseScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(currentLanguage == 'urdu' ? 'کیس بنائیں' : 'Create Case'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getSpacing(context, 24),
                vertical: ResponsiveUtils.getSpacing(context, 12)
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.draft:
        return const Color(0xFF9E9E9E);
      case CaseStatus.inProgress:
        return const Color(0xFF2E7D32);
      case CaseStatus.closed:
        return const Color(0xFF1976D2);
    }
  }

  String _formatDate(DateTime? date) {
    final currentLanguage = ref.read(languageProvider);
    
    if (date == null) return currentLanguage == 'urdu' ? 'شیڈول نہیں' : 'Not scheduled';
    
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays == 0) {
      return currentLanguage == 'urdu' ? 'آج' : 'Today';
    } else if (difference.inDays == 1) {
      return currentLanguage == 'urdu' ? 'کل' : 'Tomorrow';
    } else if (difference.inDays < 7) {
      return currentLanguage == 'urdu' 
        ? '${difference.inDays} دن'
        : '${difference.inDays} days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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

  void _showDeleteConfirmation(CaseModel caseModel) {
    final currentLanguage = ref.watch(languageProvider);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(currentLanguage == 'urdu' ? 'کیس حذف کریں' : 'Delete Case'),
          content: Text(
            currentLanguage == 'urdu' 
              ? 'کیا آپ واقعی "${caseModel.title}" کو حذف کرنا چاہتے ہیں؟ یہ عمل واپس نہیں ہو سکتا۔'
              : 'Are you sure you want to delete "${caseModel.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(currentLanguage == 'urdu' ? 'منسوخ' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCase(caseModel.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(currentLanguage == 'urdu' ? 'حذف' : 'Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCase(String caseId) async {
    final currentLanguage = ref.watch(languageProvider);
    final success = await ref.read(caseControllerProvider.notifier).deleteCase(caseId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'urdu' ? 'کیس کامیابی سے حذف ہو گیا' : 'Case deleted successfully',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'urdu' ? 'کیس حذف کرنے میں ناکامی' : 'Failed to delete case',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'civil law':
        return const Color(0xFF3498DB); // Blue
      case 'criminal law':
        return const Color(0xFFE74C3C); // Red
      case 'corporate law':
        return const Color(0xFF9B59B6); // Purple
      case 'family law':
        return const Color(0xFFE67E22); // Orange
      case 'property law':
        return const Color(0xFF27AE60); // Green
      case 'labor law':
        return const Color(0xFFF39C12); // Yellow-Orange
      case 'tax law':
        return const Color(0xFF34495E); // Dark Blue-Gray
      case 'constitutional law':
        return const Color(0xFF8E44AD); // Dark Purple
      case 'intellectual property law':
        return const Color(0xFF16A085); // Teal
      case 'environmental law':
        return const Color(0xFF2ECC71); // Light Green
      default:
        return const Color(0xFF95A5A6); // Gray for unknown categories
    }
  }
}
