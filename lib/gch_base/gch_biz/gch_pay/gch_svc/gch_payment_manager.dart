import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_internal/gch_provider_registry.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_internal/gch_payment_executor.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_internal/gch_order_validator.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_internal/gch_product_cache.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_providers/gch_product_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_internal/gch_payment_event_handler.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_svc/gch_order_recovery_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 支付管理器 - 轻量Facade版本（重构后）
///
/// 职责拆分：
/// - ProviderRegistry: Provider注册与配置管理
/// - PaymentExecutor: 支付操作执行
/// - OrderValidator: 订单校验
/// - ProductCache: 产品缓存
/// - PaymentEventHandler: 事件处理
///
/// PaymentManager现在仅作为轻量协调层，负责：
/// 1. 组装各个服务组件
/// 2. 提供统一的对外接口
/// 3. 管理整体生命周期
///
/// 注意：旧版 PaymentManager 已备份为 payment_manager_legacy.dart
class PaymentManager implements Disposable {
  // 核心服务组件
  late final ProviderRegistry _providerRegistry;
  late final PaymentExecutor _executor;
  late final OrderValidator _orderValidator;
  late final ProductCache _productCache;
  late final PaymentEventHandler _eventHandler;

  // Bootstrap状态
  bool _bootstrapped = false;
  Completer<bool>? _bootstrapCompleter;

  // 订单恢复服务
  OrderRecoveryService? _recoveryService;
  Timer? _periodicTimer;

  final Ref? ref;

  PaymentManager({this.ref}) {
    _initializeComponents();
  }

  /// 初始化各个服务组件
  void _initializeComponents() {
    _providerRegistry = ProviderRegistry(ref: ref);
    _orderValidator = OrderValidator(ref: ref);

    // ✅ 使用 Provider 管理的 ProductCache（解决静态缓存污染问题）
    _productCache = ref != null
        ? ref!.read(productCacheProvider)
        : ProductCache(ref: ref);

    _eventHandler = PaymentEventHandler(ref: ref);
    _executor = PaymentExecutor(
      providerRegistry: _providerRegistry,
      orderValidator: _orderValidator,
    );
  }

  // ========== Bootstrap ==========

  /// 支付系统引导初始化
  Future<bool> bootstrap() async {
    if (_bootstrapped) {
      return true;
    }

    if (_bootstrapCompleter != null) {
      return await _bootstrapCompleter!.future;
    }

    _bootstrapCompleter = Completer<bool>();

    try {
      debugPrint('🚀 开始支付系统bootstrap...');

      // 1. 注册和初始化Provider
      await _providerRegistry.registerFromDatabase();
      await _providerRegistry.initializeAll();

      // 2. 初始化产品缓存（如果未由Provider自动初始化）
      if (!_productCache.isLoaded) {
        await _productCache.initialize();
      }

      // 3. 启动事件监听
      _eventHandler.startListening();

      // 4. 恢复未完成订单
      await _recoverOrders();

      // 5. 启动定期检查
      _startPeriodicChecks();

      _bootstrapped = true;
      debugPrint('✅ 支付系统bootstrap完成');

      _bootstrapCompleter!.complete(true);
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ 支付系统bootstrap失败: $e\n$stackTrace');
      _bootstrapCompleter!.complete(false);
      return false;
    } finally {
      _bootstrapCompleter = null;
    }
  }

  /// 恢复未完成订单
  Future<void> _recoverOrders() async {
    if (ref == null) return;

    try {
      _recoveryService = ref!.read(orderRecoveryServiceProvider);

      debugPrint('🔄 开始恢复未完成订单...');
      final result = await _recoveryService!.processIncompleteOrders();

      if (result.totalProcessed > 0) {
        debugPrint('✅ 处理了${result.totalProcessed}个未完成订单，成功: ${result.successCount}，失败: ${result.failedCount}');
        if (result.hasErrors) {
          debugPrint('⚠️ 订单恢复错误: ${result.errors}');
        }
      } else {
        debugPrint('ℹ️ 没有发现未完成的订单');
      }
    } catch (e) {
      debugPrint('❌ 处理未完成订单失败: $e');
    }
  }

  /// 启动定期检查
  void _startPeriodicChecks() {
    _recoveryService?.startPeriodicCheck(
      interval: const Duration(hours: 2),
    );
    debugPrint('✅ 定期检查已启动');
  }

  // ========== Provider管理接口 ==========

  /// 注册Provider
  void registerProvider(PayProvider method, PaymentProvider provider) {
    _providerRegistry.register(method, provider);
  }

  /// 反注册Provider
  void unregisterProvider(PayProvider method) {
    _providerRegistry.unregister(method);
  }

  /// 获取Provider
  PaymentProvider? getProvider(PayProvider method) {
    return _providerRegistry.get(method);
  }

