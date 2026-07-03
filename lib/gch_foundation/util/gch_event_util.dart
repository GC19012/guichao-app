// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:async';

// ─── Event Name Constants ──────────────────────────────────────────────────

/// Predefined event name constants for common application events.
class GchEvents {
  GchEvents._();

  // App lifecycle
  static const String appStart = 'app:start';
  static const String appStop = 'app:stop';
  static const String appPause = 'app:pause';
  static const String appResume = 'app:resume';
  static const String appForeground = 'app:foreground';
  static const String appBackground = 'app:background';

  // Navigation
  static const String navPush = 'nav:push';
  static const String navPop = 'nav:pop';
  static const String navReplace = 'nav:replace';
  static const String navTabChange = 'nav:tabChange';
  static const String navDeepLink = 'nav:deepLink';

  // Auth
  static const String authSignIn = 'auth:signIn';
  static const String authSignOut = 'auth:signOut';
  static const String authTokenRefresh = 'auth:tokenRefresh';
  static const String authSessionExpired = 'auth:sessionExpired';
  static const String authProfileUpdated = 'auth:profileUpdated';

  // Data
  static const String dataLoaded = 'data:loaded';
  static const String dataUpdated = 'data:updated';
  static const String dataDeleted = 'data:deleted';
  static const String dataSynced = 'data:synced';
  static const String dataError = 'data:error';
  static const String dataCacheCleared = 'data:cacheCleared';

  // Network
  static const String networkOnline = 'network:online';
  static const String networkOffline = 'network:offline';
  static const String networkSlowDetected = 'network:slowDetected';
  static const String networkRequestStart = 'network:requestStart';
  static const String networkRequestEnd = 'network:requestEnd';
  static const String networkRequestError = 'network:requestError';

  // UI
  static const String uiThemeChanged = 'ui:themeChanged';
  static const String uiLocaleChanged = 'ui:localeChanged';
  static const String uiFontSizeChanged = 'ui:fontSizeChanged';
  static const String uiModalOpen = 'ui:modalOpen';
  static const String uiModalClose = 'ui:modalClose';
  static const String uiSnackbar = 'ui:snackbar';
  static const String uiLoading = 'ui:loading';
  static const String uiLoadingDone = 'ui:loadingDone';

  // User actions
  static const String userClick = 'user:click';
  static const String userLongPress = 'user:longPress';
  static const String userSwipe = 'user:swipe';
  static const String userSearch = 'user:search';
  static const String userShare = 'user:share';
  static const String userDownload = 'user:download';
  static const String userUpload = 'user:upload';

  // Form
  static const String formSubmit = 'form:submit';
  static const String formValidate = 'form:validate';
  static const String formReset = 'form:reset';
  static const String formFieldChange = 'form:fieldChange';
  static const String formError = 'form:error';

  // Notification
  static const String notificationReceived = 'notification:received';
  static const String notificationTapped = 'notification:tapped';
  static const String notificationDismissed = 'notification:dismissed';
  static const String notificationPermissionGranted = 'notification:permissionGranted';
  static const String notificationPermissionDenied = 'notification:permissionDenied';

  // Media
  static const String mediaPlay = 'media:play';
  static const String mediaPause = 'media:pause';
  static const String mediaStop = 'media:stop';
  static const String mediaSeek = 'media:seek';
  static const String mediaEnd = 'media:end';
  static const String mediaError = 'media:error';

  // Purchase
  static const String purchaseStarted = 'purchase:started';
  static const String purchaseCompleted = 'purchase:completed';
  static const String purchaseFailed = 'purchase:failed';
  static const String purchaseRestored = 'purchase:restored';
}

// ─── GchEventEmitter ──────────────────────────────────────────────────────

typedef _EventHandler = void Function(dynamic data);

class _Subscription {
  final String token;
  final String event;
  final _EventHandler handler;
  final bool once;

  _Subscription({
    required this.token,
    required this.event,
    required this.handler,
    required this.once,
  });
}

/// A flexible event emitter that supports named events and one-time listeners.
class GchEventEmitter {
  final Map<String, List<_Subscription>> _subscriptions = {};
  int _tokenCounter = 0;

  String _nextToken() => 'token_${++_tokenCounter}';

  /// Registers [handler] for [event]. Returns a subscription token.
  String on(String event, Function handler) {
    final token = _nextToken();
    final sub = _Subscription(
      token: token,
      event: event,
      handler: (data) => handler(data),
      once: false,
    );
    _subscriptions.putIfAbsent(event, () => []).add(sub);
    return token;
  }

