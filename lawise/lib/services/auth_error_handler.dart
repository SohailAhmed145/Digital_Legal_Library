import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHandler {
  // Convert Firebase Auth exceptions to user-friendly messages
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getFirebaseAuthErrorMessage(error);
    }
    
    // Handle other types of errors
    return error.toString().replaceAll('Exception: ', '');
  }

  // Get user-friendly error messages for Firebase Auth errors
  static String _getFirebaseAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      // Email/Password Sign In Errors
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or create a new account.';
      
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      
      case 'invalid-email':
        return 'Please enter a valid email address.';
      
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later or reset your password.';
      
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      
      // Sign Up Errors
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in or use a different email.';
      
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password with at least 8 characters, including uppercase, lowercase, numbers, and special characters.';
      
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      
      // Password Reset Errors
      case 'user-not-found':
        return 'No account found with this email address.';
      
      case 'invalid-email':
        return 'Please enter a valid email address.';
      
      case 'missing-email':
        return 'Please enter your email address.';
      
      // Network Errors
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      
      case 'timeout':
        return 'Request timed out. Please try again.';
      
      // Account Management Errors
      case 'requires-recent-login':
        return 'For security reasons, please sign in again to continue.';
      
      case 'credential-already-in-use':
        return 'This credential is already associated with another account.';
      
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please try again.';
      
      // Email Verification Errors
      case 'invalid-action-code':
        return 'Invalid or expired verification link. Please request a new one.';
      
      case 'expired-action-code':
        return 'Verification link has expired. Please request a new one.';
      
      // Generic Errors
      case 'internal-error':
        return 'An internal error occurred. Please try again later.';
      
      case 'invalid-api-key':
        return 'Configuration error. Please contact support.';
      
      case 'app-not-authorized':
        return 'App not authorized. Please contact support.';
      
      default:
        // Return a generic message for unknown errors
        return 'An error occurred: ${error.message ?? 'Please try again.'}';
    }
  }

  // Check if error is related to network issues
  static bool isNetworkError(dynamic error) {
    if (error is FirebaseAuthException) {
      return error.code == 'network-request-failed' || error.code == 'timeout';
    }
    return false;
  }

  // Check if error requires user to sign in again
  static bool requiresRecentLogin(dynamic error) {
    if (error is FirebaseAuthException) {
      return error.code == 'requires-recent-login';
    }
    return false;
  }

  // Check if error is related to too many attempts
  static bool isTooManyAttempts(dynamic error) {
    if (error is FirebaseAuthException) {
      return error.code == 'too-many-requests';
    }
    return false;
  }

  // Get suggestions for resolving the error
  static List<String> getErrorSuggestions(dynamic error) {
    if (error is! FirebaseAuthException) {
      return ['Please try again later.'];
    }

    switch (error.code) {
      case 'user-not-found':
        return [
          'Double-check your email address',
          'Create a new account if you don\'t have one',
          'Try signing in with a different method'
        ];
      
      case 'wrong-password':
        return [
          'Check your password carefully',
          'Use the "Forgot Password" option to reset',
          'Make sure Caps Lock is off'
        ];
      
      case 'weak-password':
        return [
          'Use at least 8 characters',
          'Include uppercase and lowercase letters',
          'Add numbers and special characters',
          'Avoid common words or patterns'
        ];
      
      case 'email-already-in-use':
        return [
          'Try signing in instead of creating an account',
          'Use the "Forgot Password" option if needed',
          'Check if you have an existing account'
        ];
      
      case 'network-request-failed':
        return [
          'Check your internet connection',
          'Try connecting to a different network',
          'Wait a moment and try again'
        ];
      
      case 'too-many-requests':
        return [
          'Wait a few minutes before trying again',
          'Use the "Forgot Password" option',
          'Contact support if the issue persists'
        ];
      
      default:
        return ['Please try again later.'];
    }
  }
}