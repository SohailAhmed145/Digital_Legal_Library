import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import 'home/home_screen.dart';
import 'cases/cases_screen.dart';
import 'library/library_screen.dart';
import 'ai_chat/ai_chat_screen.dart';
import 'cases/add_case_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}



class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const HomeScreen(),
    const CasesScreen(),
    const LibraryScreen(),
    const AiChatScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load profile data from the authenticated user
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        print('MainScreen: Loading profile data from authenticated user');
        
        // Get the current authenticated user
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated && authState.currentUser != null) {
          // Convert UserModel to UserProfile and set it
          final userProfile = UserProfile.fromUserModel(authState.currentUser!);
          ref.read(userProfileProvider.notifier).setProfile(userProfile);
          
          // Also sync from Firebase to get the latest data
          await ref.read(userProfileProvider.notifier).loadProfileFromFirebase();
          print('MainScreen: Profile data loaded and synced successfully');
        } else {
          print('MainScreen: No authenticated user found, loading from persistence');
          await ref.read(userProfileProvider.notifier).loadProfileFromPersistence();
        }
      } catch (e) {
        print('Error loading profile in MainScreen: $e');
        // Fallback to loading from local persistence
        try {
          await ref.read(userProfileProvider.notifier).loadProfileFromPersistence();
          print('MainScreen: Loaded profile from local persistence as fallback');
        } catch (fallbackError) {
          print('Error loading profile from persistence: $fallbackError');
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: AppTheme.animationNormal,
      curve: Curves.easeInOut,
    );
  }

  void _onTabTapped(int index) {
    onTabTapped(index);
  }

  void _onAddCasePressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddCaseScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    final currentTab = ref.watch(navigationProvider);
    
    // If user is not authenticated, this screen should not be shown
    // The AuthWrapper should handle navigation to LoginScreen
    if (!authState.isAuthenticated) {
      print('MainScreen: User not authenticated, should navigate to login');
      // Return empty container while AuthWrapper handles navigation
      return const SizedBox.shrink();
    }
    
    // Listen to navigation changes
    ref.listen(navigationProvider, (previous, next) {
      if (previous != next) {
        _onTabTapped(next);
      }
    });
    
    // Configure system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
      systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ));
    
    return Scaffold(

      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _screens,
        ),
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _onAddCasePressed,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: ResponsiveUtils.getSpacing(context, 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, AppTheme.radiusL)),
              ),
              icon: Icon(Icons.add, size: ResponsiveUtils.getIconSize(context, 24)),
              label: Text(
                currentLanguage == 'urdu' ? 'کیس بنائیں' : 'Create Case',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtils.getFontSize(context, 14),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: isDarkMode ? AppTheme.darkOnSurfaceColor.withValues(alpha: 0.5) : AppTheme.onSurfaceColor.withValues(alpha: 0.5),
        selectedLabelStyle: AppTheme.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTheme.labelMedium.copyWith(
          fontWeight: FontWeight.w400,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: currentLanguage == 'urdu' ? 'ہوم' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_outlined),
            activeIcon: const Icon(Icons.folder),
            label: currentLanguage == 'urdu' ? 'کیسز' : 'Cases',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books_outlined),
            activeIcon: const Icon(Icons.library_books),
            label: currentLanguage == 'urdu' ? 'لائبریری' : 'Library',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.smart_toy_outlined),
            activeIcon: const Icon(Icons.smart_toy),
            label: currentLanguage == 'urdu' ? 'AI چیٹ' : 'AI Chat',
          ),
        ],
      ),
    );
  }
}
