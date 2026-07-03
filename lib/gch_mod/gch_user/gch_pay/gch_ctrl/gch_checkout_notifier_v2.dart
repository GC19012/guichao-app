import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:go_router/go_router.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_base/gch_nav/gch_nav_engine.dart' show gchRootNavKey;
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_pending_purchase_handler.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_widget/gch_payment_result_dialog.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_model/gch_product_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_repo/gch_product_repository.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_providers/gch_product_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_providers/gch_payprovider_providers.dart';

import 'package:guichao/gch_mod/gch_user/gch_pay/gch_svc/gch_payment_service.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_domain.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_widget/gch_unpaid_dialog.dart';
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';

part 'gch_checkout_notifier_v2.freezed.dart';
part 'gch_checkout_notifier_v2.g.dart';

/// 结账状态 V2 - 简化版
@freezed
abstract class CheckoutStateV2 with _$CheckoutStateV2 {
  const factory CheckoutStateV2({
    // 数据
    @Default([]) List<ProductEntry> products,
    ProductEntry? selectedProduct,
    @Default([]) List<PayProviderEntry> availablePayProviders,
    PayProviderEntry? selectedPayProvider,

    // 加载状态
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingProducts,
    @Default(false) bool isLoadingPayProviders,
    @Default(false) bool isProcessingPayment,
    @Default(false) bool isRestoring,

    // 支付流程状态（来自 PaymentService）
    @Default(PaymentFlowState.idle()) PaymentFlowState flowState,

    // 错误
    String? errorMessage,
    String? paymentTimeoutMessage,
  }) = _CheckoutStateV2;
}

/// CheckoutStateV2 扩展
extension CheckoutStateV2X on CheckoutStateV2 {
  /// 是否正在处理（兼容旧接口）
  /// 同时检查 flowState，避免微信等支付回调丢失时按钮一直旋转
  bool get isProcessing => isProcessingPayment && !flowState.canStartPayment;

  /// 是否可以支付
  bool get canPay =>
      selectedProduct != null &&
      selectedPayProvider != null &&
      !isProcessingPayment &&
      !isRestoring &&
      flowState.canStartPayment;

  /// 支付按钮文案
  String buttonLabel() {
    if (isProcessingPayment) return GchText.userPayStatusCancelPayment;
    if (selectedProduct == null) return GchText.userPayValidationSelectProduct;
    if (selectedPayProvider == null) return GchText.userPayValidationSelectPaymentMethod;

    return switch (flowState) {
      PaymentFlowFailed(canRetry: true) => GchText.userPayStatusRetryPayment,
      PaymentFlowTimeout() => GchText.userPayStatusRetryPayment,
      PaymentFlowCancelled() => GchText.userPayConfirmPay,
      _ => GchText.userPayConfirmPay,
    };
  }
}

/// 结账页面 Notifier V2 - 纯 UI 层
///
/// 设计原则：
/// 1. 只负责 UI 状态管理，不包含业务逻辑
/// 2. 业务逻辑委托给 PaymentService
/// 3. 通过事件流处理 UI 交互（导航、弹窗等）
/// 4. 🎯 完全不持有 BuildContext，通过 GlobalNavigatorKey 处理 UI 操作
/// 5. 约 280 行代码（原版 2200+ 行）
@riverpod
class CheckoutNotifierV2 extends _$CheckoutNotifierV2 {
  PaymentService? _paymentService;
  StreamSubscription<PaymentFlowState>? _stateSubscription;
  StreamSubscription<CheckoutUIEvent>? _eventSubscription;
  DateTime? _lastPaymentTapTime;
  static const _tapDebounceDuration = Duration(milliseconds: 200);
  bool _disposed = false;

  @override
  CheckoutStateV2 build() {
    // 初始化
    Future.microtask(_initialize);

    // 清理
    ref.onDispose(_dispose);

    return const CheckoutStateV2();
  }

  // ========== 初始化 ==========

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    GchUmengSvc.onCheckoutOpen();

