// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';
import 'dart:typed_data';

// ──────────────────────────────────────────────
// GchMatrix
// ──────────────────────────────────────────────
class GchMatrix {
  final int rows;
  final int cols;
  final Float64List _data;

  GchMatrix._(this.rows, this.cols, this._data);

  factory GchMatrix(int rows, int cols) {
    return GchMatrix._(rows, cols, Float64List(rows * cols));
  }

  factory GchMatrix.identity(int n) {
    final m = GchMatrix(n, n);
    for (int i = 0; i < n; i++) m._set(i, i, 1.0);
    return m;
  }

  factory GchMatrix.zeros(int rows, int cols) => GchMatrix(rows, cols);

  factory GchMatrix.ones(int rows, int cols) {
    final m = GchMatrix(rows, cols);
    m._data.fillRange(0, m._data.length, 1.0);
    return m;
  }

  factory GchMatrix.fromList(List<List<double>> data) {
    final rows = data.length;
    final cols = rows > 0 ? data[0].length : 0;
    final m = GchMatrix(rows, cols);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        m._set(r, c, data[r][c]);
      }
    }
    return m;
  }

  factory GchMatrix.diagonal(List<double> values) {
    final n = values.length;
    final m = GchMatrix(n, n);
    for (int i = 0; i < n; i++) m._set(i, i, values[i]);
    return m;
  }

  factory GchMatrix.random(int rows, int cols, {Random? rng}) {
    final r = rng ?? Random();
    final m = GchMatrix(rows, cols);
    for (int i = 0; i < m._data.length; i++) {
      m._data[i] = r.nextDouble();
    }
    return m;
  }

  factory GchMatrix.fromFlatList(int rows, int cols, List<double> data) {
    assert(data.length == rows * cols, 'Data length mismatch');
    final m = GchMatrix._(rows, cols, Float64List.fromList(data));
    return m;
  }

  double _get(int r, int c) => _data[r * cols + c];
  void _set(int r, int c, double v) => _data[r * cols + c] = v;

  double operator [](int index) => _data[index];
  void operator []=(int index, double value) => _data[index] = value;

  double at(int r, int c) {
    _checkBounds(r, c);
    return _get(r, c);
  }

  void setAt(int r, int c, double value) {
    _checkBounds(r, c);
    _set(r, c, value);
  }

  void _checkBounds(int r, int c) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) {
      throw RangeError('Index ($r, $c) out of bounds for matrix ${rows}x${cols}');
    }
  }

  (int, int) get shape => (rows, cols);

  bool get isSquare => rows == cols;

  bool get isSymmetric {
    if (!isSquare) return false;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if ((_get(r, c) - _get(c, r)).abs() > 1e-10) return false;
      }
    }
    return true;
  }

  bool get isDiagonal {
    if (!isSquare) return false;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (r != c && _get(r, c).abs() > 1e-10) return false;
      }
    }
    return true;
  }

  bool get isIdentity {
    if (!isSquare) return false;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final expected = r == c ? 1.0 : 0.0;
        if ((_get(r, c) - expected).abs() > 1e-10) return false;
      }
    }
    return true;
  }

  GchMatrix operator +(GchMatrix other) {
    assert(rows == other.rows && cols == other.cols, 'Size mismatch for +');
    final result = GchMatrix(rows, cols);
    for (int i = 0; i < _data.length; i++) result._data[i] = _data[i] + other._data[i];
    return result;
  }

  GchMatrix operator -(GchMatrix other) {
    assert(rows == other.rows && cols == other.cols, 'Size mismatch for -');
    final result = GchMatrix(rows, cols);
    for (int i = 0; i < _data.length; i++) result._data[i] = _data[i] - other._data[i];
    return result;
  }

  GchMatrix operator *(dynamic other) {
    if (other is double || other is int) {
      final scalar = (other as num).toDouble();
      final result = GchMatrix(rows, cols);
      for (int i = 0; i < _data.length; i++) result._data[i] = _data[i] * scalar;
      return result;
    }
    if (other is GchMatrix) {
      assert(cols == other.rows, 'Size mismatch for *: ${rows}x${cols} * ${other.rows}x${other.cols}');
      final result = GchMatrix(rows, other.cols);
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < other.cols; c++) {
          double sum = 0.0;
          for (int k = 0; k < cols; k++) sum += _get(r, k) * other._get(k, c);
          result._set(r, c, sum);
        }
      }
      return result;
    }
    throw ArgumentError('Cannot multiply GchMatrix by ${other.runtimeType}');
  }

  @override
  bool operator ==(Object other) {
    if (other is! GchMatrix) return false;
    if (rows != other.rows || cols != other.cols) return false;
    for (int i = 0; i < _data.length; i++) {
      if ((_data[i] - other._data[i]).abs() > 1e-10) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(rows, cols, _data.fold<int>(0, (h, v) => h ^ v.hashCode));

  GchMatrix get transpose {
    final result = GchMatrix(cols, rows);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        result._set(c, r, _get(r, c));
      }
    }
    return result;
  }

  double get trace {
    assert(isSquare, 'Trace requires square matrix');
    double sum = 0.0;
    for (int i = 0; i < rows; i++) sum += _get(i, i);
    return sum;
  }

  double get determinant {
    assert(isSquare, 'Determinant requires square matrix');
    if (rows == 1) return _get(0, 0);
    if (rows == 2) {
      return _get(0, 0) * _get(1, 1) - _get(0, 1) * _get(1, 0);
    }
    if (rows == 3) {
      return _get(0, 0) * (_get(1, 1) * _get(2, 2) - _get(1, 2) * _get(2, 1)) -
          _get(0, 1) * (_get(1, 0) * _get(2, 2) - _get(1, 2) * _get(2, 0)) +
          _get(0, 2) * (_get(1, 0) * _get(2, 1) - _get(1, 1) * _get(2, 0));
    }
    // LU decomposition for larger matrices
    final lu = luDecompose();
    if (lu == null) return 0.0;
    double det = 1.0;
    for (int i = 0; i < rows; i++) det *= lu.U._get(i, i);
    // Count permutation sign
    int swaps = 0;
    final pivot = lu.pivot;
    for (int i = 0; i < pivot.length; i++) {
      if (pivot[i] != i) swaps++;
    }
    return swaps.isOdd ? -det : det;
  }

  GchMatrix? get inverse {
    if (!isSquare) return null;
    final n = rows;
    // Gauss-Jordan elimination
    final aug = GchMatrix(n, 2 * n);
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) aug._set(r, c, _get(r, c));
      aug._set(r, n + r, 1.0);
    }
    for (int col = 0; col < n; col++) {
      // Find pivot
      int pivotRow = -1;
      double pivotVal = 0.0;
      for (int r = col; r < n; r++) {
        if (aug._get(r, col).abs() > pivotVal) {
          pivotVal = aug._get(r, col).abs();
          pivotRow = r;
        }
      }
      if (pivotRow < 0 || pivotVal < 1e-12) return null;
      if (pivotRow != col) {
        for (int c = 0; c < 2 * n; c++) {
          final tmp = aug._get(col, c);
          aug._set(col, c, aug._get(pivotRow, c));
          aug._set(pivotRow, c, tmp);
        }
      }
      final pivot = aug._get(col, col);
      for (int c = 0; c < 2 * n; c++) aug._set(col, c, aug._get(col, c) / pivot);
      for (int r = 0; r < n; r++) {
        if (r == col) continue;
        final factor = aug._get(r, col);
        for (int c = 0; c < 2 * n; c++) {
          aug._set(r, c, aug._get(r, c) - factor * aug._get(col, c));
        }
      }
    }
    final result = GchMatrix(n, n);
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        result._set(r, c, aug._get(r, n + c));
      }
    }
    return result;
  }

  int get rank {
    final copy = _copyData();
    int r = 0;
    for (int col = 0; col < cols && r < rows; col++) {
      int pivotRow = -1;
      for (int row = r; row < rows; row++) {
        if (copy[row][col].abs() > 1e-10) {
          pivotRow = row;
          break;
        }
      }
      if (pivotRow < 0) continue;
      final tmp = copy[r];
      copy[r] = copy[pivotRow];
      copy[pivotRow] = tmp;
      final pivotVal = copy[r][col];
      for (int c = 0; c < cols; c++) copy[r][c] /= pivotVal;
      for (int row = 0; row < rows; row++) {
        if (row == r) continue;
        final factor = copy[row][col];
        for (int c = 0; c < cols; c++) copy[row][c] -= factor * copy[r][c];
      }
      r++;
    }
    return r;
  }

  List<List<double>> _copyData() {
    return List.generate(rows, (r) => List.generate(cols, (c) => _get(r, c)));
  }

  GchMatrix reshape(int newRows, int newCols) {
    assert(newRows * newCols == rows * cols, 'Total elements must remain the same');
    final result = GchMatrix._(newRows, newCols, Float64List.fromList(_data));
    return result;
  }

  GchMatrix submatrix(int r1, int c1, int r2, int c2) {
    assert(r1 >= 0 && c1 >= 0 && r2 <= rows && c2 <= cols, 'Submatrix bounds invalid');
    final newRows = r2 - r1;
    final newCols = c2 - c1;
    final result = GchMatrix(newRows, newCols);
    for (int r = 0; r < newRows; r++) {
      for (int c = 0; c < newCols; c++) {
        result._set(r, c, _get(r1 + r, c1 + c));
      }
    }
    return result;
  }

  GchMatrix hstack(GchMatrix other) {
    assert(rows == other.rows, 'hstack requires equal row count');
    final result = GchMatrix(rows, cols + other.cols);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) result._set(r, c, _get(r, c));
      for (int c = 0; c < other.cols; c++) result._set(r, cols + c, other._get(r, c));
    }
    return result;
  }

  GchMatrix vstack(GchMatrix other) {
    assert(cols == other.cols, 'vstack requires equal col count');
    final result = GchMatrix(rows + other.rows, cols);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) result._set(r, c, _get(r, c));
    }
    for (int r = 0; r < other.rows; r++) {
      for (int c = 0; c < cols; c++) result._set(rows + r, c, other._get(r, c));
    }
    return result;
  }

  GchMatrix map(double Function(double) f) {
    final result = GchMatrix(rows, cols);
    for (int i = 0; i < _data.length; i++) result._data[i] = f(_data[i]);
    return result;
  }

  double get sum => _data.fold(0.0, (s, v) => s + v);

  double get max => _data.reduce((a, b) => a > b ? a : b);

  double get min => _data.reduce((a, b) => a < b ? a : b);

  double get mean => sum / _data.length;

  List<double> get rowSums {
    return List.generate(rows, (r) {
      double s = 0.0;
      for (int c = 0; c < cols; c++) s += _get(r, c);
      return s;
    });
  }

  List<double> get colSums {
    return List.generate(cols, (c) {
      double s = 0.0;
      for (int r = 0; r < rows; r++) s += _get(r, c);
      return s;
    });
  }

  double norm({int p = 2}) {
    if (p == 0) {
      // Frobenius norm
      double sum = 0.0;
      for (final v in _data) sum += v * v;
      return sqrt(sum);
    }
    if (p == 1) {
      // Max column sum
      double maxSum = 0.0;
      for (final cs in colSums) {
        final abs = cs.abs();
        if (abs > maxSum) maxSum = abs;
      }
      return maxSum;
    }
    // p-norm element-wise
    double sum = 0.0;
    for (final v in _data) sum += pow(v.abs(), p).toDouble();
    return pow(sum, 1.0 / p).toDouble();
  }

  List<double>? solve(List<double> b) {
    assert(isSquare, 'solve requires square matrix');
    final n = rows;
    assert(b.length == n, 'b vector length must match matrix rows');
    final aug = List.generate(n, (r) => [..._copyData()[r], b[r]]);
    for (int col = 0; col < n; col++) {
      int pivotRow = -1;
      double pivotVal = 0.0;
      for (int r = col; r < n; r++) {
        if (aug[r][col].abs() > pivotVal) {
          pivotVal = aug[r][col].abs();
          pivotRow = r;
        }
      }
      if (pivotRow < 0 || pivotVal < 1e-12) return null;
      final tmp = aug[col];
      aug[col] = aug[pivotRow];
      aug[pivotRow] = tmp;
      final pivot = aug[col][col];
      for (int c = 0; c <= n; c++) aug[col][c] /= pivot;
      for (int r = 0; r < n; r++) {
        if (r == col) continue;
        final factor = aug[r][col];
        for (int c = 0; c <= n; c++) aug[r][c] -= factor * aug[col][c];
      }
    }
    return List.generate(n, (i) => aug[i][n]);
  }

  ({GchMatrix L, GchMatrix U, List<int> pivot})? luDecompose() {
    if (!isSquare) return null;
    final n = rows;
    final A = _copyData();
    final pivot = List.generate(n, (i) => i);
    for (int k = 0; k < n; k++) {
      int maxRow = k;
      double maxVal = A[k][k].abs();
      for (int r = k + 1; r < n; r++) {
        if (A[r][k].abs() > maxVal) {
          maxVal = A[r][k].abs();
          maxRow = r;
        }
      }
      if (maxVal < 1e-12) return null;
      if (maxRow != k) {
        final tmp = A[k];
        A[k] = A[maxRow];
        A[maxRow] = tmp;
        final tp = pivot[k];
        pivot[k] = pivot[maxRow];
        pivot[maxRow] = tp;
      }
      for (int r = k + 1; r < n; r++) {
        A[r][k] /= A[k][k];
        for (int c = k + 1; c < n; c++) {
          A[r][c] -= A[r][k] * A[k][c];
        }
      }
    }
    final L = GchMatrix.identity(n);
    final U = GchMatrix(n, n);
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (c < r) {
          L._set(r, c, A[r][c]);
        } else {
          U._set(r, c, A[r][c]);
        }
      }
    }
    return (L: L, U: U, pivot: pivot);
  }

  List<double> getRow(int r) {
    _checkBounds(r, 0);
    return List.generate(cols, (c) => _get(r, c));
  }

  List<double> getCol(int c) {
    _checkBounds(0, c);
    return List.generate(rows, (r) => _get(r, c));
  }

  void setRow(int r, List<double> values) {
    assert(values.length == cols, 'Row length mismatch');
    for (int c = 0; c < cols; c++) _set(r, c, values[c]);
  }

  void setCol(int c, List<double> values) {
    assert(values.length == rows, 'Column length mismatch');
    for (int r = 0; r < rows; r++) _set(r, c, values[r]);
  }

  GchMatrix swapRows(int r1, int r2) {
    final result = GchMatrix._(rows, cols, Float64List.fromList(_data));
    for (int c = 0; c < cols; c++) {
      final tmp = result._get(r1, c);
      result._set(r1, c, result._get(r2, c));
      result._set(r2, c, tmp);
    }
    return result;
  }

  @override
  String toString({int decimals = 4}) {
    final sb = StringBuffer('GchMatrix ${rows}x${cols}:\n');
    for (int r = 0; r < rows; r++) {
      sb.write('[');
      for (int c = 0; c < cols; c++) {
        if (c > 0) sb.write(', ');
        sb.write(_get(r, c).toStringAsFixed(decimals));
      }
      sb.write(']\n');
    }
    return sb.toString();
  }
}

