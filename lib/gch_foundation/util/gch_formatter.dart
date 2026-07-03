// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';

/// Formats numbers in various styles.
class GchNumberFormatter {
  GchNumberFormatter._();

  /// Formats [n] with [decimals] decimal places, optional prefix/suffix.
  static String format(
    num n, {
    int decimals = 2,
    String? prefix,
    String? suffix,
  }) {
    final formatted = n.toStringAsFixed(decimals);
    final sb = StringBuffer();
    if (prefix != null) sb.write(prefix);
    sb.write(formatted);
    if (suffix != null) sb.write(suffix);
    return sb.toString();
  }

  /// Returns a compact representation: 1200 → "1.2K", 2300000 → "2.3M".
  static String compact(num n) {
    final abs = n.abs();
    final sign = n < 0 ? '-' : '';
    if (abs >= 1e12) return '$sign${_compactRound(abs / 1e12)}T';
    if (abs >= 1e9) return '$sign${_compactRound(abs / 1e9)}B';
    if (abs >= 1e6) return '$sign${_compactRound(abs / 1e6)}M';
    if (abs >= 1e3) return '$sign${_compactRound(abs / 1e3)}K';
    return n.toString();
  }

  static String _compactRound(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }

  /// Formats [amount] as a currency string.
  static String currency(num amount, {String symbol = '¥', int decimals = 2}) {
    final formatted = thousandsSeparated(amount, sep: ',');
    final parts = formatted.split('.');
    if (decimals == 0) return '$symbol${parts[0]}';
    final intPart = parts[0];
    final decPart = amount.toStringAsFixed(decimals).split('.').last;
    return '$symbol$intPart.$decPart';
  }

  /// Formats [value] as a percentage string.
  static String percentage(num value, {int decimals = 1}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Returns the ordinal representation: 1 → "1st", 2 → "2nd", etc.
  static String ordinal(int n) {
    final abs = n.abs();
    final mod100 = abs % 100;
    if (mod100 >= 11 && mod100 <= 13) return '${n}th';
    switch (abs % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  /// Formats [n] with thousands separator.
  static String thousandsSeparated(num n, {String sep = ','}) {
    final str = n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
    final parts = str.split('.');
    final intPart = parts[0];
    final negative = intPart.startsWith('-');
    final digits = negative ? intPart.substring(1) : intPart;
    final formatted = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        formatted.write(sep);
      }
      formatted.write(digits[i]);
    }
    final result = (negative ? '-' : '') + formatted.toString();
    return parts.length > 1 ? '$result.${parts[1]}' : result;
  }

  /// Formats [n] in scientific notation.
  static String scientificNotation(num n, {int decimals = 3}) {
    if (n == 0) return '0.000e+0';
    final exp = (log(n.abs()) / log(10)).floor();
    final mantissa = n / pow(10, exp);
    final sign = exp >= 0 ? '+' : '-';
    return '${mantissa.toStringAsFixed(decimals)}e$sign${exp.abs()}';
  }

  /// Converts an integer (1-3999) to Roman numerals.
  static String roman(int n) {
    if (n < 1 || n > 3999) throw ArgumentError('Roman numerals only support 1-3999');
    const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const symbols = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
    final result = StringBuffer();
    int remaining = n;
    for (int i = 0; i < values.length; i++) {
      while (remaining >= values[i]) {
        result.write(symbols[i]);
        remaining -= values[i];
      }
    }
    return result.toString();
  }

  /// Spells out an integer in English (0-999999).
  static String wordsEN(int n) {
    if (n == 0) return 'zero';
    if (n < 0) return 'negative ${wordsEN(-n)}';

    const ones = ['', 'one', 'two', 'three', 'four', 'five', 'six', 'seven',
        'eight', 'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen',
        'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'];
    const tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];

    String below1000(int num) {
      if (num < 20) return ones[num];
      if (num < 100) {
        final r = num % 10;
        return tens[num ~/ 10] + (r > 0 ? '-${ones[r]}' : '');
      }
      final h = num ~/ 100;
      final remainder = num % 100;
      return '${ones[h]} hundred${remainder > 0 ? ' ${below1000(remainder)}' : ''}';
    }

    final parts = <String>[];
    if (n >= 100000) {
      parts.add('${below1000(n ~/ 100000)} hundred thousand');
      n = n % 100000;
    } else if (n >= 1000) {
      parts.add('${below1000(n ~/ 1000)} thousand');
      n = n % 1000;
    }
    if (n > 0) parts.add(below1000(n));
    return parts.join(' ');
  }

