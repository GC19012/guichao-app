import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';

/// 友盟统计服务
///
/// 封装友盟 SDK 的初始化和事件埋点，提供统一的统计 API。
/// 仅在 iOS 平台生效。
class GchUmengSvc {
  GchUmengSvc._();

  static bool _initialized = false;

  // ========== 友盟 App Key 配置 ==========
  static const String _iosAppKeyRelease = '6a052cff6f259537c7a901d4';
  static const String _iosAppKeyDebug = '69df75d29a7f376488c312fc';
  static String get _iosAppKey => kDebugMode ? _iosAppKeyDebug : _iosAppKeyRelease;
  static const String _channel = 'App Store';

  /// 初始化友盟 SDK
  ///
  /// 应在 app 启动时调用（bootstrap 阶段）
  static Future<void> setup() async {
    if (_initialized) return;

    if (!Platform.isIOS) {
      debugPrint('[GchUmengSvc] 非 iOS 平台，跳过友盟初始化');
      return;
    }

    try {
      // initCommon 的 native 实现不调用 result()，Future 永远不会 resolve。
      // 使用 unawaited：native 侧 [UMConfigure initWithAppkey:channel:] 是同步执行的，
      // 调用完成后立即可使用后续 API。
      unawaited(UmengCommonSdk.initCommon('', _iosAppKey, _channel));

      // 禁用 SDK 自动页面采集，改为由 GchUmengObserver + routerDelegate 手动上报
      UmengCommonSdk.setPageCollectionModeManual();

      _initialized = true;
      debugPrint('[GchUmengSvc] 友盟 SDK 初始化成功');
    } catch (e, stack) {
      debugPrint('[GchUmengSvc] 友盟 SDK 初始化失败: $e');
      debugPrint('$stack');
    }
  }

  /// 是否已初始化
  static bool get isReady => _initialized;

  // ========== 页面统计 ==========

  /// 进入页面（手动模式）
  static void onPageStart(String pageName) {
    if (!_initialized) return;
    if (kDebugMode) debugPrint('[GchUmeng] ▶ pageStart: $pageName');
    UmengCommonSdk.onPageStart(pageName);
  }

  /// 离开页面（手动模式）
  static void onPageEnd(String pageName) {
    if (!_initialized) return;
    if (kDebugMode) debugPrint('[GchUmeng] ◀ pageEnd: $pageName');
    UmengCommonSdk.onPageEnd(pageName);
  }

  // ========== 自定义事件 ==========

  /// 计数事件
  ///
  /// [eventId] 事件 ID（在友盟后台配置）
  /// [params] 事件参数（可选）
  static void onEvent(String eventId, [Map<String, dynamic>? params]) {
    if (!_initialized) return;
    // 友盟要求 attributes 的 key/value 必须是 NSString，将所有 value 转为 String
    final stringParams = (params ?? {}).map((k, v) => MapEntry(k, '$v'));
    if (kDebugMode) {
      debugPrint('[GchUmeng] ▶ onEvent: $eventId  params=$stringParams');
    }
    UmengCommonSdk.onEvent(eventId, stringParams);
  }

  // ========== 预定义事件 ==========

  /// 用户登录
  static void onLogin(String userId, {String provider = 'custom'}) {
    if (!_initialized) return;
    UmengCommonSdk.onProfileSignIn(userId);
    onEvent('gch_login', {'provider': provider});
  }

  /// 用户登出
  static void onLogout() {
    if (!_initialized) return;
    UmengCommonSdk.onProfileSignOff();
    onEvent('gch_logout');
  }

  /// VPN 连接
  static void onVpnConnect({String? node, String? protocol}) {
    onEvent('gch_vpn_connect', {
      if (node != null) 'node': node,
      if (protocol != null) 'protocol': protocol,
    });
  }

  /// VPN 断开
  static void onVpnDisconnect({int? durationSec}) {
    onEvent('gch_vpn_disconnect', {
      if (durationSec != null) 'duration_sec': durationSec,
    });
  }

  /// 订阅购买
  static void onPurchase({
    required String productId,
    String? price,
    String? currency,
  }) {
    onEvent('gch_purchase', {
      'product_id': productId,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
    });
  }

  /// 节点切换
  static void onNodeSwitch(String fromNode, String toNode) {
    onEvent('gch_node_switch', {
      'from': fromNode,
      'to': toNode,
    });
  }

  /// 页面访问
  static void onPageView(String pageName) {
    onEvent('gch_page_view', {'page': pageName});
  }

  // ========== 用户行为埋点 ==========

  static String _eventTime() => DateTime.now().toIso8601String();

  /// 底部 TabBar 点击
  /// [tab] 标签名称：purchase / acceleration / more
  static void onTabTap(String tab) {
    onEvent('gch_tab_tap', {'tab': tab, 'event_time': _eventTime()});
  }

