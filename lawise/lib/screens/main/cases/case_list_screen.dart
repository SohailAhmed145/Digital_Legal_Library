import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../controllers/case_controller.dart';
import '../../../models/case_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/detail_bottom_sheet.dart';
import '../../../utils/responsive_utils.dart';
import 'add_case_screen.dart';
import 'case_detail_screen.dart';

class CasesScreen extends ConsumerStatefulWidget {
  const CasesScreen({super.key});

  @override
  ConsumerState<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends ConsumerState<CasesScreen> {
  final _searchController = TextEditingController();
  CaseStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    // Cases are automatically initialized by the case controller
    // No need to manually initialize
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(caseControllerProvider.notifier).setSearchQuery(query);
  }

  void _onStatusFilterChanged(CaseStatus? status) {
    setState(() {
      _selectedStatusFilter = status;
    });
    ref.read(caseControllerProvider.notifier).setStatusFilter(status);
  }

  void _clearFilters() {
    setState(() {
      _selectedStatusFilter = null;
    });
    _searchController.clear();
    ref.read(caseControllerProvider.notifier).setSearchQuery('');
    ref.read(caseControllerProvider.notifier).setStatusFilter(null);
  }

  void _showDeleteConfirmation(CaseModel caseModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Case'),
          content: Text('Are you sure you want to delete "${caseModel.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCase(caseModel.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCase(String caseId) async {
    final success = await ref.read(caseControllerProvider.notifier).deleteCase(caseId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Case deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(caseErrorProvider) ?? 'Failed to delete case'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(filteredCasesProvider);
    final isLoading = ref.watch(caseIsLoadingProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final syncStats = ref.watch(syncStatisticsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Cases',
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(context, 24),
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        actions: [
          // Sync status indicator
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getSpacing(context, AppTheme.radiusM),
              vertical: ResponsiveUtils.getSpacing(context, AppTheme.spacingS),
            ),
            margin: EdgeInsets.only(right: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
            decoration: BoxDecoration(
              color: isOnline ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 20)),
              border: Border.all(
                color: isOnline ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  size: ResponsiveUtils.getIconSize(context, 16),
                  color: isOnline ? Colors.green : Colors.orange,
                ),
                SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.spacingXS)),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context, 12),
                    color: isOnline ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search cases...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingM),
                      vertical: ResponsiveUtils.getSpacing(context, AppTheme.radiusM),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
                
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedStatusFilter == null,
                        onSelected: (_) => _onStatusFilterChanged(null),
                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.primaryColor,
                      ),
                      SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
                      ...CaseStatus.values.map((status) => Padding(
                        padding: EdgeInsets.only(right: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
                        child: FilterChip(
                          label: Text(status.displayName),
                          selected: _selectedStatusFilter == status,
                          onSelected: (_) => _onStatusFilterChanged(status),
                          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                          checkmarkColor: AppTheme.primaryColor,
                        ),
                      )),
                    ],
                  ),
                ),
                
                // Sync Statistics
                if (syncStats.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.getSpacing(context, 16)),
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.radiusM)),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 8)),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Total', syncStats['total'] ?? 0, Icons.folder),
                        _buildStatItem('Synced', syncStats['synced'] ?? 0, Icons.cloud_done, Colors.green),
                        _buildStatItem('Pending', syncStats['unsynced'] ?? 0, Icons.sync, Colors.orange),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Cases List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : cases.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(caseControllerProvider.notifier).refreshCases();
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, 16)),
                          itemCount: cases.length,
                          itemBuilder: (context, index) {
                            final caseModel = cases[index];
                            return _buildCaseCard(caseModel);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddCaseScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: Icon(Icons.add, color: Colors.white, size: ResponsiveUtils.getIconSize(context, 24)),
        label: Text(
          'Add Case',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.getFontSize(context, 14),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.primaryColor, size: ResponsiveUtils.getIconSize(context, 20)),
        SizedBox(height: ResponsiveUtils.getSpacing(context, 4)),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(context, 12),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: ResponsiveUtils.getIconSize(context, 80),
            color: Colors.grey[400],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, 16)),
          Text(
            'No cases found',
            style: TextStyle(
              fontSize: ResponsiveUtils.getFontSize(context, 20),
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
          Text(
            'Start by adding your first case',
            style: TextStyle(
              fontSize: ResponsiveUtils.getFontSize(context, 16),
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingL)),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddCaseScreen(),
                ),
              );
            },
            icon: Icon(Icons.add, size: ResponsiveUtils.getIconSize(context, 24)),
            label: Text('Add Case', style: TextStyle(fontSize: ResponsiveUtils.getFontSize(context, 14))),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingL),
                vertical: ResponsiveUtils.getSpacing(context, AppTheme.radiusM),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCard(CaseModel caseModel) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context, AppTheme.radiusM)),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12))),
      child: InkWell(
        onTap: () => BottomSheetHelper.showCaseDetails(context, caseModel),
        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      caseModel.title,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context, 18),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  // Sync status indicator
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingS),
                      vertical: ResponsiveUtils.getSpacing(context, AppTheme.spacingXS),
                    ),
                    decoration: BoxDecoration(
                      color: caseModel.isSynced 
                          ? Colors.green.withValues(alpha: 0.1) 
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          caseModel.isSynced ? Icons.cloud_done : Icons.sync,
                          size: ResponsiveUtils.getIconSize(context, 16),
                          color: caseModel.isSynced ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: ResponsiveUtils.getSpacing(context, 4)),
                        Text(
                          caseModel.isSynced ? 'Synced' : 'Pending',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getFontSize(context, 12),
                            color: caseModel.isSynced ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context, 8)),
              
              // Case details
              Row(
                children: [
                  Icon(Icons.gavel, size: ResponsiveUtils.getIconSize(context, 16), color: Colors.grey[600]),
                  SizedBox(width: ResponsiveUtils.getSpacing(context, 8)),
                  Expanded(
                    child: Text(
                      caseModel.court,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context, 14),
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingXS)),
              
              Row(
                children: [
                  Icon(Icons.people, size: ResponsiveUtils.getIconSize(context, 16), color: Colors.grey[600]),
                  SizedBox(width: ResponsiveUtils.getSpacing(context, 8)),
                  Expanded(
                    child: Text(
                      '${caseModel.plaintiff} vs ${caseModel.defendant}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context, 14),
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context, 4)),
              
              Row(
                children: [
                  Icon(Icons.schedule, size: ResponsiveUtils.getIconSize(context, 16), color: Colors.grey[600]),
                  SizedBox(width: ResponsiveUtils.getSpacing(context, 8)),
                  Expanded(
                    child: Text(
                      'Hearing: ${DateFormat('MMM dd, yyyy - hh:mm a').format(caseModel.hearingDate)}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context, 14),
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context, 8)),
              
              // Status and actions
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getSpacing(context, AppTheme.radiusM),
                      vertical: ResponsiveUtils.getSpacing(context, AppTheme.spacingS - AppTheme.spacingXS / 2),
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(caseModel.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 20)),
                      border: Border.all(
                        color: _getStatusColor(caseModel.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      caseModel.status.displayName,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context, 12),
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(caseModel.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // View details button
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CaseDetailScreen(caseId: caseModel.id),
                        ),
                      );
                    },
                    icon: Icon(Icons.visibility, color: AppTheme.primaryColor, size: ResponsiveUtils.getIconSize(context, 24)),
                    tooltip: 'View Details',
                  ),
                  
                  // Edit button
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddCaseScreen(caseToEdit: caseModel),
                        ),
                      );
                    },
                    icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: ResponsiveUtils.getIconSize(context, 24)),
                    tooltip: 'Edit Case',
                  ),
                  
                  // Delete button
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(caseModel),
                    icon: Icon(Icons.delete, color: Colors.red, size: ResponsiveUtils.getIconSize(context, 24)),
                    tooltip: 'Delete Case',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.draft:
        return Colors.grey;
      case CaseStatus.inProgress:
        return Colors.blue;
      case CaseStatus.closed:
        return Colors.green;
    }
  }
}