// ──────────────────────────────────────────────
// GchVector
// ──────────────────────────────────────────────
class GchVector {
  final List<double> _data;

  GchVector(List<double> data) : _data = List.from(data);

  factory GchVector.zeros(int n) => GchVector(List.filled(n, 0.0));

  factory GchVector.ones(int n) => GchVector(List.filled(n, 1.0));

  factory GchVector.unit(int n, int axis) {
    final data = List.filled(n, 0.0);
    data[axis] = 1.0;
    return GchVector(data);
  }

  int get length => _data.length;

  double operator [](int index) => _data[index];
  void operator []=(int index, double value) => _data[index] = value;

  double dot(GchVector other) {
    assert(length == other.length, 'Vector length mismatch for dot');
    double sum = 0.0;
    for (int i = 0; i < length; i++) sum += _data[i] * other._data[i];
    return sum;
  }

  GchVector cross(GchVector other) {
    assert(length == 3 && other.length == 3, 'Cross product only for 3D vectors');
    return GchVector([
      _data[1] * other._data[2] - _data[2] * other._data[1],
      _data[2] * other._data[0] - _data[0] * other._data[2],
      _data[0] * other._data[1] - _data[1] * other._data[0],
    ]);
  }

  double get magnitude => sqrt(_data.fold(0.0, (s, v) => s + v * v));

