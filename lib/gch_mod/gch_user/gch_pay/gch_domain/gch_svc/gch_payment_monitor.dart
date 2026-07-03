import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_event_bus.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_svc/gch_order_sync_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_payment_monitor.g.dart';

/// Payment Monitor Provider
@Riverpod(keepAlive: true)
PaymentMonitor paymentMonitor(PaymentMonitorRef ref) {
  final orderSyncService = ref.watch(orderSyncServiceProvider);
  final monitor = PaymentMonitor(
    ref: ref,
    orderSyncService: orderSyncService,
  );
  ref.onDispose(monitor.dispose);
  return monitor;
}

/// Payment Monitor - 三阶段超时的支付监控
///
/// 设计原则：
/// 1. **事件驱动**：监听 PaymentEventBus 事件
/// 2. **三阶段超时**：
///    - 信号检测（10秒）：检测 SDK 是否成功启动，触发 onNoSignalDetected
///    - 第一阶段（30秒）：初次超时，触发订单恢复
///    - 第二阶段（2分钟）：总超时，返回超时状态
/// 3. **无轮询**：不做数据库轮询（事件丢失时数据库也不会更新，轮询无效）
///
/// 与 PaymentEventBus 的关系：
/// - PaymentEventBus: 全局事件总线，负责发布/订阅支付事件
/// - PaymentMonitor: 事件消费者，负责监控特定支付流程的结果
class PaymentMonitor {
  final Ref ref;
  final OrderSyncService orderSyncService;

  // ========== Configuration ==========

  /// 信号检测超时：检测 SDK 是否成功启动
  static const Duration signalTimeout = Duration(seconds: 10);

  /// 第一阶段超时：初次超时，触发订单恢复
  static const Duration initialTimeout = Duration(seconds: 30);

  /// 第二阶段超时：总超时时间（从开始监控算起）
  static const Duration totalTimeout = Duration(minutes: 2);

  // ========== State ==========

  /// Event subscription (订阅 PaymentEventBus)
  StreamSubscription<PaymentEvent>? _eventSubscription;

  /// 信号检测 Timer（10秒）- 检测 SDK 是否启动
  Timer? _signalTimeoutTimer;

  /// 第一阶段超时 Timer（30秒）
  Timer? _initialTimeoutTimer;

  /// 第二阶段超时 Timer（2分钟总超时）
  Timer? _totalTimeoutTimer;

  /// 无信号回调 - 当 10 秒内未收到 SDK 事件时触发
  void Function()? onNoSignalDetected;

  /// Current monitoring context
  PaymentMonitorContext? _currentContext;

  /// Active payment completer
  Completer<PaymentMonitorResult>? _activeCompleter;

  /// Flag: payment flow has started (dialog shown or processing)
  bool _paymentFlowStarted = false;

  /// Flag: entered background monitoring phase
  bool _inBackgroundPhase = false;

  PaymentMonitor({
    required this.ref,
    required this.orderSyncService,
  });

  // ========== Public API ==========

  /// Start monitoring payment
  ///
  /// 订阅 PaymentEventBus 事件，等待支付结果
  /// 两阶段超时：30秒初次超时 → 2分钟总超时
  Future<PaymentMonitorResult> startMonitoring({
    required String userId,
    required String productId,
    required String providerCode,
    String? orderId,
  }) async {
    debugPrint('🔍 Starting payment monitoring: productId=$productId, provider=$providerCode');

    // Cleanup previous monitoring
    await stopMonitoring();

    // Initialize context
    _currentContext = PaymentMonitorContext(
      userId: userId,
      productId: productId,
      providerCode: providerCode.toLowerCase(),
      orderId: orderId,
    );
    _paymentFlowStarted = false;
    _inBackgroundPhase = false;

    // Create completer
    _activeCompleter = Completer<PaymentMonitorResult>();
    final completer = _activeCompleter!;

    // Subscribe to payment events (核心：依赖 PaymentEventBus)
    _subscribeToEvents(completer);

    // Setup two-phase timeout
    _setupTwoPhaseTimeout(completer);

    // Wait for result
    final result = await completer.future;
    debugPrint('📋 Payment monitoring result: ${result.status}');

    return result;
  }

  /// Stop monitoring (cleanup)
  Future<void> stopMonitoring() async {
    // 只有在有活动监控时才输出日志
    final hadActiveMonitoring = _eventSubscription != null ||
        _currentContext != null ||
        _activeCompleter != null;

    if (hadActiveMonitoring) {
      debugPrint('🛑 [Monitor] stopMonitoring 被调用');
      debugPrint('   eventSubscription=${_eventSubscription != null}');
      debugPrint('   currentContext=${_currentContext != null}');
      debugPrint('   activeCompleter=${_activeCompleter != null}, isCompleted=${_activeCompleter?.isCompleted}');
    }

    _eventSubscription?.cancel();
    _eventSubscription = null;

    _signalTimeoutTimer?.cancel();
    _signalTimeoutTimer = null;

    _initialTimeoutTimer?.cancel();
    _initialTimeoutTimer = null;

    _totalTimeoutTimer?.cancel();
    _totalTimeoutTimer = null;

    _currentContext = null;
    _paymentFlowStarted = false;
    _inBackgroundPhase = false;

    if (hadActiveMonitoring) {
      debugPrint('🧹 Payment monitoring stopped');
    }
  }

