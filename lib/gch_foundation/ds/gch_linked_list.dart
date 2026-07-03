// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:collection';
import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// GchNode – doubly-linked list node
// ─────────────────────────────────────────────────────────────────────────────
class GchNode<T> {
  T value;
  GchNode<T>? next;
  GchNode<T>? prev;

  GchNode(this.value, {this.next, this.prev});

  @override
  String toString() => 'GchNode($value)';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchLinkedList – doubly-linked list
// ─────────────────────────────────────────────────────────────────────────────
class GchLinkedList<T> extends Iterable<T> {
  GchNode<T>? _head;
  GchNode<T>? _tail;
  int _length = 0;

  GchLinkedList();

  int get length => _length;
  bool get isEmpty => _length == 0;
  bool get isNotEmpty => _length > 0;
  GchNode<T>? get head => _head;
  GchNode<T>? get tail => _tail;

  // addFirst
  void addFirst(T value) {
    final node = GchNode<T>(value);
    if (_head == null) {
      _head = node;
      _tail = node;
    } else {
      node.next = _head;
      _head!.prev = node;
      _head = node;
    }
    _length++;
  }

  // addLast
  void addLast(T value) {
    final node = GchNode<T>(value);
    if (_tail == null) {
      _head = node;
      _tail = node;
    } else {
      node.prev = _tail;
      _tail!.next = node;
      _tail = node;
    }
    _length++;
  }

  // addAt – insert before the node currently at [index]
  void addAt(int index, T value) {
    _rangeCheckInsert(index);
    if (index == 0) {
      addFirst(value);
      return;
    }
    if (index == _length) {
      addLast(value);
      return;
    }
    final current = _nodeAt(index);
    final node = GchNode<T>(value, next: current, prev: current!.prev);
    current.prev!.next = node;
    current.prev = node;
    _length++;
  }

  // removeFirst
  T removeFirst() {
    _assertNotEmpty();
    final value = _head!.value;
    if (_head == _tail) {
      _head = null;
      _tail = null;
    } else {
      _head = _head!.next;
      _head!.prev = null;
    }
    _length--;
    return value;
  }

  // removeLast
  T removeLast() {
    _assertNotEmpty();
    final value = _tail!.value;
    if (_head == _tail) {
      _head = null;
      _tail = null;
    } else {
      _tail = _tail!.prev;
      _tail!.next = null;
    }
    _length--;
    return value;
  }

  // removeAt
  T removeAt(int index) {
    _rangeCheck(index);
    if (index == 0) return removeFirst();
    if (index == _length - 1) return removeLast();
    final node = _nodeAt(index)!;
    node.prev!.next = node.next;
    node.next!.prev = node.prev;
    _length--;
    return node.value;
  }

  // remove by value (first occurrence)
  bool remove(T value) {
    GchNode<T>? current = _head;
    while (current != null) {
      if (current.value == value) {
        if (current == _head) {
          removeFirst();
        } else if (current == _tail) {
          removeLast();
        } else {
          current.prev!.next = current.next;
          current.next!.prev = current.prev;
          _length--;
        }
        return true;
      }
      current = current.next;
    }
    return false;
  }

  // contains
  @override
  bool contains(Object? value) {
    GchNode<T>? current = _head;
    while (current != null) {
      if (current.value == value) return true;
      current = current.next;
    }
    return false;
  }

  // indexOf (first occurrence)
  int indexOf(T value) {
    GchNode<T>? current = _head;
    int index = 0;
    while (current != null) {
      if (current.value == value) return index;
      current = current.next;
      index++;
    }
    return -1;
  }

  // get element at index
  T get(int index) {
    _rangeCheck(index);
    return _nodeAt(index)!.value;
  }

  // operator[]
  T operator [](int index) => get(index);

  // toList
  @override
  List<T> toList({bool growable = true}) {
    final result = <T>[];
    GchNode<T>? current = _head;
    while (current != null) {
      result.add(current.value);
      current = current.next;
    }
    return growable ? result : List.unmodifiable(result);
  }

  // fromList (static factory)
  static GchLinkedList<T> fromList<T>(List<T> list) {
    final ll = GchLinkedList<T>();
    for (final item in list) {
      ll.addLast(item);
    }
    return ll;
  }

  // reverse in-place
  void reverse() {
    GchNode<T>? current = _head;
    GchNode<T>? temp;
    _tail = _head;
    while (current != null) {
      temp = current.prev;
      current.prev = current.next;
      current.next = temp;
      current = current.prev;
    }
    if (temp != null) {
      _head = temp.prev;
    }
  }