  GchVector get normalize {
    final m = magnitude;
    if (m < 1e-12) return GchVector.zeros(length);
    return GchVector(_data.map((v) => v / m).toList());
  }

  double angle(GchVector other) {
    final d = dot(other);
    final m = magnitude * other.magnitude;
    if (m < 1e-12) return 0.0;
    return acos((d / m).clamp(-1.0, 1.0));
  }

  GchVector projection(GchVector onto) {
    final scale = dot(onto) / onto.dot(onto);
    return onto * scale;
  }

  GchVector operator +(GchVector other) {
    assert(length == other.length);
    return GchVector(List.generate(length, (i) => _data[i] + other._data[i]));
  }

  GchVector operator -(GchVector other) {
    assert(length == other.length);
    return GchVector(List.generate(length, (i) => _data[i] - other._data[i]));
  }

  GchVector operator *(double scalar) =>
      GchVector(_data.map((v) => v * scalar).toList());

  @override
  bool operator ==(Object other) {
    if (other is! GchVector) return false;
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if ((_data[i] - other._data[i]).abs() > 1e-10) return false;
    }
    return true;
  }

  @override
  int get hashCode => _data.fold<int>(0, (h, v) => h ^ v.hashCode);

  GchMatrix toColumnMatrix() {
    final m = GchMatrix(length, 1);
    for (int i = 0; i < length; i++) m[i] = _data[i];
    return m;
  }

  GchMatrix toRowMatrix() {
    final m = GchMatrix(1, length);
    for (int i = 0; i < length; i++) m[i] = _data[i];
    return m;
  }

  GchMatrix outerProduct(GchVector other) {
    final m = GchMatrix(length, other.length);
    for (int r = 0; r < length; r++) {
      for (int c = 0; c < other.length; c++) {
        m[r * other.length + c] = _data[r] * other._data[c];
      }
    }
    return m;
  }

  double sum() => _data.fold(0.0, (s, v) => s + v);

  double get maxValue => _data.reduce(max);
  double get minValue => _data.reduce(min);
  double get mean => sum() / length;

  GchVector map(double Function(double) f) =>
      GchVector(_data.map(f).toList());

  @override
  String toString() =>
      'GchVector([${_data.map((v) => v.toStringAsFixed(4)).join(', ')}])';
}

