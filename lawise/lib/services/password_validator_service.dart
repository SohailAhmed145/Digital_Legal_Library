import 'dart:math';

class PasswordStrength {
  final int score; // 0-4 (very weak to very strong)
  final String label;
  final double progress; // 0.0-1.0
  final List<String> suggestions;
  final List<String> warnings;
  final bool isValid;

  const PasswordStrength({
    required this.score,
    required this.label,
    required this.progress,
    required this.suggestions,
    required this.warnings,
    required this.isValid,
  });
}

class PasswordValidatorService {
  static const int minLength = 8;
  static const int maxLength = 128;
  static const int strongMinLength = 12;
  
  // Minimum requirements for a valid password
  static const Map<String, String> requirements = {
    'length': 'At least 8 characters long',
    'uppercase': 'At least one uppercase letter (A-Z)',
    'lowercase': 'At least one lowercase letter (a-z)',
    'number': 'At least one number (0-9)',
    'special': 'At least one special character (!@#\$%^&*)',
  };
  
  // Common weak passwords and patterns
  static const List<String> commonPasswords = [
    'password', '123456', '123456789', 'qwerty', 'abc123',
    'password123', 'admin', 'letmein', 'welcome', 'monkey',
    'dragon', 'master', 'shadow', 'superman', 'michael',
    'football', 'baseball', 'liverpool', 'jordan', 'harley',
  ];

  static const List<String> commonPatterns = [
    r'123', r'abc', r'qwe', r'asd', r'zxc',
  ];

  // Validate password strength in real-time
  static PasswordStrength validatePassword(String password) {
    if (password.isEmpty) {
      return const PasswordStrength(
        score: 0,
        label: 'Enter a password',
        progress: 0.0,
        suggestions: ['Start typing your password'],
        warnings: [],
        isValid: false,
      );
    }

    final suggestions = <String>[];
    final warnings = <String>[];
    int score = 0;
    
    // Check length
    if (password.length < minLength) {
      warnings.add('Password must be at least $minLength characters long');
    } else if (password.length >= minLength) {
      score += 1;
    }
    
    if (password.length > maxLength) {
      warnings.add('Password must be less than $maxLength characters');
    }
    
    // Additional length bonus for stronger passwords
    if (password.length < strongMinLength) {
      suggestions.add('Use at least $strongMinLength characters for better security');
    }

    // Check for uppercase letters (required)
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    if (hasUppercase) {
      score += 1;
    } else {
      warnings.add('Must contain at least one uppercase letter (A-Z)');
      suggestions.add('Add uppercase letters (A-Z)');
    }

    // Check for lowercase letters (required)
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    if (hasLowercase) {
      score += 1;
    } else {
      warnings.add('Must contain at least one lowercase letter (a-z)');
      suggestions.add('Add lowercase letters (a-z)');
    }

    // Check for numbers (required)
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    if (hasNumbers) {
      score += 1;
    } else {
      warnings.add('Must contain at least one number (0-9)');
      suggestions.add('Add numbers (0-9)');
    }

    // Check for special characters (required)
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (hasSpecialChars) {
      score += 1;
    } else {
      warnings.add('Must contain at least one special character (!@#\$%^&*)');
      suggestions.add('Add special characters (!@#\$%^&*)');
    }

    // Check for common passwords
    if (_isCommonPassword(password.toLowerCase())) {
      warnings.add('This is a commonly used password');
      score = max(0, score - 2);
    }

    // Check for common patterns
    if (_hasCommonPatterns(password.toLowerCase())) {
      warnings.add('Avoid common patterns like 123 or abc');
      score = max(0, score - 1);
    }

    // Check for repeated characters
    if (_hasRepeatedCharacters(password)) {
      warnings.add('Avoid repeating characters');
      score = max(0, score - 1);
    }

    // Check for keyboard patterns
    if (_hasKeyboardPatterns(password.toLowerCase())) {
      warnings.add('Avoid keyboard patterns like qwerty');
      score = max(0, score - 1);
    }

    // Bonus points for longer passwords
    if (password.length >= 12) {
      score += 1;
    }
    if (password.length >= 16) {
      score += 1;
    }

    // Cap the score at 4
    score = min(4, score);

    final strengthData = _getStrengthData(score);
    // Password is valid only if it meets all basic requirements (no warnings) and has good score
    final isValid = warnings.isEmpty && score >= 4;

    return PasswordStrength(
      score: score,
      label: strengthData['label']!,
      progress: score / 4.0,
      suggestions: suggestions,
      warnings: warnings,
      isValid: isValid,
    );
  }