  /// Registers [handler] for [event] that fires only once. Returns a subscription token.
  String once(String event, Function handler) {
    final token = _nextToken();
    final sub = _Subscription(
      token: token,
      event: event,
      handler: (data) => handler(data),
      once: true,
    );
    _subscriptions.putIfAbsent(event, () => []).add(sub);
    return token;
  }

  /// Unregisters the listener identified by [token].
  void off(String token) {
    for (final key in _subscriptions.keys) {
      _subscriptions[key]!.removeWhere((s) => s.token == token);
    }
  }

  /// Removes all listeners for [event].
  void offAll(String event) {
    _subscriptions.remove(event);
  }

  /// Emits [event] synchronously, passing [data] to each listener.
  void emit(String event, [dynamic data]) {
    final subs = List<_Subscription>.from(_subscriptions[event] ?? []);
    for (final sub in subs) {
      sub.handler(data);
      if (sub.once) {
        _subscriptions[event]?.remove(sub);
      }
    }
  }

  /// Emits [event] asynchronously using microtask scheduling.
  Future<void> emitAsync(String event, [dynamic data]) async {
    await Future.microtask(() => emit(event, data));
  }

  /// Returns the number of listeners for [event].
  int listenerCount(String event) {
    return _subscriptions[event]?.length ?? 0;
  }

  /// Returns all event names that have at least one listener.
  List<String> get eventNames {
    return _subscriptions.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList();
  }

  /// Returns true if [event] has at least one listener.
  bool hasListeners(String event) {
    return (_subscriptions[event]?.isNotEmpty) ?? false;
  }

  /// Removes all subscriptions.
  void removeAllListeners() {
    _subscriptions.clear();
  }

  /// Returns a total count of all registered listeners.
  int get totalListenerCount {
    return _subscriptions.values.fold(0, (sum, list) => sum + list.length);
  }
}

// ─── GchStreamController ──────────────────────────────────────────────────

/// A wrapper around [StreamController] with convenience operators.
class GchStreamController<T> {
  late final StreamController<T> _controller;

  GchStreamController({bool broadcast = true}) {
    _controller = broadcast
        ? StreamController<T>.broadcast()
        : StreamController<T>();
  }

  /// The underlying broadcast stream.
  Stream<T> get stream => _controller.stream;

  /// Adds [value] to the stream.
  void add(T value) {
    if (!_controller.isClosed) _controller.add(value);
  }

  /// Adds an error event to the stream.
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_controller.isClosed) _controller.addError(error, stackTrace);
  }

  /// Closes the stream controller.
  Future<void> close() => _controller.close();

  /// Returns true if the controller is closed.
  bool get isClosed => _controller.isClosed;

  /// Filters events using [test].
  Stream<T> where(bool Function(T) test) {
    return stream.where(test);
  }

  /// Transforms events using [transform].
  Stream<R> map<R>(R Function(T) transform) {
    return stream.map(transform);
  }

  /// Throttles events: emits at most one event per [duration].
  Stream<T> throttle(Duration duration) {
    DateTime? lastEmit;
    return stream.where((event) {
      final now = DateTime.now();
      if (lastEmit == null || now.difference(lastEmit!) >= duration) {
        lastEmit = now;
        return true;
      }
      return false;
    });
  }

  /// Debounces events: waits [duration] of silence before emitting.
  Stream<T> debounce(Duration duration) {
    final controller = StreamController<T>.broadcast();
    Timer? timer;
    stream.listen((event) {
      timer?.cancel();
      timer = Timer(duration, () {
        if (!controller.isClosed) controller.add(event);
      });
    }, onDone: () => controller.close());
    return controller.stream;
  }

  /// Buffers [count] events and emits them as a list.
  Stream<List<T>> buffer(int count) {
    final controller = StreamController<List<T>>.broadcast();
    final buffer = <T>[];
    stream.listen((event) {
      buffer.add(event);
      if (buffer.length >= count) {
        controller.add(List<T>.from(buffer));
        buffer.clear();
      }
    }, onDone: () {
      if (buffer.isNotEmpty) controller.add(List<T>.from(buffer));
      controller.close();
    });
    return controller.stream;
  }

  /// Emits only distinct consecutive values.
  Stream<T> distinct() {
    T? last;
    bool hasLast = false;
    return stream.where((event) {
      if (!hasLast || event != last) {
        last = event;
        hasLast = true;
        return true;
      }
      return false;
    });
  }

  /// Skips the first [count] events.
  Stream<T> skip(int count) => stream.skip(count);

  /// Takes only the first [count] events.
  Stream<T> take(int count) => stream.take(count);
}

