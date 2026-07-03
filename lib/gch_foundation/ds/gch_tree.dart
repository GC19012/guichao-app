// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:collection';
import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// GchBSTNode – binary search tree node
// ─────────────────────────────────────────────────────────────────────────────
class GchBSTNode<T extends Comparable<T>> {
  T value;
  GchBSTNode<T>? left;
  GchBSTNode<T>? right;

  GchBSTNode(this.value);

  @override
  String toString() => 'BSTNode($value)';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchBST – binary search tree
// ─────────────────────────────────────────────────────────────────────────────
class GchBST<T extends Comparable<T>> {
  GchBSTNode<T>? _root;
  int _size = 0;

  int get size => _size;
  bool get isEmpty => _size == 0;

  void insert(T value) {
    _root = _insertNode(_root, value);
  }

  GchBSTNode<T> _insertNode(GchBSTNode<T>? node, T value) {
    if (node == null) {
      _size++;
      return GchBSTNode<T>(value);
    }
    final cmp = value.compareTo(node.value);
    if (cmp < 0) {
      node.left = _insertNode(node.left, value);
    } else if (cmp > 0) {
      node.right = _insertNode(node.right, value);
    }
    return node;
  }

  bool remove(T value) {
    final before = _size;
    _root = _removeNode(_root, value);
    return _size < before;
  }

  GchBSTNode<T>? _removeNode(GchBSTNode<T>? node, T value) {
    if (node == null) return null;
    final cmp = value.compareTo(node.value);
    if (cmp < 0) {
      node.left = _removeNode(node.left, value);
    } else if (cmp > 0) {
      node.right = _removeNode(node.right, value);
    } else {
      _size--;
      if (node.left == null) return node.right;
      if (node.right == null) return node.left;
      final minNode = _minNode(node.right!);
      node.value = minNode.value;
      _size++;
      node.right = _removeNode(node.right, minNode.value);
    }
    return node;
  }

  bool search(T value) => _searchNode(_root, value);

  bool _searchNode(GchBSTNode<T>? node, T value) {
    if (node == null) return false;
    final cmp = value.compareTo(node.value);
    if (cmp == 0) return true;
    if (cmp < 0) return _searchNode(node.left, value);
    return _searchNode(node.right, value);
  }

  bool contains(T value) => search(value);

  // inorder traversal – returns sorted list
  List<T> inorder() {
    final result = <T>[];
    _inorder(_root, result);
    return result;
  }

  void _inorder(GchBSTNode<T>? node, List<T> result) {
    if (node == null) return;
    _inorder(node.left, result);
    result.add(node.value);
    _inorder(node.right, result);
  }

  // preorder traversal
  List<T> preorder() {
    final result = <T>[];
    _preorder(_root, result);
    return result;
  }

  void _preorder(GchBSTNode<T>? node, List<T> result) {
    if (node == null) return;
    result.add(node.value);
    _preorder(node.left, result);
    _preorder(node.right, result);
  }

  // postorder traversal
  List<T> postorder() {
    final result = <T>[];
    _postorder(_root, result);
    return result;
  }

  void _postorder(GchBSTNode<T>? node, List<T> result) {
    if (node == null) return;
    _postorder(node.left, result);
    _postorder(node.right, result);
    result.add(node.value);
  }

  // level order (BFS)
  List<List<T>> levelOrder() {
    if (_root == null) return [];
    final result = <List<T>>[];
    final queue = Queue<GchBSTNode<T>>();
    queue.add(_root!);
    while (queue.isNotEmpty) {
      final levelSize = queue.length;
      final level = <T>[];
      for (int i = 0; i < levelSize; i++) {
        final node = queue.removeFirst();
        level.add(node.value);
        if (node.left != null) queue.add(node.left!);
        if (node.right != null) queue.add(node.right!);
      }
      result.add(level);
    }
    return result;
  }

  int height() => _height(_root);

