// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';
import 'dart:collection';

extension GchListExt<T> on List<T> {
  T? get(int index, {T? fallback}) {
    if (index < 0 || index >= length) return fallback;
    return this[index];
  }

  List<T> safeSublist(int start, [int? end]) {
    final s = start.clamp(0, length);
    final e = (end ?? length).clamp(s, length);
    return sublist(s, e);
  }

  List<List<T>> chunk(int size) {
    if (size <= 0) return [];
    final result = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      result.add(safeSublist(i, i + size));
    }
    return result;
  }

  List<List<T>> sliding(int size, {int step = 1}) {
    if (size <= 0 || step <= 0) return [];
    final result = <List<T>>[];
    for (int i = 0; i + size <= length; i += step) {
      result.add(sublist(i, i + size));
    }
    return result;
  }

  List<T> interleave(T separator) {
    if (isEmpty) return [];
    final result = <T>[];
    for (int i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) result.add(separator);
    }
    return result;
  }

  List<T> unique({Object Function(T)? by}) {
    final seen = <Object>{};
    final result = <T>[];
    for (final item in this) {
      final key = by != null ? by(item) : item as Object;
      if (seen.add(key)) {
        result.add(item);
      }
    }
    return result;
  }

  Map<K, List<T>> groupBy<K>(K Function(T) key) {
    final map = <K, List<T>>{};
    for (final item in this) {
      final k = key(item);
      map.putIfAbsent(k, () => <T>[]).add(item);
    }
    return map;
  }

  List<T> sortedBy<K extends Comparable>(K Function(T) key, {bool descending = false}) {
    final copy = List<T>.from(this);
    copy.sort((a, b) {
      final cmp = key(a).compareTo(key(b));
      return descending ? -cmp : cmp;
    });
    return copy;
  }

  T? minBy<K extends Comparable>(K Function(T) key) {
    if (isEmpty) return null;
    T minItem = first;
    K minKey = key(first);
    for (int i = 1; i < length; i++) {
      final k = key(this[i]);
      if (k.compareTo(minKey) < 0) {
        minItem = this[i];
        minKey = k;
      }
    }
    return minItem;
  }

  T? maxBy<K extends Comparable>(K Function(T) key) {
    if (isEmpty) return null;
    T maxItem = first;
    K maxKey = key(first);
    for (int i = 1; i < length; i++) {
      final k = key(this[i]);
      if (k.compareTo(maxKey) > 0) {
        maxItem = this[i];
        maxKey = k;
      }
    }
    return maxItem;
  }

  num sumBy(num Function(T) selector) {
    num total = 0;
    for (final item in this) {
      total += selector(item);
    }
    return total;
  }

  double averageBy(num Function(T) selector) {
    if (isEmpty) return 0.0;
    return sumBy(selector) / length;
  }

  int countWhere(bool Function(T) predicate) {
    int count = 0;
    for (final item in this) {
      if (predicate(item)) count++;
    }
    return count;
  }

  (List<T>, List<T>) partition(bool Function(T) predicate) {
    final trueList = <T>[];
    final falseList = <T>[];
    for (final item in this) {
      if (predicate(item)) {
        trueList.add(item);
      } else {
        falseList.add(item);
      }
    }
    return (trueList, falseList);
  }

  List<R> zip<B, R>(List<B> other, R Function(T, B) combine) {
    final result = <R>[];
    final len = min(length, other.length);
    for (int i = 0; i < len; i++) {
      result.add(combine(this[i], other[i]));
    }
    return result;
  }

  List<T> rotate(int positions) {
    if (isEmpty) return List<T>.from(this);
    final n = length;
    final pos = ((positions % n) + n) % n;
    return [...sublist(pos), ...sublist(0, pos)];
  }

  List<T> takeWhileRight(bool Function(T) test) {
    final result = <T>[];
    for (int i = length - 1; i >= 0; i--) {
      if (test(this[i])) {
        result.insert(0, this[i]);
      } else {
        break;
      }
    }
    return result;
  }

  List<T> dropWhile(bool Function(T) test) {
    int start = 0;
    while (start < length && test(this[start])) {
      start++;
    }
    return sublist(start);
  }

  List<T> dropWhileRight(bool Function(T) test) {
    int end = length;
    while (end > 0 && test(this[end - 1])) {
      end--;
    }
    return sublist(0, end);
  }

  List<T> sample(int count, {Random? rng}) {
    final rand = rng ?? Random();
    final copy = List<T>.from(this);
    final n = min(count, length);
    for (int i = copy.length - 1; i > copy.length - 1 - n; i--) {
      final j = rand.nextInt(i + 1);
      final temp = copy[i];
      copy[i] = copy[j];
      copy[j] = temp;
    }
    return copy.sublist(copy.length - n);
  }

  Map<T, int> frequencies() {
    final map = <T, int>{};
    for (final item in this) {
      map[item] = (map[item] ?? 0) + 1;
    }
    return map;
  }

  T? mode() {
    if (isEmpty) return null;
    final freq = frequencies();
    T? result;
    int maxCount = 0;
    for (final entry in freq.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        result = entry.key;
      }
    }
    return result;
  }

  List<List<T>> permutations() {
    if (length > 8) throw ArgumentError('permutations() is limited to lists of 8 elements or fewer');
    if (isEmpty) return [[]];
    final result = <List<T>>[];
    void generate(List<T> current, List<T> remaining) {
      if (remaining.isEmpty) {
        result.add(List<T>.from(current));
        return;
      }
      for (int i = 0; i < remaining.length; i++) {
        current.add(remaining[i]);
        final next = [...remaining.sublist(0, i), ...remaining.sublist(i + 1)];
        generate(current, next);
        current.removeLast();
      }
    }
    generate([], List<T>.from(this));
    return result;
  }

  List<List<T>> combinations(int k) {
    if (k <= 0 || k > length) return k == 0 ? [[]] : [];
    final result = <List<T>>[];
    void generate(int start, List<T> current) {
      if (current.length == k) {
        result.add(List<T>.from(current));
        return;
      }
      for (int i = start; i < length; i++) {
        current.add(this[i]);
        generate(i + 1, current);
        current.removeLast();
      }
    }
    generate(0, []);
    return result;
  }

  List<T> shuffled({Random? rng}) {
    final rand = rng ?? Random();
    final copy = List<T>.from(this);
    for (int i = copy.length - 1; i > 0; i--) {
      final j = rand.nextInt(i + 1);
      final temp = copy[i];
      copy[i] = copy[j];
      copy[j] = temp;
    }
    return copy;
  }

  List<T> padLeft(int targetLength, T fill) {
    if (length >= targetLength) return List<T>.from(this);
    return [...List<T>.filled(targetLength - length, fill), ...this];
  }

  List<T> padRight(int targetLength, T fill) {
    if (length >= targetLength) return List<T>.from(this);
    return [...this, ...List<T>.filled(targetLength - length, fill)];
  }

  T? firstOrNull() => isEmpty ? null : first;
  T? lastOrNull() => isEmpty ? null : last;

  List<T> takeLast(int n) {
    if (n <= 0) return [];
    if (n >= length) return List<T>.from(this);
    return sublist(length - n);
  }

  List<T> dropLast(int n) {
    if (n <= 0) return List<T>.from(this);
    if (n >= length) return [];
    return sublist(0, length - n);
  }
}

