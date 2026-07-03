// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';

/// Result of a validation operation.
class GchValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> suggestions;

  const GchValidationResult({
    required this.isValid,
    this.errorMessage,
    this.suggestions = const [],
  });

  factory GchValidationResult.ok() {
    return const GchValidationResult(isValid: true);
  }

  factory GchValidationResult.fail(String message, {List<String> suggestions = const []}) {
    return GchValidationResult(isValid: false, errorMessage: message, suggestions: suggestions);
  }

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $errorMessage';
}

/// Password strength levels.
enum GchPasswordStrength {
  veryWeak,
  weak,
  fair,
  strong,
  veryStrong;

  String get label {
    switch (this) {
      case GchPasswordStrength.veryWeak:
        return 'Very Weak';
      case GchPasswordStrength.weak:
        return 'Weak';
      case GchPasswordStrength.fair:
        return 'Fair';
      case GchPasswordStrength.strong:
        return 'Strong';
      case GchPasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  int get score {
    return index;
  }
}

/// Comprehensive validation utility class.
class GchValidator {
  GchValidator._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _urlRegex = RegExp(
    r'^(https?|ftp)://[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
  );

  static final RegExp _ipv4Regex = RegExp(
    r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
  );

  static final RegExp _ipv6Regex = RegExp(
    r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|'
    r'^::([0-9a-fA-F]{1,4}:){0,6}[0-9a-fA-F]{1,4}$|'
    r'^[0-9a-fA-F]{1,4}::([0-9a-fA-F]{1,4}:){0,5}[0-9a-fA-F]{1,4}$|'
    r'^([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}$|'
    r'^([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}$|'
    r'^([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}$|'
    r'^::$',
  );

  static final RegExp _macRegex = RegExp(
    r'^([0-9a-fA-F]{2}[:\-]){5}[0-9a-fA-F]{2}$',
  );

  static final RegExp _hexColorRegex = RegExp(
    r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$',
  );

  static final RegExp _cnPhoneRegex = RegExp(r'^(\+?86)?1[3-9]\d{9}$');
  static final RegExp _usPhoneRegex = RegExp(r'^(\+?1[\s\-]?)?\(?\d{3}\)?[\s\-]?\d{3}[\s\-]?\d{4}$');
  static final RegExp _ukPhoneRegex = RegExp(r'^(\+?44|0)[\s\-]?(\d[\s\-]?){9,10}$');
  static final RegExp _jpPhoneRegex = RegExp(r'^(\+?81|0)\d{9,10}$');
  static final RegExp _krPhoneRegex = RegExp(r'^(\+?82|0)1[0-9][\s\-]?\d{3,4}[\s\-]?\d{4}$');

  /// Validates an email address.
  static GchValidationResult email(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return GchValidationResult.fail('Email cannot be empty');
    if (!_emailRegex.hasMatch(trimmed)) {
      return GchValidationResult.fail(
        'Invalid email format',
        suggestions: ['Ensure format is user@domain.tld', 'Check for missing @ symbol'],
      );
    }
    return GchValidationResult.ok();
  }

  /// Validates a phone number for the given country code.
  static GchValidationResult phone(String s, {String countryCode = 'CN'}) {
    final digits = s.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (digits.isEmpty) return GchValidationResult.fail('Phone number cannot be empty');

    bool isMatch;
    switch (countryCode.toUpperCase()) {
      case 'CN':
        isMatch = _cnPhoneRegex.hasMatch(s.trim());
        break;
      case 'US':
        isMatch = _usPhoneRegex.hasMatch(s.trim());
        break;
      case 'UK':
        isMatch = _ukPhoneRegex.hasMatch(s.trim());
        break;
      case 'JP':
        isMatch = _jpPhoneRegex.hasMatch(s.trim());
        break;
      case 'KR':
        isMatch = _krPhoneRegex.hasMatch(s.trim());
        break;
      default:
        isMatch = digits.length >= 7 && digits.length <= 15;
    }

    if (!isMatch) {
      return GchValidationResult.fail(
        'Invalid phone number for country $countryCode',
        suggestions: ['Check country code format', 'Verify number length'],
      );
    }
    return GchValidationResult.ok();
  }

  /// Validates a URL.
  static GchValidationResult url(String s) {
    if (s.trim().isEmpty) return GchValidationResult.fail('URL cannot be empty');
    if (!_urlRegex.hasMatch(s.trim())) {
      return GchValidationResult.fail(
        'Invalid URL format',
        suggestions: ['URL must start with http:// or https://', 'Check for spaces in URL'],
      );
    }
    return GchValidationResult.ok();
  }

  /// Validates an IPv4 address.
  static GchValidationResult ipv4(String s) {
    if (!_ipv4Regex.hasMatch(s.trim())) {
      return GchValidationResult.fail('Invalid IPv4 address');
    }
    final parts = s.trim().split('.').map(int.parse).toList();
    if (parts.any((p) => p > 255)) {
      return GchValidationResult.fail('Each IPv4 octet must be 0-255');
    }
    return GchValidationResult.ok();
  }

  /// Validates an IPv6 address.
  static GchValidationResult ipv6(String s) {
    if (!_ipv6Regex.hasMatch(s.trim())) {
      return GchValidationResult.fail(
        'Invalid IPv6 address',
        suggestions: ['Format: xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx'],
      );
    }
    return GchValidationResult.ok();
  }

  /// Validates a credit card number using the Luhn algorithm.
  static GchValidationResult creditCard(String s) {
    final digits = s.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^\d{13,19}$').hasMatch(digits)) {
      return GchValidationResult.fail('Credit card number must be 13-19 digits');
    }
    if (!_luhnCheck(digits)) {
      return GchValidationResult.fail('Invalid credit card number (Luhn check failed)');
    }
    return GchValidationResult.ok();
  }

  static bool _luhnCheck(String number) {
    int sum = 0;
    bool alternate = false;
    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  /// Validates a postal code for the given country.
  static GchValidationResult postalCode(String s, {String countryCode = 'CN'}) {
    final trimmed = s.trim();
    final patterns = <String, RegExp>{
      'CN': RegExp(r'^\d{6}$'),
      'US': RegExp(r'^\d{5}(-\d{4})?$'),
      'UK': RegExp(r'^[A-Z]{1,2}\d[A-Z\d]? ?\d[A-Z]{2}$', caseSensitive: false),
      'CA': RegExp(r'^[A-Z]\d[A-Z] ?\d[A-Z]\d$', caseSensitive: false),
      'AU': RegExp(r'^\d{4}$'),
      'DE': RegExp(r'^\d{5}$'),
      'FR': RegExp(r'^\d{5}$'),
      'JP': RegExp(r'^\d{3}-?\d{4}$'),
    };

    final pattern = patterns[countryCode.toUpperCase()];
    if (pattern == null) {
      return trimmed.length >= 3 && trimmed.length <= 10
          ? GchValidationResult.ok()
          : GchValidationResult.fail('Invalid postal code');
    }

    if (!pattern.hasMatch(trimmed)) {
      return GchValidationResult.fail('Invalid postal code for $countryCode');
    }
    return GchValidationResult.ok();
  }

  /// Validates a Chinese national ID card number (18 digits with check digit).
  static GchValidationResult idCard(String s) {
    final id = s.trim().toUpperCase();
    if (!RegExp(r'^\d{17}[\dX]$').hasMatch(id)) {
      return GchValidationResult.fail('ID card must be 18 characters (17 digits + check)');
    }

    // Validate date
    final year = int.tryParse(id.substring(6, 10));
    final month = int.tryParse(id.substring(10, 12));
    final day = int.tryParse(id.substring(12, 14));
    if (year == null || month == null || day == null) {
      return GchValidationResult.fail('Invalid date in ID card');
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return GchValidationResult.fail('Invalid birth date in ID card');
    }

    // Luhn-like check digit for Chinese ID
    const weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
    const checkChars = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'];
    int sum = 0;
    for (int i = 0; i < 17; i++) {
      sum += int.parse(id[i]) * weights[i];
    }
    final expectedCheck = checkChars[sum % 11];
    if (id[17] != expectedCheck) {
      return GchValidationResult.fail('Invalid ID card check digit');
    }
    return GchValidationResult.ok();
  }

  /// Validates a username.
  static GchValidationResult username(String s, {int minLen = 3, int maxLen = 20}) {
    if (s.isEmpty) return GchValidationResult.fail('Username cannot be empty');
    if (s.length < minLen) {
      return GchValidationResult.fail('Username must be at least $minLen characters');
    }
    if (s.length > maxLen) {
      return GchValidationResult.fail('Username cannot exceed $maxLen characters');
    }
    if (!RegExp(r'^[a-zA-Z0-9_\-\.]+$').hasMatch(s)) {
      return GchValidationResult.fail(
        'Username may only contain letters, digits, underscores, hyphens, and dots',
      );
    }
    if (s.startsWith('.') || s.startsWith('-') || s.startsWith('_')) {
      return GchValidationResult.fail('Username cannot start with a special character');
    }
    return GchValidationResult.ok();
  }

  /// Validates a password and returns strength information.
  static GchValidationResult password(String s) {
    if (s.length < 8) {
      return GchValidationResult.fail(
        'Password must be at least 8 characters',
        suggestions: GchPasswordAnalyzer.suggestions(s),
      );
    }
    final strength = GchPasswordAnalyzer.analyze(s);
    if (strength == GchPasswordStrength.veryWeak) {
      return GchValidationResult.fail(
        'Password is too weak',
        suggestions: GchPasswordAnalyzer.suggestions(s),
      );
    }
    return GchValidationResult.ok();
  }

  /// Validates a date string against the given format.
  static GchValidationResult date(String s, {String format = 'yyyy-MM-dd'}) {
    if (s.trim().isEmpty) return GchValidationResult.fail('Date cannot be empty');

    try {
      if (format == 'yyyy-MM-dd') {
        final parts = s.split('-');
        if (parts.length != 3) return GchValidationResult.fail('Invalid date format, expected yyyy-MM-dd');
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year == null || month == null || day == null) {
          return GchValidationResult.fail('Date components must be numeric');
        }
        if (month < 1 || month > 12) return GchValidationResult.fail('Month must be 1-12');
        if (day < 1 || day > 31) return GchValidationResult.fail('Day must be 1-31');
        final maxDay = _daysInMonth(year, month);
        if (day > maxDay) return GchValidationResult.fail('Day $day is out of range for month $month');
        return GchValidationResult.ok();
      }
      // Fallback: just check non-empty for custom formats
      return GchValidationResult.ok();
    } catch (_) {
      return GchValidationResult.fail('Invalid date');
    }
  }

  static int _daysInMonth(int year, int month) {
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0)) return 29;
    return days[month];
  }

  /// Validates a time string (HH:mm:ss).
  static GchValidationResult time(String s) {
    final parts = s.trim().split(':');
    if (parts.length < 2) return GchValidationResult.fail('Invalid time format, expected HH:mm[:ss]');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return GchValidationResult.fail('Time components must be numeric');
    if (hour < 0 || hour > 23) return GchValidationResult.fail('Hour must be 0-23');
    if (minute < 0 || minute > 59) return GchValidationResult.fail('Minute must be 0-59');
    if (parts.length >= 3) {
      final second = int.tryParse(parts[2]);
      if (second == null || second < 0 || second > 59) {
        return GchValidationResult.fail('Second must be 0-59');
      }
    }
    return GchValidationResult.ok();
  }

  /// Validates an integer string, optionally within [min] and [max].
  static GchValidationResult integer(String s, {int? min, int? max}) {
    final value = int.tryParse(s.trim());
    if (value == null) return GchValidationResult.fail('Must be a valid integer');
    if (min != null && value < min) return GchValidationResult.fail('Value must be at least $min');
    if (max != null && value > max) return GchValidationResult.fail('Value must be at most $max');
    return GchValidationResult.ok();
  }

  /// Validates a decimal number string.
  static GchValidationResult decimal(String s, {double? min, double? max, int? maxDecimals}) {
    final value = double.tryParse(s.trim());
    if (value == null) return GchValidationResult.fail('Must be a valid decimal number');
    if (min != null && value < min) return GchValidationResult.fail('Value must be at least $min');
    if (max != null && value > max) return GchValidationResult.fail('Value must be at most $max');
    if (maxDecimals != null) {
      final dotIdx = s.indexOf('.');
      if (dotIdx != -1 && s.length - dotIdx - 1 > maxDecimals) {
        return GchValidationResult.fail('At most $maxDecimals decimal places allowed');
      }
    }
    return GchValidationResult.ok();
  }

  /// Validates a Chinese name (2-4 Chinese characters).
  static GchValidationResult chineseName(String s) {
    if (s.isEmpty) return GchValidationResult.fail('Name cannot be empty');
    if (!RegExp(r'^[一-龥]{2,4}$').hasMatch(s)) {
      return GchValidationResult.fail(
        'Chinese name must be 2-4 Chinese characters',
        suggestions: ['Use Chinese characters only', 'Name should be 2-4 characters'],
      );
    }
    return GchValidationResult.ok();
  }

  /// Validates a bank card number (16 or 19 digits, Luhn check).
  static GchValidationResult bankCard(String s) {
    final digits = s.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^\d{16}(\d{3})?$').hasMatch(digits)) {
      return GchValidationResult.fail('Bank card must be 16 or 19 digits');
    }
    if (!_luhnCheck(digits)) {
      return GchValidationResult.fail('Invalid bank card number');
    }
    return GchValidationResult.ok();
  }

  /// Validates an ISBN-10 or ISBN-13 number.
  static GchValidationResult isbn(String s) {
    final clean = s.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
    if (clean.length == 10) {
      return _validateIsbn10(clean);
    } else if (clean.length == 13) {
      return _validateIsbn13(clean);
    }
    return GchValidationResult.fail('ISBN must be 10 or 13 digits');
  }

  static GchValidationResult _validateIsbn10(String isbn) {
    if (!RegExp(r'^\d{9}[\dX]$').hasMatch(isbn)) {
      return GchValidationResult.fail('Invalid ISBN-10 format');
    }
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(isbn[i]) * (10 - i);
    }
    final checkChar = isbn[9] == 'X' ? 10 : int.parse(isbn[9]);
    sum += checkChar;
    return sum % 11 == 0
        ? GchValidationResult.ok()
        : GchValidationResult.fail('Invalid ISBN-10 check digit');
  }

  static GchValidationResult _validateIsbn13(String isbn) {
    if (!RegExp(r'^\d{13}$').hasMatch(isbn)) {
      return GchValidationResult.fail('Invalid ISBN-13 format');
    }
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(isbn[i]) * (i % 2 == 0 ? 1 : 3);
    }
    final check = (10 - (sum % 10)) % 10;
    return check == int.parse(isbn[12])
        ? GchValidationResult.ok()
        : GchValidationResult.fail('Invalid ISBN-13 check digit');
  }

  /// Validates a MAC address.
  static GchValidationResult macAddress(String s) {
    if (!_macRegex.hasMatch(s.trim())) {
      return GchValidationResult.fail(
        'Invalid MAC address format',
        suggestions: ['Format: XX:XX:XX:XX:XX:XX or XX-XX-XX-XX-XX-XX'],
      );
    }
    return GchValidationResult.ok();
  }

  /// Validates a hex color string (#RGB, #RRGGBB, #RRGGBBAA).
  static GchValidationResult hexColor(String s) {
    if (!_hexColorRegex.hasMatch(s.trim())) {
      return GchValidationResult.fail(
        'Invalid hex color',
        suggestions: ['Format: #RGB, #RRGGBB, or #RRGGBBAA'],
      );
    }
    return GchValidationResult.ok();
  }

  /// Validates a latitude value (-90 to 90).
  static GchValidationResult latitude(double value) {
    if (value < -90 || value > 90) {
      return GchValidationResult.fail('Latitude must be between -90 and 90');
    }
    return GchValidationResult.ok();
  }

  /// Validates a longitude value (-180 to 180).
  static GchValidationResult longitude(double value) {
    if (value < -180 || value > 180) {
      return GchValidationResult.fail('Longitude must be between -180 and 180');
    }
    return GchValidationResult.ok();
  }

  /// Validates that [value] falls within [[min], [max]].
  static GchValidationResult range(num value, num min, num max) {
    if (value < min || value > max) {
      return GchValidationResult.fail('Value must be between $min and $max');
    }
    return GchValidationResult.ok();
  }
}