// ──────────────────────────────────────────────
// Predefined test matrices
// ──────────────────────────────────────────────
class GchMatrixTestData {
  GchMatrixTestData._();

  static final GchMatrix identity2 = GchMatrix.identity(2);
  static final GchMatrix identity3 = GchMatrix.identity(3);
  static final GchMatrix zeros3x3 = GchMatrix.zeros(3, 3);
  static final GchMatrix ones4x4 = GchMatrix.ones(4, 4);

  static final GchMatrix simple2x2 = GchMatrix.fromList([
    [1.0, 2.0],
    [3.0, 4.0],
  ]);

  static final GchMatrix simple3x3 = GchMatrix.fromList([
    [1.0, 2.0, 3.0],
    [4.0, 5.0, 6.0],
    [7.0, 8.0, 9.0],
  ]);

  static final GchMatrix invertible3x3 = GchMatrix.fromList([
    [2.0, 1.0, 1.0],
    [4.0, 3.0, 3.0],
    [8.0, 7.0, 9.0],
  ]);

  static final GchMatrix symmetric4x4 = GchMatrix.fromList([
    [4.0, 2.0, 0.0, 1.0],
    [2.0, 3.0, 1.0, 0.0],
    [0.0, 1.0, 5.0, 2.0],
    [1.0, 0.0, 2.0, 6.0],
  ]);