extension GchNestedListExt<E> on List<List<E>> {
  List<E> flatten() {
    final result = <E>[];
    for (final inner in this) {
      result.addAll(inner);
    }
    return result;
  }
}

extension GchIntListExt on List<int> {
  int get sum => fold(0, (acc, v) => acc + v);
  int get product => fold(1, (acc, v) => acc * v);
  double get mean => isEmpty ? 0.0 : sum / length;

  double get median {
    if (isEmpty) return 0.0;
    final sorted = List<int>.from(this)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid].toDouble();
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  double get variance {
    if (isEmpty) return 0.0;
    final m = mean;
    final sumSq = fold<double>(0, (acc, v) => acc + (v - m) * (v - m));
    return sumSq / length;
  }

  double get stdDev => sqrt(variance);

  int get range {
    if (isEmpty) return 0;
    int mn = first;
    int mx = first;
    for (final v in this) {
      if (v < mn) mn = v;
      if (v > mx) mx = v;
    }
    return mx - mn;
  }

  int get minValue => isEmpty ? 0 : reduce(min);
  int get maxValue => isEmpty ? 0 : reduce(max);

  List<int> sorted({bool descending = false}) {
    final copy = List<int>.from(this)..sort();
    if (descending) return copy.reversed.toList();
    return copy;
  }
}