  /// 连接按钮点击
  static void onConnectTap() {
    onEvent('gch_connect_tap', {'event_time': _eventTime()});
  }

  /// 内购按钮点击（立即开通）
  static void onIapTap() {
    onEvent('gch_iap_tap', {'event_time': _eventTime()});
  }

  /// 登录按钮点击
  static void onLoginTap() {
    onEvent('gch_login_tap', {'event_time': _eventTime()});
  }

  /// 注册按钮点击
  static void onRegisterTap() {
    onEvent('gch_register_tap', {'event_time': _eventTime()});
  }

  /// 个人中心功能模块点击
  /// [module] 模块名称：orders / support / privacy / about / delete_account / checkout / password_change
  static void onProfileModuleTap(String module) {
    onEvent('gch_profile_module_tap', {'module': module, 'event_time': _eventTime()});
  }

  /// 客服按钮点击
  static void onServiceTap() {
    onEvent('gch_service_tap', {'event_time': _eventTime()});
  }

  // ========== 高优先级补充埋点 ==========

  /// 节点选择（用户点击某个代理节点）
  static void onNodeSelect(String nodeName, {String? groupTag}) {
    onEvent('gch_node_select', {
      'node_name': nodeName,
      if (groupTag != null) 'group_tag': groupTag,
      'event_time': _eventTime(),
    });
  }

  /// 测速触发
  static void onSpeedTest({String? groupTag}) {
    onEvent('gch_speed_test', {
      if (groupTag != null) 'group_tag': groupTag,
      'event_time': _eventTime(),
    });
  }

  /// 套餐卡片选择
  static void onProductSelect(String productId, {double? price, String? currency}) {
    onEvent('gch_product_select', {
      'product_id': productId,
      if (price != null) 'price': price.toStringAsFixed(2),
      if (currency != null) 'currency': currency,
      'event_time': _eventTime(),
    });
  }

  /// 恢复购买按钮点击
  static void onRestorePurchaseTap() {
    onEvent('gch_restore_purchase_tap', {'event_time': _eventTime()});
  }

  /// 注册成功
  static void onRegisterSuccess({String authType = 'email'}) {
    onEvent('gch_register_success', {'auth_type': authType, 'event_time': _eventTime()});
  }

  /// VPN 连接失败
  static void onConnFail({String? reason}) {
    onEvent('gch_conn_fail', {
      if (reason != null) 'reason': reason,
      'event_time': _eventTime(),
    });
  }

  /// 用户确认支付（点击立即开通并通过前置校验，进入实际支付流程）
  static void onPaymentConfirm({String? productId, String? provider}) {
    onEvent('gch_payment_confirm', {
      if (productId != null) 'product_id': productId,
      if (provider != null) 'provider': provider,
      'event_time': _eventTime(),
    });
  }

  /// 用户取消支付流程（StoreKit 取消或主动点击取消）
  static void onSubscriptionCancel({String? productId}) {
    onEvent('gch_subscription_cancel', {
      if (productId != null) 'product_id': productId,
      'event_time': _eventTime(),
    });
  }

  // ========== 中优先级：用户行为分析 ==========

  /// 智能选线开关切换
  static void onSmartLineToggle({required bool enabled}) {
    onEvent('gch_smart_line_toggle', {
      'enabled': enabled ? '1' : '0',
      'event_time': _eventTime(),
    });
  }

  /// 用户登出
  static void onLogoutTap() {
    if (!_initialized) return;
    UmengCommonSdk.onProfileSignOff();
    onEvent('gch_logout_tap', {'event_time': _eventTime()});
  }

  // ========== 工具模块 ==========

  /// 工具 tab：功能卡片点击
  /// [tool] 工具标识：traffic / netdiag / history / speedtest
  static void onToolItemTap(String tool) {
    onEvent('gch_tool_item_tap', {'tool': tool, 'event_time': _eventTime()});
  }

  /// 工具 tab：节假日卡片点击（进入节假日列表）
  static void onToolHolidayTap() {
    onEvent('gch_tool_holiday_tap', {'event_time': _eventTime()});
  }

  /// 工具 tab：网络诊断执行
  static void onToolNetDiagRun() {
    onEvent('gch_tool_netdiag_run', {'event_time': _eventTime()});
  }

  // ========== 低优先级 ==========

  /// 结账页面打开（漏斗入口）
  static void onCheckoutOpen() {
    onEvent('gch_checkout_open', {'event_time': _eventTime()});
  }

  /// 代理节点页面打开
  static void onProxyPageOpen() {
    onEvent('gch_proxy_page_open', {'event_time': _eventTime()});
  }

  /// 搜索栏打开（代理节点页）
  static void onSearchOpen() {
    onEvent('gch_search_open', {'event_time': _eventTime()});
  }
}