    try {
      // 获取 PaymentService
      _paymentService = ref.read(paymentServiceProvider);

      // 监听状态流
      _stateSubscription = _paymentService!.stateStream.listen(_onFlowStateChanged);

      // 监听事件流 - 🎯 PaymentService 已订阅 PaymentEventBus 并转发为 UI 事件
      _eventSubscription = _paymentService!.eventStream.listen(_onUIEvent);

      // 初始化 PaymentService
      await _paymentService!.initialize();

      // 进入购买页时刷新用户状态，确保 VIP/到期时间最新
      _refreshUserStatus();

      // 加载数据
      await Future.wait([
        _loadProducts(),
        _loadPayProviders(),
      ]);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('❌ CheckoutNotifierV2 initialize failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: GchText.userPayErrorsGeneralError,
      );
    }
  }

  void _dispose() {
    _disposed = true;
    _stateSubscription?.cancel();
    _eventSubscription?.cancel();
  }

  /// 后台刷新用户状态（不阻塞页面加载）
  void _refreshUserStatus() {
    ref.read(authManagerProvider.future).then((authManager) {
      authManager.refreshUserData(force: true);
    }).catchError((e) {
      debugPrint('CheckoutNotifierV2 _refreshUserStatus error: $e');
    });
  }

  // ========== 数据加载 ==========

  Future<void> _loadProducts() async {
    state = state.copyWith(isLoadingProducts: true);

    var hasQuickData = false;

    // 1) 先读 ProductCache（内存快路径）
    final cache = ref.read(productCacheProvider);
    final cachedProducts = cache.all.values.toList();
    if (cachedProducts.isNotEmpty) {
      _applyProducts(cachedProducts, source: 'cache');
      hasQuickData = true;
    } else {
      // 2) 回退：从本地数据库读取（不触发网络）
      try {
        final productService = ref.read(productServiceProvider);
        final dbProducts = await productService.watchProducts().first;
        if (dbProducts.isNotEmpty) {
          _applyProducts(dbProducts, source: 'db');
          hasQuickData = true;
        }
      } catch (e) {
        debugPrint('⚠️ _loadProducts db fallback failed: $e');
      }
    }

    // 3) 后台刷新：服务端优先路径
    unawaited(_refreshProductsFromNetwork(hasQuickData: hasQuickData));
  }

  Future<void> _refreshProductsFromNetwork({required bool hasQuickData}) async {
    try {
      final repository = ref.read(productRepositoryProvider);
      if (repository is ProductRepository) {
        repository.clearCache();
      }
      final products = await ref.refresh(productsProvider.future);
      _applyProducts(products, source: 'network');
    } catch (e) {
      debugPrint('❌ _loadProducts refresh failed: $e');
      if (!hasQuickData) {
        state = state.copyWith(
          errorMessage: GchText.userPayErrorsProductError,
          isLoadingProducts: false,
        );
      }
    }
  }

  void _applyProducts(List<ProductEntry> products, {required String source}) {
    // 客户端侧平台过滤：防止缓存/DB 中混入其他平台的旧数据
    final filtered = _filterByCurrentPlatform(products);
    debugPrint('📱 Products platform filter: ${products.length} → ${filtered.length} ($source)');
    _logLoadedProducts(products, source: source, stage: 'raw');
    _logLoadedProducts(filtered, source: source, stage: 'filtered');

    final currentSelectedId = state.selectedProduct?.productId;
    ProductEntry? selected;
    if (currentSelectedId != null) {
      for (final product in filtered) {
        if (product.productId == currentSelectedId) {
          selected = product;
          break;
        }
      }
    }
    selected ??= filtered.isNotEmpty ? filtered.first : null;

    state = state.copyWith(
      products: filtered,
      selectedProduct: selected,
      isLoadingProducts: false,
    );
    debugPrint('✅ Products loaded ($source): ${filtered.length}');
    _prefetchIapProducts(filtered);
  }

  String? _storeSku(ProductEntry product) {
    final productSku = product.productId.trim();
    if (productSku.isNotEmpty) {
      debugPrint(
        '🧾 [CheckoutUI] resolved store SKU from productId '
        '(business=${product.productId}, sku=$productSku)',
      );
      return productSku;
    }

    final fallbackSku = product.priceId?.trim();
    if (fallbackSku != null && fallbackSku.isNotEmpty) {
      debugPrint(
        '🧾 [CheckoutUI] resolved store SKU from priceId fallback '
        '(business=${product.productId}, sku=$fallbackSku)',
      );
      return fallbackSku;
    }

    debugPrint(
      'ℹ️ [CheckoutUI] skip store SKU resolve '
      '(business=${product.productId}, productId=${product.productId}, priceId=${product.priceId})',
    );
    return null;
  }

  void _prefetchIapProducts(List<ProductEntry> products) {
    final service = _paymentService;
    if (service == null || products.isEmpty) return;

    final skuMap = <String, String>{};
    for (final product in products) {
      final sku = _storeSku(product);
      if (sku != null) {
        skuMap[product.productId] = sku;
      }
    }

    if (skuMap.isEmpty) {
      debugPrint('ℹ️ [CheckoutUI] no store SKUs available for IAP prefetch');
      return;
    }

    debugPrint('🔄 [CheckoutUI] prefetch IAP SKUs: $skuMap');
    unawaited(service.prefetchIapProducts(skuMap.values));
  }

  void _logLoadedProducts(
    List<ProductEntry> products, {
    required String source,
    required String stage,
  }) {
    debugPrint('🧾 Purchase products [$source][$stage] count=${products.length}');
    if (products.isEmpty) {
      debugPrint('🧾 Purchase products [$source][$stage] is empty');
      return;
    }

    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      debugPrint('''
🧾 Purchase product[$i] [$source][$stage]
  id=${product.id}
  productId=${product.productId}
  title=${product.title}
  description=${product.description}
  price=${product.price}
  priceFormatted=${product.priceFormatted}
  currency=${product.currency}
  platform=${product.platform}
  type=${product.type}
  duration=${product.duration}
  priceId=${product.priceId}
  title2=${product.title2}
  title3=${product.title3}
  description2=${product.description2}
  description3=${product.description3}
  promoinfo1=${product.promoinfo1}
  promoinfo2=${product.promoinfo2}
  visible=${product.visible}
''');
    }
  }

  List<ProductEntry> _filterByCurrentPlatform(List<ProductEntry> products) {
    return products.where((p) => p.platform == ProductPlatform.ios.value).toList();
  }

  Future<void> _loadPayProviders() async {
    state = state.copyWith(isLoadingPayProviders: true);
    try {
      final allProviders = await ref.read(currentPayProvidersProvider.future);

      // Filter providers using PaymentService
      final filteredProviders = await _paymentService?.filterAvailableProviders(allProviders)
          ?? allProviders;

      state = state.copyWith(
        availablePayProviders: filteredProviders,
        selectedPayProvider: filteredProviders.isNotEmpty ? filteredProviders.first : null,
        isLoadingPayProviders: false,
      );
    } catch (e) {
      debugPrint('❌ _loadPayProviders failed: $e');
      state = state.copyWith(
        errorMessage: GchText.userPayErrorsPaymentError,
        isLoadingPayProviders: false,
      );
    }
  }

  // ========== UI 操作 ==========

  /// 选择商品
  void selectProduct(ProductEntry product) {
    GchUmengSvc.onProductSelect(
      product.productId,
      price: product.price,
      currency: product.currency,
    );
    // 🔑 仅当 flowState 是 alreadyOwned 时重置，允许用户购买其他产品
    // 其他失败状态（paymentFailed、cancelled 等）不受影响
    PaymentFlowState newFlowState = state.flowState;
    if (state.flowState case PaymentFlowFailed(reason: PaymentFailureReason.alreadyOwned)) {
      newFlowState = const PaymentFlowState.idle();
      debugPrint('🔄 [Select] 重置 alreadyOwned 状态，允许购买: ${product.productId}');
    }

    state = state.copyWith(
      selectedProduct: product,
      flowState: newFlowState,
    );
    _prefetchIapProducts([product]);
  }

  /// 选择支付方式
  void selectPayProvider(PayProviderEntry provider) {
    state = state.copyWith(selectedPayProvider: provider);
  }

  /// 处理支付按钮点击
  ///
  /// 🎯 不保存 BuildContext，所有 UI 操作通过事件流处理
  Future<void> handlePaymentTap(BuildContext context) async {
    debugPrint('🔘 [Tap] handlePaymentTap 被调用');
    debugPrint('🔘 [Tap] isProcessingPayment=${state.isProcessingPayment}, canPay=${state.canPay}');
    debugPrint('🔘 [Tap] flowState=${state.flowState}, canStartPayment=${state.flowState.canStartPayment}');

    if (!state.isProcessingPayment && !_consumePaymentTap()) {
      debugPrint('⚠️ [Tap] 被防抖拦截');
      return;
    }

    if (state.isProcessingPayment) {
      debugPrint('🔘 [Tap] 正在处理中，调用取消支付');
      await cancelPayment();
      return;
    }

    if (!state.canPay) {
      debugPrint('⚠️ [Tap] canPay=false，无法支付');
      debugPrint('   selectedProduct=${state.selectedProduct != null}');
      debugPrint('   selectedPayProvider=${state.selectedPayProvider != null}');
      debugPrint('   isProcessingPayment=${state.isProcessingPayment}');
      debugPrint('   isRestoring=${state.isRestoring}');
      debugPrint('   flowState.canStartPayment=${state.flowState.canStartPayment}');

      // 🔑 特殊处理：alreadyOwned 状态不应阻止购买其他产品
      final flowState = state.flowState;
      if (flowState is PaymentFlowFailed &&
          flowState.reason == PaymentFailureReason.alreadyOwned &&
          state.selectedProduct != null &&
          state.selectedPayProvider != null) {
        // 重置状态，允许购买其他产品（不 return，继续执行支付流程）
        state = state.copyWith(flowState: const PaymentFlowState.idle());
        debugPrint('🔄 [Tap] 重置 alreadyOwned 状态，继续执行支付');
        // 不 return，继续往下执行
      } else {
        return;
      }
    }

    final product = state.selectedProduct!;
    final provider = state.selectedPayProvider!;

    // 获取用户
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      const NavLoginRoute().go(context);
      return;
    }

    // 转换支付方式
    final method = PayProviderExtension.fromCode(provider.code);
    if (method == null) {
      _showError(GchText.userPayErrorsPaymentError);
      return;
    }

    final paymentLaunchStopwatch = Stopwatch()..start();

    // 🌐 检查支付网关连通性
    final gatewayCheckStopwatch = Stopwatch()..start();
    final unreachableGateway = await _paymentService?.checkGatewayReachability(method);
    gatewayCheckStopwatch.stop();
    debugPrint(
      '⏱️ [CheckoutUI] gateway check finished in '
      '${gatewayCheckStopwatch.elapsedMilliseconds}ms '
      '(method=${method.name}, reachable=${unreachableGateway == null})',
    );
    if (unreachableGateway != null) {
      final shouldContinue = await _confirmGatewayWarning(unreachableGateway);
      if (!shouldContinue) {
        paymentLaunchStopwatch.stop();
        debugPrint(
          '⏱️ [CheckoutUI] payment launch aborted by user after '
          '${paymentLaunchStopwatch.elapsedMilliseconds}ms '
          '(gateway=$unreachableGateway)',
        );
        return; // 用户取消
      }
    }

    // 开始支付
    GchUmengSvc.onPaymentConfirm(productId: product.productId, provider: provider.code);
    state = state.copyWith(isProcessingPayment: true);
    debugPrint(
      '⏱️ [CheckoutUI] handing off to PaymentService.startPayment '
      'after ${paymentLaunchStopwatch.elapsedMilliseconds}ms '
      '(product=${product.productId}, provider=${provider.code})',
    );
    paymentLaunchStopwatch.stop();

    unawaited(_paymentService!
        .startPayment(
      product: ProductInfo(
        id: product.id,
        productId: product.productId,
        priceId: product.priceId,
        title: product.title,
        description: product.description ?? '',
        price: product.price,
        currency: product.currency ?? 'USD',
        formattedPrice: product.priceFormatted,
        type: product.type,
        durationDays: product.duration,
      ),
      method: method,
      userId: user.userId,
      payProviderId: provider.id,
    ).catchError((error, stackTrace) {
      debugPrint('❌ startPayment failed: $error');
      state = state.copyWith(isProcessingPayment: false);
      return state.flowState;
    }));
  }

  /// 取消支付
  Future<void> cancelPayment() async {
    state = state.copyWith(isProcessingPayment: false);
    await _paymentService?.cancelPayment();
  }

  /// 重试支付
  Future<void> retryPayment() async {
    state = state.copyWith(isProcessingPayment: true);
    try {
      await _paymentService?.retryPayment();
    } finally {
      state = state.copyWith(isProcessingPayment: false);
    }
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 清除超时消息（兼容旧接口）
  void clearTimeoutMessage() {
    state = state.copyWith(paymentTimeoutMessage: null);
  }

  /// 应用恢复时检查并重置过期的支付状态
  ///
  /// 当用户从外部支付界面(App Store)返回但未完成支付时，
  /// 需要重置按钮状态，避免一直显示旋转
  void onAppResumed() {
    _resetStalePaymentState();
  }

  /// 检查并重置过期的支付状态
  ///
  /// App Store：USER_CANCELED 时 purchaseStream 可能不发事件，
  /// 延迟几秒等待事件到达，若仍在处理中则兜底取消。
  ///
  /// 关键保护：如果支付已进入 processing（后端验证中）或更后续状态，
  /// 说明 Apple 已经扣款成功，绝不能取消订单。
  void _resetStalePaymentState() {
    if (!state.isProcessingPayment) return;

    final flowState = state.flowState;

    // 如果已进入 processing/success/completed 阶段，说明支付已成功，
    // 正在等待后端验证，绝不能取消
    if (flowState is PaymentFlowProcessing ||
        flowState is PaymentFlowSuccess) {
      debugPrint('📱 onAppResumed: 支付正在验证中，跳过取消 (flowState=${flowState.runtimeType})');
      return;
    }

    // App Store：延迟 5 秒兜底
    // 正常情况下取消事件会在 5 秒内到达并自动重置；
    // 若届时仍处于处理中，说明 purchaseStream 未收到取消事件。
    final isInAppPurchase = switch (flowState) {
      PaymentFlowPreparingPayment(:final method) => method == PayProvider.inAppPurchase,
      PaymentFlowAwaitingPayment(:final method) => method == PayProvider.inAppPurchase,
      _ => false,
    };

    if (isInAppPurchase) {
      Future.delayed(const Duration(seconds: 5), () {
        if (_disposed) return;
        if (!state.isProcessingPayment) return;

        // 再次检查：延迟期间可能已进入验证阶段
        final currentFlow = state.flowState;
        if (currentFlow is PaymentFlowProcessing ||
            currentFlow is PaymentFlowSuccess) {
          debugPrint('📱 5s后检查: 支付已进入验证阶段，跳过取消 (flowState=${currentFlow.runtimeType})');
          return;
        }

        debugPrint('📱 Resetting stale InAppPurchase payment state after app resume');
        cancelPayment();
      });
    }
  }

  /// 恢复购买 - 用于支付成功但验证失败的补单
  ///
  /// 职责分离：
  /// - UI 层：状态管理、Toast 通知
  /// - PaymentService：业务逻辑（刷新会话、断开连接）、配置下载事件
  Future<bool> restorePurchases(BuildContext context) async {
    if (state.isRestoring) {
      debugPrint('⚠️ restorePurchases: already in progress');
      return false;
    }

    state = state.copyWith(isRestoring: true);
    final notificationController = ref.read(gchSignalHubProvider);

    try {
      debugPrint('🔄 restorePurchases: starting...');

      // 调用 PendingPurchaseHandler 处理未完成购买（获取详细结果用于 UI）
      // 🔑 source: userTriggered - 用户主动点击"恢复购买"按钮
      final handler = ref.read(pendingPurchaseHandlerProvider);
      final result = await handler.processPendingPurchases(
        source: RestoreSource.userTriggered,
      ).timeout(const Duration(seconds: 30));

      debugPrint('✅ restorePurchases: processed=${result.totalProcessed}, success=${result.successCount}');

      // UI：显示结果通知
      final message = result.totalProcessed > 0
          ? (result.allSuccessful
              ? GchText.userPayRestoreSuccess
              : GchText.userPayRestorePartial)
          : GchText.userPayRestoreNoPending;

      final showSuccessToast = result.allSuccessful && result.totalProcessed > 0;
      if (showSuccessToast) {
        notificationController.flashSuccess(message, duration: const Duration(seconds: 3));
      } else {
        notificationController.flashInfo(message, duration: const Duration(seconds: 3));
      }

      // 🎯 委托 PaymentService 完成后续业务逻辑（刷新会话、断开连接、配置下载）
      await _paymentService?.handleRestoreCompletion(
        hasRestoredPurchases: true,
      );

      return result.allSuccessful;
    } catch (e) {
      debugPrint('❌ restorePurchases: failed - $e');
      notificationController.flashError(GchText.userPayRestoreFailed);
      return false;
    } finally {
      state = state.copyWith(isRestoring: false);
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.wait([
      _loadProducts(),
      _loadPayProviders(),
    ]);
    state = state.copyWith(isLoading: false);
  }

  // ========== State Listening ==========

  void _onFlowStateChanged(PaymentFlowState flowState) {
    state = state.copyWith(flowState: flowState);

    // Terminal state handling — 关闭处理中对话框并重置按钮状态
    if (flowState.isTerminal) {
      state = state.copyWith(isProcessingPayment: false);
      // 确保处理中对话框在任何终态（成功/失败/取消/超时）都被关闭
      PaymentProcessingDialog.dismissIfShowing();
    }

    // Show notifications based on state
    _handleFlowStateNotification(flowState);
  }

  /// Handle notifications based on flow state
  void _handleFlowStateNotification(PaymentFlowState flowState) {
    final notificationController = ref.read(gchSignalHubProvider);

    switch (flowState) {
      case PaymentFlowSuccess():
        // 通知成功 - 业务逻辑已由 PaymentService 处理
        // UI 操作（导航、配置下载）由 OnPaymentSuccessEvent 处理
        notificationController.flashSuccess(GchText.userPayResultsPaymentSuccess);
        break;

      case PaymentFlowFailed(:final reason):
        // Some errors are handled silently:
        // - alreadyOwned: User already owns this subscription (store shows its own dialog)
        // - subscriptionChangeBlocked: Subscription change blocked by store (store handles UI)
        final silentReasons = {
          PaymentFailureReason.alreadyOwned,
          PaymentFailureReason.subscriptionChangeBlocked,
        };
        if (!silentReasons.contains(reason)) {
          notificationController.flashError(GchText.userPayErrorsPaymentError);
        }
        break;

      case PaymentFlowCancelled():
        // User cancellation - no notification needed, just log
        GchUmengSvc.onSubscriptionCancel(productId: state.selectedProduct?.productId);
        debugPrint('ℹ️ Payment cancelled by user');
        break;

      case PaymentFlowTimeout(:final message):
        // Timeout - show message and allow retry
        final timeoutMsg = GchText.userPayErrorsPaymentTakingLong;
        if (message != null && message != timeoutMsg) {
          debugPrint('ℹ️ Payment timeout detail: $message');
        }
        notificationController.flashInfo(timeoutMsg);
        break;

      default:
        // Other states don't need notifications
        break;
    }
  }

  // ========== Event Handling ==========

  /// 处理 UI 事件
  ///
  /// 🎯 所有 UI 操作都通过此方法处理，包括：
  /// - 导航操作
  /// - 弹窗操作（支付处理中、确认、选择器等）
  /// - 配置下载触发
  void _onUIEvent(CheckoutUIEvent event) {
    // Get context (via gchRootNavKey)
    final context = _getContext();
    if (context == null) return;

    switch (event) {
      case NavigateToEvent(:final route):
        Navigator.of(context).pushNamed(route);

      case NavigateBackEvent(:final result):
        Navigator.of(context).pop(result);

      case NavigateToLoginEvent():
        const NavLoginRoute().go(context);

      case DismissEvent():
        Navigator.of(context).pop();

      case ShowUnpaidOrderDialogEvent(
          :final orderId,
          :final productId,
          :final productName,
          :final amount,
          :final currency,
          :final callbackId
        ):
        _showUnpaidOrderDialog(
          context,
          orderId,
          productId,
          productName,
          amount,
          currency,
          callbackId,
        );

      case ShowPaymentMethodSelectorEvent(:final methods, :final currentMethod, :final callbackId):
        _showPaymentMethodSelector(context, methods, currentMethod, callbackId);

      case ShowConfirmDialogEvent(:final title, :final message, :final callbackId):
        _showConfirmDialog(context, title, message, callbackId);

      case ShowLoadingEvent(:final message):
        _showLoading(context, message);

      case HideLoadingEvent():
        _hideLoading(context);

      // 🎯 支付处理中弹框（来自 PaymentEventBus -> PaymentService）
      case ShowPaymentProcessingDialogEvent(:final message):
        if (!state.isProcessingPayment && !state.flowState.isProcessing) {
          debugPrint('⏭️ Ignoring processing dialog (no active flow)');
          return;
        }
        PaymentProcessingDialog.show(
          context,
          message: message ?? GchText.userPayProcessingMsg,
        );

      case HidePaymentProcessingDialogEvent():
        PaymentProcessingDialog.dismiss(context);
        // 同时重置按钮状态
        state = state.copyWith(isProcessingPayment: false);

      // 🎯 配置下载触发（来自 PaymentEventBus.completed -> PaymentService）
      case TriggerConfigDownloadEvent(:final orderId, :final redirectTo):
        _triggerConfigDownload(context, orderId, redirectTo);

      case RefreshProductsEvent():
        _loadProducts();

      case RefreshUserInfoEvent():
        ref.invalidate(currentUserProvider);

      case UpdateFlowStateEvent():
        // Already handled via stateStream
        break;

      case ShowDuplicatePaymentWarningEvent():
        _handleDuplicatePaymentWarning();

      case ShowAlreadySubscribedDialogEvent(
            :final productId,
            :final isSubscriptionSwitch,
            :final message):
        _showAlreadySubscribedDialog(context, productId, isSubscriptionSwitch, message);

      case OnPaymentSuccessEvent(:final orderId):
        // 🎯 业务逻辑事件，配置下载已由 TriggerConfigDownloadEvent 处理
        // 此事件仅用于兼容性和日志
        debugPrint('🎉 [UI] OnPaymentSuccessEvent received, orderId=$orderId');
        break;

      case OpenUrlEvent():
        // TODO: Implement URL opening
        break;
    }
  }

  /// Handle duplicate payment warning
  void _handleDuplicatePaymentWarning() {
    final notificationController = ref.read(gchSignalHubProvider);
    notificationController.flashInfo(GchText.userPayErrorsDuplicatePayment);
  }

  /// 🔔 显示已订阅提示
  ///
  /// 当用户点击购买但 iOS 返回 restored 状态时触发
  /// 表示用户已有有效订阅，iOS 未显示付款界面
  ///
  /// [isSubscriptionSwitch] 为 true 时表示切换到不同商品，显示切换提示；
  /// 为 false 时表示重复购买同一商品，显示已订阅提示。
  void _showAlreadySubscribedDialog(
    BuildContext context,
    String productId,
    bool isSubscriptionSwitch,
    String? message,
  ) {
    debugPrint('🔔 [UI] 显示已订阅提示: $productId, isSwitch=$isSubscriptionSwitch');
    final notificationController = ref.read(gchSignalHubProvider);

    // 重置支付处理状态
    state = state.copyWith(isProcessingPayment: false);

    // 根据场景选择提示信息
    final displayMessage = message ??
        (isSubscriptionSwitch
            ? GchText.userPayErrorsSubscriptionSwitched
            : GchText.userPayErrorsAlreadySubscribedSame);

    notificationController.flashInfo(displayMessage);
  }

  /// 🌐 网关不可达确认弹窗
  Future<bool> _confirmGatewayWarning(String gatewayName) async {
    final notificationController = ref.read(gchSignalHubProvider);
    return notificationController.alertConfirm(
      title: GchText.userPayGatewayWarningTitle,
      message: GchText.userPayGatewayWarningMessage.replaceAll('{}', gatewayName),
      confirmText: GchText.userPayGatewayWarningContinueBtn,
      cancelText: GchText.userPayGatewayWarningCancelBtn,
    );
  }

  /// 🎯 支付成功后跳转
  ///
  /// 来自 PaymentService 的 TriggerConfigDownloadEvent
  void _triggerConfigDownload(
    BuildContext context,
    String? orderId,
    String redirectTo,
  ) {
    if (!context.mounted) return;

    debugPrint('🎉 [UI] Payment succeeded, orderId=$orderId, redirectTo=$redirectTo');
    final notificationController = ref.read(gchSignalHubProvider);
    notificationController.flashSuccess(GchText.userCommonDownloadSuccess);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (redirectTo.isNotEmpty) {
        context.go(redirectTo);
      } else {
        const NavMainHomeRoute().go(context);
      }
    });
  }

  // ========== Helper Methods ==========

  BuildContext? _getContext() {
    return gchRootNavKey.currentContext ??
        gchRootNavKey.currentState?.context;
  }

  void _showError(String message) {
    state = state.copyWith(errorMessage: message);
    ref.read(gchSignalHubProvider).flashError(message);
  }

  void _showUnpaidOrderDialog(
    BuildContext context,
    String orderId,
    int productId,
    String productName,
    double amount,
    String currency,
    String callbackId,
  ) {
    // 创建临时 OrderEntry 用于 UnpaidDialog
    final tempOrder = OrderEntry(
      orderNum: orderId,
      userId: '',
      productId: productId,
      productName: productName,
      originalTotal: amount,
      discountTotal: 0,
      total: amount,
      currency: currency,
      voucherId: '',
      orderType: '',
      payStatus: 0,
      status: 0,
      agentId: 0,
      platform: '',
      refundTotal: 0,
      createAt: DateTime.now(),
      updateAt: DateTime.now(),
      qty: 1,
      price: amount,
      tax: 0,
      rate: 1,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UnpaidDialog(
        order: tempOrder,
        onPay: () {
          _paymentService?.handleUICallback(UIEventCallbackResult(
            callbackId: callbackId,
            confirmed: true,
            data: {'action': 'continue'},
          ));
        },
        onCancel: () {
          _paymentService?.handleUICallback(UIEventCallbackResult(
            callbackId: callbackId,
            confirmed: false,
            data: {'action': 'cancel'},
          ));
        },
      ),
    );
  }

  void _showPaymentMethodSelector(
    BuildContext context,
    List<PayProvider> methods,
    PayProvider? currentMethod,
    String callbackId,
  ) {
    if (methods.isEmpty) {
      _paymentService?.handleUICallback(UIEventCallbackResult(
        callbackId: callbackId,
        confirmed: false,
      ));
      return;
    }


    showModalBottomSheet<PayProvider>(
      context: context,
      useSafeArea: true, // 避免刘海遮挡内容
      builder: (ctx) {
        PayProvider? selected = currentMethod ?? methods.first;
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setState) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    GchText.userPayPaymentMethod,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                    ...methods.map(
                      (method) => RadioListTile<PayProvider>(
                        value: method,
                        groupValue: selected,
                        contentPadding: EdgeInsets.zero,
                        title: Text(_getPayProviderDisplayName(method)),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selected = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: Text(GchText.userCommonCancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(selected),
                        child: Text(GchText.userCommonConfirm),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((selectedMethod) {
      _paymentService?.handleUICallback(UIEventCallbackResult(
        callbackId: callbackId,
        confirmed: selectedMethod != null,
        data: selectedMethod != null
            ? {'method': selectedMethod.code}
            : null,
      ));
    });
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    String callbackId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _paymentService?.handleUICallback(UIEventCallbackResult(
                callbackId: callbackId,
                confirmed: false,
              ));
            },
            child: Text(GchText.userCommonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _paymentService?.handleUICallback(UIEventCallbackResult(
                callbackId: callbackId,
                confirmed: true,
              ));
            },
            child: Text(GchText.userCommonConfirm),
          ),
        ],
      ),
    );
  }

  void _showLoading(BuildContext context, String? message) {
    PaymentProcessingDialog.show(context, message: message);
  }

  void _hideLoading(BuildContext context) {
    PaymentProcessingDialog.dismiss(context);
  }

  String _getPayProviderDisplayName(PayProvider method) {
    for (final provider in state.availablePayProviders) {
      final mapped = PayProviderExtension.fromCode(provider.code);
      if (mapped == method && provider.name.isNotEmpty) {
        return provider.name;
      }
    }

    switch (method) {
      case PayProvider.inAppPurchase:
        return '应用内购买';
    }
  }

  bool _consumePaymentTap() {
    final now = DateTime.now();
    final lastTap = _lastPaymentTapTime;
    if (lastTap != null && now.difference(lastTap) < _tapDebounceDuration) {
      debugPrint('⚠️ CheckoutNotifierV2: tap ignored due to debounce');
      return false;
    }
    _lastPaymentTapTime = now;
    return true;
  }
}