  // sort using comparator
  void sort([int Function(T a, T b)? comparator]) {
    if (_length <= 1) return;
    final list = toList();
    if (comparator != null) {
      list.sort(comparator);
    } else {
      list.sort((a, b) => (a as Comparable).compareTo(b));
    }
    GchNode<T>? current = _head;
    for (final item in list) {
      current!.value = item;
      current = current.next;
    }
  }

  // Iterable<T> iterator implementation
  @override
  Iterator<T> get iterator => _GchLinkedListIterator<T>(_head);

  // clear all elements
  void clear() {
    _head = null;
    _tail = null;
    _length = 0;
  }

  // set element at index
  void set(int index, T value) {
    _rangeCheck(index);
    _nodeAt(index)!.value = value;
  }

  // swap two elements by index
  void swap(int i, int j) {
    if (i == j) return;
    _rangeCheck(i);
    _rangeCheck(j);
    final nodeI = _nodeAt(i)!;
    final nodeJ = _nodeAt(j)!;
    final temp = nodeI.value;
    nodeI.value = nodeJ.value;
    nodeJ.value = temp;
  }

  // subList from [start] to [end] exclusive
  GchLinkedList<T> subList(int start, int end) {
    if (start < 0 || end > _length || start > end) {
      throw RangeError('Invalid range: $start..$end for length $_length');
    }
    final result = GchLinkedList<T>();
    GchNode<T>? current = _nodeAt(start);
    for (int i = start; i < end; i++) {
      result.addLast(current!.value);
      current = current.next;
    }
    return result;
  }

  // count occurrences of value
  int count(T value) {
    int cnt = 0;
    GchNode<T>? current = _head;
    while (current != null) {
      if (current.value == value) cnt++;
      current = current.next;
    }
    return cnt;
  }

  // map each element to a new list
  GchLinkedList<R> mapElements<R>(R Function(T) f) {
    final result = GchLinkedList<R>();
    GchNode<T>? current = _head;
    while (current != null) {
      result.addLast(f(current.value));
      current = current.next;
    }
    return result;
  }

  // filter elements
  GchLinkedList<T> filterElements(bool Function(T) predicate) {
    final result = GchLinkedList<T>();
    GchNode<T>? current = _head;
    while (current != null) {
      if (predicate(current.value)) result.addLast(current.value);
      current = current.next;
    }
    return result;
  }

  // reduce
  T reduceElements(T Function(T acc, T element) combine) {
    _assertNotEmpty();
    T acc = _head!.value;
    GchNode<T>? current = _head!.next;
    while (current != null) {
      acc = combine(acc, current.value);
      current = current.next;
    }
    return acc;
  }

  // merge another list to the end
  void merge(GchLinkedList<T> other) {
    GchNode<T>? current = other._head;
    while (current != null) {
      addLast(current.value);
      current = current.next;
    }
  }

  // rotate left by n positions
  void rotateLeftBy(int n) {
    if (_length <= 1 || n == 0) return;
    n = n % _length;
    if (n == 0) return;
    for (int i = 0; i < n; i++) {
      addLast(removeFirst());
    }
  }

  // rotate right by n positions
  void rotateRightBy(int n) {
    if (_length <= 1 || n == 0) return;
    n = n % _length;
    if (n == 0) return;
    for (int i = 0; i < n; i++) {
      addFirst(removeLast());
    }
  }

  @override
  String toString() => 'GchLinkedList(${toList()})';

  // ── private helpers ─────────────────────────────────────────────────────
  GchNode<T>? _nodeAt(int index) {
    if (index < _length ~/ 2) {
      GchNode<T>? current = _head;
      for (int i = 0; i < index; i++) {
        current = current!.next;
      }
      return current;
    } else {
      GchNode<T>? current = _tail;
      for (int i = _length - 1; i > index; i--) {
        current = current!.prev;
      }
      return current;
    }
  }

  void _rangeCheck(int index) {
    if (index < 0 || index >= _length) {
      throw RangeError.index(index, this, 'index', null, _length);
    }
  }

  void _rangeCheckInsert(int index) {
    if (index < 0 || index > _length) {
      throw RangeError('Insert index $index out of range [0, $_length]');
    }
  }

