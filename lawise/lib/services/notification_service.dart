import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'email_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EmailService _emailService = EmailService();
  
  /// Sends a password change confirmation notification
  Future<Map<String, dynamic>> sendPasswordChangeNotification({
    required String userId,
    required String email,
    required String changeMethod,
    String? ipAddress,
    String? userAgent,
    String? deviceInfo,
  }) async {
    try {
      final timestamp = DateTime.now();
      
      // Create notification record in Firestore
      final notificationData = {
        'userId': userId,
        'email': email,
        'type': 'password_change',
        'method': changeMethod,
        'timestamp': timestamp,
        'ipAddress': ipAddress ?? 'unknown',
        'userAgent': userAgent ?? 'unknown',
        'deviceInfo': deviceInfo ?? 'unknown',
        'status': 'sent',
        'read': false,
      };
      
      // Store notification in Firestore
      final docRef = await _firestore
          .collection('notifications')
          .add(notificationData);
      
      // Send email notification
      final emailResult = await _emailService.sendPasswordChangeConfirmation(
        toEmail: email,
        changeMethod: changeMethod,
        timestamp: timestamp,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );
      
      // Update notification status based on email result
      await docRef.update({
        'emailSent': emailResult['success'],
        'emailError': emailResult['error'],
      });
      
      return {
        'success': true,
        'message': 'Password change notification sent successfully',
        'notificationId': docRef.id,
        'emailSent': emailResult['success'],
      };
    } catch (e) {
      debugPrint('Error sending password change notification: $e');
      return {
        'success': false,
        'message': 'Failed to send notification',
        'error': e.toString(),
      };
    }
  }
  
  /// Sends a password reset request notification
  Future<Map<String, dynamic>> sendPasswordResetNotification({
    required String email,
    required String resetToken,
    required DateTime expiryTime,
    String? ipAddress,
  }) async {
    try {
      final timestamp = DateTime.now();
      
      // Create notification record
      final notificationData = {
        'email': email,
        'type': 'password_reset_request',
        'resetToken': resetToken,
        'expiryTime': expiryTime,
        'timestamp': timestamp,
        'ipAddress': ipAddress ?? 'unknown',
        'status': 'sent',
        'used': false,
      };
      
      // Store notification in Firestore
      final docRef = await _firestore
          .collection('notifications')
          .add(notificationData);
      
      // Send email with reset link
      final emailResult = await _emailService.sendPasswordResetEmail(
        toEmail: email,
        resetToken: resetToken,
        expiryTime: expiryTime,
      );
      
      // Update notification status
      await docRef.update({
        'emailSent': emailResult['success'],
        'emailError': emailResult['error'],
      });
      
      return {
        'success': true,
        'message': 'Password reset notification sent successfully',
        'notificationId': docRef.id,
        'emailSent': emailResult['success'],
      };
    } catch (e) {
      debugPrint('Error sending password reset notification: $e');
      return {
        'success': false,
        'message': 'Failed to send reset notification',
        'error': e.toString(),
      };
    }
  }
  
  /// Sends a security alert notification
  Future<Map<String, dynamic>> sendSecurityAlert({
    required String userId,
    required String email,
    required String alertType,
    required String description,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final timestamp = DateTime.now();
      
      // Create security alert record
      final alertData = {
        'userId': userId,
        'email': email,
        'type': 'security_alert',
        'alertType': alertType,
        'description': description,
        'timestamp': timestamp,
        'ipAddress': ipAddress ?? 'unknown',
        'userAgent': userAgent ?? 'unknown',
        'status': 'sent',
        'severity': _getAlertSeverity(alertType),
      };
      
      // Store alert in Firestore
      final docRef = await _firestore
          .collection('security_alerts')
          .add(alertData);
      
      // Send email alert
      final emailResult = await _emailService.sendSecurityAlert(
        toEmail: email,
        alertType: alertType,
        description: description,
        timestamp: timestamp,
        ipAddress: ipAddress,
      );
      
      // Update alert status
      await docRef.update({
        'emailSent': emailResult['success'],
        'emailError': emailResult['error'],
      });
      
      return {
        'success': true,
        'message': 'Security alert sent successfully',
        'alertId': docRef.id,
        'emailSent': emailResult['success'],
      };
    } catch (e) {
      debugPrint('Error sending security alert: $e');
      return {
        'success': false,
        'message': 'Failed to send security alert',
        'error': e.toString(),
      };
    }
  }
  

  

  
  /// Gets alert severity level
  String _getAlertSeverity(String alertType) {
    switch (alertType) {
      case 'multiple_failed_logins':
      case 'suspicious_location':
        return 'high';
      case 'password_change':
        return 'medium';
      case 'account_locked':
        return 'critical';
      default:
        return 'low';
    }
  }
  
  /// Gets user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }
  
  /// Marks notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true, 'readAt': DateTime.now()});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
  
  /// Cleans up old notifications (older than 90 days)
  Future<void> cleanupOldNotifications() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('timestamp', isLessThan: cutoffDate)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('Cleaned up ${querySnapshot.docs.length} old notifications');
    } catch (e) {
      debugPrint('Error cleaning up old notifications: $e');
    }
  }
}