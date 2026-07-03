// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';
import 'dart:typed_data';

// ─────────────────────────────────────────────────────────────────────────────
// GchPrime – number theory utilities
// ─────────────────────────────────────────────────────────────────────────────
class GchPrime {
  GchPrime._();

  // isPrime – trial division
  static bool isPrime(int n) {
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;
    if (n == 3) return true;
    if (n % 3 == 0) return false;
    for (int i = 5; i * i <= n; i += 6) {
      if (n % i == 0 || n % (i + 2) == 0) return false;
    }
    return true;
  }

  // nthPrime – returns the n-th prime (1-indexed)
  static int nthPrime(int n) {
    if (n <= 0) throw ArgumentError('n must be positive');
    int count = 0, candidate = 1;
    while (count < n) {
      candidate++;
      if (isPrime(candidate)) count++;
    }
    return candidate;
  }

  // primesBelow – Sieve of Eratosthenes
  static List<int> primesBelow(int limit) {
    if (limit < 2) return [];
    final sieve = List<bool>.filled(limit, true);
    sieve[0] = false;
    sieve[1] = false;
    for (int i = 2; i * i < limit; i++) {
      if (sieve[i]) {
        for (int j = i * i; j < limit; j += i) {
          sieve[j] = false;
        }
      }
    }
    final primes = <int>[];
    for (int i = 2; i < limit; i++) {
      if (sieve[i]) primes.add(i);
    }
    return primes;
  }

  // primeFactors – returns prime factorization
  static List<int> primeFactors(int n) {
    final factors = <int>[];
    int num = n;
    for (int i = 2; i * i <= num; i++) {
      while (num % i == 0) {
        factors.add(i);
        num ~/= i;
      }
    }
    if (num > 1) factors.add(num);
    return factors;
  }

  // gcd – Euclidean algorithm
  static int gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  // lcm – least common multiple
  static int lcm(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return (a * b).abs() ~/ gcd(a, b);
  }

  // extendedGcd – returns {gcd, x, y} where a*x + b*y = gcd(a,b)
  static ({int g, int x, int y}) extendedGcd(int a, int b) {
    if (b == 0) return (g: a, x: 1, y: 0);
    final sub = extendedGcd(b, a % b);
    return (g: sub.g, x: sub.y, y: sub.x - (a ~/ b) * sub.y);
  }

  // modPow – fast modular exponentiation
  static int modPow(int base, int exp, int mod) {
    if (mod == 1) return 0;
    int result = 1;
    int b = base % mod;
    int e = exp;
    while (e > 0) {
      if (e % 2 == 1) result = (result * b) % mod;
      e ~/= 2;
      b = (b * b) % mod;
    }
    return result;
  }

  // modInverse – modular inverse using Fermat's little theorem (mod must be prime)
  static int modInverse(int a, int mod) {
    return modPow(a, mod - 2, mod);
  }

  // phi – Euler's totient function
  static int phi(int n) {
    int result = n;
    int num = n;
    for (int p = 2; p * p <= num; p++) {
      if (num % p == 0) {
        while (num % p == 0) num ~/= p;
        result -= result ~/ p;
      }
    }
    if (num > 1) result -= result ~/ num;
    return result;
  }

  // isCoprime
  static bool isCoprime(int a, int b) => gcd(a, b) == 1;

  // mobiusSieve – returns Mobius function values up to limit
  static List<int> mobiusSieve(int limit) {
    final mu = List<int>.filled(limit + 1, 1);
    final primes = <int>[];
    final visited = List<bool>.filled(limit + 1, false);
    for (int i = 2; i <= limit; i++) {
      if (!visited[i]) {
        primes.add(i);
        mu[i] = -1;
      }
      for (int j = 0; j < primes.length && i * primes[j] <= limit; j++) {
        visited[i * primes[j]] = true;
        if (i % primes[j] == 0) {
          mu[i * primes[j]] = 0;
          break;
        }
        mu[i * primes[j]] = -mu[i];
      }
    }
    return mu;
  }

  // isSquareFree – number has no squared prime factor
  static bool isSquareFree(int n) {
    for (final p in primeFactors(n)) {
      if (n % (p * p) == 0) return false;
    }
    return true;
  }

  // sumOfDivisors
  static int sumOfDivisors(int n) {
    int total = 0;
    for (int i = 1; i * i <= n; i++) {
      if (n % i == 0) {
        total += i;
        if (i != n ~/ i) total += n ~/ i;
      }
    }
    return total;
  }

