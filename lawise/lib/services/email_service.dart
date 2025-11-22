import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/email_config.dart';

/// Email service for sending transactional emails
/// This service can be configured to work with various email providers
class EmailService {
  // Get configuration from EmailConfig
  static final Map<String, dynamic> _config = EmailConfig.getConfig();
  static final Map<String, String> _providerConfig = EmailConfig.getProviderConfig();
  
  // Email provider configuration
  static String get _provider => _config['provider'] as String;
  
  // App configuration
  static String get _fromEmail => _config['fromEmail'] as String;
  static String get _fromName => _config['fromName'] as String;
  static String get _appUrl => _config['appUrl'] as String;
  
  /// Sends a password reset email with a secure reset link
  Future<Map<String, dynamic>> sendPasswordResetEmail({
    required String toEmail,
    required String resetToken,
    required DateTime expiryTime,
    String? userName,
  }) async {
    try {
      final resetLink = '$_appUrl/reset-password?token=$resetToken';
      final expiryMinutes = expiryTime.difference(DateTime.now()).inMinutes;
      
      final emailData = {
        'to': toEmail,
        'subject': 'Reset Your Legal Library Password',
        'html': _buildPasswordResetEmailHtml(
          resetLink: resetLink,
          expiryMinutes: expiryMinutes,
          userName: userName,
        ),
        'text': _buildPasswordResetEmailText(
          resetLink: resetLink,
          expiryMinutes: expiryMinutes,
          userName: userName,
        ),
      };
      
      return await _sendEmail(emailData);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Sends a password change confirmation email
  Future<Map<String, dynamic>> sendPasswordChangeConfirmation({
    required String toEmail,
    required String changeMethod,
    required DateTime timestamp,
    String? userName,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    try {
      final emailData = {
        'to': toEmail,
        'subject': 'Password Changed Successfully - Legal Library',
        'html': _buildPasswordChangeEmailHtml(
          changeMethod: changeMethod,
          timestamp: timestamp,
          userName: userName,
          ipAddress: ipAddress,
          deviceInfo: deviceInfo,
        ),
        'text': _buildPasswordChangeEmailText(
          changeMethod: changeMethod,
          timestamp: timestamp,
          userName: userName,
          ipAddress: ipAddress,
          deviceInfo: deviceInfo,
        ),
      };
      
      return await _sendEmail(emailData);
    } catch (e) {
      debugPrint('Error sending password change confirmation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Sends a security alert email
  Future<Map<String, dynamic>> sendSecurityAlert({
    required String toEmail,
    required String alertType,
    required String description,
    required DateTime timestamp,
    String? userName,
    String? ipAddress,
  }) async {
    try {
      final emailData = {
        'to': toEmail,
        'subject': 'Security Alert - Legal Library Account',
        'html': _buildSecurityAlertEmailHtml(
          alertType: alertType,
          description: description,
          timestamp: timestamp,
          userName: userName,
          ipAddress: ipAddress,
        ),
        'text': _buildSecurityAlertEmailText(
          alertType: alertType,
          description: description,
          timestamp: timestamp,
          userName: userName,
          ipAddress: ipAddress,
        ),
      };
      
      return await _sendEmail(emailData);
    } catch (e) {
      debugPrint('Error sending security alert: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Core email sending method that routes to the configured provider
  Future<Map<String, dynamic>> _sendEmail(Map<String, dynamic> emailData) async {
    // Check if emails should be sent in current environment
    if (!EmailConfig.shouldSendEmails()) {
      debugPrint('Email sending disabled in current environment');
      return {
        'success': false,
        'error': 'Email sending disabled in current environment',
      };
    }
    
    switch (_provider) {
      case 'sendgrid':
        return await _sendWithSendGrid(emailData);
      case 'mailgun':
        return await _sendWithMailgun(emailData);
      case 'aws_ses':
        return await _sendWithAwsSes(emailData);
      case 'firebase':
        return await _sendWithFirebase(emailData);
      case 'development':
      default:
        // For development/demo, log the email with enhanced visibility
        return await _logEmailForDevelopment(emailData);
    }
  }
  
  /// Sends email using SendGrid API
  Future<Map<String, dynamic>> _sendWithSendGrid(Map<String, dynamic> emailData) async {
    try {
      final apiKey = _providerConfig['apiKey'];
      final url = _providerConfig['url'];
      
      if (apiKey == null || url == null || apiKey.contains('your-')) {
        return {
          'success': false,
          'error': 'SendGrid API key not configured properly',
        };
      }
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [{'email': emailData['to']}],
              'subject': emailData['subject'],
            }
          ],
          'from': {
            'email': _fromEmail,
            'name': _fromName,
          },
          'content': [
            {
              'type': 'text/plain',
              'value': emailData['text'],
            },
            {
              'type': 'text/html',
              'value': emailData['html'],
            },
          ],
        }),
      );
      
      if (response.statusCode == 202) {
        return {
          'success': true,
          'message': 'Email sent successfully via SendGrid',
        };
      } else {
        return {
          'success': false,
          'error': 'SendGrid API error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'SendGrid error: $e',
      };
    }
  }
  
  /// Sends email using Mailgun API
  Future<Map<String, dynamic>> _sendWithMailgun(Map<String, dynamic> emailData) async {
    try {
      final apiKey = _providerConfig['apiKey'];
      final domain = _providerConfig['domain'];
      final url = _providerConfig['url'];
      
      if (apiKey == null || domain == null || url == null || apiKey.contains('your-')) {
        return {
          'success': false,
          'error': 'Mailgun API configuration not set up properly',
        };
      }
      
      final response = await http.post(
        Uri.parse('$url/$domain/messages'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('api:$apiKey'))}',
        },
        body: {
          'from': '$_fromName <$_fromEmail>',
          'to': emailData['to'],
          'subject': emailData['subject'],
          'text': emailData['text'],
          'html': emailData['html'],
        },
      );
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Email sent successfully via Mailgun',
        };
      } else {
        return {
          'success': false,
          'error': 'Mailgun API error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Mailgun error: $e',
      };
    }
  }
  
  /// Sends email using AWS SES (placeholder implementation)
  Future<Map<String, dynamic>> _sendWithAwsSes(Map<String, dynamic> emailData) async {
    // This would require AWS SDK integration
    // For now, return a placeholder response
    debugPrint('AWS SES integration not implemented yet');
    return {
      'success': false,
      'error': 'AWS SES integration not implemented',
    };
  }
  
  /// Sends email using Firebase Extensions (placeholder implementation)
  Future<Map<String, dynamic>> _sendWithFirebase(Map<String, dynamic> emailData) async {
    // This would use Firebase Extensions for email sending
    // For now, return a placeholder response
    debugPrint('Firebase email extension not implemented yet');
    return {
      'success': false,
      'error': 'Firebase email extension not implemented',
    };
  }
  
  /// Logs email content for development purposes
  Future<Map<String, dynamic>> _logEmailForDevelopment(Map<String, dynamic> emailData) async {
    final timestamp = DateTime.now().toIso8601String();
    
    print('\n${'='*60}');
    print('📧 EMAIL SENT IN DEVELOPMENT MODE');
    print('='*60);
    print('⏰ Timestamp: $timestamp');
    print('📮 To: ${emailData['to']}');
    print('📝 Subject: ${emailData['subject']}');
    print('-'*60);
    print('📄 Text Content:');
    print(emailData['text']);
    print('-'*60);
    print('🌐 HTML Content:');
    print(emailData['html']);
    print('='*60);
    print('✅ EMAIL LOGGED SUCCESSFULLY');
    print('='*60 + '\n');
    
    // Simulate email sending delay if configured
    if (_config['simulateEmailDelay'] as bool) {
      final delayMs = _config['simulatedDelayMs'] as int;
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    
    return {
      'success': true,
      'message': 'Email logged for development - Check console for details',
      'timestamp': timestamp,
      'recipient': emailData['to'],
      'subject': emailData['subject'],
    };
  }
  
  /// Builds HTML content for password reset email
  String _buildPasswordResetEmailHtml({
    required String resetLink,
    required int expiryMinutes,
    String? userName,
  }) {
    final greeting = userName != null ? 'Dear $userName,' : 'Dear User,';
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Your Password</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #2196F3; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .button { display: inline-block; padding: 12px 24px; background-color: #2196F3; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .warning { background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Legal Library</h1>
            <h2>Password Reset Request</h2>
        </div>
        <div class="content">
            <p>$greeting</p>
            <p>We received a request to reset your password. Click the button below to create a new password:</p>
            <p style="text-align: center;">
                <a href="$resetLink" class="button">Reset Password</a>
            </p>
            <div class="warning">
                <strong>⚠️ Important:</strong>
                <ul>
                    <li>This link will expire in $expiryMinutes minutes</li>
                    <li>For security, you can only use this link once</li>
                    <li>If you didn't request this reset, please ignore this email</li>
                </ul>
            </div>
            <p>If the button doesn't work, copy and paste this link into your browser:</p>
            <p style="word-break: break-all; background-color: #f0f0f0; padding: 10px; border-radius: 3px;">$resetLink</p>
        </div>
        <div class="footer">
            <p>This email was sent by Legal Library Security Team</p>
            <p>If you have questions, contact our support team</p>
        </div>
    </div>
</body>
</html>
''';
  }
  
  /// Builds text content for password reset email
  String _buildPasswordResetEmailText({
    required String resetLink,
    required int expiryMinutes,
    String? userName,
  }) {
    final greeting = userName != null ? 'Dear $userName,' : 'Dear User,';
    
    return '''
$greeting

We received a request to reset your password for your Legal Library account.

To reset your password, click the following link:
$resetLink

IMPORTANT:
- This link will expire in $expiryMinutes minutes
- You can only use this link once
- If you didn't request this reset, please ignore this email

If you have any questions, please contact our support team.

Best regards,
The Legal Library Security Team
''';
  }
  
  /// Builds HTML content for password change confirmation email
  String _buildPasswordChangeEmailHtml({
    required String changeMethod,
    required DateTime timestamp,
    String? userName,
    String? ipAddress,
    String? deviceInfo,
  }) {
    final greeting = userName != null ? 'Dear $userName,' : 'Dear User,';
    final methodDescription = _getChangeMethodDescription(changeMethod);
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Password Changed Successfully</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .details { background-color: white; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .warning { background-color: #ffebee; border: 1px solid #f8bbd9; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Legal Library</h1>
            <h2>✅ Password Changed Successfully</h2>
        </div>
        <div class="content">
            <p>$greeting</p>
            <p>Your password has been successfully changed.</p>
            <div class="details">
                <h3>Change Details:</h3>
                <ul>
                    <li><strong>Method:</strong> $methodDescription</li>
                    <li><strong>Time:</strong> ${timestamp.toLocal().toString()}</li>
                    <li><strong>IP Address:</strong> ${ipAddress ?? 'Unknown'}</li>
                    <li><strong>Device:</strong> ${deviceInfo ?? 'Unknown'}</li>
                </ul>
            </div>
            <div class="warning">
                <strong>🔒 Security Notice:</strong>
                <p>For your security, you have been logged out of all devices and will need to sign in again with your new password.</p>
            </div>
            <p>If you did not make this change, please contact our support team immediately.</p>
        </div>
        <div class="footer">
            <p>This email was sent by Legal Library Security Team</p>
            <p>If you have questions, contact our support team</p>
        </div>
    </div>
</body>
</html>
''';
  }
  
  /// Builds text content for password change confirmation email
  String _buildPasswordChangeEmailText({
    required String changeMethod,
    required DateTime timestamp,
    String? userName,
    String? ipAddress,
    String? deviceInfo,
  }) {
    final greeting = userName != null ? 'Dear $userName,' : 'Dear User,';
    final methodDescription = _getChangeMethodDescription(changeMethod);
    
    return '''
$greeting

Your password has been successfully changed.

Change Details:
- Method: $methodDescription
- Time: ${timestamp.toLocal().toString()}
- IP Address: ${ipAddress ?? 'Unknown'}
- Device: ${deviceInfo ?? 'Unknown'}

SECURITY NOTICE:
For your security, you have been logged out of all devices and will need to sign in again with your new password.

If you did not make this change, please contact our support team immediately.

Best regards,
The Legal Library Security Team
''';
  }
  
  /// Builds HTML content for security alert email
  String _buildSecurityAlertEmailHtml({
    required String alertType,
    required String description,
    required DateTime timestamp,
    String? userName,
    String? ipAddress,
  }) {
    final greeting = userName != null ? 'Dear $userName,' : 'Dear User,';
    final alertDescription = _getAlertTypeDescription(alertType);
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Alert</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #f44336; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .alert { background-color: #ffebee; border: 1px solid #f8bbd9; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .actions { background-color: white; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Legal Library</h1>
            <h2>🚨 Security Alert</h2>
        </div>
        <div class="content">
            <p>$greeting</p>
            <p>We detected unusual activity on your account:</p>
            <div class="alert">
                <h3>Alert Details:</h3>
                <ul>
                    <li><strong>Type:</strong> $alertDescription</li>
                    <li><strong>Description:</strong> $description</li>
                    <li><strong>Time:</strong> ${timestamp.toLocal().toString()}</li>
                    <li><strong>IP Address:</strong> ${ipAddress ?? 'Unknown'}</li>
                </ul>
            </div>
            <div class="actions">
                <h3>Recommended Actions:</h3>
                <p>If this was you, no action is needed. If you don't recognize this activity, please:</p>
                <ol>
                    <li>Change your password immediately</li>
                    <li>Review your account settings</li>
                    <li>Contact our support team</li>
                </ol>
            </div>
        </div>
        <div class="footer">
            <p>This email was sent by Legal Library Security Team</p>
            <p>If you have questions, contact our support team</p>
        </div>
    </div>
</body>
</html>
''';
  }
  
  /// Builds text content for security alert email
  String _buildSecurityAlertEmailText({
    required String alertType,
    required String description,
    required DateTime timestamp,
    String? userName,
    String? ipAddress,
  }) {
    final greeting = userName != null ? 'Dear $userName,' : 'Dear User,';
    final alertDescription = _getAlertTypeDescription(alertType);
    
    return '''
$greeting

We detected unusual activity on your account:

Alert Details:
- Type: $alertDescription
- Description: $description
- Time: ${timestamp.toLocal().toString()}
- IP Address: ${ipAddress ?? 'Unknown'}

RECOMMENDED ACTIONS:
If this was you, no action is needed. If you don't recognize this activity, please:
1. Change your password immediately
2. Review your account settings
3. Contact our support team

Best regards,
The Legal Library Security Team
''';
  }
  
  /// Gets user-friendly description for change method
  String _getChangeMethodDescription(String method) {
    switch (method) {
      case 'reset_token':
        return 'Password Reset Link';
      case 'authenticated_change':
        return 'Account Settings';
      case 'admin_reset':
        return 'Administrative Reset';
      default:
        return 'Unknown Method';
    }
  }
  
  /// Gets user-friendly description for alert type
  String _getAlertTypeDescription(String alertType) {
    switch (alertType) {
      case 'multiple_failed_logins':
        return 'Multiple Failed Login Attempts';
      case 'password_change':
        return 'Password Changed';
      case 'suspicious_location':
        return 'Login from New Location';
      case 'account_locked':
        return 'Account Temporarily Locked';
      default:
        return alertType;
    }
  }
}