  int _height(GchBSTNode<T>? node) {
    if (node == null) return 0;
    return 1 + max(_height(node.left), _height(node.right));
  }

  bool isBalanced() => _isBalancedNode(_root) != -1;

  int _isBalancedNode(GchBSTNode<T>? node) {
    if (node == null) return 0;
    final left = _isBalancedNode(node.left);
    if (left == -1) return -1;
    final right = _isBalancedNode(node.right);
    if (right == -1) return -1;
    if ((left - right).abs() > 1) return -1;
    return 1 + max(left, right);
  }

  T? minValue() => _root == null ? null : _minNode(_root!).value;
  T? maxValue() => _root == null ? null : _maxNode(_root!).value;

  GchBSTNode<T> _minNode(GchBSTNode<T> node) {
    while (node.left != null) {
      node = node.left!;
    }
    return node;
  }

  GchBSTNode<T> _maxNode(GchBSTNode<T> node) {
    while (node.right != null) {
      node = node.right!;
    }
    return node;
  }

  // successor – smallest value greater than value
  T? successor(T value) {
    GchBSTNode<T>? current = _root;
    GchBSTNode<T>? successor;
    while (current != null) {
      final cmp = value.compareTo(current.value);
      if (cmp < 0) {
        successor = current;
        current = current.left;
      } else {
        current = current.right;
      }
    }
    return successor?.value;
  }

  // predecessor – largest value less than value
  T? predecessor(T value) {
    GchBSTNode<T>? current = _root;
    GchBSTNode<T>? predecessor;
    while (current != null) {
      final cmp = value.compareTo(current.value);
      if (cmp > 0) {
        predecessor = current;
        current = current.right;
      } else {
        current = current.left;
      }
    }
    return predecessor?.value;
  }

  List<T> toSortedList() => inorder();

  static GchBST<T> fromSortedList<T extends Comparable<T>>(List<T> sorted) {
    final bst = GchBST<T>();
    if (sorted.isEmpty) return bst;
    bst._root = _buildBalanced(sorted, 0, sorted.length - 1);
    bst._size = sorted.length;
    return bst;
  }

  static GchBSTNode<T> _buildBalanced<T extends Comparable<T>>(
      List<T> list, int start, int end) {
    final mid = (start + end) ~/ 2;
    final node = GchBSTNode<T>(list[mid]);
    if (start < mid) node.left = _buildBalanced(list, start, mid - 1);
    if (mid < end) node.right = _buildBalanced(list, mid + 1, end);
    return node;
  }

  void clear() {
    _root = null;
    _size = 0;
  }

  @override
  String toString() => 'GchBST(size=$_size, height=${height()})';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchAVLNode – AVL tree node
// ─────────────────────────────────────────────────────────────────────────────
class GchAVLNode<T extends Comparable<T>> {
  T value;
  GchAVLNode<T>? left;
  GchAVLNode<T>? right;
  int height;

  GchAVLNode(this.value) : height = 1;
}

// ─────────────────────────────────────────────────────────────────────────────
// GchAVLTree – self-balancing AVL tree
// ─────────────────────────────────────────────────────────────────────────────
class GchAVLTree<T extends Comparable<T>> {
  GchAVLNode<T>? _root;
  int _size = 0;

  int get size => _size;
  bool get isEmpty => _size == 0;

  int _nodeHeight(GchAVLNode<T>? node) => node?.height ?? 0;

  void _updateHeight(GchAVLNode<T> node) {
    node.height = 1 + max(_nodeHeight(node.left), _nodeHeight(node.right));
  }

  int _balanceFactor(GchAVLNode<T>? node) {
    if (node == null) return 0;
    return _nodeHeight(node.left) - _nodeHeight(node.right);
  }

  GchAVLNode<T> _rotateRight(GchAVLNode<T> y) {
    final x = y.left!;
    final t2 = x.right;
    x.right = y;
    y.left = t2;
    _updateHeight(y);
    _updateHeight(x);
    return x;
  }

