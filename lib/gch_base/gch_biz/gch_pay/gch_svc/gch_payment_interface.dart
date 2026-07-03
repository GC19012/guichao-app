import 'dart:async';

import 'package:flutter/foundation.dart';

/// 可释放资源的接口
abstract class Disposable {
  void dispose();
}

/// 🔑 恢复购买的来源类型
/// 用于区分不同场景的 restorePurchases 调用，避免事件处理冲突
enum RestoreSource {
  /// 无恢复操作（正常购买流程）
  none,

  /// 用户主动点击"恢复购买"按钮
  /// - 应处理所有历史购买
  /// - 应显示恢复结果 Toast
  userTriggered,

  /// 应用初始化时自动检查（已禁用 iOS restorePurchases）
  /// - 仅处理未完成的交易
  /// - 静默处理，不显示 UI
  initialization,

  /// 网络恢复后自动检查
  /// - 仅处理未完成的交易
  /// - 静默处理，不显示 UI
  networkRestore,

  /// 定期后台检查
  /// - 仅处理未完成的交易
  /// - 静默处理，不显示 UI
  periodicCheck,
}

/// 通用回调基类：简化 listen + broadcast，生产级可用
abstract class StreamCallback<T> implements Disposable {
  StreamController<IResponse>? _controller;
  StreamSubscription<T>? _sub;
  bool _initialized = false;
  bool _disposed = false;

  /// 支付上下文（跨调用传递业务信息：userId, orderId, flowId, productId 等）
  /// 用于解决平台 SDK 回调不返回业务上下文的问题
  Map<String, dynamic>? _pendingContext;

  /// 🔑 当前恢复购买的来源
  /// 用于事件处理时区分场景，决定处理策略
  RestoreSource _restoreSource = RestoreSource.none;

  /// 获取当前恢复来源
  RestoreSource get restoreSource => _restoreSource;

  /// 设置恢复来源（在调用 restorePurchases 前设置）
  void setRestoreSource(RestoreSource source) {
    _restoreSource = source;
    debugPrint('🔄 [RestoreSource] 设置为: $source');
  }

  /// 重置恢复来源（在恢复完成后调用）
  void resetRestoreSource() {
    if (_restoreSource != RestoreSource.none) {
      debugPrint('🔄 [RestoreSource] 重置: $_restoreSource → none');
      _restoreSource = RestoreSource.none;
    }
  }

  /// 判断是否为用户主动触发的恢复
  bool get isUserTriggeredRestore => _restoreSource == RestoreSource.userTriggered;

  /// 判断是否为自动恢复（初始化/网络恢复/定期检查）
  bool get isAutoRestore =>
      _restoreSource == RestoreSource.initialization ||
      _restoreSource == RestoreSource.networkRestore ||
      _restoreSource == RestoreSource.periodicCheck;

  /// 平台流源（子类实现）
  Stream<T> get platformStream;

  /// 事件转换器（子类实现）
  IResponse convert(T event);

  /// 设置待处理的支付上下文
  /// 在发起支付前调用，回调返回时会合并到事件数据中
  void setPendingContext(Map<String, dynamic> context) {
    _pendingContext = context;
  }

  /// 获取当前支付上下文
  Map<String, dynamic>? getPendingContext() => _pendingContext;

  /// 清除支付上下文
  void clearPendingContext() {
    _pendingContext = null;
  }

  /// 合并事件数据与支付上下文
  /// 上下文中的字段不会覆盖已存在的字段（使用 putIfAbsent）
  Map<String, dynamic> mergeWithContext(Map<String, dynamic>? data) {
    if (_pendingContext == null) return data ?? const {};
    final merged = <String, dynamic>{...(data ?? const {})};
    _pendingContext!.forEach((key, value) {
      merged.putIfAbsent(key, () => value);
    });
    return merged;
  }

  /// 从参数中提取事件上下文（通用实现）
  /// 子类可覆盖以添加特定字段
  static Map<String, dynamic> extractEventContext(Map<String, dynamic> params) {
    final context = <String, dynamic>{};
    final userId = params['userId'];
    final flowId = params['flowId'];
    final orderId = params['orderId'] ?? params['orderNum'] ?? params['outTradeNo'];
    final productId = params['productId'];
    if (userId != null) context['userId'] = userId;
    if (flowId != null) context['flowId'] = flowId;
    if (orderId != null) context['orderId'] = orderId;
    if (productId != null) context['productId'] = productId;
    return context;
  }