  static final GchMatrix rect2x3 = GchMatrix.fromList([
    [1.0, 2.0, 3.0],
    [4.0, 5.0, 6.0],
  ]);

  static final GchMatrix rect3x2 = GchMatrix.fromList([
    [7.0, 8.0],
    [9.0, 10.0],
    [11.0, 12.0],
  ]);

  static final GchMatrix diagonal3 = GchMatrix.diagonal([3.0, 1.0, 4.0]);

  static final GchMatrix upper3x3 = GchMatrix.fromList([
    [1.0, 2.0, 3.0],
    [0.0, 4.0, 5.0],
    [0.0, 0.0, 6.0],
  ]);

  static final GchMatrix lower3x3 = GchMatrix.fromList([
    [1.0, 0.0, 0.0],
    [2.0, 3.0, 0.0],
    [4.0, 5.0, 6.0],
  ]);

  static final GchMatrix hilbert4x4 = GchMatrix.fromList([
    [1.0, 1/2, 1/3, 1/4],
    [1/2, 1/3, 1/4, 1/5],
    [1/3, 1/4, 1/5, 1/6],
    [1/4, 1/5, 1/6, 1/7],
  ]);

  static final GchMatrix magic3x3 = GchMatrix.fromList([
    [2.0, 7.0, 6.0],
    [9.0, 5.0, 1.0],
    [4.0, 3.0, 8.0],
  ]);