  /// Spells out an integer in Chinese (0-99999999).
  static String wordsCN(int n) {
    if (n == 0) return '零';
    if (n < 0) return '负${wordsCN(-n)}';

    const digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
    const units = ['', '十', '百', '千'];

    String below10000(int num) {
      if (num == 0) return '';
      final result = StringBuffer();
      bool lastWasZero = false;
      for (int i = 3; i >= 0; i--) {
        final d = (num ~/ pow(10, i).toInt()) % 10;
        if (d == 0) {
          if (!lastWasZero && result.isNotEmpty) {
            result.write('零');
            lastWasZero = true;
          }
        } else {
          result.write(digits[d]);
          result.write(units[i]);
          lastWasZero = false;
        }
      }
      String s = result.toString();
      if (s.endsWith('零')) s = s.substring(0, s.length - 1);
      return s;
    }

    if (n < 10000) return below10000(n);
    final wan = n ~/ 10000;
    final remainder = n % 10000;
    final prefix = '${below10000(wan)}万';
    if (remainder == 0) return prefix;
    if (remainder < 1000) return '${prefix}零${below10000(remainder)}';
    return prefix + below10000(remainder);
  }

  /// Formats a byte count into a human-readable file size string.
  static String fileSize(int bytes, {int decimals = 1}) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(decimals)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(decimals)} MB';
    }
    if (bytes < 1024 * 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(decimals)} GB';
    }
    return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(decimals)} TB';
  }

  /// Formats a [Duration] into a readable string.
  static String duration(Duration d, {bool verbose = false}) {
    final total = d.inSeconds.abs();
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;

    if (verbose) {
      final parts = <String>[];
      if (h > 0) parts.add('$h ${h == 1 ? "hour" : "hours"}');
      if (m > 0) parts.add('$m ${m == 1 ? "minute" : "minutes"}');
      if (s > 0 || parts.isEmpty) parts.add('$s ${s == 1 ? "second" : "seconds"}');
      return parts.join(', ');
    }
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}

/// Country phone format rules.
class _PhoneFormatRule {
  final String countryCode;
  final String dialCode;
  final String pattern; // # = digit
  final int digitCount;

  const _PhoneFormatRule({
    required this.countryCode,
    required this.dialCode,
    required this.pattern,
    required this.digitCount,
  });
}

/// Formats phone numbers by country.
class GchPhoneFormatter {
  GchPhoneFormatter._();

  static const Map<String, _PhoneFormatRule> _rules = {
    'CN': _PhoneFormatRule(countryCode: 'CN', dialCode: '+86', pattern: '### #### ####', digitCount: 11),
    'US': _PhoneFormatRule(countryCode: 'US', dialCode: '+1', pattern: '(###) ###-####', digitCount: 10),
    'UK': _PhoneFormatRule(countryCode: 'UK', dialCode: '+44', pattern: '#### ### ####', digitCount: 11),
    'AU': _PhoneFormatRule(countryCode: 'AU', dialCode: '+61', pattern: '#### ### ###', digitCount: 10),
    'DE': _PhoneFormatRule(countryCode: 'DE', dialCode: '+49', pattern: '#### #######', digitCount: 11),
    'FR': _PhoneFormatRule(countryCode: 'FR', dialCode: '+33', pattern: '## ## ## ## ##', digitCount: 10),
    'JP': _PhoneFormatRule(countryCode: 'JP', dialCode: '+81', pattern: '###-####-####', digitCount: 11),
    'KR': _PhoneFormatRule(countryCode: 'KR', dialCode: '+82', pattern: '###-####-####', digitCount: 11),
    'IN': _PhoneFormatRule(countryCode: 'IN', dialCode: '+91', pattern: '#####-#####', digitCount: 10),
    'BR': _PhoneFormatRule(countryCode: 'BR', dialCode: '+55', pattern: '(##) #####-####', digitCount: 11),
    'MX': _PhoneFormatRule(countryCode: 'MX', dialCode: '+52', pattern: '## #### ####', digitCount: 10),
    'RU': _PhoneFormatRule(countryCode: 'RU', dialCode: '+7', pattern: '(###) ###-##-##', digitCount: 10),
    'IT': _PhoneFormatRule(countryCode: 'IT', dialCode: '+39', pattern: '### ### ####', digitCount: 10),
    'ES': _PhoneFormatRule(countryCode: 'ES', dialCode: '+34', pattern: '### ### ###', digitCount: 9),
    'NL': _PhoneFormatRule(countryCode: 'NL', dialCode: '+31', pattern: '## ### ####', digitCount: 9),
    'SE': _PhoneFormatRule(countryCode: 'SE', dialCode: '+46', pattern: '##-### ## ##', digitCount: 9),
    'NO': _PhoneFormatRule(countryCode: 'NO', dialCode: '+47', pattern: '### ## ###', digitCount: 8),
    'DK': _PhoneFormatRule(countryCode: 'DK', dialCode: '+45', pattern: '## ## ## ##', digitCount: 8),
    'CH': _PhoneFormatRule(countryCode: 'CH', dialCode: '+41', pattern: '### ### ## ##', digitCount: 10),
    'SG': _PhoneFormatRule(countryCode: 'SG', dialCode: '+65', pattern: '#### ####', digitCount: 8),
  };

