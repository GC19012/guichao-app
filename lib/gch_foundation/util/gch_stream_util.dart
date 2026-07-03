// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:async';
import 'dart:collection';
import 'dart:math';

extension GchStreamExt<T> on Stream<T> {
  Stream<R> whereType<R>() {
    return where((event) => event is R).cast<R>();
  }

  Stream<R> mapIndexed<R>(R Function(int index, T value) transform) {
    int index = 0;
    return map((event) => transform(index++, event));
  }

  Stream<T> doOnData(void Function(T) action) {
    return map((event) {
      action(event);
      return event;
    });
  }

  Stream<T> doOnError(void Function(Object error, StackTrace stackTrace) action) {
    return transform(StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleError: (error, stackTrace, sink) {
        action(error, stackTrace);
        sink.addError(error, stackTrace);
      },
    ));
  }

  Stream<T> doOnDone(void Function() action) {
    return transform(StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleDone: (sink) {
        action();
        sink.close();
      },
    ));
  }

  Stream<T> throttleTime(Duration duration) {
    DateTime? lastEmit;
    return where((event) {
      final now = DateTime.now();
      if (lastEmit == null || now.difference(lastEmit!) >= duration) {
        lastEmit = now;
        return true;
      }
      return false;
    });
  }

  Stream<T> debounceTime(Duration duration) {
    Timer? timer;
    late StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        final subscription = listen(
          (event) {
            timer?.cancel();
            timer = Timer(duration, () {
              if (!controller.isClosed) controller.add(event);
            });
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            controller.close();
          },
        );
        controller.onCancel = () {
          timer?.cancel();
          subscription.cancel();
        };
      },
    );
    return controller.stream;
  }

  Stream<List<T>> bufferTime(Duration duration) {
    late StreamController<List<T>> controller;
    List<T> buffer = [];
    Timer? timer;

    controller = StreamController<List<T>>(
      onListen: () {
        timer = Timer.periodic(duration, (_) {
          if (buffer.isNotEmpty && !controller.isClosed) {
            controller.add(List<T>.from(buffer));
            buffer.clear();
          }
        });

        final subscription = listen(
          (event) => buffer.add(event),
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            if (buffer.isNotEmpty) controller.add(List<T>.from(buffer));
            controller.close();
          },
        );

        controller.onCancel = () {
          timer?.cancel();
          subscription.cancel();
        };
      },
    );
    return controller.stream;
  }

  Stream<List<T>> bufferCount(int count) {
    List<T> buffer = [];
    return transform(StreamTransformer<T, List<T>>.fromHandlers(
      handleData: (data, sink) {
        buffer.add(data);
        if (buffer.length >= count) {
          sink.add(List<T>.from(buffer));
          buffer.clear();
        }
      },
      handleDone: (sink) {
        if (buffer.isNotEmpty) sink.add(List<T>.from(buffer));
        sink.close();
      },
    ));
  }

  Stream<List<T>> windowCount(int count, {int skip = 1}) {
    final queue = Queue<T>();
    int itemCount = 0;
    return transform(StreamTransformer<T, List<T>>.fromHandlers(
      handleData: (data, sink) {
        queue.add(data);
        itemCount++;
        if (queue.length > count) queue.removeFirst();
        if (queue.length == count && (itemCount - count) % skip == 0) {
          sink.add(List<T>.from(queue));
        }
      },
    ));
  }

  Stream<(T, T)> pairwise() {
    T? previous;
    bool hasPrevious = false;
    return transform(StreamTransformer<T, (T, T)>.fromHandlers(
      handleData: (data, sink) {
        if (hasPrevious) {
          sink.add((previous as T, data));
        }
        previous = data;
        hasPrevious = true;
      },
    ));
  }

  Stream<R> scan<R>(R seed, R Function(R accumulator, T item) accumulator) {
    R acc = seed;
    return map((event) {
      acc = accumulator(acc, event);
      return acc;
    });
  }

  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }

  Stream<T> endWith(T value) async* {
    yield* this;
    yield value;
  }

  Stream<T> delay(Duration duration) {
    return asyncMap((event) async {
      await Future.delayed(duration);
      return event;
    });
  }

  Stream<T> timeoutWith(Duration duration, {T Function()? onTimeout}) {
    return transform(StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) => sink.add(data),
    )).timeout(
      duration,
      onTimeout: onTimeout != null
          ? (sink) => sink.add(onTimeout())
          : (sink) => sink.close(),
    );
  }

  Stream<T> retry(int count) {
    return transform(_RetryTransformer<T>(count, () => this));
  }

  Stream<T> onErrorReturn(T value) {
    return transform(StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleError: (_, __, sink) => sink.add(value),
    ));
  }

  Stream<T> onErrorReturnWith(T Function(Object) handler) {
    return transform(StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleError: (error, _, sink) => sink.add(handler(error)),
    ));
  }

  Future<List<T>> collectList() async {
    final result = <T>[];
    await forEach(result.add);
    return result;
  }

  Future<Set<T>> collectSet() async {
    final result = <T>{};
    await forEach(result.add);
    return result;
  }

  Future<int> count() async {
    int c = 0;
    await forEach((_) => c++);
    return c;
  }

  Stream<T> distinctUntilChanged([bool Function(T a, T b)? equals]) {
    T? previous;
    bool hasPrevious = false;
    final eq = equals ?? (a, b) => a == b;
    return where((event) {
      if (!hasPrevious || !eq(previous as T, event)) {
        previous = event;
        hasPrevious = true;
        return true;
      }
      return false;
    });
  }

  Stream<T> take(int count) {
    int taken = 0;
    return takeWhile((_) => taken++ < count);
  }

  Stream<T> skip(int count) {
    int skipped = 0;
    return where((_) => skipped++ >= count);
  }

  Stream<R> flatMap<R>(Stream<R> Function(T) transform) {
    late StreamController<R> controller;
    final subscriptions = <StreamSubscription>[];

    controller = StreamController<R>(
      onListen: () {
        final sub = listen(
          (event) {
            final inner = transform(event);
            final innerSub = inner.listen(
              controller.add,
              onError: controller.addError,
            );
            subscriptions.add(innerSub);
          },
          onError: controller.addError,
          onDone: () {
            Future.wait(subscriptions.map((s) => s.asFuture())).then((_) {
              if (!controller.isClosed) controller.close();
            });
          },
        );
        subscriptions.add(sub);
      },
      onCancel: () {
        for (final s in subscriptions) {
          s.cancel();
        }
      },
    );

    return controller.stream;
  }

  Stream<T> withLatestFrom<O>(Stream<O> other, T Function(T, O) combiner) {
    return GchStreamCombine.withLatestFrom<T, O, T>(this, other, combiner);
  }

  Stream<List<T>> bufferUntil(Stream<void> trigger) {
    late StreamController<List<T>> controller;
    List<T> buffer = [];

    controller = StreamController<List<T>>(
      onListen: () {
        final triggerSub = trigger.listen((_) {
          if (!controller.isClosed && buffer.isNotEmpty) {
            controller.add(List<T>.from(buffer));
            buffer.clear();
          }
        });

        final sub = listen(
          buffer.add,
          onError: controller.addError,
          onDone: () {
            triggerSub.cancel();
            if (buffer.isNotEmpty) controller.add(List<T>.from(buffer));
            controller.close();
          },
        );

        controller.onCancel = () {
          triggerSub.cancel();
          sub.cancel();
        };
      },
    );
    return controller.stream;
  }
}

