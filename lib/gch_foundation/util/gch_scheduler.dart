// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:async';
import 'dart:collection';
import 'dart:math';

// ──────────────────────────────────────────────
// GchDebounce
// ──────────────────────────────────────────────
class GchDebounce {
  final Duration delay;
  Timer? _timer;

  GchDebounce(this.delay);

  bool get isPending => _timer?.isActive == true;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

// ──────────────────────────────────────────────
// GchThrottle
// ──────────────────────────────────────────────
class GchThrottle {
  final Duration interval;
  DateTime? _lastExecutedAt;

  GchThrottle(this.interval);

  DateTime? get lastExecutedAt => _lastExecutedAt;

  bool call(void Function() action) {
    final now = DateTime.now();
    if (_lastExecutedAt == null ||
        now.difference(_lastExecutedAt!) >= interval) {
      _lastExecutedAt = now;
      action();
      return true;
    }
    return false;
  }

  void reset() {
    _lastExecutedAt = null;
  }
}

// ──────────────────────────────────────────────
// GchTaskPriority
// ──────────────────────────────────────────────
enum GchTaskPriority {
  low(0),
  normal(1),
  high(2),
  critical(3);

  final int level;
  const GchTaskPriority(this.level);
}

// ──────────────────────────────────────────────
// GchTask
// ──────────────────────────────────────────────
class GchTask {
  final String id;
  final String name;
  final Future<dynamic> Function() action;
  final GchTaskPriority priority;
  final DateTime scheduledAt;
  int retries;
  final int maxRetries;

  GchTask({
    required this.id,
    required this.name,
    required this.action,
    this.priority = GchTaskPriority.normal,
    DateTime? scheduledAt,
    this.retries = 0,
    this.maxRetries = 0,
  }) : scheduledAt = scheduledAt ?? DateTime.now();

  @override
  String toString() =>
      'GchTask(id=$id, name=$name, priority=$priority, retries=$retries/$maxRetries)';
}

// ──────────────────────────────────────────────
// GchTaskQueue
// ──────────────────────────────────────────────
class GchTaskQueue {
  final _queue = <GchTask>[];
  final _running = <String>{};
  bool _paused = false;
  bool _processing = false;

  void Function(GchTask task, dynamic result)? onTaskComplete;
  void Function(GchTask task, Object error)? onTaskError;

  int get length => _queue.length;
  int get pendingCount => _queue.length;
  int get runningCount => _running.length;
  bool get isPaused => _paused;

  void enqueue(GchTask task) {
    int insertIndex = _queue.length;
    for (int i = 0; i < _queue.length; i++) {
      if (task.priority.level > _queue[i].priority.level) {
        insertIndex = i;
        break;
      }
    }
    _queue.insert(insertIndex, task);
    _process();
  }

  GchTask? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  bool cancel(String id) {
    final idx = _queue.indexWhere((t) => t.id == id);
    if (idx < 0) return false;
    _queue.removeAt(idx);
    return true;
  }

  void pause() {
    _paused = true;
  }

  void resume() {
    _paused = false;
    _process();
  }

  void clear() {
    _queue.clear();
  }

  void _process() {
    if (_paused || _processing || _queue.isEmpty) return;
    _processing = true;
    _runNext();
  }

  void _runNext() async {
    if (_paused || _queue.isEmpty) {
      _processing = false;
      return;
    }
    final task = _queue.removeAt(0);
    _running.add(task.id);
    try {
      final result = await task.action();
      onTaskComplete?.call(task, result);
    } catch (e) {
      if (task.retries < task.maxRetries) {
        task.retries++;
        _queue.insert(0, task);
      } else {
        onTaskError?.call(task, e);
      }
    } finally {
      _running.remove(task.id);
    }
    _runNext();
  }
}

// ──────────────────────────────────────────────
// GchCronExpression
// ──────────────────────────────────────────────
class GchCronExpression {
  final String expression;
  final Set<int> _minutes;
  final Set<int> _hours;
  final Set<int> _daysOfMonth;
  final Set<int> _months;
  final Set<int> _daysOfWeek;

  GchCronExpression._(
    this.expression,
    this._minutes,
    this._hours,
    this._daysOfMonth,
    this._months,
    this._daysOfWeek,
  );