  /// Formats a phone number according to its country format.
  static String format(String phone, {String countryCode = 'CN'}) {
    final digits = strip(phone);
    final rule = _rules[countryCode.toUpperCase()];
    if (rule == null) return phone;

    // Take only the needed digit count
    final d = digits.length > rule.digitCount
        ? digits.substring(digits.length - rule.digitCount)
        : digits;

    final result = StringBuffer();
    int digitIdx = 0;
    for (final char in rule.pattern.split('')) {
      if (char == '#') {
        if (digitIdx < d.length) {
          result.write(d[digitIdx++]);
        }
      } else {
        result.write(char);
      }
    }
    return result.toString();
  }

  /// Removes all non-digit characters.
  static String strip(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  /// Prepends a dial code to a local phone number.
  static String addCountryCode(String phone, String cc) {
    final rule = _rules[cc.toUpperCase()];
    final dialCode = rule?.dialCode ?? '+$cc';
    final digits = strip(phone);
    return '$dialCode $digits';
  }

  /// Returns the dial code for a given country code.
  static String? dialCode(String countryCode) {
    return _rules[countryCode.toUpperCase()]?.dialCode;
  }

  /// Returns all supported country codes.
  static List<String> supportedCountries() {
    return _rules.keys.toList();
  }
}

/// Formats credit/debit card numbers.
class GchCardFormatter {
  GchCardFormatter._();

  static const Map<String, String> _cardPatterns = {
    'Visa': r'^4',
    'MasterCard': r'^5[1-5]|^2[2-7]',
    'Amex': r'^3[47]',
    'Discover': r'^6(?:011|5)',
    'UnionPay': r'^62',
    'JCB': r'^35(?:2[89]|[3-8])',
    'DinersClub': r'^3(?:0[0-5]|[68])',
    'Maestro': r'^(?:5018|5020|5038|6304|6759|6761|6763)',
    'MIR': r'^220',
    'Elo': r'^(?:401178|401179|431274|438935)',
  };

  /// Formats a card number with spaces every 4 digits.
  static String format(String card) {
    final digits = card.replaceAll(RegExp(r'\D'), '');
    final groups = <String>[];
    for (int i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(i, min(i + 4, digits.length)));
    }
    return groups.join(' ');
  }

  /// Detects the card network type from the card number prefix.
  static String detectType(String card) {
    final digits = card.replaceAll(RegExp(r'\D'), '');
    for (final entry in _cardPatterns.entries) {
      if (RegExp(entry.value).hasMatch(digits)) {
        return entry.key;
      }
    }
    return 'Unknown';
  }

  /// Masks all but the last 4 digits of a card number.
  static String mask(String card) {
    final digits = card.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return digits;
    final last4 = digits.substring(digits.length - 4);
    final masked = '*' * (digits.length - 4);
    // Format as groups of 4
    final combined = masked + last4;
    final groups = <String>[];
    for (int i = 0; i < combined.length; i += 4) {
      groups.add(combined.substring(i, min(i + 4, combined.length)));
    }
    return groups.join(' ');
  }

