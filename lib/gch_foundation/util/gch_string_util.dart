// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';
import 'dart:convert';

/// Character set constants.
class GchCharsets {
  GchCharsets._();

  static const String digits = '0123456789';
  static const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String letters = lowercase + uppercase;
  static const String alphanumeric = letters + digits;
  static const String hex = '0123456789abcdef';
  static const String hexUpper = '0123456789ABCDEF';
  static const String printable =
      r'0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"#$%&' "'" r'()*+,-./:;<=>?@[\]^_`{|}~';
  static const String symbols = r'!"#$%&' "'" r'()*+,-./:;<=>?@[\]^_`{|}~';
  static const String safeSymbols = r'!@#$%^&*()-_=+[]{}|;:,.<>?';
  static const String urlSafe = letters + digits + '-._~';
  static const String base64Chars = letters + digits + '+/=';
  static const String punctuation = '.,;:!?\'"-()[]{}';
}

/// Regex pattern constants.
class GchPatterns {
  GchPatterns._();

  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp urlRegex = RegExp(
    r'https?://[^\s/$.?#].[^\s]*',
    caseSensitive: false,
  );
  static final RegExp emailInTextRegex = RegExp(
    r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
  );
  static final RegExp numberRegex = RegExp(r'-?\d+(?:\.\d+)?');
  static final RegExp hashtagRegex = RegExp(r'#[a-zA-Z_]\w*');
  static final RegExp whitespaceRegex = RegExp(r'\s+');
  static final RegExp multipleSpaceRegex = RegExp(r' {2,}');
  static final RegExp leadingTrailingWhitespace = RegExp(r'^\s+|\s+$');
  static final RegExp camelCaseSplit = RegExp(r'(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])');
  static final RegExp nonAlphanumeric = RegExp(r'[^a-zA-Z0-9]+');
  static final RegExp nonAlphanumericHyphen = RegExp(r'[^a-zA-Z0-9\-]+');
  static final RegExp htmlTagRegex = RegExp(r'<[^>]*>');
  static final RegExp sentenceEndRegex = RegExp(r'[.!?]+\s+');
  static final RegExp lineRegex = RegExp(r'\r?\n');
  static final RegExp phoneRegex = RegExp(r'[\d\s\-\+\(\)]+');
}

/// Comprehensive string utility class with 30+ methods.
class GchStringUtil {
  GchStringUtil._();

