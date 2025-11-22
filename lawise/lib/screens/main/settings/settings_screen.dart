import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/profile_image_widget.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../utils/responsive_utils.dart';
import '../profile/edit_profile_screen.dart';
import '../../auth/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoSyncEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    final userProfile = ref.watch(userProfileProvider);
    
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
          currentLanguage == 'urdu' ? 'ترتیبات' : 'Settings',
          style: GoogleFonts.inter(
            fontSize: ResponsiveUtils.getFontSize(context, 20),
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: isDarkMode ? Colors.grey[300] : Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfileData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingL - AppTheme.spacingXS)),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Profile Section
            _buildProfileSection(isDarkMode, currentLanguage),
            
            SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingL)),
            
                         // Account Settings
             _buildSectionHeader(currentLanguage == 'urdu' ? 'اکاؤنٹ کی ترتیبات' : 'Account Settings'),
             _buildSettingsCard(
               userProfile == null 
                 ? List.generate(3, (index) => const ShimmerSettingsItem())
                 : [
                   _buildSettingItem(
                     icon: Icons.person_outline,
                     title: currentLanguage == 'urdu' ? 'پروفائل میں ترمیم' : 'Edit Profile',
                     subtitle: currentLanguage == 'urdu' ? 'اپنی ذاتی معلومات اپ ڈیٹ کریں' : 'Update your personal information',
                     trailing: Icon(Icons.arrow_forward_ios, size: ResponsiveUtils.getIconSize(context, 16)),
                     onTap: () => _navigateToEditProfile(context),
                   ),
                   _buildDivider(),
                   _buildSettingItem(
                     icon: Icons.email_outlined,
                     title: currentLanguage == 'urdu' ? 'ای میل تبدیل کریں' : 'Change Email',
                     subtitle: userProfile.email.isNotEmpty ? userProfile.email : 'No email',
                     trailing: Icon(Icons.arrow_forward_ios, size: ResponsiveUtils.getIconSize(context, 16)),
                     onTap: () => _showChangeEmailDialog(context),
                   ),
                   _buildDivider(),
                   _buildSettingItem(
                     icon: Icons.lock_outline,
                     title: currentLanguage == 'urdu' ? 'پاس ورڈ تبدیل کریں' : 'Change Password',
                     subtitle: currentLanguage == 'urdu' ? 'آخری بار 3 ماہ پہلے تبدیل کیا گیا' : 'Last changed 3 months ago',
                     trailing: Icon(Icons.arrow_forward_ios, size: ResponsiveUtils.getIconSize(context, 16)),
                     onTap: () => _showChangePasswordDialog(context),
                   ),
                 ],
             ),
            
            SizedBox(height: ResponsiveUtils.getSpacing(context, 24)),
            
            // Preferences
            _buildSectionHeader(currentLanguage == 'urdu' ? 'ترجیحات' : 'Preferences'),
            _buildSettingsCard([
              _buildSwitchItem(
                icon: Icons.dark_mode_outlined,
                title: currentLanguage == 'urdu' ? 'ڈارک موڈ' : 'Dark Mode',
                subtitle: currentLanguage == 'urdu' ? 'لائٹ اور ڈارک تھیمز کے درمیان سوئچ کریں' : 'Switch between light and dark themes',
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
              _buildDivider(),
              _buildSwitchItem(
                icon: Icons.sync,
                title: currentLanguage == 'urdu' ? 'خودکار سنک' : 'Auto Sync',
                subtitle: currentLanguage == 'urdu' ? 'آن لائن ہونے پر خودکار طور پر ڈیٹا سنک کریں' : 'Automatically sync data when online',
                value: _autoSyncEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoSyncEnabled = value;
                  });
                },
              ),
            ]),
            
            SizedBox(height: ResponsiveUtils.getSpacing(context, 24)),
            
            // App Settings
            _buildSectionHeader(currentLanguage == 'urdu' ? 'ایپ کی ترتیبات' : 'App Settings'),
            _buildSettingsCard([
              _buildSettingItem(
                icon: Icons.language,
                title: currentLanguage == 'urdu' ? 'زبان' : 'Language',
                subtitle: currentLanguage == 'urdu' ? 'اردو' : 'English',
                trailing: Icon(Icons.arrow_forward_ios, size: ResponsiveUtils.getIconSize(context, 16)),
                onTap: () => _showLanguageSelector(context, currentLanguage),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.storage,
                title: currentLanguage == 'urdu' ? 'اسٹوریج اور کیشے' : 'Storage & Cache',
                subtitle: currentLanguage == 'urdu' ? 'ایپ ڈیٹا اور کیشے صاف کریں' : 'Clear app data and cache',
                trailing: Icon(Icons.arrow_forward_ios, size: ResponsiveUtils.getIconSize(context, 16)),
                onTap: () => _showStorageOptions(context),
              ),
            ]),
            
            SizedBox(height: ResponsiveUtils.getSpacing(context, 24)),
            
            // Support & Legal
            _buildSectionHeader(currentLanguage == 'urdu' ? 'مدد اور قانونی' : 'Support & Legal'),
            _buildSettingsCard([
              _buildSettingItem(
                icon: Icons.help_outline,
                title: currentLanguage == 'urdu' ? 'مدد اور سپورٹ' : 'Help & Support',
                subtitle: currentLanguage == 'urdu' ? 'ایپ کے ساتھ مدد حاصل کریں' : 'Get help with the app',
                trailing: Icon(Icons.arrow_forward_ios, size: ResponsiveUtils.getIconSize(context, 16)),
                onTap: () {},
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.feedback_outlined,
                title: currentLanguage == 'urdu' ? 'فیڈبیک بھیجیں' : 'Send Feedback',
                subtitle: currentLanguage == 'urdu' ? 'ایپ کو بہتر بنانے میں ہماری مدد کریں' : 'Help us improve the app',
                trailing: Icon(Icons.arrow_forward_ios, size: ResponsiveUtils.getIconSize(context, 16)),
                onTap: () {},
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.description_outlined,
                title: currentLanguage == 'urdu' ? 'سروس کی شرائط' : 'Terms of Service',
                subtitle: currentLanguage == 'urdu' ? 'ہماری شرائط اور شرائط پڑھیں' : 'Read our terms and conditions',
                trailing: Icon(Icons.arrow_forward_ios, size: ResponsiveUtils.getIconSize(context, 16)),
                onTap: () {},
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.privacy_tip_outlined,
                title: currentLanguage == 'urdu' ? 'رازداری کی پالیسی' : 'Privacy Policy',
                subtitle: currentLanguage == 'urdu' ? 'ہم اپنے ڈیٹا کو کیسے سنبھالتے ہیں' : 'How we handle your data',
                trailing: Icon(Icons.arrow_forward_ios, size: ResponsiveUtils.getIconSize(context, 16)),
                onTap: () {},
              ),
            ]),
            
            SizedBox(height: ResponsiveUtils.getSpacing(context, 24)),
            
            // App Info
            _buildSectionHeader(currentLanguage == 'urdu' ? 'ایپ کی معلومات' : 'App Info'),
            _buildSettingsCard([
              _buildSettingItem(
                icon: Icons.info_outline,
                title: currentLanguage == 'urdu' ? 'ورژن' : 'Version',
                subtitle: '1.0.0 (Build 2024.1)',
                trailing: null,
                onTap: null,
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.update,
                title: currentLanguage == 'urdu' ? 'اپ ڈیٹس کے لیے چیک کریں' : 'Check for Updates',
                subtitle: currentLanguage == 'urdu' ? 'تازہ ترین ورژن دستیاب ہے' : 'Latest version available',
                trailing: Icon(Icons.arrow_forward_ios, size: ResponsiveUtils.getIconSize(context, 16)),
                onTap: () {},
              ),
            ]),
            
            SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingXL)),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: ResponsiveUtils.getSpacing(context, 56),
              child: ElevatedButton(
                onPressed: () => _showLogoutConfirmation(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 16)),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  currentLanguage == 'urdu' ? 'لاگ آؤٹ' : 'Logout',
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getFontSize(context, 18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingL - AppTheme.spacingXS)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isDarkMode, String currentLanguage) {
    final userProfile = ref.watch(userProfileProvider);
    
    // Show shimmer loading if profile is not loaded yet
    if (userProfile == null) {
      return const ShimmerProfileCard();
    }
    
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 20)),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 20)),
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
          GestureDetector(
            onTap: () => _navigateToEditProfile(context),
            child: Container(
              width: ResponsiveUtils.getSpacing(context, 60),
              height: ResponsiveUtils.getSpacing(context, 60),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 30)),
                border: Border.all(color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white, width: ResponsiveUtils.getSpacing(context, 3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: ResponsiveUtils.getSpacing(context, 10),
                    offset: Offset(0, ResponsiveUtils.getSpacing(context, 5)),
                  ),
                ],
              ),
              child: ProfileImageWidget(
                size: ResponsiveUtils.getSpacing(context, 54),
                borderWidth: 0,
                showBorder: false,
                onTap: () => _navigateToEditProfile(context),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile.fullName.isNotEmpty ? userProfile.fullName : 'User',
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getFontSize(context, 20),
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingXS)),
                Text(
                  userProfile.email.isNotEmpty ? userProfile.email : 'No email',
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getFontSize(context, 14),
                    color: isDarkMode ? Colors.grey[300] : const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFFE0E0E0),
      child: Icon(
        Icons.person,
        color: const Color(0xFF757575),
        size: ResponsiveUtils.getIconSize(context, 30),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDarkMode = ref.watch(themeProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context, 12)),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: ResponsiveUtils.getFontSize(context, 18),
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    final isDarkMode = ref.watch(themeProvider);
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDarkMode = ref.watch(themeProvider);
    return ListTile(
      leading: Container(
        width: ResponsiveUtils.getSpacing(context, 40),
        height: ResponsiveUtils.getSpacing(context, 40),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
        ),
        child: Icon(
          icon,
          color: isDarkMode ? Colors.white : const Color(0xFF424242),
          size: ResponsiveUtils.getIconSize(context, 20),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: ResponsiveUtils.getFontSize(context, 16),
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: ResponsiveUtils.getFontSize(context, 14),
          color: isDarkMode ? Colors.grey[300] : const Color(0xFF757575),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingM), vertical: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = ref.watch(themeProvider);
    return ListTile(
      leading: Container(
        width: ResponsiveUtils.getSpacing(context, 40),
        height: ResponsiveUtils.getSpacing(context, 40),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
        ),
        child: Icon(
          icon,
          color: isDarkMode ? Colors.white : const Color(0xFF424242),
          size: ResponsiveUtils.getIconSize(context, 20),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: ResponsiveUtils.getFontSize(context, 16),
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: ResponsiveUtils.getFontSize(context, 14),
          color: isDarkMode ? Colors.grey[300] : const Color(0xFF757575),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1A237E),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, 16), vertical: ResponsiveUtils.getSpacing(context, 8)),
    );
  }

  Widget _buildDivider() {
    final isDarkMode = ref.watch(themeProvider);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
      height: ResponsiveUtils.getSpacing(context, 1),
      color: isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF0F0F0),
    );
  }

  void _showLanguageSelector(BuildContext context, String currentLanguage) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLanguage == 'urdu' ? 'زبان منتخب کریں' : 'Select Language',
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, 20)),
            _buildLanguageOption('English', 'English', currentLanguage),
            _buildLanguageOption('urdu', 'اردو', currentLanguage),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String value, String label, String currentLanguage) {
    return ListTile(
      title: Text(label),
      trailing: currentLanguage == value
          ? const Icon(Icons.check, color: Color(0xFF1A237E))
          : null,
      onTap: () {
        ref.read(languageProvider.notifier).setLanguage(value);
        Navigator.pop(context);
      },
    );
  }



  void _showStorageOptions(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentLanguage == 'urdu' ? 'اسٹوریج اور کیشے' : 'Storage & Cache'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentLanguage == 'urdu' 
              ? 'یہ تمام کیش شدہ ڈیٹا اور عارضی فائلوں کو صاف کر دے گا۔'
              : 'This will clear all cached data and temporary files.'),
            const SizedBox(height: 16),
            Text(
              currentLanguage == 'urdu' ? 'اختیارات:' : 'Options:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('• ${currentLanguage == 'urdu' ? 'کیشے صاف کریں' : 'Clear Cache'}'),
            Text('• ${currentLanguage == 'urdu' ? 'ڈمی پروفائل ڈیٹا صاف کریں (Alexander Mitchell)' : 'Clear Dummy Profile Data (Alexander Mitchell)'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(currentLanguage == 'urdu' ? 'منسوخ کریں' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCacheOnly(context);
            },
            child: Text(currentLanguage == 'urdu' ? 'کیشے صاف کریں' : 'Clear Cache'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearDummyProfileData(context);
            },
            child: Text(currentLanguage == 'urdu' ? 'ڈمی ڈیٹا صاف کریں' : 'Clear Dummy Data', 
              style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    final currentLanguage = ref.watch(languageProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentLanguage == 'urdu' ? 'لاگ آؤٹ' : 'Logout'),
        content: Text(currentLanguage == 'urdu' 
          ? 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟ آپ کو دوبارہ سائن ان کرنا ہوگا۔'
          : 'Are you sure you want to logout? You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(currentLanguage == 'urdu' ? 'منسوخ کریں' : 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout();
            },
            child: Text(currentLanguage == 'urdu' ? 'لاگ آؤٹ' : 'Logout', 
              style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    // TODO: Navigate to edit profile screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentLanguage == 'urdu' ? 'ای میل تبدیل کریں' : 'Change Email'),
        content: Text(currentLanguage == 'urdu' 
          ? 'ای میل تبدیل کرنے کے لیے، آپ کو اپنے موجودہ ای میل پر تصدیقی کوڈ بھیجا جائے گا۔'
          : 'To change your email, a verification code will be sent to your current email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(currentLanguage == 'urdu' ? 'منسوخ کریں' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement email change with verification
            },
            child: Text(currentLanguage == 'urdu' ? 'بھیجیں' : 'Send Code'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentLanguage == 'urdu' ? 'پاس ورڈ تبدیل کریں' : 'Change Password'),
        content: Text(currentLanguage == 'urdu' 
          ? 'پاس ورڈ تبدیل کرنے کے لیے، آپ کو اپنے ای میل پر تصدیقی کوڈ بھیجا جائے گا۔'
          : 'To change your password, a verification code will be sent to your email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(currentLanguage == 'urdu' ? 'منسوخ کریں' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement password change with verification
            },
            child: Text(currentLanguage == 'urdu' ? 'بھیجیں' : 'Send Code'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshProfileData() async {
    try {
      final currentLanguage = ref.read(languageProvider);
      
      // Show loading message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'urdu' 
                ? 'پروفائل ڈیٹا سنک کر رہے ہیں...'
                : 'Syncing profile data...',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
      // Sync profile data from Firebase
      await ref.read(userProfileProvider.notifier).syncProfileFromFirebase();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'urdu' 
                ? 'پروفائل ڈیٹا کامیابی سے سنک ہو گیا'
                : 'Profile data synced successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      print('Profile data refreshed successfully via pull-to-refresh');
    } catch (e) {
      print('Error refreshing profile data: $e');
      
      final currentLanguage = ref.read(languageProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'urdu' 
                ? 'پروفائل ڈیٹا سنک کرنے میں خرابی: $e'
                : 'Failed to sync profile data: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _performLogout() async {
    try {
      // Clear user profile state (but keep local image data)
      ref.read(userProfileProvider.notifier).clearProfile();
      
      // Sign out from Firebase
      await ref.read(authProvider.notifier).signOut();
      
      // Explicitly navigate to LoginScreen and clear stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
      print('Logout completed successfully and navigated to LoginScreen');
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _clearCacheOnly(BuildContext context) async {
    final currentLanguage = ref.read(languageProvider);
    try {
      // Show loading message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'urdu' 
                ? 'کیشے صاف کر رہے ہیں...'
                : 'Clearing cache...',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
      // TODO: Implement actual cache clearing logic
      await Future.delayed(const Duration(seconds: 1)); // Simulate clearing
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'urdu' 
                ? 'کیشے کامیابی سے صاف ہو گیا'
                : 'Cache cleared successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error clearing cache: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'urdu' 
                ? 'کیشے صاف کرنے میں خرابی: $e'
                : 'Failed to clear cache: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  Future<void> _clearDummyProfileData(BuildContext context) async {
    final currentLanguage = ref.read(languageProvider);
    try {
      // Show loading message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'urdu' 
                ? 'ڈمی پروفائل ڈیٹا صاف کر رہے ہیں...'
                : 'Clearing dummy profile data...',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Clear dummy profile data using the auth provider method
      await ref.read(authProvider.notifier).clearPersistentDummyData();
      
      // Reload profile from persistence to reflect changes
      await ref.read(userProfileProvider.notifier).loadProfileFromPersistence();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'urdu' 
                ? 'ڈمی پروفائل ڈیٹا کامیابی سے صاف ہو گیا! اب آپ اپنا اصل نام استعمال کر سکتے ہیں۔'
                : 'Dummy profile data cleared successfully! You can now use your real name.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      print('Dummy profile data (Alexander Mitchell) cleared successfully');
    } catch (e) {
      print('Error clearing dummy profile data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'urdu' 
                ? 'ڈمی پروفائل ڈیٹا صاف کرنے میں خرابی: $e'
                : 'Failed to clear dummy profile data: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
