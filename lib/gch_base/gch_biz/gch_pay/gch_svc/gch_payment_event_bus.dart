import 'dart:async';
import 'package:flutter/foundation.dart';

/// 标准支付事件类型
enum PaymentEventType {
  initiated,     // 支付已发起
  dialogShown,   // 支付弹窗已显示（新增）
  processing,    // 支付处理中
  completed,     // 支付完成
  failed,        // 支付失败
  cancelled,     // 支付取消
  custom,        // 自定义事件
}

/// 支付事件对象
class PaymentEvent {
  final PaymentEventType type;
  final String? orderId;
  final dynamic data;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  PaymentEvent(
    this.type, {
    this.orderId,
    this.data,
    this.error,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'PaymentEvent(type: $type, orderId: $orderId, data: $data, error: $error, time: $timestamp)';
}

/// 生产级支付事件总线（线程安全，支持多订阅者，健壮的错误处理）
class PaymentEventBus {
  PaymentEventBus._internal();
  static final PaymentEventBus _instance = PaymentEventBus._internal();
  static PaymentEventBus get instance => _instance;

  final StreamController<PaymentEvent> _controller = StreamController<PaymentEvent>.broadcast();

  bool get isClosed => _controller.isClosed;

  /// 事件流（只读）
  Stream<PaymentEvent> get events => _controller.stream;

  /// 发布事件（异步模式，避免阻塞UI线程）
  void publish(PaymentEvent event) {
    if (_controller.isClosed) {
      debugPrint('[PaymentEventBus] Attempted to publish to closed controller: $event');
      return;
    }
    
    // 使用微任务异步发布，避免阻塞当前执行流
    scheduleMicrotask(() {
      _publishSync(event);
    });
  }

  /// 同步发布事件（仅在特殊场景使用，如关键错误处理）
  void publishSync(PaymentEvent event) {
    if (_controller.isClosed) {
      debugPrint('[PaymentEventBus] Attempted to publish to closed controller: $event');
      return;
    }
    _publishSync(event);
  }

  /// 内部同步发布实现
  void _publishSync(PaymentEvent event) {
    try {
      final normalized = _normalizeEvent(event);
      _controller.add(normalized);
    } catch (e, s) {
      debugPrint('[PaymentEventBus] Error publishing event: $e\n$s');
      // 生产环境可上报日志/埋点
    }
  }

  /// 发布错误事件（便于统一错误处理）
  void publishError(Object error, {String? orderId, dynamic data, StackTrace? stackTrace}) {
    publish(PaymentEvent(
      PaymentEventType.failed,
      orderId: orderId,
      data: data,
      error: error,
      stackTrace: stackTrace,
    ),);
  }

  /// 订阅事件（支持 onError/onDone，返回订阅对象，便于管理）
  StreamSubscription<PaymentEvent> subscribe(
    void Function(PaymentEvent event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return events.listen(
      onData,
      onError: onError ??
          (Object error, StackTrace stack) {
            debugPrint('[PaymentEventBus] Unhandled error: $error\n$stack');
          },
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// 安全关闭（防止多次关闭异常）
  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  PaymentEvent _normalizeEvent(PaymentEvent event) {
    if (event.orderId != null && event.orderId!.isNotEmpty) {
      return event;
    }
    if (event.type != PaymentEventType.processing &&
        event.type != PaymentEventType.completed) {
      return event;
    }

    final dataMap = _asDataMap(event.data);
    final fallback = _extractOrderIdCandidate(dataMap);
    if (fallback == null || fallback.isEmpty) {
      debugPrint('[PaymentEventBus] missing orderId for ${event.type}');
      return event;
    }

    return PaymentEvent(
      event.type,
      orderId: fallback,
      data: event.data,
      error: event.error,
      stackTrace: event.stackTrace,
      timestamp: event.timestamp,
    );
  }

  Map<String, dynamic>? _asDataMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  String? _extractOrderIdCandidate(Map<String, dynamic>? data) {
    if (data == null) return null;
    for (final key in [
      'orderId',
      'order_id',
      'orderNum',
      'order_num',
      'transactionId',
      'transaction_id',
      'purchaseId',
      'purchaseID',
      'trade_no',
      'flowId',
    ]) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }
}

/// 支付结果回调接口
typedef PaymentResultCallback = void Function(PaymentEvent event);

/// 支付错误回调接口
typedef PaymentErrorCallback = void Function(Object error, StackTrace? stack);