  /// Capitalizes the first character of [s].
  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  /// Capitalizes the first letter of every word in [s].
  static String capitalizeWords(String s) {
    if (s.isEmpty) return s;
    return s.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : '');
    }).join(' ');
  }

  /// Converts [s] to camelCase.
  static String camelCase(String s) {
    final words = _splitWords(s);
    if (words.isEmpty) return '';
    return words[0].toLowerCase() +
        words.skip(1).map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join('');
  }

  /// Converts [s] to PascalCase (UpperCamelCase).
  static String pascalCase(String s) {
    final words = _splitWords(s);
    return words.map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join('');
  }

  /// Converts [s] to snake_case.
  static String snakeCase(String s) {
    return _splitWords(s).map((w) => w.toLowerCase()).join('_');
  }

  /// Converts [s] to kebab-case.
  static String kebabCase(String s) {
    return _splitWords(s).map((w) => w.toLowerCase()).join('-');
  }

  /// Converts [s] to dot.case.
  static String dotCase(String s) {
    return _splitWords(s).map((w) => w.toLowerCase()).join('.');
  }

  /// Converts [s] to Title Case.
  static String titleCase(String s) {
    return capitalizeWords(s);
  }

  /// Splits a string into words, handling camelCase, snake_case, kebab-case, etc.
  static List<String> _splitWords(String s) {
    // First split camelCase
    final expanded = s.replaceAllMapped(
      GchPatterns.camelCaseSplit,
      (m) => ' ',
    );
    return expanded
        .split(GchPatterns.nonAlphanumeric)
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Truncates [s] to [maxLen] characters, appending [ellipsis] if truncated.
  static String truncate(String s, int maxLen, {String ellipsis = '...'}) {
    if (s.length <= maxLen) return s;
    final cutoff = maxLen - ellipsis.length;
    if (cutoff <= 0) return ellipsis.substring(0, maxLen);
    return s.substring(0, cutoff) + ellipsis;
  }

  /// Left-pads [s] to [width] with [pad] character.
  static String padLeft(String s, int width, [String pad = ' ']) {
    return s.padLeft(width, pad);
  }

  /// Right-pads [s] to [width] with [pad] character.
  static String padRight(String s, int width, [String pad = ' ']) {
    return s.padRight(width, pad);
  }

  /// Centers [s] within [width], padding with [pad] on both sides.
  static String center(String s, int width, [String pad = ' ']) {
    if (s.length >= width) return s;
    final totalPad = width - s.length;
    final leftPad = totalPad ~/ 2;
    final rightPad = totalPad - leftPad;
    return pad * leftPad + s + pad * rightPad;
  }

  /// Repeats [s] [n] times.
  static String repeat(String s, int n) {
    if (n <= 0) return '';
    return s * n;
  }

  /// Removes all whitespace from [s].
  static String removeWhitespace(String s) {
    return s.replaceAll(GchPatterns.whitespaceRegex, '');
  }

  /// Collapses multiple whitespace characters into a single space.
  static String collapseWhitespace(String s) {
    return s.replaceAll(GchPatterns.whitespaceRegex, ' ').trim();
  }

  /// Trims whitespace from each line.
  static String trimLines(String s) {
    return s.split(GchPatterns.lineRegex).map((line) => line.trim()).join('\n');
  }

  /// Counts the number of words in [s].
  static int wordCount(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(GchPatterns.whitespaceRegex).length;
  }

  /// Returns the number of characters (code units) in [s].
  static int charCount(String s) => s.length;

  /// Counts the number of lines in [s].
  static int lineCount(String s) {
    if (s.isEmpty) return 0;
    return s.split(GchPatterns.lineRegex).length;
  }

  /// Estimates the number of sentences in [s].
  static int sentenceCount(String s) {
    if (s.trim().isEmpty) return 0;
    final matches = GchPatterns.sentenceEndRegex.allMatches(s);
    final count = matches.length;
    return count == 0 ? 1 : count;
  }

  /// Counts how many times [pattern] occurs in [s].
  static int countOccurrences(String s, String pattern) {
    if (pattern.isEmpty) return 0;
    int count = 0;
    int start = 0;
    while (true) {
      final idx = s.indexOf(pattern, start);
      if (idx == -1) break;
      count++;
      start = idx + pattern.length;
    }
    return count;
  }

  /// Extracts all numbers (integer and decimal) from [s].
  static List<double> extractNumbers(String s) {
    return GchPatterns.numberRegex
        .allMatches(s)
        .map((m) => double.tryParse(m.group(0)!))
        .whereType<double>()
        .toList();
  }

  /// Extracts all URLs from [s].
  static List<String> extractUrls(String s) {
    return GchPatterns.urlRegex.allMatches(s).map((m) => m.group(0)!).toList();
  }

  /// Extracts all email addresses from [s].
  static List<String> extractEmails(String s) {
    return GchPatterns.emailInTextRegex.allMatches(s).map((m) => m.group(0)!).toList();
  }

  /// Extracts all hashtags (e.g., #flutter) from [s].
  static List<String> extractHashtags(String s) {
    return GchPatterns.hashtagRegex.allMatches(s).map((m) => m.group(0)!).toList();
  }

  /// Masks an email address: user@example.com → u***@e***.com.
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final user = parts[0];
    final domainParts = parts[1].split('.');
    final maskedUser = user.isEmpty ? '' : user[0] + ('*' * (user.length - 1).clamp(3, 10));
    final maskedDomain = domainParts[0].isEmpty
        ? ''
        : domainParts[0][0] + ('*' * (domainParts[0].length - 1).clamp(3, 8));
    final tld = domainParts.skip(1).join('.');
    return '$maskedUser@$maskedDomain.$tld';
  }

  /// Masks a phone number, showing only the last 4 digits.
  static String maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '***-****-${digits.padLeft(4, '*')}';
    final last4 = digits.substring(digits.length - 4);
    return '***-****-$last4';
  }

  /// Masks a credit card number, showing only the last 4 digits.
  static String maskCreditCard(String card) {
    final digits = card.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '**** **** **** ****';
    final last4 = digits.substring(digits.length - 4);
    return '**** **** **** $last4';
  }

  /// Converts [s] to a URL slug.
  static String slugify(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(GchPatterns.nonAlphanumericHyphen, '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Escapes HTML special characters in [s].
  static String escapeHtml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Unescapes HTML entities in [s].
  static String unescapeHtml(String s) {
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  /// Escapes special regex characters in [s].
  static String escapeRegex(String s) {
    return s.replaceAllMapped(
      RegExp(r'[.*+?^${}()|[\]\\]'),
      (m) => '\\${m.group(0)}',
    );
  }

  /// Wraps [s] at [lineWidth] characters, breaking at word boundaries.
  static String wrapText(String s, int lineWidth) {
    if (lineWidth <= 0) return s;
    final words = s.split(' ');
    final lines = <String>[];
    var currentLine = StringBuffer();
    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine.write(word);
      } else if (currentLine.length + 1 + word.length <= lineWidth) {
        currentLine.write(' $word');
      } else {
        lines.add(currentLine.toString());
        currentLine = StringBuffer(word);
      }
    }
    if (currentLine.isNotEmpty) lines.add(currentLine.toString());
    return lines.join('\n');
  }

  /// Adds [spaces] spaces of indentation to each line of [s].
  static String indent(String s, int spaces) {
    final prefix = ' ' * spaces;
    return s.split(GchPatterns.lineRegex).map((line) => '$prefix$line').join('\n');
  }

  /// Removes the common leading whitespace from all lines of [s].
  static String dedent(String s) {
    final lines = s.split(GchPatterns.lineRegex);
    final nonEmpty = lines.where((l) => l.trim().isNotEmpty).toList();
    if (nonEmpty.isEmpty) return s;
    final minIndent = nonEmpty.map((l) {
      int i = 0;
      while (i < l.length && l[i] == ' ') i++;
      return i;
    }).reduce(min);
    return lines.map((l) => l.length >= minIndent ? l.substring(minIndent) : l).join('\n');
  }

  /// Generates a random string of [length] characters from [charset].
  static String randomString(int length, {String charset = GchCharsets.alphanumeric, Random? rng}) {
    final random = rng ?? Random();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Generates a random UUID v4 string.
  static String uuid4({Random? rng}) {
    final random = rng ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant bits
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).toList();
    return '${b[0]}${b[1]}${b[2]}${b[3]}-'
        '${b[4]}${b[5]}-'
        '${b[6]}${b[7]}-'
        '${b[8]}${b[9]}-'
        '${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
  }

  /// Encodes [s] to Base64.
  static String base64Encode(String s) {
    return base64.encode(utf8.encode(s));
  }

  /// Decodes a Base64 string.
  static String base64Decode(String s) {
    return utf8.decode(base64.decode(s));
  }

  /// Encodes a list of bytes to a hex string.
  static String hexEncode(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Decodes a hex string to a list of bytes.
  static List<int> hexDecode(String hex) {
    final clean = hex.replaceAll(' ', '');
    final result = <int>[];
    for (int i = 0; i < clean.length - 1; i += 2) {
      result.add(int.parse(clean.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  /// Computes Jaro-Winkler similarity between [a] and [b] (0.0 - 1.0).
  static double similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final matchDist = (max(a.length, b.length) / 2).floor() - 1;
    final aMatches = List<bool>.filled(a.length, false);
    final bMatches = List<bool>.filled(b.length, false);
    int matches = 0;
    int transpositions = 0;

    for (int i = 0; i < a.length; i++) {
      final start = max(0, i - matchDist);
      final end = min(i + matchDist + 1, b.length);
      for (int j = start; j < end; j++) {
        if (bMatches[j] || a[i] != b[j]) continue;
        aMatches[i] = true;
        bMatches[j] = true;
        matches++;
        break;
      }
    }

    if (matches == 0) return 0.0;

    int k = 0;
    for (int i = 0; i < a.length; i++) {
      if (!aMatches[i]) continue;
      while (!bMatches[k]) k++;
      if (a[i] != b[k]) transpositions++;
      k++;
    }

    final jaro = (matches / a.length + matches / b.length + (matches - transpositions / 2) / matches) / 3;

    // Winkler prefix bonus
    int prefix = 0;
    for (int i = 0; i < min(4, min(a.length, b.length)); i++) {
      if (a[i] == b[i]) {
        prefix++;
      } else {
        break;
      }
    }
    return jaro + prefix * 0.1 * (1 - jaro);
  }

  /// Returns the longest common prefix of all strings in [strs].
  static String longestCommonPrefix(List<String> strs) {
    if (strs.isEmpty) return '';
    if (strs.length == 1) return strs[0];
    String prefix = strs[0];
    for (int i = 1; i < strs.length; i++) {
      while (!strs[i].startsWith(prefix)) {
        prefix = prefix.substring(0, prefix.length - 1);
        if (prefix.isEmpty) return '';
      }
    }
    return prefix;
  }

  /// Checks if [s] is a palindrome (ignoring case and non-alphabetic).
  static bool isPalindrome(String s) {
    final clean = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return clean == clean.split('').reversed.join();
  }

  /// Returns the Levenshtein (edit) distance between [a] and [b].
  static int editDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final dp = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
    for (int i = 0; i <= a.length; i++) dp[i][0] = i;
    for (int j = 0; j <= b.length; j++) dp[0][j] = j;
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(min);
        }
      }
    }
    return dp[a.length][b.length];
  }

  /// Returns true if [s] starts with any of the given [prefixes].
  static bool startsWithAny(String s, List<String> prefixes) {
    return prefixes.any((p) => s.startsWith(p));
  }

  /// Returns true if [s] ends with any of the given [suffixes].
  static bool endsWithAny(String s, List<String> suffixes) {
    return suffixes.any((p) => s.endsWith(p));
  }

  /// Reverses a string.
  static String reverse(String s) {
    return String.fromCharCodes(s.codeUnits.reversed);
  }

  /// Counts vowels in [s] (a, e, i, o, u, case-insensitive).
  static int countVowels(String s) {
    return s.toLowerCase().split('').where((c) => 'aeiou'.contains(c)).length;
  }

  /// Counts consonants in [s] (letters that are not vowels).
  static int countConsonants(String s) {
    return s.toLowerCase().split('').where((c) => RegExp(r'[a-z]').hasMatch(c) && !'aeiou'.contains(c)).length;
  }

  /// Removes all HTML tags from [s].
  static String stripHtml(String s) {
    return s.replaceAll(GchPatterns.htmlTagRegex, '');
  }

  /// Abbreviates a full name to initials (e.g., "John Doe" → "JD").
  static String initials(String name) {
    return name
        .split(GchPatterns.whitespaceRegex)
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .join();
  }

  /// Generates a consistent color-code hex string from a string (deterministic).
  static String toColorHash(String s) {
    int hash = 0;
    for (final c in s.codeUnits) {
      hash = c + ((hash << 5) - hash);
      hash = hash & 0xFFFFFF;
    }
    return '#${(hash & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Checks whether [s] contains only ASCII characters.
  static bool isAscii(String s) {
    return s.codeUnits.every((c) => c < 128);
  }

  /// Counts the occurrences of each character in [s].
  static Map<String, int> charFrequency(String s) {
    final freq = <String, int>{};
    for (final c in s.split('')) {
      freq[c] = (freq[c] ?? 0) + 1;
    }
    return freq;
  }

  /// Returns the most frequent character in [s].
  static String? mostFrequentChar(String s) {
    if (s.isEmpty) return null;
    final freq = charFrequency(s);
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Joins a list of strings with [separator], using [lastSeparator] before the last element.
  static String joinWithOxfordComma(List<String> items, {String separator = ', ', String lastSeparator = ', and '}) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items[0];
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    final allButLast = items.sublist(0, items.length - 1);
    return allButLast.join(separator) + lastSeparator + items.last;
  }

  /// Formats bytes into a human-readable string.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Returns true if [s] contains only digits.
  static bool isNumeric(String s) => RegExp(r'^\d+$').hasMatch(s);

  /// Returns true if [s] contains only alphabetic characters.
  static bool isAlpha(String s) => RegExp(r'^[a-zA-Z]+$').hasMatch(s);

  /// Returns true if [s] contains only alphanumeric characters.
  static bool isAlphanumeric(String s) => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(s);

  /// Returns true if [s] is a valid hex string (even length).
  static bool isHex(String s) => s.isNotEmpty && s.length % 2 == 0 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(s);

  /// Converts a string to a list of Unicode code points.
  static List<int> toCodePoints(String s) => s.runes.toList();

  /// Creates a string from a list of Unicode code points.
  static String fromCodePoints(List<int> codePoints) => String.fromCharCodes(codePoints);

  /// Returns every nth character of [s].
  static String everyNth(String s, int n) {
    if (n <= 0) return s;
    final result = StringBuffer();
    for (int i = 0; i < s.length; i += n) {
      result.write(s[i]);
    }
    return result.toString();
  }

  /// Interleaves [a] and [b] character by character.
  static String interleave(String a, String b) {
    final result = StringBuffer();
    final maxLen = max(a.length, b.length);
    for (int i = 0; i < maxLen; i++) {
      if (i < a.length) result.write(a[i]);
      if (i < b.length) result.write(b[i]);
    }
    return result.toString();
  }

  /// Replaces all occurrences of keys in [replacements] map within [s].
  static String multiReplace(String s, Map<String, String> replacements) {
    String result = s;
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Returns lines of [s] that contain [substring] (case-insensitive).
  static List<String> grepLines(String s, String substring) {
    final lower = substring.toLowerCase();
    return s.split(GchPatterns.lineRegex).where((line) => line.toLowerCase().contains(lower)).toList();
  }

  /// Returns [s] with all lines numbered (e.g., "  1: first line").
  static String numberLines(String s, {int startAt = 1}) {
    final lines = s.split(GchPatterns.lineRegex);
    final width = (lines.length + startAt - 1).toString().length;
    return lines
        .asMap()
        .entries
        .map((e) => '${(e.key + startAt).toString().padLeft(width)}: ${e.value}')
        .join('\n');
  }

  /// Splits [s] into chunks of [size] characters.
  static List<String> chunkString(String s, int size) {
    if (size <= 0) return [s];
    final result = <String>[];
    for (int i = 0; i < s.length; i += size) {
      result.add(s.substring(i, min(i + size, s.length)));
    }
    return result;
  }

  /// Returns the [n] most frequent words in [s].
  static List<String> topWords(String s, int n) {
    final words = s
        .toLowerCase()
        .split(GchPatterns.whitespaceRegex)
        .where((w) => w.isNotEmpty)
        .toList();
    final freq = <String, int>{};
    for (final word in words) {
      freq[word] = (freq[word] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }

  /// Returns true if [s] is a valid JSON-like structure (starts/ends with {}, []).
  static bool looksLikeJson(String s) {
    final trimmed = s.trim();
    return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'));
  }

  /// Converts a string to its binary representation.
  static String toBinary(String s) {
    return s.codeUnits.map((c) => c.toRadixString(2).padLeft(8, '0')).join(' ');
  }

  /// Converts snake_case identifiers to a human-readable label.
  static String toLabel(String s) {
    return s
        .replaceAll(RegExp(r'[_\-]'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Returns a censored version of [s] replacing characters in the middle with [censor].
  static String censor(String s, {int visibleStart = 1, int visibleEnd = 1, String censor = '*'}) {
    if (s.length <= visibleStart + visibleEnd) return censor * s.length;
    final start = s.substring(0, visibleStart);
    final end = visibleEnd > 0 ? s.substring(s.length - visibleEnd) : '';
    final middle = censor * (s.length - visibleStart - visibleEnd);
    return start + middle + end;
  }

  /// Normalizes line endings to LF (\n).
  static String normalizeLF(String s) {
    return s.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  /// Returns true if [s] is composed entirely of whitespace.
  static bool isBlank(String s) => s.trim().isEmpty;

  /// Returns true if [s] has at least one non-whitespace character.
  static bool isNotBlank(String s) => s.trim().isNotEmpty;

  /// Wraps [s] with [left] and [right] delimiters.
  static String wrap(String s, {String left = '(', String right = ')'}) => '$left$s$right';

  /// Removes leading [prefix] from [s] if present.
  static String removePrefix(String s, String prefix) =>
      s.startsWith(prefix) ? s.substring(prefix.length) : s;

  /// Removes trailing [suffix] from [s] if present.
  static String removeSuffix(String s, String suffix) =>
      s.endsWith(suffix) ? s.substring(0, s.length - suffix.length) : s;

  /// Returns the substring between [start] and [end] markers (exclusive).
  static String between(String s, String start, String end) {
    final si = s.indexOf(start);
    if (si == -1) return '';
    final ei = s.indexOf(end, si + start.length);
    if (ei == -1) return '';
    return s.substring(si + start.length, ei);
  }

  /// Splits [s] into a list of grapheme clusters (handles emoji/surrogate pairs).
  static List<String> graphemes(String s) {
    final result = <String>[];
    final runes = s.runes.toList();
    for (int i = 0; i < runes.length; i++) {
      result.add(String.fromCharCode(runes[i]));
    }
    return result;
  }

  /// Returns the ROT13 encoding of [s] (letters only).
  static String rot13(String s) {
    return s.split('').map((c) {
      final code = c.codeUnitAt(0);
      if (code >= 65 && code <= 90) return String.fromCharCode((code - 65 + 13) % 26 + 65);
      if (code >= 97 && code <= 122) return String.fromCharCode((code - 97 + 13) % 26 + 97);
      return c;
    }).join();
  }

  /// Returns the Caesar cipher encoding of [s] with given [shift].
  static String caesarCipher(String s, int shift) {
    return s.split('').map((c) {
      final code = c.codeUnitAt(0);
      if (code >= 65 && code <= 90) return String.fromCharCode((code - 65 + shift) % 26 + 65);
      if (code >= 97 && code <= 122) return String.fromCharCode((code - 97 + shift) % 26 + 97);
      return c;
    }).join();
  }

  /// Converts [s] to Morse code (letters and digits only).
  static String toMorse(String s) {
    const morseMap = {
      'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.',
      'F': '..-.', 'G': '--.', 'H': '....', 'I': '..', 'J': '.---',
      'K': '-.-', 'L': '.-..', 'M': '--', 'N': '-.', 'O': '---',
      'P': '.--.', 'Q': '--.-', 'R': '.-.', 'S': '...', 'T': '-',
      'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-', 'Y': '-.--',
      'Z': '--..', '0': '-----', '1': '.----', '2': '..---', '3': '...--',
      '4': '....-', '5': '.....', '6': '-....', '7': '--...', '8': '---..',
      '9': '----.',
    };
    return s.toUpperCase().split('').map((c) {
      if (c == ' ') return '/';
      return morseMap[c] ?? '?';
    }).join(' ');
  }

  /// Returns [s] with each word reversed but word order preserved.
  static String reverseWords(String s) {
    return s.split(GchPatterns.whitespaceRegex).map((w) => reverse(w)).join(' ');
  }

  /// Returns a text excerpt of at most [maxChars] characters, ending at a word boundary.
  static String excerpt(String s, int maxChars, {String ellipsis = '...'}) {
    if (s.length <= maxChars) return s;
    int cutoff = maxChars - ellipsis.length;
    while (cutoff > 0 && s[cutoff] != ' ') cutoff--;
    if (cutoff <= 0) cutoff = maxChars - ellipsis.length;
    return '${s.substring(0, cutoff).trimRight()}$ellipsis';
  }

  /// Normalizes diacritics (accent marks) by replacing common accented chars.
  static String removeDiacritics(String s) {
    const pairs = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ñ': 'n', 'ç': 'c', 'ý': 'y', 'ÿ': 'y',
      'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
      'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E',
      'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I',
      'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
      'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U',
      'Ñ': 'N', 'Ç': 'C', 'Ý': 'Y',
    };
    String result = s;
    pairs.forEach((from, to) => result = result.replaceAll(from, to));
    return result;
  }

  /// Returns true if [a] is an anagram of [b] (ignoring case and spaces).
  static bool isAnagram(String a, String b) {
    final normalize = (String s) => s.toLowerCase().replaceAll(' ', '').split('')..sort();
    return normalize(a).join() == normalize(b).join();
  }

  /// Counts the number of digits in [s].
  static int digitCount(String s) => s.split('').where((c) => RegExp(r'\d').hasMatch(c)).length;

  /// Returns true if [s] contains at least one uppercase letter.
  static bool hasUppercase(String s) => RegExp(r'[A-Z]').hasMatch(s);

  /// Returns true if [s] contains at least one lowercase letter.
  static bool hasLowercase(String s) => RegExp(r'[a-z]').hasMatch(s);

  /// Returns true if [s] contains at least one digit.
  static bool hasDigit(String s) => RegExp(r'\d').hasMatch(s);

  /// Returns true if [s] contains at least one special character.
  static bool hasSpecialChar(String s) => RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>?/]').hasMatch(s);
}
