import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../widgets/simple_image_crop_widget.dart';
import '../../../services/data_persistence_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Uint8List? _pendingImageData; // Store cropped image temporarily
  bool _hasUnsavedImageChanges = false; // Track if image needs saving

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfile = ref.read(userProfileProvider);
      if (userProfile != null) {
        _nameController.text = userProfile.fullName;
        _emailController.text = userProfile.email;
        _selectedImagePath = userProfile.profileImagePath;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          currentLanguage == 'urdu' ? 'پروفائل میں ترمیم' : 'Edit Profile',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasUnsavedImageChanges 
                    ? Colors.orange 
                    : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: _hasUnsavedImageChanges ? 2 : 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      currentLanguage == 'urdu' ? 'محفوظ کریں' : 'Save',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _selectImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(
                            color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                                                 child: ClipRRect(
                           borderRadius: BorderRadius.circular(56),
                           child: _pendingImageData != null
                               ? Image.memory(
                                   _pendingImageData!,
                                   width: 120,
                                   height: 120,
                                   fit: BoxFit.cover,
                                 )
                               : Consumer(
                                   builder: (context, ref, child) {
                                     final userProfile = ref.watch(userProfileProvider);
                                     if (userProfile?.profileImagePath != null && userProfile!.profileImagePath!.isNotEmpty) {
                                       // Check if it's a Firebase URL
                                       if (userProfile.profileImagePath!.startsWith('http')) {
                                         return Image.network(
                                           userProfile.profileImagePath!,
                                           fit: BoxFit.cover,
                                           errorBuilder: (context, error, stackTrace) {
                                             return _buildDefaultAvatar();
                                           },
                                           loadingBuilder: (context, child, loadingProgress) {
                                             if (loadingProgress == null) return child;
                                             return Center(
                                               child: CircularProgressIndicator(
                                                 strokeWidth: 2,
                                                 value: loadingProgress.expectedTotalBytes != null
                                                     ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                     : null,
                                               ),
                                             );
                                           },
                                         );
                                       } else if (kIsWeb) {
                                         // For web, try to get local image data
                                         return FutureBuilder<Uint8List?>(
                                           future: _getWebImageData(),
                                           builder: (context, snapshot) {
                                             if (snapshot.hasData && snapshot.data != null) {
                                               return Image.memory(
                                                 snapshot.data!,
                                                 fit: BoxFit.cover,
                                                 errorBuilder: (context, error, stackTrace) {
                                                   return _buildDefaultAvatar();
                                                 },
                                               );
                                             } else if (snapshot.connectionState == ConnectionState.waiting) {
                                               return const Center(
                                                 child: CircularProgressIndicator(strokeWidth: 2),
                                               );
                                             } else {
                                               return _buildDefaultAvatar();
                                             }
                                           },
                                         );
                                       } else {
                                         // Mobile platforms
                                         return Image.file(
                                           File(userProfile.profileImagePath!),
                                           fit: BoxFit.cover,
                                           errorBuilder: (context, error, stackTrace) {
                                             return _buildDefaultAvatar();
                                           },
                                         );
                                       }
                                     } else {
                                       return _buildDefaultAvatar();
                                     }
                                   },
                                 ),
                         ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentLanguage == 'urdu' ? 'تصویر تبدیل کرنے کے لیے ٹیپ کریں' : 'Tap to change image',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[300] : const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Form Fields
              _buildFormField(
                controller: _nameController,
                label: currentLanguage == 'urdu' ? 'پورا نام' : 'Full Name',
                hint: currentLanguage == 'urdu' ? 'اپنا پورا نام درج کریں' : 'Enter your full name',
                icon: Icons.person_outline,
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 20),
              
              _buildFormField(
                controller: _emailController,
                label: currentLanguage == 'urdu' ? 'ای میل' : 'Email',
                hint: currentLanguage == 'urdu' ? 'اپنا ای میل درج کریں' : 'Enter your email',
                icon: Icons.email_outlined,
                isDarkMode: isDarkMode,
                enabled: false, // Email should be changed through verification
              ),
              
              const SizedBox(height: 32),
              
              // Additional Options
              _buildOptionTile(
                icon: Icons.lock_outline,
                title: currentLanguage == 'urdu' ? 'پاس ورڈ تبدیل کریں' : 'Change Password',
                subtitle: currentLanguage == 'urdu' ? 'اپنا پاس ورڈ تبدیل کریں' : 'Update your password',
                onTap: () => _showChangePasswordDialog(context),
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 16),
              
              _buildOptionTile(
                icon: Icons.email_outlined,
                title: currentLanguage == 'urdu' ? 'ای میل تبدیل کریں' : 'Change Email',
                subtitle: currentLanguage == 'urdu' ? 'اپنا ای میل تبدیل کریں' : 'Update your email address',
                onTap: () => _showChangeEmailDialog(context),
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE3F2FD),
            Color(0xFFBBDEFB),
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        color: Color(0xFF1976D2),
        size: 60,
      ),
    );
  }

  Future<Uint8List?> _getWebImageData() async {
    try {
      final persistenceService = await DataPersistenceService.getInstance();
      return persistenceService.getProfileImageData();
    } catch (e) {
      print('Error getting web image data: $e');
      return null;
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: isDarkMode ? Colors.grey[400] : const Color(0xFF9E9E9E),
            ),
            prefixIcon: Icon(
              icon,
              color: isDarkMode ? Colors.grey[400] : const Color(0xFF9E9E9E),
            ),
            filled: true,
            fillColor: isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
          style: GoogleFonts.inter(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[300] : const Color(0xFF757575),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      
      if (image != null) {
        // Get image bytes for cropping
        final imageBytes = await image.readAsBytes();
        
        if (mounted) {
          // Navigate to crop screen
          final result = await Navigator.of(context).push<Uint8List>(
            MaterialPageRoute(
              builder: (context) => SimpleImageCropWidget(
                imageData: imageBytes,
                title: ref.read(languageProvider) == 'urdu' ? 'تصویر کاٹیں' : 'Crop Image',
              ),
            ),
          );
          
          if (result != null && mounted) {
            // Store the cropped image temporarily - don't save yet
            setState(() {
              _pendingImageData = result;
              _hasUnsavedImageChanges = true;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ref.read(languageProvider) == 'urdu' 
                      ? 'تصویر منتخب ہو گئی - محفوظ کرنے کے لیے "محفوظ کریں" دبائیں'
                      : 'Image selected - tap "Save" to save changes'
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(languageProvider) == 'urdu'
                ? 'تصویر منتخب کرنے میں خرابی: $e'
                : 'Error selecting image: $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Save pending image data first if available
        if (_pendingImageData != null) {
          await ref.read(userProfileProvider.notifier).updateProfileImageData(_pendingImageData!);
        }
        
        // Update the profile with text data
        ref.read(userProfileProvider.notifier).updateProfile(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );
        
        // Clear pending changes
        setState(() {
          _pendingImageData = null;
          _hasUnsavedImageChanges = false;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(languageProvider) == 'urdu'
                ? 'پروفائل کامیابی سے محفوظ ہو گئی'
                : 'Profile saved successfully'
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(languageProvider) == 'urdu'
                ? 'پروفائل محفوظ کرنے میں خرابی: $e'
                : 'Error saving profile: $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentLanguage = ref.read(languageProvider);
    final TextEditingController verificationCodeController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isVerificationSent = false;
    bool isCodeVerified = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(currentLanguage == 'urdu' ? 'پاس ورڈ تبدیل کریں' : 'Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isVerificationSent) ...[
                Text(currentLanguage == 'urdu' 
                  ? 'پاس ورڈ تبدیل کرنے کے لیے، آپ کو اپنے ای میل پر تصدیقی کوڈ بھیجا جائے گا۔'
                  : 'To change your password, a verification code will be sent to your email.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isVerificationSent = true;
                    });
                    // TODO: Send verification code to email
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(currentLanguage == 'urdu' 
                          ? 'تصدیقی کوڈ بھیجا گیا ہے'
                          : 'Verification code sent'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text(currentLanguage == 'urdu' ? 'تصدیقی کوڈ بھیجیں' : 'Send Verification Code'),
                ),
              ] else if (!isCodeVerified) ...[
                Text(currentLanguage == 'urdu' 
                  ? 'اپنے ای میل پر بھیجے گئے تصدیقی کوڈ کو درج کریں'
                  : 'Enter the verification code sent to your email'),
                const SizedBox(height: 16),
                TextField(
                  controller: verificationCodeController,
                  decoration: InputDecoration(
                    labelText: currentLanguage == 'urdu' ? 'تصدیقی کوڈ' : 'Verification Code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (verificationCodeController.text.trim().isNotEmpty) {
                      setState(() {
                        isCodeVerified = true;
                      });
                      // TODO: Verify the code
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(currentLanguage == 'urdu' 
                            ? 'کوڈ تصدیق شدہ'
                            : 'Code verified'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Text(currentLanguage == 'urdu' ? 'تصدیق کریں' : 'Verify Code'),
                ),
              ] else ...[
                Text(currentLanguage == 'urdu' 
                  ? 'اپنا نیا پاس ورڈ درج کریں'
                  : 'Enter your new password'),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: currentLanguage == 'urdu' ? 'نیا پاس ورڈ' : 'New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: currentLanguage == 'urdu' ? 'پاس ورڈ کی تصدیق کریں' : 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(currentLanguage == 'urdu' ? 'منسوخ کریں' : 'Cancel'),
            ),
            if (isCodeVerified)
              TextButton(
                onPressed: () {
                  if (newPasswordController.text.trim().isNotEmpty &&
                      newPasswordController.text == confirmPasswordController.text) {
                    // TODO: Update password
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(currentLanguage == 'urdu' 
                          ? 'پاس ورڈ کامیابی سے تبدیل ہو گیا'
                          : 'Password changed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(currentLanguage == 'urdu' 
                          ? 'پاس ورڈز مماثل نہیں ہیں'
                          : 'Passwords do not match'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(currentLanguage == 'urdu' ? 'پاس ورڈ تبدیل کریں' : 'Change Password'),
              ),
          ],
        ),
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final currentLanguage = ref.read(languageProvider);
    final TextEditingController newEmailController = TextEditingController();
    final TextEditingController verificationCodeController = TextEditingController();
    bool isVerificationSent = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(currentLanguage == 'urdu' ? 'ای میل تبدیل کریں' : 'Change Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isVerificationSent) ...[
                Text(currentLanguage == 'urdu' 
                  ? 'اپنا نیا ای میل درج کریں'
                  : 'Enter your new email address'),
                const SizedBox(height: 16),
                TextField(
                  controller: newEmailController,
                  decoration: InputDecoration(
                    labelText: currentLanguage == 'urdu' ? 'نیا ای میل' : 'New Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ] else ...[
                Text(currentLanguage == 'urdu' 
                  ? 'اپنے ای میل پر بھیجے گئے تصدیقی کوڈ کو درج کریں'
                  : 'Enter the verification code sent to your email'),
                const SizedBox(height: 16),
                TextField(
                  controller: verificationCodeController,
                  decoration: InputDecoration(
                    labelText: currentLanguage == 'urdu' ? 'تصدیقی کوڈ' : 'Verification Code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(currentLanguage == 'urdu' ? 'منسوخ کریں' : 'Cancel'),
            ),
            if (!isVerificationSent)
              TextButton(
                onPressed: () {
                  if (newEmailController.text.trim().isNotEmpty) {
                    setState(() {
                      isVerificationSent = true;
                    });
                    // TODO: Send verification code to new email
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(currentLanguage == 'urdu' 
                          ? 'تصدیقی کوڈ بھیجا گیا ہے'
                          : 'Verification code sent'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text(currentLanguage == 'urdu' ? 'بھیجیں' : 'Send Code'),
              )
            else
              TextButton(
                onPressed: () {
                  if (verificationCodeController.text.trim().isNotEmpty) {
                    // TODO: Verify code and update email
                    ref.read(userProfileProvider.notifier).updateProfile(
                      email: newEmailController.text.trim(),
                    );
                    _emailController.text = newEmailController.text.trim();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(currentLanguage == 'urdu' 
                          ? 'ای میل کامیابی سے تبدیل ہو گیا'
                          : 'Email changed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text(currentLanguage == 'urdu' ? 'تصدیق کریں' : 'Verify'),
              ),
          ],
        ),
      ),
    );
  }
}
