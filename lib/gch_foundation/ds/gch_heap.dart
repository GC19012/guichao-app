// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:collection';

// ─────────────────────────────────────────────────────────────────────────────
// GchMinHeap – min-heap
// ─────────────────────────────────────────────────────────────────────────────
class GchMinHeap<T extends Comparable<T>> {
  final List<T> _data = [];

  int get size => _data.length;
  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;

  T get peek {
    if (isEmpty) throw StateError('Heap is empty');
    return _data[0];
  }

  void insert(T value) {
    _data.add(value);
    _bubbleUp(_data.length - 1);
  }

  T extractMin() {
    if (isEmpty) throw StateError('Heap is empty');
    final min = _data[0];
    final last = _data.removeLast();
    if (_data.isNotEmpty) {
      _data[0] = last;
      _bubbleDown(0);
    }
    return min;
  }

  void _bubbleUp(int index) {
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_data[index].compareTo(_data[parent]) < 0) {
        final tmp = _data[index];
        _data[index] = _data[parent];
        _data[parent] = tmp;
        index = parent;
      } else {
        break;
      }
    }
  }

  void _bubbleDown(int index) {
    final n = _data.length;
    while (true) {
      int smallest = index;
      final left = 2 * index + 1;
      final right = 2 * index + 2;
      if (left < n && _data[left].compareTo(_data[smallest]) < 0) {
        smallest = left;
      }
      if (right < n && _data[right].compareTo(_data[smallest]) < 0) {
        smallest = right;
      }
      if (smallest == index) break;
      final tmp = _data[index];
      _data[index] = _data[smallest];
      _data[smallest] = tmp;
      index = smallest;
    }
  }

  void heapifyFrom(List<T> list) {
    _data.clear();
    _data.addAll(list);
    for (int i = _data.length ~/ 2 - 1; i >= 0; i--) {
      _bubbleDown(i);
    }
  }

  List<T> toSortedList() {
    final copy = GchMinHeap<T>();
    copy._data.addAll(_data);
    final result = <T>[];
    while (copy.isNotEmpty) {
      result.add(copy.extractMin());
    }
    return result;
  }

  bool contains(T value) => _data.contains(value);

  void clear() => _data.clear();

  List<T> toList() => List<T>.unmodifiable(_data);

  @override
  String toString() => 'GchMinHeap(size=$size, peek=${isEmpty ? "empty" : peek})';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchMaxHeap – max-heap
// ─────────────────────────────────────────────────────────────────────────────
class GchMaxHeap<T extends Comparable<T>> {
  final List<T> _data = [];

  int get size => _data.length;
  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;

  T get peek {
    if (isEmpty) throw StateError('Heap is empty');
    return _data[0];
  }

  void insert(T value) {
    _data.add(value);
    _bubbleUp(_data.length - 1);
  }

  T extractMax() {
    if (isEmpty) throw StateError('Heap is empty');
    final max = _data[0];
    final last = _data.removeLast();
    if (_data.isNotEmpty) {
      _data[0] = last;
      _bubbleDown(0);
    }
    return max;
  }

  void _bubbleUp(int index) {
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_data[index].compareTo(_data[parent]) > 0) {
        final tmp = _data[index];
        _data[index] = _data[parent];
        _data[parent] = tmp;
        index = parent;
      } else {
        break;
      }
    }
  }

  void _bubbleDown(int index) {
    final n = _data.length;
    while (true) {
      int largest = index;
      final left = 2 * index + 1;
      final right = 2 * index + 2;
      if (left < n && _data[left].compareTo(_data[largest]) > 0) {
        largest = left;
      }
      if (right < n && _data[right].compareTo(_data[largest]) > 0) {
        largest = right;
      }
      if (largest == index) break;
      final tmp = _data[index];
      _data[index] = _data[largest];
      _data[largest] = tmp;
      index = largest;
    }
  }

  void heapifyFrom(List<T> list) {
    _data.clear();
    _data.addAll(list);
    for (int i = _data.length ~/ 2 - 1; i >= 0; i--) {
      _bubbleDown(i);
    }
  }

  List<T> toSortedList() {
    final copy = GchMaxHeap<T>();
    copy._data.addAll(_data);
    final result = <T>[];
    while (copy.isNotEmpty) {
      result.add(copy.extractMax());
    }
    return result;
  }

  bool contains(T value) => _data.contains(value);

  void clear() => _data.clear();

  List<T> toList() => List<T>.unmodifiable(_data);

  @override
  String toString() => 'GchMaxHeap(size=$size, peek=${isEmpty ? "empty" : peek})';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchPriorityQueue – generic priority queue with custom comparator
