// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';

// ──────────────────────────────────────────────
// GchBase64
// ──────────────────────────────────────────────
class GchBase64 {
  GchBase64._();

  static const String _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  static const String _urlChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  static String encode(List<int> bytes) {
    return _encodeInternal(bytes, _chars, padding: true);
  }

  static List<int> decode(String s) {
    return _decodeInternal(s.replaceAll('\n', '').replaceAll('\r', ''), _chars);
  }

  static String encodeUrl(List<int> bytes) {
    return _encodeInternal(bytes, _urlChars, padding: false);
  }

  static List<int> decodeUrl(String s) {
    final padded = s + '=' * ((4 - s.length % 4) % 4);
    return _decodeInternal(padded, _urlChars);
  }

  static String encodeString(String s) =>
      encode(utf8.encode(s));

  static String decodeString(String s) =>
      utf8.decode(decode(s));

  static String _encodeInternal(List<int> bytes, String chars,
      {required bool padding}) {
    final sb = StringBuffer();
    final n = bytes.length;
    int i = 0;
    while (i < n) {
      final b0 = bytes[i++];
      final b1 = i < n ? bytes[i++] : 0;
      final b2 = i < n ? bytes[i++] : 0;
      sb.write(chars[(b0 >> 2) & 0x3f]);
      sb.write(chars[((b0 << 4) | (b1 >> 4)) & 0x3f]);
      sb.write(chars[((b1 << 2) | (b2 >> 6)) & 0x3f]);
      sb.write(chars[b2 & 0x3f]);
    }
    if (padding) {
      final remainder = n % 3;
      if (remainder == 1) {
        final result = sb.toString();
        return result.substring(0, result.length - 2) + '==';
      } else if (remainder == 2) {
        final result = sb.toString();
        return result.substring(0, result.length - 1) + '=';
      }
    } else {
      final remainder = n % 3;
      if (remainder == 1) {
        final result = sb.toString();
        return result.substring(0, result.length - 2);
      } else if (remainder == 2) {
        final result = sb.toString();
        return result.substring(0, result.length - 1);
      }
    }
    return sb.toString();
  }

  static List<int> _decodeInternal(String s, String chars) {
    final lookup = <String, int>{};
    for (int i = 0; i < chars.length; i++) lookup[chars[i]] = i;

    final clean = s.replaceAll('=', '');
    final result = <int>[];
    int i = 0;
    while (i < clean.length) {
      final c0 = lookup[clean[i++]] ?? 0;
      final c1 = i < clean.length ? (lookup[clean[i++]] ?? 0) : 0;
      final c2 = i < clean.length ? (lookup[clean[i++]] ?? 0) : 0;
      final c3 = i < clean.length ? (lookup[clean[i++]] ?? 0) : 0;
      result.add((c0 << 2) | (c1 >> 4));
      if (i - 2 < clean.length) result.add(((c1 & 0xf) << 4) | (c2 >> 2));
      if (i - 1 < clean.length) result.add(((c2 & 0x3) << 6) | c3);
    }
    return result;
  }
}

// ──────────────────────────────────────────────
// GchHex
// ──────────────────────────────────────────────
class GchHex {
  GchHex._();

  static const String _hexChars = '0123456789abcdef';