  factory GchCronExpression.parse(String expr) {
    final parts = expr.trim().split(RegExp(r'\s+'));
    if (parts.length != 5) {
      throw FormatException('Cron expression must have 5 fields: $expr');
    }
    return GchCronExpression._(
      expr,
      _parseField(parts[0], 0, 59),
      _parseField(parts[1], 0, 23),
      _parseField(parts[2], 1, 31),
      _parseField(parts[3], 1, 12),
      _parseField(parts[4], 0, 6),
    );
  }

  static Set<int> _parseField(String field, int min, int max) {
    final result = <int>{};
    for (final part in field.split(',')) {
      if (part == '*') {
        for (int i = min; i <= max; i++) result.add(i);
      } else if (part.contains('/')) {
        final sub = part.split('/');
        final step = int.parse(sub[1]);
        int start = sub[0] == '*' ? min : int.parse(sub[0]);
        for (int i = start; i <= max; i += step) result.add(i);
      } else if (part.contains('-')) {
        final bounds = part.split('-');
        final lo = int.parse(bounds[0]);
        final hi = int.parse(bounds[1]);
        for (int i = lo; i <= hi; i++) result.add(i);
      } else {
        result.add(int.parse(part));
      }
    }
    return result;
  }

  bool matches(DateTime dt) {
    return _minutes.contains(dt.minute) &&
        _hours.contains(dt.hour) &&
        _daysOfMonth.contains(dt.day) &&
        _months.contains(dt.month) &&
        _daysOfWeek.contains(dt.weekday % 7);
  }

  DateTime nextRun({DateTime? from}) {
    var dt = (from ?? DateTime.now()).add(const Duration(minutes: 1));
    dt = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
    for (int attempt = 0; attempt < 525960; attempt++) {
      if (matches(dt)) return dt;
      dt = dt.add(const Duration(minutes: 1));
    }
    throw StateError('No matching time found within one year for: $expression');
  }

  List<DateTime> nextRuns(int count, {DateTime? from}) {
    final result = <DateTime>[];
    DateTime current = from ?? DateTime.now();
    for (int i = 0; i < count; i++) {
      current = nextRun(from: current);
      result.add(current);
    }
    return result;
  }

  String get description {
    if (expression == '* * * * *') return 'every minute';
    if (expression == '0 * * * *') return 'every hour';
    if (expression == '0 0 * * *') return 'every day at midnight';
    if (expression == '0 9 * * 1') return 'every Monday at 9am';
    final parts = expression.trim().split(RegExp(r'\s+'));
    final sb = StringBuffer('runs at ');
    sb.write('minute(s) ${parts[0]} ');
    sb.write('hour(s) ${parts[1]} ');
    sb.write('day-of-month ${parts[2]} ');
    sb.write('month ${parts[3]} ');
    sb.write('weekday ${parts[4]}');
    return sb.toString();
  }

  @override
  String toString() => 'GchCronExpression($expression)';
}

// ──────────────────────────────────────────────
// GchRateLimiter  (token bucket)
// ──────────────────────────────────────────────
class GchRateLimiter {
  final int maxRequests;
  final Duration window;
  int _tokens;
  DateTime _lastRefill;

  GchRateLimiter(this.maxRequests, this.window)
      : _tokens = maxRequests,
        _lastRefill = DateTime.now();

  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill);
    if (elapsed >= window) {
      final periods = elapsed.inMicroseconds ~/ window.inMicroseconds;
      _tokens = min(maxRequests, _tokens + periods * maxRequests);
      _lastRefill = now;
    }
  }

  int get remainingTokens {
    _refill();
    return _tokens;
  }

  Duration get resetIn {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill);
    if (elapsed >= window) return Duration.zero;
    return window - elapsed;
  }

  bool tryAcquire({int count = 1}) {
    _refill();
    if (_tokens >= count) {
      _tokens -= count;
      return true;
    }
    return false;
  }

  Future<void> acquire({int count = 1}) async {
    while (!tryAcquire(count: count)) {
      final wait = resetIn;
      await Future.delayed(wait.inMilliseconds > 0 ? wait : const Duration(milliseconds: 10));
    }
  }
}

// ──────────────────────────────────────────────
// GchRetryUtil
// ──────────────────────────────────────────────
class GchRetryUtil {
  GchRetryUtil._();