  /// Update order ID (when received from payment response)
  void updateOrderId(String orderId) {
    if (_currentContext != null) {
      _currentContext = _currentContext!.copyWith(orderId: orderId);
      debugPrint('📌 Order ID updated: $orderId');
    }
  }

  /// Check if currently monitoring
  bool get isMonitoring => _activeCompleter != null && !_activeCompleter!.isCompleted;

  /// Check if in background monitoring phase
  bool get isInBackgroundPhase => _inBackgroundPhase;

  // ========== Event Handling ==========

  /// 订阅 PaymentEventBus 事件
  ///
  /// 核心逻辑：监听支付事件总线，根据事件类型完成监控
  void _subscribeToEvents(Completer<PaymentMonitorResult> completer) {
    debugPrint('🔔 [Monitor] 开始订阅支付事件');
    _eventSubscription = PaymentEventBus.instance.subscribe((event) {
      debugPrint('📡 [Monitor] 收到事件: ${event.type}, orderId=${event.orderId}, completer.isCompleted=${completer.isCompleted}');

      // Check if event is for current payment
      if (!_isEventForCurrentPayment(event)) {
        debugPrint('⏭️ Skipping unrelated event');
        return;
      }

      // Capture order ID from event
      if (event.orderId != null && _currentContext?.orderId == null) {
        updateOrderId(event.orderId!);
      }

      // Handle event based on type
      _handlePaymentEvent(event, completer);
    });
  }

  /// 检查事件是否属于当前支付流程
  bool _isEventForCurrentPayment(PaymentEvent event) {
    final context = _currentContext;
    if (context == null) return false;

    final eventData = event.data as Map<String, dynamic>?;

    // 🔑 优先检查 productId（来自 SDK 原始数据，最可靠）
    // 解决场景：点击A取消→点击B支付，A的延迟取消事件会携带A的productId
    // 注意：Android USER_CANCELED 时 purchaseStream 的合成事件 productId 可能为空，
    // 空 productId 视为"未知产品"，不拒绝，交由后续 orderId 兜底。
    final eventProductId = eventData?['productId']?.toString();
    if (eventProductId != null && eventProductId.isNotEmpty && eventProductId != context.productId) {
      debugPrint('⏭️ 跳过其他产品的事件: event=$eventProductId, context=${context.productId}');
      return false;
    }

    // 🎯 关键事件接受（通过了 productId 检查）
    // 这些是支付流程的终态或关键状态
    if (event.type == PaymentEventType.cancelled ||
        event.type == PaymentEventType.failed ||
        event.type == PaymentEventType.completed ||
        event.type == PaymentEventType.processing) {
      debugPrint('✅ 接受关键支付事件: ${event.type}');
      return true;
    }

    // Check provider code match
    if (eventData != null) {
      final eventProvider = eventData['providerCode']?.toString().toLowerCase();
      if (eventProvider != null && eventProvider != context.providerCode) {
        return false;
      }
    }

    // Check order ID match (if both exist)
    if (context.orderId != null && event.orderId != null) {
      if (context.orderId != event.orderId &&
          !context.orderId!.contains(event.orderId!) &&
          !event.orderId!.contains(context.orderId!)) {
        return false;
      }
    }

    return true;
  }

  /// 处理支付事件
  ///
  /// 根据事件类型决定监控结果
  void _handlePaymentEvent(PaymentEvent event, Completer<PaymentMonitorResult> completer) {
    if (completer.isCompleted) return;

    switch (event.type) {
      case PaymentEventType.dialogShown:
      case PaymentEventType.processing:
        debugPrint('💰 Payment processing: ${event.orderId}');
        _markPaymentFlowStarted();
        break;

      case PaymentEventType.completed:
        debugPrint('✅ Payment completed: ${event.orderId}');
        _completeWithSuccess(completer, event.orderId);
        break;

      case PaymentEventType.failed:
        debugPrint('❌ Payment failed: ${event.error}');
        _completeWithFailure(completer, event.error?.toString());
        break;

      case PaymentEventType.cancelled:
        debugPrint('🚫 Payment cancelled');
        _completeWithCancelled(completer);
        break;

      default:
        break;
    }
  }

  void _markPaymentFlowStarted() {
    if (!_paymentFlowStarted) {
      _paymentFlowStarted = true;
      // Cancel signal timer since SDK has responded
      _signalTimeoutTimer?.cancel();
      _signalTimeoutTimer = null;
      debugPrint('✅ Payment flow started');
    }
  }

