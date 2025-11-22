import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../controllers/case_controller.dart';
import '../../../models/case_model.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive_utils.dart';

class AddCaseScreen extends ConsumerStatefulWidget {
  final CaseModel? caseToEdit;
  
  const AddCaseScreen({super.key, this.caseToEdit});

  @override
  ConsumerState<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends ConsumerState<AddCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _plaintiffController = TextEditingController();
  final _defendantController = TextEditingController();
  final _caseNumberController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedCourt;
  String _selectedCategory = CaseCategories.getDefaultCategory();
  CaseStatus _selectedStatus = CaseStatus.draft;
  DateTime? _selectedHearingDate;
  TimeOfDay? _selectedHearingTime;
  
  final List<String> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.caseToEdit != null) {
      final caseData = widget.caseToEdit!;
      _titleController.text = caseData.title;
      _plaintiffController.text = caseData.plaintiff;
      _defendantController.text = caseData.defendant;
      _caseNumberController.text = caseData.caseNumber;
      _notesController.text = caseData.notes ?? '';
      _selectedCourt = caseData.court;
      _selectedCategory = caseData.category;
      _selectedStatus = caseData.status;
      _selectedHearingDate = caseData.hearingDate;
      _selectedHearingTime = TimeOfDay.fromDateTime(caseData.hearingDate);
      _attachedFiles.addAll(caseData.attachmentPaths);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _plaintiffController.dispose();
    _defendantController.dispose();
    _caseNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedHearingDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedHearingDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedHearingTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedHearingTime = picked;
      });
    }
  }

  Future<void> _addFile() async {
    // Simulate file picker
    setState(() {
      _attachedFiles.add('Document_${_attachedFiles.length + 1}.pdf');
    });
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  Future<void> _saveCase() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedHearingDate == null || _selectedHearingTime == null) {
      String message;
      if (_selectedHearingDate == null && _selectedHearingTime == null) {
        message = 'Please select both hearing date and time';
      } else if (_selectedHearingDate == null) {
        message = 'Please select a hearing date';
      } else {
        message = 'Please select a hearing time';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.white,
                size: ResponsiveUtils.getIconSize(context, 20),
              ),
              SizedBox(width: ResponsiveUtils.getSpacing(context, 8)),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getFontSize(context, 14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, AppTheme.radiusM)),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final hearingDateTime = DateTime(
      _selectedHearingDate!.year,
      _selectedHearingDate!.month,
      _selectedHearingDate!.day,
      _selectedHearingTime!.hour,
      _selectedHearingTime!.minute,
    );

    try {
      bool success;
      String successMessage;
      String errorMessage;
      
      if (widget.caseToEdit != null) {
        // Update existing case
        final updatedCase = widget.caseToEdit!.copyWith(
          title: _titleController.text.trim(),
          plaintiff: _plaintiffController.text.trim(),
          defendant: _defendantController.text.trim(),
          caseNumber: _caseNumberController.text.trim(),
          court: _selectedCourt ?? '',
          category: _selectedCategory,
          hearingDate: hearingDateTime,
          status: _selectedStatus,
          notes: _notesController.text.trim(),
          attachmentPaths: _attachedFiles,
          updatedAt: DateTime.now(),
        );
        
        success = await ref.read(caseControllerProvider.notifier).updateCase(updatedCase);
        successMessage = 'Case updated successfully!';
        errorMessage = 'Failed to update case';
      } else {
        // Create new case
        success = await ref.read(caseControllerProvider.notifier).createCase(
          title: _titleController.text.trim(),
          plaintiff: _plaintiffController.text.trim(),
          defendant: _defendantController.text.trim(),
          caseNumber: _caseNumberController.text.trim(),
          court: _selectedCourt ?? '',
          category: _selectedCategory,
          hearingDate: hearingDateTime,
          status: _selectedStatus,
          notes: _notesController.text.trim(),
          attachmentPaths: _attachedFiles,
        );
        successMessage = 'Case created successfully!';
        errorMessage = 'Failed to create case';
      }
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, AppTheme.radiusM)),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.caseToEdit != null ? "Failed to update" : "Failed to create"} case: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, AppTheme.radiusM)),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.caseToEdit != null ? 'Edit Case' : 'Add Case',
          style: GoogleFonts.inter(
            fontSize: ResponsiveUtils.getFontSize(context, 20),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Case Title Section
              _buildSectionTitle('Case Title'),
              SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
              _buildTextField(
                controller: _titleController,
                hintText: 'Enter case title',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter case title';
                  }
                  return null;
                },
              ),

              SizedBox(height: ResponsiveUtils.getSpacing(context, 24)),

              // Parties Section
              _buildSectionTitle('Parties'),
              SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _plaintiffController,
                      hintText: 'Plaintiff',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter plaintiff';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.getSpacing(context, 16)),
                  Expanded(
                    child: _buildTextField(
                      controller: _defendantController,
                      hintText: 'Defendant',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter defendant';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: ResponsiveUtils.getSpacing(context, 24)),

              // Case Number Section
              _buildSectionTitle('Case Number'),
              SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
              _buildTextField(
                controller: _caseNumberController,
                hintText: 'Enter case number',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter case number';
                  }
                  return null;
                },
              ),

              SizedBox(height: ResponsiveUtils.getSpacing(context, 24)),

              // Case Category Section
              _buildSectionTitle('Case Category'),
              SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
              _buildCategoryDropdown(),

              SizedBox(height: ResponsiveUtils.getSpacing(context, 24)),

              // Hearing Date & Time Section
              _buildSectionTitle('Hearing Date & Time'),
              SizedBox(height: ResponsiveUtils.getSpacing(context, 8)),
              Text(
                'Select the date and time for the next hearing',
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getFontSize(context, 14),
                  color: const Color(0xFF666666),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
              Row(
                children: [
                  // Date Picker
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getSpacing(context, 16),
                          vertical: ResponsiveUtils.getSpacing(context, 16)
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
                          border: Border.all(
                            color: _selectedHearingDate != null 
                                ? AppTheme.primaryColor 
                                : const Color(0xFFE0E0E0),
                            width: _selectedHearingDate != null ? ResponsiveUtils.getSpacing(context, 2) : ResponsiveUtils.getSpacing(context, 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: _selectedHearingDate != null 
                                  ? AppTheme.primaryColor 
                                  : const Color(0xFF9E9E9E),
                              size: ResponsiveUtils.getIconSize(context, 20),
                            ),
                            SizedBox(width: ResponsiveUtils.getSpacing(context, 12)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hearing Date',
                                    style: GoogleFonts.inter(
                                      fontSize: ResponsiveUtils.getFontSize(context, 12),
                                      color: const Color(0xFF666666),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveUtils.getSpacing(context, 2)),
                                  Text(
                                    _selectedHearingDate != null
                                        ? DateFormat('MMM dd, yyyy').format(_selectedHearingDate!)
                                        : 'Select date',
                                    style: GoogleFonts.inter(
                                      fontSize: ResponsiveUtils.getFontSize(context, 16),
                                      color: _selectedHearingDate != null 
                                          ? Colors.black 
                                          : const Color(0xFF9E9E9E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Time Picker
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedHearingTime != null 
                                ? AppTheme.primaryColor 
                                : const Color(0xFFE0E0E0),
                            width: _selectedHearingTime != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: _selectedHearingTime != null 
                                  ? AppTheme.primaryColor 
                                  : const Color(0xFF9E9E9E),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hearing Time',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF666666),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedHearingTime != null
                                        ? _selectedHearingTime!.format(context)
                                        : 'Select time',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: _selectedHearingTime != null 
                                          ? Colors.black 
                                          : const Color(0xFF9E9E9E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Quick Time Suggestions
              if (_selectedHearingDate != null && _selectedHearingTime == null) ...[
                const SizedBox(height: 12),
                Text(
                  'Quick time suggestions:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildQuickTimeChip('9:00 AM', const TimeOfDay(hour: 9, minute: 0)),
                    _buildQuickTimeChip('10:00 AM', const TimeOfDay(hour: 10, minute: 0)),
                    _buildQuickTimeChip('11:00 AM', const TimeOfDay(hour: 11, minute: 0)),
                    _buildQuickTimeChip('2:00 PM', const TimeOfDay(hour: 14, minute: 0)),
                    _buildQuickTimeChip('3:00 PM', const TimeOfDay(hour: 15, minute: 0)),
                    _buildQuickTimeChip('4:00 PM', const TimeOfDay(hour: 16, minute: 0)),
                  ],
                ),
              ],
              
              // Success Indicator
              if (_selectedHearingDate != null && _selectedHearingTime != null) ...[
                const SizedBox(height: 12),
                Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: Colors.green.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(
                       color: Colors.green.withOpacity(0.3),
                     ),
                   ),
                   child: Row(
                     children: [
                       const Icon(
                         Icons.check_circle,
                         color: Colors.green,
                         size: 20,
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           'Hearing scheduled for ${DateFormat('MMM dd, yyyy').format(_selectedHearingDate!)} at ${_selectedHearingTime!.format(context)}',
                           style: GoogleFonts.inter(
                             fontSize: 14,
                             color: Colors.green.shade700,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
               ],

              const SizedBox(height: 24),

              // Status Section
              _buildSectionTitle('Status'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CaseStatus>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: CaseStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Case Details Section
              _buildSectionTitle('Case Details'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _notesController,
                hintText: 'Enter case details and notes',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter case details';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Attached Documents Section
              _buildSectionTitle('Attached Documents'),
              const SizedBox(height: 12),
              
              // File List
              if (_attachedFiles.isNotEmpty) ...[
                ..._attachedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final fileName = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // File Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53E3E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'PDF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // File Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Added ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Options Menu
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Color(0xFF9E9E9E),
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _removeFile(index);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Add File Button
              GestureDetector(
                onTap: _addFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.add,
                        size: 32,
                        color: Color(0xFF9E9E9E),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add File',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveCase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.caseToEdit != null ? 'Update Case' : 'Save Case',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          color: const Color(0xFF9E9E9E),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildQuickTimeChip(String label, TimeOfDay time) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHearingTime = time;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          hint: Text(
            'Select Category',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF9E9E9E),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.black,
          ),
          items: CaseCategories.categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
              });
            }
          },
        ),
      ),
    );
  }
}
