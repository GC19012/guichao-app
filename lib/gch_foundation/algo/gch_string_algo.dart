// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:convert';
import 'dart:typed_data';

// ─────────────────────────────────────────────────────────────────────────────
// GchStringAlgo – static string algorithm utilities
// ─────────────────────────────────────────────────────────────────────────────
class GchStringAlgo {
  GchStringAlgo._();

  // ── KMP Search ─────────────────────────────────────────────────────────────
  static List<int> kmpSearch(String text, String pattern) {
    if (pattern.isEmpty) return [];
    final result = <int>[];
    final lps = _buildLPS(pattern);
    int i = 0, j = 0;
    while (i < text.length) {
      if (text[i] == pattern[j]) {
        i++;
        j++;
        if (j == pattern.length) {
          result.add(i - j);
          j = lps[j - 1];
        }
      } else {
        if (j != 0) {
          j = lps[j - 1];
        } else {
          i++;
        }
      }
    }
    return result;
  }

  static List<int> _buildLPS(String pattern) {
    final lps = List<int>.filled(pattern.length, 0);
    int len = 0, i = 1;
    while (i < pattern.length) {
      if (pattern[i] == pattern[len]) {
        lps[i++] = ++len;
      } else {
        if (len != 0) {
          len = lps[len - 1];
        } else {
          lps[i++] = 0;
        }
      }
    }
    return lps;
  }

  // ── Rabin-Karp Search ──────────────────────────────────────────────────────
  static List<int> rabinKarpSearch(String text, String pattern) {
    if (pattern.isEmpty) return [];
    const base = 31;
    const mod = 1000000007;
    final result = <int>[];
    final n = text.length, m = pattern.length;
    if (m > n) return result;

    int patternHash = 0, windowHash = 0, power = 1;
    for (int i = 0; i < m - 1; i++) power = (power * base) % mod;
    for (int i = 0; i < m; i++) {
      patternHash = (patternHash * base + pattern.codeUnitAt(i)) % mod;
      windowHash = (windowHash * base + text.codeUnitAt(i)) % mod;
    }
    for (int i = 0; i <= n - m; i++) {
      if (windowHash == patternHash) {
        if (text.substring(i, i + m) == pattern) result.add(i);
      }
      if (i < n - m) {
        windowHash = (base * (windowHash - text.codeUnitAt(i) * power % mod) +
                text.codeUnitAt(i + m)) %
            mod;
        if (windowHash < 0) windowHash += mod;
      }
    }
    return result;
  }

  // ── Boyer-Moore (bad character heuristic) Search ───────────────────────────
  static List<int> boyerMooreSearch(String text, String pattern) {
    if (pattern.isEmpty) return [];
    final result = <int>[];
    final n = text.length, m = pattern.length;
    if (m > n) return result;

    final badChar = <int, int>{};
    for (int i = 0; i < m; i++) {
      badChar[pattern.codeUnitAt(i)] = i;
    }

    int s = 0;
    while (s <= n - m) {
      int j = m - 1;
      while (j >= 0 && pattern[j] == text[s + j]) j--;
      if (j < 0) {
        result.add(s);
        final next = s + m < n ? badChar[text.codeUnitAt(s + m)] ?? -1 : -1;
        s += m - next;
      } else {
        final bc = badChar[text.codeUnitAt(s + j)] ?? -1;
        s += (j - bc).clamp(1, m);
      }
    }
    return result;
  }

