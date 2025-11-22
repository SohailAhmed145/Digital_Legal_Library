import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/data_persistence_service.dart';
import '../services/sample_data_service.dart';
import '../repositories/case_repository.dart';
import 'user_profile_provider.dart';

// State class for auth
class AuthState {
  final UserModel? currentUser;
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? currentUser,
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  final SampleDataService _sampleDataService = SampleDataService();
  
  AuthNotifier() : super(const AuthState()) {
    initialize();
  }

  // Initialize auth state listener
  void initialize() {
    print('Initializing AuthNotifier...');
    
    try {
      // Listen to Firebase auth state changes
      _authService.authStateChanges.listen((User? firebaseUser) async {
        print('Auth state changed: ${firebaseUser?.uid ?? 'null'}');
        
        if (firebaseUser != null) {
          print('User signed in, loading profile...');
          // User is signed in
          await _loadUserProfile(firebaseUser.uid);
          
          // Update last login time if this is a new session
          if (state.currentUser != null && 
              (state.currentUser!.lastLoginAt == null || 
               DateTime.now().difference(state.currentUser!.lastLoginAt!).inMinutes > 5)) {
            final updatedUser = state.currentUser!.copyWith(
              lastLoginAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await _authService.updateUserProfile(updatedUser);
            state = state.copyWith(
              currentUser: updatedUser,
              isAuthenticated: true,
            );
          }
          
          print('AuthNotifier - User profile loaded, currentUser: ${state.currentUser?.email ?? 'null'}');
          
          // Initialize sample data for new users
          _initializeSampleData();
        } else {
          print('User signed out, clearing user data');
          // User is signed out
          await _clearUserDataOnSignOut();
          state = const AuthState();
        }
        
        print('AuthNotifier - State updated, isAuthenticated: ${state.isAuthenticated}');
      });
      
      // Check if user is already signed in
      final currentFirebaseUser = _authService.currentUser;
      if (currentFirebaseUser != null) {
        print('User already signed in: ${currentFirebaseUser.uid}');
        _loadUserProfile(currentFirebaseUser.uid);
      } else {
        print('No user currently signed in');
      }
    } catch (e) {
      print('Error in AuthNotifier.initialize(): $e');
      state = state.copyWith(errorMessage: 'Failed to initialize authentication: $e');
    }
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile(String userId) async {
    try {
      print('Loading user profile for userId: $userId');
      _setLoading(true);
      final userProfile = await _authService.getUserProfile(userId);
      if (userProfile != null) {
        print('User profile found: ${userProfile.email}');
        state = state.copyWith(
          currentUser: userProfile,
          errorMessage: null,
          isAuthenticated: true,
        );
      } else {
        print('No user profile found - creating a default profile');
        // Create a resilient default profile instead of forcing sign out
        final currentUser = _authService.currentUser;
        final email = currentUser?.email ?? '';
        // Derive a reasonable display name if missing
        final derivedName = (currentUser?.displayName?.trim()?.isNotEmpty ?? false)
            ? currentUser!.displayName!
            : (email.isNotEmpty ? email.split('@').first : 'User');

        final validUser = UserModel(
          id: userId,
          email: email,
          fullName: derivedName,
          role: UserRole.lawyer,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _authService.createUserProfile(validUser);
        state = state.copyWith(
          currentUser: validUser,
          errorMessage: null,
          isAuthenticated: true,
        );
      }
      
      // Also load the user profile data (for profile image, etc.) from Firebase
      // This ensures cross-device synchronization
      await _syncUserProfileData(userId);
      print('User profile loaded from Firestore, profile data synced...');
      
    } catch (e) {
      print('Error loading user profile: $e');
      state = state.copyWith(errorMessage: 'Failed to load user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  // Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _setLoading(true);
      state = state.copyWith(errorMessage: null);
      
      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result['success']) {
        print('Sign in successful');
        return true;
      } else {
        state = state.copyWith(errorMessage: result['error'] ?? 'Invalid email or password');
        return false;
      }
    } catch (e) {
      print('Error signing in: $e');
      state = state.copyWith(errorMessage: 'Sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create account with email and password
  Future<bool> createAccount({required String email, required String password, required String fullName}) async {
    try {
      _setLoading(true);
      state = state.copyWith(errorMessage: null);
      
      final success = await _authService.signUpWithEmailAndPassword(email, password, fullName);
      if (success) {
        print('Account creation successful');
        return true;
      } else {
        state = state.copyWith(errorMessage: 'Failed to create account');
        return false;
      }
    } catch (e) {
      print('Error creating account: $e');
      state = state.copyWith(errorMessage: 'Account creation failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Initialize sample data for new users
  void _initializeSampleData() async {
    try {
      await _sampleDataService.createSampleCases();
      print('Sample data initialization completed');
      
      // Force pull latest data from Firebase to ensure cases appear immediately
      // This is needed because the hybrid stream might not automatically pull existing data
      await _pullLatestCaseData();
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }
  
  // Pull latest case data from Firebase
  Future<void> _pullLatestCaseData() async {
    try {
      // Import case repository to pull latest data
      final caseRepository = CaseRepository();
      await caseRepository.initialize();
      await caseRepository.pullLatestData();
      print('Latest case data pulled from Firebase');
    } catch (e) {
      print('Error pulling latest case data: $e');
    }
  }

  // Legacy methods for backward compatibility
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    return signIn(email: email, password: password);
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password, String fullName) async {
    return createAccount(email: email, password: password, fullName: fullName);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Starting sign out process...');
      // Don't set loading state during sign out to avoid shimmer effect
      await _authService.signOut();
      
      // Clear the state immediately
      state = const AuthState();
      print('Sign out successful - Auth state cleared');
      
      // Force a rebuild by updating the state
      state = state.copyWith(isAuthenticated: false, currentUser: null);
      print('Sign out completed - State updated to unauthenticated');
    } catch (e) {
      print('Error signing out: $e');
      state = state.copyWith(errorMessage: 'Sign out failed: $e');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      state = state.copyWith(errorMessage: null);
      
      final success = await _authService.resetPassword(email);
      if (success) {
        print('Password reset email sent');
        return true;
      } else {
        state = state.copyWith(errorMessage: 'Failed to send reset email');
        return false;
      }
    } catch (e) {
      print('Error resetting password: $e');
      state = state.copyWith(errorMessage: 'Password reset failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      _setLoading(true);
      state = state.copyWith(errorMessage: null);
      
      final success = await _authService.updateUserProfile(updatedUser);
      if (success) {
        state = state.copyWith(currentUser: updatedUser);
        print('Profile updated successfully');
        return true;
      } else {
        state = state.copyWith(errorMessage: 'Failed to update profile');
        return false;
      }
    } catch (e) {
      print('Error updating profile: $e');
      state = state.copyWith(errorMessage: 'Profile update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sync user profile data across devices
  Future<void> _syncUserProfileData(String userId) async {
    try {
      print('Syncing user profile data for cross-device compatibility');
      
      // Get the current UserModel from auth state
      final currentUser = state.currentUser;
      if (currentUser != null) {
        // Convert UserModel to UserProfile
        final userProfile = UserProfile.fromUserModel(currentUser);
        
        // Create a new UserProfileNotifier and sync from Firebase
        final userProfileNotifier = UserProfileNotifier();
        userProfileNotifier.setProfile(userProfile);
        
        // Load profile from Firebase to ensure latest data
        await userProfileNotifier.loadProfileFromFirebase();
        
        print('User profile data synced successfully from Firebase');
      }
    } catch (e) {
      print('Error syncing user profile data: $e');
      // Don't throw - this is not critical for authentication
    }
  }

  // Clear user data on sign out
  Future<void> _clearUserDataOnSignOut() async {
    try {
      // Clear local storage
      final persistenceService = await DataPersistenceService.getInstance();
      await persistenceService.clearAllData();
      
      print('User data cleared successfully on sign out');
    } catch (e) {
      print('Error clearing user data on sign out: $e');
    }
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
  
  // Clear persistent dummy data (for fixing hardcoded names like Alexander Mitchell)
  Future<void> clearPersistentDummyData() async {
    try {
      print('Clearing persistent dummy data...');
      
      // Clear user profile data
      final userProfileNotifier = UserProfileNotifier();
      await userProfileNotifier.clearPersistentDummyData();
      
      // Clear auth data
      await _clearUserDataOnSignOut();
      
      print('All persistent dummy data cleared successfully');
    } catch (e) {
      print('Error clearing persistent dummy data: $e');
    }
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).errorMessage;
});