/// Analyzes password strength and entropy.
class GchPasswordAnalyzer {
  GchPasswordAnalyzer._();

  /// Analyzes the strength of a password.
  static GchPasswordStrength analyze(String password) {
    final score = _calculateScore(password);
    if (score < 20) return GchPasswordStrength.veryWeak;
    if (score < 40) return GchPasswordStrength.weak;
    if (score < 60) return GchPasswordStrength.fair;
    if (score < 80) return GchPasswordStrength.strong;
    return GchPasswordStrength.veryStrong;
  }

  static int _calculateScore(String password) {
    int score = 0;

    // Length scoring
    if (password.length >= 8) score += 10;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;
    if (password.length >= 20) score += 10;

    // Character variety
    if (RegExp(r'[a-z]').hasMatch(password)) score += 10;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 10;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 10;
    if (RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').hasMatch(password)) score += 15;

    // Penalize common patterns
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) score -= 10; // repeated chars
    if (RegExp(r'(012|123|234|345|456|567|678|789|890)').hasMatch(password)) score -= 5;
    if (RegExp(r'(abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm)').hasMatch(password)) score -= 5;
    if (['password', '123456', 'qwerty', 'letmein', 'admin'].contains(password.toLowerCase())) {
      score -= 30;
    }

    return score.clamp(0, 100);
  }