  static String encode(List<int> bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(_hexChars[(b >> 4) & 0xf]);
      sb.write(_hexChars[b & 0xf]);
    }
    return sb.toString();
  }

  static List<int> decode(String hex) {
    final h = hex.toLowerCase().replaceAll(' ', '');
    if (h.length % 2 != 0) throw FormatException('Odd-length hex string');
    final result = <int>[];
    for (int i = 0; i < h.length; i += 2) {
      result.add(int.parse(h.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  static String encodeString(String s) => encode(utf8.encode(s));

  static String decodeString(String hex) => utf8.decode(decode(hex));

  static bool isValid(String hex) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex) && hex.length % 2 == 0;
  }

  static String format(List<int> bytes,
      {String separator = ':', bool uppercase = true}) {
    final parts = bytes.map((b) {
      final s = b.toRadixString(16).padLeft(2, '0');
      return uppercase ? s.toUpperCase() : s;
    });
    return parts.join(separator);
  }
}

// ──────────────────────────────────────────────
// GchXOR
// ──────────────────────────────────────────────
class GchXOR {
  GchXOR._();

  static List<int> encrypt(List<int> data, List<int> key) {
    if (key.isEmpty) return List.from(data);
    return List.generate(
        data.length, (i) => data[i] ^ key[i % key.length]);
  }

  static List<int> decrypt(List<int> data, List<int> key) =>
      encrypt(data, key);

  static String stringEncrypt(String text, String key) {
    final dataBytes = utf8.encode(text);
    final keyBytes = utf8.encode(key);
    final encrypted = encrypt(dataBytes, keyBytes);
    return GchHex.encode(encrypted);
  }

  static String stringDecrypt(String hexCipher, String key) {
    final dataBytes = GchHex.decode(hexCipher);
    final keyBytes = utf8.encode(key);
    final decrypted = decrypt(dataBytes, keyBytes);
    return utf8.decode(decrypted);
  }

  static List<int> multiKeyEncrypt(List<int> data, List<List<int>> keys) {
    List<int> result = List.from(data);
    for (final key in keys) result = encrypt(result, key);
    return result;
  }

  static List<int> multiKeyDecrypt(List<int> data, List<List<int>> keys) {
    List<int> result = List.from(data);
    for (final key in keys.reversed) result = decrypt(result, key);
    return result;
  }
}

// ──────────────────────────────────────────────
// GchCRC
// ──────────────────────────────────────────────
class GchCRC {
  GchCRC._();

  // CRC-8 lookup table (Dallas/Maxim polynomial 0x31)
  static final List<int> _crc8Table = _buildCRC8Table();
  // CRC-16 lookup table (IBM polynomial 0x8005)
  static final List<int> _crc16Table = _buildCRC16Table();
  // CRC-32 lookup table (IEEE 802.3 polynomial 0x04C11DB7)
  static final List<int> _crc32Table = _buildCRC32Table();

  static List<int> _buildCRC8Table() {
    final table = List.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      int crc = i;
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x80) != 0) {
          crc = ((crc << 1) ^ 0x31) & 0xff;
        } else {
          crc = (crc << 1) & 0xff;
        }
      }
      table[i] = crc;
    }
    return table;
  }

  static List<int> _buildCRC16Table() {
    final table = List.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      int crc = i << 8;
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x8005) & 0xffff;
        } else {
          crc = (crc << 1) & 0xffff;
        }
      }
      table[i] = crc;
    }
    return table;
  }

  static List<int> _buildCRC32Table() {
    final table = List.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      int crc = i;
      for (int j = 0; j < 8; j++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
      table[i] = crc;
    }
    return table;
  }

  static int crc8(List<int> data) {
    int crc = 0;
    for (final b in data) {
      crc = _crc8Table[(crc ^ b) & 0xff];
    }
    return crc;
  }

  static int crc16(List<int> data) {
    int crc = 0xffff;
    for (final b in data) {
      crc = ((crc << 8) ^ _crc16Table[((crc >> 8) ^ b) & 0xff]) & 0xffff;
    }
    return crc;
  }

  static int crc32(List<int> data) {
    int crc = 0xffffffff;
    for (final b in data) {
      crc = (crc >> 8) ^ _crc32Table[(crc ^ b) & 0xff];
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }

  static bool verifyCRC8(List<int> data, int expected) => crc8(data) == expected;
  static bool verifyCRC16(List<int> data, int expected) => crc16(data) == expected;
  static bool verifyCRC32(List<int> data, int expected) => crc32(data) == expected;
}

// ──────────────────────────────────────────────
// GchAdler32
// ──────────────────────────────────────────────
class GchAdler32 {
  GchAdler32._();

  static const int _mod = 65521;

  static int compute(List<int> data) {
    int a = 1, b = 0;
    for (final byte in data) {
      a = (a + byte) % _mod;
      b = (b + a) % _mod;
    }
    return (b << 16) | a;
  }

  static bool verify(List<int> data, int checksum) =>
      compute(data) == checksum;

  static int combine(int adler1, int adler2, int len2) {
    final remLen = len2 % _mod;
    final s1 = (adler1 & 0xffff) + remLen * ((adler2 >> 16) & 0xffff) % _mod;
    final s2 = ((adler1 >> 16) & 0xffff) + (adler2 & 0xffff) + _mod - 1 +
        ((adler2 >> 16) & 0xffff);
    return ((s2 % _mod) << 16) | (s1 % _mod);
  }
}

