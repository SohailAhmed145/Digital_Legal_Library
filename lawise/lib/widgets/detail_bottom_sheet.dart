import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../models/case_model.dart';
import '../models/law_library_model.dart';
import '../screens/main/cases/case_detail_screen.dart';

class DetailBottomSheet extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final String description;
  final Map<String, String>? additionalInfo;
  final Widget? customContent;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final IconData? icon;
  final Color? iconColor;

  const DetailBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.description,
    this.additionalInfo,
    this.customContent,
    this.onActionPressed,
    this.actionLabel,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon!,
                            color: iconColor ?? AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Description
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.5,
                      color: isDarkMode ? Colors.grey[200] : Colors.grey[700],
                    ),
                  ),
                  
                  // Additional info
                  if (additionalInfo != null && additionalInfo!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ...additionalInfo!.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              entry.key,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  
                  // Custom content
                  if (customContent != null) ...[
                    const SizedBox(height: 24),
                    customContent!,
                  ],
                  
                  // Action button
                  if (onActionPressed != null && actionLabel != null) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onActionPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          actionLabel!,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Bottom padding for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper functions to show bottom sheets for specific content types
class BottomSheetHelper {
  static void showCaseDetails(BuildContext context, CaseModel caseModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetailBottomSheet(
        title: caseModel.title,
        subtitle: 'Case #${caseModel.caseNumber}',
        description: caseModel.notes ?? 'No additional notes available for this case.',
        icon: Icons.folder_open,
        iconColor: _getCaseStatusColor(caseModel.status),
        additionalInfo: {
          'Plaintiff': caseModel.plaintiff,
          'Defendant': caseModel.defendant,
          'Court': caseModel.court,
          'Status': _getCaseStatusText(caseModel.status),
          'Created': _formatDate(caseModel.createdAt),
          'Last Updated': _formatDate(caseModel.updatedAt),
        },
        actionLabel: 'View Full Details',
        onActionPressed: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CaseDetailScreen(caseId: caseModel.id),
            ),
          );
        },
      ),
    );
  }
  
  static void showLawDetails(BuildContext context, LawDocument document) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetailBottomSheet(
        title: document.title,
        subtitle: document.documentType,
        description: document.description,
        icon: Icons.gavel,
        iconColor: AppTheme.primaryColor,
        additionalInfo: {
          'Category': document.category,
          'Document Type': document.documentType,
          'Last Updated': _formatDate(document.lastUpdated),
          'Bookmarked': document.isBookmarked ? 'Yes' : 'No',
        },
        actionLabel: 'Read Full Document',
        onActionPressed: () {
          Navigator.pop(context);
          // TODO: Navigate to full document viewer when implemented
        },
      ),
    );
  }
  
  static Color _getCaseStatusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.draft:
        return Colors.grey;
      case CaseStatus.inProgress:
        return Colors.blue;
      case CaseStatus.closed:
        return Colors.green;
    }
  }
  
  static String _getCaseStatusText(CaseStatus status) {
    switch (status) {
      case CaseStatus.draft:
        return 'Draft';
      case CaseStatus.inProgress:
        return 'In Progress';
      case CaseStatus.closed:
        return 'Closed';
    }
  }
  
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}