class _RetryTransformer<T> extends StreamTransformerBase<T, T> {
  final int maxRetries;
  final Stream<T> Function() streamFactory;

  _RetryTransformer(this.maxRetries, this.streamFactory);

  @override
  Stream<T> bind(Stream<T> stream) {
    late StreamController<T> controller;
    int retryCount = 0;
    StreamSubscription<T>? subscription;

    void subscribeToStream() {
      subscription = streamFactory().listen(
        controller.add,
        onError: (Object error, StackTrace st) {
          if (retryCount < maxRetries) {
            retryCount++;
            subscribeToStream();
          } else {
            controller.addError(error, st);
            controller.close();
          }
        },
        onDone: controller.close,
      );
    }

    controller = StreamController<T>(
      onListen: subscribeToStream,
      onCancel: () => subscription?.cancel(),
    );

    return controller.stream;
  }
}

class GchStreamCombine {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    late StreamController<T> controller;
    final subscriptions = <StreamSubscription<T>>[];
    int doneCount = 0;

    controller = StreamController<T>(
      onListen: () {
        for (final stream in streams) {
          final sub = stream.listen(
            controller.add,
            onError: controller.addError,
            onDone: () {
              doneCount++;
              if (doneCount == streams.length) controller.close();
            },
          );
          subscriptions.add(sub);
        }
      },
      onCancel: () {
        for (final sub in subscriptions) {
          sub.cancel();
        }
      },
    );

