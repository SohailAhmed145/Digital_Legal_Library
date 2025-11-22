import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/data_persistence_service.dart';
import '../services/supabase_storage_service.dart';

import '../models/user_model.dart';

class UserProfile {
  // Convert from UserModel to UserProfile
  factory UserProfile.fromUserModel(UserModel userModel) {
    return UserProfile(
      id: userModel.id,
      fullName: userModel.fullName,
      email: userModel.email,
      profileImagePath: userModel.profileImageUrl,
      role: userModel.role,
      phoneNumber: userModel.phoneNumber,
      address: userModel.address,
      specialization: userModel.specialization,
      barNumber: userModel.barNumber,
      isEmailVerified: userModel.isEmailVerified,
      isActive: userModel.isActive,
      lastLoginAt: userModel.lastLoginAt,
      createdAt: userModel.createdAt,
      updatedAt: userModel.updatedAt,
    );
  }
  
  // Convert to UserModel
  UserModel toUserModel() {
    return UserModel(
      id: id,
      fullName: fullName,
      email: email,
      profileImageUrl: profileImagePath,
      role: role,
      phoneNumber: phoneNumber,
      address: address,
      specialization: specialization,
      barNumber: barNumber,
      isEmailVerified: isEmailVerified,
      isActive: isActive,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  final String id;
  final String fullName;
  final String email;
  final String? profileImagePath;
  final UserRole role;
  final String? phoneNumber;
  final String? address;
  final String? specialization;
  final String? barNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;
  final bool isActive;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.profileImagePath,
    required this.role,
    this.phoneNumber,
    this.address,
    this.specialization,
    this.barNumber,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    required this.isEmailVerified,
    required this.isActive,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? profileImagePath,
    UserRole? role,
    String? phoneNumber,
    String? address,
    String? specialization,
    String? barNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    bool? isActive,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      specialization: specialization ?? this.specialization,
      barNumber: barNumber ?? this.barNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null);

  void setProfile(UserProfile profile) {
    state = profile;
  }

  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? profileImagePath,
    UserRole? role,
    String? phoneNumber,
    String? address,
    String? specialization,
    String? barNumber,
    bool? isEmailVerified,
    bool? isActive,
  }) async {
    if (state != null) {
      final updatedProfile = state!.copyWith(
        fullName: fullName ?? state!.fullName,
        email: email ?? state!.email,
        profileImagePath: profileImagePath ?? state!.profileImagePath,
        role: role ?? state!.role,
        phoneNumber: phoneNumber ?? state!.phoneNumber,
        address: address ?? state!.address,
        specialization: specialization ?? state!.specialization,
        barNumber: barNumber ?? state!.barNumber,
        isEmailVerified: isEmailVerified ?? state!.isEmailVerified,
        isActive: isActive ?? state!.isActive,
        updatedAt: DateTime.now(),
      );
      
      state = updatedProfile;
      
      // Save to Firebase Firestore
      await _saveProfileToFirebase(updatedProfile);
      
      // Persist the updated profile locally
      final persistenceService = await DataPersistenceService.getInstance();
      await persistenceService.saveProfileData(
        fullName: updatedProfile.fullName,
        email: updatedProfile.email,
        profileImagePath: updatedProfile.profileImagePath,
      );
    }
  }

  Future<void> updateProfileImage(String imagePath) async {
    if (state != null) {
      try {
        // Save image to local storage first
        final persistenceService = await DataPersistenceService.getInstance();
        final savedImagePath = await persistenceService.saveProfileImage(File(imagePath));
        
        if (savedImagePath != null) {
          final updatedProfile = state!.copyWith(
            profileImagePath: savedImagePath,
            updatedAt: DateTime.now(),
          );
          
          state = updatedProfile;
          
          // Persist the updated profile data
          await persistenceService.saveProfileData(
            fullName: updatedProfile.fullName,
            email: updatedProfile.email,
            profileImagePath: updatedProfile.profileImagePath,
          );
        }
      } catch (e) {
        print('Error updating profile image: $e');
        // Fallback to original path if local save fails
        final updatedProfile = state!.copyWith(
          profileImagePath: imagePath,
          updatedAt: DateTime.now(),
        );
        
        state = updatedProfile;
        
        // Persist the updated profile data
        final persistenceService = await DataPersistenceService.getInstance();
        await persistenceService.saveProfileData(
          fullName: updatedProfile.fullName,
          email: updatedProfile.email,
          profileImagePath: updatedProfile.profileImagePath,
        );
      }
    }
  }

  Future<void> updateProfileImageData(Uint8List imageData) async {
    if (state != null) {
      print('Updating profile image with data length: ${imageData.length}');
      
      // Always save to local storage first for immediate UI update
      try {
        final persistenceService = await DataPersistenceService.getInstance();
        final savedImagePath = await persistenceService.saveProfileImage(null, imageData: imageData);
        
        if (savedImagePath != null) {
          // Immediately update the UI with local image
          final localProfile = state!.copyWith(
            profileImagePath: savedImagePath,
            updatedAt: DateTime.now(),
          );
          
          state = localProfile;
          print('Profile image immediately updated with local path: $savedImagePath');
          
          // Try Firebase Storage in background (non-blocking)
          _tryFirebaseUpload(imageData, savedImagePath);
        }
      } catch (e) {
        print('Error saving profile image to local storage: $e');
      }
    }
  }

  // Background Firebase upload method
  void _tryFirebaseUpload(Uint8List imageData, String localPath) {
    // Run Supabase upload in background without blocking UI
    Future.microtask(() async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        print('Starting background Supabase upload for user: ${user.uid}');
        final supabase = SupabaseStorageService();
        final downloadURL = await supabase.uploadProfileImage(imageData, user.uid);
        print('Supabase upload completed, public URL: $downloadURL');
        
        // Update the profile with the Firebase URL
        final updatedProfile = state!.copyWith(
          profileImagePath: downloadURL,
          updatedAt: DateTime.now(),
        );
        
        // Update the state with the new URL
        state = updatedProfile;
        
        print('Profile state updated with Supabase URL: $downloadURL');
        
        // Update profile in Firestore with the new image URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'profileImageURL': downloadURL,
          'profileImageUrl': downloadURL,
          'profileImagePath': downloadURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('Profile image URL updated in Firestore (Supabase): $downloadURL');
        
        // Update local persistence with the new Firebase URL
        final persistenceService = await DataPersistenceService.getInstance();
        await persistenceService.saveProfileData(
          fullName: updatedProfile.fullName,
          email: updatedProfile.email,
          profileImagePath: downloadURL,
        );
        
        print('Profile image successfully stored via Supabase: $downloadURL');
        
      } catch (e) {
        print('Background Supabase upload failed: $e');
        print('Profile image remains in local storage: $localPath');
        // Don't throw - this is background operation
      }
    });
  }

  Future<void> _saveProfileToFirebase(UserProfile profile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'id': profile.id,
        'fullName': profile.fullName,
        'email': profile.email,
        'profileImageUrl': profile.profileImagePath,
        'role': profile.role.toString().split('.').last,
        'phoneNumber': profile.phoneNumber,
        'address': profile.address,
        'specialization': profile.specialization,
        'barNumber': profile.barNumber,
        'isEmailVerified': profile.isEmailVerified,
        'isActive': profile.isActive,
        'lastLoginAt': profile.lastLoginAt != null ? Timestamp.fromDate(profile.lastLoginAt!) : null,
        'createdAt': Timestamp.fromDate(profile.createdAt),
        'updatedAt': Timestamp.fromDate(profile.updatedAt),
      }, SetOptions(merge: true));
      
      print('Profile saved to Firebase successfully');
    } catch (e) {
      print('Error saving profile to Firebase: $e');
        rethrow;
    }
  }

  void clearProfile() {
    state = null;
  }

  // Load profile from persistence
  Future<void> loadProfileFromPersistence() async {
    try {
      final persistenceService = await DataPersistenceService.getInstance();
      final profileData = persistenceService.getProfileData();
      
      print('Loading profile from persistence: $profileData');
      
      if (profileData != null) {
        final profile = UserProfile(
          id: 'persisted_user',
          fullName: profileData['fullName'],
          email: profileData['email'],
          profileImagePath: profileData['profileImagePath'],
          role: UserRole.lawyer,
          isEmailVerified: false,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        state = profile;
        print('Profile loaded from persistence: ${profile.fullName}, Image: ${profile.profileImagePath}');
        
        // If we have a profile image path, verify the image data exists
        if (profile.profileImagePath != null && profile.profileImagePath!.isNotEmpty) {
          try {
            final imageData = persistenceService.getProfileImageData();
            if (imageData != null) {
              print('Profile image data found in persistence: ${imageData.length} bytes');
            } else {
              print('Profile image data not found in persistence');
            }
          } catch (e) {
            print('Error checking profile image data: $e');
          }
        }
      } else {
        print('No profile data found in persistence');
      }
    } catch (e) {
      print('Error loading profile from persistence: $e');
    }
  }

  // Load profile from Firebase
  Future<void> loadProfileFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('Loading profile from Firebase for user: ${user.uid}');
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        print('Firebase data: $data');
        
        print('Raw Firebase data for profileImagePath: ${data['profileImagePath']}');
        print('Raw Firebase data for profileImageURL: ${data['profileImageURL']}');
        print('Raw Firebase data for profileImageUrl: ${data['profileImageUrl']}');
        
        // Get the profile image path with proper priority (Firebase URLs first, then local paths)
        String? profileImagePath;
        print('Checking profile image path priority:');
        print('  profileImagePath: "${data['profileImagePath']}" (${data['profileImagePath']?.runtimeType})');
        print('  profileImageURL: "${data['profileImageURL']}" (${data['profileImageURL']?.runtimeType})');
        print('  profileImageUrl: "${data['profileImageUrl']}" (${data['profileImageUrl']?.runtimeType})');
        
        // Priority: Firebase URLs first, then local web image paths
        if (data['profileImagePath'] != null && 
            data['profileImagePath'].toString().isNotEmpty && 
            data['profileImagePath'].toString().startsWith('http')) {
          // Firebase Storage URL - highest priority
          profileImagePath = data['profileImagePath'];
          print('  → Using Firebase Storage URL: $profileImagePath');
        } else if (data['profileImageURL'] != null && 
                   data['profileImageURL'].toString().isNotEmpty && 
                   data['profileImageURL'].toString().startsWith('http')) {
          // Firebase Storage URL from profileImageURL field
          profileImagePath = data['profileImageURL'];
          print('  → Using Firebase Storage URL from profileImageURL: $profileImagePath');
        } else if (data['profileImageUrl'] != null && 
                   data['profileImageUrl'].toString().isNotEmpty && 
                   data['profileImageUrl'].toString().startsWith('http')) {
          // Firebase Storage URL from profileImageUrl field
          profileImagePath = data['profileImageUrl'];
          print('  → Using Firebase Storage URL from profileImageUrl: $profileImagePath');
        } else if (data['profileImagePath'] != null && 
                   data['profileImagePath'].toString().isNotEmpty && 
                   data['profileImagePath'].toString().startsWith('web_image_')) {
          // Local web image path - fallback
          profileImagePath = data['profileImagePath'];
          print('  → Using local web image path: $profileImagePath');
        } else {
          print('  → No valid profile image path found in Firestore, checking Firebase Storage');
          // Check Firebase Cloud Storage for existing profile image
          profileImagePath = await _getProfileImageFromStorage(user.uid);
          if (profileImagePath != null) {
            print('  → Found profile image in Firebase Storage: $profileImagePath');
            // Update Firestore with the found image URL
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({
                'profileImagePath': profileImagePath,
                'profileImageURL': profileImagePath,
                'profileImageUrl': profileImagePath,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              print('Updated Firestore with Firebase Storage image URL');
            } catch (e) {
              print('Error updating Firestore with image URL: $e');
            }
          } else {
            print('  → No profile image found in Firebase Storage either');
          }
        }
        
        var profile = UserProfile(
          id: data['id'] ?? user.uid,
          fullName: data['fullName'] ?? user.displayName ?? 'User',
          email: user.email ?? data['email'] ?? '', // Prioritize authenticated user's email
          profileImagePath: profileImagePath ?? '',
          role: UserRole.values.firstWhere(
            (e) => e.toString() == 'UserRole.${data['role']}',
            orElse: () => UserRole.lawyer,
          ),
          phoneNumber: data['phoneNumber'],
          address: data['address'],
          specialization: data['specialization'],
          barNumber: data['barNumber'],
          isEmailVerified: data['isEmailVerified'] ?? false,
          isActive: data['isActive'] ?? true,
          lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
        
        // Update Firebase if email doesn't match authenticated user's email
        if (data['email'] != user.email && user.email != null) {
          print('Email mismatch detected. Updating Firebase with authenticated email: ${user.email}');
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'email': user.email,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('Email updated in Firebase to match authenticated user');
          } catch (e) {
            print('Error updating email in Firebase: $e');
          }
        }
        
        print('Profile loaded from Firebase - Image path: ${profile.profileImagePath}');
        
        // Check if we have a valid profile image path
        if (profile.profileImagePath != null && profile.profileImagePath!.isNotEmpty) {
          print('Valid profile image path found: ${profile.profileImagePath}');
          
          if (profile.profileImagePath!.startsWith('http')) {
            print('Firebase Storage URL found: ${profile.profileImagePath}');
          } else if (profile.profileImagePath!.startsWith('web_image_')) {
            print('Local web image ID found: ${profile.profileImagePath} - will load from local storage');
          }
        } else {
          print('No profile image path found in Firebase data');
        }
        
        // Clear invalid paths (not http and not web_image_)
        if (profile.profileImagePath != null && 
            profile.profileImagePath!.isNotEmpty && 
            !profile.profileImagePath!.startsWith('http') &&
            !profile.profileImagePath!.startsWith('web_image_')) {
          print('Invalid profile image path found: ${profile.profileImagePath}, clearing it');
          profile = profile.copyWith(profileImagePath: '');
          
          // Also clear it from Firestore to fix the data
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'profileImageURL': '',
              'profileImagePath': '',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('Cleared invalid profile image path from Firestore');
          } catch (e) {
            print('Error clearing invalid path from Firestore: $e');
          }
        }
        
        print('Profile loaded from Firebase: ${profile.fullName}, Image: ${profile.profileImagePath}');
        state = profile;
        
        // Also save to local persistence
        final persistenceService = await DataPersistenceService.getInstance();
        await persistenceService.saveProfileData(
          fullName: profile.fullName,
          email: profile.email,
          profileImagePath: profile.profileImagePath,
        );
        
        print('Profile saved to local persistence');
      } else {
        print('No profile found in Firebase, creating default profile');
        // Create default profile if none exists
        final defaultProfile = UserProfile(
          id: user.uid,
          fullName: user.displayName ?? 'User',
          email: user.email ?? '',
          profileImagePath: '',
          role: UserRole.lawyer,
          isEmailVerified: false,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        state = defaultProfile;
        
        // Save to Firebase and local persistence
        await _saveProfileToFirebase(defaultProfile);
        final persistenceService = await DataPersistenceService.getInstance();
        await persistenceService.saveProfileData(
          fullName: defaultProfile.fullName,
          email: defaultProfile.email,
          profileImagePath: defaultProfile.profileImagePath,
        );
        
        print('Default profile created and saved to Firebase');
      }
    } catch (e) {
      print('Error loading profile from Firebase: $e');
      // Fallback to local persistence if Firebase fails
      await loadProfileFromPersistence();
    }
  }

  // Save profile to persistence
  Future<void> saveProfileToPersistence() async {
    if (state != null) {
      try {
        final persistenceService = await DataPersistenceService.getInstance();
        await persistenceService.saveProfileData(
          fullName: state!.fullName,
          email: state!.email,
          profileImagePath: state!.profileImagePath,
        );
        print('Profile saved to persistence successfully');
      } catch (e) {
        print('Error saving profile to persistence: $e');
      }
    }
  }

  // Clear all persistent dummy data (for fixing hardcoded names)
  Future<void> clearPersistentDummyData() async {
    try {
      final persistenceService = await DataPersistenceService.getInstance();
      await persistenceService.clearAllDataIncludingFirebase();
      
      // Reset state to null so it can be properly reloaded
      state = null;
      
      print('All persistent dummy data cleared successfully');
    } catch (e) {
      print('Error clearing persistent dummy data: $e');
    }
  }

  // Sync profile data from Firebase (for cross-device synchronization)
  Future<void> syncProfileFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No authenticated user, cannot sync profile');
        return;
      }

      print('Syncing profile data from Firebase for user: ${user.uid}');
      
      // Load latest profile data from Firebase
      await loadProfileFromFirebase();
      
      // Ensure local persistence is updated with latest data
      if (state != null) {
        await saveProfileToPersistence();
        print('Profile data synced and saved to local persistence');
      }
      
    } catch (e) {
      print('Error syncing profile from Firebase: $e');
      // Fallback to local data if sync fails
      await loadProfileFromPersistence();
    }
  }

  // Check for existing profile image in Firebase Cloud Storage
  Future<String?> _getProfileImageFromStorage(String userId) async {
    try {
      print('Checking for profile image in Firebase Storage for user: $userId');
      
      // List all files in the user's profile_images folder
      final storageRef = FirebaseStorage.instance.ref().child('profile_images');
      final listResult = await storageRef.listAll();
      
      // Look for files that start with the user's ID
      for (final item in listResult.items) {
        if (item.name.startsWith('${userId}_')) {
          final downloadUrl = await item.getDownloadURL();
          print('Found profile image in Firebase Storage: $downloadUrl');
          return downloadUrl;
        }
      }
      
      print('No profile image found in Firebase Storage for user: $userId');
      return null;
    } catch (e) {
      print('Error checking Firebase Storage for profile image: $e');
      return null;
    }
  }

  // Force refresh profile data from Firebase
  Future<void> refreshProfileFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('Force refreshing profile data from Firebase');
      
      // Clear current state to force fresh load
      state = null;
      
      // Load fresh data from Firebase
      await loadProfileFromFirebase();
      
      print('Profile data refreshed successfully');
    } catch (e) {
      print('Error refreshing profile from Firebase: $e');
      // Restore from local persistence if refresh fails
      await loadProfileFromPersistence();
    }
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  return UserProfileNotifier();
});

// Initialize with minimal default profile data - should not be used for real users
final initialProfileProvider = Provider<UserProfile>((ref) {
  return UserProfile(
    id: 'temp_user',
    fullName: 'User',
    email: '',
    profileImagePath: null,
    role: UserRole.lawyer,
    isEmailVerified: false,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
});
