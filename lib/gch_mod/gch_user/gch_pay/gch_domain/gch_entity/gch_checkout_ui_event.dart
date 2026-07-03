import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_entity/gch_payment_flow_state.dart';

part 'gch_checkout_ui_event.freezed.dart';

/// Checkout UI 事件 - 业务层发出，UI 层消费
///
/// 设计原则：
/// 1. 事件驱动：业务层通过事件通知 UI 层，而非直接持有 BuildContext
/// 2. 单向数据流：业务层 -> 事件 -> UI 层
/// 3. 类型安全：密封类确保所有事件都被处理
/// 4. 无 UI 依赖：事件只包含数据，不包含 Widget、Color 等
///
/// 注意：Toast 和通知使用项目统一的 GchSignalHub，
/// 不通过事件机制，直接在 Notifier 中调用即可。
///
/// 使用方式：
/// ```dart
/// // 在 Notifier 中发出事件
/// _emitEvent(CheckoutUIEvent.navigateToLogin());
///
/// // 在 UI 层监听事件
/// ref.listen(checkoutUIEventProvider, (_, event) {
///   if (event == null) return;
///   event.when(
///     navigateToLogin: (_) => LoginRoute().go(context),
///     showUnpaidOrderDialog: (orderId, ...) => _showDialog(context, ...),
///     ...
///   );
/// });
/// ```
@freezed
sealed class CheckoutUIEvent with _$CheckoutUIEvent {
  // ========== 导航事件 ==========

  /// 导航到指定路由
  const factory CheckoutUIEvent.navigateTo({
    required String route,
    Map<String, dynamic>? arguments,
  }) = NavigateToEvent;

  /// 返回上一页
  const factory CheckoutUIEvent.navigateBack({
    dynamic result,
  }) = NavigateBackEvent;

  /// 导航到登录页
  const factory CheckoutUIEvent.navigateToLogin({
    String? returnRoute,
  }) = NavigateToLoginEvent;

  /// 关闭当前页面/弹窗
  const factory CheckoutUIEvent.dismiss() = DismissEvent;

  // ========== 业务弹窗事件 ==========

  /// 显示未支付订单弹窗
  ///
  /// 当用户尝试购买新商品但存在未支付订单时触发
  const factory CheckoutUIEvent.showUnpaidOrderDialog({
    required String orderId,
    required int productId,
    required String productName,
    required double amount,
    required String currency,
    /// 回调 ID，用于 UI 层返回用户选择结果
    required String callbackId,
  }) = ShowUnpaidOrderDialogEvent;

  /// 显示支付方式选择弹窗
  const factory CheckoutUIEvent.showPaymentMethodSelector({
    required List<PayProvider> methods,
    PayProvider? currentMethod,
    required String callbackId,
  }) = ShowPaymentMethodSelectorEvent;

  /// 显示确认弹窗（通用）
  const factory CheckoutUIEvent.alertConfirm({
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    required String callbackId,
  }) = ShowConfirmDialogEvent;

  // ========== 加载状态事件 ==========

  /// 显示全屏加载遮罩
  const factory CheckoutUIEvent.showLoading({
    String? message,
  }) = ShowLoadingEvent;

  /// 隐藏全屏加载遮罩
  const factory CheckoutUIEvent.hideLoading() = HideLoadingEvent;

  // ========== 支付处理弹框事件 ==========

  /// 显示支付处理中弹框（订单验证中）
  ///
  /// 触发时机：收到 PaymentEventBus.processing 事件时
  /// 表示用户已完成支付SDK操作，正在等待后端验证
  const factory CheckoutUIEvent.showPaymentProcessingDialog({
    String? message,
  }) = ShowPaymentProcessingDialogEvent;

  /// 隐藏支付处理中弹框
  ///
  /// 触发时机：收到 PaymentEventBus.completed/failed/cancelled 事件时
  const factory CheckoutUIEvent.hidePaymentProcessingDialog() = HidePaymentProcessingDialogEvent;

  /// 触发配置下载流程
  ///
  /// 触发时机：支付成功后（PaymentEventBus.completed）
  /// 独立于 onPaymentSuccess，确保配置下载在支付验证完成后立即触发
  const factory CheckoutUIEvent.triggerConfigDownload({
    String? orderId,
    required String redirectTo,
  }) = TriggerConfigDownloadEvent;

  // ========== 状态同步事件 ==========

  /// 刷新商品列表
  const factory CheckoutUIEvent.refreshProducts() = RefreshProductsEvent;

  /// 刷新用户信息（订阅状态变更后）
  const factory CheckoutUIEvent.refreshUserInfo() = RefreshUserInfoEvent;

  /// 更新支付流程状态（用于 UI 同步显示）
  const factory CheckoutUIEvent.updateFlowState({
    required PaymentFlowState state,
  }) = UpdateFlowStateEvent;