  GchAVLNode<T> _rotateLeft(GchAVLNode<T> x) {
    final y = x.right!;
    final t2 = y.left;
    y.left = x;
    x.right = t2;
    _updateHeight(x);
    _updateHeight(y);
    return y;
  }

  GchAVLNode<T> _rotateLeftRight(GchAVLNode<T> node) {
    node.left = _rotateLeft(node.left!);
    return _rotateRight(node);
  }

  GchAVLNode<T> _rotateRightLeft(GchAVLNode<T> node) {
    node.right = _rotateRight(node.right!);
    return _rotateLeft(node);
  }

  GchAVLNode<T> _balance(GchAVLNode<T> node) {
    _updateHeight(node);
    final bf = _balanceFactor(node);
    if (bf > 1) {
      if (_balanceFactor(node.left) < 0) {
        return _rotateLeftRight(node);
      }
      return _rotateRight(node);
    }
    if (bf < -1) {
      if (_balanceFactor(node.right) > 0) {
        return _rotateRightLeft(node);
      }
      return _rotateLeft(node);
    }
    return node;
  }

  void insert(T value) {
    _root = _insert(_root, value);
  }

  GchAVLNode<T> _insert(GchAVLNode<T>? node, T value) {
    if (node == null) {
      _size++;
      return GchAVLNode<T>(value);
    }
    final cmp = value.compareTo(node.value);
    if (cmp < 0) {
      node.left = _insert(node.left, value);
    } else if (cmp > 0) {
      node.right = _insert(node.right, value);
    } else {
      return node; // duplicate: ignore
    }
    return _balance(node);
  }

  bool remove(T value) {
    final before = _size;
    _root = _remove(_root, value);
    return _size < before;
  }

  GchAVLNode<T>? _remove(GchAVLNode<T>? node, T value) {
    if (node == null) return null;
    final cmp = value.compareTo(node.value);
    if (cmp < 0) {
      node.left = _remove(node.left, value);
    } else if (cmp > 0) {
      node.right = _remove(node.right, value);
    } else {
      _size--;
      if (node.left == null) return node.right;
      if (node.right == null) return node.left;
      final minNode = _minNode(node.right!);
      node.value = minNode.value;
      _size++;
      node.right = _remove(node.right, minNode.value);
    }
    return _balance(node);
  }

  GchAVLNode<T> _minNode(GchAVLNode<T> node) {
    while (node.left != null) {
      node = node.left!;
    }
    return node;
  }

  bool search(T value) => _search(_root, value);

  bool _search(GchAVLNode<T>? node, T value) {
    if (node == null) return false;
    final cmp = value.compareTo(node.value);
    if (cmp == 0) return true;
    if (cmp < 0) return _search(node.left, value);
    return _search(node.right, value);
  }

  bool contains(T value) => search(value);

  List<T> toSortedList() {
    final result = <T>[];
    _inorder(_root, result);
    return result;
  }

  void _inorder(GchAVLNode<T>? node, List<T> result) {
    if (node == null) return;
    _inorder(node.left, result);
    result.add(node.value);
    _inorder(node.right, result);
  }

  int height() => _nodeHeight(_root);

  bool isBalanced() => (_balanceFactor(_root)).abs() <= 1;

  T? minValue() {
    if (_root == null) return null;
    return _minNode(_root!).value;
  }

  T? maxValue() {
    if (_root == null) return null;
    GchAVLNode<T> node = _root!;
    while (node.right != null) node = node.right!;
    return node.value;
  }

  void clear() {
    _root = null;
    _size = 0;
  }

  @override
  String toString() => 'GchAVLTree(size=$_size, height=${height()})';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchTrieNode – trie node
// ─────────────────────────────────────────────────────────────────────────────
class GchTrieNode {
  Map<String, GchTrieNode> children = {};
  bool isEnd = false;
  int passCount = 0; // how many words pass through this node