// ─────────────────────────────────────────────────────────────────────────────
int _pqAscCmp(double a, double b) => a.compareTo(b);
int _pqDescCmp(double a, double b) => b.compareTo(a);

class _PQEntry<T> {
  final T item;
  double priority;
  _PQEntry(this.item, this.priority);
}

class GchPriorityQueue<T> {
  final List<_PQEntry<T>> _data = [];
  final int Function(double, double) _cmp;

  /// [ascending] = true means lowest priority number is dequeued first
  GchPriorityQueue({bool ascending = true})
      : _cmp = ascending ? _pqAscCmp : _pqDescCmp;

  int get size => _data.length;
  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;

  T get peek {
    if (isEmpty) throw StateError('Queue is empty');
    return _data[0].item;
  }

  void enqueue(T item, double priority) {
    _data.add(_PQEntry<T>(item, priority));
    _bubbleUp(_data.length - 1);
  }

  T dequeue() {
    if (isEmpty) throw StateError('Queue is empty');
    final top = _data[0].item;
    final last = _data.removeLast();
    if (_data.isNotEmpty) {
      _data[0] = last;
      _bubbleDown(0);
    }
    return top;
  }

  void _bubbleUp(int index) {
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_cmp(_data[index].priority, _data[parent].priority) < 0) {
        final tmp = _data[index];
        _data[index] = _data[parent];
        _data[parent] = tmp;
        index = parent;
      } else {
        break;
      }
    }
  }

  void _bubbleDown(int index) {
    final n = _data.length;
    while (true) {
      int best = index;
      final left = 2 * index + 1;
      final right = 2 * index + 2;
      if (left < n && _cmp(_data[left].priority, _data[best].priority) < 0) {
        best = left;
      }
      if (right < n && _cmp(_data[right].priority, _data[best].priority) < 0) {
        best = right;
      }
      if (best == index) break;
      final tmp = _data[index];
      _data[index] = _data[best];
      _data[best] = tmp;
      index = best;
    }
  }

  bool changePriority(T item, double newPriority) {
    for (int i = 0; i < _data.length; i++) {
      if (_data[i].item == item) {
        _data[i].priority = newPriority;
        // restore heap: try bubble up then down
        _bubbleUp(i);
        // find actual position after bubbleUp
        for (int j = 0; j < _data.length; j++) {
          if (_data[j].item == item) {
            _bubbleDown(j);
            break;
          }
        }
        return true;
      }
    }
    return false;
  }

  bool contains(T item) {
    for (final entry in _data) {
      if (entry.item == item) return true;
    }
    return false;
  }

  bool remove(T item) {
    for (int i = 0; i < _data.length; i++) {
      if (_data[i].item == item) {
        final last = _data.removeLast();
        if (i < _data.length) {
          _data[i] = last;
          _bubbleUp(i);
          for (int j = 0; j < _data.length; j++) {
            if (_data[j].item == item || identical(_data[j], last)) {
              _bubbleDown(j);
              break;
            }
          }
        }
        return true;
      }
    }
    return false;
  }

  List<T> toList() {
    final copy = GchPriorityQueue<T>(ascending: _cmp(0, 1) < 0);
    for (final e in _data) {
      copy.enqueue(e.item, e.priority);
    }
    final result = <T>[];
    while (copy.isNotEmpty) {
      result.add(copy.dequeue());
    }
    return result;
  }

  void clear() => _data.clear();

  @override
  String toString() => 'GchPriorityQueue(size=$size)';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchHeapSort – static sort utilities using heap
// ─────────────────────────────────────────────────────────────────────────────
class GchHeapSort {
  GchHeapSort._();

  static List<T> sort<T extends Comparable<T>>(List<T> list) {
    if (list.length <= 1) return List<T>.from(list);
    final heap = GchMinHeap<T>();
    heap.heapifyFrom(list);
    return heap.toSortedList();
  }

