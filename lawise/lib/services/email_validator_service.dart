class EmailValidatorService {
  // Enhanced email regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Common email domains for suggestions
  static const List<String> commonDomains = [
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
    'outlook.com',
    'icloud.com',
    'aol.com',
  ];

  // Validate email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  // Get validation error message for forms
  static String? getValidationError(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }

    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      return 'Email cannot be empty';
    }

    if (!_emailRegex.hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address';
    }

    // Additional checks
    if (trimmedEmail.length > 254) {
      return 'Email address is too long';
    }

    if (trimmedEmail.startsWith('.') || trimmedEmail.endsWith('.')) {
      return 'Email cannot start or end with a period';
    }

    if (trimmedEmail.contains('..')) {
      return 'Email cannot contain consecutive periods';
    }

    return null;
  }

  // Suggest email corrections for common typos
  static String? suggestEmailCorrection(String email) {
    if (!isValidEmail(email)) return null;

    final parts = email.toLowerCase().split('@');
    if (parts.length != 2) return null;

    final domain = parts[1];
    
    // Common typo corrections
    final corrections = {
      'gmai.com': 'gmail.com',
      'gmial.com': 'gmail.com',
      'gmail.co': 'gmail.com',
      'yahooo.com': 'yahoo.com',
      'yaho.com': 'yahoo.com',
      'hotmial.com': 'hotmail.com',
      'hotmai.com': 'hotmail.com',
      'outlok.com': 'outlook.com',
      'outloo.com': 'outlook.com',
    };

    if (corrections.containsKey(domain)) {
      return '${parts[0]}@${corrections[domain]}';
    }

    return null;
  }

  // Check if email domain is commonly used
  static bool isCommonDomain(String email) {
    if (!isValidEmail(email)) return false;
    
    final domain = email.split('@')[1].toLowerCase();
    return commonDomains.contains(domain);
  }

  // Normalize email (trim and lowercase)
  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  // Check for disposable email domains (basic list)
  static bool isDisposableEmail(String email) {
    if (!isValidEmail(email)) return false;
    
    final domain = email.split('@')[1].toLowerCase();
    
    // Basic list of known disposable email domains
    const disposableDomains = [
      '10minutemail.com',
      'tempmail.org',
      'guerrillamail.com',
      'mailinator.com',
      'throwaway.email',
      'temp-mail.org',
    ];
    
    return disposableDomains.contains(domain);
  }

  // Get email validation warnings
  static List<String> getEmailWarnings(String email) {
    final warnings = <String>[];
    
    if (!isValidEmail(email)) {
      return warnings;
    }
    
    if (isDisposableEmail(email)) {
      warnings.add('Disposable email addresses may not receive important notifications');
    }
    
    final suggestion = suggestEmailCorrection(email);
    if (suggestion != null) {
      warnings.add('Did you mean: $suggestion?');
    }
    
    return warnings;
  }
}