import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';

import 'models/case_model.dart';
import 'services/hive_database_service.dart';
import 'services/permission_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (check if already initialized)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase Core initialized successfully');
    
    // Initialize Firebase services
    await FirebaseService().initialize();
    print('Firebase services initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue with app initialization even if Firebase fails
  }
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(CaseModelAdapter());
  Hive.registerAdapter(CaseStatusAdapter());
  
  // Initialize Hive database service
  await HiveDatabaseService().initialize();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(languageProvider);
    
    return MaterialApp(
      title: currentLanguage == 'urdu' ? 'Legal Library' : 'Legal Library',
      theme: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isInitializing = true;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      // Load theme and language settings first
      await ref.read(themeProvider.notifier).loadThemeFromPersistence();
      await ref.read(languageProvider.notifier).loadLanguageFromPersistence();
      
      // Load user profile from persistence
      await ref.read(userProfileProvider.notifier).loadProfileFromPersistence();
      
      // Only use default profile for unauthenticated users
      // Authenticated users will get their profile loaded from Firebase in auth_provider
      if (ref.read(userProfileProvider) == null) {
        final authState = ref.read(authProvider);
        if (!authState.isAuthenticated) {
          final initialProfile = ref.read(initialProfileProvider);
          ref.read(userProfileProvider.notifier).setProfile(initialProfile);
          // Save default profile to persistence only for unauthenticated users
          await ref.read(userProfileProvider.notifier).saveProfileToPersistence();
        }
      }
      
      // Request essential permissions natively on mobile platforms
      await _requestEssentialPermissions();
      
      print('All persisted data loaded successfully');
    } catch (e) {
      print('Error loading persisted data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }
  
  Future<void> _requestEssentialPermissions() async {
    // Only request permissions on mobile platforms (Android/iOS)
    // Skip for web and desktop platforms
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return;
    }
    
    try {
      // Request only essential permissions for core app functionality
      await PermissionService.requestEssentialPermissions();
    } catch (e) {
      print('Error requesting essential permissions: $e');
      // Continue with app initialization even if permissions fail
      // The app should still be functional with limited features
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen first while initializing
    if (_isInitializing) {
      return const SplashScreen();
    }
    

    
    final authState = ref.watch(authProvider);
    
    print('AuthWrapper - Auth state: isAuthenticated=${authState.isAuthenticated}, currentUser=${authState.currentUser?.email ?? 'null'}, isLoading=${authState.isLoading}');
    
    // Show splash screen whenever auth is loading to avoid stuck UI perception
    if (authState.isLoading) {
      return const SplashScreen();
    }
    
    if (authState.isAuthenticated && authState.currentUser != null) {
      // User is authenticated, go to main screen
      // Profile will be loaded in MainScreen
      return const MainScreen();
    }
    
    // User is not authenticated, go to login
    print('AuthWrapper - Navigating to LoginScreen');
    return const LoginScreen();
  }
}