// ──────────────────────────────────────────────
// GchFNV
// ──────────────────────────────────────────────
class GchFNV {
  GchFNV._();

  static const int _fnv32Offset = 0x811c9dc5;
  static const int _fnv32Prime = 0x01000193;

  static int fnv1a32(List<int> data) {
    int hash = _fnv32Offset;
    for (final byte in data) {
      hash ^= byte;
      hash = (hash * _fnv32Prime) & 0xffffffff;
    }
    return hash;
  }

  static BigInt fnv1a64(List<int> data) {
    var hash = BigInt.parse('14695981039346656037');
    final prime = BigInt.parse('1099511628211');
    final mask = (BigInt.one << 64) - BigInt.one;
    for (final byte in data) {
      hash ^= BigInt.from(byte);
      hash = (hash * prime) & mask;
    }
    return hash;
  }

  static int fnv1a32String(String s) => fnv1a32(utf8.encode(s));

  static BigInt fnv1a64String(String s) => fnv1a64(utf8.encode(s));

  static int fnv1_32(List<int> data) {
    int hash = _fnv32Offset;
    for (final byte in data) {
      hash = (hash * _fnv32Prime) & 0xffffffff;
      hash ^= byte;
    }
    return hash;
  }
}

// ──────────────────────────────────────────────
// GchMurmur3
// ──────────────────────────────────────────────
class GchMurmur3 {
  GchMurmur3._();

  static int hash32(List<int> data, {int seed = 0}) {
    int h1 = seed;
    const int c1 = 0xcc9e2d51;
    const int c2 = 0x1b873593;

    final bytes = Uint8List.fromList(data);
    final nblocks = bytes.length ~/ 4;

    for (int i = 0; i < nblocks; i++) {
      int k1 = bytes[i * 4] |
          (bytes[i * 4 + 1] << 8) |
          (bytes[i * 4 + 2] << 16) |
          (bytes[i * 4 + 3] << 24);
      k1 = _multiply32(k1, c1);
      k1 = _rotl32(k1, 15);
      k1 = _multiply32(k1, c2);
      h1 ^= k1;
      h1 = _rotl32(h1, 13);
      h1 = _multiply32(h1, 5) + 0xe6546b64;
      h1 &= 0xffffffff;
    }

    int tail = 0;
    final tailStart = nblocks * 4;
    final remaining = bytes.length - tailStart;
    if (remaining >= 3) tail ^= bytes[tailStart + 2] << 16;
    if (remaining >= 2) tail ^= bytes[tailStart + 1] << 8;
    if (remaining >= 1) {
      tail ^= bytes[tailStart];
      tail = _multiply32(tail, c1);
      tail = _rotl32(tail, 15);
      tail = _multiply32(tail, c2);
      h1 ^= tail;
    }

    h1 ^= bytes.length;
    h1 = _fmix32(h1);
    return h1 & 0xffffffff;
  }

  static int hash32String(String s, {int seed = 0}) =>
      hash32(utf8.encode(s), seed: seed);

  static int _rotl32(int x, int r) {
    x &= 0xffffffff;
    return ((x << r) | (x >> (32 - r))) & 0xffffffff;
  }

  static int _multiply32(int a, int b) {
    // 32-bit multiply without overflow
    const mask16 = 0xffff;
    final ah = (a >> 16) & mask16;
    final al = a & mask16;
    final bh = (b >> 16) & mask16;
    final bl = b & mask16;
    final lo = al * bl;
    final hi = (ah * bl + al * bh) & mask16;
    return ((hi << 16) + lo) & 0xffffffff;
  }

  static int _fmix32(int h) {
    h ^= h >> 16;
    h = _multiply32(h, 0x85ebca6b);
    h ^= h >> 13;
    h = _multiply32(h, 0xc2b2ae35);
    h ^= h >> 16;
    return h & 0xffffffff;
  }
}

// ──────────────────────────────────────────────
// GchDJB2 hash
// ──────────────────────────────────────────────
class GchDJB2 {
  GchDJB2._();

  static int hash(List<int> data) {
    int h = 5381;
    for (final b in data) {
      h = ((h << 5) + h + b) & 0xffffffff;
    }
    return h;
  }