  GchTrieNode();
}

// ─────────────────────────────────────────────────────────────────────────────
// GchTrie – prefix trie
// ─────────────────────────────────────────────────────────────────────────────
class GchTrie {
  final GchTrieNode _root = GchTrieNode();
  int _wordCount = 0;

  int get countWords => _wordCount;
  bool get isEmpty => _wordCount == 0;

  void insert(String word) {
    GchTrieNode current = _root;
    for (int i = 0; i < word.length; i++) {
      final ch = word[i];
      current.children.putIfAbsent(ch, () => GchTrieNode());
      current = current.children[ch]!;
      current.passCount++;
    }
    if (!current.isEnd) {
      current.isEnd = true;
      _wordCount++;
    }
  }

  bool search(String word) {
    final node = _findNode(word);
    return node != null && node.isEnd;
  }

  bool startsWith(String prefix) {
    return _findNode(prefix) != null;
  }

  GchTrieNode? _findNode(String s) {
    GchTrieNode current = _root;
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (!current.children.containsKey(ch)) return null;
      current = current.children[ch]!;
    }
    return current;
  }

  bool delete(String word) {
    if (!search(word)) return false;
    _deleteHelper(_root, word, 0);
    _wordCount--;
    return true;
  }

  bool _deleteHelper(GchTrieNode node, String word, int depth) {
    if (depth == word.length) {
      node.isEnd = false;
      return node.children.isEmpty;
    }
    final ch = word[depth];
    final child = node.children[ch];
    if (child == null) return false;
    child.passCount--;
    final shouldDelete = _deleteHelper(child, word, depth + 1);
    if (shouldDelete) {
      node.children.remove(ch);
      return node.children.isEmpty && !node.isEnd;
    }
    return false;
  }

  List<String> allWords() {
    final result = <String>[];
    _collectWords(_root, StringBuffer(), result);
    return result;
  }

  void _collectWords(GchTrieNode node, StringBuffer prefix, List<String> result) {
    if (node.isEnd) result.add(prefix.toString());
    for (final entry in node.children.entries) {
      prefix.write(entry.key);
      _collectWords(entry.value, prefix, result);
      prefix.deleteCharAt(prefix.length - 1);
    }
  }

  List<String> wordsWithPrefix(String prefix) {
    final node = _findNode(prefix);
    if (node == null) return [];
    final result = <String>[];
    _collectWords(node, StringBuffer(prefix), result);
    return result;
  }

  // longestPrefix – longest word in trie that is a prefix of the input
  String longestPrefix(String word) {
    GchTrieNode current = _root;
    String longest = '';
    for (int i = 0; i < word.length; i++) {
      final ch = word[i];
      if (!current.children.containsKey(ch)) break;
      current = current.children[ch]!;
      if (current.isEnd) longest = word.substring(0, i + 1);
    }
    return longest;
  }

  // autocomplete – returns up to [limit] words with prefix
  List<String> autocomplete(String prefix, {int limit = 10}) {
    final words = wordsWithPrefix(prefix);
    if (words.length <= limit) return words;
    return words.sublist(0, limit);
  }

  // countWithPrefix – count words that start with prefix
  int countWithPrefix(String prefix) {
    final node = _findNode(prefix);
    if (node == null) return 0;
    int cnt = 0;
    final stack = <GchTrieNode>[node];
    while (stack.isNotEmpty) {
      final n = stack.removeLast();
      if (n.isEnd) cnt++;
      stack.addAll(n.children.values);
    }
    return cnt;
  }

  // replaceWord – if word exists, replace with newWord
  bool replaceWord(String word, String newWord) {
    if (!search(word)) return false;
    delete(word);
    insert(newWord);
    return true;
  }

  void clear() {
    _root.children.clear();
    _root.isEnd = false;
    _root.passCount = 0;
    _wordCount = 0;
  }

