import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_internal/gch_provider_registry.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_internal/gch_order_validator.dart';

/// 支付执行器
/// 职责：
/// 1. 执行各种支付操作（pay、query、refund等）
/// 2. 管理当前支付方式
/// 3. 代理调用到具体的PaymentProvider
class PaymentExecutor {
  final ProviderRegistry providerRegistry;
  final OrderValidator orderValidator;

  PayProvider? _currentMethod;

  PaymentExecutor({
    required this.providerRegistry,
    required this.orderValidator,
  });

  /// 获取当前支付方式
  PayProvider? get currentMethod => _currentMethod;

  /// 获取当前支付方式代码
  String? get currentCode {
    if (_currentMethod == null) return null;
    return _currentMethod!.code;
  }

  /// 设置当前支付方式（用枚举）
  void setPaymentMethod(PayProvider method) {
    if (!providerRegistry.contains(method)) {
      throw Exception('不支持的支付方式: ${method.name}');
    }
    _currentMethod = method;
    debugPrint('✅ 当前支付方式已设置为: ${method.name}');
  }

  /// 设置当前支付方式（用code）
  void setPaymentMethodByCode(String code) {
    final method = PayProviderExtension.fromCode(code);
    if (method == null) {
      throw Exception('不支持的支付方式: $code');
    }
    setPaymentMethod(method);
  }

  /// 获取当前Provider
  PaymentProvider? get currentProvider {
    return _currentMethod != null ? providerRegistry.get(_currentMethod!) : null;
  }

  /// 检查是否已设置当前支付方式
  void _checkMethod() {
    if (_currentMethod == null) {
      throw Exception('未设置当前支付方式，请先调用setPaymentMethod');
    }

    if (!providerRegistry.contains(_currentMethod!)) {
      throw Exception('当前支付方式未注册: ${_currentMethod!.name}');
    }
  }

  /// 获取可用的支付方式
  Future<List<PayProvider>> getAvailableMethods() async {
    final available = <PayProvider>[];

    for (final entry in providerRegistry.all.entries) {
      if (await entry.value.isAvailable()) {
        available.add(entry.key);
      }
    }

    return available;
  }

  /// 获取商品列表
  Future<IResponse<List<Map<String, dynamic>>>> getProducts([List<String>? productIds]) async {
    _checkMethod();
    final provider = currentProvider!;

    if (!await provider.isAvailable()) {
      return IResponse.failed(message: '支付方式不可用: $currentCode');
    }

    try {
      debugPrint('📦 通过$currentCode获取商品列表');
      return await provider.getProducts(productIds);
    } catch (e) {
      debugPrint('❌ 获取商品列表失败: $e');
      return IResponse.failed(message: '获取商品列表失败: $e');
    }
  }

  /// 查询订单
  Future<IResponse> query(IParams<Map<String, dynamic>> params) async {
    _checkMethod();
    final provider = currentProvider!;

    if (!await provider.isAvailable()) {
      return IResponse.failed(message: '支付方式不可用: $currentCode');
    }

    try {
      return await provider.query(params);
    } catch (e) {
      debugPrint('❌ 查询失败: $e');
      return IResponse.failed(message: '查询失败: $e');
    }
  }

  /// 取消订单
  Future<IResponse> cancelOrder(IParams<Map<String, dynamic>> params) async {
    _checkMethod();
    final provider = currentProvider!;

    if (!await provider.isAvailable()) {
      return IResponse.failed(message: '支付方式不可用: $currentCode');
    }

    try {
      return await provider.cancelorder(params);
    } catch (e) {
      debugPrint('❌ 取消订单失败: $e');
      return IResponse.failed(message: '取消订单失败: $e');
    }
  }

  /// 执行支付
  Future<IResponse> pay(IParams<Map<String, dynamic>> params) async {
    _checkMethod();

    // 订单预检查
    final paramMap = params.toMap();
    final userId = paramMap['userId']?.toString();
    final productId = paramMap['productId']?.toString();
    final productName = paramMap['productName']?.toString();
    final existingOrderId = paramMap['orderId']?.toString() ?? paramMap['orderNum']?.toString();
    final skipUnpaidCheck = paramMap['skipUnpaidCheck'] == true ||
        paramMap['skipUnpaidCheck']?.toString() == 'true';

    if (!skipUnpaidCheck && (existingOrderId == null || existingOrderId.isEmpty)) {
      final validationResult = await orderValidator.checkUnpaidOrder(
        userId: userId,
        productId: productId,
        productName: productName,
      );

      if (validationResult != null) {
        // 存在未支付订单，返回提示
        return validationResult;
      }
    }

    final provider = currentProvider!;

    // 检查可用性
    if (!await provider.isAvailable()) {
      return IResponse.failed(message: '支付方式不可用: $currentCode');
    }

    try {
      debugPrint('💳 开始执行支付，方式: $currentCode');
      return await provider.pay(params);
    } catch (e) {
      debugPrint('❌ 支付失败: $e');
      return IResponse.failed(message: '支付失败: $e');
    }
  }

  /// 验证支付
  Future<IResponse> verifyPay(IParams<Map<String, dynamic>> params) async {
    _checkMethod();
    final provider = currentProvider!;

    if (!await provider.isAvailable()) {
      return IResponse.failed(message: '支付方式不可用: $currentCode');
    }

    try {
      return await provider.verifypay(params);
    } catch (e) {
      debugPrint('❌ 验证支付失败: $e');
      return IResponse.failed(message: '验证支付失败: $e');
    }
  }

  /// 获取支付结果
  Future<IResponse> getPayResult(IParams<Map<String, dynamic>> params) async {
    _checkMethod();
    final provider = currentProvider!;

    if (!await provider.isAvailable()) {
      return IResponse.failed(message: '支付方式不可用: $currentCode');
    }

    try {
      return await provider.getPayResult(params);
    } catch (e) {
      debugPrint('❌ 获取支付结果失败: $e');
      return IResponse.failed(message: '获取支付结果失败: $e');
    }
  }

  /// 退款
  Future<IResponse> refund(IParams<Map<String, dynamic>> params) async {
    _checkMethod();
    final provider = currentProvider!;

    if (!await provider.isAvailable()) {
      return IResponse.failed(message: '支付方式不可用: $currentCode');
    }

    try {
      return await provider.refund(params);
    } catch (e) {
      debugPrint('❌ 退款失败: $e');
      return IResponse.failed(message: '退款失败: $e');
    }
  }

  /// 使用特定支付方式执行操作（不改变当前选择）
  Future<T> withPaymentMethod<T>(PayProvider method, Future<T> Function() action) async {
    final oldMethod = _currentMethod;
    try {
      setPaymentMethod(method);
      return await action();
    } finally {
      _currentMethod = oldMethod;
    }
  }

  /// 使用特定支付方式执行操作（用code）
  Future<T> withPaymentMethodCode<T>(String code, Future<T> Function() action) async {
    final method = PayProviderExtension.fromCode(code);
    if (method == null) {
      throw Exception('不支持的支付方式: $code');
    }
    return await withPaymentMethod(method, action);
  }

  /// 清除当前选择
  void clearCurrentMethod() {
    _currentMethod = null;
    debugPrint('✅ 已清除当前支付方式');
  }
}