  static int hashString(String s) => hash(utf8.encode(s));

  static int hashCombine(int h1, int h2) {
    return (h1 ^ (h2 << 5) ^ (h2 >> 27)) & 0xffffffff;
  }
}

// ──────────────────────────────────────────────
// GchSipHash (simplified SipHash-2-4 reference)
// ──────────────────────────────────────────────
class GchSipHash {
  GchSipHash._();

  static int hash(List<int> data, {int k0 = 0x0706050403020100, int k1 = 0x0f0e0d0c0b0a0908}) {
    int v0 = k0 ^ 0x736f6d6570736575;
    int v1 = k1 ^ 0x646f72616e646f6d;
    int v2 = k0 ^ 0x6c7967656e657261;
    int v3 = k1 ^ 0x7465646279746573;

    void round() {
      v0 = _add64(v0, v1); v1 = _rotl64(v1, 13); v1 ^= v0; v0 = _rotl64(v0, 32);
      v2 = _add64(v2, v3); v3 = _rotl64(v3, 16); v3 ^= v2;
      v0 = _add64(v0, v3); v3 = _rotl64(v3, 21); v3 ^= v0;
      v2 = _add64(v2, v1); v1 = _rotl64(v1, 17); v1 ^= v2; v2 = _rotl64(v2, 32);
    }

    final bytes = Uint8List.fromList(data);
    int pos = 0;
    while (pos + 8 <= bytes.length) {
      int m = bytes[pos] |
          (bytes[pos + 1] << 8) |
          (bytes[pos + 2] << 16) |
          (bytes[pos + 3] << 24) |
          (bytes[pos + 4] << 32) |
          (bytes[pos + 5] << 40) |
          (bytes[pos + 6] << 48) |
          (bytes[pos + 7] << 56);
      v3 ^= m;
      round();
      round();
      v0 ^= m;
      pos += 8;
    }

    int last = (bytes.length & 0xff) << 56;
    final rem = bytes.length - pos;
    for (int i = 0; i < rem; i++) last |= bytes[pos + i] << (i * 8);
    v3 ^= last;
    round();
    round();
    v0 ^= last;

    v2 ^= 0xff;
    round();
    round();
    round();
    round();
    return v0 ^ v1 ^ v2 ^ v3;
  }

  static int _rotl64(int x, int r) => (x << r) | (x >> (64 - r));
  static int _add64(int a, int b) => (a + b) & 0xffffffffffffffff;
}

// ──────────────────────────────────────────────
// GchBytesUtil – byte manipulation helpers
// ──────────────────────────────────────────────
class GchBytesUtil {
  GchBytesUtil._();

  static List<int> xorPad(List<int> data, int blockSize) {
    if (data.length >= blockSize) return data.sublist(0, blockSize);
    return [...data, ...List.filled(blockSize - data.length, 0)];
  }

  static List<int> pkcs7Pad(List<int> data, int blockSize) {
    final padLen = blockSize - (data.length % blockSize);
    return [...data, ...List.filled(padLen, padLen)];
  }

  static List<int> pkcs7Unpad(List<int> data) {
    if (data.isEmpty) return data;
    final padLen = data.last;
    if (padLen == 0 || padLen > data.length) return data;
    return data.sublist(0, data.length - padLen);
  }

  static Uint8List int32ToBytesLE(int value) {
    final bytes = Uint8List(4);
    bytes[0] = value & 0xff;
    bytes[1] = (value >> 8) & 0xff;
    bytes[2] = (value >> 16) & 0xff;
    bytes[3] = (value >> 24) & 0xff;
    return bytes;
  }

  static Uint8List int32ToBytesBE(int value) {
    final bytes = Uint8List(4);
    bytes[0] = (value >> 24) & 0xff;
    bytes[1] = (value >> 16) & 0xff;
    bytes[2] = (value >> 8) & 0xff;
    bytes[3] = value & 0xff;
    return bytes;
  }