extension GchDoubleListExt on List<double> {
  double get sum => fold(0.0, (acc, v) => acc + v);
  double get product => fold(1.0, (acc, v) => acc * v);
  double get mean => isEmpty ? 0.0 : sum / length;

  double get median {
    if (isEmpty) return 0.0;
    final sorted = List<double>.from(this)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  double get variance {
    if (isEmpty) return 0.0;
    final m = mean;
    final sumSq = fold<double>(0, (acc, v) => acc + (v - m) * (v - m));
    return sumSq / length;
  }

  double get stdDev => sqrt(variance);

  double get range {
    if (isEmpty) return 0;
    double mn = first;
    double mx = first;
    for (final v in this) {
      if (v < mn) mn = v;
      if (v > mx) mx = v;
    }
    return mx - mn;
  }

  double get minValue => isEmpty ? 0 : reduce(min);
  double get maxValue => isEmpty ? 0 : reduce(max);

  List<double> normalize() {
    if (isEmpty) return [];
    final mn = minValue;
    final mx = maxValue;
    final r = mx - mn;
    if (r == 0) return List<double>.filled(length, 0.0);
    return map((v) => (v - mn) / r).toList();
  }

  List<double> cumsum() {
    final result = <double>[];
    double acc = 0;
    for (final v in this) {
      acc += v;
      result.add(acc);
    }
    return result;
  }

  List<double> diff() {
    if (length < 2) return [];
    return List.generate(length - 1, (i) => this[i + 1] - this[i]);
  }

  List<double> movingAverage(int window) {
    if (window <= 0 || isEmpty) return [];
    final result = <double>[];
    for (int i = 0; i < length; i++) {
      final start = max(0, i - window + 1);
      final slice = sublist(start, i + 1);
      result.add(slice.reduce((a, b) => a + b) / slice.length);
    }
    return result;
  }

  List<double> sorted({bool descending = false}) {
    final copy = List<double>.from(this)..sort();
    if (descending) return copy.reversed.toList();
    return copy;
  }

  List<double> clampAll(double minVal, double maxVal) {
    return map((v) => v.clamp(minVal, maxVal)).toList();
  }

  List<double> scaleAll(double factor) => map((v) => v * factor).toList();
  List<double> addAll2(double offset) => map((v) => v + offset).toList();

  double dot(List<double> other) {
    final len = min(length, other.length);
    double result = 0;
    for (int i = 0; i < len; i++) {
      result += this[i] * other[i];
    }
    return result;
  }

  double get magnitude => sqrt(fold<double>(0, (acc, v) => acc + v * v));

  List<double> get unit {
    final mag = magnitude;
    if (mag == 0) return List<double>.from(this);
    return map((v) => v / mag).toList();
  }
}

class GchListUtil {
  static List<T> generate<T>(int count, T Function(int) generator) {
    return List.generate(count, generator);
  }

  static List<T> repeat<T>(T value, int count) {
    return List.filled(count, value);
  }

  static List<T> concat<T>(List<List<T>> lists) {
    final result = <T>[];
    for (final list in lists) {
      result.addAll(list);
    }
    return result;
  }

  static List<int> range(int start, int end, {int step = 1}) {
    if (step == 0) throw ArgumentError('step cannot be zero');
    final result = <int>[];
    if (step > 0) {
      for (int i = start; i < end; i += step) {
        result.add(i);
      }
    } else {
      for (int i = start; i > end; i += step) {
        result.add(i);
      }
    }
    return result;
  }

  static (List<T>, List<T>) unzip<T>(List<(T, T)> pairs) {
    final a = <T>[];
    final b = <T>[];
    for (final pair in pairs) {
      a.add(pair.$1);
      b.add(pair.$2);
    }
    return (a, b);
  }

  static List<List<T>> cartesianProduct<T>(List<List<T>> lists) {
    if (lists.isEmpty) return [[]];
    final result = <List<T>>[];
    final rest = cartesianProduct(lists.sublist(1));
    for (final item in lists[0]) {
      for (final r in rest) {
        result.add([item, ...r]);
      }
    }
    return result;
  }

  static int binarySearch<T extends Comparable>(List<T> sortedList, T target) {
    int lo = 0;
    int hi = sortedList.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      final cmp = sortedList[mid].compareTo(target);
      if (cmp == 0) return mid;
      if (cmp < 0) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return -1;
  }