    return controller.stream;
  }

  static Stream<R> combineLatest2<A, B, R>(
    Stream<A> a,
    Stream<B> b,
    R Function(A, B) combiner,
  ) {
    late StreamController<R> controller;
    A? latestA;
    B? latestB;
    bool hasA = false, hasB = false;
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;

    controller = StreamController<R>(
      onListen: () {
        subA = a.listen(
          (va) {
            latestA = va;
            hasA = true;
            if (hasB) controller.add(combiner(va, latestB as B));
          },
          onError: controller.addError,
          onDone: () {
            subB?.cancel();
            controller.close();
          },
        );
        subB = b.listen(
          (vb) {
            latestB = vb;
            hasB = true;
            if (hasA) controller.add(combiner(latestA as A, vb));
          },
          onError: controller.addError,
          onDone: () {
            subA?.cancel();
            controller.close();
          },
        );
      },
      onCancel: () {
        subA?.cancel();
        subB?.cancel();
      },
    );

    return controller.stream;
  }

  static Stream<R> combineLatest3<A, B, C, R>(
    Stream<A> a,
    Stream<B> b,
    Stream<C> c,
    R Function(A, B, C) combiner,
  ) {
    late StreamController<R> controller;
    A? latestA;
    B? latestB;
    C? latestC;
    bool hasA = false, hasB = false, hasC = false;
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;
    StreamSubscription<C>? subC;
    int doneCount = 0;

    void onDone() {
      doneCount++;
      if (doneCount == 3) controller.close();
    }

    void tryEmit() {
      if (hasA && hasB && hasC) {
        controller.add(combiner(latestA as A, latestB as B, latestC as C));
      }
    }

    controller = StreamController<R>(
      onListen: () {
        subA = a.listen((v) { latestA = v; hasA = true; tryEmit(); }, onError: controller.addError, onDone: onDone);
        subB = b.listen((v) { latestB = v; hasB = true; tryEmit(); }, onError: controller.addError, onDone: onDone);
        subC = c.listen((v) { latestC = v; hasC = true; tryEmit(); }, onError: controller.addError, onDone: onDone);
      },
      onCancel: () {
        subA?.cancel();
        subB?.cancel();
        subC?.cancel();
      },
    );

    return controller.stream;
  }

  static Stream<R> zip2<A, B, R>(
    Stream<A> a,
    Stream<B> b,
    R Function(A, B) combiner,
  ) {
    late StreamController<R> controller;
    final queueA = Queue<A>();
    final queueB = Queue<B>();
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;

    void tryEmit() {
      while (queueA.isNotEmpty && queueB.isNotEmpty) {
        controller.add(combiner(queueA.removeFirst(), queueB.removeFirst()));
      }
    }

    controller = StreamController<R>(
      onListen: () {
        subA = a.listen(
          (v) { queueA.add(v); tryEmit(); },
          onError: controller.addError,
          onDone: () { subB?.cancel(); controller.close(); },
        );
        subB = b.listen(
          (v) { queueB.add(v); tryEmit(); },
          onError: controller.addError,
          onDone: () { subA?.cancel(); controller.close(); },
        );
      },
      onCancel: () {
        subA?.cancel();
        subB?.cancel();
      },
    );

    return controller.stream;
  }

  static Stream<T> concat<T>(List<Stream<T>> streams) {
    if (streams.isEmpty) return Stream<T>.empty();
    late StreamController<T> controller;
    int currentIndex = 0;
    StreamSubscription<T>? currentSub;

    void subscribeToNext() {
      if (currentIndex >= streams.length) {
        controller.close();
        return;
      }
      currentSub = streams[currentIndex].listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          currentIndex++;
          subscribeToNext();
        },
      );
    }

    controller = StreamController<T>(
      onListen: subscribeToNext,
      onCancel: () => currentSub?.cancel(),
    );

    return controller.stream;
  }

  static Stream<T> race<T>(List<Stream<T>> streams) {
    late StreamController<T> controller;
    final subscriptions = <StreamSubscription<T>>[];
    bool settled = false;

    controller = StreamController<T>(
      onListen: () {
        for (int i = 0; i < streams.length; i++) {
          late StreamSubscription<T> sub;
          sub = streams[i].listen(
            (event) {
              if (!settled) {
                settled = true;
                for (final s in subscriptions) {
                  if (s != sub) s.cancel();
                }
              }
              if (!controller.isClosed) controller.add(event);
            },
            onError: (Object err, StackTrace st) {
              if (!controller.isClosed) controller.addError(err, st);
            },
            onDone: () {
              if (!controller.isClosed) controller.close();
            },
          );
          subscriptions.add(sub);
        }
      },
      onCancel: () {
        for (final s in subscriptions) {
          s.cancel();
        }
      },
    );

    return controller.stream;
  }

  static Stream<R> withLatestFrom<T, O, R>(
    Stream<T> source,
    Stream<O> other,
    R Function(T, O) combiner,
  ) {
    late StreamController<R> controller;
    O? latestOther;
    bool hasOther = false;
    StreamSubscription<T>? sourceSub;
    StreamSubscription<O>? otherSub;

    controller = StreamController<R>(
      onListen: () {
        otherSub = other.listen(
          (v) { latestOther = v; hasOther = true; },
          onError: controller.addError,
        );
        sourceSub = source.listen(
          (event) {
            if (hasOther) {
              controller.add(combiner(event, latestOther as O));
            }
          },
          onError: controller.addError,
          onDone: () {
            otherSub?.cancel();
            controller.close();
          },
        );
      },
      onCancel: () {
        sourceSub?.cancel();
        otherSub?.cancel();
      },
    );

    return controller.stream;
  }

  static Stream<T> interval<T>(T value, Duration period) {
    return Stream<T>.periodic(period, (_) => value);
  }

  static Stream<int> timer(Duration delay) {
    return Stream<int>.fromFuture(
      Future.delayed(delay, () => 0),
    );
  }
}

