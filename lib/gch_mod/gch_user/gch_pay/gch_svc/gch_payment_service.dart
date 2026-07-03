import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_event_bus.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_google_apple_pay_provider.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_manager.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_model/gch_product_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_wire/gch_appprovider.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_entity/gch_payment_flow_state.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_entity/gch_checkout_ui_event.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_guard/gch_payment_guard.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_svc/gch_order_sync_service.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_svc/gch_payment_monitor.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_strategy/gch_payment_strategy.dart' show PaymentContext, GenericPaymentParams;
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_strategy/gch_payment_strategy_factory.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_bankendapi/gch_pay_api.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_payment_service.g.dart';

/// Payment Service Provider
@Riverpod(keepAlive: true)
PaymentService paymentService(PaymentServiceRef ref) {
  final paymentManager = ref.watch(paymentManagerProvider);
  final orderSyncService = ref.watch(orderSyncServiceProvider);
  final paymentMonitor = ref.watch(paymentMonitorProvider);

  final service = PaymentService(
    ref: ref,
    paymentManager: paymentManager,
    orderSyncService: orderSyncService,
    paymentMonitor: paymentMonitor,
  );

  ref.onDispose(service.dispose);
  return service;
}

/// PaymentManager Provider (imported from existing module)
@Riverpod(keepAlive: true)
PaymentManager paymentManager(PaymentManagerRef ref) {
  final manager = PaymentManager(ref: ref);
  ref.onDispose(manager.dispose);
  return manager;
}

/// Payment Service - Core Orchestrator
///
/// Architecture:
/// ```
/// PaymentService (Orchestrator)
///     ├── PaymentGuard (Concurrency Control)
///     ├── OrderSyncService (Order State Management)
///     ├── PaymentMonitor (Background Monitoring)
///     └── PaymentStrategyFactory (Strategy Pattern)
/// ```
///
/// Design Principles:
/// 1. Does not hold BuildContext, notifies UI layer through events
/// 2. Wraps existing PaymentManager, does not modify underlying logic
/// 3. Uses Strategy pattern to support multiple payment methods
/// 4. Delegates concurrency control to PaymentGuard
/// 5. Delegates order state to OrderSyncService
/// 6. Delegates background monitoring to PaymentMonitor
///
/// Responsibilities:
/// 1. Orchestrate payment flow (guard -> check order -> execute -> monitor)
/// 2. Manage payment flow state (PaymentFlowState)
/// 3. Emit UI events (CheckoutUIEvent)
/// 4. Coordinate between guard, sync, and monitor services
class PaymentService {
  final Ref _ref;
  final PaymentManager _paymentManager;
  final OrderSyncService _orderSyncService;
  final PaymentMonitor _paymentMonitor;
  late final PaymentStrategyFactory _strategyFactory;

  /// Payment guard (singleton)
  final PaymentGuard _guard = PaymentGuard.instance;

  /// Current payment flow state
  PaymentFlowState _currentState = const PaymentFlowState.idle();

  /// State stream controller
  final _stateController = StreamController<PaymentFlowState>.broadcast();

  /// UI event stream controller
  final _eventController = StreamController<CheckoutUIEvent>.broadcast();

  /// Current payment context (for cancel/restore)
  PaymentContext? _currentContext;

  /// Callback completers (for waiting on UI feedback)
  final Map<String, Completer<UIEventCallbackResult>> _pendingCallbacks = {};

  /// Flow tracking
  String? _currentFlowId;
  int? _flowStartMs;
  String? _activeFlowId;
  String? _activeUserId;
  String? _activeProductId;
  String? _lastUserId;

  /// PaymentEventBus subscription to drive UI events
  StreamSubscription<PaymentEvent>? _paymentEventSubscription;

  /// Prevent duplicate config download triggers
  bool _configDownloadTriggered = false;
  final Set<String> _handledOrphanPurchaseIds = {};

  PaymentService({
    required Ref ref,
    required PaymentManager paymentManager,
    required OrderSyncService orderSyncService,
    required PaymentMonitor paymentMonitor,
  })  : _ref = ref,
        _paymentManager = paymentManager,
        _orderSyncService = orderSyncService,
        _paymentMonitor = paymentMonitor {
    _strategyFactory = PaymentStrategyFactory(_paymentManager);
    _subscribeToPaymentEvents();
  }

  void _subscribeToPaymentEvents() {
    _paymentEventSubscription =
        PaymentEventBus.instance.subscribe(_handlePaymentBusEvent);
  }

  void _handlePaymentBusEvent(PaymentEvent event) {
    // 🔑 关键事件：不受流程约束，始终处理（解决事件延迟到达的问题）
    if (_isKeyEvent(event)) {
      _handleKeyEvent(event);
      return;
    }

    if (!_shouldHandlePaymentEvent(event)) {
      _handleOrphanPaymentEvent(event);
      debugPrint('⏭️ Ignoring payment event: ${event.type}');
      return;
    }

    switch (event.type) {
      case PaymentEventType.processing:
        debugPrint('💰 Payment processing (event bus), notifying UI');
        _emitEvent(const CheckoutUIEvent.showPaymentProcessingDialog());
        break;
      case PaymentEventType.completed:
        debugPrint('✅ Payment completed (event bus)');
        // ✅ 纯 UI 更新：隐藏对话框，业务逻辑由 _handlePaymentResult 处理
        _emitEvent(const CheckoutUIEvent.hidePaymentProcessingDialog());
        break;
      case PaymentEventType.failed:
        debugPrint('⚠️ Payment failed (event bus), hiding dialog');
        // ✅ 纯 UI 更新：隐藏对话框，业务逻辑由 _handlePaymentResult 处理
        _emitEvent(const CheckoutUIEvent.hidePaymentProcessingDialog());
        break;
      case PaymentEventType.cancelled:
        debugPrint('⚠️ Payment cancelled (event bus), hiding dialog');
        // ✅ 纯 UI 更新：隐藏对话框，业务逻辑由 _handlePaymentResult 处理
        _emitEvent(const CheckoutUIEvent.hidePaymentProcessingDialog());
        break;
      case PaymentEventType.dialogShown:
        _configDownloadTriggered = false;
        break;
      case PaymentEventType.custom:
        // 🔑 关键自定义事件（如 already_subscribed）已在 _handleKeyEvent 中处理
        // 此处仅处理其他自定义事件（如有）
        break;
      default:
        break;
    }
  }