  /// Returns the security code label for a card type (CVV, CVC, CID, etc.).
  static String securityCodeLabel(String cardType) {
    switch (cardType) {
      case 'Amex':
        return 'CID';
      case 'Discover':
        return 'CID';
      default:
        return 'CVV';
    }
  }

  /// Returns the expected security code length.
  static int securityCodeLength(String cardType) {
    return cardType == 'Amex' ? 4 : 3;
  }
}

/// Formats dates in various display styles.
class GchDateFormatter {
  GchDateFormatter._();

  // Date format constants
  static const String iso8601 = 'yyyy-MM-ddTHH:mm:ss';
  static const String isoDate = 'yyyy-MM-dd';
  static const String isoTime = 'HH:mm:ss';
  static const String usDate = 'MM/dd/yyyy';
  static const String euDate = 'dd.MM.yyyy';
  static const String cnDate = 'yyyy年MM月dd日';
  static const String shortDate = 'MMM d';
  static const String longDate = 'MMMM d, yyyy';
  static const String shortDateTime = 'MMM d, h:mm a';
  static const String longDateTime = 'MMMM d, yyyy h:mm:ss a';
  static const String timeOnly = 'HH:mm';
  static const String timeWithAmPm = 'h:mm a';
  static const String monthYear = 'MMMM yyyy';
  static const String dayOfWeek = 'EEEE';
  static const String shortDayOfWeek = 'EEE';
  static const String dayMonthYear = 'dd MMM yyyy';
  static const String yearMonthDay = 'yyyy/MM/dd';
  static const String compactDate = 'yyyyMMdd';
  static const String rfcDate = 'EEE, dd MMM yyyy HH:mm:ss';
  static const String chatDate = 'MM/dd HH:mm';
  static const String relativeBase = 'yyyy-MM-dd HH:mm';

  static const List<String> _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _weekdaysFull = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  /// Returns a relative time description (Chinese + English).
  static String relative(DateTime dt, {bool chinese = false}) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final abs = diff.inSeconds.abs();
    final isFuture = diff.isNegative;

    if (chinese) {
      if (abs < 60) return '刚刚';
      if (abs < 3600) return '${abs ~/ 60}分钟${isFuture ? "后" : "前"}';
      if (abs < 86400) return '${abs ~/ 3600}小时${isFuture ? "后" : "前"}';
      if (abs < 86400 * 30) return '${abs ~/ 86400}天${isFuture ? "后" : "前"}';
      if (abs < 86400 * 365) return '${abs ~/ (86400 * 30)}个月${isFuture ? "后" : "前"}';
      return '${abs ~/ (86400 * 365)}年${isFuture ? "后" : "前"}';
    }

    if (abs < 60) return 'just now';
    if (abs < 3600) {
      final m = abs ~/ 60;
      return isFuture ? 'in $m ${m == 1 ? "minute" : "minutes"}' : '$m ${m == 1 ? "minute" : "minutes"} ago';
    }
    if (abs < 86400) {
      final h = abs ~/ 3600;
      return isFuture ? 'in $h ${h == 1 ? "hour" : "hours"}' : '$h ${h == 1 ? "hour" : "hours"} ago';
    }
    if (abs < 86400 * 30) {
      final d = abs ~/ 86400;
      return isFuture ? 'in $d ${d == 1 ? "day" : "days"}' : '$d ${d == 1 ? "day" : "days"} ago';
    }
    if (abs < 86400 * 365) {
      final mo = abs ~/ (86400 * 30);
      return isFuture ? 'in $mo ${mo == 1 ? "month" : "months"}' : '$mo ${mo == 1 ? "month" : "months"} ago';
    }
    final y = abs ~/ (86400 * 365);
    return isFuture ? 'in $y ${y == 1 ? "year" : "years"}' : '$y ${y == 1 ? "year" : "years"} ago';
  }

  /// Returns a friendly date string ("Today", "Yesterday", weekday name, or "Jan 5").
  static String friendlyDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    if (diff > 1 && diff <= 7) return 'Last ${_weekdaysFull[dt.weekday - 1]}';
    if (diff < -1 && diff >= -7) return 'Next ${_weekdaysFull[dt.weekday - 1]}';
    if (dt.year == now.year) return '${_monthsShort[dt.month - 1]} ${dt.day}';
    return '${_monthsShort[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  /// Returns a chat-style time string.
  static String chatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minStr';

    if (diff == 0) return timeStr;
    if (diff == 1) return 'Yesterday $timeStr';
    if (diff < 7) return '${_weekdaysFull[dt.weekday - 1]} $timeStr';
    if (dt.year == now.year) {
      return '${_monthsShort[dt.month - 1]} ${dt.day} $timeStr';
    }
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} $timeStr';
  }

  /// Returns a formatted date in the given named format.
  static String formatNamed(DateTime dt, String formatName) {
    switch (formatName) {
      case 'iso8601':
        return dt.toIso8601String();
      case 'isoDate':
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      case 'isoTime':
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
      case 'usDate':
        return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
      case 'cnDate':
        return '${dt.year}年${dt.month}月${dt.day}日';
      case 'longDate':
        return '${_monthsFull[dt.month - 1]} ${dt.day}, ${dt.year}';
      case 'shortDate':
        return '${_monthsShort[dt.month - 1]} ${dt.day}';
      case 'monthYear':
        return '${_monthsFull[dt.month - 1]} ${dt.year}';
      case 'chatTime':
        return chatTime(dt);
      case 'relative':
        return relative(dt);
      case 'friendly':
        return friendlyDate(dt);
      default:
        return dt.toString();
    }
  }
}

