import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/enhanced_card.dart';

class PracticeAreaDetailScreen extends ConsumerStatefulWidget {
  final String practiceArea;

  const PracticeAreaDetailScreen({
    super.key,
    required this.practiceArea,
  });

  @override
  ConsumerState<PracticeAreaDetailScreen> createState() => _PracticeAreaDetailScreenState();
}

class _PracticeAreaDetailScreenState extends ConsumerState<PracticeAreaDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTranslatedTitle(widget.practiceArea, currentLanguage),
          style: GoogleFonts.inter(
            fontSize: ResponsiveUtils.getFontSize(context, 18),
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(
              text: currentLanguage == 'urdu' ? 'قوانین' : 'Laws',
            ),
            Tab(
              text: currentLanguage == 'urdu' ? 'متعلقہ کیسز' : 'Related Cases',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLawsTab(),
          _buildRelatedCasesTab(),
        ],
      ),
    );
  }

  Widget _buildLawsTab() {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    final laws = _getLawsForPracticeArea(widget.practiceArea);

    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 16)),
      itemCount: laws.length,
      itemBuilder: (context, index) {
        final law = laws[index];
        return Padding(
          padding: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context, AppTheme.radiusM)),
          child: EnhancedCard(
            padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 8)),
                      ),
                      child: Icon(
                        Icons.gavel,
                        color: AppTheme.primaryColor,
                        size: ResponsiveUtils.getIconSize(context, 20),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.radiusM)),
                    Expanded(
                      child: Text(
                        currentLanguage == 'urdu' ? law['titleUrdu']! : law['title']!,
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getFontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.radiusM)),
                Text(
                  currentLanguage == 'urdu' ? law['descriptionUrdu']! : law['description']!,
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getFontSize(context, 14),
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingS),
                    vertical: ResponsiveUtils.getSpacing(context, AppTheme.spacingXS)
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
                  ),
                  child: Text(
                    law['section']!,
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveUtils.getFontSize(context, 12),
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRelatedCasesTab() {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    final cases = _getRelatedCases(widget.practiceArea);

    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 16)),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final case_ = cases[index];
        return Padding(
          padding: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context, 12)),
          child: EnhancedCard(
            padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 8)),
                      decoration: BoxDecoration(
                        color: _getStatusColor(case_['status']!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 8)),
                      ),
                      child: Icon(
                        Icons.folder_open,
                        color: _getStatusColor(case_['status']!),
                        size: ResponsiveUtils.getIconSize(context, 20),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getSpacing(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            case_['title']!,
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveUtils.getFontSize(context, 16),
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingXS)),
                          Text(
                            case_['client']!,
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveUtils.getFontSize(context, 14),
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getSpacing(context, 8),
                        vertical: ResponsiveUtils.getSpacing(context, 4)
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(case_['status']!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
                      ),
                      child: Text(
                        _getTranslatedStatus(case_['status']!, currentLanguage),
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getFontSize(context, 12),
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(case_['status']!),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
                Text(
                  case_['description']!,
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getFontSize(context, 14),
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: ResponsiveUtils.getIconSize(context, 16),
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                    SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.spacingXS)),
                    Text(
                      case_['date']!,
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getFontSize(context, 12),
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTranslatedTitle(String practiceArea, String language) {
    if (language == 'urdu') {
      switch (practiceArea) {
        case 'Civil Law':
          return 'سول قانون';
        case 'Criminal Law':
          return 'فوجداری قانون';
        case 'Corporate Law':
          return 'کارپوریٹ قانون';
        case 'Family Law':
          return 'خاندانی قانون';
        case 'Property Law':
          return 'جائیداد قانون';
        case 'Tax Law':
          return 'ٹیکس قانون';
        case 'Labor Law':
          return 'لیبر قانون';
        case 'Immigration':
          return 'امیگریشن';
        case 'Intellectual Property':
          return 'دانشورانہ املاک';
        default:
          return practiceArea;
      }
    }
    return practiceArea;
  }

  List<Map<String, String>> _getLawsForPracticeArea(String practiceArea) {
    // Mock data - in real app, this would come from a database
    switch (practiceArea) {
      case 'Civil Law':
        return [
          {
            'title': 'Civil Procedure Code 1908',
            'titleUrdu': 'سول پروسیجر کوڈ 1908',
            'description': 'Governs the procedure for civil litigation in courts',
            'descriptionUrdu': 'عدالتوں میں دیوانی مقدمات کی کارروائی کو کنٹرول کرتا ہے',
            'section': 'Section 1-158',
          },
          {
            'title': 'Contract Act 1872',
            'titleUrdu': 'کنٹریکٹ ایکٹ 1872',
            'description': 'Defines the law relating to contracts in Pakistan',
            'descriptionUrdu': 'پاکستان میں معاہدوں سے متعلق قانون کی تعریف کرتا ہے',
            'section': 'Section 1-238',
          },
        ];
      case 'Criminal Law':
        return [
          {
            'title': 'Pakistan Penal Code 1860',
            'titleUrdu': 'پاکستان پینل کوڈ 1860',
            'description': 'Main criminal code defining offenses and punishments',
            'descriptionUrdu': 'بنیادی فوجداری کوڈ جو جرائم اور سزاؤں کی تعریف کرتا ہے',
            'section': 'Section 1-511',
          },
          {
            'title': 'Code of Criminal Procedure 1898',
            'titleUrdu': 'کوڈ آف کرمنل پروسیجر 1898',
            'description': 'Governs the procedure for criminal cases',
            'descriptionUrdu': 'فوجداری مقدمات کی کارروائی کو کنٹرول کرتا ہے',
            'section': 'Section 1-565',
          },
        ];
      default:
        return [
          {
            'title': 'General Legal Provisions',
            'titleUrdu': 'عمومی قانونی دفعات',
            'description': 'Basic legal framework for this practice area',
            'descriptionUrdu': 'اس شعبے کے لیے بنیادی قانونی فریم ورک',
            'section': 'Various Sections',
          },
        ];
    }
  }

  List<Map<String, String>> _getRelatedCases(String practiceArea) {
    // Mock data - in real app, this would come from a database
    return [
      {
        'title': 'Sample Case vs. Defendant',
        'client': 'John Doe',
        'description': 'A complex case involving multiple legal aspects of $practiceArea',
        'status': 'Active',
        'date': '2024-01-15',
      },
      {
        'title': 'Another Case Matter',
        'client': 'Jane Smith',
        'description': 'Important precedent case in $practiceArea jurisdiction',
        'status': 'Completed',
        'date': '2023-12-20',
      },
      {
        'title': 'Recent Legal Matter',
        'client': 'ABC Corporation',
        'description': 'Corporate case involving $practiceArea regulations',
        'status': 'Pending',
        'date': '2024-01-10',
      },
    ];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTranslatedStatus(String status, String language) {
    if (language == 'urdu') {
      switch (status.toLowerCase()) {
        case 'active':
          return 'فعال';
        case 'completed':
          return 'مکمل';
        case 'pending':
          return 'زیر التواء';
        default:
          return status;
      }
    }
    return status;
  }
}