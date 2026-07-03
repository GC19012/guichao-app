// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:collection';
import 'dart:math';

extension GchMapExt<K, V> on Map<K, V> {
  V getOrDefault(K key, V defaultValue) {
    return containsKey(key) ? this[key] as V : defaultValue;
  }

  V getOrPut(K key, V Function() defaultFactory) {
    if (!containsKey(key)) {
      this[key] = defaultFactory();
    }
    return this[key] as V;
  }

  Map<K, V> filterKeys(bool Function(K) predicate) {
    final result = <K, V>{};
    for (final entry in entries) {
      if (predicate(entry.key)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  Map<K, V> filterValues(bool Function(V) predicate) {
    final result = <K, V>{};
    for (final entry in entries) {
      if (predicate(entry.value)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  Map<K, R> mapValues<R>(R Function(V) transform) {
    final result = <K, R>{};
    for (final entry in entries) {
      result[entry.key] = transform(entry.value);
    }
    return result;
  }

  Map<R, V> mapKeys<R>(R Function(K) transform) {
    final result = <R, V>{};
    for (final entry in entries) {
      result[transform(entry.key)] = entry.value;
    }
    return result;
  }

  Map<K, V> mergeWith(Map<K, V> other, V Function(V, V) resolve) {
    final result = Map<K, V>.from(this);
    for (final entry in other.entries) {
      if (result.containsKey(entry.key)) {
        result[entry.key] = resolve(result[entry.key] as V, entry.value);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  Map<V, K> invert() {
    final result = <V, K>{};
    for (final entry in entries) {
      result[entry.value] = entry.key;
    }
    return result;
  }

  List<T> toList<T>(T Function(K, V) transform) {
    return entries.map((e) => transform(e.key, e.value)).toList();
  }

  bool any(bool Function(K, V) predicate) {
    for (final entry in entries) {
      if (predicate(entry.key, entry.value)) return true;
    }
    return false;
  }

  bool all(bool Function(K, V) predicate) {
    for (final entry in entries) {
      if (!predicate(entry.key, entry.value)) return false;
    }
    return true;
  }

  int count(bool Function(K, V) predicate) {
    int c = 0;
    for (final entry in entries) {
      if (predicate(entry.key, entry.value)) c++;
    }
    return c;
  }

  MapEntry<K, V>? minByValue() {
    if (isEmpty) return null;
    MapEntry<K, V>? result;
    for (final entry in entries) {
      final v = entry.value;
      if (v is! Comparable) break;
      if (result == null || (v as Comparable).compareTo(result.value) < 0) {
        result = entry;
      }
    }
    return result;
  }

  MapEntry<K, V>? maxByValue() {
    if (isEmpty) return null;
    MapEntry<K, V>? result;
    for (final entry in entries) {
      final v = entry.value;
      if (v is! Comparable) break;
      if (result == null || (v as Comparable).compareTo(result.value) > 0) {
        result = entry;
      }
    }
    return result;
  }

  Map<K, V> sortedByValue({bool descending = false}) {
    final entryList = entries.toList();
    entryList.sort((a, b) {
      final av = a.value;
      final bv = b.value;
      if (av is Comparable && bv is Comparable) {
        final cmp = av.compareTo(bv);
        return descending ? -cmp : cmp;
      }
      return 0;
    });
    final result = LinkedHashMap<K, V>();
    for (final e in entryList) {
      result[e.key] = e.value;
    }
    return result;
  }

  Map<K, V> sortedByKey({bool descending = false}) {
    final keyList = keys.toList();
    keyList.sort((a, b) {
      if (a is Comparable && b is Comparable) {
        final cmp = a.compareTo(b);
        return descending ? -cmp : cmp;
      }
      return 0;
    });
    final result = LinkedHashMap<K, V>();
    for (final k in keyList) {
      result[k] = this[k] as V;
    }
    return result;
  }

  Map<K, V> updated(K key, V Function(V?) update) {
    final result = Map<K, V>.from(this);
    result[key] = update(result[key]);
    return result;
  }

  Map<K, V> withoutKeys(Set<K> keysToRemove) {
    return filterKeys((k) => !keysToRemove.contains(k));
  }

  Map<K, V> withoutValues(Set<V> valuesToRemove) {
    return filterValues((v) => !valuesToRemove.contains(v));
  }

  Map<K, V> deepMerge(Map<K, V> other) {
    final result = Map<K, V>.from(this);
    for (final entry in other.entries) {
      final existing = result[entry.key];
      if (existing is Map && entry.value is Map) {
        result[entry.key] = (existing as Map).deepMerge(entry.value as Map) as V;
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}

class GchBiMap<K, V> {
  final Map<K, V> _forward = {};
  final Map<V, K> _backward = {};

  void put(K key, V value) {
    final oldValue = _forward[key];
    if (oldValue != null) _backward.remove(oldValue);
    final oldKey = _backward[value];
    if (oldKey != null) _forward.remove(oldKey);
    _forward[key] = value;
    _backward[value] = key;
  }

  V? getByKey(K key) => _forward[key];
  K? getByValue(V value) => _backward[value];

  void removeByKey(K key) {
    final value = _forward.remove(key);
    if (value != null) _backward.remove(value);
  }

  void removeByValue(V value) {
    final key = _backward.remove(value);
    if (key != null) _forward.remove(key);
  }

  bool containsKey(K key) => _forward.containsKey(key);
  bool containsValue(V value) => _backward.containsKey(value);

  Set<K> get keys => _forward.keys.toSet();
  Set<V> get values => _backward.keys.toSet();
  Iterable<MapEntry<K, V>> get entries => _forward.entries;
  int get length => _forward.length;
  bool get isEmpty => _forward.isEmpty;
  bool get isNotEmpty => _forward.isNotEmpty;

  void clear() {
    _forward.clear();
    _backward.clear();
  }

  Map<K, V> toMap() => Map.unmodifiable(_forward);

  GchBiMap<V, K> get inverse {
    final inverted = GchBiMap<V, K>();
    for (final entry in _forward.entries) {
      inverted.put(entry.value, entry.key);
    }
    return inverted;
  }

  @override
  String toString() => 'GchBiMap($_forward)';
}

class GchMultiMap<K, V> {
  final Map<K, List<V>> _data = {};

  void add(K key, V value) {
    _data.putIfAbsent(key, () => <V>[]).add(value);
  }

  void addAll(K key, List<V> values) {
    _data.putIfAbsent(key, () => <V>[]).addAll(values);
  }

  List<V> get(K key) => List.unmodifiable(_data[key] ?? const []);

  void remove(K key, V value) {
    _data[key]?.remove(value);
    if (_data[key]?.isEmpty ?? false) _data.remove(key);
  }

  void removeAll(K key) => _data.remove(key);

  bool contains(K key, V value) => _data[key]?.contains(value) ?? false;

  bool containsKey(K key) => _data.containsKey(key);

  Set<K> get keys => _data.keys.toSet();

  int get totalCount => _data.values.fold(0, (acc, list) => acc + list.length);

  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;

  int countForKey(K key) => _data[key]?.length ?? 0;

  void clear() => _data.clear();

  Map<K, List<V>> toMap() => Map.unmodifiable(
        _data.map((k, v) => MapEntry(k, List.unmodifiable(v))),
      );

  Iterable<MapEntry<K, List<V>>> get entries => _data.entries;

  void forEach(void Function(K, V) action) {
    for (final entry in _data.entries) {
      for (final v in entry.value) {
        action(entry.key, v);
      }
    }
  }

  GchMultiMap<K, V> filter(bool Function(K, V) predicate) {
    final result = GchMultiMap<K, V>();
    for (final entry in _data.entries) {
      for (final v in entry.value) {
        if (predicate(entry.key, v)) result.add(entry.key, v);
      }
    }
    return result;
  }

  @override
  String toString() => 'GchMultiMap($_data)';
}

class GchOrderedMap<K, V> extends Iterable<MapEntry<K, V>> {
  final LinkedHashMap<K, V> _map;
  final List<K> _insertionOrder = [];
  final bool accessOrder;

  GchOrderedMap({this.accessOrder = false}) : _map = LinkedHashMap<K, V>();

  void put(K key, V value) {
    if (!_map.containsKey(key)) {
      _insertionOrder.add(key);
    }
    _map[key] = value;
    if (accessOrder) {
      _insertionOrder.remove(key);
      _insertionOrder.add(key);
    }
  }

  V? get(K key) {
    if (!_map.containsKey(key)) return null;
    if (accessOrder) {
      _insertionOrder.remove(key);
      _insertionOrder.add(key);
    }
    return _map[key];
  }

  V? remove(K key) {
    _insertionOrder.remove(key);
    return _map.remove(key);
  }

  bool containsKey(K key) => _map.containsKey(key);
  bool containsValue(V value) => _map.containsValue(value);

  K? get firstKey => _insertionOrder.isEmpty ? null : _insertionOrder.first;
  K? get lastKey => _insertionOrder.isEmpty ? null : _insertionOrder.last;

  K? keyAt(int index) {
    if (index < 0 || index >= _insertionOrder.length) return null;
    return _insertionOrder[index];
  }

  V? valueAt(int index) {
    final key = keyAt(index);
    return key != null ? _map[key] : null;
  }

  void reorder(K key, int newIndex) {
    if (!_insertionOrder.contains(key)) return;
    _insertionOrder.remove(key);
    final clamped = newIndex.clamp(0, _insertionOrder.length);
    _insertionOrder.insert(clamped, key);
  }

  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;

  Iterable<K> get keys => List.unmodifiable(_insertionOrder);
  Iterable<V> get values => _insertionOrder.map((k) => _map[k] as V);

  @override
  Iterator<MapEntry<K, V>> get iterator {
    return _insertionOrder.map((k) => MapEntry(k, _map[k] as V)).iterator;
  }

  void clear() {
    _map.clear();
    _insertionOrder.clear();
  }

  Map<K, V> toMap() {
    final result = LinkedHashMap<K, V>();
    for (final k in _insertionOrder) {
      result[k] = _map[k] as V;
    }
    return result;
  }

  @override
  void forEach(void Function(MapEntry<K, V>) action) {
    for (final k in _insertionOrder) {
      action(MapEntry(k, _map[k] as V));
    }
  }

  void forEachEntry(void Function(K, V) action) {
    for (final k in _insertionOrder) {
      action(k, _map[k] as V);
    }
  }

  GchOrderedMap<K, V> filterKeys(bool Function(K) predicate) {
    final result = GchOrderedMap<K, V>(accessOrder: accessOrder);
    for (final k in _insertionOrder) {
      if (predicate(k)) result.put(k, _map[k] as V);
    }
    return result;
  }

  GchOrderedMap<K, V> filterValues(bool Function(V) predicate) {
    final result = GchOrderedMap<K, V>(accessOrder: accessOrder);
    for (final k in _insertionOrder) {
      final v = _map[k] as V;
      if (predicate(v)) result.put(k, v);
    }
    return result;
  }

  @override
  String toString() {
    final pairs = _insertionOrder.map((k) => '$k: ${_map[k]}').join(', ');
    return 'GchOrderedMap{$pairs}';
  }
}

class GchMapUtil {
  static Map<K, V> fromEntries<K, V>(List<MapEntry<K, V>> entries) {
    final result = <K, V>{};
    for (final e in entries) {
      result[e.key] = e.value;
    }
    return result;
  }

  static Map<K, V> fromLists<K, V>(List<K> keys, List<V> values) {
    final result = <K, V>{};
    final len = min(keys.length, values.length);
    for (int i = 0; i < len; i++) {
      result[keys[i]] = values[i];
    }
    return result;
  }

  static Map<K, List<V>> groupBy<T, K, V>(
    List<T> items,
    K Function(T) keySelector,
    V Function(T) valueSelector,
  ) {
    final result = <K, List<V>>{};
    for (final item in items) {
      final k = keySelector(item);
      result.putIfAbsent(k, () => []).add(valueSelector(item));
    }
    return result;
  }

  static Map<K, V> flattenNested<K, V>(Map<String, dynamic> nested, {String separator = '.'}) {
    final result = <K, V>{};
    void recurse(Map<String, dynamic> map, String prefix) {
      for (final entry in map.entries) {
        final key = prefix.isEmpty ? entry.key : '$prefix$separator${entry.key}';
        if (entry.value is Map<String, dynamic>) {
          recurse(entry.value as Map<String, dynamic>, key);
        } else {
          result[key as K] = entry.value as V;
        }
      }
    }
    recurse(nested, '');
    return result;
  }

  static Map<String, dynamic> unflatten(Map<String, dynamic> flat, {String separator = '.'}) {
    final result = <String, dynamic>{};
    for (final entry in flat.entries) {
      final parts = entry.key.split(separator);
      Map<String, dynamic> current = result;
      for (int i = 0; i < parts.length - 1; i++) {
        current.putIfAbsent(parts[i], () => <String, dynamic>{});
        current = current[parts[i]] as Map<String, dynamic>;
      }
      current[parts.last] = entry.value;
    }
    return result;
  }

  static Map<K, V> pick<K, V>(Map<K, V> map, Set<K> keys) {
    return Map.fromEntries(
      keys.where(map.containsKey).map((k) => MapEntry(k, map[k] as V)),
    );
  }

  static Map<K, V> omit<K, V>(Map<K, V> map, Set<K> keys) {
    return Map.fromEntries(
      map.entries.where((e) => !keys.contains(e.key)),
    );
  }

  static Map<K, V> defaults<K, V>(Map<K, V> map, Map<K, V> defaultValues) {
    final result = Map<K, V>.from(defaultValues);
    result.addAll(map);
    return result;
  }

  static bool deepEqual<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final av = a[key];
      final bv = b[key];
      if (av is Map && bv is Map) {
        if (!deepEqual(av as Map<dynamic, dynamic>, bv as Map<dynamic, dynamic>)) return false;
      } else if (av != bv) {
        return false;
      }
    }
    return true;
  }

  static Map<K, V> tap<K, V>(Map<K, V> map, void Function(K, V) action) {
    for (final entry in map.entries) {
      action(entry.key, entry.value);
    }
    return map;
  }

  static Map<K, V> sortBy<K, V>(
    Map<K, V> map,
    Comparator<MapEntry<K, V>> comparator,
  ) {
    final entryList = map.entries.toList()..sort(comparator);
    final result = LinkedHashMap<K, V>();
    for (final e in entryList) {
      result[e.key] = e.value;
    }
    return result;
  }

  static Map<V, K> invertMap<K, V>(Map<K, V> map) {
    final result = <V, K>{};
    for (final entry in map.entries) {
      result[entry.value] = entry.key;
    }
    return result;
  }

  static Map<K, V> zipToMap<K, V>(Iterable<K> keys, Iterable<V> values) {
    final ki = keys.iterator;
    final vi = values.iterator;
    final result = <K, V>{};
    while (ki.moveNext() && vi.moveNext()) {
      result[ki.current] = vi.current;
    }
    return result;
  }

  static Map<K, V> computeIfAbsent<K, V>(Map<K, V> map, K key, V Function(K) compute) {
    if (!map.containsKey(key)) {
      map[key] = compute(key);
    }
    return map;
  }

  static Map<K, V> replaceAll<K, V>(Map<K, V> map, V Function(K, V) replacer) {
    return {for (final e in map.entries) e.key: replacer(e.key, e.value)};
  }

  static Map<String, dynamic> toCamelCase(Map<String, dynamic> map) {
    String camelize(String s) {
      final parts = s.split('_');
      if (parts.length <= 1) return s;
      return parts[0] + parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join('');
    }

    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      final newKey = camelize(entry.key);
      if (entry.value is Map<String, dynamic>) {
        result[newKey] = toCamelCase(entry.value as Map<String, dynamic>);
      } else {
        result[newKey] = entry.value;
      }
    }
    return result;
  }

  static Map<String, dynamic> toSnakeCase(Map<String, dynamic> map) {
    String snakeize(String s) {
      final buffer = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        final c = s[i];
        if (c == c.toUpperCase() && c != c.toLowerCase() && i > 0) {
          buffer.write('_');
        }
        buffer.write(c.toLowerCase());
      }
      return buffer.toString();
    }

    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      final newKey = snakeize(entry.key);
      if (entry.value is Map<String, dynamic>) {
        result[newKey] = toSnakeCase(entry.value as Map<String, dynamic>);
      } else {
        result[newKey] = entry.value;
      }
    }
    return result;
  }

  static List<Map<K, V>> chunk<K, V>(Map<K, V> map, int chunkSize) {
    if (chunkSize <= 0) return [];
    final entries = map.entries.toList();
    final result = <Map<K, V>>[];
    for (int i = 0; i < entries.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, entries.length);
      result.add(Map.fromEntries(entries.sublist(i, end)));
    }
    return result;
  }

  static Map<K, List<V>> groupValues<K, V>(List<MapEntry<K, V>> entries) {
    final result = <K, List<V>>{};
    for (final e in entries) {
      result.putIfAbsent(e.key, () => []).add(e.value);
    }
    return result;
  }
}

class GchLruCache<K, V> {
  final int capacity;
  final LinkedHashMap<K, V> _cache;

  GchLruCache(this.capacity)
      : _cache = LinkedHashMap<K, V>();

  V? get(K key) {
    if (!_cache.containsKey(key)) return null;
    final value = _cache.remove(key) as V;
    _cache[key] = value;
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= capacity) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  bool containsKey(K key) => _cache.containsKey(key);
  int get size => _cache.length;
  bool get isFull => _cache.length >= capacity;
  bool get isEmpty => _cache.isEmpty;
  void clear() => _cache.clear();
  Set<K> get keys => _cache.keys.toSet();
  List<V> get values => _cache.values.toList();

  @override
  String toString() => 'GchLruCache(capacity=$capacity, size=$size)';
}

class GchCountMap<K> {
  final Map<K, int> _counts = {};

  void add(K key, [int count = 1]) {
    _counts[key] = (_counts[key] ?? 0) + count;
  }

  void remove(K key, [int count = 1]) {
    final current = _counts[key] ?? 0;
    final next = current - count;
    if (next <= 0) {
      _counts.remove(key);
    } else {
      _counts[key] = next;
    }
  }

  int getCount(K key) => _counts[key] ?? 0;
  bool contains(K key) => (_counts[key] ?? 0) > 0;
  Set<K> get keys => _counts.keys.toSet();
  int get totalCount => _counts.values.fold(0, (a, b) => a + b);
  int get distinctCount => _counts.length;
  bool get isEmpty => _counts.isEmpty;

  K? mostCommon() {
    if (_counts.isEmpty) return null;
    K? result;
    int maxCount = 0;
    for (final entry in _counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        result = entry.key;
      }
    }
    return result;
  }

  K? leastCommon() {
    if (_counts.isEmpty) return null;
    K? result;
    int minCount = 0x7fffffff;
    for (final entry in _counts.entries) {
      if (entry.value < minCount) {
        minCount = entry.value;
        result = entry.key;
      }
    }
    return result;
  }

  List<MapEntry<K, int>> topN(int n) {
    final sorted = _counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  Map<K, double> toFrequencies() {
    final total = totalCount;
    if (total == 0) return {};
    return _counts.map((k, v) => MapEntry(k, v / total));
  }

  void clear() => _counts.clear();

  Map<K, int> toMap() => Map.unmodifiable(_counts);

  @override
  String toString() => 'GchCountMap($_counts)';
}

class GchMapDiff<K, V> {
  final Map<K, V> added;
  final Map<K, V> removed;
  final Map<K, ({V before, V after})> changed;

  const GchMapDiff({
    required this.added,
    required this.removed,
    required this.changed,
  });

  bool get isEmpty => added.isEmpty && removed.isEmpty && changed.isEmpty;
  bool get hasChanges => !isEmpty;

  static GchMapDiff<K, V> compute<K, V>(Map<K, V> before, Map<K, V> after) {
    final added = <K, V>{};
    final removed = <K, V>{};
    final changed = <K, ({V before, V after})>{};

    for (final key in after.keys) {
      if (!before.containsKey(key)) {
        added[key] = after[key] as V;
      } else if (before[key] != after[key]) {
        changed[key] = (before: before[key] as V, after: after[key] as V);
      }
    }

    for (final key in before.keys) {
      if (!after.containsKey(key)) {
        removed[key] = before[key] as V;
      }
    }

    return GchMapDiff(added: added, removed: removed, changed: changed);
  }

  Map<K, V> apply(Map<K, V> base) {
    final result = Map<K, V>.from(base);
    for (final key in removed.keys) {
      result.remove(key);
    }
    result.addAll(added);
    for (final entry in changed.entries) {
      result[entry.key] = entry.value.after;
    }
    return result;
  }

  @override
  String toString() =>
      'GchMapDiff(added=${added.length}, removed=${removed.length}, changed=${changed.length})';
}