  void _handleOrphanPaymentEvent(PaymentEvent event) {
    if (event.type != PaymentEventType.completed) {
      return;
    }

    final data = _asEventDataMap(event.data);
    final eventProductId = data?['productId']?.toString();
    final orderId = event.orderId?.toString();
    if (eventProductId == null || orderId == null || orderId.isEmpty) {
      return;
    }

    // Only handle completed events for other products to avoid blocking UI flow.
    if (_activeProductId != null && eventProductId == _activeProductId) {
      debugPrint('🔄 [Orphan] Same productId as active flow, skipping orphan handling: '
          'productId=$eventProductId, orderId=$orderId');
      return;
    }

    if (_handledOrphanPurchaseIds.contains(orderId)) {
      return;
    }
    _handledOrphanPurchaseIds.add(orderId);

    debugPrint('🔄 [Orphan] Payment completed: productId=$eventProductId, orderId=$orderId');
    unawaited(_handleOrphanPaymentCompletion(orderId));
  }

  Future<void> _handleOrphanPaymentCompletion(String orderId) async {
    // Background recovery only: keep UI flow untouched.
    debugPrint('🔄 [Orphan] Running background recovery for orderId=$orderId');
    await _triggerOrderRecovery('orphan_payment_completed');
    await _refreshSession();
  }

  /// 判断是否为关键事件（不受流程约束）
  ///
  /// 关键事件：即使没有活动流程也需要处理，因为：
  /// 1. 用户体验关键（如 already_subscribed 必须告知用户）
  /// 2. 事件可能延迟到达（StoreKit 队列特性）
  bool _isKeyEvent(PaymentEvent event) {
    if (event.type == PaymentEventType.custom) {
      final action = event.data?['action']?.toString();
      return action == 'already_subscribed';
    }
    return false;
  }

  /// 处理关键事件
  void _handleKeyEvent(PaymentEvent event) {
    final action = event.data?['action']?.toString();

    if (action == 'already_subscribed') {
      final productId = event.data?['productId']?.toString() ?? '';
      final originalProductId = event.data?['originalProductId']?.toString();
      final orderNum = event.data?['orderNum']?.toString();

      // 区分两种场景：
      // 1. 同一商品重复购买：originalProductId 为空或与 productId 相同
      // 2. 切换到不同商品（升级/降级）：originalProductId 与 productId 不同
      final bool isSubscriptionSwitch = originalProductId != null &&
          originalProductId.isNotEmpty &&
          originalProductId != productId;

      debugPrint('🔔 [KeyEvent] 已订阅: productId=$productId, '
          'originalProductId=$originalProductId, isSwitch=$isSubscriptionSwitch, order=$orderNum');

      _emitEvent(CheckoutUIEvent.showAlreadySubscribedDialog(
        productId: productId,
        isSubscriptionSwitch: isSubscriptionSwitch,
      ));
      _emitEvent(const CheckoutUIEvent.hidePaymentProcessingDialog());

      // 🔑 重置 flowState，允许后续购买
      _updateState(PaymentFlowState.cancelled(
        productId: productId,
        message: 'already_subscribed',
      ));

      if (_activeFlowId != null) {
        _endFlowTracking();
        _guard.releaseLock();
      }

      if (orderNum != null && orderNum.isNotEmpty) {
        _cancelOrder(orderNum, productId, 'already_subscribed');
      }
    }
  }

  /// 取消订单（后端+本地）
  Future<void> _cancelOrder(String orderNum, String productId, String reason) async {
    debugPrint('🧹 取消订单: $orderNum, reason=$reason');
    try {
      final payApi = _ref.read(payApiProvider);
      await payApi.cancelOrder(orderId: orderNum, reason: reason, productId: productId);
      debugPrint('✅ 后端订单已取消: $orderNum');
    } catch (e) {
      debugPrint('⚠️ 后端取消失败: $e');
    }
    try {
      final orderService = _ref.read(orderServiceProvider);
      await orderService.deleteOrder(orderNum);
      debugPrint('✅ 本地订单已删除: $orderNum');
    } catch (e) {
      debugPrint('⚠️ 本地删除失败: $e');
    }
  }

  // ========== Public Properties ==========

  /// Current state
  PaymentFlowState get currentState => _currentState;

  /// State stream
  Stream<PaymentFlowState> get stateStream => _stateController.stream;

  /// UI event stream
  Stream<CheckoutUIEvent> get eventStream => _eventController.stream;

  /// Is processing (locked)
  bool get isProcessing => _guard.isLocked;

  /// Get strategy factory
  PaymentStrategyFactory get strategyFactory => _strategyFactory;

  /// Get payment guard
  PaymentGuard get guard => _guard;