class GchSubject<T> {
  final StreamController<T> _controller = StreamController<T>.broadcast();
  T? _value;
  bool _hasValue = false;

  GchSubject();

  factory GchSubject.seeded(T value) {
    final subject = GchSubject<T>();
    subject.add(value);
    return subject;
  }

  T? get value => _value;
  bool get hasValue => _hasValue;
  bool get isClosed => _controller.isClosed;
  Stream<T> get stream {
    if (_hasValue) {
      final captured = _value as T;
      final ctrl = _controller;
      return (() async* {
        yield captured;
        yield* ctrl.stream;
      })();
    }
    return _controller.stream;
  }

  void add(T value) {
    if (_controller.isClosed) return;
    _value = value;
    _hasValue = true;
    _controller.add(value);
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    if (_controller.isClosed) return;
    _controller.addError(error, stackTrace);
  }

  Future<void> close() => _controller.close();

  StreamSubscription<T> listen(
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  String toString() => 'GchSubject(value=$_value, closed=$isClosed)';
}

class GchReplaySubject<T> {
  final int bufferSize;
  final Queue<T> _buffer;
  final StreamController<T> _controller = StreamController<T>.broadcast();

  GchReplaySubject(this.bufferSize) : _buffer = Queue<T>();

  List<T> get bufferedValues => List.unmodifiable(_buffer);
  bool get isClosed => _controller.isClosed;
  int get bufferLength => _buffer.length;

  Stream<T> get stream {
    final snapshot = List<T>.from(_buffer);
    final ctrl = _controller;
    return (() async* {
      for (final item in snapshot) yield item;
      yield* ctrl.stream;
    })();
  }

  void add(T value) {
    if (_controller.isClosed) return;
    _buffer.add(value);
    while (_buffer.length > bufferSize) {
      _buffer.removeFirst();
    }
    _controller.add(value);
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    if (_controller.isClosed) return;
    _controller.addError(error, stackTrace);
  }

  Future<void> close() => _controller.close();

  void clearBuffer() => _buffer.clear();

  StreamSubscription<T> listen(
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  String toString() =>
      'GchReplaySubject(bufferSize=$bufferSize, buffered=${_buffer.length})';
}

class GchStreamUtil {
  static Stream<T> fromFutures<T>(List<Future<T>> futures) {
    return Stream.fromFutures(futures);
  }

  static Future<T> first<T>(Stream<T> stream) => stream.first;

  static Stream<T> fromIterable<T>(Iterable<T> iterable) {
    return Stream.fromIterable(iterable);
  }

  static Stream<T> periodic<T>(
    Duration period,
    T Function(int count) computation,
  ) {
    return Stream.periodic(period, computation);
  }

  static StreamTransformer<T, T> filterTransformer<T>(
    bool Function(T) predicate,
  ) {
    return StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) {
        if (predicate(data)) sink.add(data);
      },
    );
  }

  static StreamTransformer<T, R> mapTransformer<T, R>(
    R Function(T) transform,
  ) {
    return StreamTransformer<T, R>.fromHandlers(
      handleData: (data, sink) => sink.add(transform(data)),
    );
  }

  static StreamTransformer<T, T> tapTransformer<T>(
    void Function(T) action,
  ) {
    return StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) {
        action(data);
        sink.add(data);
      },
    );
  }

  static Stream<T> never<T>() {
    return StreamController<T>().stream;
  }

  static Stream<T> empty<T>() => Stream<T>.empty();

  static Stream<T> value<T>(T v) => Stream<T>.value(v);

  static Stream<T> error<T>(Object error) {
    return Stream<T>.error(error);
  }

  static Stream<int> count({int start = 0, int step = 1, Duration? delay}) {
    int current = start;
    if (delay != null) {
      return Stream.periodic(delay, (_) {
        final v = current;
        current += step;
        return v;
      });
    }
    return Stream.fromIterable(
      Iterable.generate(1000, (i) => start + i * step),
    );
  }

  static StreamTransformer<T, List<T>> groupUntilChanged<T>(
    bool Function(T prev, T curr) shouldGroup,
  ) {
    return StreamTransformer<T, List<T>>.fromHandlers(
      handleData: (data, sink) {
        sink.add([data]);
      },
    );
  }
}