  @override
  String toString() => 'GchTrie(words=$_wordCount)';
}

extension on StringBuffer {
  void deleteCharAt(int index) {
    final s = toString();
    clear();
    write(s.substring(0, index));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preset word constants (50+ words for testing)
// ─────────────────────────────────────────────────────────────────────────────
const List<String> kSampleWords = [
  'apple', 'application', 'apply', 'apt', 'banana', 'band', 'bandana',
  'cat', 'car', 'card', 'care', 'careful', 'carpenter', 'carpet',
  'dart', 'data', 'database', 'date', 'dog', 'door', 'double',
  'elephant', 'element', 'else', 'email', 'empty', 'enable', 'end',
  'flutter', 'flute', 'fly', 'focus', 'fold', 'follow', 'food',
  'garden', 'gate', 'gather', 'general', 'get', 'give', 'global',
  'happy', 'hard', 'hash', 'have', 'head', 'heap', 'help', 'high',
  'index', 'inner', 'input', 'insert', 'integer', 'interval',
  'java', 'join', 'just', 'key', 'keyword', 'kind', 'link', 'list',
  'map', 'match', 'matrix', 'max', 'merge', 'method', 'min', 'mode',
  'node', 'null', 'number', 'object', 'open', 'order', 'output',
  'package', 'pair', 'param', 'parse', 'path', 'pattern', 'pointer',
  'queue', 'quick', 'range', 'read', 'reduce', 'remove', 'return',
  'search', 'set', 'size', 'sort', 'split', 'stack', 'start', 'string',
  'table', 'target', 'tree', 'type', 'unique', 'update', 'value', 'vector',
  'weight', 'word', 'write', 'zero', 'zone',
];

const List<int> kTreeTestData = [
  50, 25, 75, 12, 37, 62, 87, 6, 18, 31,
  43, 56, 68, 81, 93, 3, 9, 15, 21, 28,
  34, 40, 46, 53, 59, 65, 71, 78, 84, 90,
  96, 1, 4, 7, 10, 13, 16, 19, 22, 26,
  29, 32, 35, 38, 41, 44, 47, 51, 54, 57,
];

const List<int> kTreeTestData2 = [
  100, 80, 120, 60, 90, 110, 130, 40, 70, 85,
  95, 105, 115, 125, 135, 20, 30, 50, 65, 75,
  82, 88, 92, 98, 102, 108, 112, 118, 122, 128,
  132, 138, 10, 15, 25, 35, 45, 55, 68, 72,
  78, 83, 86, 89, 93, 97, 101, 104, 107, 111,
];

// ─────────────────────────────────────────────────────────────────────────────
// GchSegmentTree – segment tree for range queries
// ─────────────────────────────────────────────────────────────────────────────
class GchSegmentTree {
  final List<int> _tree;
  final List<int> _data;
  final int _n;

  GchSegmentTree(List<int> data)
      : _n = data.length,
        _data = List<int>.from(data),
        _tree = List<int>.filled(4 * data.length, 0) {
    if (data.isNotEmpty) _build(0, 0, data.length - 1);
  }

  void _build(int node, int start, int end) {
    if (start == end) {
      _tree[node] = _data[start];
      return;
    }
    final mid = (start + end) ~/ 2;
    _build(2 * node + 1, start, mid);
    _build(2 * node + 2, mid + 1, end);
    _tree[node] = _tree[2 * node + 1] + _tree[2 * node + 2];
  }

  // rangeSum – sum of elements in [l, r] inclusive
  int rangeSum(int l, int r) {
    if (l < 0 || r >= _n || l > r) throw RangeError('Invalid range [$l, $r]');
    return _querySum(0, 0, _n - 1, l, r);
  }

  int _querySum(int node, int start, int end, int l, int r) {
    if (r < start || end < l) return 0;
    if (l <= start && end <= r) return _tree[node];
    final mid = (start + end) ~/ 2;
    return _querySum(2 * node + 1, start, mid, l, r) +
        _querySum(2 * node + 2, mid + 1, end, l, r);
  }

  // pointUpdate – update element at index [i] to [value]
  void pointUpdate(int i, int value) {
    if (i < 0 || i >= _n) throw RangeError.index(i, _data);
    _data[i] = value;
    _updateNode(0, 0, _n - 1, i, value);
  }

  void _updateNode(int node, int start, int end, int i, int value) {
    if (start == end) {
      _tree[node] = value;
      return;
    }
    final mid = (start + end) ~/ 2;
    if (i <= mid) {
      _updateNode(2 * node + 1, start, mid, i, value);
    } else {
      _updateNode(2 * node + 2, mid + 1, end, i, value);
    }
    _tree[node] = _tree[2 * node + 1] + _tree[2 * node + 2];
  }

  // rangeMin – minimum element in [l, r]
  int rangeMin(int l, int r) {
    if (l < 0 || r >= _n || l > r) throw RangeError('Invalid range');
    return _queryMin(0, 0, _n - 1, l, r);
  }

  int _queryMin(int node, int start, int end, int l, int r) {
    if (r < start || end < l) return 0x7FFFFFFF;
    if (l <= start && end <= r) return _tree[node];
    final mid = (start + end) ~/ 2;
    final leftMin = _queryMin(2 * node + 1, start, mid, l, r);
    final rightMin = _queryMin(2 * node + 2, mid + 1, end, l, r);
    return leftMin < rightMin ? leftMin : rightMin;
  }

  // rangeMax – maximum element in [l, r]
  int rangeMax(int l, int r) {
    if (l < 0 || r >= _n || l > r) throw RangeError('Invalid range');
    return _queryMax(0, 0, _n - 1, l, r);
  }

  int _queryMax(int node, int start, int end, int l, int r) {
    if (r < start || end < l) return -0x7FFFFFFF;
    if (l <= start && end <= r) return _tree[node];
    final mid = (start + end) ~/ 2;
    final leftMax = _queryMax(2 * node + 1, start, mid, l, r);
    final rightMax = _queryMax(2 * node + 2, mid + 1, end, l, r);
    return leftMax > rightMax ? leftMax : rightMax;
  }

  int get size => _n;

  List<int> toList() => List<int>.from(_data);

  @override
  String toString() => 'GchSegmentTree(n=$_n)';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchFenwickTree (Binary Indexed Tree) – point updates, prefix sum queries
// ─────────────────────────────────────────────────────────────────────────────
class GchFenwickTree {
  final List<int> _tree;
  final int _n;

  GchFenwickTree(int n)
      : _n = n,
        _tree = List<int>.filled(n + 1, 0);

  GchFenwickTree.fromList(List<int> data)
      : _n = data.length,
        _tree = List<int>.filled(data.length + 1, 0) {
    for (int i = 0; i < data.length; i++) {
      update(i, data[i]);
    }
  }

  // update – add [delta] to element at index [i] (0-based)
  void update(int i, int delta) {
    int idx = i + 1;
    while (idx <= _n) {
      _tree[idx] += delta;
      idx += idx & (-idx);
    }
  }

  // prefixSum – sum of elements from index 0 to [i] inclusive (0-based)
  int prefixSum(int i) {
    int sum = 0;
    int idx = i + 1;
    while (idx > 0) {
      sum += _tree[idx];
      idx -= idx & (-idx);
    }
    return sum;
  }

  // rangeSum – sum from [l] to [r] inclusive (0-based)
  int rangeSum(int l, int r) {
    if (l > r) return 0;
    final right = prefixSum(r);
    final left = l > 0 ? prefixSum(l - 1) : 0;
    return right - left;
  }

  // pointSet – set element at index [i] to [value] (requires original value)
  void pointSet(int i, int oldValue, int newValue) {
    update(i, newValue - oldValue);
  }

  int get size => _n;

  @override
  String toString() => 'GchFenwickTree(n=$_n)';
}

// ─────────────────────────────────────────────────────────────────────────────
// GchRedBlackNode – red-black tree node (simplified)
// ─────────────────────────────────────────────────────────────────────────────
enum _RBColor { red, black }

class GchRedBlackNode<T extends Comparable<T>> {
  T value;
  GchRedBlackNode<T>? left;
  GchRedBlackNode<T>? right;
  GchRedBlackNode<T>? parent;
  _RBColor color;

  GchRedBlackNode(this.value, {this.color = _RBColor.red});

  bool get isRed => color == _RBColor.red;
  bool get isBlack => color == _RBColor.black;
}

// ─────────────────────────────────────────────────────────────────────────────
// GchNaryTree – N-ary tree (each node can have multiple children)
// ─────────────────────────────────────────────────────────────────────────────
class GchNaryNode<T> {
  T value;
  List<GchNaryNode<T>> children;

  GchNaryNode(this.value) : children = [];

  void addChild(GchNaryNode<T> child) => children.add(child);

  void removeChild(GchNaryNode<T> child) => children.remove(child);

  bool get isLeaf => children.isEmpty;
  int get degree => children.length;
}

class GchNaryTree<T> {
  GchNaryNode<T>? root;

  GchNaryTree({T? rootValue})
      : root = rootValue != null ? GchNaryNode<T>(rootValue) : null;

  // BFS level-order traversal
  List<T> levelOrder() {
    if (root == null) return [];
    final result = <T>[];
    final queue = Queue<GchNaryNode<T>>();
    queue.add(root!);
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      result.add(node.value);
      for (final child in node.children) {
        queue.add(child);
      }
    }
    return result;
  }

  // DFS preorder traversal
  List<T> preorder() {
    final result = <T>[];
    _preorderHelper(root, result);
    return result;
  }

  void _preorderHelper(GchNaryNode<T>? node, List<T> result) {
    if (node == null) return;
    result.add(node.value);
    for (final child in node.children) {
      _preorderHelper(child, result);
    }
  }

  // DFS postorder traversal
  List<T> postorder() {
    final result = <T>[];
    _postorderHelper(root, result);
    return result;
  }

  void _postorderHelper(GchNaryNode<T>? node, List<T> result) {
    if (node == null) return;
    for (final child in node.children) {
      _postorderHelper(child, result);
    }
    result.add(node.value);
  }

  int height() => _heightHelper(root);

  int _heightHelper(GchNaryNode<T>? node) {
    if (node == null) return 0;
    if (node.isLeaf) return 1;
    int maxH = 0;
    for (final child in node.children) {
      final h = _heightHelper(child);
      if (h > maxH) maxH = h;
    }
    return 1 + maxH;
  }

  int size() => _sizeHelper(root);

  int _sizeHelper(GchNaryNode<T>? node) {
    if (node == null) return 0;
    int count = 1;
    for (final child in node.children) {
      count += _sizeHelper(child);
    }
    return count;
  }

  // find by value (BFS)
  GchNaryNode<T>? find(T value) {
    if (root == null) return null;
    final queue = Queue<GchNaryNode<T>>();
    queue.add(root!);
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      if (node.value == value) return node;
      for (final child in node.children) {
        queue.add(child);
      }
    }
    return null;
  }

  // leaves – all leaf nodes
  List<T> leaves() {
    final result = <T>[];
    _leavesHelper(root, result);
    return result;
  }

  void _leavesHelper(GchNaryNode<T>? node, List<T> result) {
    if (node == null) return;
    if (node.isLeaf) {
      result.add(node.value);
      return;
    }
    for (final child in node.children) {
      _leavesHelper(child, result);
    }
  }

  // pathToNode – returns path from root to node with given value
  List<T>? pathToNode(T target) {
    final path = <T>[];
    if (_findPath(root, target, path)) return path;
    return null;
  }

  bool _findPath(GchNaryNode<T>? node, T target, List<T> path) {
    if (node == null) return false;
    path.add(node.value);
    if (node.value == target) return true;
    for (final child in node.children) {
      if (_findPath(child, target, path)) return true;
    }
    path.removeLast();
    return false;
  }

  @override
  String toString() => 'GchNaryTree(size=${size()}, height=${height()})';
}