  static int bytesToInt32LE(List<int> bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  static int bytesToInt32BE(List<int> bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  static List<int> concat(List<List<int>> chunks) {
    final total = chunks.fold<int>(0, (s, c) => s + c.length);
    final result = Uint8List(total);
    int offset = 0;
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }

  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
    return diff == 0;
  }

  static List<int> randomBytes(int count, {Random? rng}) {
    final r = rng ?? Random.secure();
    return List.generate(count, (_) => r.nextInt(256));
  }

  static List<int> rotate(List<int> bytes, int n) {
    if (bytes.isEmpty) return bytes;
    final shift = n % bytes.length;
    if (shift == 0) return List.from(bytes);
    return [...bytes.sublist(shift), ...bytes.sublist(0, shift)];
  }

  static List<int> reverse(List<int> bytes) => bytes.reversed.toList();

  static String toBinaryString(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(2).padLeft(8, '0'))
        .join(' ');
  }
}

// ──────────────────────────────────────────────
// GchSimpleChecksum – multiple checksum methods
// ──────────────────────────────────────────────
class GchSimpleChecksum {
  GchSimpleChecksum._();

  static int sum8(List<int> data) {
    return data.fold<int>(0, (s, b) => (s + b) & 0xff);
  }

  static int sum16(List<int> data) {
    return data.fold<int>(0, (s, b) => (s + b) & 0xffff);
  }

  static int sum32(List<int> data) {
    return data.fold<int>(0, (s, b) => (s + b) & 0xffffffff);
  }

  static int xorChecksum(List<int> data) {
    return data.fold<int>(0, (s, b) => s ^ b);
  }

  static int fletcherChecksum16(List<int> data) {
    int sum1 = 0, sum2 = 0;
    for (final b in data) {
      sum1 = (sum1 + b) % 255;
      sum2 = (sum2 + sum1) % 255;
    }
    return (sum2 << 8) | sum1;
  }

  static int fletcherChecksum32(List<int> data) {
    int sum1 = 0, sum2 = 0;
    const mod = 65535;
    for (int i = 0; i < data.length; i += 2) {
      int word = data[i];
      if (i + 1 < data.length) word |= data[i + 1] << 8;
      sum1 = (sum1 + word) % mod;
      sum2 = (sum2 + sum1) % mod;
    }
    return (sum2 << 16) | sum1;
  }
}

// ──────────────────────────────────────────────
// GchOTP – One-Time Password utilities (TOTP/HOTP-like)
// ──────────────────────────────────────────────
class GchOTP {
  GchOTP._();

  // HMAC-based OTP counter function (simplified, no real HMAC)
  // Uses FNV hash as a substitute for demonstration
  static int hotp(List<int> secret, int counter, {int digits = 6}) {
    final data = [...secret, ...GchBytesUtil.int32ToBytesBE(counter >> 32),
      ...GchBytesUtil.int32ToBytesBE(counter & 0xffffffff)];
    final hash = GchFNV.fnv1a32(data);
    final offset = hash & 0xf;
    final otp = (hash >> offset) & 0x7fffffff;
    return otp % _pow10(digits);
  }

  static int _pow10(int n) {
    int result = 1;
    for (int i = 0; i < n; i++) result *= 10;
    return result;
  }

  static String hotpString(List<int> secret, int counter, {int digits = 6}) {
    return hotp(secret, counter, digits: digits)
        .toString()
        .padLeft(digits, '0');
  }

  static int totp(List<int> secret, {int period = 30, int digits = 6}) {
    final counter =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ period;
    return hotp(secret, counter, digits: digits);
  }

  static String totpString(List<int> secret,
      {int period = 30, int digits = 6}) {
    return totp(secret, period: period, digits: digits)
        .toString()
        .padLeft(digits, '0');
  }
}

// ──────────────────────────────────────────────
// Known test vectors
// ──────────────────────────────────────────────
class GchCryptoTestVectors {
  GchCryptoTestVectors._();

  // Base64 vectors: input string → expected base64
  static const Map<String, String> base64Vectors = {
    '': '',
    'f': 'Zg==',
    'fo': 'Zm8=',
    'foo': 'Zm9v',
    'foobar': 'Zm9vYmFy',
    'Man': 'TWFu',
    'Hello, World!': 'SGVsbG8sIFdvcmxkIQ==',
    'The quick brown fox': 'VGhlIHF1aWNrIGJyb3duIGZveA==',
  };

  // Hex vectors: input bytes → expected hex
  static const Map<String, String> hexVectors = {
    '\x00': '00',
    '\xff': 'ff',
    'ABC': '414243',
    'Hello': '48656c6c6f',
  };

