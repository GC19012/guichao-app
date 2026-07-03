// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// GchSortAlgo – 12 sorting algorithms, all as static generic methods
// ─────────────────────────────────────────────────────────────────────────────
class GchSortAlgo {
  GchSortAlgo._();

  // ── 1. Bubble Sort ─────────────────────────────────────────────────────────
  static List<T> bubbleSort<T extends Comparable<T>>(
    List<T> list, {
    Comparator<T>? comparator,
  }) {
    final arr = List<T>.from(list);
    final cmp = comparator ?? (a, b) => a.compareTo(b);
    final n = arr.length;
    for (int i = 0; i < n - 1; i++) {
      bool swapped = false;
      for (int j = 0; j < n - 1 - i; j++) {
        if (cmp(arr[j], arr[j + 1]) > 0) {
          final tmp = arr[j];
          arr[j] = arr[j + 1];
          arr[j + 1] = tmp;
          swapped = true;
        }
      }
      if (!swapped) break;
    }
    return arr;
  }

  // ── 2. Selection Sort ──────────────────────────────────────────────────────
  static List<T> selectionSort<T extends Comparable<T>>(
    List<T> list, {
    Comparator<T>? comparator,
  }) {
    final arr = List<T>.from(list);
    final cmp = comparator ?? (a, b) => a.compareTo(b);
    final n = arr.length;
    for (int i = 0; i < n - 1; i++) {
      int minIdx = i;
      for (int j = i + 1; j < n; j++) {
        if (cmp(arr[j], arr[minIdx]) < 0) minIdx = j;
      }
      if (minIdx != i) {
        final tmp = arr[i];
        arr[i] = arr[minIdx];
        arr[minIdx] = tmp;
      }
    }
    return arr;
  }