  /// Calculates password entropy in bits.
  static double entropy(String password) {
    if (password.isEmpty) return 0.0;
    int poolSize = 0;
    if (RegExp(r'[a-z]').hasMatch(password)) poolSize += 26;
    if (RegExp(r'[A-Z]').hasMatch(password)) poolSize += 26;
    if (RegExp(r'[0-9]').hasMatch(password)) poolSize += 10;
    if (RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').hasMatch(password)) poolSize += 32;
    if (poolSize == 0) return 0.0;
    return password.length * (log(poolSize) / log(2));
  }

  /// Returns improvement suggestions for the given password.
  static List<String> suggestions(String password) {
    final hints = <String>[];
    if (password.length < 12) hints.add('Use at least 12 characters');
    if (!RegExp(r'[A-Z]').hasMatch(password)) hints.add('Add uppercase letters');
    if (!RegExp(r'[a-z]').hasMatch(password)) hints.add('Add lowercase letters');
    if (!RegExp(r'[0-9]').hasMatch(password)) hints.add('Add numbers');
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password)) {
      hints.add('Add special characters (!@#\$%^&*)');
    }
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) hints.add('Avoid repeating characters');
    if (password.length >= 20 && hints.isEmpty) hints.add('Great password!');
    return hints;
  }

  /// Generates a strong random password.
  static String generate({int length = 16, bool symbols = true}) {
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const special = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

    String charset = lowercase + uppercase + digits;
    if (symbols) charset += special;

    final random = Random.secure();
    final chars = <String>[];

    // Ensure at least one of each required type
    chars.add(lowercase[random.nextInt(lowercase.length)]);
    chars.add(uppercase[random.nextInt(uppercase.length)]);
    chars.add(digits[random.nextInt(digits.length)]);
    if (symbols) chars.add(special[random.nextInt(special.length)]);

    while (chars.length < length) {
      chars.add(charset[random.nextInt(charset.length)]);
    }

    // Shuffle
    for (int i = chars.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }

    return chars.join();
  }
}