  // isPerfect – sum of proper divisors equals n
  static bool isPerfect(int n) => n > 1 && sumOfDivisors(n) - n == n;
}

// ─────────────────────────────────────────────────────────────────────────────
// GchStatistics – descriptive and inferential statistics
// ─────────────────────────────────────────────────────────────────────────────
class GchStatistics {
  GchStatistics._();

  static double mean(List<double> data) {
    if (data.isEmpty) throw ArgumentError('Empty data');
    return data.reduce((a, b) => a + b) / data.length;
  }

  static double median(List<double> data) {
    if (data.isEmpty) throw ArgumentError('Empty data');
    final sorted = List<double>.from(data)..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  static List<double> mode(List<double> data) {
    if (data.isEmpty) return [];
    final freq = <double, int>{};
    for (final x in data) freq[x] = (freq[x] ?? 0) + 1;
    final maxFreq = freq.values.reduce(max);
    return freq.entries
        .where((e) => e.value == maxFreq)
        .map((e) => e.key)
        .toList();
  }

  static double variance(List<double> data) {
    if (data.length < 2) throw ArgumentError('Need at least 2 data points');
    final m = mean(data);
    return data.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) /
        (data.length - 1);
  }

  static double stdDev(List<double> data) => sqrt(variance(data));

  static double percentile(List<double> data, double p) {
    if (data.isEmpty) throw ArgumentError('Empty data');
    final sorted = List<double>.from(data)..sort();
    final index = (p / 100.0) * (sorted.length - 1);
    final lower = index.floor();
    final upper = index.ceil();
    if (lower == upper) return sorted[lower];
    return sorted[lower] + (sorted[upper] - sorted[lower]) * (index - lower);
  }

  static ({double q1, double q2, double q3}) quartiles(List<double> data) {
    return (
      q1: percentile(data, 25),
      q2: percentile(data, 50),
      q3: percentile(data, 75),
    );
  }

  static double minVal(List<double> data) {
    if (data.isEmpty) throw ArgumentError('Empty data');
    return data.reduce(min);
  }

  static double maxVal(List<double> data) {
    if (data.isEmpty) throw ArgumentError('Empty data');
    return data.reduce(max);
  }

  static double range(List<double> data) => maxVal(data) - minVal(data);

  static double sum(List<double> data) => data.reduce((a, b) => a + b);

  // Pearson correlation coefficient
  static double correlation(List<double> a, List<double> b) {
    if (a.length != b.length) throw ArgumentError('Lists must be equal length');
    final n = a.length;
    final ma = mean(a), mb = mean(b);
    double num = 0, da = 0, db = 0;
    for (int i = 0; i < n; i++) {
      final ai = a[i] - ma, bi = b[i] - mb;
      num += ai * bi;
      da += ai * ai;
      db += bi * bi;
    }
    if (da == 0 || db == 0) return 0;
    return num / sqrt(da * db);
  }

  // Z-score normalization
  static List<double> normalize(List<double> data) {
    final m = mean(data);
    final sd = stdDev(data);
    if (sd == 0) return List<double>.filled(data.length, 0);
    return data.map((x) => (x - m) / sd).toList();
  }

  // Simple linear regression
  static ({double slope, double intercept}) linearRegression(
      List<double> x, List<double> y) {
    if (x.length != y.length) throw ArgumentError('Lists must be equal length');
    final n = x.length;
    final mx = mean(x), my = mean(y);
    double num = 0, denom = 0;
    for (int i = 0; i < n; i++) {
      num += (x[i] - mx) * (y[i] - my);
      denom += (x[i] - mx) * (x[i] - mx);
    }
    final slope = denom == 0 ? 0.0 : num / denom;
    final intercept = my - slope * mx;
    return (slope: slope, intercept: intercept);
  }

  // Moving average
  static List<double> movingAverage(List<double> data, int windowSize) {
    if (windowSize <= 0 || windowSize > data.length) {
      throw ArgumentError('Invalid window size');
    }
    final result = <double>[];
    double windowSum = 0;
    for (int i = 0; i < windowSize; i++) windowSum += data[i];
    result.add(windowSum / windowSize);
    for (int i = windowSize; i < data.length; i++) {
      windowSum += data[i] - data[i - windowSize];
      result.add(windowSum / windowSize);
    }
    return result;
  }

  // Coefficient of variation (relative stddev)
  static double coefficientOfVariation(List<double> data) {
    final m = mean(data);
    if (m == 0) throw StateError('Mean is zero, CV undefined');
    return stdDev(data) / m.abs();
  }