/// Formats names in various cultural styles.
class GchNameFormatter {
  GchNameFormatter._();

  /// Returns "First Last" format.
  static String fullName(String first, String last) => '$first $last';

  /// Returns "Last, First" format (Western formal).
  static String formalName(String first, String last) => '$last, $first';

  /// Returns initials (e.g., "JD" for John Doe).
  static String initials(String first, String last) {
    final f = first.trim().isNotEmpty ? first.trim()[0].toUpperCase() : '';
    final l = last.trim().isNotEmpty ? last.trim()[0].toUpperCase() : '';
    return '$f$l';
  }

  /// Returns a salutation string (e.g., "Dear Mr. Smith,").
  static String salutation(String last, {String title = 'Mr.'}) {
    return 'Dear $title $last,';
  }

  /// Returns a display name, falling back to [email] if name parts are empty.
  static String displayName(String first, String last, {String? email}) {
    final name = '$first $last'.trim();
    if (name.isNotEmpty) return name;
    return email ?? 'User';
  }

  /// Returns the last name, first name (East Asian order).
  static String eastAsianOrder(String first, String last) => '$last$first';
}

/// Formats lists of items into display strings.
class GchListFormatter {
  GchListFormatter._();

  /// Formats a list as a comma-separated string.
  static String commaSeparated(List<String> items) => items.join(', ');

  /// Formats with "and" before the last item.
  static String withAnd(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items[0];
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    return '${items.sublist(0, items.length - 1).join(', ')}, and ${items.last}';
  }

  /// Formats as a bulleted list with a prefix.
  static String bulletList(List<String> items, {String bullet = '•'}) {
    return items.map((item) => '$bullet $item').join('\n');
  }

  /// Formats as a numbered list.
  static String numberedList(List<String> items, {int startAt = 1}) {
    return items
        .asMap()
        .entries
        .map((e) => '${e.key + startAt}. ${e.value}')
        .join('\n');
  }

  /// Truncates a list to [maxItems], appending a count of hidden items.
  static String truncatedList(List<String> items, int maxItems, {String moreSuffix = 'more'}) {
    if (items.length <= maxItems) return commaSeparated(items);
    final shown = items.take(maxItems).join(', ');
    final remaining = items.length - maxItems;
    return '$shown and $remaining $moreSuffix';
  }
}

/// Formats table data as a plain-text ASCII table.
class GchTableFormatter {
  GchTableFormatter._();