/// Utility for validating and normalizing common data fields.
class GchFieldValidator {
  GchFieldValidator._();

  /// Validates that [s] is not empty or blank.
  static GchValidationResult required(String s, {String fieldName = 'Field'}) {
    if (s.trim().isEmpty) {
      return GchValidationResult.fail('$fieldName is required');
    }
    return GchValidationResult.ok();
  }

  /// Validates minimum string length.
  static GchValidationResult minLength(String s, int min, {String fieldName = 'Field'}) {
    if (s.length < min) {
      return GchValidationResult.fail('$fieldName must be at least $min characters');
    }
    return GchValidationResult.ok();
  }

  /// Validates maximum string length.
  static GchValidationResult maxLength(String s, int max, {String fieldName = 'Field'}) {
    if (s.length > max) {
      return GchValidationResult.fail('$fieldName must not exceed $max characters');
    }
    return GchValidationResult.ok();
  }

  /// Validates exact string length.
  static GchValidationResult exactLength(String s, int length, {String fieldName = 'Field'}) {
    if (s.length != length) {
      return GchValidationResult.fail('$fieldName must be exactly $length characters');
    }
    return GchValidationResult.ok();
  }

  /// Validates that [s] matches the given [pattern].
  static GchValidationResult matches(String s, RegExp pattern, {String fieldName = 'Field', String? message}) {
    if (!pattern.hasMatch(s)) {
      return GchValidationResult.fail(message ?? '$fieldName format is invalid');
    }
    return GchValidationResult.ok();
  }