  /// 根据code获取Provider
  PaymentProvider? getProviderByCode(String code) {
    return _providerRegistry.getByCode(code);
  }

  /// 初始化Provider（公开接口，兼容旧代码）
  Future<void> initialize(Map<String, Map<String, dynamic>> configs) async {
    // 这个方法保留用于向后兼容
    // 实际初始化在bootstrap中完成
    await _providerRegistry.initializeAll();
  }

  /// 重新加载配置
  Future<bool> reloadConfig() async {
    if (!_bootstrapped) {
      debugPrint('⚠️ 支付系统未启动，无法重新加载配置');
      return false;
    }

    try {
      // 1. 重新加载支付配置
      final success = await _providerRegistry.reload();

      if (success) {
        // 2. ✅ 清空并重新加载产品缓存
        // 重要：切账号/地区后必须清空旧数据
        await _productCache.refresh();
        debugPrint('✅ 产品缓存已刷新');
      }

      return success;
    } catch (e) {
      debugPrint('❌ 重新加载配置失败: $e');
      return false;
    }
  }

  // ========== 支付方式管理 ==========

  /// 获取当前支付方式
  PayProvider? get currentMethod => _executor.currentMethod;

  /// 获取当前支付方式代码
  String? get currentCode => _executor.currentCode;

  /// 设置支付方式（用枚举）
  void setPaymentMethod(PayProvider method) {
    _executor.setPaymentMethod(method);
  }

  /// 设置支付方式（用code）
  void setPaymentMethodByCode(String code) {
    _executor.setPaymentMethodByCode(code);
  }

  /// 获取当前Provider
  PaymentProvider? get currentProvider => _executor.currentProvider;

  /// 获取可用的支付方式
  Future<List<PayProvider>> getAvailableMethods() async {
    if (!_bootstrapped) {
      await bootstrap();
    }
    return await _executor.getAvailableMethods();
  }

  // ========== 支付操作接口 ==========

  /// 获取商品列表
  Future<IResponse<List<Map<String, dynamic>>>> getProducts([List<String>? productIds]) async {
    return await _executor.getProducts(productIds);
  }

  /// 查询
  Future<IResponse> query(IParams<Map<String, dynamic>> params) async {
    return await _executor.query(params);
  }

  /// 取消订单
  Future<IResponse> cancelorder(IParams<Map<String, dynamic>> params) async {
    return await _executor.cancelOrder(params);
  }

  /// 执行支付
  Future<IResponse> pay(IParams<Map<String, dynamic>> params) async {
    return await _executor.pay(params);
  }

  /// 验证支付
  Future<IResponse> verifypay(IParams<Map<String, dynamic>> params) async {
    return await _executor.verifyPay(params);
  }

  /// 获取支付结果
  Future<IResponse> getPayResult(IParams<Map<String, dynamic>> params) async {
    return await _executor.getPayResult(params);
  }

  /// 退款
  Future<IResponse> refund(IParams<Map<String, dynamic>> params) async {
    return await _executor.refund(params);
  }

  /// 使用特定支付方式执行操作（不改变当前选择）
  Future<T> withPaymentMethod<T>(PayProvider method, Future<T> Function() action) async {
    return await _executor.withPaymentMethod(method, action);
  }

  /// 使用特定支付方式执行操作（用code）
  Future<T> withPaymentMethodCode<T>(String code, Future<T> Function() action) async {
    return await _executor.withPaymentMethodCode(code, action);
  }

  // ========== 产品缓存接口 ==========

  /// 获取产品（静态方法，向后兼容）
  static ProductEntry? getProduct(String productId) {
    // 这需要访问实例的_productCache，暂时保留旧的静态访问方式
    // 建议逐步迁移到实例方法
    return null; // TODO: 需要重构调用方
  }

  /// 获取产品（实例方法）
  ProductEntry? getProductById(String productId) {
    return _productCache.get(productId);
  }

  /// 检查产品是否存在
  bool hasProduct(String productId) {
    return _productCache.contains(productId);
  }

  /// 获取所有产品
  Map<String, ProductEntry> get products => _productCache.all;

  // ========== 生命周期管理 ==========

  @override
  void dispose() {
    debugPrint('🗑️ 开始销毁PaymentManager...');

    // 停止定期检查
    _periodicTimer?.cancel();
    _recoveryService?.dispose();

    // 销毁各个服务组件
    _eventHandler.dispose();
    _productCache.clear();
    _providerRegistry.dispose();

    // ⚠️ 注意：不销毁PaymentEventBus单例
    // PaymentEventBus是全局基础设施，生命周期由应用级别管理
    // PaymentManager只是订阅者之一，销毁时只取消自己的订阅即可
    // 实际的订阅取消由_eventHandler.dispose()完成

    // 重置状态
    _bootstrapped = false;
    _bootstrapCompleter = null;

    debugPrint('✅ PaymentManager已完全销毁');
  }
}