  /// Renders a list of rows into a plain-text table.
  static String render(List<String> headers, List<List<String>> rows) {
    final colWidths = List<int>.filled(headers.length, 0);
    for (int i = 0; i < headers.length; i++) {
      colWidths[i] = headers[i].length;
    }
    for (final row in rows) {
      for (int i = 0; i < row.length && i < headers.length; i++) {
        if (row[i].length > colWidths[i]) colWidths[i] = row[i].length;
      }
    }

    String separator() {
      return '+${colWidths.map((w) => '-' * (w + 2)).join('+')}+';
    }

    String formatRow(List<String> cells) {
      final parts = <String>[];
      for (int i = 0; i < headers.length; i++) {
        final cell = i < cells.length ? cells[i] : '';
        parts.add(' ${cell.padRight(colWidths[i])} ');
      }
      return '|${parts.join('|')}|';
    }

    final sb = StringBuffer();
    sb.writeln(separator());
    sb.writeln(formatRow(headers));
    sb.writeln(separator());
    for (final row in rows) {
      sb.writeln(formatRow(row));
    }
    sb.write(separator());
    return sb.toString();
  }
}

/// Formats JSON-like structures with indentation.
class GchJsonFormatter {
  GchJsonFormatter._();

  /// Indents a compact JSON string (naive, for display purposes).
  static String prettyPrint(String json, {String indent = '  '}) {
    final sb = StringBuffer();
    int level = 0;
    bool inString = false;

    for (int i = 0; i < json.length; i++) {
      final char = json[i];
      if (char == '"' && (i == 0 || json[i - 1] != '\\')) {
        inString = !inString;
        sb.write(char);
        continue;
      }
      if (inString) {
        sb.write(char);
        continue;
      }
      switch (char) {
        case '{':
        case '[':
          level++;
          sb.write('$char\n${indent * level}');
          break;
        case '}':
        case ']':
          level--;
          sb.write('\n${indent * level}$char');
          break;
        case ',':
          sb.write(',\n${indent * level}');
          break;
        case ':':
          sb.write(': ');
          break;
        default:
          if (char != ' ' && char != '\n' && char != '\r' && char != '\t') {
            sb.write(char);
          }
      }
    }
    return sb.toString();
  }

  /// Minifies a pretty-printed JSON string (removes extra whitespace outside strings).
  static String minify(String json) {
    final sb = StringBuffer();
    bool inString = false;
    for (int i = 0; i < json.length; i++) {
      final char = json[i];
      if (char == '"' && (i == 0 || json[i - 1] != '\\')) {
        inString = !inString;
        sb.write(char);
        continue;
      }
      if (inString) {
        sb.write(char);
      } else if (char != ' ' && char != '\n' && char != '\r' && char != '\t') {
        sb.write(char);
      }
    }
    return sb.toString();
  }
}

/// Formats progress and percentage values.
class GchProgressFormatter {
  GchProgressFormatter._();

  /// Returns an ASCII progress bar of [width] characters.
  static String progressBar(double fraction, {int width = 20, String filled = '█', String empty = '░'}) {
    final clamped = fraction.clamp(0.0, 1.0);
    final filledCount = (clamped * width).round();
    final emptyCount = width - filledCount;
    final pct = (clamped * 100).toStringAsFixed(1);
    return '[${filled * filledCount}${empty * emptyCount}] $pct%';
  }

  /// Returns a short fraction string (e.g., "3/10").
  static String fraction(int numerator, int denominator) => '$numerator/$denominator';

  /// Returns an ETA string from elapsed time and current fraction.
  static String eta(Duration elapsed, double fraction) {
    if (fraction <= 0) return 'calculating...';
    if (fraction >= 1.0) return 'done';
    final totalEstimated = elapsed.inSeconds / fraction;
    final remaining = totalEstimated - elapsed.inSeconds;
    if (remaining < 60) return '${remaining.round()}s remaining';
    if (remaining < 3600) return '${(remaining / 60).round()}m remaining';
    return '${(remaining / 3600).toStringAsFixed(1)}h remaining';
  }
}

/// Formats time intervals and countdowns.
class GchCountdownFormatter {
  GchCountdownFormatter._();

  /// Returns a countdown string for [target] (e.g., "2d 3h 15m 22s").
  static String countdown(DateTime target, {DateTime? now}) {
    final base = now ?? DateTime.now();
    final diff = target.difference(base);
    if (diff.isNegative) return 'Expired';
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    final parts = <String>[];
    if (d > 0) parts.add('${d}d');
    if (h > 0) parts.add('${h}h');
    if (m > 0) parts.add('${m}m');
    parts.add('${s}s');
    return parts.join(' ');
  }

  /// Returns "HH:MM:SS" format for a duration.
  static String clockFormat(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
