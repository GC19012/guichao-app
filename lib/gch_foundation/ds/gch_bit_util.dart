// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:typed_data';
import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// GchBitUtil – bit manipulation utilities
// ─────────────────────────────────────────────────────────────────────────────
class GchBitUtil {
  GchBitUtil._();

  // countOnes – population count (number of set bits)
  static int countOnes(int n) {
    int count = 0;
    int x = n;
    while (x != 0) {
      x &= (x - 1);
      count++;
    }
    return count;
  }

  // countZeros – for a given bit width
  static int countZeros(int n, {int width = 32}) {
    return width - countOnes(n & ((1 << width) - 1));
  }

  // highestSetBit – position of highest set bit (0-indexed from right)
  static int highestSetBit(int n) {
    if (n <= 0) return -1;
    int pos = 0;
    int x = n;
    while (x > 1) {
      x >>= 1;
      pos++;
    }
    return pos;
  }

  // lowestSetBit – position of lowest set bit (0-indexed from right)
  static int lowestSetBit(int n) {
    if (n == 0) return -1;
    int pos = 0;
    int x = n;
    while ((x & 1) == 0) {
      x >>= 1;
      pos++;
    }
    return pos;
  }

  // isPowerOfTwo
  static bool isPowerOfTwo(int n) => n > 0 && (n & (n - 1)) == 0;

  // nextPowerOfTwo – smallest power of two >= n
  static int nextPowerOfTwo(int n) {
    if (n <= 1) return 1;
    int x = n - 1;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
  }

  // reverseBits – reverse the lowest [width] bits
  static int reverseBits(int n, {int width = 32}) {
    int result = 0;
    int x = n;
    for (int i = 0; i < width; i++) {
      result = (result << 1) | (x & 1);
      x >>= 1;
    }
    return result;
  }

  // rotateLeft – circular left shift
  static int rotateLeft(int n, int k, {int width = 32}) {
    final mask = (1 << width) - 1;
    k = k % width;
    return ((n << k) | (n >> (width - k))) & mask;
  }

  // rotateRight – circular right shift
  static int rotateRight(int n, int k, {int width = 32}) {
    final mask = (1 << width) - 1;
    k = k % width;
    return ((n >> k) | (n << (width - k))) & mask;
  }

  // parity – returns 1 if number of set bits is odd, else 0
  static int parity(int n) {
    int x = n;
    x ^= x >> 16;
    x ^= x >> 8;
    x ^= x >> 4;
    x ^= x >> 2;
    x ^= x >> 1;
    return x & 1;
  }

  // swapBits – swap bits at positions i and j
  static int swapBits(int n, int i, int j) {
    if (((n >> i) & 1) != ((n >> j) & 1)) {
      n ^= (1 << i) | (1 << j);
    }
    return n;
  }

  // setBit – set bit at position pos to 1
  static int setBit(int n, int pos) => n | (1 << pos);

  // clearBit – clear bit at position pos (set to 0)
  static int clearBit(int n, int pos) => n & ~(1 << pos);

  // toggleBit – flip bit at position pos
  static int toggleBit(int n, int pos) => n ^ (1 << pos);

  // testBit – returns true if bit at position pos is set
  static bool testBit(int n, int pos) => (n >> pos) & 1 == 1;

  // grayCodingEncode – binary to Gray code
  static int grayCodingEncode(int n) => n ^ (n >> 1);

  // grayCodingDecode – Gray code to binary
  static int grayCodingDecode(int gray) {
    int num = gray;
    int mask = gray >> 1;
    while (mask != 0) {
      num ^= mask;
      mask >>= 1;
    }
    return num;
  }

  // intToBytes – convert int to Uint8List
  static Uint8List intToBytes(int n,
      {int byteCount = 4, Endian endian = Endian.big}) {
    final buf = ByteData(byteCount);
    if (byteCount == 1) {
      buf.setUint8(0, n & 0xFF);
    } else if (byteCount == 2) {
      buf.setUint16(0, n & 0xFFFF, endian);
    } else if (byteCount == 4) {
      buf.setUint32(0, n & 0xFFFFFFFF, endian);
    } else if (byteCount == 8) {
      buf.setUint64(0, n, endian);
    } else {
      // generic fallback
      int val = n;
      for (int i = byteCount - 1; i >= 0; i--) {
        buf.setUint8(endian == Endian.big ? i : byteCount - 1 - i, val & 0xFF);
        val >>= 8;
      }
    }
    return buf.buffer.asUint8List();
  }