  // ── 3. Insertion Sort ──────────────────────────────────────────────────────
  static List<T> insertionSort<T extends Comparable<T>>(
    List<T> list, {
    Comparator<T>? comparator,
  }) {
    final arr = List<T>.from(list);
    final cmp = comparator ?? (a, b) => a.compareTo(b);
    for (int i = 1; i < arr.length; i++) {
      final key = arr[i];
      int j = i - 1;
      while (j >= 0 && cmp(arr[j], key) > 0) {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[j + 1] = key;
    }
    return arr;
  }

  // ── 4. Shell Sort ──────────────────────────────────────────────────────────
  static List<T> shellSort<T extends Comparable<T>>(
    List<T> list, {
    Comparator<T>? comparator,
  }) {
    final arr = List<T>.from(list);
    final cmp = comparator ?? (a, b) => a.compareTo(b);
    int gap = arr.length ~/ 2;
    while (gap > 0) {
      for (int i = gap; i < arr.length; i++) {
        final temp = arr[i];
        int j = i;
        while (j >= gap && cmp(arr[j - gap], temp) > 0) {
          arr[j] = arr[j - gap];
          j -= gap;
        }
        arr[j] = temp;
      }
      gap ~/= 2;
    }
    return arr;
  }

  // ── 5. Merge Sort ──────────────────────────────────────────────────────────
  static List<T> mergeSort<T extends Comparable<T>>(
    List<T> list, {
    Comparator<T>? comparator,
  }) {
    if (list.length <= 1) return List<T>.from(list);
    final arr = List<T>.from(list);
    final cmp = comparator ?? (a, b) => a.compareTo(b);
    _mergeSortHelper(arr, 0, arr.length - 1, cmp);
    return arr;
  }

  static void _mergeSortHelper<T>(
      List<T> arr, int left, int right, Comparator<T> cmp) {
    if (left >= right) return;
    final mid = (left + right) ~/ 2;
    _mergeSortHelper(arr, left, mid, cmp);
    _mergeSortHelper(arr, mid + 1, right, cmp);
    _merge(arr, left, mid, right, cmp);
  }

  static void _merge<T>(
      List<T> arr, int left, int mid, int right, Comparator<T> cmp) {
    final leftArr = arr.sublist(left, mid + 1);
    final rightArr = arr.sublist(mid + 1, right + 1);
    int i = 0, j = 0, k = left;
    while (i < leftArr.length && j < rightArr.length) {
      if (cmp(leftArr[i], rightArr[j]) <= 0) {
        arr[k++] = leftArr[i++];
      } else {
        arr[k++] = rightArr[j++];
      }
    }
    while (i < leftArr.length) arr[k++] = leftArr[i++];
    while (j < rightArr.length) arr[k++] = rightArr[j++];
  }

  // ── 6. Quick Sort ──────────────────────────────────────────────────────────
  static List<T> quickSort<T extends Comparable<T>>(
    List<T> list, {
    Comparator<T>? comparator,
  }) {
    if (list.length <= 1) return List<T>.from(list);
    final arr = List<T>.from(list);
    final cmp = comparator ?? (a, b) => a.compareTo(b);
    _quickSortHelper(arr, 0, arr.length - 1, cmp);
    return arr;
  }

  static void _quickSortHelper<T>(
      List<T> arr, int low, int high, Comparator<T> cmp) {
    if (low < high) {
      final pi = _partition(arr, low, high, cmp);
      _quickSortHelper(arr, low, pi - 1, cmp);
      _quickSortHelper(arr, pi + 1, high, cmp);
    }
  }

  static int _partition<T>(
      List<T> arr, int low, int high, Comparator<T> cmp) {
    final pivot = arr[high];
    int i = low - 1;
    for (int j = low; j < high; j++) {
      if (cmp(arr[j], pivot) <= 0) {
        i++;
        final tmp = arr[i];
        arr[i] = arr[j];
        arr[j] = tmp;
      }
    }
    final tmp = arr[i + 1];
    arr[i + 1] = arr[high];
    arr[high] = tmp;
    return i + 1;
  }

  // ── 7. Heap Sort ───────────────────────────────────────────────────────────
  static List<T> heapSort<T extends Comparable<T>>(
    List<T> list, {
    Comparator<T>? comparator,
  }) {
    final arr = List<T>.from(list);
    final cmp = comparator ?? (a, b) => a.compareTo(b);
    final n = arr.length;
    for (int i = n ~/ 2 - 1; i >= 0; i--) {
      _heapify(arr, n, i, cmp);
    }
    for (int i = n - 1; i > 0; i--) {
      final tmp = arr[0];
      arr[0] = arr[i];
      arr[i] = tmp;
      _heapify(arr, i, 0, cmp);
    }
    return arr;
  }

  static void _heapify<T>(
      List<T> arr, int n, int i, Comparator<T> cmp) {
    int largest = i;
    final left = 2 * i + 1;
    final right = 2 * i + 2;
    if (left < n && cmp(arr[left], arr[largest]) > 0) largest = left;
    if (right < n && cmp(arr[right], arr[largest]) > 0) largest = right;
    if (largest != i) {
      final tmp = arr[i];
      arr[i] = arr[largest];
      arr[largest] = tmp;
      _heapify(arr, n, largest, cmp);
    }
  }

  // ── 8. Counting Sort (int only) ────────────────────────────────────────────
  static List<int> countingSort(List<int> list) {
    if (list.isEmpty) return [];
    final minVal = list.reduce(min);
    final maxVal = list.reduce(max);
    final range = maxVal - minVal + 1;
    final count = List<int>.filled(range, 0);
    for (final x in list) count[x - minVal]++;
    final result = <int>[];
    for (int i = 0; i < range; i++) {
      for (int j = 0; j < count[i]; j++) {
        result.add(i + minVal);
      }
    }
    return result;
  }

  // ── 9. Radix Sort (int only, non-negative) ─────────────────────────────────
  static List<int> radixSort(List<int> list) {
    if (list.isEmpty) return [];
    final arr = List<int>.from(list);
    final maxVal = arr.reduce(max);
    for (int exp = 1; maxVal ~/ exp > 0; exp *= 10) {
      _countingSortByDigit(arr, exp);
    }
    return arr;
  }

  static void _countingSortByDigit(List<int> arr, int exp) {
    final n = arr.length;
    final output = List<int>.filled(n, 0);
    final count = List<int>.filled(10, 0);
    for (final x in arr) count[(x ~/ exp) % 10]++;
    for (int i = 1; i < 10; i++) count[i] += count[i - 1];
    for (int i = n - 1; i >= 0; i--) {
      final digit = (arr[i] ~/ exp) % 10;
      output[count[digit] - 1] = arr[i];
      count[digit]--;
    }
    for (int i = 0; i < n; i++) arr[i] = output[i];
  }

  // ── 10. Tim Sort (simplified: insertion sort for small, merge for large) ───
  static List<T> timSort<T extends Comparable<T>>(
    List<T> list, {
    Comparator<T>? comparator,
  }) {
    final arr = List<T>.from(list);
    final cmp = comparator ?? (a, b) => a.compareTo(b);
    const runSize = 32;
    final n = arr.length;
    for (int i = 0; i < n; i += runSize) {
      final end = min(i + runSize - 1, n - 1);
      _insertionSortRange(arr, i, end, cmp);
    }
    for (int size = runSize; size < n; size *= 2) {
      for (int left = 0; left < n; left += 2 * size) {
        final mid = min(left + size - 1, n - 1);
        final right = min(left + 2 * size - 1, n - 1);
        if (mid < right) _merge(arr, left, mid, right, cmp);
      }
    }
    return arr;
  }

  static void _insertionSortRange<T>(
      List<T> arr, int left, int right, Comparator<T> cmp) {
    for (int i = left + 1; i <= right; i++) {
      final key = arr[i];
      int j = i - 1;
      while (j >= left && cmp(arr[j], key) > 0) {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[j + 1] = key;
    }
  }

  // ── 11. Intro Sort (quicksort + heapsort fallback) ─────────────────────────
  static List<T> introSort<T extends Comparable<T>>(
    List<T> list, {
    Comparator<T>? comparator,
  }) {
    if (list.length <= 1) return List<T>.from(list);
    final arr = List<T>.from(list);
    final cmp = comparator ?? (a, b) => a.compareTo(b);
    final maxDepth = 2 * (log(arr.length) / log(2)).floor();
    _introSortHelper(arr, 0, arr.length - 1, maxDepth, cmp);
    return arr;
  }

  static void _introSortHelper<T extends Comparable<T>>(
      List<T> arr, int low, int high, int depthLimit, Comparator<T> cmp) {
    if (high - low < 16) {
      _insertionSortRange(arr, low, high, cmp);
      return;
    }
    if (depthLimit == 0) {
      _heapSortRange<T>(arr, low, high, cmp);
      return;
    }
    final pi = _partition(arr, low, high, cmp);
    _introSortHelper(arr, low, pi - 1, depthLimit - 1, cmp);
    _introSortHelper(arr, pi + 1, high, depthLimit - 1, cmp);
  }

  static void _heapSortRange<T extends Comparable<T>>(
      List<T> arr, int low, int high, Comparator<T> cmp) {
    final sub = arr.sublist(low, high + 1);
    final sorted = heapSort<T>(sub, comparator: cmp);
    for (int i = 0; i < sorted.length; i++) arr[low + i] = sorted[i];
  }

  // ── 12. Gnome Sort ─────────────────────────────────────────────────────────
  static List<T> gnomeSort<T extends Comparable<T>>(
    List<T> list, {
    Comparator<T>? comparator,
  }) {
    final arr = List<T>.from(list);
    final cmp = comparator ?? (a, b) => a.compareTo(b);
    int pos = 0;
    while (pos < arr.length) {
      if (pos == 0 || cmp(arr[pos], arr[pos - 1]) >= 0) {
        pos++;
      } else {
        final tmp = arr[pos];
        arr[pos] = arr[pos - 1];
        arr[pos - 1] = tmp;
        pos--;
      }
    }
    return arr;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GchSortBenchmark – benchmarking utilities
// ─────────────────────────────────────────────────────────────────────────────
class GchSortBenchmark {
  GchSortBenchmark._();

  static final Random _rng = Random(12345);

  static List<int> generateRandom(int size, {int maxVal = 10000}) {
    return List<int>.generate(size, (_) => _rng.nextInt(maxVal));
  }

  static List<int> generateNearlySorted(int size, int swaps) {
    final list = List<int>.generate(size, (i) => i);
    for (int i = 0; i < swaps; i++) {
      final a = _rng.nextInt(size);
      final b = _rng.nextInt(size);
      final tmp = list[a];
      list[a] = list[b];
      list[b] = tmp;
    }
    return list;
  }

  static List<int> generateReverseSorted(int size) {
    return List<int>.generate(size, (i) => size - i);
  }

  static List<int> generateSorted(int size) {
    return List<int>.generate(size, (i) => i);
  }

  static Map<String, Duration> benchmark(List<int> data) {
    final results = <String, Duration>{};

    DateTime t;
    t = DateTime.now();
    GchSortAlgo.bubbleSort<num>(data);
    results['bubbleSort'] = DateTime.now().difference(t);

    t = DateTime.now();
    GchSortAlgo.selectionSort<num>(data);
    results['selectionSort'] = DateTime.now().difference(t);

    t = DateTime.now();
    GchSortAlgo.insertionSort<num>(data);
    results['insertionSort'] = DateTime.now().difference(t);

    t = DateTime.now();
    GchSortAlgo.shellSort<num>(data);
    results['shellSort'] = DateTime.now().difference(t);

    t = DateTime.now();
    GchSortAlgo.mergeSort<num>(data);
    results['mergeSort'] = DateTime.now().difference(t);

    t = DateTime.now();
    GchSortAlgo.quickSort<num>(data);
    results['quickSort'] = DateTime.now().difference(t);

    t = DateTime.now();
    GchSortAlgo.heapSort<num>(data);
    results['heapSort'] = DateTime.now().difference(t);

    t = DateTime.now();
    GchSortAlgo.countingSort(data);
    results['countingSort'] = DateTime.now().difference(t);

    t = DateTime.now();
    final positiveData = data.map((x) => x.abs()).toList();
    GchSortAlgo.radixSort(positiveData);
    results['radixSort'] = DateTime.now().difference(t);

    t = DateTime.now();
    GchSortAlgo.timSort<num>(data);
    results['timSort'] = DateTime.now().difference(t);

    t = DateTime.now();
    GchSortAlgo.introSort<num>(data);
    results['introSort'] = DateTime.now().difference(t);

    t = DateTime.now();
    GchSortAlgo.gnomeSort<num>(data.sublist(0, min(data.length, 500)));
    results['gnomeSort(500)'] = DateTime.now().difference(t);

    return results;
  }

  static void printBenchmarkReport(Map<String, Duration> results) {
    print('=== Sort Benchmark Results ===');
    final sorted = results.entries.toList()
      ..sort((a, b) => a.value.inMicroseconds.compareTo(b.value.inMicroseconds));
    for (final entry in sorted) {
      print('  ${entry.key.padRight(20)} : ${entry.value.inMicroseconds} µs');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preset test data constants
// ─────────────────────────────────────────────────────────────────────────────
const List<int> kSortTest20 = [
  64, 34, 25, 12, 22, 11, 90, 45, 77, 33,
  18, 55, 72, 40, 8,  60, 15, 88, 3,  99,
];

const List<int> kSortTest50 = [
  64, 34, 25, 12, 22, 11, 90, 45, 77, 33,
  18, 55, 72, 40, 8,  60, 15, 88, 3,  99,
  47, 63, 29, 81, 56, 14, 70, 38, 93, 21,
  67, 4,  50, 85, 27, 74, 41, 96, 10, 58,
  35, 79, 16, 53, 84, 23, 68, 44, 91, 6,
];

const List<int> kSortTestReversed = [
  100, 99, 98, 97, 96, 95, 94, 93, 92, 91,
  90, 89, 88, 87, 86, 85, 84, 83, 82, 81,
  80, 79, 78, 77, 76, 75, 74, 73, 72, 71,
];

const List<int> kSortTestNearlySorted = [
  1, 2, 3, 4, 5, 7, 6, 8, 9, 10,
  11, 12, 13, 15, 14, 16, 17, 18, 19, 20,
  21, 22, 24, 23, 25, 26, 27, 28, 29, 30,
];

const List<int> kSortTestDuplicates = [
  5, 3, 8, 3, 2, 9, 1, 8, 4, 6,
  3, 7, 5, 1, 9, 2, 4, 6, 8, 3,
  5, 1, 7, 9, 2, 4, 6, 8, 3, 5,
];

const List<int> kSortTest100 = [
  64, 34, 25, 12, 22, 11, 90, 45, 77, 33,
  18, 55, 72, 40, 8,  60, 15, 88, 3,  99,
  47, 63, 29, 81, 56, 14, 70, 38, 93, 21,
  67, 4,  50, 85, 27, 74, 41, 96, 10, 58,
  35, 79, 16, 53, 84, 23, 68, 44, 91, 6,
  42, 78, 19, 62, 87, 30, 73, 46, 97, 9,
  52, 82, 20, 65, 89, 31, 76, 48, 100,2,
  57, 83, 24, 69, 92, 37, 80, 49, 98, 7,
  54, 86, 26, 71, 94, 39, 75, 43, 95, 13,
  59, 84, 28, 66, 90, 36, 77, 44, 93, 17,
];

// ─────────────────────────────────────────────────────────────────────────────
// GchExternalSort – merge-sort based external sort simulation
// ─────────────────────────────────────────────────────────────────────────────
class GchExternalSort {
  GchExternalSort._();

  /// Simulate external sort: split list into chunks, sort each, then k-way merge.
  static List<int> sort(List<int> data, {int chunkSize = 100}) {
    if (data.isEmpty) return [];
    final chunks = <List<int>>[];
    for (int i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      final chunk = data.sublist(i, end)..sort();
      chunks.add(chunk);
    }
    return _kWayMerge(chunks);
  }

  static List<int> _kWayMerge(List<List<int>> chunks) {
    // Use a priority queue approach: maintain one pointer per chunk
    final result = <int>[];
    final indices = List<int>.filled(chunks.length, 0);
    while (true) {
      int minVal = 0x7FFFFFFF, minChunk = -1;
      for (int i = 0; i < chunks.length; i++) {
        if (indices[i] < chunks[i].length) {
          if (chunks[i][indices[i]] < minVal) {
            minVal = chunks[i][indices[i]];
            minChunk = i;
          }
        }
      }
      if (minChunk == -1) break;
      result.add(minVal);
      indices[minChunk]++;
    }
    return result;
  }

  /// Parallel merge sort simulation using isolate-like chunking.
  static List<T> parallelMergeSort<T extends Comparable<T>>(List<T> data) {
    if (data.length <= 1) return List<T>.from(data);
    final mid = data.length ~/ 2;
    final left = parallelMergeSort(data.sublist(0, mid));
    final right = parallelMergeSort(data.sublist(mid));
    return _mergeSorted(left, right);
  }

  static List<T> _mergeSorted<T extends Comparable<T>>(
      List<T> left, List<T> right) {
    final result = <T>[];
    int i = 0, j = 0;
    while (i < left.length && j < right.length) {
      if (left[i].compareTo(right[j]) <= 0) {
        result.add(left[i++]);
      } else {
        result.add(right[j++]);
      }
    }
    while (i < left.length) result.add(left[i++]);
    while (j < right.length) result.add(right[j++]);
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GchTopKFinder – find top-k elements using a heap
// ─────────────────────────────────────────────────────────────────────────────
class GchTopKFinder {
  GchTopKFinder._();

  /// Find k largest elements in O(n log k) time.
  static List<T> topK<T extends Comparable<T>>(List<T> data, int k) {
    if (k <= 0) return [];
    if (k >= data.length) {
      final sorted = List<T>.from(data)
        ..sort((a, b) => b.compareTo(a));
      return sorted;
    }
    // Maintain a min-heap of size k
    final heap = <T>[];
    for (final item in data) {
      if (heap.length < k) {
        heap.add(item);
        _heapifyUp(heap, heap.length - 1);
      } else if (item.compareTo(heap[0]) > 0) {
        heap[0] = item;
        _heapifyDown(heap, 0);
      }
    }
    heap.sort((a, b) => b.compareTo(a));
    return heap;
  }

  /// Find k smallest elements in O(n log k) time.
  static List<T> bottomK<T extends Comparable<T>>(List<T> data, int k) {
    if (k <= 0) return [];
    if (k >= data.length) {
      final sorted = List<T>.from(data)..sort();
      return sorted;
    }
    // Maintain a max-heap of size k
    final heap = <T>[];
    for (final item in data) {
      if (heap.length < k) {
        heap.add(item);
        _maxHeapifyUp(heap, heap.length - 1);
      } else if (item.compareTo(heap[0]) < 0) {
        heap[0] = item;
        _maxHeapifyDown(heap, 0);
      }
    }
    heap.sort();
    return heap;
  }

  static void _heapifyUp<T extends Comparable<T>>(List<T> heap, int idx) {
    while (idx > 0) {
      final p = (idx - 1) ~/ 2;
      if (heap[idx].compareTo(heap[p]) < 0) {
        final tmp = heap[idx]; heap[idx] = heap[p]; heap[p] = tmp;
        idx = p;
      } else break;
    }
  }

  static void _heapifyDown<T extends Comparable<T>>(List<T> heap, int idx) {
    final n = heap.length;
    while (true) {
      int smallest = idx;
      final l = 2 * idx + 1, r = 2 * idx + 2;
      if (l < n && heap[l].compareTo(heap[smallest]) < 0) smallest = l;
      if (r < n && heap[r].compareTo(heap[smallest]) < 0) smallest = r;
      if (smallest == idx) break;
      final tmp = heap[idx]; heap[idx] = heap[smallest]; heap[smallest] = tmp;
      idx = smallest;
    }
  }

  static void _maxHeapifyUp<T extends Comparable<T>>(List<T> heap, int idx) {
    while (idx > 0) {
      final p = (idx - 1) ~/ 2;
      if (heap[idx].compareTo(heap[p]) > 0) {
        final tmp = heap[idx]; heap[idx] = heap[p]; heap[p] = tmp;
        idx = p;
      } else break;
    }
  }

  static void _maxHeapifyDown<T extends Comparable<T>>(List<T> heap, int idx) {
    final n = heap.length;
    while (true) {
      int largest = idx;
      final l = 2 * idx + 1, r = 2 * idx + 2;
      if (l < n && heap[l].compareTo(heap[largest]) > 0) largest = l;
      if (r < n && heap[r].compareTo(heap[largest]) > 0) largest = r;
      if (largest == idx) break;
      final tmp = heap[idx]; heap[idx] = heap[largest]; heap[largest] = tmp;
      idx = largest;
    }
  }

  /// kth largest element using QuickSelect (average O(n)).
  static T kthLargest<T extends Comparable<T>>(List<T> data, int k) {
    if (k < 1 || k > data.length) throw RangeError('k=$k out of range');
    return _quickSelect(List<T>.from(data), 0, data.length - 1, data.length - k);
  }

  static T _quickSelect<T extends Comparable<T>>(
      List<T> arr, int low, int high, int k) {
    if (low == high) return arr[low];
    final pivot = arr[high];
    int i = low - 1;
    for (int j = low; j < high; j++) {
      if (arr[j].compareTo(pivot) <= 0) {
        i++;
        final tmp = arr[i]; arr[i] = arr[j]; arr[j] = tmp;
      }
    }
    final tmp = arr[i + 1]; arr[i + 1] = arr[high]; arr[high] = tmp;
    final pi = i + 1;
    if (pi == k) return arr[pi];
    if (pi < k) return _quickSelect(arr, pi + 1, high, k);
    return _quickSelect(arr, low, pi - 1, k);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GchMergeSortedLists – utilities for merging already-sorted lists
// ─────────────────────────────────────────────────────────────────────────────
class GchMergeSortedLists {
  GchMergeSortedLists._();

  /// Merge two sorted lists into one sorted list.
  static List<T> mergeTwoSorted<T extends Comparable<T>>(
      List<T> a, List<T> b) {
    final result = <T>[];
    int i = 0, j = 0;
    while (i < a.length && j < b.length) {
      if (a[i].compareTo(b[j]) <= 0) {
        result.add(a[i++]);
      } else {
        result.add(b[j++]);
      }
    }
    while (i < a.length) result.add(a[i++]);
    while (j < b.length) result.add(b[j++]);
    return result;
  }

  /// k-way merge of sorted lists using tournament tree approach.
  static List<T> mergeKSorted<T extends Comparable<T>>(
      List<List<T>> sortedLists) {
    if (sortedLists.isEmpty) return [];
    final result = <T>[];
    final indices = List<int>.filled(sortedLists.length, 0);
    while (true) {
      T? minVal;
      int minList = -1;
      for (int i = 0; i < sortedLists.length; i++) {
        if (indices[i] < sortedLists[i].length) {
          final val = sortedLists[i][indices[i]];
          if (minList == -1 || val.compareTo(minVal as T) < 0) {
            minVal = val;
            minList = i;
          }
        }
      }
      if (minList == -1) break;
      result.add(minVal as T);
      indices[minList]++;
    }
    return result;
  }

  /// Check if a list is sorted in ascending order.
  static bool isSorted<T extends Comparable<T>>(List<T> list,
      {bool ascending = true}) {
    for (int i = 1; i < list.length; i++) {
      final cmp = list[i - 1].compareTo(list[i]);
      if (ascending && cmp > 0) return false;
      if (!ascending && cmp < 0) return false;
    }
    return true;
  }

  /// Count inversions in a list using merge sort.
  static int countInversions(List<int> list) {
    final arr = List<int>.from(list);
    return _countInvHelper(arr, 0, arr.length - 1);
  }

  static int _countInvHelper(List<int> arr, int left, int right) {
    if (left >= right) return 0;
    final mid = (left + right) ~/ 2;
    int count = _countInvHelper(arr, left, mid);
    count += _countInvHelper(arr, mid + 1, right);
    count += _mergeCount(arr, left, mid, right);
    return count;
  }

  static int _mergeCount(List<int> arr, int left, int mid, int right) {
    final leftArr = arr.sublist(left, mid + 1);
    final rightArr = arr.sublist(mid + 1, right + 1);
    int i = 0, j = 0, k = left, count = 0;
    while (i < leftArr.length && j < rightArr.length) {
      if (leftArr[i] <= rightArr[j]) {
        arr[k++] = leftArr[i++];
      } else {
        count += leftArr.length - i;
        arr[k++] = rightArr[j++];
      }
    }
    while (i < leftArr.length) arr[k++] = leftArr[i++];
    while (j < rightArr.length) arr[k++] = rightArr[j++];
    return count;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GchSortVerifier – validate sort correctness
// ─────────────────────────────────────────────────────────────────────────────
class GchSortVerifier {
  GchSortVerifier._();

  /// Verify that [sorted] is a valid sorted version of [original].
  static bool verify<T extends Comparable<T>>(
      List<T> original, List<T> sorted) {
    if (original.length != sorted.length) return false;
    // Check sorted order
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i - 1].compareTo(sorted[i]) > 0) return false;
    }
    // Check same multiset using frequency map
    final freq = <T, int>{};
    for (final x in original) freq[x] = (freq[x] ?? 0) + 1;
    for (final x in sorted) {
      freq[x] = (freq[x] ?? 0) - 1;
      if (freq[x]! < 0) return false;
    }
    return true;
  }

  /// Run all sort algorithms on the input and verify each result.
  static Map<String, bool> verifyAllAlgorithms(List<int> data) {
    final results = <String, bool>{};
    final expected = List<int>.from(data)..sort();
    results['bubbleSort'] =
        verify(data, GchSortAlgo.bubbleSort<num>(data));
    results['selectionSort'] =
        verify(data, GchSortAlgo.selectionSort<num>(data));
    results['insertionSort'] =
        verify(data, GchSortAlgo.insertionSort<num>(data));
    results['shellSort'] =
        verify(data, GchSortAlgo.shellSort<num>(data));
    results['mergeSort'] =
        verify(data, GchSortAlgo.mergeSort<num>(data));
    results['quickSort'] =
        verify(data, GchSortAlgo.quickSort<num>(data));
    results['heapSort'] =
        verify(data, GchSortAlgo.heapSort<num>(data));
    results['timSort'] =
        verify(data, GchSortAlgo.timSort<num>(data));
    results['introSort'] =
        verify(data, GchSortAlgo.introSort<num>(data));
    results['gnomeSort'] =
        verify(data.sublist(0, min(data.length, 200)),
            GchSortAlgo.gnomeSort<num>(data.sublist(0, min(data.length, 200))));
    final positiveData = data.map((x) => x.abs() + 1).toList();
    results['countingSort'] =
        verify<num>(positiveData, GchSortAlgo.countingSort(positiveData));
    results['radixSort'] =
        verify<num>(positiveData, GchSortAlgo.radixSort(positiveData));
    // Validate all passed
    final allPassed = results.values.every((v) => v);
    results['_allPassed'] = allPassed;
    return results;
  }
}