  // Inter-quartile range
  static double iqr(List<double> data) {
    final q = quartiles(data);
    return q.q3 - q.q1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GchMatrix – dense 2-D matrix
// ─────────────────────────────────────────────────────────────────────────────
class GchMatrix {
  final int rows;
  final int cols;
  final List<List<double>> _data;

  GchMatrix._(this.rows, this.cols, this._data);

  factory GchMatrix.fromList(List<List<double>> data) {
    if (data.isEmpty) throw ArgumentError('Empty data');
    final rows = data.length;
    final cols = data[0].length;
    for (final row in data) {
      if (row.length != cols) throw ArgumentError('Jagged rows not allowed');
    }
    return GchMatrix._(rows, cols,
        data.map((r) => List<double>.from(r)).toList());
  }

  factory GchMatrix.identity(int n) {
    final data = List.generate(
        n, (i) => List<double>.generate(n, (j) => i == j ? 1.0 : 0.0));
    return GchMatrix._(n, n, data);
  }

  factory GchMatrix.zeros(int r, int c) {
    final data = List.generate(r, (_) => List<double>.filled(c, 0.0));
    return GchMatrix._(r, c, data);
  }

  factory GchMatrix.ones(int r, int c) {
    final data = List.generate(r, (_) => List<double>.filled(c, 1.0));
    return GchMatrix._(r, c, data);
  }

  double get(int r, int c) => _data[r][c];

  void set(int r, int c, double val) => _data[r][c] = val;

  bool get isSquare => rows == cols;

  double get trace {
    if (!isSquare) throw StateError('Trace only defined for square matrices');
    double t = 0;
    for (int i = 0; i < rows; i++) t += _data[i][i];
    return t;
  }

  GchMatrix operator +(GchMatrix other) {
    if (rows != other.rows || cols != other.cols) {
      throw ArgumentError('Matrix dimensions mismatch for addition');
    }
    final result = GchMatrix.zeros(rows, cols);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        result._data[i][j] = _data[i][j] + other._data[i][j];
      }
    }
    return result;
  }