  // ── LCS (Longest Common Subsequence) ──────────────────────────────────────
  static String longestCommonSubsequence(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }
    final sb = StringBuffer();
    int i = m, j = n;
    while (i > 0 && j > 0) {
      if (a[i - 1] == b[j - 1]) {
        sb.write(a[i - 1]);
        i--;
        j--;
      } else if (dp[i - 1][j] > dp[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }
    return sb.toString().split('').reversed.join();
  }

  // ── Longest Common Substring ───────────────────────────────────────────────
  static String longestCommonSubstring(String a, String b) {
    final m = a.length, n = b.length;
    int maxLen = 0, endIdx = 0;
    final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
          if (dp[i][j] > maxLen) {
            maxLen = dp[i][j];
            endIdx = i;
          }
        }
      }
    }
    return a.substring(endIdx - maxLen, endIdx);
  }

  // ── Edit Distance (Levenshtein) ────────────────────────────────────────────
  static int editDistance(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (i) => List<int>.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 +
              [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
                  .reduce((a, b) => a < b ? a : b);
        }
      }
    }
    return dp[m][n];
  }

  // ── Longest Palindromic Substring (Manacher) ───────────────────────────────
  static String longestPalindromicSubstring(String s) {
    if (s.isEmpty) return '';
    // Transform: insert '#' between characters
    final t = '#${s.split('').join('#')}#';
    final n = t.length;
    final p = List<int>.filled(n, 0);
    int center = 0, right = 0;
    for (int i = 0; i < n; i++) {
      final mirror = 2 * center - i;
      if (i < right) p[i] = (right - i).clamp(0, p[mirror]);
      // expand around center i
      while (i + p[i] + 1 < n &&
          i - p[i] - 1 >= 0 &&
          t[i + p[i] + 1] == t[i - p[i] - 1]) {
        p[i]++;
      }
      if (i + p[i] > right) {
        center = i;
        right = i + p[i];
      }
    }
    int maxLen = 0, centerIdx = 0;
    for (int i = 0; i < n; i++) {
      if (p[i] > maxLen) {
        maxLen = p[i];
        centerIdx = i;
      }
    }
    final start = (centerIdx - maxLen) ~/ 2;
    return s.substring(start, start + maxLen);
  }

  // ── isAnagram ──────────────────────────────────────────────────────────────
  static bool isAnagram(String a, String b) {
    if (a.length != b.length) return false;
    final count = <String, int>{};
    for (final c in a.split('')) count[c] = (count[c] ?? 0) + 1;
    for (final c in b.split('')) {
      count[c] = (count[c] ?? 0) - 1;
      if (count[c]! < 0) return false;
    }
    return true;
  }

  // ── isPalindrome ───────────────────────────────────────────────────────────
  static bool isPalindrome(String s) {
    int lo = 0, hi = s.length - 1;
    while (lo < hi) {
      if (s[lo] != s[hi]) return false;
      lo++;
      hi--;
    }
    return true;
  }

  // ── reverseWords ───────────────────────────────────────────────────────────
  static String reverseWords(String s) {
    return s.trim().split(RegExp(r'\s+')).reversed.join(' ');
  }

  // ── RLE compress ───────────────────────────────────────────────────────────
  static String compressRLE(String s) {
    if (s.isEmpty) return '';
    final sb = StringBuffer();
    int count = 1;
    for (int i = 1; i <= s.length; i++) {
      if (i < s.length && s[i] == s[i - 1]) {
        count++;
      } else {
        if (count > 1) sb.write(count);
        sb.write(s[i - 1]);
        count = 1;
      }
    }
    return sb.toString();
  }

  // ── RLE decompress ─────────────────────────────────────────────────────────
  static String decompressRLE(String s) {
    final sb = StringBuffer();
    int i = 0;
    while (i < s.length) {
      // accumulate digits
      int num = 0;
      while (i < s.length && s[i].codeUnitAt(0) >= 48 && s[i].codeUnitAt(0) <= 57) {
        num = num * 10 + int.parse(s[i]);
        i++;
      }
      if (i < s.length) {
        final ch = s[i++];
        sb.write(ch * (num == 0 ? 1 : num));
      }
    }
    return sb.toString();
  }

  // ── Roman to Int ───────────────────────────────────────────────────────────
  static int romanToInt(String s) {
    const map = {
      'I': 1, 'V': 5, 'X': 10, 'L': 50,
      'C': 100, 'D': 500, 'M': 1000,
    };
    int result = 0;
    for (int i = 0; i < s.length; i++) {
      final cur = map[s[i]] ?? 0;
      final next = i + 1 < s.length ? (map[s[i + 1]] ?? 0) : 0;
      if (cur < next) {
        result -= cur;
      } else {
        result += cur;
      }
    }
    return result;
  }

  // ── Int to Roman ───────────────────────────────────────────────────────────
  static String intToRoman(int n) {
    const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const symbols = [
      'M', 'CM', 'D', 'CD', 'C', 'XC',
      'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'
    ];
    final sb = StringBuffer();
    int num = n;
    for (int i = 0; i < values.length; i++) {
      while (num >= values[i]) {
        sb.write(symbols[i]);
        num -= values[i];
      }
    }
    return sb.toString();
  }

  // ── Balanced Brackets ──────────────────────────────────────────────────────
  static bool isBalancedBrackets(String s) {
    const open = '({[';
    const close = ')}]';
    final stack = <String>[];
    for (final ch in s.split('')) {
      if (open.contains(ch)) {
        stack.add(ch);
      } else if (close.contains(ch)) {
        if (stack.isEmpty) return false;
        final top = stack.removeLast();
        final idx = close.indexOf(ch);
        if (open[idx] != top) return false;
      }
    }
    return stack.isEmpty;
  }

  // ── Zigzag Conversion (LeetCode 6) ────────────────────────────────────────
  static String zigzagConvert(String s, int numRows) {
    if (numRows <= 1 || s.length <= numRows) return s;
    final rows = List<StringBuffer>.generate(numRows, (_) => StringBuffer());
    int curRow = 0;
    bool goingDown = false;
    for (final ch in s.split('')) {
      rows[curRow].write(ch);
      if (curRow == 0 || curRow == numRows - 1) goingDown = !goingDown;
      curRow += goingDown ? 1 : -1;
    }
    return rows.map((r) => r.toString()).join();
  }

  // ── Multiply Strings (big integer) ────────────────────────────────────────
  static String multiplyStrings(String a, String b) {
    if (a == '0' || b == '0') return '0';
    final m = a.length, n = b.length;
    final pos = List<int>.filled(m + n, 0);
    for (int i = m - 1; i >= 0; i--) {
      for (int j = n - 1; j >= 0; j--) {
        final mul = (a.codeUnitAt(i) - 48) * (b.codeUnitAt(j) - 48);
        final p1 = i + j, p2 = i + j + 1;
        final sum = mul + pos[p2];
        pos[p2] = sum % 10;
        pos[p1] += sum ~/ 10;
      }
    }
    final sb = StringBuffer();
    for (final d in pos) {
      if (!(sb.isEmpty && d == 0)) sb.write(d);
    }
    return sb.isEmpty ? '0' : sb.toString();
  }

  // ── Add Binary Strings ─────────────────────────────────────────────────────
  static String addBinaryStrings(String a, String b) {
    final sb = StringBuffer();
    int i = a.length - 1, j = b.length - 1, carry = 0;
    while (i >= 0 || j >= 0 || carry > 0) {
      final da = i >= 0 ? a.codeUnitAt(i--) - 48 : 0;
      final db = j >= 0 ? b.codeUnitAt(j--) - 48 : 0;
      final sum = da + db + carry;
      sb.write(sum % 2);
      carry = sum ~/ 2;
    }
    return sb.toString().split('').reversed.join();
  }

  // ── Word frequency map ─────────────────────────────────────────────────────
  static Map<String, int> wordFrequency(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final freq = <String, int>{};
    for (final w in words) {
      if (w.isNotEmpty) freq[w] = (freq[w] ?? 0) + 1;
    }
    return freq;
  }

  // ── String to character frequency ─────────────────────────────────────────
  static Map<String, int> charFrequency(String s) {
    final freq = <String, int>{};
    for (final ch in s.split('')) {
      freq[ch] = (freq[ch] ?? 0) + 1;
    }
    return freq;
  }

  // ── Remove duplicates preserving order ────────────────────────────────────
  static String removeDuplicateChars(String s) {
    final seen = <String>{};
    final sb = StringBuffer();
    for (final ch in s.split('')) {
      if (!seen.contains(ch)) {
        seen.add(ch);
        sb.write(ch);
      }
    }
    return sb.toString();
  }

  // ── Find first non-repeating character ────────────────────────────────────
  static String? firstNonRepeating(String s) {
    final freq = charFrequency(s);
    for (final ch in s.split('')) {
      if (freq[ch] == 1) return ch;
    }
    return null;
  }

  // ── Count vowels and consonants ────────────────────────────────────────────
  static ({int vowels, int consonants}) countVowelsConsonants(String s) {
    const vowelSet = {'a', 'e', 'i', 'o', 'u'};
    int vowels = 0, consonants = 0;
    for (final ch in s.toLowerCase().split('')) {
      if (RegExp(r'[a-z]').hasMatch(ch)) {
        if (vowelSet.contains(ch)) {
          vowels++;
        } else {
          consonants++;
        }
      }
    }
    return (vowels: vowels, consonants: consonants);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GchStringMetrics – string similarity and encoding metrics
// ─────────────────────────────────────────────────────────────────────────────
class GchStringMetrics {
  GchStringMetrics._();

  // ── Hamming Distance ───────────────────────────────────────────────────────
  static int hammingDistance(String a, String b) {
    if (a.length != b.length) {
      throw ArgumentError('Strings must be equal length for Hamming distance');
    }
    int dist = 0;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) dist++;
    }
    return dist;
  }

  // ── Jaccard Similarity ─────────────────────────────────────────────────────
  static double jaccardSimilarity(String a, String b) {
    final setA = Set<String>.from(a.split(''));
    final setB = Set<String>.from(b.split(''));
    final intersection = setA.intersection(setB).length;
    final unionSize = setA.union(setB).length;
    if (unionSize == 0) return 1.0;
    return intersection / unionSize;
  }

  // ── Cosine Similarity (word-frequency vectors) ─────────────────────────────
  static double cosineSimilarity(String a, String b) {
    final freqA = GchStringAlgo.wordFrequency(a);
    final freqB = GchStringAlgo.wordFrequency(b);
    final allWords = {...freqA.keys, ...freqB.keys};
    double dot = 0, magA = 0, magB = 0;
    for (final w in allWords) {
      final fa = (freqA[w] ?? 0).toDouble();
      final fb = (freqB[w] ?? 0).toDouble();
      dot += fa * fb;
      magA += fa * fa;
      magB += fb * fb;
    }
    if (magA == 0 || magB == 0) return 0.0;
    return dot / (magA * magB <= 0 ? 1.0 : _sqrt(magA * magB));
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 50; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  // ── Soundex ────────────────────────────────────────────────────────────────
  static String soundex(String s) {
    if (s.isEmpty) return '';
    const code = {
      'B': '1', 'F': '1', 'P': '1', 'V': '1',
      'C': '2', 'G': '2', 'J': '2', 'K': '2', 'Q': '2', 'S': '2', 'X': '2', 'Z': '2',
      'D': '3', 'T': '3',
      'L': '4',
      'M': '5', 'N': '5',
      'R': '6',
    };
    final upper = s.toUpperCase();
    final sb = StringBuffer(upper[0]);
    String prev = code[upper[0]] ?? '0';
    for (int i = 1; i < upper.length && sb.length < 4; i++) {
      final cur = code[upper[i]] ?? '0';
      if (cur != '0' && cur != prev) sb.write(cur);
      prev = cur;
    }
    while (sb.length < 4) sb.write('0');
    return sb.toString().substring(0, 4);
  }

  // ── Metaphone (simplified) ─────────────────────────────────────────────────
  static String metaphone(String s) {
    if (s.isEmpty) return '';
    String word = s.toUpperCase();
    // Drop initial silent letters
    if (word.startsWith('AE') ||
        word.startsWith('GN') ||
        word.startsWith('KN') ||
        word.startsWith('PN') ||
        word.startsWith('WR')) {
      word = word.substring(1);
    }
    final sb = StringBuffer();
    for (int i = 0; i < word.length; i++) {
      final ch = word[i];
      final prev = i > 0 ? word[i - 1] : '';
      final next = i + 1 < word.length ? word[i + 1] : '';
      if ('AEIOU'.contains(ch)) {
        if (i == 0) sb.write(ch);
        continue;
      }
      switch (ch) {
        case 'B':
          if (!(i == word.length - 1 && prev == 'M')) sb.write('B');
          break;
        case 'C':
          if ('EIY'.contains(next)) {
            sb.write('S');
          } else {
            sb.write('K');
          }
          break;
        case 'D':
          if (next == 'G' && 'EIY'.contains(i + 2 < word.length ? word[i + 2] : '')) {
            sb.write('J');
            i++;
          } else {
            sb.write('T');
          }
          break;
        case 'F':
          sb.write('F');
          break;
        case 'G':
          if ('EIY'.contains(next)) {
            sb.write('J');
          } else if (next != 'H' && !(next == 'N' && i + 1 == word.length - 1)) {
            sb.write('K');
          }
          break;
        case 'H':
          if ('AEIOU'.contains(next) && !'AEIOU'.contains(prev)) sb.write('H');
          break;
        case 'J':
          sb.write('J');
          break;
        case 'K':
          if (prev != 'C') sb.write('K');
          break;
        case 'L':
          sb.write('L');
          break;
        case 'M':
          sb.write('M');
          break;
        case 'N':
          sb.write('N');
          break;
        case 'P':
          if (next == 'H') {
            sb.write('F');
            i++;
          } else {
            sb.write('P');
          }
          break;
        case 'Q':
          sb.write('K');
          break;
        case 'R':
          sb.write('R');
          break;
        case 'S':
          if (next == 'H' || (next == 'I' && i + 2 < word.length && 'AO'.contains(word[i + 2]))) {
            sb.write('X');
          } else {
            sb.write('S');
          }
          break;
        case 'T':
          if (next == 'H') {
            sb.write('0');
          } else {
            sb.write('T');
          }
          break;
        case 'V':
          sb.write('F');
          break;
        case 'W':
          if ('AEIOU'.contains(next)) sb.write('W');
          break;
        case 'X':
          sb.write('KS');
          break;
        case 'Y':
          if ('AEIOU'.contains(next)) sb.write('Y');
          break;
        case 'Z':
          sb.write('S');
          break;
      }
    }
    return sb.toString();
  }

  // ── Normalized edit distance (0.0 to 1.0) ─────────────────────────────────
  static double normalizedEditDistance(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 0.0;
    final dist = GchStringAlgo.editDistance(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    return dist / maxLen;
  }

  // ── Longest common prefix ─────────────────────────────────────────────────
  static String longestCommonPrefix(List<String> strs) {
    if (strs.isEmpty) return '';
    String prefix = strs[0];
    for (int i = 1; i < strs.length; i++) {
      while (!strs[i].startsWith(prefix)) {
        prefix = prefix.substring(0, prefix.length - 1);
        if (prefix.isEmpty) return '';
      }
    }
    return prefix;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preset test string constants (50+ entries)
// ─────────────────────────────────────────────────────────────────────────────
const List<String> kTestStrings = [
  'hello', 'world', 'dart', 'flutter', 'programming',
  'algorithm', 'data', 'structure', 'binary', 'search',
  'insertion', 'deletion', 'traversal', 'recursion', 'iteration',
  'stack', 'queue', 'heap', 'graph', 'tree',
  'racecar', 'madam', 'level', 'refer', 'kayak',
  'abcdef', 'fedcba', 'aabbcc', 'abcabc', 'aaabbb',
  'listen', 'silent', 'enlist', 'inlets', 'tinsel',
  'MMXXVI', 'XIV', 'XLII', 'CDXLIV', 'MCMXCIX',
  'hello world', 'the quick brown fox', 'jumps over the lazy dog',
  'to be or not to be', 'that is the question',
  '({[]})', '({[}])', '((()))', '(())()', '([{}])',
  'aababab', 'aaaa', 'abababab', 'mississippi', 'abcabcabc',
  '101', '1101', '11111111', '10101010', '11001100',
  'dart is amazing', 'flutter is great', 'programming is fun',
];

const List<String> kPalindromeTests = [
  'racecar', 'madam', 'level', 'refer', 'kayak',
  'civic', 'radar', 'noon', 'rotor', 'stats',
  'abcba', 'amanaplanacanalpanama', 'wasitacaroracatisaw',
];

const List<String> kBracketTests = [
  '()', '[]', '{}', '([])', '{[()]}',
  '([)]', '{[}', '((', '))', '({[]})',
];

const List<String> kRomanNumerals = [
  'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
  'XI', 'XIV', 'XL', 'XC', 'CD', 'CM', 'XLII', 'XLIX', 'XCIX',
  'CDXLIV', 'MMXXVI', 'MCMXCIX', 'MMMDCCCLXXXVIII', 'MMMCMXCIX',
];

// ─────────────────────────────────────────────────────────────────────────────
// GchStringBuilder – efficient string building utilities
// ─────────────────────────────────────────────────────────────────────────────
class GchStringBuilder {
  GchStringBuilder._();

  /// Center a string within a given width using padding character.
  static String center(String s, int width, {String pad = ' '}) {
    if (s.length >= width) return s;
    final totalPad = width - s.length;
    final leftPad = totalPad ~/ 2;
    final rightPad = totalPad - leftPad;
    return pad * leftPad + s + pad * rightPad;
  }

  /// Left-justify within a given width.
  static String ljust(String s, int width, {String pad = ' '}) {
    if (s.length >= width) return s;
    return s + pad * (width - s.length);
  }

  /// Right-justify within a given width.
  static String rjust(String s, int width, {String pad = ' '}) {
    if (s.length >= width) return s;
    return pad * (width - s.length) + s;
  }

  /// Wrap text at the specified column width.
  static List<String> wrap(String text, int width) {
    if (width <= 0) throw ArgumentError('Width must be positive');
    final words = text.split(' ');
    final lines = <String>[];
    final line = StringBuffer();
    for (final word in words) {
      if (line.isEmpty) {
        line.write(word);
      } else if (line.length + 1 + word.length <= width) {
        line.write(' ');
        line.write(word);
      } else {
        lines.add(line.toString());
        line.clear();
        line.write(word);
      }
    }
    if (line.isNotEmpty) lines.add(line.toString());
    return lines;
  }

  /// Count occurrences of [sub] in [s].
  static int countOccurrences(String s, String sub) {
    if (sub.isEmpty) return 0;
    int count = 0, start = 0;
    while (true) {
      final idx = s.indexOf(sub, start);
      if (idx == -1) break;
      count++;
      start = idx + sub.length;
    }
    return count;
  }

  /// Replace all occurrences of [from] with [to] (non-overlapping).
  static String replaceAll(String s, String from, String to) {
    if (from.isEmpty) return s;
    return s.split(from).join(to);
  }

  /// Extract all substrings matching a simple glob pattern (* = any sequence).
  static bool matchGlob(String text, String pattern) {
    final m = text.length, n = pattern.length;
    final dp = List.generate(m + 1, (_) => List<bool>.filled(n + 1, false));
    dp[0][0] = true;
    for (int j = 1; j <= n; j++) {
      if (pattern[j - 1] == '*') dp[0][j] = dp[0][j - 1];
    }
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (pattern[j - 1] == '*') {
          dp[i][j] = dp[i - 1][j] || dp[i][j - 1];
        } else if (pattern[j - 1] == '?' || text[i - 1] == pattern[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        }
      }
    }
    return dp[m][n];
  }

  /// Trim characters from a set at both ends of a string.
  static String trimChars(String s, String chars) {
    int start = 0, end = s.length - 1;
    while (start <= end && chars.contains(s[start])) start++;
    while (end >= start && chars.contains(s[end])) end--;
    return s.substring(start, end + 1);
  }

  /// Convert camelCase to snake_case.
  static String camelToSnake(String s) {
    final sb = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch.toUpperCase() == ch && ch != ch.toLowerCase()) {
        if (i > 0) sb.write('_');
        sb.write(ch.toLowerCase());
      } else {
        sb.write(ch);
      }
    }
    return sb.toString();
  }

  /// Convert snake_case to camelCase.
  static String snakeToCamel(String s) {
    final parts = s.split('_');
    if (parts.isEmpty) return s;
    final sb = StringBuffer(parts[0]);
    for (int i = 1; i < parts.length; i++) {
      final p = parts[i];
      if (p.isNotEmpty) {
        sb.write(p[0].toUpperCase());
        sb.write(p.substring(1));
      }
    }
    return sb.toString();
  }

  /// Repeat a string n times.
  static String repeat(String s, int n) => s * n;

  /// Rotate string left by k characters.
  static String rotateLeft(String s, int k) {
    if (s.isEmpty) return s;
    k = k % s.length;
    return s.substring(k) + s.substring(0, k);
  }

  /// Rotate string right by k characters.
  static String rotateRight(String s, int k) {
    if (s.isEmpty) return s;
    k = k % s.length;
    return s.substring(s.length - k) + s.substring(0, s.length - k);
  }

  /// Check if s2 is a rotation of s1.
  static bool isRotation(String s1, String s2) {
    if (s1.length != s2.length) return false;
    return (s1 + s1).contains(s2);
  }

  /// Minimum window substring (LC 76).
  static String minWindowSubstring(String s, String t) {
    if (t.isEmpty || s.isEmpty) return '';
    final need = <String, int>{};
    for (final ch in t.split('')) need[ch] = (need[ch] ?? 0) + 1;
    int have = 0, required = need.length;
    final window = <String, int>{};
    int left = 0, minLen = s.length + 1, minLeft = 0;
    for (int right = 0; right < s.length; right++) {
      final ch = s[right];
      window[ch] = (window[ch] ?? 0) + 1;
      if (need.containsKey(ch) && window[ch] == need[ch]) have++;
      while (have == required) {
        if (right - left + 1 < minLen) {
          minLen = right - left + 1;
          minLeft = left;
        }
        final lCh = s[left];
        window[lCh] = window[lCh]! - 1;
        if (need.containsKey(lCh) && window[lCh]! < need[lCh]!) have--;
        left++;
      }
    }
    return minLen > s.length ? '' : s.substring(minLeft, minLeft + minLen);
  }
}