  static List<T> sortDescending<T extends Comparable<T>>(List<T> list) {
    if (list.length <= 1) return List<T>.from(list);
    final heap = GchMaxHeap<T>();
    heap.heapifyFrom(list);
    return heap.toSortedList();
  }

  static List<T> sortBy<T>(List<T> list, Comparable<dynamic> Function(T) key) {
    if (list.length <= 1) return List<T>.from(list);
    final indexed = list.map((e) => _KeyedItem<T>(e, key(e))).toList();
    // use min-heap approach with keyed items
    indexed.sort((a, b) => a.key.compareTo(b.key));
    return indexed.map((e) => e.item).toList();
  }

  // in-place heap sort on int list
  static List<int> inPlaceSort(List<int> list) {
    final arr = List<int>.from(list);
    final n = arr.length;
    // build max-heap
    for (int i = n ~/ 2 - 1; i >= 0; i--) {
      _heapifyDown(arr, n, i);
    }
    // extract elements one by one
    for (int i = n - 1; i > 0; i--) {
      final tmp = arr[0];
      arr[0] = arr[i];
      arr[i] = tmp;
      _heapifyDown(arr, i, 0);
    }
    return arr;
  }

  static void _heapifyDown(List<int> arr, int n, int i) {
    int largest = i;
    final left = 2 * i + 1;
    final right = 2 * i + 2;
    if (left < n && arr[left] > arr[largest]) largest = left;
    if (right < n && arr[right] > arr[largest]) largest = right;
    if (largest != i) {
      final tmp = arr[i];
      arr[i] = arr[largest];
      arr[largest] = tmp;
      _heapifyDown(arr, n, largest);
    }
  }
}

class _KeyedItem<T> {
  final T item;
  final Comparable<dynamic> key;
  _KeyedItem(this.item, this.key);
}

// ─────────────────────────────────────────────────────────────────────────────
// GchMedianFinder – online median using two heaps
// ─────────────────────────────────────────────────────────────────────────────
class GchMedianFinder {
  // _lower holds the lower half (max-heap)
  final GchMaxHeap<num> _lower = GchMaxHeap<num>();
  // _upper holds the upper half (min-heap)
  final GchMinHeap<num> _upper = GchMinHeap<num>();

  int get size => _lower.size + _upper.size;
  bool get isEmpty => size == 0;

  void addNum(double num) {
    if (_lower.isEmpty || num <= _lower.peek) {
      _lower.insert(num);
    } else {
      _upper.insert(num);
    }
    // balance
    if (_lower.size > _upper.size + 1) {
      _upper.insert(_lower.extractMax());
    } else if (_upper.size > _lower.size) {
      _lower.insert(_upper.extractMin());
    }
  }

  double findMedian() {
    if (isEmpty) throw StateError('No numbers added');
    if (_lower.size == _upper.size) {
      return (_lower.peek + _upper.peek) / 2.0;
    }
    return _lower.peek.toDouble();
  }

  void clear() {
    _lower.clear();
    _upper.clear();
  }

  @override
  String toString() =>
      'GchMedianFinder(size=$size, median=${isEmpty ? "N/A" : findMedian()})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Preset test data constants
// ─────────────────────────────────────────────────────────────────────────────
const List<int> kHeapTestInts = [
  64, 34, 25, 12, 22, 11, 90, 45, 77, 33,
  18, 55, 72, 40, 8,  60, 15, 88, 3,  99,
  47, 63, 29, 81, 56, 14, 70, 38, 93, 21,
  67, 4,  50, 85, 27, 74, 41, 96, 10, 58,
];

const List<double> kHeapTestDoubles = [
  3.14, 2.71, 1.41, 1.73, 0.57, 2.30, 1.61, 0.30, 4.67, 5.29,
  7.38, 6.02, 8.85, 9.10, 4.44, 3.33, 2.22, 1.11, 0.99, 6.78,
  5.55, 4.12, 3.90, 2.50, 1.80, 9.99, 8.75, 7.60, 6.43, 5.01,
];

const List<int> kLargePrimes = [
  101, 103, 107, 109, 113, 127, 131, 137, 139, 149,
  151, 157, 163, 167, 173, 179, 181, 191, 193, 197,
  199, 211, 223, 227, 229, 233, 239, 241, 251, 257,
];

const List<int> kHeapExtra = [
  300, 301, 302, 303, 304, 305, 306, 307, 308, 309,
  310, 311, 312, 313, 314, 315, 316, 317, 318, 319,
  320, 321, 322, 323, 324, 325, 326, 327, 328, 329,
];

// ─────────────────────────────────────────────────────────────────────────────
// GchIndexedPriorityQueue – priority queue that also supports key lookup
// ─────────────────────────────────────────────────────────────────────────────
class GchIndexedPriorityQueue<K, V extends Comparable<V>> {
  final Map<K, int> _keyToIndex = {};
  final List<K> _keys = [];
  final List<V> _values = [];
  final bool _isMinQueue;