// ─── GchObserver / GchObservable ──────────────────────────────────────────

/// Abstract observer that receives notifications of type [T].
abstract class GchObserver<T> {
  void onNotify(T value);
  void onError(Object error) {}
  void onComplete() {}
}

/// An observable that manages a list of typed observers.
class GchObservable<T> {
  final Map<String, GchObserver<T>> _observers = {};
  int _tokenCounter = 0;
  bool _completed = false;

  String _nextToken() => 'obs_${++_tokenCounter}';

  /// Subscribes [observer] and returns a subscription token.
  String subscribe(GchObserver<T> observer) {
    if (_completed) {
      observer.onComplete();
      return '';
    }
    final token = _nextToken();
    _observers[token] = observer;
    return token;
  }

  /// Unsubscribes the observer identified by [token].
  void unsubscribe(String token) {
    _observers.remove(token);
  }

  /// Notifies all observers with [value].
  void notify(T value) {
    if (_completed) return;
    for (final observer in List<GchObserver<T>>.from(_observers.values)) {
      try {
        observer.onNotify(value);
      } catch (e) {
        observer.onError(e);
      }
    }
  }

  /// Notifies all observers of an error.
  void notifyError(Object error) {
    for (final observer in List<GchObserver<T>>.from(_observers.values)) {
      try {
        observer.onError(error);
      } catch (_) {}
    }
  }

  /// Marks the observable as complete and notifies all observers.
  void complete() {
    if (_completed) return;
    _completed = true;
    for (final observer in List<GchObserver<T>>.from(_observers.values)) {
      try {
        observer.onComplete();
      } catch (_) {}
    }
    _observers.clear();
  }

  /// The number of active observers.
  int get observerCount => _observers.length;

  /// Whether this observable has been completed.
  bool get isCompleted => _completed;
}

// ─── GchEventBus ──────────────────────────────────────────────────────────

/// A type-based event bus singleton for decoupled communication.
class GchEventBus {
  static final GchEventBus _instance = GchEventBus._internal();
  factory GchEventBus() => _instance;
  GchEventBus._internal();

  final Map<Type, StreamController<dynamic>> _controllers = {};

  StreamController<dynamic> _controllerFor(Type type) {
    return _controllers.putIfAbsent(
      type,
      () => StreamController<dynamic>.broadcast(),
    );
  }

  /// Publishes [event] to all subscribers of its runtime type.
  void publish<T>(T event) {
    final controller = _controllerFor(T);
    if (!controller.isClosed) {
      controller.add(event);
    }
  }

  /// Subscribes to events of type [T], calling [handler] for each.
  StreamSubscription<T> subscribe<T>(void Function(T) handler) {
    return _controllerFor(T).stream.cast<T>().listen(handler);
  }

  /// Returns a typed stream of events of type [T].
  Stream<T> streamOf<T>() {
    return _controllerFor(T).stream.cast<T>();
  }

  /// Closes the channel for type [T].
  Future<void> closeChannel<T>() async {
    final controller = _controllers[T];
    if (controller != null && !controller.isClosed) {
      await controller.close();
      _controllers.remove(T);
    }
  }

  /// Closes all channels.
  Future<void> closeAll() async {
    for (final controller in _controllers.values) {
      if (!controller.isClosed) await controller.close();
    }
    _controllers.clear();
  }
}

// ─── GchSignal ────────────────────────────────────────────────────────────

/// A reactive value holder that notifies listeners on change.
class GchSignal<T> {
  T _value;
  final List<void Function(T)> _listeners = [];
  final T? _initialValue;

  GchSignal(T initialValue)
      : _value = initialValue,
        _initialValue = initialValue;

  /// The current value.
  T get value => _value;

  /// Sets a new value and notifies all listeners if changed.
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    _notifyListeners(newValue);
  }

  /// Forces a notification even if the value has not changed.
  void forceNotify() => _notifyListeners(_value);

  /// Resets the signal to its initial value.
  void reset() {
    if (_initialValue != null) {
      value = _initialValue;
    }
  }

  void _notifyListeners(T val) {
    for (final listener in List<void Function(T)>.from(_listeners)) {
      listener(val);
    }
  }

  /// Adds a [listener] that is called whenever the value changes.
  void addListener(void Function(T) listener) {
    _listeners.add(listener);
  }

  /// Removes a previously added [listener].
  void removeListener(void Function(T) listener) {
    _listeners.remove(listener);
  }

  /// Removes all listeners.
  void clearListeners() {
    _listeners.clear();
  }

  /// The number of active listeners.
  int get listenerCount => _listeners.length;

  @override
  String toString() => 'GchSignal<$T>(value: $_value)';
}