  // bytesToInt – convert Uint8List to int
  static int bytesToInt(Uint8List bytes, {Endian endian = Endian.big}) {
    final buf = ByteData.sublistView(bytes);
    if (bytes.length == 1) return buf.getUint8(0);
    if (bytes.length == 2) return buf.getUint16(0, endian);
    if (bytes.length == 4) return buf.getUint32(0, endian);
    if (bytes.length == 8) return buf.getUint64(0, endian);
    int result = 0;
    for (int i = 0; i < bytes.length; i++) {
      final b = endian == Endian.big
          ? bytes[i]
          : bytes[bytes.length - 1 - i];
      result = (result << 8) | b;
    }
    return result;
  }

  // xorBytes – element-wise XOR of two Uint8List (min length is used)
  static Uint8List xorBytes(Uint8List a, Uint8List b) {
    final len = a.length < b.length ? a.length : b.length;
    final result = Uint8List(len);
    for (int i = 0; i < len; i++) {
      result[i] = a[i] ^ b[i];
    }
    return result;
  }

  // hammingWeight – alias for countOnes
  static int hammingWeight(int n) => countOnes(n);

  // bitLength – minimum number of bits to represent n
  static int bitLength(int n) {
    if (n == 0) return 1;
    return highestSetBit(n.abs()) + 1;
  }

  // extractBits – extract bits from [start] to [end] (inclusive, 0-indexed)
  static int extractBits(int n, int start, int end) {
    final width = end - start + 1;
    final mask = (1 << width) - 1;
    return (n >> start) & mask;
  }

  // insertBits – insert [value] into [n] at bit positions [start]..[start+width-1]
  static int insertBits(int n, int value, int start, int width) {
    final mask = ((1 << width) - 1) << start;
    return (n & ~mask) | ((value << start) & mask);
  }

  // toBinaryString – binary representation with optional padding
  static String toBinaryString(int n, {int width = 0}) {
    String bin = n.toRadixString(2);
    if (width > bin.length) bin = bin.padLeft(width, '0');
    return bin;
  }

  // fromBinaryString
  static int fromBinaryString(String s) => int.parse(s, radix: 2);

  // toHexString
  static String toHexString(int n, {bool prefix = true}) {
    final hex = n.toRadixString(16).toUpperCase();
    return prefix ? '0x$hex' : hex;
  }

  // multiplyWithoutOperator – using bit shifts
  static int multiplyWithoutOperator(int a, int b) {
    int result = 0;
    int x = a.abs(), y = b.abs();
    while (y > 0) {
      if (y & 1 == 1) result += x;
      x <<= 1;
      y >>= 1;
    }
    return (a < 0) != (b < 0) ? -result : result;
  }