  GchIndexedPriorityQueue({bool ascending = true}) : _isMinQueue = ascending;

  int get size => _keys.length;
  bool get isEmpty => _keys.isEmpty;

  void insert(K key, V value) {
    if (_keyToIndex.containsKey(key)) {
      changeValue(key, value);
      return;
    }
    _keys.add(key);
    _values.add(value);
    final idx = _keys.length - 1;
    _keyToIndex[key] = idx;
    _siftUp(idx);
  }

  K extractTop() {
    if (isEmpty) throw StateError('Queue is empty');
    final topKey = _keys[0];
    _swap(0, _keys.length - 1);
    _keys.removeLast();
    _values.removeLast();
    _keyToIndex.remove(topKey);
    if (_keys.isNotEmpty) _siftDown(0);
    return topKey;
  }

  V? getValue(K key) {
    final idx = _keyToIndex[key];
    if (idx == null) return null;
    return _values[idx];
  }

  bool contains(K key) => _keyToIndex.containsKey(key);

  void changeValue(K key, V newValue) {
    final idx = _keyToIndex[key];
    if (idx == null) throw ArgumentError('Key not found: $key');
    _values[idx] = newValue;
    _siftUp(idx);
    _siftDown(_keyToIndex[key]!);
  }

  bool remove(K key) {
    final idx = _keyToIndex[key];
    if (idx == null) return false;
    _swap(idx, _keys.length - 1);
    _keys.removeLast();
    _values.removeLast();
    _keyToIndex.remove(key);
    if (idx < _keys.length) {
      _siftUp(idx);
      _siftDown(_keyToIndex[_keys[idx]]!);
    }
    return true;
  }

  int _compare(int i, int j) {
    final cmp = _values[i].compareTo(_values[j]);
    return _isMinQueue ? cmp : -cmp;
  }

  void _swap(int i, int j) {
    final tmpKey = _keys[i];
    _keys[i] = _keys[j];
    _keys[j] = tmpKey;
    final tmpVal = _values[i];
    _values[i] = _values[j];
    _values[j] = tmpVal;
    _keyToIndex[_keys[i]] = i;
    _keyToIndex[_keys[j]] = j;
  }

  void _siftUp(int idx) {
    int i = idx;
    while (i > 0) {
      final parent = (i - 1) ~/ 2;
      if (_compare(i, parent) < 0) {
        _swap(i, parent);
        i = parent;
      } else break;
    }
  }

  void _siftDown(int idx) {
    int i = idx;
    final n = _keys.length;
    while (true) {
      int best = i;
      final l = 2 * i + 1, r = 2 * i + 2;
      if (l < n && _compare(l, best) < 0) best = l;
      if (r < n && _compare(r, best) < 0) best = r;
      if (best == i) break;
      _swap(i, best);
      i = best;
    }
  }

  List<K> toSortedKeys() {
    final copy = GchIndexedPriorityQueue<K, V>(ascending: _isMinQueue);
    for (int i = 0; i < _keys.length; i++) {
      copy.insert(_keys[i], _values[i]);
    }
    final result = <K>[];
    while (!copy.isEmpty) result.add(copy.extractTop());
    return result;
  }

