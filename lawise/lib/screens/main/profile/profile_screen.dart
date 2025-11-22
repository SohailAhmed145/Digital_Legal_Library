import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive_utils.dart';
import '../../auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _showProfileModal = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background content (simulated)
          _buildBackgroundContent(),
          
          // Profile Modal Overlay
          if (_showProfileModal) _buildProfileModal(),
        ],
      ),
    );
  }

  Widget _buildBackgroundContent() {
    return Column(
      children: [
        // Top Header Section
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingL)),
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
                      color: Colors.black,
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
                          color: Colors.white,
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
                          color: const Color(0xFF424242),
                          size: ResponsiveUtils.getIconSize(context, 20),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.radiusM)),
                      // User Avatar
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showProfileModal = true;
                          });
                        },
                        child: Container(
                          width: ResponsiveUtils.getSpacing(context, 40),
                          height: ResponsiveUtils.getSpacing(context, 40),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 20)),
                            border: Border.all(color: Colors.white, width: ResponsiveUtils.getSpacing(context, 2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: ResponsiveUtils.getSpacing(context, 10),
                                offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 18)),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&h=80&fit=crop&crop=face',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFE0E0E0),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF757575),
                                  ),
                                );
                              },
                            ),
                          ),
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
                  color: Colors.white,
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
                  decoration: InputDecoration(
                    hintText: 'Search cases, laws, documents...',
                    hintStyle: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, 16),
                      color: const Color(0xFF9E9E9E),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF9E9E9E),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getSpacing(context, 20),
                      vertical: ResponsiveUtils.getSpacing(context, 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Simulated case list content
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, AppTheme.spacingL - AppTheme.spacingXS)),
            children: [
              _buildCaseCard(
                'Thompson vs. City Council',
                'Administrative Law',
                'Active',
                'Property development permit dispute regarding environmental regulations.',
                'Updated 2 hours ago',
                Colors.green,
              ),
              _buildCaseCard(
                'Roberts Family Trust',
                'Estate Planning',
                'Pending',
                'Trust modification and beneficiary designation',
                'Updated 1 day ago',
                Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaseCard(String title, String category, String status, String description, String lastUpdated, Color statusColor) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context, 16)),
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: ResponsiveUtils.getSpacing(context, 10),
            offset: Offset(0, ResponsiveUtils.getSpacing(context, 2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getSpacing(context, AppTheme.radiusM),
                  vertical: ResponsiveUtils.getSpacing(context, AppTheme.spacingS - AppTheme.spacingXS / 2),
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 20)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getFontSize(context, 12),
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingS)),
          Text(
            category,
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getFontSize(context, 14),
              color: const Color(0xFF757575),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, 8)),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getFontSize(context, 14),
              color: const Color(0xFF424242),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.radiusM)),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: ResponsiveUtils.getIconSize(context, 16),
                color: const Color(0xFF9E9E9E),
              ),
              SizedBox(width: ResponsiveUtils.getSpacing(context, AppTheme.spacingS - AppTheme.spacingXS / 2)),
              Text(
                lastUpdated,
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getFontSize(context, 12),
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileModal() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingL)),
          padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, AppTheme.spacingL)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: ResponsiveUtils.getSpacing(context, 20),
                offset: Offset(0, ResponsiveUtils.getSpacing(context, 10)),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Picture
              Container(
                width: ResponsiveUtils.getSpacing(context, 80),
                height: ResponsiveUtils.getSpacing(context, 80),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 40)),
                  border: Border.all(color: Colors.white, width: ResponsiveUtils.getSpacing(context, 3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: ResponsiveUtils.getSpacing(context, 10),
                      offset: Offset(0, ResponsiveUtils.getSpacing(context, 5)),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, 37)),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&h=80&fit=crop&crop=face',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFE0E0E0),
                        child: Icon(
                          Icons.person,
                          color: const Color(0xFF757575),
                          size: ResponsiveUtils.getIconSize(context, 40),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingM)),
              
              // Name
              Text(
                'Alexander Mitchell',
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getFontSize(context, 24),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              SizedBox(height: ResponsiveUtils.getSpacing(context, 8)),
              
              // Email
              Text(
                'alex.mitchell@company.com',
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getFontSize(context, 16),
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
              
              SizedBox(height: ResponsiveUtils.getSpacing(context, AppTheme.spacingL)),
              
              // Menu Options
              _buildMenuOption(Icons.person, 'View Profile'),
              _buildMenuOption(Icons.edit, 'Edit Profile'),
              _buildMenuOption(Icons.folder, 'Saved Cases'),
              _buildMenuOption(Icons.settings, 'Settings & Preferences'),
              _buildMenuOption(Icons.help, 'Help & Support'),
              
              Divider(height: ResponsiveUtils.getSpacing(context, 32)),
              
              // Logout
              _buildMenuOption(Icons.logout, 'Logout', isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey[700],
        size: ResponsiveUtils.getIconSize(context, 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: ResponsiveUtils.getFontSize(context, 16),
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      onTap: () {
        if (title == 'Logout') {
          _showLogoutConfirmation();
        } else {
          // Handle other menu options
        }
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut().then((_) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              });
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