  // ========== Two-Phase Timeout ==========

  /// 设置超时机制
  ///
  /// 信号检测（10秒）：检测 SDK 是否成功启动
  /// 第一阶段（30秒）：初次超时，触发订单恢复，进入后台监控
  /// 第二阶段（2分钟）：总超时，返回超时状态
  void _setupTwoPhaseTimeout(Completer<PaymentMonitorResult> completer) {
    // 信号检测：10秒无事件则触发回调
    _signalTimeoutTimer = Timer(signalTimeout, () {
      if (completer.isCompleted) return;
      if (!_paymentFlowStarted) {
        debugPrint('⚠️ No SDK signal detected within ${signalTimeout.inSeconds}s');
        onNoSignalDetected?.call();
      }
    });

    // 第一阶段：30秒初次超时
    _initialTimeoutTimer = Timer(initialTimeout, () {
      if (completer.isCompleted) return;

      debugPrint('⏱️ Initial timeout (${initialTimeout.inSeconds}s), entering background phase');

      // 进入后台监控阶段
      _inBackgroundPhase = true;

      // 触发订单恢复（异步，不阻塞）
      orderSyncService.triggerOrderRecovery(reason: 'initial_timeout');

      debugPrint('🔄 Background monitoring started, waiting for events...');
    });

    // 第二阶段：2分钟总超时
    _totalTimeoutTimer = Timer(totalTimeout, () {
      if (completer.isCompleted) return;

      debugPrint('⏱️ Total timeout (${totalTimeout.inMinutes}min), completing as timeout');

      // 再次触发订单恢复
      orderSyncService.triggerOrderRecovery(reason: 'total_timeout');

      // 返回超时状态
      _completeWithTimeout(completer);
    });
  }

  // ========== Completion ==========

  void _completeWithSuccess(Completer<PaymentMonitorResult> completer, String? orderId) {
    debugPrint('🎯 [Monitor] _completeWithSuccess 被调用, orderId=$orderId, isCompleted=${completer.isCompleted}');
    if (completer.isCompleted) {
      debugPrint('⚠️ [Monitor] completer 已完成，跳过');
      return;
    }
    debugPrint('✅ [Monitor] 监控成功完成');
    stopMonitoring();
    completer.complete(PaymentMonitorResult.success(orderId: orderId));
  }

  void _completeWithFailure(Completer<PaymentMonitorResult> completer, String? error) {
    if (completer.isCompleted) return;
    stopMonitoring();
    completer.complete(PaymentMonitorResult.failed(error: error));
  }

  void _completeWithCancelled(Completer<PaymentMonitorResult> completer) {
    if (completer.isCompleted) return;
    stopMonitoring();
    completer.complete(const PaymentMonitorResult.cancelled());
  }

  void _completeWithTimeout(Completer<PaymentMonitorResult> completer) {
    if (completer.isCompleted) return;
    stopMonitoring();
    completer.complete(const PaymentMonitorResult.timeout());
  }

  // ========== Cleanup ==========

  void dispose() {
    stopMonitoring();
    debugPrint('✅ PaymentMonitor disposed');
  }
}

/// Payment Monitor Context
class PaymentMonitorContext {
  final String userId;
  final String productId;
  final String providerCode;
  final String? orderId;

  const PaymentMonitorContext({
    required this.userId,
    required this.productId,
    required this.providerCode,
    this.orderId,
  });

  PaymentMonitorContext copyWith({
    String? userId,
    String? productId,
    String? providerCode,
    String? orderId,
  }) {
    return PaymentMonitorContext(
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      providerCode: providerCode ?? this.providerCode,
      orderId: orderId ?? this.orderId,
    );
  }
}

/// Payment Monitor Result
class PaymentMonitorResult {
  final PaymentMonitorStatus status;
  final String? orderId;
  final String? error;

  const PaymentMonitorResult._({
    required this.status,
    this.orderId,
    this.error,
  });

  const PaymentMonitorResult.success({String? orderId})
      : this._(status: PaymentMonitorStatus.success, orderId: orderId);

  const PaymentMonitorResult.failed({String? error})
      : this._(status: PaymentMonitorStatus.failed, error: error);

  const PaymentMonitorResult.cancelled()
      : this._(status: PaymentMonitorStatus.cancelled);

  const PaymentMonitorResult.timeout()
      : this._(status: PaymentMonitorStatus.timeout);

  bool get isSuccess => status == PaymentMonitorStatus.success;
  bool get isFailed => status == PaymentMonitorStatus.failed;
  bool get isCancelled => status == PaymentMonitorStatus.cancelled;
  bool get isTimeout => status == PaymentMonitorStatus.timeout;
}

/// Payment Monitor Status
enum PaymentMonitorStatus {
  success,
  failed,
  cancelled,
  timeout,
}