  // Check if passwords match
  static bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  // Validate password confirmation
  static String? validatePasswordConfirmation(
    String password,
    String confirmPassword,
  ) {
    if (confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (!passwordsMatch(password, confirmPassword)) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Get strength data based on score
  static Map<String, String> _getStrengthData(int score) {
    switch (score) {
      case 0:
      case 1:
        return {
          'label': 'Very Weak',
          'color': 'red',
        };
      case 2:
        return {
          'label': 'Weak',
          'color': 'orange',
        };
      case 3:
        return {
          'label': 'Good',
          'color': 'yellow',
        };
      case 4:
      default:
        return {
          'label': 'Strong',
          'color': 'green',
        };
    }
  }

  // Check if password is in common passwords list
  static bool _isCommonPassword(String password) {
    return commonPasswords.contains(password);
  }

  // Check for common patterns
  static bool _hasCommonPatterns(String password) {
    for (final pattern in commonPatterns) {
      if (password.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  // Check for repeated characters (3 or more in a row)
  static bool _hasRepeatedCharacters(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i] == password[i + 2]) {
        return true;
      }
    }
    return false;
  }

  // Check for keyboard patterns
  static bool _hasKeyboardPatterns(String password) {
    final keyboardPatterns = [
      'qwerty', 'asdf', 'zxcv', 'qwertyuiop',
      'asdfghjkl', 'zxcvbnm', '1234567890',
    ];
    
    for (final pattern in keyboardPatterns) {
      if (password.contains(pattern) || 
          password.contains(pattern.split('').reversed.join())) {
        return true;
      }
    }
    return false;
  }

  // Generate password suggestions
  static List<String> generatePasswordSuggestions() {
    final random = Random.secure();
    final suggestions = <String>[];
    
    // Generate 3 different password suggestions
    for (int i = 0; i < 3; i++) {
      final password = _generateSecurePassword(random);
      suggestions.add(password);
    }
    
    return suggestions;
  }

  // Generate a secure password
  static String _generateSecurePassword(Random random) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    
    const allChars = uppercase + lowercase + numbers + symbols;
    final length = 12 + random.nextInt(5); // 12-16 characters
    
    String password = '';
    
    // Ensure at least one character from each category
    password += uppercase[random.nextInt(uppercase.length)];
    password += lowercase[random.nextInt(lowercase.length)];
    password += numbers[random.nextInt(numbers.length)];
    password += symbols[random.nextInt(symbols.length)];
    
    // Fill the rest randomly
    for (int i = 4; i < length; i++) {
      password += allChars[random.nextInt(allChars.length)];
    }
    
    // Shuffle the password
    final chars = password.split('');
    chars.shuffle(random);
    
    return chars.join('');
  }

  // Check if password meets minimum requirements
  static bool meetsMinimumRequirements(String password) {
    final strength = validatePassword(password);
    return strength.isValid;
  }

  // Get validation error message for forms
  static String? getValidationError(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    
    final strength = validatePassword(password);
    
    // Return the first warning as the primary error
    if (strength.warnings.isNotEmpty) {
      return strength.warnings.first;
    }
    
    // If no warnings but password is still weak
    if (!strength.isValid) {
      return 'Password is too weak. Please follow the suggestions above.';
    }
    
    return null;
  }

  // Get all requirement violations
  static List<String> getRequirementViolations(String password) {
    final violations = <String>[];
    
    if (password.length < minLength) {
      violations.add(requirements['length']!);
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      violations.add(requirements['uppercase']!);
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      violations.add(requirements['lowercase']!);
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      violations.add(requirements['number']!);
    }
    
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      violations.add(requirements['special']!);
    }
    
    return violations;
  }

  // Get password entropy (bits)
  static double calculateEntropy(String password) {
    if (password.isEmpty) return 0.0;
    
    int charsetSize = 0;
    
    if (password.contains(RegExp(r'[a-z]'))) charsetSize += 26;
    if (password.contains(RegExp(r'[A-Z]'))) charsetSize += 26;
    if (password.contains(RegExp(r'[0-9]'))) charsetSize += 10;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) charsetSize += 32;
    
    if (charsetSize == 0) return 0.0;
    
    return password.length * (log(charsetSize) / log(2));
  }

  // Estimate time to crack password
  static String estimateTimeToCrack(String password) {
    final entropy = calculateEntropy(password);
    
    if (entropy < 30) {
      return 'Instantly';
    } else if (entropy < 40) {
      return 'Minutes';
    } else if (entropy < 50) {
      return 'Hours';
    } else if (entropy < 60) {
      return 'Days';
    } else if (entropy < 70) {
      return 'Years';
    } else {
      return 'Centuries';
    }
  }

  // Check if passwords match
  static bool doPasswordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }
}