  // ========== Initialization ==========

  /// Initialize service
  Future<void> initialize() async {
    _updateState(const PaymentFlowState.initializing());

    try {
      // Ensure PaymentManager is bootstrapped
      final success = await _paymentManager.bootstrap();
      if (!success) {
        _updateState(const PaymentFlowState.failed(
          reason: PaymentFailureReason.sdkInitializationFailed,
          message: 'SDK initialization failed',
          canRetry: true,
        ));
        return;
      }

      // Load available payment methods
      final availableMethods = await _paymentManager.getAvailableMethods();

      _updateState(PaymentFlowState.ready(
        products: [], // Products loaded externally
        availableMethods: availableMethods,
      ));

      debugPrint('✅ PaymentService initialized, methods: ${availableMethods.length}');
    } catch (e) {
      debugPrint('❌ PaymentService init failed: $e');
      _updateState(PaymentFlowState.failed(
        reason: PaymentFailureReason.sdkInitializationFailed,
        message: 'SDK initialization failed: $e',
        canRetry: true,
      ));
    }
  }

  // ========== Payment Flow ==========

  /// Start payment with full guard and monitoring support
  ///
  /// Flow:
  /// 1. Debounce check
  /// 2. Acquire payment lock
  /// 3. Check user login
  /// 4. Check unpaid orders
  /// 5. Validate payment method
  /// 6. Execute payment
  /// 7. Monitor result
  /// 8. Release lock
  Future<PaymentFlowState> startPayment({
    required ProductInfo product,
    required PayProvider method,
    String? userId,
    String? existingOrderId,
    int? payProviderId,
    Map<String, dynamic>? additionalParams,
    bool skipUnpaidCheck = false,
  }) async {
    debugPrint('🚀 startPayment: ${product.productId}, method: ${method.name}');
    debugPrint('🔍 [Lock] 当前锁状态: isLocked=${_guard.isLocked}, currentLockKey=${_guard.currentLockKey}');
    final flowStopwatch = Stopwatch()..start();

    // 1. Debounce check
    if (_guard.shouldDebounce()) {
      debugPrint('⚠️ startPayment: debounced');
      return _currentState;
    }

    // 2. Check user login status
    if (userId == null || userId.isEmpty) {
      _updateState(const PaymentFlowState.requiresAction(
        action: PaymentActionRequired.login,
        message: 'Login required',
      ));
      _emitEvent(const CheckoutUIEvent.navigateToLogin());
      return _currentState;
    }

    // 3. Ensure order scope is aligned with current user
    final ensureOrderScopeStopwatch = Stopwatch()..start();
    await _ensureOrderScope(userId);
    ensureOrderScopeStopwatch.stop();
    debugPrint(
      '⏱️ [PaymentService] ensureOrderScope finished in '
      '${ensureOrderScopeStopwatch.elapsedMilliseconds}ms '
      '(product=${product.productId}, method=${method.name})',
    );

    // 4. Acquire payment lock
    final lockKey = _guard.generateLockKey(
      userId: userId,
      productId: product.productId,
      providerCode: method.name,
    );
    debugPrint('🔍 [Lock] 尝试获取锁: $lockKey');

    if (!_guard.tryAcquireLock(lockKey)) {
      debugPrint('⚠️ startPayment: locked, duplicate payment blocked');
      debugPrint('🔍 [Lock] 锁获取失败，当前锁: ${_guard.currentLockKey}');
      _emitEvent(const CheckoutUIEvent.showDuplicatePaymentWarning());
      return _currentState;
    }
    debugPrint('✅ [Lock] 锁获取成功: $lockKey');

    // Start flow tracking
    _startFlowTracking(product.productId, method.name, userId);
    _configDownloadTriggered = false;

    var resolvedExistingOrderId = existingOrderId;
    var resolvedPayProviderId = payProviderId;

    // 5. Check for unpaid orders
    if (!skipUnpaidCheck) {
      final unpaidCheckStopwatch = Stopwatch()..start();
      final unpaidDecision = await _checkAndHandleUnpaidOrder(
        userId: userId,
        productId: product.productId,
      );
      unpaidCheckStopwatch.stop();
      debugPrint(
        '⏱️ [PaymentService] unpaid order check finished in '
        '${unpaidCheckStopwatch.elapsedMilliseconds}ms '
        '(cancelled=${unpaidDecision.cancelled}, '
        'resolvedOrder=${unpaidDecision.order?.orderNum})',
      );

      if (unpaidDecision.cancelled) {
        _updateState(PaymentFlowState.cancelled(
          productId: product.productId,
          method: method,
          message: '用户取消未完成订单支付',
        ));
        _endFlowTracking();
        _guard.releaseLock();  // 🔑 修复：取消时释放锁
        debugPrint('🔓 [Lock] 用户取消未完成订单，释放锁');
        return _currentState;
      }

      if (unpaidDecision.order != null) {
        resolvedExistingOrderId = unpaidDecision.order!.orderNum;
        resolvedPayProviderId = unpaidDecision.order!.payProvider;
      }
    }

    // Save context
    _currentContext = PaymentContext(
      product: product,
      method: method,
      userId: userId,
      existingOrderId: resolvedExistingOrderId,
      extra: _buildContextExtras(
        product: product,
        method: method,
        payProviderId: resolvedPayProviderId,
        existingOrderId: resolvedExistingOrderId,
        additionalParams: additionalParams,
        skipUnpaidCheck: true,
      ),
    );

    try {
      // 6. Get and validate strategy
      final strategyResolveStopwatch = Stopwatch()..start();
      final strategy = _strategyFactory.getStrategy(method);
      strategyResolveStopwatch.stop();
      debugPrint(
        '⏱️ [PaymentService] strategy resolve finished in '
        '${strategyResolveStopwatch.elapsedMilliseconds}ms '
        '(method=${method.name}, found=${strategy != null})',
      );
      if (strategy == null) {
        final failState = PaymentFlowState.failed(
          reason: PaymentFailureReason.paymentMethodNotAvailable,
          message: 'Unsupported payment method: ${method.name}',
          productId: product.productId,
          canRetry: false,
        );
        _updateState(failState);
        return _currentState;
      }

      // Check payment method availability
      final availabilityStopwatch = Stopwatch()..start();
      final availability = await strategy.checkAvailability();
      availabilityStopwatch.stop();
      debugPrint(
        '⏱️ [PaymentService] strategy availability finished in '
        '${availabilityStopwatch.elapsedMilliseconds}ms '
        '(method=${method.name}, available=${availability.isAvailable})',
      );
      if (!availability.isAvailable) {
        final failState = availability.toFailedState()!;
        _updateState(failState);
        return _currentState;
      }

      // Update state: preparing payment
      _updateState(PaymentFlowState.preparingPayment(
        productId: product.productId,
        method: method,
        orderId: resolvedExistingOrderId,
      ));

      // 7. Execute strategy
      final executeStopwatch = Stopwatch()..start();
      final strategyResult = await strategy.execute(_currentContext!);
      executeStopwatch.stop();
      debugPrint(
        '⏱️ [PaymentService] strategy execute finished in '
        '${executeStopwatch.elapsedMilliseconds}ms '
        '(method=${method.name}, result=${strategyResult.runtimeType})',
      );

      // Check if strategy returned terminal state
      if (strategyResult.isTerminal) {
        flowStopwatch.stop();
        debugPrint(
          '⏱️ [PaymentService] startPayment reached terminal state in '
          '${flowStopwatch.elapsedMilliseconds}ms '
          '(method=${method.name}, state=${strategyResult.runtimeType})',
        );
        return await _handlePaymentResult(strategyResult);
      }

      // 8. Start monitoring if payment is processing
      if (strategyResult is PaymentFlowProcessing) {
        final monitorStopwatch = Stopwatch()..start();
        final monitorResult = await _paymentMonitor.startMonitoring(
          userId: userId,
          productId: product.productId,
          providerCode: method.name,
          orderId: strategyResult.orderId,
        );
        monitorStopwatch.stop();
        flowStopwatch.stop();
        debugPrint(
          '⏱️ [PaymentService] payment monitor finished in '
          '${monitorStopwatch.elapsedMilliseconds}ms '
          '(total=${flowStopwatch.elapsedMilliseconds}ms, '
          'status=${monitorResult.status}, orderId=${strategyResult.orderId})',
        );

        // Convert monitor result to flow state
        final finalState = _monitorResultToFlowState(monitorResult, product, method);
        return await _handlePaymentResult(finalState);
      }

      // Handle result
      flowStopwatch.stop();
      debugPrint(
        '⏱️ [PaymentService] startPayment finished in '
        '${flowStopwatch.elapsedMilliseconds}ms '
        '(method=${method.name}, state=${strategyResult.runtimeType})',
      );
      return await _handlePaymentResult(strategyResult);
    } catch (e) {
      debugPrint('❌ startPayment exception: $e');
      flowStopwatch.stop();
      debugPrint(
        '⏱️ [PaymentService] startPayment failed after '
        '${flowStopwatch.elapsedMilliseconds}ms '
        '(method=${method.name}, error=$e)',
      );

      final failState = PaymentFlowState.failed(
        reason: PaymentFailureReason.unknown,
        message: 'Payment error: $e',
        productId: product.productId,
        method: method,
        canRetry: true,
      );
      _updateState(failState);
      _endFlowTracking();
      return _currentState;
    } finally {
      // 9. Release lock
      debugPrint('🔓 [Lock] finally 块释放锁');
      _guard.releaseLock();
    }
  }