  /// 初始化回调监听
  void initialize() {
    if (_initialized || _disposed) return;

    _controller = StreamController<IResponse>.broadcast(
      onCancel: () {
        // 当没有监听者时，暂停平台流监听以节省资源
        _pauseIfNoListeners();
      },
    );

    _sub = platformStream.listen(
      _handleEvent,
      onError: _handleError,
      onDone: _handleDone,
    );

    _initialized = true;
  }

  /// 获取结果流
  Stream<IResponse> onResult() {
    if (!_initialized) {
      throw StateError('StreamCallback未初始化，请先调用initialize()');
    }
    return _controller!.stream;
  }

  /// 处理平台事件
  void _handleEvent(T event) {
    if (_disposed || _controller == null) return;

    try {
      final response = convert(event);
      _controller!.add(response);
    } catch (e, s) {
      _handleError(e, s);
    }
  }

  /// 处理错误事件
  void _handleError(Object error, [StackTrace? stackTrace]) {
    if (_disposed || _controller == null) return;

    // 将错误转换为失败响应
    final failedResponse = IResponse.failed(
      message: error.toString(),
      data: {'error': error.toString(), 'stackTrace': stackTrace.toString()},
    );
    _controller!.add(failedResponse);
  }

  /// 处理流结束
  void _handleDone() {
    // 平台流结束，但保持controller开放等待重新连接
  }

  /// 当没有监听者时暂停
  void _pauseIfNoListeners() {
    if (_controller?.hasListener == false) {
      _sub?.pause();
    }
  }

  /// 检查是否有活跃监听者
  bool get hasListeners => _controller?.hasListener ?? false;

  /// 检查是否已初始化
  bool get isInitialized => _initialized;

  @override
  void dispose() {
    if (_disposed) return;

    _sub?.cancel();
    _controller?.close();

    _sub = null;
    _controller = null;
    _pendingContext = null;
    _restoreSource = RestoreSource.none;
    _initialized = false;
    _disposed = true;
  }
}

/// 函数式回调实现：进一步简化使用
class FunctionalCallback<T> extends StreamCallback<T> {
  final Stream<T> _platformStream;
  final IResponse Function(T) _converter;

  FunctionalCallback(this._platformStream, this._converter);

  @override
  Stream<T> get platformStream => _platformStream;

  @override
  IResponse convert(T event) => _converter(event);

  /// 快速创建函数式回调的工厂方法
  static FunctionalCallback<T> create<T>(
    Stream<T> stream,
    IResponse Function(T) converter,
  ) {
    final callback = FunctionalCallback(stream, converter);
    callback.initialize();
    return callback;
  }
}

/// 支付提供商抽象：封装回调管理
abstract class PaymentProvider<P extends Map<String, dynamic>, R extends Map<String, dynamic>> implements Disposable {
  PayProvider get method;
  bool get requiresSdk;

  final Map<CallbackType, StreamCallback> _callbacks = {};

  Future<bool> initialize(Map<String, dynamic> config) async {
    for (final cb in _callbacks.values) {
      cb.initialize();
    }
    return true;
  }

  @override
  void dispose() {
    for (final cb in _callbacks.values) {
      cb.dispose();
    }
    _callbacks.clear();
  }

  Set<CallbackType> getSupportedCallbackTypes() => _callbacks.keys.toSet();
  Stream<IResponse>? resultStream(CallbackType type) => _callbacks[type]?.onResult();

  Future<bool> isAvailable();

  /// 检查支付网关连通性
  /// 返回 null 表示网关可达，返回错误消息表示不可达
  /// 默认实现返回 null（不需要检测的支付方式直接放行）
  Future<String?> checkGatewayReachability() async => null;

  /// 获取网关显示名称（用于错误提示）
  String get gatewayDisplayName => method.name;