  static final GchMatrix pascal4x4 = GchMatrix.fromList([
    [1.0, 1.0, 1.0, 1.0],
    [1.0, 2.0, 3.0, 4.0],
    [1.0, 3.0, 6.0, 10.0],
    [1.0, 4.0, 10.0, 20.0],
  ]);

  static final GchMatrix rotation45deg = GchMatrix.fromList([
    [cos(pi / 4), -sin(pi / 4)],
    [sin(pi / 4), cos(pi / 4)],
  ]);

  static final GchMatrix scale2x = GchMatrix.fromList([
    [2.0, 0.0],
    [0.0, 2.0],
  ]);

  static final GchMatrix shear = GchMatrix.fromList([
    [1.0, 0.5],
    [0.0, 1.0],
  ]);

  static final GchMatrix companion4 = GchMatrix.fromList([
    [0.0, 0.0, 0.0, -1.0],
    [1.0, 0.0, 0.0, -4.0],
    [0.0, 1.0, 0.0, -6.0],
    [0.0, 0.0, 1.0, -4.0],
  ]);

  static final GchMatrix sparse5x5 = GchMatrix.fromList([
    [5.0, 0.0, 0.0, 1.0, 0.0],
    [0.0, 3.0, 0.0, 0.0, 2.0],
    [0.0, 0.0, 8.0, 0.0, 0.0],
    [1.0, 0.0, 0.0, 4.0, 0.0],
    [0.0, 2.0, 0.0, 0.0, 6.0],
  ]);

  static final GchVector vec3a = GchVector([1.0, 2.0, 3.0]);
  static final GchVector vec3b = GchVector([4.0, 5.0, 6.0]);
  static final GchVector vec3unit_x = GchVector([1.0, 0.0, 0.0]);
  static final GchVector vec3unit_y = GchVector([0.0, 1.0, 0.0]);
  static final GchVector vec3unit_z = GchVector([0.0, 0.0, 1.0]);
}