  @override
  String toString() => 'GchIndexedPriorityQueue(size=$size)';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchDHeap – D-ary heap (generalization of binary heap to D children)
// ─────────────────────────────────────────────────────────────────────────────
class GchDHeap<T extends Comparable<T>> {
  final List<T> _data = [];
  final int _d; // branching factor
  final bool _isMinHeap;

  GchDHeap({int d = 3, bool minHeap = true})
      : _d = d < 2 ? 2 : d,
        _isMinHeap = minHeap;

  int get size => _data.length;
  bool get isEmpty => _data.isEmpty;

  T get peek {
    if (isEmpty) throw StateError('Heap is empty');
    return _data[0];
  }

  void insert(T value) {
    _data.add(value);
    _siftUp(_data.length - 1);
  }

  T extractTop() {
    if (isEmpty) throw StateError('Heap is empty');
    final top = _data[0];
    final last = _data.removeLast();
    if (_data.isNotEmpty) {
      _data[0] = last;
      _siftDown(0);
    }
    return top;
  }

  bool _better(T a, T b) {
    final cmp = a.compareTo(b);
    return _isMinHeap ? cmp < 0 : cmp > 0;
  }

  void _siftUp(int idx) {
    while (idx > 0) {
      final parent = (idx - 1) ~/ _d;
      if (_better(_data[idx], _data[parent])) {
        final tmp = _data[idx];
        _data[idx] = _data[parent];
        _data[parent] = tmp;
        idx = parent;
      } else break;
    }
  }

  void _siftDown(int idx) {
    final n = _data.length;
    while (true) {
      int best = idx;
      for (int i = 1; i <= _d; i++) {
        final child = _d * idx + i;
        if (child < n && _better(_data[child], _data[best])) {
          best = child;
        }
      }
      if (best == idx) break;
      final tmp = _data[idx];
      _data[idx] = _data[best];
      _data[best] = tmp;
      idx = best;
    }
  }

  void heapifyFrom(List<T> list) {
    _data.clear();
    _data.addAll(list);
    for (int i = (_data.length - 2) ~/ _d; i >= 0; i--) {
      _siftDown(i);
    }
  }

  List<T> toSortedList() {
    final copy = GchDHeap<T>(d: _d, minHeap: _isMinHeap);
    copy._data.addAll(_data);
    final result = <T>[];
    while (!copy.isEmpty) result.add(copy.extractTop());
    return result;
  }

  void clear() => _data.clear();

  @override
  String toString() => 'GchDHeap(d=$_d, size=$size, type=${_isMinHeap ? "min" : "max"})';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchRunningStats – maintains running statistics with O(1) updates
// ─────────────────────────────────────────────────────────────────────────────
class GchRunningStats {
  int _count = 0;
  double _mean = 0;
  double _m2 = 0; // for Welford's online variance
  double _min = double.infinity;
  double _max = double.negativeInfinity;
  double _sum = 0;

  int get count => _count;
  bool get isEmpty => _count == 0;

  void addValue(double value) {
    _count++;
    _sum += value;
    if (value < _min) _min = value;
    if (value > _max) _max = value;
    // Welford's online algorithm
    final delta = value - _mean;
    _mean += delta / _count;
    final delta2 = value - _mean;
    _m2 += delta * delta2;
  }

  double get mean {
    if (_count == 0) throw StateError('No data');
    return _mean;
  }

  double get variance {
    if (_count < 2) throw StateError('Need at least 2 values');
    return _m2 / (_count - 1);
  }

  double get stdDev => _count < 2 ? 0.0 : _sqrt(variance);

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double g = x / 2;
    for (int i = 0; i < 50; i++) g = (g + x / g) / 2;
    return g;
  }

  double get min => _count == 0 ? double.infinity : _min;
  double get max => _count == 0 ? double.negativeInfinity : _max;
  double get sum => _sum;
  double get range => _count == 0 ? 0 : _max - _min;

  void reset() {
    _count = 0;
    _mean = 0;
    _m2 = 0;
    _min = double.infinity;
    _max = double.negativeInfinity;
    _sum = 0;
  }

  @override
  String toString() => isEmpty
      ? 'GchRunningStats(empty)'
      : 'GchRunningStats(n=$_count, mean=${_mean.toStringAsFixed(4)}, '
          'min=$_min, max=$_max)';
}