  /// 后端预支付/创建订单（默认不实现，由具体实现类按需调用）
  /// 要求：不要抛异常，失败请内部处理或返回 failed 响应
  Future<IResponse<R>> PrePay(IParams<P> params) async {
    return IResponse.failed(message: 'PrePay is not implemented for \\${method.name}');
  }
  /// 取消订单；默认客户端不支持，子类可覆盖
  Future<IResponse<R>> cancelorder(IParams<P> params) async {
    return _FailedResponse<R>(message: 'cancel order is not supported on client for \\${method.name}');
  }
  Future<IResponse<R>> pay(IParams<P> params);
  Future<IResponse<R>> query(IParams<P> params);
  Future<IResponse<R>> verifypay(IParams<P> params);
  Future<IResponse<R>> getPayResult(IParams<P> params);
  Future<IResponse<R>> refund(IParams<P> params);
  
  /// 获取商品列表 - 通用接口
  /// 不同支付方式有不同的实现策略：
  /// - 应用内购买：应用商店API -> 本地缓存 -> 数据库 -> 服务器
  /// - 第三方支付：本地数据库 -> 服务器API -> 配置文件
  Future<IResponse<List<Map<String, dynamic>>>> getProducts([List<String>? productIds]);
}

/// 回调类型枚举
enum CallbackType {
  payment, // 支付回调
  auth, // 授权回调
  transfer, // 转账回调
  refund, // 退款回调
  notify, // 通知回调
  purchase, // 应用内购买回调
  custom, // 自定义回调
}

/// 支付结果枚举
enum PaymentResult {
  success(100), // 支付成功
  failed(101), // 支付失败
  cancelled(102), // 支付取消
  processing(103), // 处理中
  pending(104), // 等待支付
  refunded(105), // 已退款
  partialRefunded(106), // 部分退款
  alreadyOwned(107), // 已购买/已订阅
  networkError(108), // 网络错误（无法连接App Store服务）
  serviceUnavailable(109), // 服务不可用（App Store服务不可用）
  serviceTimeout(110), // 服务超时
  subscriptionChangeBlocked(111); // 订阅变更被阻止

  const PaymentResult(this.value);

  final int value;

  /// 是否为网络/服务相关错误
  bool get isNetworkOrServiceError =>
      this == PaymentResult.networkError ||
      this == PaymentResult.serviceUnavailable ||
      this == PaymentResult.serviceTimeout;

  // 可选：通过数值反查枚举值
  static PaymentResult fromValue(int value) {
    return PaymentResult.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw Exception('Invalid PaymentResult value: $value'),
    );
  }
}

/// 支付方式枚举
enum PayProvider {
  inAppPurchase, // 统一的应用内购买（包含Google Play和App Store）
}

/// 支付方式枚举扩展
extension PayProviderExtension on PayProvider {
  /// 从数据库代码转换为枚举（统一入口）
  static PayProvider? fromCode(String code) {
    switch (code.toLowerCase()) {
      // 应用内购买的所有变体
      case 'googlepay':
      case 'applepay':
      case 'google_pay':
      case 'apple_pay':
      case 'in_app_purchase':
        return PayProvider.inAppPurchase;

      default:
        return null;
    }
  }

  /// 获取标准化的支付方式代码
  String get code {
    switch (this) {
      case PayProvider.inAppPurchase:
        return 'in_app_purchase';
    }
  }
}

/// 支付参数基础接口
///
abstract class IParams<T> {
  Map<String, dynamic> toMap();
}

/// 支付响应基础接口
abstract class IResponse<T> {
  PaymentResult get result;
  String? get message;
  Map<String, dynamic>? get data;

  /// 便捷方法：判断是否成功
  bool get success => result == PaymentResult.success;

  /// 便捷方法：判断是否失败
  bool get isFailed => result == PaymentResult.failed;

  /// 返回错误消息内容
  static IResponse<T> failed<T>({String? message, Map<String, dynamic>? data}) {
    return _FailedResponse<T>(message: message, data: data);
  }
}

class _FailedResponse<T> implements IResponse<T> {
  @override
  final PaymentResult result = PaymentResult.failed;

  @override
  final String? message;
  @override
  final Map<String, dynamic>? data;

  _FailedResponse({this.message, this.data});