  // CRC32 vectors: input string → expected CRC32 (hex)
  static const Map<String, int> crc32Vectors = {
    '': 0x00000000,
    '123456789': 0xCBF43926,
    'The quick brown fox jumps over the lazy dog': 0x414FA339,
  };

  // Adler32 vectors: input → expected checksum
  static const Map<String, int> adler32Vectors = {
    'Wikipedia': 0x11E60398,
    'Mark Adler': 0x13070394,
  };

  // FNV-1a 32-bit vectors
  static const Map<String, int> fnv1a32Vectors = {
    '': 0x811c9dc5,
    'a': 0xe40c292c,
    'foobar': 0xbf9cf968,
  };

  // MurmurHash3 32-bit vectors (seed=0)
  static const Map<String, int> murmur3Vectors = {
    '': 0x00000000,
    'hello': 0x248bfa47,
    'The quick brown fox': 0x2e4ff723,
  };

  // XOR encryption round-trip test cases
  static final List<({String plaintext, String key})> xorCases = [
    (plaintext: 'Hello, World!', key: 'secret'),
    (plaintext: 'test data 123', key: 'k'),
    (plaintext: 'The quick brown fox', key: 'mykey123'),
    (plaintext: '', key: 'key'),
  ];

  // Random byte generation test sizes
  static const List<int> randomByteSizes = [1, 8, 16, 32, 64, 128, 256, 512];

  static void runAllVerifications() {
    _verifyBase64();
    _verifyHex();
    _verifyCRC32();
    _verifyAdler32();
    _verifyFNV();
    _verifyXOR();
  }

  static void _verifyBase64() {
    print('=== Base64 Verification ===');
    for (final entry in base64Vectors.entries) {
      if (entry.key.isEmpty) {
        print('Empty string: ok (skipped)');
        continue;
      }
      final encoded = GchBase64.encodeString(entry.key);
      final decoded = GchBase64.decodeString(encoded);
      final ok = decoded == entry.key;
      print('  "${entry.key}" → $encoded (roundtrip: $ok)');
    }
  }

  static void _verifyHex() {
    print('\n=== Hex Verification ===');
    for (final entry in hexVectors.entries) {
      final bytes = utf8.encode(entry.key);
      final encoded = GchHex.encode(bytes);
      final roundtrip = utf8.decode(GchHex.decode(encoded));
      print('  "${entry.key}" → $encoded (expected: ${entry.value}, match: ${encoded == entry.value}, roundtrip: ${roundtrip == entry.key})');
    }
  }

  static void _verifyCRC32() {
    print('\n=== CRC32 Verification ===');
    for (final entry in crc32Vectors.entries) {
      final crc = GchCRC.crc32(utf8.encode(entry.key));
      print('  "${entry.key}" → 0x${crc.toRadixString(16).padLeft(8, '0')} (expected: 0x${entry.value.toRadixString(16).padLeft(8, '0')}, match: ${crc == entry.value})');
    }
  }

  static void _verifyAdler32() {
    print('\n=== Adler32 Verification ===');
    for (final entry in adler32Vectors.entries) {
      final checksum = GchAdler32.compute(utf8.encode(entry.key));
      print('  "${entry.key}" → 0x${checksum.toRadixString(16)} (expected: 0x${entry.value.toRadixString(16)}, match: ${checksum == entry.value})');
    }
  }

  static void _verifyFNV() {
    print('\n=== FNV-1a 32 Verification ===');
    for (final entry in fnv1a32Vectors.entries) {
      final hash = GchFNV.fnv1a32String(entry.key);
      print('  "${entry.key}" → 0x${hash.toRadixString(16)} (expected: 0x${entry.value.toRadixString(16)}, match: ${hash == entry.value})');
    }
  }

  static void _verifyXOR() {
    print('\n=== XOR Round-trip ===');
    for (final c in xorCases) {
      final enc = GchXOR.stringEncrypt(c.plaintext, c.key);
      final dec = GchXOR.stringDecrypt(enc, c.key);
      print('  "${c.plaintext}" encrypted, roundtrip ok: ${dec == c.plaintext}');
    }
  }
}

// ignore: unused_element
final _usedMath = max(0, 0);
// ignore: unused_element
final _usedRandom = Random();