  static Future<T> retry<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(Object)? retryIf,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        if (retryIf != null && !retryIf(e)) rethrow;
        await Future.delayed(delay);
      }
    }
  }

  static Future<T> retryWithBackoff<T>(
    Future<T> Function() action, {
    int maxAttempts = 5,
    Duration initialDelay = const Duration(milliseconds: 500),
    double multiplier = 2.0,
    Duration maxDelay = const Duration(seconds: 30),
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(currentDelay);
        final nextMs =
            (currentDelay.inMilliseconds * multiplier).round();
        currentDelay = Duration(
            milliseconds: min(nextMs, maxDelay.inMilliseconds));
      }
    }
  }

  static Future<T?> withTimeout<T>(
    Future<T> action,
    Duration timeout, {
    T? fallback,
  }) async {
    try {
      return await action.timeout(timeout);
    } on TimeoutException {
      return fallback;
    }
  }
}

// ──────────────────────────────────────────────
// GchEventLoop – simple in-process event scheduler
// ──────────────────────────────────────────────
class _ScheduledEvent {
  final String id;
  final DateTime runAt;
  final void Function() callback;
  final bool repeating;
  final Duration? interval;

  _ScheduledEvent({
    required this.id,
    required this.runAt,
    required this.callback,
    this.repeating = false,
    this.interval,
  });
}

class GchEventLoop {
  final _events = SplayTreeMap<String, _ScheduledEvent>(
    (a, b) => a.compareTo(b),
  );
  Timer? _timer;
  bool _running = false;
  int _idCounter = 0;

  String scheduleAt(DateTime at, void Function() callback) {
    final id = 'evt_${++_idCounter}';
    _events[id] = _ScheduledEvent(
      id: id,
      runAt: at,
      callback: callback,
    );
    _reschedule();
    return id;
  }

  String scheduleAfter(Duration delay, void Function() callback) {
    return scheduleAt(DateTime.now().add(delay), callback);
  }

  String scheduleRepeating(Duration interval, void Function() callback) {
    final id = 'evt_${++_idCounter}';
    _events[id] = _ScheduledEvent(
      id: id,
      runAt: DateTime.now().add(interval),
      callback: callback,
      repeating: true,
      interval: interval,
    );
    _reschedule();
    return id;
  }

  bool cancel(String id) {
    if (_events.containsKey(id)) {
      _events.remove(id);
      _reschedule();
      return true;
    }
    return false;
  }

  void start() {
    _running = true;
    _reschedule();
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  int get pendingCount => _events.length;

  void _reschedule() {
    _timer?.cancel();
    if (!_running || _events.isEmpty) return;
    final next = _events.values
        .reduce((a, b) => a.runAt.isBefore(b.runAt) ? a : b);
    final delay = next.runAt.difference(DateTime.now());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, _tick);
  }

  void _tick() {
    final now = DateTime.now();
    final toRun = _events.values
        .where((e) => !e.runAt.isAfter(now))
        .toList();
    for (final event in toRun) {
      _events.remove(event.id);
      try {
        event.callback();
      } catch (e) {
        print('GchEventLoop: error in event ${event.id}: $e');
      }
      if (event.repeating && event.interval != null) {
        _events[event.id] = _ScheduledEvent(
          id: event.id,
          runAt: now.add(event.interval!),
          callback: event.callback,
          repeating: true,
          interval: event.interval,
        );
      }
    }
    _reschedule();
  }
}

// ──────────────────────────────────────────────
// GchCircuitBreaker
// ──────────────────────────────────────────────
enum _CircuitState { closed, halfOpen, open }

class GchCircuitBreaker {
  final int failureThreshold;
  final Duration recoveryTime;
  final int successThresholdInHalfOpen;

  _CircuitState _state = _CircuitState.closed;
  int _failureCount = 0;
  int _successCountInHalfOpen = 0;
  DateTime? _openedAt;

  GchCircuitBreaker({
    this.failureThreshold = 5,
    this.recoveryTime = const Duration(seconds: 30),
    this.successThresholdInHalfOpen = 2,
  });

  bool get isAvailable {
    if (_state == _CircuitState.closed) return true;
    if (_state == _CircuitState.open) {
      if (_openedAt != null &&
          DateTime.now().difference(_openedAt!) >= recoveryTime) {
        _state = _CircuitState.halfOpen;
        _successCountInHalfOpen = 0;
        return true;
      }
      return false;
    }
    return true; // halfOpen
  }