// ──────────────────────────────────────────────
// GchMatrixOps – additional operations
// ──────────────────────────────────────────────
class GchMatrixOps {
  GchMatrixOps._();

  static GchMatrix hadamard(GchMatrix a, GchMatrix b) {
    assert(a.rows == b.rows && a.cols == b.cols, 'Size mismatch for Hadamard');
    final result = GchMatrix(a.rows, a.cols);
    for (int i = 0; i < a._data.length; i++) result._data[i] = a._data[i] * b._data[i];
    return result;
  }

  static GchMatrix kronecker(GchMatrix a, GchMatrix b) {
    final rows = a.rows * b.rows;
    final cols = a.cols * b.cols;
    final result = GchMatrix(rows, cols);
    for (int ar = 0; ar < a.rows; ar++) {
      for (int ac = 0; ac < a.cols; ac++) {
        final scalar = a._get(ar, ac);
        for (int br = 0; br < b.rows; br++) {
          for (int bc = 0; bc < b.cols; bc++) {
            result._set(ar * b.rows + br, ac * b.cols + bc, scalar * b._get(br, bc));
          }
        }
      }
    }
    return result;
  }

  static GchMatrix power(GchMatrix m, int exp) {
    assert(m.isSquare, 'Matrix power requires square matrix');
    if (exp == 0) return GchMatrix.identity(m.rows);
    if (exp == 1) return m;
    if (exp < 0) {
      final inv = m.inverse;
      if (inv == null) throw StateError('Matrix is not invertible');
      return power(inv!, -exp);
    }
    GchMatrix result = GchMatrix.identity(m.rows);
    GchMatrix base = m;
    int e = exp;
    while (e > 0) {
      if (e.isOdd) result = result * base as GchMatrix;
      base = base * base as GchMatrix;
      e >>= 1;
    }
    return result;
  }

  static double frobeniusNorm(GchMatrix m) {
    return sqrt(m._data.fold(0.0, (s, v) => s + v * v));
  }

  static GchMatrix elementWiseAdd(GchMatrix a, GchMatrix b) => a + b;

  static GchMatrix scalarAdd(GchMatrix m, double s) {
    return m.map((v) => v + s);
  }

  static GchMatrix abs_(GchMatrix m) => m.map((v) => v.abs());

  static GchMatrix clamp_(GchMatrix m, double minVal, double maxVal) =>
      m.map((v) => v.clamp(minVal, maxVal));

  static GchMatrix softmax(GchMatrix m) {
    double maxVal = m.max;
    final shifted = m.map((v) => exp(v - maxVal));
    final s = shifted.sum;
    return shifted.map((v) => v / s);
  }

  static GchMatrix relu(GchMatrix m) => m.map((v) => v < 0 ? 0.0 : v);

  static GchMatrix sigmoid(GchMatrix m) =>
      m.map((v) => 1.0 / (1.0 + exp(-v)));

  static GchMatrix tanh_(GchMatrix m) => m.map((v) {
    final e2 = exp(2 * v);
    return (e2 - 1) / (e2 + 1);
  });

  static bool isOrthogonal(GchMatrix m) {
    if (!m.isSquare) return false;
    final product = m.transpose * m;
    return (product as GchMatrix) == GchMatrix.identity(m.rows);
  }

  static GchMatrix gramSchmidt(GchMatrix a) {
    final n = a.cols;
    final vecs = <GchVector>[];
    for (int j = 0; j < n; j++) {
      var v = GchVector(a.getCol(j));
      for (final u in vecs) {
        final proj = u * (v.dot(u) / u.dot(u));
        v = v - proj;
      }
      vecs.add(v.magnitude > 1e-12 ? v.normalize : v);
    }
    final result = GchMatrix(a.rows, n);
    for (int j = 0; j < n; j++) {
      for (int r = 0; r < a.rows; r++) {
        result._set(r, j, j < vecs.length ? vecs[j][r] : 0.0);
      }
    }
    return result;
  }
}
