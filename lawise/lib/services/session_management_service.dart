import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class SessionManagementService {
  static const String _lastPasswordChangeKey = 'last_password_change';
  static const String _sessionTokenKey = 'session_token';
  static const String _deviceIdKey = 'device_id';
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  
  /// Terminates the current session immediately after password change
  /// This ensures security by forcing re-authentication
  Future<Map<String, dynamic>> terminateSessionAfterPasswordChange({
    required String userId,
    String? reason,
  }) async {
    try {
      // Record the password change timestamp
      await _recordPasswordChangeTime(userId);
      
      // Clear local session data
      await _clearLocalSessionData();
      
      // Sign out from Firebase Auth
      await _auth.signOut();
      
      // Clear any cached user data
      await _clearUserCache();
      
      // Invalidate any stored tokens
      await _invalidateStoredTokens();
      
      return {
        'success': true,
        'message': 'Session terminated successfully for security. Please sign in again.',
        'reason': reason ?? 'Password changed',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error terminating session: $e');
      return {
        'success': false,
        'message': 'Failed to terminate session properly',
        'error': e.toString(),
      };
    }
  }
  
  /// Records the timestamp of password change for security tracking
  Future<void> _recordPasswordChangeTime(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('${_lastPasswordChangeKey}_$userId', timestamp);
    } catch (e) {
      debugPrint('Error recording password change time: $e');
    }
  }
  
  /// Clears all local session data
  Future<void> _clearLocalSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove session-related keys
      await prefs.remove(_sessionTokenKey);
      await prefs.remove(_deviceIdKey);
      
      // Remove any user preference data that should not persist
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('user_') || 
            key.startsWith('session_') ||
            key.startsWith('cache_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing local session data: $e');
    }
  }
  
  /// Clears user cache and temporary data
  Future<void> _clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear cached user profile data
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.contains('profile_') || 
            key.contains('user_data_') ||
            key.contains('temp_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing user cache: $e');
    }
  }
  
  /// Invalidates any stored authentication tokens
  Future<void> _invalidateStoredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove any stored tokens
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.contains('token') || 
            key.contains('auth_') ||
            key.contains('refresh_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error invalidating stored tokens: $e');
    }
  }
  
  /// Checks if a session should be terminated due to password change
  Future<bool> shouldTerminateSession(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPasswordChange = prefs.getInt('${_lastPasswordChangeKey}_$userId');
      
      if (lastPasswordChange == null) {
        return false;
      }
      
      final changeTime = DateTime.fromMillisecondsSinceEpoch(lastPasswordChange);
      final now = DateTime.now();
      
      // If password was changed in the last 5 minutes, consider terminating session
      return now.difference(changeTime).inMinutes < 5;
    } catch (e) {
      debugPrint('Error checking session termination: $e');
      return false;
    }
  }
  
  /// Forces immediate logout with custom message
  Future<Map<String, dynamic>> forceLogout({
    required String reason,
    String? customMessage,
  }) async {
    try {
      // Clear all session data
      await _clearLocalSessionData();
      await _clearUserCache();
      await _invalidateStoredTokens();
      
      // Sign out from Firebase
      await _auth.signOut();
      
      return {
        'success': true,
        'message': customMessage ?? 'You have been logged out for security reasons.',
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error forcing logout: $e');
      return {
        'success': false,
        'message': 'Failed to logout properly',
        'error': e.toString(),
      };
    }
  }
  
  /// Gets the last password change time for a user
  Future<DateTime?> getLastPasswordChangeTime(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('${_lastPasswordChangeKey}_$userId');
      
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last password change time: $e');
      return null;
    }
  }
  
  /// Validates current session integrity
  Future<bool> validateSessionIntegrity() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }
      
      // Check if user should be logged out due to recent password change
      final shouldTerminate = await shouldTerminateSession(user.uid);
      if (shouldTerminate) {
        await forceLogout(
          reason: 'Password recently changed',
          customMessage: 'Your session has been terminated due to a recent password change. Please sign in again.',
        );
        return false;
      }
      
      // Refresh the user's token to ensure it's still valid
      await user.getIdToken(true);
      
      return true;
    } catch (e) {
      debugPrint('Session validation failed: $e');
      // If token refresh fails, the session is invalid
      await forceLogout(
        reason: 'Invalid session token',
        customMessage: 'Your session has expired. Please sign in again.',
      );
      return false;
    }
  }
  
  /// Clears all session data for a specific user
  Future<void> clearUserSessionData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove user-specific data
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.contains(userId)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing user session data: $e');
    }
  }
  
  /// Sets up session monitoring for automatic termination
  void startSessionMonitoring() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Validate session when user state changes
        await validateSessionIntegrity();
      }
    });
  }
  
  /// Stops session monitoring
  void stopSessionMonitoring() {
    // Implementation would depend on how monitoring is set up
    // For now, this is a placeholder for future enhancement
  }
}