  static void stableSort<T>(List<T> list, Comparator<T> compare) {
    final indexed = List.generate(list.length, (i) => (i, list[i]));
    indexed.sort((a, b) {
      final cmp = compare(a.$2, b.$2);
      if (cmp != 0) return cmp;
      return a.$1.compareTo(b.$1);
    });
    for (int i = 0; i < list.length; i++) {
      list[i] = indexed[i].$2;
    }
  }

  static List<T> flatten<T>(List<dynamic> nested) {
    final result = <T>[];
    void recurse(dynamic item) {
      if (item is List) {
        for (final child in item) {
          recurse(child);
        }
      } else if (item is T) {
        result.add(item);
      }
    }
    recurse(nested);
    return result;
  }

  static Map<K, int> histogram<T, K>(List<T> list, K Function(T) key) {
    final map = <K, int>{};
    for (final item in list) {
      final k = key(item);
      map[k] = (map[k] ?? 0) + 1;
    }
    return map;
  }

  static List<T> interleaveMultiple<T>(List<List<T>> lists) {
    final result = <T>[];
    final iters = lists.map((l) => l.iterator).toList();
    bool hasAny = true;
    while (hasAny) {
      hasAny = false;
      for (final iter in iters) {
        if (iter.moveNext()) {
          result.add(iter.current);
          hasAny = true;
        }
      }
    }
    return result;
  }

  static List<(A, B)> zipTwo<A, B>(List<A> a, List<B> b) {
    final len = min(a.length, b.length);
    return List.generate(len, (i) => (a[i], b[i]));
  }

  static List<List<T>> transpose<T>(List<List<T>> matrix) {
    if (matrix.isEmpty || matrix[0].isEmpty) return [];
    final rows = matrix.length;
    final cols = matrix[0].length;
    return List.generate(cols, (c) => List.generate(rows, (r) => matrix[r][c]));
  }

  static List<T> deduplicate<T>(List<T> list) {
    final seen = LinkedHashSet<T>();
    seen.addAll(list);
    return seen.toList();
  }

  static List<List<T>> windows<T>(List<T> list, int size) {
    if (size <= 0 || size > list.length) return [];
    return List.generate(
      list.length - size + 1,
      (i) => list.sublist(i, i + size),
    );
  }

  static T? findFirst<T>(List<T> list, bool Function(T) predicate) {
    for (final item in list) {
      if (predicate(item)) return item;
    }
    return null;
  }

  static T? findLast<T>(List<T> list, bool Function(T) predicate) {
    for (int i = list.length - 1; i >= 0; i--) {
      if (predicate(list[i])) return list[i];
    }
    return null;
  }

  static int indexOfFirst<T>(List<T> list, bool Function(T) predicate) {
    for (int i = 0; i < list.length; i++) {
      if (predicate(list[i])) return i;
    }
    return -1;
  }

  static int indexOfLast<T>(List<T> list, bool Function(T) predicate) {
    for (int i = list.length - 1; i >= 0; i--) {
      if (predicate(list[i])) return i;
    }
    return -1;
  }

  static List<T> mergeSort<T>(List<T> list, Comparator<T> compare) {
    if (list.length <= 1) return List<T>.from(list);
    final mid = list.length ~/ 2;
    final left = mergeSort(list.sublist(0, mid), compare);
    final right = mergeSort(list.sublist(mid), compare);
    return _merge<T>(left, right, compare);
  }

  static List<T> _merge<T>(List<T> left, List<T> right, Comparator<T> compare) {
    final result = <T>[];
    int i = 0, j = 0;
    while (i < left.length && j < right.length) {
      if (compare(left[i], right[j]) <= 0) {
        result.add(left[i++]);
      } else {
        result.add(right[j++]);
      }
    }
    result.addAll(left.sublist(i));
    result.addAll(right.sublist(j));
    return result;
  }

  static List<T> insertionSort<T>(List<T> list, Comparator<T> compare) {
    final copy = List<T>.from(list);
    for (int i = 1; i < copy.length; i++) {
      final key = copy[i];
      int j = i - 1;
      while (j >= 0 && compare(copy[j], key) > 0) {
        copy[j + 1] = copy[j];
        j--;
      }
      copy[j + 1] = key;
    }
    return copy;
  }

