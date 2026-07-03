// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';
import 'dart:async';

// ──────────────────────────────────────────────
// GchPageInfo
// ──────────────────────────────────────────────
class GchPageInfo {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  const GchPageInfo({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;
  bool get isFirst => page == 1;
  bool get isLast => page == totalPages;

  int? get nextPage => hasNext ? page + 1 : null;
  int? get prevPage => hasPrev ? page - 1 : null;

  int get startIndex => (page - 1) * pageSize;
  int get endIndex => min(startIndex + pageSize, totalItems);
  int get itemCount => endIndex - startIndex;

  GchPageInfo copyWith({
    int? page,
    int? pageSize,
    int? totalItems,
    int? totalPages,
  }) {
    return GchPageInfo(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  String toString() =>
      'GchPageInfo(page=$page/$totalPages, size=$pageSize, total=$totalItems)';

  @override
  bool operator ==(Object other) =>
      other is GchPageInfo &&
      page == other.page &&
      pageSize == other.pageSize &&
      totalItems == other.totalItems &&
      totalPages == other.totalPages;

  @override
  int get hashCode => Object.hash(page, pageSize, totalItems, totalPages);
}

// ──────────────────────────────────────────────
// GchPage<T>
// ──────────────────────────────────────────────
class GchPage<T> {
  final List<T> items;
  final GchPageInfo info;

  const GchPage({required this.items, required this.info});

  bool get isEmpty => items.isEmpty;
  int get length => items.length;

  GchPage<R> map<R>(R Function(T) mapper) {
    return GchPage<R>(
      items: items.map(mapper).toList(),
      info: info,
    );
  }

  GchPage<T> where(bool Function(T) predicate) {
    return GchPage<T>(
      items: items.where(predicate).toList(),
      info: info,
    );
  }

  T? firstWhere(bool Function(T) predicate) {
    for (final item in items) {
      if (predicate(item)) return item;
    }
    return null;
  }

  GchPage<T> sorted(Comparator<T> comparator) {
    final sorted = List<T>.from(items)..sort(comparator);
    return GchPage<T>(items: sorted, info: info);
  }

  @override
  String toString() =>
      'GchPage(items=${items.length}, ${info})';
}

// ──────────────────────────────────────────────
// GchPaginator<T>  (in-memory)
// ──────────────────────────────────────────────
class GchPaginator<T> {
  List<T> _allItems;
  int _pageSize;
  int _currentPage = 1;

  GchPaginator(List<T> allItems, {int pageSize = 20})
      : _allItems = List.from(allItems),
        _pageSize = pageSize;

  int get totalItems => _allItems.length;

  int get totalPages => max(1, (_allItems.length / _pageSize).ceil());

  int get currentPage => _currentPage;

  int get pageSize => _pageSize;

  void setPageSize(int size) {
    _pageSize = max(1, size);
    _currentPage = 1;
  }

  GchPage<T> getPage(int page) {
    final clampedPage = page.clamp(1, totalPages);
    _currentPage = clampedPage;
    final start = (clampedPage - 1) * _pageSize;
    final end = min(start + _pageSize, _allItems.length);
    final pageItems = _allItems.sublist(start, end);
    return GchPage<T>(
      items: pageItems,
      info: GchPageInfo(
        page: clampedPage,
        pageSize: _pageSize,
        totalItems: _allItems.length,
        totalPages: totalPages,
      ),
    );
  }

  GchPage<T> search(bool Function(T) predicate) {
    final filtered = _allItems.where(predicate).toList();
    return GchPage<T>(
      items: filtered,
      info: GchPageInfo(
        page: 1,
        pageSize: filtered.length,
        totalItems: filtered.length,
        totalPages: 1,
      ),
    );
  }

  void sort(Comparator<T> comparator) {
    _allItems.sort(comparator);
    _currentPage = 1;
  }

  GchPaginator<T> filter(bool Function(T) predicate) {
    return GchPaginator<T>(
      _allItems.where(predicate).toList(),
      pageSize: _pageSize,
    );
  }

  GchPage<T> goToFirst() => getPage(1);

  GchPage<T> goToLast() => getPage(totalPages);

  GchPage<T> goToNext() => getPage((_currentPage + 1).clamp(1, totalPages));

  GchPage<T> goToPrev() => getPage((_currentPage - 1).clamp(1, totalPages));

  GchPage<T> current() => getPage(_currentPage);

  List<int> get pageNumbers => List.generate(totalPages, (i) => i + 1);

  List<int> get visiblePageNumbers {
    const maxVisible = 7;
    if (totalPages <= maxVisible) return pageNumbers;
    final start = max(1, _currentPage - 3);
    final end = min(totalPages, start + maxVisible - 1);
    return List.generate(end - start + 1, (i) => start + i);
  }

  void replaceAll(List<T> newItems) {
    _allItems = List.from(newItems);
    _currentPage = 1;
  }

  void addItem(T item) {
    _allItems.add(item);
  }

  bool removeItem(bool Function(T) predicate) {
    final idx = _allItems.indexWhere(predicate);
    if (idx < 0) return false;
    _allItems.removeAt(idx);
    _currentPage = _currentPage.clamp(1, totalPages);
    return true;
  }

  void updateItem(bool Function(T) predicate, T newItem) {
    final idx = _allItems.indexWhere(predicate);
    if (idx >= 0) _allItems[idx] = newItem;
  }

  @override
  String toString() =>
      'GchPaginator(items=${_allItems.length}, page=$_currentPage/$totalPages, size=$_pageSize)';
}

// ──────────────────────────────────────────────
// GchAsyncPaginator<T>
// ──────────────────────────────────────────────
class GchAsyncPaginator<T> {
  final Future<GchPage<T>> Function(int page, int pageSize) fetcher;
  final int pageSize;

  final Map<int, GchPage<T>> _cache = {};
  int _currentPage = 1;
  GchPage<T>? _lastPage;

  GchAsyncPaginator(this.fetcher, {this.pageSize = 20});

  Map<int, GchPage<T>> get cachedPages => Map.unmodifiable(_cache);

  Future<GchPage<T>> loadPage(int page) async {
    if (_cache.containsKey(page)) {
      _currentPage = page;
      _lastPage = _cache[page]!;
      return _lastPage!;
    }
    final result = await fetcher(page, pageSize);
    _cache[page] = result;
    _currentPage = page;
    _lastPage = result;
    return result;
  }

  Future<GchPage<T>> loadNext() async {
    final next = (_lastPage?.info.nextPage) ?? (_currentPage + 1);
    return loadPage(next);
  }

  Future<GchPage<T>> loadPrev() async {
    final prev = (_lastPage?.info.prevPage) ?? max(1, _currentPage - 1);
    return loadPage(prev);
  }

  Future<void> preloadNext() async {
    final next = (_lastPage?.info.nextPage) ?? (_currentPage + 1);
    if (!_cache.containsKey(next)) {
      final page = await fetcher(next, pageSize);
      _cache[next] = page;
    }
  }

  void clearCache() => _cache.clear();

  int get currentPage => _currentPage;

  bool isCached(int page) => _cache.containsKey(page);

  List<int> get cachedPageNumbers => _cache.keys.toList()..sort();

  void evictOldestCached({int keepCount = 5}) {
    if (_cache.length <= keepCount) return;
    final sorted = _cache.keys.toList()..sort();
    final toRemove = sorted.sublist(0, sorted.length - keepCount);
    for (final k in toRemove) _cache.remove(k);
  }
}

// ──────────────────────────────────────────────
// GchCursorPaginator<T>
// ──────────────────────────────────────────────
class GchCursorPaginator<T> {
  final Future<({List<T> items, String? nextCursor})> Function(
      String? cursor, int limit) fetcher;
  final int limit;

  String? _currentCursor;
  String? _nextCursor;
  bool _hasMore = true;
  final List<T> _allLoaded = [];

  GchCursorPaginator(this.fetcher, {this.limit = 20});

  bool get hasMore => _hasMore;
  String? get currentCursor => _currentCursor;
  List<T> get allLoaded => List.unmodifiable(_allLoaded);

  Future<List<T>> loadNext() async {
    if (!_hasMore) return [];
    final result = await fetcher(_nextCursor, limit);
    _currentCursor = _nextCursor;
    _nextCursor = result.nextCursor;
    _hasMore = result.nextCursor != null;
    _allLoaded.addAll(result.items);
    return result.items;
  }

  void reset() {
    _currentCursor = null;
    _nextCursor = null;
    _hasMore = true;
    _allLoaded.clear();
  }

  int get totalLoadedCount => _allLoaded.length;

  GchPage<T> asPage() {
    return GchPage<T>(
      items: _allLoaded,
      info: GchPageInfo(
        page: 1,
        pageSize: _allLoaded.length,
        totalItems: _allLoaded.length,
        totalPages: 1,
      ),
    );
  }

  Future<void> loadAll() async {
    while (_hasMore) {
      await loadNext();
    }
  }
}

// ──────────────────────────────────────────────
// GchInfiniteList<T>
// ──────────────────────────────────────────────
class GchInfiniteList<T> {
  final List<T> _items = [];
  bool _hasMore;
  final StreamController<List<T>> _controller =
      StreamController<List<T>>.broadcast();

  GchInfiniteList({bool hasMore = true}) : _hasMore = hasMore;

  Stream<List<T>> get stream => _controller.stream;

  bool get hasMore => _hasMore;
  int get totalLoaded => _items.length;
  bool get isEmpty => _items.isEmpty;

  List<T> get items => List.unmodifiable(_items);

  void append(List<T> newItems) {
    _items.addAll(newItems);
    _controller.add(List.unmodifiable(_items));
  }

  void prepend(List<T> newItems) {
    _items.insertAll(0, newItems);
    _controller.add(List.unmodifiable(_items));
  }

  void clear() {
    _items.clear();
    _hasMore = true;
    _controller.add([]);
  }

  List<T> slice(int start, int end) {
    final s = start.clamp(0, _items.length);
    final e = end.clamp(s, _items.length);
    return _items.sublist(s, e);
  }

  void removeDuplicates(bool Function(T, T) equals) {
    final result = <T>[];
    for (final item in _items) {
      bool isDuplicate = false;
      for (final r in result) {
        if (equals(r, item)) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate) result.add(item);
    }
    _items
      ..clear()
      ..addAll(result);
    _controller.add(List.unmodifiable(_items));
  }

  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _controller.add(List.unmodifiable(_items));
    }
  }

  void updateAt(int index, T item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      _controller.add(List.unmodifiable(_items));
    }
  }

  void insertAt(int index, T item) {
    final clampedIdx = index.clamp(0, _items.length);
    _items.insert(clampedIdx, item);
    _controller.add(List.unmodifiable(_items));
  }

  void markNoMore() {
    _hasMore = false;
  }

  void sort(Comparator<T> comparator) {
    _items.sort(comparator);
    _controller.add(List.unmodifiable(_items));
  }

  GchPage<T> asPage({int pageSize = 20, int page = 1}) {
    final start = (page - 1) * pageSize;
    final end = min(start + pageSize, _items.length);
    final pageItems = start < _items.length ? _items.sublist(start, end) : <T>[];
    final totalPages = max(1, (_items.length / pageSize).ceil());
    return GchPage<T>(
      items: pageItems,
      info: GchPageInfo(
        page: page,
        pageSize: pageSize,
        totalItems: _items.length,
        totalPages: totalPages,
      ),
    );
  }

  void dispose() {
    _controller.close();
  }
}

// ──────────────────────────────────────────────
// GchOffsetPaginator<T>  (offset-based async)
// ──────────────────────────────────────────────
class GchOffsetPaginator<T> {
  final Future<List<T>> Function(int offset, int limit) fetcher;
  final int limit;