  Future<T> call<T>(Future<T> Function() action) async {
    if (!isAvailable) {
      throw StateError(
          'Circuit breaker is open. Retry after $recoveryTime.');
    }
    try {
      final result = await action();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    if (_state == _CircuitState.halfOpen) {
      _successCountInHalfOpen++;
      if (_successCountInHalfOpen >= successThresholdInHalfOpen) {
        _state = _CircuitState.closed;
        _failureCount = 0;
      }
    } else {
      _failureCount = 0;
    }
  }

  void _onFailure() {
    _failureCount++;
    if (_state == _CircuitState.halfOpen) {
      _state = _CircuitState.open;
      _openedAt = DateTime.now();
    } else if (_failureCount >= failureThreshold) {
      _state = _CircuitState.open;
      _openedAt = DateTime.now();
    }
  }

  String get stateDescription {
    switch (_state) {
      case _CircuitState.closed:
        return 'closed (healthy)';
      case _CircuitState.open:
        return 'open (failing, recover in ${recoveryTime.inSeconds}s)';
      case _CircuitState.halfOpen:
        return 'half-open (testing recovery)';
    }
  }

  void reset() {
    _state = _CircuitState.closed;
    _failureCount = 0;
    _successCountInHalfOpen = 0;
    _openedAt = null;
  }
}

// ──────────────────────────────────────────────
// GchTimer – extended timer with pause/resume
// ──────────────────────────────────────────────
class GchResumableTimer {
  final Duration duration;
  final void Function() callback;

  Duration _remaining;
  DateTime? _startedAt;
  Timer? _timer;
  bool _completed = false;
  bool _paused = false;

  GchResumableTimer(this.duration, this.callback)
      : _remaining = duration;

  void start() {
    if (_completed) return;
    _paused = false;
    _startedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer(_remaining, _onComplete);
  }

  void pause() {
    if (_paused || _completed) return;
    _paused = true;
    if (_startedAt != null) {
      final elapsed = DateTime.now().difference(_startedAt!);
      _remaining = _remaining - elapsed;
      if (_remaining.isNegative) _remaining = Duration.zero;
    }
    _timer?.cancel();
    _timer = null;
    _startedAt = null;
  }

  void resume() {
    if (!_paused || _completed) return;
    start();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _startedAt = null;
    _remaining = duration;
    _paused = false;
  }

  bool get isActive => _timer?.isActive == true;
  bool get isPaused => _paused;
  bool get isCompleted => _completed;

  Duration get remaining {
    if (_paused || _startedAt == null) return _remaining;
    final elapsed = DateTime.now().difference(_startedAt!);
    final rem = _remaining - elapsed;
    return rem.isNegative ? Duration.zero : rem;
  }

  void _onComplete() {
    _completed = true;
    _timer = null;
    callback();
  }
}

// ──────────────────────────────────────────────
// GchTaskSchedulerStats
// ──────────────────────────────────────────────
class GchTaskSchedulerStats {
  int totalEnqueued = 0;
  int totalCompleted = 0;
  int totalFailed = 0;
  int totalRetried = 0;
  final Map<String, int> completedByName = {};
  final List<Duration> executionTimes = [];

  void recordEnqueue() => totalEnqueued++;

  void recordComplete(String name, Duration elapsed) {
    totalCompleted++;
    completedByName[name] = (completedByName[name] ?? 0) + 1;
    executionTimes.add(elapsed);
  }

  void recordFailure() => totalFailed++;
  void recordRetry() => totalRetried++;

  double get averageExecutionMs {
    if (executionTimes.isEmpty) return 0;
    final total =
        executionTimes.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    return total / executionTimes.length;
  }

  Duration get maxExecutionTime {
    if (executionTimes.isEmpty) return Duration.zero;
    return executionTimes.reduce((a, b) => a > b ? a : b);
  }

  Duration get minExecutionTime {
    if (executionTimes.isEmpty) return Duration.zero;
    return executionTimes.reduce((a, b) => a < b ? a : b);
  }

  double get successRate {
    if (totalEnqueued == 0) return 0;
    return totalCompleted / totalEnqueued;
  }

  @override
  String toString() => 'Stats(enqueued=$totalEnqueued, '
      'completed=$totalCompleted, failed=$totalFailed, '
      'retried=$totalRetried, successRate=${(successRate * 100).toStringAsFixed(1)}%)';
}

// ignore: unused_element
final _mathRef = max(0, 0);