  Map<String, dynamic> _buildContextExtras({
    required ProductInfo product,
    required PayProvider method,
    int? payProviderId,
    String? existingOrderId,
    Map<String, dynamic>? additionalParams,
    bool skipUnpaidCheck = false,
  }) {
    final extras = <String, dynamic>{};

    if (product.extra != null) {
      extras.addAll(product.extra!);
    }

    if (additionalParams != null) {
      extras.addAll(additionalParams);
    }

    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

    extras.addAll({
      'product_id': product.productId,
      'product_code': product.productId,
      'product_name': product.title,
      'purchaseType': product.type,
      'payProviderId': payProviderId,
      'amount': product.price,
      'currency': product.currency,
      'description': product.description,
      'subject': product.title,
      'platform': platform,
      'clientType': 'mobile',
      'flowId': _currentFlowId,
      'method': method.name,
      'skipUnpaidCheck': skipUnpaidCheck,
      if (existingOrderId != null) 'orderNum': existingOrderId,
    });

    return extras;
  }

  int? _currentPayProviderId() {
    final value = _currentContext?.extra['payProviderId'];
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  /// Pay existing unpaid order
  Future<PaymentFlowState> payExistingOrder({
    required OrderEntry order,
    required PayProvider method,
    required String userId,
  }) async {
    debugPrint('💳 payExistingOrder: ${order.orderNum}');

    // Convert order to product info
    final product = ProductInfo(
      id: order.productId ?? 0,
      productId: order.storeProductId ?? '',
      priceId: '',
      title: order.productName ?? '',
      description: '',
      price: order.total,
      currency: order.currency ?? 'USD',
      formattedPrice: '${order.currency ?? '\$'}${order.total}',
      type: ProductType.subscription.value,
      durationDays: 30,
    );

    return startPayment(
      product: product,
      method: method,
      userId: userId,
      existingOrderId: order.orderNum,
      payProviderId: order.payProvider,
      skipUnpaidCheck: true,
    );
  }

  /// Convert monitor result to flow state
  PaymentFlowState _monitorResultToFlowState(
    PaymentMonitorResult result,
    ProductInfo product,
    PayProvider method,
  ) {
    switch (result.status) {
      case PaymentMonitorStatus.success:
        return PaymentFlowState.success(
          orderId: result.orderId ?? '',
          productId: product.productId,
          method: method,
        );
      case PaymentMonitorStatus.failed:
        return PaymentFlowState.failed(
          reason: PaymentFailureReason.paymentFailed,
          message: result.error ?? 'Payment failed',
          productId: product.productId,
          method: method,
          canRetry: true,
        );
      case PaymentMonitorStatus.cancelled:
        return PaymentFlowState.cancelled(
          productId: product.productId,
          method: method,
          message: 'Payment cancelled',
        );
      case PaymentMonitorStatus.timeout:
        return PaymentFlowState.timeout(
          productId: product.productId,
          method: method,
          message: 'Payment verification timeout',
        );
    }
  }

  /// Check and handle unpaid order
  Future<_UnpaidOrderDecision> _checkAndHandleUnpaidOrder({
    required String userId,
    required String productId,
  }) async {
    try {
      final normalizedUserId = userId.trim();
      if (normalizedUserId.isEmpty) {
        return const _UnpaidOrderDecision.none();
      }
      debugPrint('🔎 Unpaid check: sessionUserId=$normalizedUserId, productId=$productId');
      final unpaidOrder = await _orderSyncService.checkUnpaidOrder(
        userId: normalizedUserId,
        productId: productId,
      );

      if (unpaidOrder != null) {
        debugPrint(
          '🔎 Unpaid order found: orderNum=${unpaidOrder.orderNum}, orderUserId=${unpaidOrder.userId}, '
          'productId=${unpaidOrder.productId}, storeProductId=${unpaidOrder.storeProductId}',
        );
        if (unpaidOrder.userId.trim() != normalizedUserId) {
          debugPrint('⚠️ Unpaid order user mismatch: ${unpaidOrder.userId} != $normalizedUserId');
          return const _UnpaidOrderDecision.none();
        }
        debugPrint('📦 Found unpaid order: ${unpaidOrder.orderNum}');
        _updateState(PaymentFlowState.hasUnpaidOrder(
          orderId: unpaidOrder.orderNum,
          productId: unpaidOrder.productId,
          productName: unpaidOrder.productName ?? 'Unknown',
          amount: unpaidOrder.total,
          currency: unpaidOrder.currency ?? 'USD',
        ));

        final callbackId = 'unpaid_order_${unpaidOrder.orderNum}';
        // Emit UI event to show unpaid order dialog
        _emitEvent(CheckoutUIEvent.showUnpaidOrderDialog(
          orderId: unpaidOrder.orderNum,
          productId: unpaidOrder.productId,
          productName: unpaidOrder.productName ?? 'Unknown',
          amount: unpaidOrder.total,
          currency: unpaidOrder.currency ?? 'USD',
          callbackId: callbackId,
        ));

        final result = await waitForUICallback(callbackId)
            .timeout(const Duration(seconds: 30), onTimeout: () {
          _pendingCallbacks.remove(callbackId);
          return UIEventCallbackResult(
            callbackId: callbackId,
            confirmed: false,
            data: const {'action': 'timeout'},
          );
        });

        if (result.confirmed && result.data?['action'] == 'continue') {
          return _UnpaidOrderDecision.proceed(unpaidOrder);
        }

        return const _UnpaidOrderDecision.cancelled();
      }
    } catch (e) {
      debugPrint('⚠️ Check unpaid order failed: $e');
    }
    return const _UnpaidOrderDecision.none();
  }

  /// Handle payment result
  ///
  /// 业务逻辑层处理支付结果：
  /// - 刷新会话
  /// - 断开连接（如果需要）
  /// - 触发订单恢复
  /// - 发出 UI 事件
  Future<PaymentFlowState> _handlePaymentResult(PaymentFlowState result) async {
    _updateState(result);

    if (_currentFlowId == null) {
      debugPrint('⏭️ Flow already ended, skipping business logic in _handlePaymentResult');
      return result;
    }

    // Handle side effects based on result type
    switch (result) {
      case PaymentFlowSuccess(:final orderId):
        // 🎯 业务逻辑：支付成功后的完整处理流程
        await _handlePaymentSuccessBusinessLogic(orderId);
        _endFlowTracking();
        break;

      case PaymentFlowFailed():
        // Trigger order recovery in case of partial payment
        unawaited(_triggerOrderRecovery('payment_failed'));
        _endFlowTracking();
        break;

      case PaymentFlowCancelled():
        debugPrint('ℹ️ Payment cancelled by user');
        // Sync order state after cancellation
        if (_currentContext != null && _currentContext!.userId != null) {
          unawaited(_syncAfterCancellation(
            userId: _currentContext!.userId!,
            productId: _currentContext!.product.productId,
          ));
        }
        _endFlowTracking();
        break;

      case PaymentFlowTimeout():
        // Trigger order recovery on timeout
        unawaited(_triggerOrderRecovery('payment_timeout'));
        _emitEvent(const CheckoutUIEvent.hidePaymentProcessingDialog());
        _endFlowTracking();
        break;

      case PaymentFlowRequiresAction(:final action):
        _handleRequiresAction(action);
        break;

      case PaymentFlowHasUnpaidOrder(
          :final orderId,
          :final productId,
          :final productName,
          :final amount,
          :final currency
        ):
        _handleUnpaidOrder(orderId, productId, productName, amount, currency);
        break;

      default:
        break;
    }

    return result;
  }

  /// 🎯 支付成功后的业务逻辑处理
  ///
  /// 职责：
  /// 1. 触发订单恢复同步
  /// 2. 刷新会话获取最新 VIP 状态
  /// 3. 触发配置下载
  /// 4. 断开当前连接（准备更新配置）
  /// 5. 发出事件通知 UI 层执行导航
  Future<void> _handlePaymentSuccessBusinessLogic(String? orderId) async {
    debugPrint('🎯 [Business] 开始执行支付成功业务逻辑, orderId=$orderId');
    debugPrint('🎯 [Business] _configDownloadTriggered=$_configDownloadTriggered, _currentFlowId=$_currentFlowId');

    // 1. 触发订单恢复
    debugPrint('🎯 [Business] Step 1: 触发订单恢复');
    await _triggerOrderRecovery('payment_success');

    // 2. 刷新会话获取最新 VIP 状态
    debugPrint('🎯 [Business] Step 2: 刷新会话');
    await _refreshSession();

    // 3. 触发配置下载（与微信支付流程保持一致）
    debugPrint('🎯 [Business] Step 3: 检查配置下载, _configDownloadTriggered=$_configDownloadTriggered');
    if (!_configDownloadTriggered) {
      _configDownloadTriggered = true;
      debugPrint('🎯 [Business] Step 3: 发送 triggerConfigDownload 事件');
      _emitEvent(CheckoutUIEvent.triggerConfigDownload(
        orderId: orderId,
        redirectTo: const NavMainHomeRoute().location,
      ));
    } else {
      debugPrint('⚠️ [Business] Step 3: 配置下载已触发过，跳过');
    }

    // 4. 断开当前连接（如果已连接），准备更新 VIP 配置
    debugPrint('🎯 [Business] Step 4: 断开连接');
    await _disconnectIfNeeded();

    // 5. 发出成功事件，通知 UI 层执行导航
    debugPrint('🎯 [Business] Step 5: 发送 onPaymentSuccess 事件');
    _emitEvent(CheckoutUIEvent.onPaymentSuccess(
      orderId: orderId,
      redirectTo: const NavMainHomeRoute().location,
    ));

    debugPrint('🎯 [Business] 支付成功业务逻辑执行完毕');
  }

  Future<void> _handleRestoreBusinessLogic({
    required bool hasRestoredPurchases,
  }) async {
    if (hasRestoredPurchases) {
      await _triggerOrderRecovery('restore_purchases');
    }
    await _refreshSession();
    await _disconnectIfNeeded();
    _emitEvent(CheckoutUIEvent.onPaymentSuccess(
      orderId: null,
      redirectTo: const NavMainHomeRoute().location,
    ));
  }

  /// 🎯 从服务器刷新会话以获取最新用户信息（VIP状态等）
  Future<void> _refreshSession() async {
    try {
      final authManager = await _ref.read(authManagerProvider.future);
      debugPrint('PaymentService _refreshSession - 准备刷新会话 & 用户信息');
      // 支付成功后必须立即拉取最新 VIP 状态，绕过 5 秒节流窗口
      final refreshedUser = await authManager.refreshUserData(force: true);
      if (refreshedUser != null) {
        debugPrint('刷新的refreshedUser=$refreshedUser');
        // 刷新成功后，invalidate providers 以触发 UI 更新
        _ref.invalidate(currentUserProvider);
        _ref.invalidate(userInfoProvider);
        debugPrint('✅ 会话刷新成功，用户信息已更新');
      } else {
        debugPrint('⚠️ 会话刷新失败，已回退到缓存');
      }
    } catch (e) {
      debugPrint('❌ 刷新会话异常: $e');
    }
  }

  /// 断开当前连接（如果已连接）— VPN module removed, no-op
  Future<void> _disconnectIfNeeded() async {
    // VPN connection module removed — nothing to disconnect
    debugPrint('ℹ️ _disconnectIfNeeded: VPN module removed, skipping');
  }

  /// Handle cases requiring user action
  void _handleRequiresAction(PaymentActionRequired action) {
    switch (action) {
      case PaymentActionRequired.login:
        _emitEvent(const CheckoutUIEvent.navigateToLogin());
        break;

      case PaymentActionRequired.handleUnpaidOrder:
        // Handled by PaymentFlowHasUnpaidOrder branch
        break;

      default:
        debugPrint('⚠️ User action required: $action');
        break;
    }
  }

  /// Handle unpaid order dialog
  void _handleUnpaidOrder(
    String orderId,
    int productId,
    String productName,
    double amount,
    String currency,
  ) {
    final callbackId = 'unpaid_order_$orderId';

    _emitEvent(CheckoutUIEvent.showUnpaidOrderDialog(
      orderId: orderId,
      productId: productId,
      productName: productName,
      amount: amount,
      currency: currency,
      callbackId: callbackId,
    ));
  }

  /// Cancel current payment
  Future<void> cancelPayment() async {
    if (!_guard.isLocked) return;

    final orderId = _currentState.orderId;

    // Stop monitoring
    await _stopMonitoring();
    await _cancelPendingPayment(reason: 'user_cancelled');

    _updateState(PaymentFlowState.cancelled(
      orderId: orderId,
      productId: _currentContext?.product.productId,
      message: 'Payment cancelled by user',
    ));

    // Sync order state
    if (_currentContext != null && _currentContext!.userId != null) {
      await _syncAfterCancellation(
        userId: _currentContext!.userId!,
        productId: _currentContext!.product.productId,
      );
    }

    // Release lock
    _guard.releaseLock();
    _currentContext = null;
    _endFlowTracking();
  }

  /// Retry payment
  Future<PaymentFlowState> retryPayment() async {
    if (_currentContext == null) {
      return const PaymentFlowState.failed(
        reason: PaymentFailureReason.unknown,
        message: 'No payment to retry',
        canRetry: false,
      );
    }

    // Get the last used payment method
    final lastMethod = switch (_currentState) {
      PaymentFlowFailed(:final method) => method,
      PaymentFlowCancelled(:final method) => method,
      PaymentFlowTimeout(:final method) => method,
      _ => null,
    };

    if (lastMethod == null) {
      return const PaymentFlowState.failed(
        reason: PaymentFailureReason.unknown,
        message: 'Cannot determine payment method',
        canRetry: false,
      );
    }

    return startPayment(
      product: _currentContext!.product,
      method: lastMethod,
      userId: _currentContext!.userId,
      existingOrderId: _currentContext!.existingOrderId,
      payProviderId: _currentPayProviderId(),
    );
  }

  // ========== UI Callback Handling ==========

  /// Handle UI callback result
  void handleUICallback(UIEventCallbackResult result) {
    final completer = _pendingCallbacks.remove(result.callbackId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  /// Wait for UI callback
  Future<UIEventCallbackResult> waitForUICallback(String callbackId) {
    final completer = Completer<UIEventCallbackResult>();
    _pendingCallbacks[callbackId] = completer;
    return completer.future;
  }

  // ========== Helper Methods ==========

  /// Get available payment methods
  Future<List<PayProvider>> getAvailableMethods() async {
    return await _paymentManager.getAvailableMethods();
  }

  /// Filter pay providers by availability
  Future<List<PayProviderEntry>> filterAvailableProviders(
    List<PayProviderEntry> providers,
  ) async {
    final filteredProviders = <PayProviderEntry>[];

    for (final p in providers) {
      final method = PayProviderExtension.fromCode(p.code);
      if (method == null) continue;

      final provider = _paymentManager.getProvider(method);
      if (provider == null) continue;

      try {
        final available = await provider.isAvailable();
        if (available) filteredProviders.add(p);
      } catch (_) {
        // Skip unavailable providers
      }
    }

    return filteredProviders;
  }

  /// Check if a specific payment method is available
  Future<bool> isMethodAvailable(PayProvider method) async {
    final strategy = _strategyFactory.getStrategy(method);
    if (strategy == null) return false;

    final availability = await strategy.checkAvailability();
    return availability.isAvailable;
  }

  /// 检查支付网关连通性
  ///
  /// 返回不可达的网关名称，如果可达则返回 null
  Future<String?> checkGatewayReachability(PayProvider method) async {
    final provider = _paymentManager.getProvider(method);
    if (provider == null) return null;

    try {
      return await provider.checkGatewayReachability();
    } catch (e) {
      debugPrint('⚠️ checkGatewayReachability error: $e');
      return null;
    }
  }

  /// 预取 IAP 商品详情，减少点击支付时的实时查询。
  Future<void> prefetchIapProducts(Iterable<String> productIds) async {
    final ids = productIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) {
      debugPrint('ℹ️ [PaymentService] prefetchIapProducts skipped (empty ids)');
      return;
    }

    final stopwatch = Stopwatch()..start();
    try {
      final provider = _paymentManager.getProvider(PayProvider.inAppPurchase);
      if (provider is! InAppPurchaseProvider) {
        stopwatch.stop();
        debugPrint(
          '⚠️ [PaymentService] prefetchIapProducts skipped '
          '(provider=$provider, ids=$ids)',
        );
        return;
      }

      await provider.prefetchProducts(ids);
      stopwatch.stop();
      debugPrint(
        '⏱️ [PaymentService] prefetchIapProducts finished in '
        '${stopwatch.elapsedMilliseconds}ms '
        '(count=${ids.length}, ids=$ids)',
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint(
        '⏱️ [PaymentService] prefetchIapProducts failed after '
        '${stopwatch.elapsedMilliseconds}ms '
        '(count=${ids.length}, ids=$ids, error=$e)',
      );
    }
  }

  /// Restore purchases
  ///
  /// Used to restore Apple App Store purchase records
  /// Returns true if restoration was successful
  Future<bool> restorePurchases() async {
    debugPrint('🔄 Starting purchase restoration');

    try {
      // Get in-app purchase provider to restore purchases
      final inAppProvider = _paymentManager.getProvider(PayProvider.inAppPurchase);

      if (inAppProvider != null) {
        // Call restore through the provider's query method with restore action
        await inAppProvider.query(GenericPaymentParams({'action': 'restore'}));
      }

      await _handleRestoreBusinessLogic(hasRestoredPurchases: true);

      debugPrint('✅ Purchase restoration complete');
      return true;
    } catch (e) {
      debugPrint('❌ Purchase restoration failed: $e');
      rethrow;
    }
  }

  /// 完成外部恢复流程（PendingPurchaseHandler 已处理完）
  Future<void> handleRestoreCompletion({
    required bool hasRestoredPurchases,
  }) async {
    await _handleRestoreBusinessLogic(hasRestoredPurchases: hasRestoredPurchases);
  }

  // ========== Flow Tracking ==========

  void _startFlowTracking(String? productId, String? providerCode, String? userId) {
    _flowStartMs = DateTime.now().millisecondsSinceEpoch;
    final base = productId?.isNotEmpty == true
        ? productId!
        : (providerCode?.isNotEmpty == true ? providerCode! : 'payment');
    _currentFlowId = '$base-$_flowStartMs';
    _activeFlowId = _currentFlowId;
    _activeUserId = userId;
    _activeProductId = productId;
    debugPrint('[flow $_currentFlowId] 🔄 Payment flow started, productId=$productId');
  }

  void _endFlowTracking() {
    if (_currentFlowId != null) {
      debugPrint('[flow $_currentFlowId] ✅ Payment flow ended');
    }
    _currentFlowId = null;
    _flowStartMs = null;
    _activeFlowId = null;
    _activeUserId = null;
    _activeProductId = null;
  }

  // ========== Private Methods ==========

  /// Update state
  void _updateState(PaymentFlowState newState) {
    _currentState = newState;
    _stateController.add(newState);

    // Also emit state update event
    _emitEvent(CheckoutUIEvent.updateFlowState(state: newState));
  }

  /// Emit UI event
  void _emitEvent(CheckoutUIEvent event) {
    debugPrint('📤 UI event: ${event.eventName}');
    _eventController.add(event);
  }

  bool _shouldHandlePaymentEvent(PaymentEvent event) {
    if (_activeFlowId == null) {
      return false;
    }

    final data = _asEventDataMap(event.data);

    // 🔑 优先检查 productId（来自 SDK 原始数据，最可靠）
    // 解决场景：点击A取消→点击B支付，A的延迟取消事件会携带A的productId
    final eventProductId = data?['productId']?.toString();
    if (eventProductId != null &&
        _activeProductId != null &&
        eventProductId != _activeProductId) {
      debugPrint('⏭️ 跳过其他产品的事件: event=$eventProductId, active=$_activeProductId');
      return false;
    }

    // 检查 flowId（来自 pendingContext，可能被覆盖）
    final eventFlowId = data?['flowId']?.toString();
    if (eventFlowId != null &&
        _activeFlowId != null &&
        eventFlowId != _activeFlowId) {
      return false;
    }

    // 检查 userId
    final eventUserId = data?['userId']?.toString();
    if (eventUserId != null &&
        _activeUserId != null &&
        eventUserId != _activeUserId) {
      return false;
    }

    return true;
  }

  Map<String, dynamic>? _asEventDataMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Future<void> _triggerOrderRecovery(String reason) async {
    try {
      await _orderSyncService.triggerOrderRecovery(reason: reason);
    } catch (e) {
      debugPrint('⚠️ Order recovery failed ($reason): $e');
    }
  }

  Future<void> _cancelPendingPayment({String? reason}) async {
    final context = _currentContext;
    if (context == null) {
      return;
    }

    try {
      _paymentManager.setPaymentMethod(context.method);
      final paramsMap = Map<String, dynamic>.from(context.toParamsMap());
      if (reason != null) {
        paramsMap['reason'] = reason;
      }
      final response = await _paymentManager.cancelorder(
        GenericPaymentParams(paramsMap),
      );
      if (!response.success) {
        debugPrint('⚠️ Cancel pending payment failed: ${response.message}');
      }
    } catch (e) {
      debugPrint('⚠️ Cancel pending payment exception: $e');
    }
  }

  Future<void> _ensureOrderScope(String userId) async {
    if (_lastUserId != null && _lastUserId != userId) {
      try {
        final orderService = _ref.read(AppProvider.orders.service);
        await orderService.deleteOrdersByUserId(_lastUserId!);
        debugPrint('🧹 Cleared orders for previous user: $_lastUserId');
      } catch (e) {
        debugPrint('⚠️ Failed to clear previous user orders: $e');
      }
    }
    _lastUserId = userId;
  }

  Future<void> _syncAfterCancellation({
    required String userId,
    required String? productId,
  }) async {
    try {
      await _orderSyncService.syncAfterCancellation(
        userId: userId,
        productId: productId,
      );
    } catch (e) {
      debugPrint('⚠️ Sync after cancellation failed: $e');
    }
  }

  Future<void> _stopMonitoring() async {
    try {
      await _paymentMonitor.stopMonitoring();
    } catch (e) {
      debugPrint('⚠️ Stop monitoring failed: $e');
    }
  }

  /// Release resources
  void dispose() {
    _paymentEventSubscription?.cancel();
    _paymentEventSubscription = null;
    _stateController.close();
    _eventController.close();
    _pendingCallbacks.clear();
    _handledOrphanPurchaseIds.clear();
    _strategyFactory.clearCache();
    _guard.forceCleanup();
    debugPrint('✅ PaymentService disposed');
  }
}

class _UnpaidOrderDecision {
  final OrderEntry? order;
  final bool cancelled;

  const _UnpaidOrderDecision._({
    required this.order,
    required this.cancelled,
  });

  const _UnpaidOrderDecision.none() : this._(order: null, cancelled: false);

  const _UnpaidOrderDecision.cancelled() : this._(order: null, cancelled: true);

  const _UnpaidOrderDecision.proceed(OrderEntry order)
      : this._(order: order, cancelled: false);
}
