/// Email configuration for Legal Library application
/// This file contains email service configuration for different environments
library;

class EmailConfig {
  // Environment configuration
  static const String environment = 'development'; // 'development', 'staging', 'production'
  
  // Development email configuration
  static const bool enableEmailInDevelopment = true;
  static const bool logEmailsToConsole = true;
  
  // Email provider settings
  static const String provider = 'development'; // 'sendgrid', 'mailgun', 'aws_ses', 'development'
  
  // SendGrid configuration (for production)
  static const String sendGridApiKey = 'your-sendgrid-api-key-here';
  static const String sendGridUrl = 'https://api.sendgrid.com/v3/mail/send';
  
  // Mailgun configuration (for production)
  static const String mailgunApiKey = 'your-mailgun-api-key-here';
  static const String mailgunDomain = 'your-domain.mailgun.org';
  static const String mailgunUrl = 'https://api.mailgun.net/v3';
  
  // App configuration
  static const String fromEmail = 'noreply@legallibrary.com';
  static const String fromName = 'Legal Library Security Team';
  static const String appUrl = 'https://legallibrary.com';
  
  // Development settings
  static const String developmentEmail = 'test@legallibrary.com';
  static const bool simulateEmailDelay = true;
  static const int simulatedDelayMs = 1000;
  
  // Email templates
  static const String passwordResetSubject = 'Reset Your Legal Library Password';
  static const String passwordChangeSubject = 'Password Changed Successfully - Legal Library';
  static const String securityAlertSubject = 'Security Alert - Legal Library Account';
  
  /// Gets the appropriate email configuration based on environment
  static Map<String, dynamic> getConfig() {
    return {
      'environment': environment,
      'provider': provider,
      'enableEmailInDevelopment': enableEmailInDevelopment,
      'logEmailsToConsole': logEmailsToConsole,
      'fromEmail': fromEmail,
      'fromName': fromName,
      'appUrl': appUrl,
      'developmentEmail': developmentEmail,
      'simulateEmailDelay': simulateEmailDelay,
      'simulatedDelayMs': simulatedDelayMs,
    };
  }
  
  /// Checks if emails should be sent in current environment
  static bool shouldSendEmails() {
    switch (environment) {
      case 'development':
        return enableEmailInDevelopment;
      case 'staging':
      case 'production':
        return true;
      default:
        return false;
    }
  }
  
  /// Gets the email provider configuration
  static Map<String, String> getProviderConfig() {
    switch (provider) {
      case 'sendgrid':
        return {
          'apiKey': sendGridApiKey,
          'url': sendGridUrl,
        };
      case 'mailgun':
        return {
          'apiKey': mailgunApiKey,
          'domain': mailgunDomain,
          'url': mailgunUrl,
        };
      default:
        return {};
    }
  }
}