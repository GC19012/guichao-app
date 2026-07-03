// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:collection';
import 'dart:async';

/// A single cache entry holding a value and metadata.
class GchCacheEntry<V> {
  final V value;
  final DateTime createdAt;
  final DateTime? expiresAt;
  int hitCount;

  GchCacheEntry({
    required this.value,
    required this.createdAt,
    this.expiresAt,
  }) : hitCount = 0;

  /// Returns true if this entry has not expired.
  bool get isAlive {
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Time remaining until expiry; null if no expiry set.
  Duration? get ttlRemaining {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  String toString() => 'GchCacheEntry(value: $value, hits: $hitCount, alive: $isAlive)';
}

/// A Least-Recently-Used (LRU) cache backed by a [LinkedHashMap].
class GchLRUCache<K, V> {
  final int capacity;
  final LinkedHashMap<K, V> _map;
  int _hits = 0;
  int _misses = 0;

  GchLRUCache(this.capacity)
      : assert(capacity > 0, 'Capacity must be positive'),
        _map = LinkedHashMap<K, V>();

  /// Retrieves the value for [key], moving it to the most-recently-used position.
  V? get(K key) {
    if (!_map.containsKey(key)) {
      _misses++;
      return null;
    }
    _hits++;
    final value = _map.remove(key) as V;
    _map[key] = value;
    return value;
  }

  /// Inserts or updates [key] with [value], evicting the LRU entry if at capacity.
  void put(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= capacity) {
      // Remove the least recently used (first) entry
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }

  /// Removes the entry for [key].
  V? remove(K key) {
    return _map.remove(key);
  }

  /// Returns true if [key] is present in the cache.
  bool contains(K key) => _map.containsKey(key);

  /// Clears all entries.
  void clear() {
    _map.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Returns all keys in LRU order (oldest first).
  Iterable<K> get keys => _map.keys;

  /// Returns all values in LRU order (oldest first).
  Iterable<V> get values => _map.values;

  /// Returns all key-value pairs.
  Iterable<MapEntry<K, V>> get entries => _map.entries;

  /// The current number of entries in the cache.
  int get length => _map.length;

  /// The hit rate as a fraction of total lookups.
  double get hitRate {
    final total = _hits + _misses;
    return total == 0 ? 0.0 : _hits / total;
  }

  /// Total number of cache hits since creation or last clear.
  int get totalHits => _hits;

  /// Total number of cache misses since creation or last clear.
  int get totalMisses => _misses;

  /// Returns a snapshot map of current entries.
  Map<K, V> toMap() => Map<K, V>.from(_map);

  @override
  String toString() => 'GchLRUCache(capacity: $capacity, size: $length, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
}

/// A cache with per-entry time-to-live (TTL) expiration.
class GchTTLCache<K, V> {
  final Duration defaultTTL;
  final int? maxSize;
  final Map<K, GchCacheEntry<V>> _store = {};
  int _hitCount = 0;
  int _missCount = 0;
  int _evictionCount = 0;

  GchTTLCache(this.defaultTTL, {this.maxSize});

  /// Returns the cached value for [key], or null if absent or expired.
  V? get(K key) {
    final entry = _store[key];
    if (entry == null) {
      _missCount++;
      return null;
    }
    if (!entry.isAlive) {
      _store.remove(key);
      _missCount++;
      return null;
    }
    entry.hitCount++;
    _hitCount++;
    return entry.value;
  }

  /// Stores [value] for [key] with optional [ttl] override.
  void put(K key, V value, {Duration? ttl}) {
    // Evict if at max size
    if (maxSize != null && _store.length >= maxSize! && !_store.containsKey(key)) {
      _evictOldest();
    }
    final effectiveTTL = ttl ?? defaultTTL;
    final now = DateTime.now();
    _store[key] = GchCacheEntry<V>(
      value: value,
      createdAt: now,
      expiresAt: now.add(effectiveTTL),
    );
  }

  void _evictOldest() {
    if (_store.isEmpty) return;
    K? oldestKey;
    DateTime? oldestTime;
    for (final entry in _store.entries) {
      if (oldestTime == null || entry.value.createdAt.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value.createdAt;
      }
    }
    if (oldestKey != null) {
      _store.remove(oldestKey);
      _evictionCount++;
    }
  }

  /// Removes the entry for [key].
  V? remove(K key) {
    return _store.remove(key)?.value;
  }

  /// Removes all entries.
  void clear() {
    _store.clear();
    _hitCount = 0;
    _missCount = 0;
    _evictionCount = 0;
  }

  /// Returns true if [key] is present and not expired.
  bool contains(K key) {
    final entry = _store[key];
    if (entry == null) return false;
    if (!entry.isAlive) {
      _store.remove(key);
      return false;
    }
    return true;
  }

  /// The current number of entries (including possibly expired ones).
  int get length => _store.length;

  /// Removes all expired entries and returns the count removed.
  int purgeExpired() {
    final expired = _store.entries.where((e) => !e.value.isAlive).map((e) => e.key).toList();
    for (final key in expired) {
      _store.remove(key);
    }
    _evictionCount += expired.length;
    return expired.length;
  }

  /// Returns cache statistics.
  Map<String, dynamic> get stats => {
    'hitCount': _hitCount,
    'missCount': _missCount,
    'evictionCount': _evictionCount,
    'size': _store.length,
    'hitRate': (_hitCount + _missCount) == 0
        ? 0.0
        : _hitCount / (_hitCount + _missCount),
  };

  /// Returns all non-expired keys.
  List<K> get liveKeys =>
      _store.entries.where((e) => e.value.isAlive).map((e) => e.key).toList();

  @override
  String toString() => 'GchTTLCache(size: $length, stats: $stats)';
}

/// Provides memoization helpers for pure functions.
class GchMemoize {
  GchMemoize._();

  /// Memoizes a single-argument function.
  static T Function(A) memo1<A, T>(T Function(A) fn) {
    final cache = <A, T>{};
    return (A arg) {
      if (cache.containsKey(arg)) return cache[arg] as T;
      final result = fn(arg);
      cache[arg] = result;
      return result;
    };
  }

  /// Memoizes a two-argument function.
  static T Function(A, B) memo2<A, B, T>(T Function(A, B) fn) {
    final cache = <String, T>{};
    return (A a, B b) {
      final key = '${a.hashCode}:${b.hashCode}';
      if (cache.containsKey(key)) return cache[key] as T;
      final result = fn(a, b);
      cache[key] = result;
      return result;
    };
  }

  /// Memoizes a single-argument function with a TTL for each cached result.
  static T Function(A) memoWithTTL<A, T>(T Function(A) fn, Duration ttl) {
    final cache = GchTTLCache<A, T>(ttl);
    return (A arg) {
      final cached = cache.get(arg);
      if (cached != null) return cached;
      final result = fn(arg);
      cache.put(arg, result);
      return result;
    };
  }

  /// Memoizes a zero-argument function (computed once, then cached).
  static T Function() memoOnce<T>(T Function() fn) {
    bool computed = false;
    late T result;
    return () {
      if (!computed) {
        result = fn();
        computed = true;
      }
      return result;
    };
  }

  /// Returns a debounced version of [fn] that delays execution by [delay].
  static void Function(A) debounce<A>(void Function(A) fn, Duration delay) {
    Timer? timer;
    return (A arg) {
      timer?.cancel();
      timer = Timer(delay, () => fn(arg));
    };
  }

  /// Returns a throttled version of [fn] that executes at most once per [interval].
  static void Function(A) throttle<A>(void Function(A) fn, Duration interval) {
    DateTime? lastCall;
    return (A arg) {
      final now = DateTime.now();
      if (lastCall == null || now.difference(lastCall!) >= interval) {
        lastCall = now;
        fn(arg);
      }
    };
  }
}

/// An async cache that coalesces in-flight requests for the same key.
class GchAsyncCache<K, V> {
  final Duration? defaultTTL;
  final GchTTLCache<K, V>? _ttlCache;
  final Map<K, Future<V>> _pending = {};

  GchAsyncCache({this.defaultTTL})
      : _ttlCache = defaultTTL != null ? GchTTLCache<K, V>(defaultTTL) : null;

  /// Returns the cached value for [key], or fetches it using [fetcher].
  /// Concurrent calls for the same key share a single in-flight request.
  Future<V> getOrFetch(K key, Future<V> Function() fetcher, {Duration? ttl}) async {
    // Check TTL cache first
    if (_ttlCache != null) {
      final cached = _ttlCache.get(key);
      if (cached != null) return cached;
    }

    // Coalesce in-flight requests
    if (_pending.containsKey(key)) {
      return _pending[key]!;
    }

    final future = fetcher().then((value) {
      _pending.remove(key);
      if (_ttlCache != null) {
        _ttlCache.put(key, value, ttl: ttl);
      }
      return value;
    }).catchError((error) {
      _pending.remove(key);
      throw error as Object;
    });

    _pending[key] = future;
    return future;
  }

  /// Invalidates the cache entry for [key].
  void invalidate(K key) {
    _pending.remove(key);
    _ttlCache?.remove(key);
  }

  /// Invalidates all cache entries.
  void invalidateAll() {
    _pending.clear();
    _ttlCache?.clear();
  }

  /// Returns the list of keys with in-flight fetches.
  List<K> get pendingKeys => List.unmodifiable(_pending.keys);

  /// Returns the number of currently pending fetches.
  int get pendingCount => _pending.length;

  /// Returns whether there is a pending fetch for [key].
  bool isPending(K key) => _pending.containsKey(key);
}

/// A simple in-memory write-through cache with versioning.
class GchVersionedCache<K, V> {
  final Map<K, ({V value, int version, DateTime updatedAt})> _store = {};

  /// Stores [value] for [key], incrementing its version.
  void put(K key, V value) {
    final current = _store[key];
    _store[key] = (
      value: value,
      version: (current?.version ?? 0) + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns the value for [key], or null if absent.
  V? get(K key) => _store[key]?.value;

  /// Returns the version number for [key], or 0 if absent.
  int version(K key) => _store[key]?.version ?? 0;

  /// Returns the last update time for [key], or null if absent.
  DateTime? updatedAt(K key) => _store[key]?.updatedAt;

  /// Removes the entry for [key].
  void remove(K key) => _store.remove(key);

  /// Clears all entries.
  void clear() => _store.clear();

  /// Returns whether [key] is present.
  bool contains(K key) => _store.containsKey(key);

  /// The number of entries.
  int get length => _store.length;

  /// Returns all keys.
  Iterable<K> get keys => _store.keys;
}

/// A ring-buffer (circular) cache with fixed capacity.
class GchRingCache<V> {
  final int capacity;
  final List<V?> _buffer;
  int _head = 0;
  int _count = 0;

  GchRingCache(this.capacity)
      : assert(capacity > 0),
        _buffer = List<V?>.filled(capacity, null);

  /// Adds [value] to the ring buffer, overwriting the oldest entry if full.
  void add(V value) {
    _buffer[_head] = value;
    _head = (_head + 1) % capacity;
    if (_count < capacity) _count++;
  }

  /// Returns all stored values in insertion order (oldest first).
  List<V> toList() {
    if (_count < capacity) {
      return _buffer.take(_count).whereType<V>().toList();
    }
    final result = <V>[];
    for (int i = 0; i < capacity; i++) {
      final idx = (_head + i) % capacity;
      final v = _buffer[idx];
      if (v != null) result.add(v);
    }
    return result;
  }

  /// Returns the most recently added value, or null if empty.
  V? get latest {
    if (_count == 0) return null;
    final idx = (_head - 1 + capacity) % capacity;
    return _buffer[idx];
  }

  /// Clears the buffer.
  void clear() {
    _buffer.fillRange(0, capacity, null);
    _head = 0;
    _count = 0;
  }

  /// Number of entries currently stored.
  int get length => _count;

  /// Whether the buffer is at full capacity.
  bool get isFull => _count == capacity;

  /// Returns the element at logical [index] (0 = oldest).
  V? elementAt(int index) {
    if (index < 0 || index >= _count) return null;
    if (_count < capacity) return _buffer[index];
    final idx = (_head + index) % capacity;
    return _buffer[idx];
  }
}

// ─── GchMultiLayerCache ────────────────────────────────────────────────────

/// A two-layer cache: L1 is a fast LRU, L2 is a larger TTL cache.
class GchMultiLayerCache<K, V> {
  final GchLRUCache<K, V> _l1;
  final GchTTLCache<K, V> _l2;

  GchMultiLayerCache({
    int l1Capacity = 50,
    required Duration l2TTL,
    int? l2MaxSize,
  })  : _l1 = GchLRUCache<K, V>(l1Capacity),
        _l2 = GchTTLCache<K, V>(l2TTL, maxSize: l2MaxSize);

  /// Gets a value, checking L1 first, then L2, promoting to L1 on L2 hit.
  V? get(K key) {
    final l1Value = _l1.get(key);
    if (l1Value != null) return l1Value;

    final l2Value = _l2.get(key);
    if (l2Value != null) {
      _l1.put(key, l2Value); // promote to L1
      return l2Value;
    }
    return null;
  }

  /// Stores [value] in both L1 and L2.
  void put(K key, V value, {Duration? l2TTL}) {
    _l1.put(key, value);
    _l2.put(key, value, ttl: l2TTL);
  }

  /// Removes [key] from both layers.
  void remove(K key) {
    _l1.remove(key);
    _l2.remove(key);
  }

  /// Clears both layers.
  void clear() {
    _l1.clear();
    _l2.clear();
  }

  /// Returns true if [key] is present in either layer.
  bool contains(K key) => _l1.contains(key) || _l2.contains(key);

  /// L1 hit rate.
  double get l1HitRate => _l1.hitRate;

  /// L2 statistics.
  Map<String, dynamic> get l2Stats => _l2.stats;

  /// Purges expired L2 entries.
  int purgeExpired() => _l2.purgeExpired();
}

// ─── GchCacheGroup ────────────────────────────────────────────────────────

/// Manages a named group of LRU caches.
class GchCacheGroup {
  final Map<String, GchLRUCache<dynamic, dynamic>> _group = {};
  final int defaultCapacity;

  GchCacheGroup({this.defaultCapacity = 100});

  /// Returns the cache for [name], creating it if necessary.
  GchLRUCache<K, V> group<K, V>(String name, {int? capacity}) {
    if (!_group.containsKey(name)) {
      _group[name] = GchLRUCache<K, V>(capacity ?? defaultCapacity);
    }
    return _group[name]! as GchLRUCache<K, V>;
  }

  /// Clears all caches in the group.
  void clearAll() {
    for (final cache in _group.values) {
      cache.clear();
    }
  }

  /// Removes a named cache from the group.
  void removeGroup(String name) {
    _group.remove(name);
  }

  /// Returns the names of all managed caches.
  List<String> get groupNames => _group.keys.toList();

  /// Returns the combined size across all caches.
  int get totalSize => _group.values.fold(0, (sum, c) => sum + c.length);
}

// ─── GchPersistentCacheAdapter ────────────────────────────────────────────

/// An adapter interface for adding persistence to an in-memory cache.
abstract class GchCachePersistenceAdapter<K, V> {
  Future<void> save(K key, V value);
  Future<V?> load(K key);
  Future<void> delete(K key);
  Future<void> deleteAll();
  Future<Map<K, V>> loadAll();
}

/// An in-memory implementation of [GchCachePersistenceAdapter] (for testing).
class GchInMemoryPersistenceAdapter<K, V> implements GchCachePersistenceAdapter<K, V> {
  final Map<K, V> _store = {};

  @override
  Future<void> save(K key, V value) async {
    _store[key] = value;
  }

  @override
  Future<V?> load(K key) async {
    return _store[key];
  }

  @override
  Future<void> delete(K key) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _store.clear();
  }

  @override
  Future<Map<K, V>> loadAll() async {
    return Map<K, V>.from(_store);
  }

  int get size => _store.length;
}

// ─── GchCacheStats ────────────────────────────────────────────────────────

/// Aggregated statistics across multiple cache instances.
class GchCacheStats {
  int totalHits;
  int totalMisses;
  int totalEvictions;
  int totalEntries;

  GchCacheStats({
    this.totalHits = 0,
    this.totalMisses = 0,
    this.totalEvictions = 0,
    this.totalEntries = 0,
  });

  double get hitRate {
    final total = totalHits + totalMisses;
    return total == 0 ? 0.0 : totalHits / total;
  }

  void merge(Map<String, dynamic> stats) {
    totalHits += (stats['hitCount'] as int? ?? 0);
    totalMisses += (stats['missCount'] as int? ?? 0);
    totalEvictions += (stats['evictionCount'] as int? ?? 0);
    totalEntries += (stats['size'] as int? ?? 0);
  }

  Map<String, dynamic> toMap() => {
    'totalHits': totalHits,
    'totalMisses': totalMisses,
    'totalEvictions': totalEvictions,
    'totalEntries': totalEntries,
    'hitRate': hitRate,
  };

  @override
  String toString() => 'GchCacheStats(hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, entries: $totalEntries)';
}

// ─── GchNullSafeCache ─────────────────────────────────────────────────────

/// A cache that distinguishes between "not cached" and "cached as null".
class GchNullSafeCache<K, V> {
  final Map<K, _NullableEntry<V>> _store = {};
  final int? maxSize;

  GchNullSafeCache({this.maxSize});

  /// Returns a [_CacheLookup] result indicating whether the key was found.
  _CacheLookup<V> lookup(K key) {
    if (!_store.containsKey(key)) return _CacheLookup.miss();
    return _CacheLookup.hit(_store[key]!.value);
  }

  /// Stores [value] (which may be null) for [key].
  void put(K key, V? value) {
    if (maxSize != null && _store.length >= maxSize! && !_store.containsKey(key)) {
      _store.remove(_store.keys.first);
    }
    _store[key] = _NullableEntry<V>(value);
  }

  /// Removes the entry for [key].
  void remove(K key) => _store.remove(key);

  /// Clears all entries.
  void clear() => _store.clear();

  /// The number of entries including null-valued ones.
  int get length => _store.length;

  /// Whether [key] is present (regardless of null value).
  bool contains(K key) => _store.containsKey(key);
}

class _NullableEntry<V> {
  final V? value;
  _NullableEntry(this.value);
}

class _CacheLookup<V> {
  final bool found;
  final V? value;

  _CacheLookup._({required this.found, this.value});

  factory _CacheLookup.hit(V? value) => _CacheLookup._(found: true, value: value);
  factory _CacheLookup.miss() => _CacheLookup._(found: false);
}

// ─── GchCachePolicy ───────────────────────────────────────────────────────

/// Defines cache eviction and storage policies.
class GchCachePolicy {
  final Duration? ttl;
  final int? maxSize;
  final GchEvictionStrategy strategy;
  final bool storeNull;

  const GchCachePolicy({
    this.ttl,
    this.maxSize,
    this.strategy = GchEvictionStrategy.lru,
    this.storeNull = false,
  });

  static const GchCachePolicy noExpiry = GchCachePolicy(strategy: GchEvictionStrategy.lru);

  static const GchCachePolicy shortLived = GchCachePolicy(
    ttl: Duration(minutes: 5),
    maxSize: 200,
  );

  static const GchCachePolicy longLived = GchCachePolicy(
    ttl: Duration(hours: 24),
    maxSize: 500,
  );

  GchCachePolicy copyWith({
    Duration? ttl,
    int? maxSize,
    GchEvictionStrategy? strategy,
    bool? storeNull,
  }) {
    return GchCachePolicy(
      ttl: ttl ?? this.ttl,
      maxSize: maxSize ?? this.maxSize,
      strategy: strategy ?? this.strategy,
      storeNull: storeNull ?? this.storeNull,
    );
  }

  @override
  String toString() => 'GchCachePolicy(ttl: $ttl, maxSize: $maxSize, strategy: $strategy)';
}

/// Cache eviction strategies.
enum GchEvictionStrategy {
  lru,   // Least Recently Used
  lfu,   // Least Frequently Used
  fifo,  // First In, First Out
  ttl,   // Time-To-Live only
}

// ─── GchComputeCache ──────────────────────────────────────────────────────

/// A cache that computes missing values on demand using a [computeFn].
class GchComputeCache<K, V> {
  final V Function(K) computeFn;
  final GchLRUCache<K, V> _cache;

  GchComputeCache(this.computeFn, {int capacity = 128})
      : _cache = GchLRUCache<K, V>(capacity);

  /// Returns the cached value for [key], computing it if not present.
  V getOrCompute(K key) {
    final cached = _cache.get(key);
    if (cached != null) return cached;
    final computed = computeFn(key);
    _cache.put(key, computed);
    return computed;
  }

  /// Invalidates the cached value for [key].
  void invalidate(K key) => _cache.remove(key);

  /// Clears all cached values.
  void clear() => _cache.clear();

  /// Returns true if [key] has a cached value.
  bool contains(K key) => _cache.contains(key);

  /// The number of cached entries.
  int get size => _cache.length;

  /// The cache hit rate.
  double get hitRate => _cache.hitRate;
}