  /// Validates that [s] contains only alphabetic characters.
  static GchValidationResult alpha(String s, {String fieldName = 'Field'}) {
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(s)) {
      return GchValidationResult.fail('$fieldName must contain only letters');
    }
    return GchValidationResult.ok();
  }

  /// Validates that [s] contains only alphanumeric characters.
  static GchValidationResult alphanumeric(String s, {String fieldName = 'Field'}) {
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(s)) {
      return GchValidationResult.fail('$fieldName must contain only letters and digits');
    }
    return GchValidationResult.ok();
  }

  /// Validates that [s] does not contain the characters in [forbidden].
  static GchValidationResult noForbiddenChars(String s, String forbidden, {String fieldName = 'Field'}) {
    for (final char in forbidden.split('')) {
      if (s.contains(char)) {
        return GchValidationResult.fail('$fieldName contains forbidden character: "$char"');
      }
    }
    return GchValidationResult.ok();
  }

  /// Validates that [s] starts with [prefix].
  static GchValidationResult startsWith(String s, String prefix, {String fieldName = 'Field'}) {
    if (!s.startsWith(prefix)) {
      return GchValidationResult.fail('$fieldName must start with "$prefix"');
    }
    return GchValidationResult.ok();
  }

  /// Validates that [s] ends with [suffix].
  static GchValidationResult endsWith(String s, String suffix, {String fieldName = 'Field'}) {
    if (!s.endsWith(suffix)) {
      return GchValidationResult.fail('$fieldName must end with "$suffix"');
    }
    return GchValidationResult.ok();
  }

  /// Validates that [value] is one of the [allowed] values.
  static GchValidationResult oneOf<T>(T value, List<T> allowed, {String fieldName = 'Field'}) {
    if (!allowed.contains(value)) {
      return GchValidationResult.fail('$fieldName must be one of: ${allowed.join(", ")}');
    }
    return GchValidationResult.ok();
  }

  /// Runs multiple validators and returns the first failure, or ok if all pass.
  static GchValidationResult all(List<GchValidationResult> results) {
    for (final result in results) {
      if (!result.isValid) return result;
    }
    return GchValidationResult.ok();
  }

  /// Runs multiple validators and collects all failures.
  static List<GchValidationResult> allErrors(List<GchValidationResult> results) {
    return results.where((r) => !r.isValid).toList();
  }

  /// Validates a non-negative integer string.
  static GchValidationResult nonNegativeInt(String s, {String fieldName = 'Field'}) {
    final value = int.tryParse(s);
    if (value == null) return GchValidationResult.fail('$fieldName must be a whole number');
    if (value < 0) return GchValidationResult.fail('$fieldName must not be negative');
    return GchValidationResult.ok();
  }

  /// Validates that [s] represents a positive number.
  static GchValidationResult positiveNumber(String s, {String fieldName = 'Field'}) {
    final value = double.tryParse(s);
    if (value == null) return GchValidationResult.fail('$fieldName must be a number');
    if (value <= 0) return GchValidationResult.fail('$fieldName must be positive');
    return GchValidationResult.ok();
  }

  /// Validates a list is not empty.
  static GchValidationResult listNotEmpty<T>(List<T> list, {String fieldName = 'List'}) {
    if (list.isEmpty) return GchValidationResult.fail('$fieldName must not be empty');
    return GchValidationResult.ok();
  }

  /// Validates that [a] and [b] are equal (e.g., confirm password).
  static GchValidationResult equals(String a, String b, {String fieldName = 'Field'}) {
    if (a != b) return GchValidationResult.fail('$fieldName values do not match');
    return GchValidationResult.ok();
  }

  /// Validates that [s] has no leading or trailing whitespace.
  static GchValidationResult noLeadingTrailingWhitespace(String s, {String fieldName = 'Field'}) {
    if (s != s.trim()) {
      return GchValidationResult.fail('$fieldName must not have leading or trailing spaces');
    }
    return GchValidationResult.ok();
  }

  /// Validates that [s] contains no consecutive spaces.
  static GchValidationResult noConsecutiveSpaces(String s, {String fieldName = 'Field'}) {
    if (RegExp(r'  ').hasMatch(s)) {
      return GchValidationResult.fail('$fieldName must not contain consecutive spaces');
    }
    return GchValidationResult.ok();
  }

  /// Validates that [s] has at most [max] words.
  static GchValidationResult maxWords(String s, int max, {String fieldName = 'Field'}) {
    final count = s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;
    if (count > max) {
      return GchValidationResult.fail('$fieldName must not exceed $max words (currently $count)');
    }
    return GchValidationResult.ok();
  }

  /// Validates that [s] contains at least [min] words.
  static GchValidationResult minWords(String s, int min, {String fieldName = 'Field'}) {
    final count = s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;
    if (count < min) {
      return GchValidationResult.fail('$fieldName must contain at least $min words');
    }
    return GchValidationResult.ok();
  }
}