  // ========== 警告事件 ==========

  /// 显示重复支付警告
  const factory CheckoutUIEvent.showDuplicatePaymentWarning() = ShowDuplicatePaymentWarningEvent;

  /// 显示已订阅提示
  ///
  /// 触发时机：用户点击购买按钮，但 iOS 返回 restored 状态（表示已有有效订阅）
  /// iOS App Store 在用户已订阅时不会显示付款界面，而是直接返回恢复状态
  ///
  /// [isSubscriptionSwitch] 为 true 时表示用户切换到了不同的订阅商品（升级/降级），
  /// 此时应显示"已切换订阅，下个周期生效"的提示；
  /// 为 false 时表示用户重复购买同一商品，应显示"已订阅，无需重复购买"的提示。
  const factory CheckoutUIEvent.showAlreadySubscribedDialog({
    required String productId,
    @Default(false) bool isSubscriptionSwitch,
    String? message,
  }) = ShowAlreadySubscribedDialogEvent;

  // ========== 支付成功后事件 ==========

  /// 支付成功后，触发配置下载并跳转
  const factory CheckoutUIEvent.onPaymentSuccess({
    required String? orderId,
    required String redirectTo,
  }) = OnPaymentSuccessEvent;

  // ========== 外部操作事件 ==========

  /// 打开外部链接（如 WebView 支付页）
  const factory CheckoutUIEvent.openUrl({
    required String url,
    @Default(false) bool external,
  }) = OpenUrlEvent;
}

/// UI 事件回调结果
///
/// 用于 UI 层返回用户在弹窗中的选择结果
class UIEventCallbackResult {
  final String callbackId;
  final bool confirmed;
  final dynamic data;

  const UIEventCallbackResult({
    required this.callbackId,
    required this.confirmed,
    this.data,
  });
}

/// CheckoutUIEvent 扩展
extension CheckoutUIEventX on CheckoutUIEvent {
  /// 是否为导航事件
  bool get isNavigationEvent => switch (this) {
        NavigateToEvent() => true,
        NavigateBackEvent() => true,
        NavigateToLoginEvent() => true,
        DismissEvent() => true,
        _ => false,
      };

  /// 是否为弹窗事件
  bool get isDialogEvent => switch (this) {
        ShowUnpaidOrderDialogEvent() => true,
        ShowPaymentMethodSelectorEvent() => true,
        ShowConfirmDialogEvent() => true,
        ShowLoadingEvent() => true,
        HideLoadingEvent() => true,
        ShowPaymentProcessingDialogEvent() => true,
        HidePaymentProcessingDialogEvent() => true,
        _ => false,
      };

  /// 是否需要等待用户反馈
  bool get requiresCallback => switch (this) {
        ShowUnpaidOrderDialogEvent() => true,
        ShowPaymentMethodSelectorEvent() => true,
        ShowConfirmDialogEvent() => true,
        _ => false,
      };

  /// 获取回调 ID（如果有）
  String? get callbackId => switch (this) {
        ShowUnpaidOrderDialogEvent(:final callbackId) => callbackId,
        ShowPaymentMethodSelectorEvent(:final callbackId) => callbackId,
        ShowConfirmDialogEvent(:final callbackId) => callbackId,
        _ => null,
      };

  /// 获取事件名称（用于日志）
  String get eventName => switch (this) {
        NavigateToEvent(:final route) => 'navigate_to:$route',
        NavigateBackEvent() => 'navigate_back',
        NavigateToLoginEvent() => 'navigate_to_login',
        DismissEvent() => 'dismiss',
        ShowUnpaidOrderDialogEvent(:final orderId) =>
          'unpaid_order_dialog:$orderId',
        ShowPaymentMethodSelectorEvent() => 'payment_method_selector',
        ShowConfirmDialogEvent(:final title) => 'confirm_dialog:$title',
        ShowLoadingEvent() => 'show_loading',
        HideLoadingEvent() => 'hide_loading',
        ShowPaymentProcessingDialogEvent() => 'show_payment_processing_dialog',
        HidePaymentProcessingDialogEvent() => 'hide_payment_processing_dialog',
        TriggerConfigDownloadEvent(:final orderId) =>
          'trigger_config_download:$orderId',
        RefreshProductsEvent() => 'refresh_products',
        RefreshUserInfoEvent() => 'refresh_user_info',
        UpdateFlowStateEvent() => 'update_flow_state',
        ShowDuplicatePaymentWarningEvent() => 'duplicate_payment_warning',
        ShowAlreadySubscribedDialogEvent(:final productId) =>
          'already_subscribed:$productId',
        OnPaymentSuccessEvent(:final orderId) => 'on_payment_success:$orderId',
        OpenUrlEvent(:final url) => 'open_url:$url',
      };
}