  // divideWithoutOperator – integer division using bit shifts
  static int divideWithoutOperator(int dividend, int divisor) {
    if (divisor == 0) throw ArgumentError('Division by zero');
    int result = 0;
    int a = dividend.abs(), b = divisor.abs();
    for (int i = 31; i >= 0; i--) {
      if ((a >> i) >= b) {
        result += 1 << i;
        a -= b << i;
      }
    }
    return (dividend < 0) != (divisor < 0) ? -result : result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GchBloomFilter – probabilistic membership data structure
// ─────────────────────────────────────────────────────────────────────────────
class GchBloomFilter {
  final Uint8List _bits;
  final int _numHashFunctions;
  final int _size;
  int _addedCount = 0;

  GchBloomFilter._(this._bits, this._numHashFunctions, this._size);

  factory GchBloomFilter(int expectedElements, double falsePositiveRate) {
    if (expectedElements <= 0) throw ArgumentError('Expected elements must be > 0');
    if (falsePositiveRate <= 0 || falsePositiveRate >= 1) {
      throw ArgumentError('False positive rate must be in (0, 1)');
    }
    // Optimal bit array size: m = -n * ln(p) / (ln(2)^2)
    final ln2 = 0.6931471805599453;
    final m = (-expectedElements * _log(falsePositiveRate) / (ln2 * ln2)).ceil();
    // Optimal number of hash functions: k = (m/n) * ln(2)
    final k = ((m / expectedElements) * ln2).ceil().clamp(1, 20);
    final byteCount = (m + 7) ~/ 8;
    return GchBloomFilter._(Uint8List(byteCount), k, m);
  }

  static double _log(double x) {
    // Natural log approximation using series
    // Use dart:math log
    double result = 0;
    double y = (x - 1) / (x + 1);
    double term = y;
    for (int i = 1; i < 100; i += 2) {
      result += term / i;
      term *= y * y;
    }
    return 2 * result;
  }

  int _hash1(String item) {
    int hash = 5381;
    for (final ch in item.codeUnits) {
      hash = ((hash << 5) + hash) ^ ch;
    }
    return hash.abs() % _size;
  }

  int _hash2(String item) {
    int hash = 0;
    for (final ch in item.codeUnits) {
      hash = (hash << 6) + (hash << 16) - hash + ch;
    }
    return hash.abs() % _size;
  }

  int _hash3(String item) {
    int hash = 2166136261;
    for (final ch in item.codeUnits) {
      hash ^= ch;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash % _size;
  }

  // Generate k hash positions for a given item
  List<int> _hashPositions(String item) {
    final h1 = _hash1(item);
    final h2 = _hash2(item);
    final h3 = _hash3(item);
    final positions = <int>[];
    for (int i = 0; i < _numHashFunctions; i++) {
      positions.add((h1 + i * h2 + i * i * h3) % _size);
    }
    return positions;
  }

  void _setBitAt(int pos) {
    final byteIndex = pos ~/ 8;
    final bitIndex = pos % 8;
    _bits[byteIndex] |= (1 << bitIndex);
  }

  bool _getBitAt(int pos) {
    final byteIndex = pos ~/ 8;
    final bitIndex = pos % 8;
    return (_bits[byteIndex] & (1 << bitIndex)) != 0;
  }

  void add(String item) {
    for (final pos in _hashPositions(item)) {
      _setBitAt(pos);
    }
    _addedCount++;
  }

  bool contains(String item) {
    for (final pos in _hashPositions(item)) {
      if (!_getBitAt(pos)) return false;
    }
    return true;
  }

  double get estimatedFalsePositiveRate {
    if (_addedCount == 0) return 0.0;
    final ln2 = 0.6931471805599453;
    final exponent = -_numHashFunctions * _addedCount / _size;
    // approximate e^x for negative x
    final base = 1 - _exp(exponent);
    return _pow(base, _numHashFunctions);
  }

  static double _exp(double x) {
    // Taylor series for e^x
    double result = 1, term = 1;
    for (int i = 1; i <= 50; i++) {
      term *= x / i;
      result += term;
      if (term.abs() < 1e-15) break;
    }
    return result;
  }

  static double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) result *= base;
    return result;
  }

  int get bitCount {
    int count = 0;
    for (final byte in _bits) {
      int b = byte;
      while (b != 0) {
        b &= b - 1;
        count++;
      }
    }
    return count;
  }

  int get size => _size;
  int get addedCount => _addedCount;
  int get numHashFunctions => _numHashFunctions;

  void reset() {
    _bits.fillRange(0, _bits.length, 0);
    _addedCount = 0;
  }

  @override
  String toString() =>
      'GchBloomFilter(size=$_size, k=$_numHashFunctions, added=$_addedCount, '
      'estimatedFPR=${estimatedFalsePositiveRate.toStringAsFixed(4)})';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchCRC – cyclic redundancy check utilities
// ─────────────────────────────────────────────────────────────────────────────
class GchCRC {
  GchCRC._();

  // CRC-8 lookup table (polynomial 0x07)
  static final List<int> _crc8Table = _buildCRC8Table();

  static List<int> _buildCRC8Table() {
    const poly = 0x07;
    final table = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      int crc = i;
      for (int j = 0; j < 8; j++) {
        if (crc & 0x80 != 0) {
          crc = ((crc << 1) ^ poly) & 0xFF;
        } else {
          crc = (crc << 1) & 0xFF;
        }
      }
      table[i] = crc;
    }
    return table;
  }

  static int crc8(Uint8List data) {
    int crc = 0;
    for (final byte in data) {
      crc = _crc8Table[(crc ^ byte) & 0xFF];
    }
    return crc;
  }

  // CRC-16 lookup table (polynomial 0x8005, reflected)
  static final List<int> _crc16Table = _buildCRC16Table();

  static List<int> _buildCRC16Table() {
    const poly = 0x8005;
    final table = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      int crc = i << 8;
      for (int j = 0; j < 8; j++) {
        if (crc & 0x8000 != 0) {
          crc = ((crc << 1) ^ poly) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
      table[i] = crc;
    }
    return table;
  }

  static int crc16(Uint8List data) {
    int crc = 0;
    for (final byte in data) {
      crc = ((crc << 8) ^ _crc16Table[((crc >> 8) ^ byte) & 0xFF]) & 0xFFFF;
    }
    return crc;
  }

  // CRC-32 lookup table (IEEE 802.3 polynomial 0xEDB88320, reflected)
  static final List<int> _crc32Table = _buildCRC32Table();

  static List<int> _buildCRC32Table() {
    const poly = 0xEDB88320;
    final table = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      int crc = i;
      for (int j = 0; j < 8; j++) {
        if (crc & 1 != 0) {
          crc = (crc >> 1) ^ poly;
        } else {
          crc >>= 1;
        }
      }
      table[i] = crc;
    }
    return table;
  }

  static int crc32(Uint8List data) {
    int crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc = (crc >> 8) ^ _crc32Table[(crc ^ byte) & 0xFF];
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }

  // Convenience: compute CRC-32 of a UTF-8 string
  static int crc32String(String s) {
    return crc32(Uint8List.fromList(utf8.encode(s)));
  }

  // Convenience: compute CRC-16 of a UTF-8 string
  static int crc16String(String s) {
    return crc16(Uint8List.fromList(utf8.encode(s)));
  }

  // Verify CRC-32 of data appended with its CRC
  static bool verifyCRC32(Uint8List data, int expectedCRC) {
    return crc32(data) == expectedCRC;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preset test data constants
// ─────────────────────────────────────────────────────────────────────────────
const List<int> kBitTestInts = [
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
  15, 16, 31, 32, 63, 64, 127, 128, 255, 256,
  511, 512, 1023, 1024, 2047, 2048, 4095, 4096, 8191, 8192,
  65535, 65536, 131071, 131072, 262143, 262144, 524287, 524288,
  1048575, 1048576, 2147483647, -1, -2, -128, -256, -1024,
];

const List<int> kPowerOfTwoTests = [
  1, 2, 4, 8, 16, 32, 64, 128, 256, 512,
  1024, 2048, 4096, 8192, 16384, 32768, 65536,
  131072, 262144, 524288, 1048576, 2097152,
];

const List<String> kBloomTestWords = [
  'hello', 'world', 'dart', 'flutter', 'programming',
  'algorithm', 'data', 'structure', 'binary', 'hash',
  'bloom', 'filter', 'crc', 'checksum', 'parity',
  'bit', 'byte', 'word', 'integer', 'float',
  'alpha', 'beta', 'gamma', 'delta', 'epsilon',
  'zeta', 'eta', 'theta', 'iota', 'kappa',
];

const List<int> kGrayCodeTests = [
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
  10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
];

// ─────────────────────────────────────────────────────────────────────────────
// GchBitArray – fixed-size bit array backed by Uint8List
// ─────────────────────────────────────────────────────────────────────────────
class GchBitArray {
  final Uint8List _data;
  final int _length;

  GchBitArray(int length)
      : _length = length,
        _data = Uint8List((length + 7) ~/ 8);

  GchBitArray.fromBytes(Uint8List bytes, int length)
      : _length = length,
        _data = Uint8List.fromList(bytes);

  int get length => _length;

  bool getBit(int index) {
    _rangeCheck(index);
    return (_data[index ~/ 8] & (1 << (index % 8))) != 0;
  }

  void setBitTrue(int index) {
    _rangeCheck(index);
    _data[index ~/ 8] |= (1 << (index % 8));
  }

  void setBitFalse(int index) {
    _rangeCheck(index);
    _data[index ~/ 8] &= ~(1 << (index % 8));
  }

  void flipBit(int index) {
    _rangeCheck(index);
    _data[index ~/ 8] ^= (1 << (index % 8));
  }

  void setAll(bool value) {
    final fill = value ? 0xFF : 0x00;
    _data.fillRange(0, _data.length, fill);
  }

  // AND, OR, XOR operations with another bit array
  GchBitArray and(GchBitArray other) {
    if (_length != other._length) throw ArgumentError('Length mismatch');
    final result = GchBitArray(_length);
    for (int i = 0; i < _data.length; i++) {
      result._data[i] = _data[i] & other._data[i];
    }
    return result;
  }

  GchBitArray or(GchBitArray other) {
    if (_length != other._length) throw ArgumentError('Length mismatch');
    final result = GchBitArray(_length);
    for (int i = 0; i < _data.length; i++) {
      result._data[i] = _data[i] | other._data[i];
    }
    return result;
  }

  GchBitArray xor(GchBitArray other) {
    if (_length != other._length) throw ArgumentError('Length mismatch');
    final result = GchBitArray(_length);
    for (int i = 0; i < _data.length; i++) {
      result._data[i] = _data[i] ^ other._data[i];
    }
    return result;
  }

  GchBitArray not() {
    final result = GchBitArray(_length);
    for (int i = 0; i < _data.length; i++) {
      result._data[i] = (~_data[i]) & 0xFF;
    }
    return result;
  }

  // count of set bits
  int get popCount {
    int count = 0;
    for (final byte in _data) {
      int b = byte;
      while (b != 0) {
        b &= b - 1;
        count++;
      }
    }
    return count;
  }

  // find index of first set bit
  int firstSet() {
    for (int i = 0; i < _length; i++) {
      if (getBit(i)) return i;
    }
    return -1;
  }

  // find index of first clear bit
  int firstClear() {
    for (int i = 0; i < _length; i++) {
      if (!getBit(i)) return i;
    }
    return -1;
  }

  // shift left by k positions
  GchBitArray shiftLeft(int k) {
    final result = GchBitArray(_length);
    for (int i = k; i < _length; i++) {
      if (getBit(i - k)) result.setBitTrue(i);
    }
    return result;
  }

  // shift right by k positions
  GchBitArray shiftRight(int k) {
    final result = GchBitArray(_length);
    for (int i = 0; i < _length - k; i++) {
      if (getBit(i + k)) result.setBitTrue(i);
    }
    return result;
  }

  List<bool> toList() {
    return List.generate(_length, (i) => getBit(i));
  }

  Uint8List toBytes() => Uint8List.fromList(_data);

  String toBinaryString() {
    final sb = StringBuffer();
    for (int i = 0; i < _length; i++) {
      sb.write(getBit(i) ? '1' : '0');
    }
    return sb.toString();
  }

  void _rangeCheck(int index) {
    if (index < 0 || index >= _length) {
      throw RangeError.index(index, this, 'index', null, _length);
    }
  }

  @override
  String toString() => 'GchBitArray(length=$_length, popCount=$popCount)';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchHammingCode – Hamming error correction code utilities
// ─────────────────────────────────────────────────────────────────────────────
class GchHammingCode {
  GchHammingCode._();

  /// Encode data bits with Hamming parity bits (Hamming(7,4) style).
  /// Returns the encoded bits as a list (parity bits inserted at power-of-2 positions).
  static List<int> encode(List<int> dataBits) {
    // Determine number of parity bits needed
    int r = 0;
    while ((1 << r) < dataBits.length + r + 1) r++;
    final n = dataBits.length + r;
    final encoded = List<int>.filled(n, 0);

    // Insert data bits at non-power-of-2 positions
    int dataIdx = 0;
    for (int i = 1; i <= n; i++) {
      if (!GchBitUtil.isPowerOfTwo(i)) {
        encoded[i - 1] = dataIdx < dataBits.length ? dataBits[dataIdx++] : 0;
      }
    }

    // Compute parity bits
    for (int i = 0; i < r; i++) {
      final parityPos = (1 << i);
      int parity = 0;
      for (int j = parityPos; j <= n; j++) {
        if ((j & parityPos) != 0) parity ^= encoded[j - 1];
      }
      encoded[parityPos - 1] = parity;
    }
    return encoded;
  }

  /// Detect and correct a single-bit error in Hamming-encoded bits.
  /// Returns (correctedBits, errorPosition) where errorPosition == 0 means no error.
  static ({List<int> corrected, int errorPosition}) decode(List<int> encoded) {
    final n = encoded.length;
    int errorPos = 0;
    int r = 0;
    while ((1 << r) <= n) {
      final parityPos = (1 << r);
      int parity = 0;
      for (int j = parityPos; j <= n; j++) {
        if ((j & parityPos) != 0) parity ^= encoded[j - 1];
      }
      if (parity != 0) errorPos += parityPos;
      r++;
    }
    final corrected = List<int>.from(encoded);
    if (errorPos > 0 && errorPos <= n) {
      corrected[errorPos - 1] ^= 1;
    }
    return (corrected: corrected, errorPosition: errorPos);
  }

  /// Extract data bits from Hamming-encoded bits.
  static List<int> extractData(List<int> encoded) {
    final result = <int>[];
    for (int i = 1; i <= encoded.length; i++) {
      if (!GchBitUtil.isPowerOfTwo(i)) result.add(encoded[i - 1]);
    }
    return result;
  }
}