  void _assertNotEmpty() {
    if (isEmpty) throw StateError('List is empty');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Iterator
// ─────────────────────────────────────────────────────────────────────────────
class _GchLinkedListIterator<T> implements Iterator<T> {
  GchNode<T>? _current;
  bool _started = false;

  _GchLinkedListIterator(GchNode<T>? head) : _current = head;

  @override
  T get current => _current!.value;

  @override
  bool moveNext() {
    if (!_started) {
      _started = true;
      return _current != null;
    }
    if (_current?.next != null) {
      _current = _current!.next;
      return true;
    }
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GchCircularList – circular doubly-linked list
// ─────────────────────────────────────────────────────────────────────────────
class GchCircularList<T> {
  GchNode<T>? _head;
  int _length = 0;

  int get length => _length;
  bool get isEmpty => _length == 0;

  void addLast(T value) {
    final node = GchNode<T>(value);
    if (_head == null) {
      _head = node;
      node.next = node;
      node.prev = node;
    } else {
      final tail = _head!.prev!;
      tail.next = node;
      node.prev = tail;
      node.next = _head;
      _head!.prev = node;
    }
    _length++;
  }

  void addFirst(T value) {
    addLast(value);
    _head = _head!.prev;
  }

  // addAfter – insert after the first node with the given value
  bool addAfter(T target, T value) {
    if (_head == null) return false;
    GchNode<T>? current = _head;
    for (int i = 0; i < _length; i++) {
      if (current!.value == target) {
        final node = GchNode<T>(value);
        node.next = current.next;
        node.prev = current;
        current.next!.prev = node;
        current.next = node;
        if (current == _head!.prev) {
          // was tail, no special adjustment needed for circular
        }
        _length++;
        return true;
      }
      current = current!.next;
    }
    return false;
  }

  // addBefore – insert before the first node with the given value
  bool addBefore(T target, T value) {
    if (_head == null) return false;
    GchNode<T>? current = _head;
    for (int i = 0; i < _length; i++) {
      if (current!.value == target) {
        final node = GchNode<T>(value);
        node.next = current;
        node.prev = current.prev;
        current.prev!.next = node;
        current.prev = node;
        if (current == _head) _head = node;
        _length++;
        return true;
      }
      current = current!.next;
    }
    return false;
  }

  T removeFirst() {
    if (_head == null) throw StateError('Circular list is empty');
    final value = _head!.value;
    if (_length == 1) {
      _head = null;
    } else {
      final tail = _head!.prev!;
      _head = _head!.next;
      tail.next = _head;
      _head!.prev = tail;
    }
    _length--;
    return value;
  }

  bool contains(T value) {
    if (_head == null) return false;
    GchNode<T>? current = _head;
    for (int i = 0; i < _length; i++) {
      if (current!.value == value) return true;
      current = current!.next;
    }
    return false;
  }

  // rotateLeft by n steps
  void rotateLeft(int n) {
    if (_length <= 1 || n == 0) return;
    n = n % _length;
    for (int i = 0; i < n; i++) {
      _head = _head!.next;
    }
  }

  // rotateRight by n steps
  void rotateRight(int n) {
    if (_length <= 1 || n == 0) return;
    n = n % _length;
    for (int i = 0; i < n; i++) {
      _head = _head!.prev;
    }
  }

  List<T> toList() {
    final result = <T>[];
    if (_head == null) return result;
    GchNode<T>? current = _head;
    for (int i = 0; i < _length; i++) {
      result.add(current!.value);
      current = current!.next;
    }
    return result;
  }

  // josephus – solve the Josephus problem: every k-th person is eliminated
  // Returns the 0-based index of the survivor.
  int josephus(int k) {
    if (_length == 0) return -1;
    // Mathematical O(n) solution
    int pos = 0;
    for (int i = 2; i <= _length; i++) {
      pos = (pos + k) % i;
    }
    return pos;
  }

  // josephusOrder – returns the elimination order as a list of values
  List<T> josephusOrder(int k) {
    final order = <T>[];
    if (_head == null) return order;
    GchNode<T>? current = _head;
    int remaining = _length;
    while (remaining > 0) {
      for (int i = 1; i < k; i++) {
        current = current!.next;
      }
      order.add(current!.value);
      final next = current.next;
      if (remaining == 1) {
        _head = null;
      } else {
        current.prev!.next = current.next;
        current.next!.prev = current.prev;
        if (current == _head) _head = next;
      }
      current = next;
      remaining--;
    }
    _length = 0;
    return order;
  }

  @override
  String toString() => 'GchCircularList(${toList()})';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchSkipListNode
// ─────────────────────────────────────────────────────────────────────────────
class GchSkipListNode<T> {
  T? value;
  List<GchSkipListNode<T>?> forward;

  GchSkipListNode(this.value, int level)
      : forward = List<GchSkipListNode<T>?>.filled(level, null);
}

// ─────────────────────────────────────────────────────────────────────────────
// GchSkipList – probabilistic skip list
// ─────────────────────────────────────────────────────────────────────────────
class GchSkipList<T extends Comparable<T>> {
  static const int _maxLevel = 16;
  static const double _probability = 0.5;

  final GchSkipListNode<T> _header =
      GchSkipListNode<T>(null, _maxLevel);
  int _level = 1;
  int _size = 0;
  final Random _rng = Random(42);

  int get level => _level;
  int get size => _size;
  bool get isEmpty => _size == 0;

  int _randomLevel() {
    int lvl = 1;
    while (_rng.nextDouble() < _probability && lvl < _maxLevel) {
      lvl++;
    }
    return lvl;
  }

  void insert(T value) {
    final update = List<GchSkipListNode<T>?>.filled(_maxLevel, null);
    GchSkipListNode<T>? current = _header;

    for (int i = _level - 1; i >= 0; i--) {
      while (current!.forward[i] != null &&
          current.forward[i]!.value!.compareTo(value) < 0) {
        current = current.forward[i];
      }
      update[i] = current;
    }

    final newLevel = _randomLevel();
    if (newLevel > _level) {
      for (int i = _level; i < newLevel; i++) {
        update[i] = _header;
      }
      _level = newLevel;
    }

    final newNode = GchSkipListNode<T>(value, newLevel);
    for (int i = 0; i < newLevel; i++) {
      newNode.forward[i] = update[i]!.forward[i];
      update[i]!.forward[i] = newNode;
    }
    _size++;
  }

  bool remove(T value) {
    final update = List<GchSkipListNode<T>?>.filled(_maxLevel, null);
    GchSkipListNode<T>? current = _header;

    for (int i = _level - 1; i >= 0; i--) {
      while (current!.forward[i] != null &&
          current.forward[i]!.value!.compareTo(value) < 0) {
        current = current.forward[i];
      }
      update[i] = current;
    }

    current = current?.forward[0];
    if (current == null || current.value!.compareTo(value) != 0) return false;

    for (int i = 0; i < _level; i++) {
      if (update[i]!.forward[i] != current) break;
      update[i]!.forward[i] = current.forward[i];
    }

    while (_level > 1 && _header.forward[_level - 1] == null) {
      _level--;
    }
    _size--;
    return true;
  }

  GchSkipListNode<T>? search(T value) {
    GchSkipListNode<T>? current = _header;
    for (int i = _level - 1; i >= 0; i--) {
      while (current!.forward[i] != null &&
          current.forward[i]!.value!.compareTo(value) < 0) {
        current = current.forward[i];
      }
    }
    current = current?.forward[0];
    if (current != null && current.value!.compareTo(value) == 0) {
      return current;
    }
    return null;
  }

  bool contains(T value) => search(value) != null;

  List<T> toSortedList() {
    final result = <T>[];
    GchSkipListNode<T>? current = _header.forward[0];
    while (current != null) {
      result.add(current.value as T);
      current = current.forward[0];
    }
    return result;
  }

  @override
  String toString() => 'GchSkipList(size=$_size, level=$_level)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Preset test data constants (int lists for bulk testing)
// ─────────────────────────────────────────────────────────────────────────────
const List<int> kSampleInts50 = [
  42, 17, 83, 56, 29, 74, 11, 65, 38, 92,
  3,  88, 21, 47, 60, 15, 70, 34, 99, 6,
  51, 26, 79, 44, 13, 68, 37, 82, 9,  55,
  28, 73, 46, 19, 64, 31, 86, 5,  58, 23,
  77, 40, 95, 12, 67, 36, 81, 48, 16, 71,
];

const List<int> kSampleInts100 = [
  42, 17, 83, 56, 29, 74, 11, 65, 38, 92,
  3,  88, 21, 47, 60, 15, 70, 34, 99, 6,
  51, 26, 79, 44, 13, 68, 37, 82, 9,  55,
  28, 73, 46, 19, 64, 31, 86, 5,  58, 23,
  77, 40, 95, 12, 67, 36, 81, 48, 16, 71,
  50, 25, 75, 100, 33, 66, 1,  89, 43, 78,
  24, 57, 90, 8,  53, 20, 63, 96, 41, 76,
  14, 59, 84, 30, 69, 4,  49, 72, 35, 98,
  7,  52, 87, 22, 45, 80, 18, 61, 94, 27,
  62, 97, 32, 85, 10, 39, 91, 2,  54, 93,
];

const List<int> kPrimeSamples = [
  2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
  31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
  73, 79, 83, 89, 97, 101, 103, 107, 109, 113,
];

const List<int> kFibonacciSamples = [
  0, 1, 1, 2, 3, 5, 8, 13, 21, 34,
  55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181,
];

const List<double> kDoubleSamples = [
  1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.0,
  11.1, 12.2, 13.3, 14.4, 15.5, 16.6, 17.7, 18.8, 19.9, 20.0,
  21.1, 22.2, 23.3, 24.4, 25.5, 26.6, 27.7, 28.8, 29.9, 30.0,
];