// ─── GchEventQueue ────────────────────────────────────────────────────────

/// A serialized async event processing queue.
class GchEventQueue {
  final _queue = <Future<void> Function()>[];
  bool _processing = false;
  int _processedCount = 0;

  /// Enqueues [task] for sequential execution.
  Future<void> enqueue(Future<void> Function() task) async {
    final completer = Completer<void>();
    _queue.add(() async {
      try {
        await task();
        completer.complete();
      } catch (e) {
        completer.completeError(e);
      }
    });
    _processNext();
    return completer.future;
  }

  void _processNext() {
    if (_processing || _queue.isEmpty) return;
    _processing = true;
    final task = _queue.removeAt(0);
    task().whenComplete(() {
      _processedCount++;
      _processing = false;
      _processNext();
    });
  }

  /// Returns the number of tasks waiting in the queue.
  int get pendingCount => _queue.length;

  /// Returns the total number of tasks processed.
  int get processedCount => _processedCount;

  /// Returns true if a task is currently executing.
  bool get isProcessing => _processing;
}

// ─── GchRetryPolicy ───────────────────────────────────────────────────────

/// Configures retry behavior for async operations.
class GchRetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(Object error)? retryIf;

  const GchRetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.retryIf,
  });

  /// Returns the delay for the given attempt number (0-indexed).
  Duration delayFor(int attempt) {
    final ms = initialDelay.inMilliseconds * pow(backoffMultiplier, attempt);
    return Duration(milliseconds: ms.round().clamp(0, maxDelay.inMilliseconds));
  }

  double pow(double base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) result *= base;
    return result;
  }
}

/// Executes an async operation with retry support.
class GchRetryRunner {
  GchRetryRunner._();

  /// Runs [operation] with the given [policy], retrying on failure.
  static Future<T> run<T>(
    Future<T> Function() operation, {
    GchRetryPolicy policy = const GchRetryPolicy(),
    void Function(int attempt, Object error)? onRetry,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= policy.maxAttempts) rethrow;
        if (policy.retryIf != null && !policy.retryIf!(e)) rethrow;
        onRetry?.call(attempt, e);
        await Future.delayed(policy.delayFor(attempt - 1));
      }
    }
  }
}

// ─── GchPubSubTopic ───────────────────────────────────────────────────────

/// A named topic in a publish-subscribe system with message history.
class GchPubSubTopic<T> {
  final String name;
  final int historySize;
  final _history = <T>[];
  final StreamController<T> _controller;

  GchPubSubTopic(this.name, {this.historySize = 10})
      : _controller = StreamController<T>.broadcast();

  /// Publishes a message to this topic.
  void publish(T message) {
    _history.add(message);
    if (_history.length > historySize) _history.removeAt(0);
    if (!_controller.isClosed) _controller.add(message);
  }

  /// Subscribes to this topic, optionally replaying history.
  StreamSubscription<T> subscribe(
    void Function(T) onMessage, {
    bool replayHistory = false,
  }) {
    if (replayHistory) {
      for (final msg in List<T>.from(_history)) {
        Future.microtask(() => onMessage(msg));
      }
    }
    return _controller.stream.listen(onMessage);
  }

  /// Returns a snapshot of recent messages.
  List<T> get recentMessages => List.unmodifiable(_history);

  /// Returns the number of messages published in total (capped by history).
  int get historyLength => _history.length;

  /// Closes this topic.
  Future<void> close() => _controller.close();

  /// Whether this topic is closed.
  bool get isClosed => _controller.isClosed;
}

// ─── GchEventHistory ──────────────────────────────────────────────────────

/// Tracks a history of emitted events with timestamps.
class GchEventHistory {
  final int maxEntries;
  final List<_EventRecord> _records = [];

  GchEventHistory({this.maxEntries = 200});

  /// Records an event with optional data.
  void record(String event, [dynamic data]) {
    _records.add(_EventRecord(event: event, data: data, timestamp: DateTime.now()));
    if (_records.length > maxEntries) _records.removeAt(0);
  }

  /// Returns all recorded events, newest first.
  List<_EventRecord> get all => List.unmodifiable(_records.reversed.toList());

  /// Returns events for [eventName] only.
  List<_EventRecord> forEvent(String eventName) {
    return _records.where((r) => r.event == eventName).toList();
  }