  int _offset = 0;
  bool _hasMore = true;
  final List<T> _buffer = [];

  GchOffsetPaginator(this.fetcher, {this.limit = 20});

  bool get hasMore => _hasMore;
  int get loadedCount => _buffer.length;
  int get currentOffset => _offset;

  Future<List<T>> loadNext() async {
    if (!_hasMore) return [];
    final results = await fetcher(_offset, limit);
    if (results.length < limit) {
      _hasMore = false;
    }
    _offset += results.length;
    _buffer.addAll(results);
    return results;
  }

  void reset() {
    _offset = 0;
    _hasMore = true;
    _buffer.clear();
  }

  List<T> get allItems => List.unmodifiable(_buffer);

  GchPage<T> getBufferedPage(int page, {int pageSize = 20}) {
    final start = (page - 1) * pageSize;
    final end = min(start + pageSize, _buffer.length);
    final items = start < _buffer.length ? _buffer.sublist(start, end) : <T>[];
    final totalPages = max(1, (_buffer.length / pageSize).ceil());
    return GchPage<T>(
      items: items,
      info: GchPageInfo(
        page: page,
        pageSize: pageSize,
        totalItems: _buffer.length,
        totalPages: totalPages,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// GchPaginationUtil  – static helpers
// ──────────────────────────────────────────────
class GchPaginationUtil {
  GchPaginationUtil._();

  static GchPageInfo buildPageInfo(
      {required int page, required int pageSize, required int totalItems}) {
    final totalPages = totalItems == 0 ? 1 : (totalItems / pageSize).ceil();
    return GchPageInfo(
      page: page.clamp(1, totalPages),
      pageSize: pageSize,
      totalItems: totalItems,
      totalPages: totalPages,
    );
  }

  static List<T> paginate<T>(List<T> items, int page, int pageSize) {
    if (items.isEmpty) return [];
    final start = ((page - 1) * pageSize).clamp(0, items.length);
    final end = (start + pageSize).clamp(start, items.length);
    return items.sublist(start, end);
  }

  static Map<String, dynamic> toJson(GchPageInfo info) => {
        'page': info.page,
        'pageSize': info.pageSize,
        'totalItems': info.totalItems,
        'totalPages': info.totalPages,
        'hasNext': info.hasNext,
        'hasPrev': info.hasPrev,
        'nextPage': info.nextPage,
        'prevPage': info.prevPage,
      };

  static GchPageInfo fromJson(Map<String, dynamic> json) => GchPageInfo(
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
        totalItems: json['totalItems'] as int,
        totalPages: json['totalPages'] as int,
      );

  static List<int> windowedPageNumbers(
      int currentPage, int totalPages, int windowSize) {
    if (totalPages <= windowSize) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = max(1, currentPage - windowSize ~/ 2);
    int end = start + windowSize - 1;
    if (end > totalPages) {
      end = totalPages;
      start = max(1, end - windowSize + 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  static Map<K, GchPage<T>> groupIntoPages<T, K>(
      List<T> items, K Function(T) keyExtractor, int pageSize) {
    final grouped = <K, List<T>>{};
    for (final item in items) {
      final key = keyExtractor(item);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped.map((key, list) {
      final info = buildPageInfo(page: 1, pageSize: pageSize, totalItems: list.length);
      return MapEntry(key, GchPage<T>(items: list.take(pageSize).toList(), info: info));
    });
  }

  static GchPage<T> emptyPage<T>({int pageSize = 20}) {
    return GchPage<T>(
      items: [],
      info: GchPageInfo(
        page: 1,
        pageSize: pageSize,
        totalItems: 0,
        totalPages: 1,
      ),
    );
  }

  static GchPage<T> mergePagesAsSingle<T>(List<GchPage<T>> pages) {
    final allItems = pages.expand((p) => p.items).toList();
    return GchPage<T>(
      items: allItems,
      info: GchPageInfo(
        page: 1,
        pageSize: allItems.length,
        totalItems: allItems.length,
        totalPages: 1,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// GchSearchablePaginator<T>
// ──────────────────────────────────────────────
class GchSearchablePaginator<T> {
  final List<T> _originalItems;
  List<T> _filteredItems;
  int _pageSize;
  int _currentPage = 1;
  String _searchQuery = '';
  Comparator<T>? _sorter;
  bool Function(T item)? _activeFilter;

  GchSearchablePaginator(List<T> items, {int pageSize = 20})
      : _originalItems = List.from(items),
        _filteredItems = List.from(items),
        _pageSize = pageSize;

  String get searchQuery => _searchQuery;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalResults => _filteredItems.length;
  int get totalPages => max(1, (_filteredItems.length / _pageSize).ceil());

  void setPageSize(int size) {
    _pageSize = max(1, size);
    _currentPage = 1;
  }

  void search(String query, bool Function(T item, String query) matcher) {
    _searchQuery = query;
    _apply(matcher);
  }

  void clearSearch(bool Function(T item, String query) matcher) {
    _searchQuery = '';
    _apply(matcher);
  }

  void setFilter(bool Function(T item) filter) {
    _activeFilter = filter;
    _rebuildFiltered();
  }

  void clearFilter() {
    _activeFilter = null;
    _rebuildFiltered();
  }

  void setSorter(Comparator<T> sorter) {
    _sorter = sorter;
    _rebuildFiltered();
  }

  void _apply(bool Function(T item, String query) matcher) {
    _rebuildFilteredWithMatcher(
        _searchQuery.isEmpty ? null : (T item) => matcher(item, _searchQuery));
  }

  void _rebuildFiltered() {
    _rebuildFilteredWithMatcher(_activeFilter);
  }

  void _rebuildFilteredWithMatcher(bool Function(T)? filter) {
    var result = List<T>.from(_originalItems);
    if (filter != null) result = result.where(filter).toList();
    if (_activeFilter != null && filter != _activeFilter) {
      result = result.where(_activeFilter!).toList();
    }
    if (_sorter != null) result.sort(_sorter);
    _filteredItems = result;
    _currentPage = 1;
  }

  GchPage<T> getPage(int page) {
    final clampedPage = page.clamp(1, totalPages);
    _currentPage = clampedPage;
    final start = (clampedPage - 1) * _pageSize;
    final end = min(start + _pageSize, _filteredItems.length);
    final pageItems =
        start < _filteredItems.length ? _filteredItems.sublist(start, end) : <T>[];
    return GchPage<T>(
      items: pageItems,
      info: GchPageInfo(
        page: clampedPage,
        pageSize: _pageSize,
        totalItems: _filteredItems.length,
        totalPages: totalPages,
      ),
    );
  }

  GchPage<T> currentPageData() => getPage(_currentPage);

  GchPage<T> nextPage() => getPage(_currentPage + 1);

  GchPage<T> prevPage() => getPage(_currentPage - 1);
}
