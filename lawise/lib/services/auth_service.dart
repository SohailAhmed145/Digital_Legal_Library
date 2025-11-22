import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'security_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SecurityService _securityService = SecurityService();

  // Get current user
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get auth state changes stream
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      print('Error getting auth state changes: $e');
      return Stream.value(null);
    }
  }

  // Get user ID token stream
  Stream<String?> get idTokenStream {
    try {
      return _auth.idTokenChanges().map((user) => user?.uid);
    } catch (e) {
      print('Error getting ID token stream: $e');
      return Stream.value(null);
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailAndPassword({
    required String email,
    required String password,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      // Check if account is locked
      final lockStatus = await _securityService.checkAccountLockStatus(email);
      if (lockStatus['locked']) {
        await _securityService.recordLoginAttempt(
          email,
          successful: false,
          ipAddress: ipAddress,
          userAgent: userAgent,
          failureReason: 'account_locked',
        );
        
        return {
          'success': false,
          'error': 'Account temporarily locked due to too many failed attempts. Please try again later.',
          'lockedUntil': lockStatus['lockedUntil'],
        };
      }
      
      // Check for suspicious activity
      final suspiciousActivity = await _securityService.detectSuspiciousActivity(
        email,
        ipAddress: ipAddress,
        userAgent: userAgent,
      );
      
      if (suspiciousActivity['suspicious']) {
        debugPrint('Suspicious activity detected: ${suspiciousActivity['details']}');
      }
      
      print('Attempting to sign in with email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Sign in successful for user: ${credential.user?.uid}');
      
      if (credential.user != null) {
        // Record successful login
        await _securityService.recordLoginAttempt(
          email,
          successful: true,
          ipAddress: ipAddress,
          userAgent: userAgent,
        );
        
        // Update last login time
        await _updateLastLoginTime(credential.user!.uid);
        
        return {
          'success': true,
          'user': credential.user,
          'message': 'Successfully signed in',
          'suspiciousActivity': suspiciousActivity['suspicious'],
        };
      } else {
        await _securityService.recordLoginAttempt(
          email,
          successful: false,
          ipAddress: ipAddress,
          userAgent: userAgent,
          failureReason: 'unknown_error',
        );
        
        return {
          'success': false,
          'error': 'Sign in failed',
        };
      }
    } on FirebaseAuthException catch (e) {
      // Record failed login attempt
      await _securityService.recordLoginAttempt(
        email,
        successful: false,
        ipAddress: ipAddress,
        userAgent: userAgent,
        failureReason: e.code,
      );
      
      print('Sign in error: $e');
      return {
        'success': false,
        'error': e.message ?? 'Authentication failed',
      };
    } catch (e) {
      await _securityService.recordLoginAttempt(
        email,
        successful: false,
        ipAddress: ipAddress,
        userAgent: userAgent,
        failureReason: 'unexpected_error',
      );
      
      print('Sign in error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred',
      };
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailAndPassword(String email, String password, String fullName) async {
    try {
      print('Attempting to create account for email: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Account created successfully for user: ${credential.user?.uid}');
      
      // Create user profile
      if (credential.user != null) {
        final newUser = UserModel(
          id: credential.user!.uid,
          email: email,
          fullName: fullName,
          role: UserRole.lawyer,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        await createUserProfile(newUser);
        
        // Send email verification
        try {
          await credential.user!.sendEmailVerification();
          print('Email verification sent');
        } catch (e) {
          print('Failed to send email verification: $e');
        }
      }
      
      return true;
    } catch (e) {
      print('Account creation error: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Signing out user');
      await _auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      print('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent successfully');
      return true;
    } catch (e) {
      print('Password reset error: $e');
      return false;
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('Updating password for user: ${user.uid}');
        await user.updatePassword(newPassword);
        print('Password updated successfully');
      } else {
        print('No user to update password for');
      }
    } catch (e) {
      print('Password update error: $e');
      rethrow;
    }
  }

  // Change password with current password verification
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated.',
        };
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      print('Password changed successfully for user: ${user.uid}');

      // Sign out user for security
      await _auth.signOut();

      return {
        'success': true,
        'message': 'Password changed successfully. For security, you have been logged out. Please sign in with your new password.',
      };
    } catch (e) {
      print('Error changing password: $e');
      
      String message = 'Failed to change password.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            message = 'Current password is incorrect.';
            break;
          case 'weak-password':
            message = 'New password is too weak.';
            break;
          case 'requires-recent-login':
            message = 'Please sign in again before changing your password.';
            break;
        }
      }

      return {
        'success': false,
        'message': message,
      };
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('Updating email for user: ${user.uid} to: $newEmail');
        await user.updateEmail(newEmail);
        await user.sendEmailVerification();
        print('Email updated and verification sent successfully');
      } else {
        print('No user to update email for');
      }
    } catch (e) {
      print('Email update error: $e');
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        print('Sending email verification to: ${user.email}');
        await user.sendEmailVerification();
        print('Email verification sent successfully');
      } else {
        print('User not found or already verified');
      }
    } catch (e) {
      print('Email verification error: $e');
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore first
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete Firebase Auth account
        await user.delete();
      }
    } catch (e) {
      print('Account deletion error: $e');
      rethrow;
    }
  }

  // Update last login time
  Future<void> _updateLastLoginTime(String userId) async {
    try {
      print('Updating last login time for user: $userId');
      await _firestore.collection('users').doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Last login time updated successfully');
    } catch (e) {
      print('Error updating last login time: $e');
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      print('Getting user profile from Firestore for user: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        print('User profile found in Firestore');
        return UserModel.fromMap(doc.data()!);
      }
      print('User profile not found in Firestore');
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create user profile in Firestore
  Future<void> createUserProfile(UserModel user) async {
    try {
      print('Creating user profile in Firestore for user: ${user.id}');
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      print('User profile created successfully in Firestore');
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Update user profile in Firestore
  Future<bool> updateUserProfile(UserModel user) async {
    try {
      print('Updating user profile in Firestore for user: ${user.id}');
      await _firestore.collection('users').doc(user.id).update(user.toMap());
      print('User profile updated successfully in Firestore');
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Stream user profile changes
  Stream<UserModel?> getUserProfileStream(String userId) {
    try {
      print('Setting up user profile stream for user: $userId');
      return _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((doc) {
            if (doc.exists) {
              return UserModel.fromMap(doc.data()!);
            }
            return null;
          });
    } catch (e) {
      print('Error setting up user profile stream: $e');
      return Stream.value(null);
    }
  }

  // Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      print('Checking if user exists: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      final exists = doc.exists;
      print('User exists: $exists');
      return exists;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      print('Getting user by email: $email');
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        print('User found by email');
        return UserModel.fromMap(query.docs.first.data());
      }
      print('No user found with this email');
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }
}