  /// Returns the most recent event of any kind.
  _EventRecord? get latest => _records.isNotEmpty ? _records.last : null;

  /// Clears all history.
  void clear() => _records.clear();

  /// Returns count of all recorded events.
  int get totalCount => _records.length;
}

class _EventRecord {
  final String event;
  final dynamic data;
  final DateTime timestamp;

  _EventRecord({required this.event, this.data, required this.timestamp});

  @override
  String toString() => '_EventRecord(event: $event, timestamp: $timestamp)';
}

// ─── GchTimedEvent ────────────────────────────────────────────────────────

/// A periodic event that fires at a fixed interval.
class GchTimedEvent {
  final Duration interval;
  final String name;
  Timer? _timer;
  int _fireCount = 0;
  final List<void Function(int)> _handlers = [];

  GchTimedEvent({required this.interval, required this.name});

  /// Starts firing the event at the configured [interval].
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      _fireCount++;
      for (final handler in List<void Function(int)>.from(_handlers)) {
        handler(_fireCount);
      }
    });
  }

  /// Stops the event from firing.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Adds a handler that receives the fire count each time the event fires.
  void addHandler(void Function(int fireCount) handler) {
    _handlers.add(handler);
  }

  /// Removes a handler.
  void removeHandler(void Function(int fireCount) handler) {
    _handlers.remove(handler);
  }

  /// Total number of times this event has fired.
  int get fireCount => _fireCount;

  /// Whether the event is currently running.
  bool get isRunning => _timer != null && _timer!.isActive;

  /// Resets the fire count.
  void resetCount() => _fireCount = 0;
}

// ─── GchReactiveMap ───────────────────────────────────────────────────────

/// A map wrapper that fires change events when entries are modified.
class GchReactiveMap<K, V> {
  final Map<K, V> _inner = {};
  final GchEventEmitter _emitter = GchEventEmitter();

  static const String eventPut = 'map:put';
  static const String eventRemove = 'map:remove';
  static const String eventClear = 'map:clear';

  /// Stores [value] for [key] and emits [eventPut].
  void put(K key, V value) {
    _inner[key] = value;
    _emitter.emit(eventPut, MapEntry<K, V>(key, value));
  }

  /// Removes [key] and emits [eventRemove].
  V? remove(K key) {
    final old = _inner.remove(key);
    if (old != null) _emitter.emit(eventRemove, key);
    return old;
  }

  /// Clears all entries and emits [eventClear].
  void clear() {
    _inner.clear();
    _emitter.emit(eventClear, null);
  }

  /// Returns the value for [key], or null.
  V? get(K key) => _inner[key];

  /// Returns true if [key] is present.
  bool contains(K key) => _inner.containsKey(key);

  /// The number of entries.
  int get length => _inner.length;

  /// Returns all keys.
  Iterable<K> get keys => _inner.keys;

  /// Returns all values.
  Iterable<V> get values => _inner.values;

  /// Registers a listener for changes to this map.
  String onPut(void Function(MapEntry<K, V>) handler) {
    return _emitter.on(eventPut, handler);
  }

  /// Registers a listener for removals.
  String onRemove(void Function(K) handler) {
    return _emitter.on(eventRemove, handler);
  }

  /// Unregisters a listener.
  void offListener(String token) => _emitter.off(token);
}

// ─── GchEventMiddleware ───────────────────────────────────────────────────

/// A middleware handler type for event pipelines.
typedef GchEventMiddlewareFn = Future<dynamic> Function(String event, dynamic data, Future<dynamic> Function() next);

/// An event emitter with middleware support.
class GchMiddlewareEmitter {
  final List<GchEventMiddlewareFn> _middlewares = [];
  final GchEventEmitter _inner = GchEventEmitter();

  /// Adds a middleware to the pipeline.
  void use(GchEventMiddlewareFn middleware) {
    _middlewares.add(middleware);
  }

  /// Emits [event] through the middleware chain, then to listeners.
  Future<void> emit(String event, [dynamic data]) async {
    Future<dynamic> Function() next = () async {
      _inner.emit(event, data);
      return data;
    };

    for (final mw in _middlewares.reversed) {
      final currentNext = next;
      final capturedMw = mw;
      next = () => capturedMw(event, data, currentNext);
    }

    await next();
  }

  /// Registers a listener for [event].
  String on(String event, Function handler) => _inner.on(event, handler);

  /// Removes a listener by token.
  void off(String token) => _inner.off(token);
}