  static List<T> quickSort<T>(List<T> list, Comparator<T> compare) {
    if (list.length <= 1) return List<T>.from(list);
    final pivot = list[list.length ~/ 2];
    final left = list.where((e) => compare(e, pivot) < 0).toList();
    final middle = list.where((e) => compare(e, pivot) == 0).toList();
    final right = list.where((e) => compare(e, pivot) > 0).toList();
    return [...quickSort(left, compare), ...middle, ...quickSort(right, compare)];
  }

  static List<T> topN<T>(List<T> list, int n, Comparator<T> compare) {
    if (n <= 0) return [];
    final copy = List<T>.from(list);
    stableSort(copy, compare);
    return copy.takeLast(n);
  }

  static List<T> bottomN<T>(List<T> list, int n, Comparator<T> compare) {
    if (n <= 0) return [];
    final copy = List<T>.from(list);
    stableSort(copy, compare);
    return copy.take(n).toList();
  }

  static List<T> takeLast<T>(List<T> list, int n) {
    if (n <= 0) return [];
    if (n >= list.length) return List<T>.from(list);
    return list.sublist(list.length - n);
  }

  static List<T> interleave<T>(List<T> a, List<T> b) {
    final result = <T>[];
    final len = max(a.length, b.length);
    for (int i = 0; i < len; i++) {
      if (i < a.length) result.add(a[i]);
      if (i < b.length) result.add(b[i]);
    }
    return result;
  }

  static Map<K, List<T>> groupBy<T, K>(List<T> list, K Function(T) key) {
    final map = <K, List<T>>{};
    for (final item in list) {
      map.putIfAbsent(key(item), () => []).add(item);
    }
    return map;
  }

  static List<T> distinct<T>(List<T> list, [Object Function(T)? keySelector]) {
    final seen = <Object>{};
    final result = <T>[];
    for (final item in list) {
      final key = keySelector != null ? keySelector(item) : item as Object;
      if (seen.add(key)) result.add(item);
    }
    return result;
  }

  static List<T> difference<T>(List<T> a, List<T> b) {
    final setB = Set<T>.from(b);
    return a.where((item) => !setB.contains(item)).toList();
  }

  static List<T> intersection<T>(List<T> a, List<T> b) {
    final setB = Set<T>.from(b);
    return a.where(setB.contains).toList();
  }

  static List<T> union<T>(List<T> a, List<T> b) {
    final result = List<T>.from(a);
    final setA = Set<T>.from(a);
    for (final item in b) {
      if (!setA.contains(item)) result.add(item);
    }
    return result;
  }

  static bool isSorted<T extends Comparable>(List<T> list, {bool descending = false}) {
    for (int i = 0; i < list.length - 1; i++) {
      final cmp = list[i].compareTo(list[i + 1]);
      if (descending ? cmp < 0 : cmp > 0) return false;
    }
    return true;
  }

  static List<T> cycle<T>(List<T> list, int totalLength) {
    if (list.isEmpty) return [];
    final result = <T>[];
    while (result.length < totalLength) {
      result.add(list[result.length % list.length]);
    }
    return result.take(totalLength).toList();
  }

  static int longestIncreasingSubsequence(List<int> list) {
    if (list.isEmpty) return 0;
    final tails = <int>[];
    for (final val in list) {
      int lo = 0, hi = tails.length;
      while (lo < hi) {
        final mid = (lo + hi) ~/ 2;
        if (tails[mid] < val) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      if (lo == tails.length) {
        tails.add(val);
      } else {
        tails[lo] = val;
      }
    }
    return tails.length;
  }

  static List<int> prefixSums(List<int> list) {
    final result = List<int>.filled(list.length + 1, 0);
    for (int i = 0; i < list.length; i++) {
      result[i + 1] = result[i] + list[i];
    }
    return result;
  }

  static int rangeSum(List<int> prefixSums, int from, int to) {
    if (from < 0 || to >= prefixSums.length - 1 || from > to) return 0;
    return prefixSums[to + 1] - prefixSums[from];
  }

  static List<T> flatten2D<T>(List<List<T>> nested) {
    return nested.expand((l) => l).toList();
  }

  static List<List<T>> splitAt<T>(List<T> list, int index) {
    if (index <= 0) return [[], List<T>.from(list)];
    if (index >= list.length) return [List<T>.from(list), []];
    return [list.sublist(0, index), list.sublist(index)];
  }
}