  GchMatrix operator -(GchMatrix other) {
    if (rows != other.rows || cols != other.cols) {
      throw ArgumentError('Matrix dimensions mismatch for subtraction');
    }
    final result = GchMatrix.zeros(rows, cols);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        result._data[i][j] = _data[i][j] - other._data[i][j];
      }
    }
    return result;
  }

  GchMatrix operator *(GchMatrix other) {
    if (cols != other.rows) {
      throw ArgumentError('Matrix dimensions incompatible for multiplication');
    }
    final result = GchMatrix.zeros(rows, other.cols);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < other.cols; j++) {
        double sum = 0;
        for (int k = 0; k < cols; k++) {
          sum += _data[i][k] * other._data[k][j];
        }
        result._data[i][j] = sum;
      }
    }
    return result;
  }

  GchMatrix transpose() {
    final result = GchMatrix.zeros(cols, rows);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        result._data[j][i] = _data[i][j];
      }
    }
    return result;
  }

  // determinant using LU decomposition (naive recursive for clarity)
  double determinant() {
    if (!isSquare) throw StateError('Determinant requires square matrix');
    return _det(_data.map((r) => List<double>.from(r)).toList(), rows);
  }

  static double _det(List<List<double>> m, int n) {
    if (n == 1) return m[0][0];
    if (n == 2) return m[0][0] * m[1][1] - m[0][1] * m[1][0];
    double result = 0;
    for (int col = 0; col < n; col++) {
      final sub = <List<double>>[];
      for (int i = 1; i < n; i++) {
        final row = <double>[];
        for (int j = 0; j < n; j++) {
          if (j != col) row.add(m[i][j]);
        }
        sub.add(row);
      }
      final sign = col % 2 == 0 ? 1 : -1;
      result += sign * m[0][col] * _det(sub, n - 1);
    }
    return result;
  }

  // scale by scalar
  GchMatrix scale(double factor) {
    final result = GchMatrix.zeros(rows, cols);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        result._data[i][j] = _data[i][j] * factor;
      }
    }
    return result;
  }

  // Frobenius norm
  double get frobeniusNorm {
    double sum = 0;
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        sum += _data[i][j] * _data[i][j];
      }
    }
    return sqrt(sum);
  }

  List<List<double>> toList() =>
      _data.map((r) => List<double>.from(r)).toList();

  @override
  String toString() {
    final sb = StringBuffer('GchMatrix(${rows}x$cols):\n');
    for (final row in _data) {
      sb.writeln('  ${row.map((v) => v.toStringAsFixed(2)).join('  ')}');
    }
    return sb.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preset constants
// ─────────────────────────────────────────────────────────────────────────────
const List<double> kMathDoubles50 = [
  1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
  11.5, 12.5, 13.5, 14.5, 15.5, 16.5, 17.5, 18.5, 19.5, 20.5,
  21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0, 30.0,
  31.7, 32.7, 33.7, 34.7, 35.7, 36.7, 37.7, 38.7, 39.7, 40.7,
  41.3, 42.3, 43.3, 44.3, 45.3, 46.3, 47.3, 48.3, 49.3, 50.3,
];

const List<double> kCorrelationX = [
  1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
  11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0,
];

const List<double> kCorrelationY = [
  2.1, 3.9, 6.2, 8.0, 9.8, 12.1, 14.0, 16.2, 18.0, 19.9,
  22.1, 24.0, 25.9, 28.1, 30.0, 32.2, 33.9, 36.1, 38.0, 40.0,
];

const List<int> kPrimeTestNumbers = [
  2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 97, 98, 99,
  100, 101, 199, 200, 211, 997, 998, 999, 1000, 1009,
];

const List<int> kNumberTheoryTests = [
  12, 18, 36, 60, 100, 120, 360, 720, 1024, 2048,
  1000003, 999983, 524287, 131071, 8191,
];

const List<double> kRegressionX = [
  0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0,
  10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0,
];

const List<double> kRegressionY = [
  2.0, 4.1, 5.9, 8.2, 10.0, 12.1, 13.9, 16.2, 18.0, 20.0,
  22.1, 24.0, 25.8, 28.0, 30.1, 32.2, 34.0, 36.1, 38.0, 40.0,
];

// ─────────────────────────────────────────────────────────────────────────────
// GchCombinatorics – combinatorial mathematics utilities
// ─────────────────────────────────────────────────────────────────────────────
class GchCombinatorics {
  GchCombinatorics._();

  // factorial – iterative
  static int factorial(int n) {
    if (n < 0) throw ArgumentError('n must be non-negative');
    int result = 1;
    for (int i = 2; i <= n; i++) result *= i;
    return result;
  }

  // binomial coefficient C(n, k) using Pascal's formula
  static int binomial(int n, int k) {
    if (k < 0 || k > n) return 0;
    if (k == 0 || k == n) return 1;
    k = k < n - k ? k : n - k;
    int result = 1;
    for (int i = 0; i < k; i++) {
      result = result * (n - i) ~/ (i + 1);
    }
    return result;
  }

  // permutation P(n, k)
  static int permutation(int n, int k) {
    if (k < 0 || k > n) return 0;
    int result = 1;
    for (int i = n; i > n - k; i--) result *= i;
    return result;
  }

  // Pascal's triangle – first n rows
  static List<List<int>> pascalTriangle(int n) {
    final triangle = <List<int>>[];
    for (int i = 0; i < n; i++) {
      final row = List<int>.filled(i + 1, 1);
      for (int j = 1; j < i; j++) {
        row[j] = triangle[i - 1][j - 1] + triangle[i - 1][j];
      }
      triangle.add(row);
    }
    return triangle;
  }

  // all permutations of a list
  static List<List<T>> permutations<T>(List<T> elements) {
    if (elements.isEmpty) return [[]];
    final result = <List<T>>[];
    _permHelper(List<T>.from(elements), 0, result);
    return result;
  }

  static void _permHelper<T>(List<T> arr, int start, List<List<T>> result) {
    if (start == arr.length - 1) {
      result.add(List<T>.from(arr));
      return;
    }
    for (int i = start; i < arr.length; i++) {
      final tmp = arr[start]; arr[start] = arr[i]; arr[i] = tmp;
      _permHelper(arr, start + 1, result);
      final tmp2 = arr[start]; arr[start] = arr[i]; arr[i] = tmp2;
    }
  }

  // all combinations of k elements from elements
  static List<List<T>> combinations<T>(List<T> elements, int k) {
    final result = <List<T>>[];
    _combHelper(elements, k, 0, [], result);
    return result;
  }

  static void _combHelper<T>(List<T> elements, int k, int start,
      List<T> current, List<List<T>> result) {
    if (current.length == k) {
      result.add(List<T>.from(current));
      return;
    }
    for (int i = start; i < elements.length; i++) {
      current.add(elements[i]);
      _combHelper(elements, k, i + 1, current, result);
      current.removeLast();
    }
  }

  // power set of elements
  static List<List<T>> powerSet<T>(List<T> elements) {
    final result = <List<T>>[[]];
    for (final e in elements) {
      final newSets = result.map((s) => [...s, e]).toList();
      result.addAll(newSets);
    }
    return result;
  }

  // Catalan number C_n
  static int catalanNumber(int n) {
    if (n <= 0) return 1;
    return binomial(2 * n, n) ~/ (n + 1);
  }

  // Stirling numbers of the second kind S(n, k)
  static int stirlingSecond(int n, int k) {
    if (k == 0) return n == 0 ? 1 : 0;
    if (k > n) return 0;
    if (k == n) return 1;
    return k * stirlingSecond(n - 1, k) + stirlingSecond(n - 1, k - 1);
  }

  // derangements D(n)
  static int derangements(int n) {
    if (n == 0) return 1;
    if (n == 1) return 0;
    int d0 = 1, d1 = 0;
    for (int i = 2; i <= n; i++) {
      final d = (i - 1) * (d0 + d1);
      d0 = d1;
      d1 = d;
    }
    return d1;
  }

  // Fibonacci sequence up to n terms
  static List<int> fibonacci(int n) {
    if (n <= 0) return [];
    if (n == 1) return [0];
    final fib = [0, 1];
    for (int i = 2; i < n; i++) {
      fib.add(fib[i - 1] + fib[i - 2]);
    }
    return fib;
  }

  // Tribonacci sequence up to n terms
  static List<int> tribonacci(int n) {
    if (n <= 0) return [];
    if (n == 1) return [0];
    if (n == 2) return [0, 0];
    if (n == 3) return [0, 0, 1];
    final trib = [0, 0, 1];
    for (int i = 3; i < n; i++) {
      trib.add(trib[i - 1] + trib[i - 2] + trib[i - 3]);
    }
    return trib;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GchIntervalTree – simple interval tree for range overlap queries
// ─────────────────────────────────────────────────────────────────────────────
class GchInterval {
  final int low;
  final int high;
  const GchInterval(this.low, this.high);

  bool overlaps(GchInterval other) => low <= other.high && other.low <= high;

  bool contains(int point) => point >= low && point <= high;

  int get length => high - low;

  @override
  String toString() => '[$low, $high]';
}

class _IntervalNode {
  GchInterval interval;
  int maxHigh;
  _IntervalNode? left;
  _IntervalNode? right;

  _IntervalNode(this.interval) : maxHigh = interval.high;
}

class GchIntervalTree {
  _IntervalNode? _root;
  int _size = 0;

  int get size => _size;
  bool get isEmpty => _size == 0;

  void insert(GchInterval interval) {
    _root = _insert(_root, interval);
    _size++;
  }

  _IntervalNode _insert(_IntervalNode? node, GchInterval interval) {
    if (node == null) return _IntervalNode(interval);
    if (interval.low < node.interval.low) {
      node.left = _insert(node.left, interval);
    } else {
      node.right = _insert(node.right, interval);
    }
    if (interval.high > node.maxHigh) node.maxHigh = interval.high;
    return node;
  }

  // Find any interval that overlaps with the given interval
  GchInterval? findOverlap(GchInterval query) {
    return _findOverlap(_root, query);
  }

  GchInterval? _findOverlap(_IntervalNode? node, GchInterval query) {
    if (node == null) return null;
    if (node.interval.overlaps(query)) return node.interval;
    if (node.left != null && node.left!.maxHigh >= query.low) {
      return _findOverlap(node.left, query);
    }
    return _findOverlap(node.right, query);
  }

  // Find all intervals that overlap with the given interval
  List<GchInterval> findAllOverlaps(GchInterval query) {
    final result = <GchInterval>[];
    _findAllOverlaps(_root, query, result);
    return result;
  }

  void _findAllOverlaps(
      _IntervalNode? node, GchInterval query, List<GchInterval> result) {
    if (node == null) return;
    if (node.interval.overlaps(query)) result.add(node.interval);
    if (node.left != null && node.left!.maxHigh >= query.low) {
      _findAllOverlaps(node.left, query, result);
    }
    if (node.right != null) {
      _findAllOverlaps(node.right, query, result);
    }
  }

  // Check if any stored interval contains the given point
  bool containsPoint(int point) {
    return findOverlap(GchInterval(point, point)) != null;
  }

  void clear() {
    _root = null;
    _size = 0;
  }

  @override
  String toString() => 'GchIntervalTree(size=$_size)';
}