  @override
  bool get success => result == PaymentResult.success;

  @override
  bool get isFailed => result == PaymentResult.failed;
}

/// 标准支付响应实现
class PaymentResponse implements IResponse<Map<String, dynamic>> {
  @override
  final PaymentResult result;

  @override
  final String? message;

  @override
  final Map<String, dynamic>? data;

  final String? transactionId;

  const PaymentResponse({
    required this.result,
    this.message,
    this.data,
    this.transactionId,
  });

  @override
  bool get success => result == PaymentResult.success;

  @override
  bool get isFailed => result == PaymentResult.failed;

  factory PaymentResponse.success({String? message, Map<String, dynamic>? data, String? transactionId}) {
    return PaymentResponse(
      result: PaymentResult.success,
      message: message,
      data: data,
      transactionId: transactionId,
    );
  }

  factory PaymentResponse.failed({String? message, Map<String, dynamic>? data}) {
    return PaymentResponse(
      result: PaymentResult.failed,
      message: message,
      data: data,
    );
  }

  factory PaymentResponse.cancelled({String? message, Map<String, dynamic>? data}) {
    return PaymentResponse(
      result: PaymentResult.cancelled,
      message: message,
      data: data,
    );
  }

  factory PaymentResponse.processing({String? message, Map<String, dynamic>? data, String? transactionId}) {
    return PaymentResponse(
      result: PaymentResult.processing,
      message: message,
      data: data,
      transactionId: transactionId,
    );
  }

  /// 已购买/已订阅状态
  factory PaymentResponse.alreadyOwned({String? message, Map<String, dynamic>? data}) {
    return PaymentResponse(
      result: PaymentResult.alreadyOwned,
      message: message ?? '您已订阅此商品',
      data: data,
    );
  }

  /// 网络错误（应用商店返回网络错误时使用）
  factory PaymentResponse.networkError({String? message, Map<String, dynamic>? data}) {
    return PaymentResponse(
      result: PaymentResult.networkError,
      message: message ?? '网络连接失败，请检查网络后重试',
      data: data,
    );
  }

  /// 服务不可用（App Store服务不可用时使用）
  factory PaymentResponse.serviceUnavailable({String? message, Map<String, dynamic>? data}) {
    return PaymentResponse(
      result: PaymentResult.serviceUnavailable,
      message: message ?? '应用商店服务不可用，请稍后重试',
      data: data,
    );
  }

  /// 服务超时
  factory PaymentResponse.serviceTimeout({String? message, Map<String, dynamic>? data}) {
    return PaymentResponse(
      result: PaymentResult.serviceTimeout,
      message: message ?? '服务响应超时，请稍后重试',
      data: data,
    );
  }

  /// 订阅变更被阻止
  ///
  /// 当用户已有活跃订阅，尝试购买不同订阅方案时，应用商店会阻止并显示系统弹窗。
  /// 此状态应静默处理，不显示额外错误弹窗。
  factory PaymentResponse.subscriptionChangeBlocked({String? message, Map<String, dynamic>? data}) {
    return PaymentResponse(
      result: PaymentResult.subscriptionChangeBlocked,
      message: message ?? '订阅变更被阻止',
      data: data,
    );
  }
}

/// 商品列表响应实现
class ProductListResponse implements IResponse<List<Map<String, dynamic>>> {
  @override
  final PaymentResult result;

  @override
  final String? message;

  @override
  final Map<String, dynamic>? data;

  final List<Map<String, dynamic>> products;

  const ProductListResponse({
    required this.result,
    required this.products,
    this.message,
    this.data,
  });

  @override
  bool get success => result == PaymentResult.success;

  @override
  bool get isFailed => result == PaymentResult.failed;

  factory ProductListResponse.success({
    required List<Map<String, dynamic>> products,
    String? message,
    Map<String, dynamic>? data,
  }) {
    return ProductListResponse(
      result: PaymentResult.success,
      products: products,
      message: message,
      data: data,
    );
  }

  factory ProductListResponse.failed({
    String? message,
    Map<String, dynamic>? data,
  }) {
    return ProductListResponse(
      result: PaymentResult.failed,
      products: [],
      message: message,
      data: data,
    );
  }
}
