// 应用内购买提供者抽象基类
// 包含 iOS 和 Android 共享的逻辑，使用模板方法模式

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_core/gch_net_guard.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_event_bus.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_vm/gch_order_manager.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_bankendapi/gch_pay_api.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_providers/gch_product_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_model/gch_product_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_svc/gch_order_converter.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'gch_in_app_purchase_models.dart';
import 'gch_purchase_error_handler.dart';
import 'gch_in_app_purchase_callback.dart';
import '../gch_ios/gch_storekit2_helper.dart' as ios_helper;
import 'package:guichao/gch_base/gch_umeng/gch_umeng_svc.dart';

/// 应用内购买提供者抽象基类
///
/// 使用模板方法模式，将平台无关的逻辑放在基类中，
/// 平台特定的逻辑由子类实现。
abstract class InAppPurchaseProviderBase
    implements PaymentProvider<Map<String, dynamic>, Map<String, dynamic>> {
  // ==================== 共享状态 ====================
  final Ref? ref;
  InAppPurchase? _inAppPurchase;
  InAppPurchase? get inAppPurchase => _inAppPurchase;

  bool _initialized = false;
  bool _isAvailable = false;
  bool _isReady = false;

  /// 最后一次初始化结果
  StoreInitResult _lastInitResult =
      const StoreInitResult(success: true);
  StoreInitResult get lastInitResult => _lastInitResult;

  /// 检查支付是否可用（考虑网络/服务错误）
  bool get isStoreAvailable =>
      _isAvailable && _isReady && !_lastInitResult.isNetworkOrServiceError;

  // 产品详情缓存
  final Map<String, ProductDetails> _productDetailsCache = {};
  Map<String, ProductDetails> get productDetailsCache => _productDetailsCache;

  // 回调管理
  final Map<CallbackType, StreamCallback> _callbacks = {};

  /// 获取支付回调（供子类使用）
  @protected
  InAppPurchaseCallback? get paymentCallback {
    final callback = _callbacks[CallbackType.payment];
    return callback is InAppPurchaseCallback ? callback : null;
  }

  // 配置项
  List<String> _productIds = [];

  // 正在验证中的购买ID集合（防止竞态条件）
  final Set<String> _verifyingPurchaseIds = {};

  // 恢复购买阶段标记
  bool _isInitRestorePhase = false;
  bool get isInitRestorePhase => _isInitRestorePhase;

  // ==================== 抽象属性 ====================

  /// 平台名称 ('ios' 或 'android')
  String get platformName;

  /// 网关显示名称 ('App Store')
  String get gatewayDisplayName;

  // ==================== 抽象方法 (平台特定实现) ====================

  /// 平台特定初始化
  Future<void> initializePlatform();

  /// 平台特定的购买资格检查
  Future<PurchaseEligibility> checkPlatformEligibility(String productId);

  /// 构建平台特定的购买参数
  Future<PurchaseParam> buildPurchaseParam({
    required ProductDetails productDetails,
    required String orderId,
    required InAppPurchaseParams inAppParams,
  });

  /// 平台特定的验证数据构建（异步，支持Android动态获取包名）
  Future<Map<String, dynamic>> buildVerifyData(
      PurchaseDetails purchase, Map<String, dynamic> baseData);

  /// 平台特定的查询实现
  Future<IResponse<Map<String, dynamic>>> queryPlatform(
      Map<String, dynamic> params);

  /// 平台特定的待处理购买检查
  Future<void> checkPendingPurchasesPlatform();

  /// 平台特定的订阅状态查询
  Future<IResponse<Map<String, dynamic>>> querySubscriptionStatusPlatform();

  /// 从数据库创建平台特定的 ProductDetails
  ProductDetails? createProductDetailsFromDb(ProductEntry productEntry);

  /// 平台特定的资源释放
  void disposePlatform();

  /// 平台特定的验证失败后处理
  /// iOS: 必须完成交易，避免 StoreKit 无限循环返回
  /// Android: 保留交易，让应用商店自动退款或用户重试
  Future<void> handleVerificationFailurePlatform(PurchaseDetails purchase);

  // ==================== 构造函数 ====================

  InAppPurchaseProviderBase({this.ref}) {
    _callbacks[CallbackType.payment] = InAppPurchaseCallback();
  }

  // ==================== PaymentProvider 接口实现 ====================

  @override
  PayProvider get method => PayProvider.inAppPurchase;

  @override
  bool get requiresSdk => true;

  @override
  Set<CallbackType> getSupportedCallbackTypes() => _callbacks.keys.toSet();

  @override
  Stream<IResponse>? resultStream(CallbackType type) =>
      _callbacks[type]?.onResult();

  // ==================== 初始化 ====================

  @override
  Future<bool> initialize(Map<String, dynamic> config) async {
    if (_initialized) return _isReady;

    try {
      _productIds =
          (config['productIds'] as List<dynamic>?)?.cast<String>() ?? [];

      // 安全地初始化 InAppPurchase.instance
      try {
        _inAppPurchase = InAppPurchase.instance;
        debugPrint('✅ InAppPurchase.instance 初始化成功');
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        debugPrint('❌ InAppPurchase.instance 初始化失败: $e');
        _lastInitResult = _parseInitError(errorStr, e.toString());
        _initialized = true;
        _isReady = false;
        return false;
      }

      // 平台特定初始化
      await initializePlatform();

      // 检测平台可用性
      if (GchNucleus.isDevMode) {
        debugPrint('🛠️ 调试模式：强制启用$gatewayDisplayName支付选项（用于调试）');
        _isAvailable = true;
      } else {
        try {
          _isAvailable = await _inAppPurchase!.isAvailable();
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          debugPrint('❌ 检查可用性时出错: $e');
          _lastInitResult = _parseInitError(errorStr, e.toString());
          _isAvailable = false;
        }
      }

      debugPrint('InAppPurchase 可用性: $_isAvailable');
      if (!_isAvailable) {
        debugPrint('应用内购买服务不可用');
        if (_lastInitResult.success) {
          _lastInitResult = StoreInitResult.failed(
            StoreInitError.serviceUnavailable,
            '$gatewayDisplayName服务不可用',
          );
        }
        _initialized = true;
        _isReady = false;
        return false;
      }

      // 初始化回调处理
      for (final cb in _callbacks.values) {
        cb.initialize();
      }

      // 监听验证事件
      _listenVerifyEvent();

      // 预加载产品
      if (_productIds.isNotEmpty) {
        debugPrint('🔄 开始预加载产品: $_productIds');
        await _loadProducts();
      }

      // 检查未确认的购买
      await _checkPendingPurchases();

      _initialized = true;
      _isReady = true;
      debugPrint('应用内购买初始化成功');
      return true;
    } catch (e, s) {
      debugPrint('应用内购买初始化失败: $e\n$s');
      final errorStr = e.toString().toLowerCase();
      _lastInitResult = _parseInitError(errorStr, e.toString());
      _initialized = true;
      _isReady = false;
      return false;
    }
  }

  /// 解析初始化错误
  StoreInitResult _parseInitError(String errorStr, String originalError) {
    if (isNetworkError(errorStr)) {
      debugPrint('📌 初始化错误类型: 网络错误');
      return StoreInitResult.failed(
        StoreInitError.networkError,
        '网络连接失败，无法连接$gatewayDisplayName服务',
        originalError,
      );
    }

    if (isServiceUnavailableError(errorStr) ||
        errorStr.contains('app store is not available')) {
      debugPrint('📌 初始化错误类型: 服务不可用');
      return StoreInitResult.failed(
        StoreInitError.serviceUnavailable,
        '$gatewayDisplayName服务不可用',
        originalError,
      );
    }

    if (isTimeoutError(errorStr)) {
      debugPrint('📌 初始化错误类型: 服务超时');
      return StoreInitResult.failed(
        StoreInitError.serviceTimeout,
        '连接$gatewayDisplayName服务超时',
        originalError,
      );
    }

    if (isServiceDisconnectedError(errorStr)) {
      debugPrint('📌 初始化错误类型: 服务断开');
      return StoreInitResult.failed(
        StoreInitError.serviceDisconnected,
        '$gatewayDisplayName服务连接已断开',
        originalError,
      );
    }

    if (errorStr.contains('billing') && errorStr.contains('unavailable')) {
      debugPrint('📌 初始化错误类型: Billing服务不可用');
      return StoreInitResult.failed(
        StoreInitError.billingUnavailable,
        '$gatewayDisplayName Billing服务不可用',
        originalError,
      );
    }

    debugPrint('📌 初始化错误类型: 未知');
    return StoreInitResult.failed(
      StoreInitError.unknown,
      '初始化失败',
      originalError,
    );
  }

  // ==================== 可用性检查 ====================

  @override
  Future<bool> isAvailable() async {
    if (!_initialized) {
      return false;
    }

    // 检查网络/服务错误
    if (_lastInitResult.isNetworkOrServiceError) {
      return false;
    }

    return _isAvailable && _isReady;
  }

  /// 检查网关可达性
  @override
  Future<String?> checkGatewayReachability() async {
    final host = platformName == 'ios' ? 'apple.com' : 'play.google.com';
    final stopwatch = Stopwatch()..start();
    try {
      final result = await GchNetGuard.probeHost(host);
      stopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] gateway reachability finished in '
        '${stopwatch.elapsedMilliseconds}ms '
        '(host=$host, reachable=$result)',
      );
      return result ? null : '无法连接到 $gatewayDisplayName';
    } catch (e) {
      stopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] gateway reachability failed after '
        '${stopwatch.elapsedMilliseconds}ms '
        '(host=$host, error=$e)',
      );
      return '检查网关可达性失败: $e';
    }
  }

  /// 获取详细的可用性状态
  Future<IResponse<Map<String, dynamic>>> getAvailabilityStatus() async {
    final data = <String, dynamic>{
      'initialized': _initialized,
      'isAvailable': _isAvailable,
      'isReady': _isReady,
      'lastInitResult': {
        'success': _lastInitResult.success,
        'error': _lastInitResult.error.name,
        'errorMessage': _lastInitResult.errorMessage,
        'errorDetails': _lastInitResult.errorDetails,
        'isNetworkOrServiceError': _lastInitResult.isNetworkOrServiceError,
      },
      'platform': platformName,
      'gateway': gatewayDisplayName,
    };

    if (!_initialized) {
      return PaymentResponse.failed(
        message: '支付服务未初始化',
        data: data,
      );
    }

    if (_lastInitResult.isNetworkOrServiceError) {
      return PaymentResponse.failed(
        message: _lastInitResult.errorMessage ?? '$gatewayDisplayName服务不可用',
        data: data,
      );
    }

    if (!_isAvailable || !_isReady) {
      return PaymentResponse.failed(
        message: '$gatewayDisplayName不可用',
        data: data,
      );
    }

    return PaymentResponse.success(
      message: '$gatewayDisplayName可用',
      data: data,
    );
  }

  // ==================== 购买资格检查 ====================

  /// 检查商品是否可以订阅购买
  Future<PurchaseEligibility> checkPurchaseEligibility(String productId) async {
    if (!await isAvailable()) {
      return PurchaseEligibility.storeUnavailable;
    }

    // 检查产品是否存在
    final productDetails = await _fetchProductDetails(productId);
    if (productDetails == null) {
      return PurchaseEligibility.productNotFound;
    }

    // 平台特定的资格检查
    return checkPlatformEligibility(productId);
  }

  /// 快速检查是否可以购买（简化版本）
  Future<bool> canPurchaseProduct(String productId) async {
    final eligibility = await checkPurchaseEligibility(productId);
    return eligibility == PurchaseEligibility.canPurchase ||
        eligibility == PurchaseEligibility.canUpgradeOrDowngrade;
  }

  /// 预取商店商品详情到内存缓存，避免点击支付时再实时查询。
  Future<void> prefetchProducts(Iterable<String> productIds) async {
    final ids = productIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && !_productDetailsCache.containsKey(id))
        .toSet();

    if (ids.isEmpty) {
      debugPrint(
        'ℹ️ [IAP:$gatewayDisplayName] prefetchProducts skipped '
        '(all cached or empty)',
      );
      return;
    }

    if (_inAppPurchase == null) {
      debugPrint(
        '⚠️ [IAP:$gatewayDisplayName] prefetchProducts skipped '
        '(store not initialized, ids=$ids)',
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _inAppPurchase!.queryProductDetails(ids);
      for (final details in response.productDetails) {
        _productDetailsCache[details.id] = details;
      }
      stopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] prefetchProducts finished in '
        '${stopwatch.elapsedMilliseconds}ms '
        '(requested=${ids.length}, loaded=${response.productDetails.length}, '
        'notFound=${response.notFoundIDs.length}, ids=$ids)',
      );
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          '⚠️ [IAP:$gatewayDisplayName] prefetchProducts not found: '
          '${response.notFoundIDs}',
        );
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] prefetchProducts failed after '
        '${stopwatch.elapsedMilliseconds}ms '
        '(requested=${ids.length}, ids=$ids, error=$e)',
      );
    }
  }

  // ==================== 预支付 ====================

  @override
  Future<IResponse<Map<String, dynamic>>> PrePay(
      IParams<Map<String, dynamic>> params) async {
    debugPrint('📦 [PrePay] 收到预支付请求');
    final stopwatch = Stopwatch()..start();

    try {
      if (ref == null) return PaymentResponse.failed(message: '依赖不可用');

      final payload = _parsePrepayPayload(params.toMap());
      await _cancelExistingUnpaidOrderIfNeededV2(payload);

      final request = _buildPaymentRequest(payload);
      debugPrint('PrePay请求参数: ${request.toJson()}');

      final api = ref!.read(payApiProvider);
      final apiStopwatch = Stopwatch()..start();
      final result = await api.Pay(request: request);
      apiStopwatch.stop();
      debugPrint(
        '⏱️ [PrePay] api.Pay finished in '
        '${apiStopwatch.elapsedMilliseconds}ms '
        '(productCode=${payload.productCode}, amount=${payload.amount})',
      );

      final response = await result.fold(
        (err) async => PaymentResponse.failed(message: err),
        (resp) async => _handlePrepaySuccess(resp, payload),
      );
      stopwatch.stop();
      debugPrint(
        '⏱️ [PrePay] total finished in '
        '${stopwatch.elapsedMilliseconds}ms '
        '(result=${response.result}, productCode=${payload.productCode})',
      );
      return response;
    } on PrepayValidationException catch (e) {
      stopwatch.stop();
      debugPrint(
        '⏱️ [PrePay] validation failed after '
        '${stopwatch.elapsedMilliseconds}ms '
        '(error=${e.message})',
      );
      return PaymentResponse.failed(message: e.message);
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint(
        '⏱️ [PrePay] failed after ${stopwatch.elapsedMilliseconds}ms '
        '(error=$e)',
      );
      debugPrint('PrePay异常: $e');
      debugPrint(stackTrace.toString());
      return PaymentResponse.failed(message: '后端下单异常: $e');
    }
  }

  /// 解析预支付参数
  PrepayPayload _parsePrepayPayload(Map<String, dynamic> params) {
    final amount =
        _toDouble(params['amount']) ?? _toDouble(params['rawPrice']);
    if (amount == null) {
      throw const PrepayValidationException('参数不足：缺少支付金额');
    }

    final productNumericId = _parseInt(params['id']);
    if (productNumericId == null) {
      throw const PrepayValidationException('参数不足：缺少产品ID');
    }

    // 负数 ID 表示 IAP-only 产品（合成 ID），此时必须有 productCode
    // 以便后端通过 product_code 解析出真实 ProductID
    if (productNumericId <= 0) {
      final productCode = _stringOrNull(params['productId']) ??
          _stringOrNull(params['product_id']) ??
          _stringOrNull(params['productCode']);
      if (productCode == null || productCode.isEmpty) {
        throw const PrepayValidationException(
            '参数不足：IAP产品缺少 productCode');
      }
    }

    final currency =
        _stringOrDefault(params['currency'] ?? params['currencyCode'], 'USD');
    final subject = _stringOrDefault(
        params['subject'] ?? params['title'], 'In-App Purchase');
    final description =
        _stringOrDefault(params['description'], 'In-App Purchase');
    final notifyUrl = _stringOrDefault(params['notifyUrl'], '');
    final returnUrl = _stringOrDefault(params['returnUrl'], '');
    final clientIp = _stringOrDefault(params['clientIp'], '0.0.0.0');
    final timeout = _parseInt(params['timeoutSeconds']) ?? 300;

    final extendParams = Map<String, dynamic>.from(params);

    return PrepayPayload(
      amount: amount,
      currency: currency,
      subject: subject,
      description: description,
      notifyUrl: notifyUrl,
      returnUrl: returnUrl,
      clientIp: clientIp,
      timeoutSeconds: timeout,
      productNumericId: productNumericId,
      extendParams: extendParams,
      userId: _stringOrNull(params['userId']),
      productCode: _stringOrNull(params['productId']) ??
          _stringOrNull(params['product_id']) ??
          _stringOrNull(params['productCode']),
      appId: _stringOrNull(params['appId']),
    );
  }

  /// 取消已存在的未支付订单 (V2版本，使用PrepayPayload)
  Future<void> _cancelExistingUnpaidOrderIfNeededV2(PrepayPayload payload) async {
    final userId = payload.userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    if (ref == null) {
      return;
    }

    try {
      final orderManager = ref!.read(orderManagerProvider.notifier);
      debugPrint('🔍 检查用户 $userId 的产品 ${payload.productNumericId} 是否有未支付订单...');
      final unpaidOrder =
          await orderManager.getUnpaidOrder(userId, payload.productNumericId);

      if (unpaidOrder == null) {
        debugPrint('✅ 未发现未支付订单，可以继续创建新订单');
        return;
      }

      final orderAge = DateTime.now().difference(unpaidOrder.createAt);
      final expiredByStatus =
          unpaidOrder.status == OrderStatus.expired.value;
      final expiredByTime =
          unpaidOrder.expireAt != null &&
          unpaidOrder.expireAt!.isBefore(DateTime.now());
      final isLocallyExpired =
          expiredByStatus ||
          expiredByTime ||
          orderAge >= const Duration(minutes: 10);
      if (isLocallyExpired) {
        debugPrint(
          'ℹ️ 旧未支付订单已过期，跳过远程取消: '
          '${unpaidOrder.orderNum} (age=${orderAge.inSeconds}s)',
        );
        try {
          await orderManager.deleteOrder(unpaidOrder.orderNum);
          debugPrint('✅ 已删除过期本地订单: ${unpaidOrder.orderNum}');
        } catch (e) {
          debugPrint('⚠️ 删除过期本地订单失败: $e');
        }
        return;
      }

      final orderNum = unpaidOrder.orderNum;
      debugPrint('⚠️ 发现未支付订单: $orderNum，准备取消...');

      final api = ref!.read(payApiProvider);
      final cancelResult = await api.cancelOrder(
        orderId: orderNum,
        reason: 'user_initiated_new_purchase',
        productId: payload.productNumericId.toString(),
      );

      await cancelResult.fold(
        (error) async {
          debugPrint('⚠️ 取消旧订单失败: $error（继续创建新订单）');
        },
        (_) async {
          debugPrint('✅ 成功取消旧订单: $orderNum');
          try {
            await orderManager.deleteOrder(orderNum);
            debugPrint('✅ 本地订单已删除: $orderNum');
          } catch (e) {
            debugPrint('⚠️ 删除本地订单失败: $e');
          }
        },
      );
    } catch (e) {
      debugPrint('⚠️ 检查/取消未支付订单异常: $e（继续创建新订单）');
    }
  }

  /// 构建支付请求
  PaymentRequest _buildPaymentRequest(PrepayPayload payload) {
    // 负数 ID 是 IAP-only 合成 ID，不传给后端（传 0）
    // 后端会通过 product_code 自动解析出真实 ProductID
    final effectiveId =
        payload.productNumericId > 0 ? payload.productNumericId : 0;
    return PaymentRequest(
      id: effectiveId,
      orderId: '',
      amount: payload.amount,
      currency: payload.currency,
      subject: payload.subject,
      description: payload.description,
      method: platformName == 'android'
          ? PaymentMethod.googlePay
          : PaymentMethod.applePay,
      notifyUrl: payload.notifyUrl,
      returnUrl: payload.returnUrl,
      clientIp: payload.clientIp,
      timeout: payload.timeoutSeconds,
      appId: payload.appId,
      userId: payload.userId,
      productId: payload.productCode,
      extendParams: payload.extendParams,
    );
  }

  /// 处理预支付成功
  Future<IResponse<Map<String, dynamic>>> _handlePrepaySuccess(
    PaymentApiResponse response,
    PrepayPayload payload,
  ) async {
    String? backendOrderId;
    final paymentInfo = response.paymentInfo;

    if (paymentInfo is Map<String, dynamic>) {
      final normalizedInfo = Map<String, dynamic>.from(paymentInfo);

      final responseProductCode =
          normalizedInfo['product_code'] ?? normalizedInfo['productCode'];
      final payloadProductCode = payload.productCode;

      final currentStoreProductId =
          normalizedInfo['store_product_id'] ?? normalizedInfo['storeProductId'];

      final effectiveStoreProductId =
          currentStoreProductId ?? payloadProductCode ?? responseProductCode;

      if (effectiveStoreProductId != null) {
        normalizedInfo['store_product_id'] = effectiveStoreProductId.toString();
      }

      backendOrderId = normalizedInfo['orderNum']?.toString() ??
          normalizedInfo['orderId']?.toString();

      // 保存订单到本地数据库
      if (ref != null) {
        try {
          final order = OrderConverter.fromServerJson(
            normalizedInfo,
            defaultUserId: payload.userId,
            defaultProductId: payload.productNumericId,
            defaultAmount: response.amount,
            defaultCurrency: response.currency,
            defaultProductName: payload.subject,
            defaultPlatform: 'app_store',
            defaultClientIp: payload.clientIp,
            defaultPayProvider: 3,
            defaultOrderType: OrderType.subscription.value,
          );
          final orderManager = ref!.read(orderManagerProvider.notifier);
          await orderManager.upsertOrder(order);
          debugPrint('✅ 订单已保存到本地数据库: ${order.orderNum}');
        } catch (e) {
          debugPrint('IAP backendPay: 订单转换/保存失败: $e');
        }
      }
    }

    final responseData = response.toJson();
    responseData['orderId'] = backendOrderId ?? response.orderId;

    debugPrint('✅ [PrePay] 订单创建成功: ${responseData['orderId']}');

    return PaymentResponse.success(
      message: '后端下单成功',
      data: responseData,
    );
  }

  // ==================== 辅助方法 ====================

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  String _stringOrDefault(dynamic value, String fallback) {
    return _stringOrNull(value) ?? fallback;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  // ==================== 支付 ====================

  @override
  Future<IResponse<Map<String, dynamic>>> pay(
      IParams<Map<String, dynamic>> params) async {
    debugPrint('💳 [pay] 收到支付请求');
    final totalStopwatch = Stopwatch()..start();

    try {
      final availabilityStopwatch = Stopwatch()..start();
      final available = await isAvailable();
      availabilityStopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] isAvailable finished in '
        '${availabilityStopwatch.elapsedMilliseconds}ms '
        '(available=$available)',
      );
      if (!available) {
        totalStopwatch.stop();
        return PaymentResponse.failed(
          message: '$gatewayDisplayName不可用',
          data: {'errorType': 'store_unavailable'},
        );
      }

      final inAppParams = _convertParams(params);
      if (inAppParams == null) {
        return PaymentResponse.failed(message: '参数转换失败');
      }

      // 🍎 平台特定的订阅预检查（iOS 使用 StoreKit 2 精确检查）
      // ⚠️ 重要：必须在 _prepareOrder 之前执行！
      // - 同一产品已订阅 → 直接返回 "已订阅" 提示，避免不必要的后端调用
      // - 不同产品（升级/降级）→ 继续购买流程
      // - iOS: App Store 有自己的订阅管理机制
      final eligibilityStopwatch = Stopwatch()..start();
      final eligibility = await checkPlatformEligibility(inAppParams.productId);
      eligibilityStopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] eligibility check finished in '
        '${eligibilityStopwatch.elapsedMilliseconds}ms '
        '(product=${inAppParams.productId}, eligibility=$eligibility)',
      );
      if (eligibility == PurchaseEligibility.alreadySubscribed) {
        debugPrint('🔔 [pay] 用户已订阅该产品: ${inAppParams.productId}');

        // 发送 already_subscribed 事件
        final eventContext = StreamCallback.extractEventContext(params.toMap());
        PaymentEventBus.instance.publish(PaymentEvent(
          PaymentEventType.custom,
          data: {
            'action': 'already_subscribed',
            'productId': inAppParams.productId,
            ...eventContext,
          },
        ));

        // 发送 cancelled 事件
        PaymentEventBus.instance.publish(PaymentEvent(
          PaymentEventType.cancelled,
          data: {
            'reason': 'already_subscribed',
            'productId': inAppParams.productId,
          },
        ));

        totalStopwatch.stop();
        return PaymentResponse.alreadyOwned(
          message: '您已订阅此商品',
          data: {
            'error': 'ALREADY_SUBSCRIBED',
            'productId': inAppParams.productId,
          },
        );
      }

      // 🔑 设置初始上下文（与备份保持一致）
      final callback = _callbacks[CallbackType.payment];
      callback?.setPendingContext(StreamCallback.extractEventContext(params.toMap()));

      // 🔑 关键步骤：调用 _prepareOrder 创建后端订单并获取订单号
      final prepareOrderStopwatch = Stopwatch()..start();
      final prepayResult = await _prepareOrder(params, inAppParams);
      prepareOrderStopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] prepareOrder finished in '
        '${prepareOrderStopwatch.elapsedMilliseconds}ms '
        '(orderId=${prepayResult.orderId}, productId=${prepayResult.productId})',
      );

      // ✅ 校验 productId 有效性（提前暴露问题）
      if (prepayResult.productId.isEmpty) {
        totalStopwatch.stop();
        throw PaymentException(
          'INVALID_PRODUCT_ID',
          '无法获取有效的商品ID\n'
          '请检查：\n'
          '1. 后端是否正确返回 payment_info.storeproductid\n'
          '2. 客户端传递的 productId 是否有效\n'
          '3. 网络请求是否成功',
          {
            'prepayOrderId': prepayResult.orderId,
            'originalProductId': inAppParams.productId,
          },
        );
      }

      final orderId = prepayResult.orderId;
      final effectiveProductId = prepayResult.productId;

      debugPrint('🔍 [pay] 订单ID: $orderId, 产品ID: $effectiveProductId');

      if (orderId == null || orderId.isEmpty) {
        debugPrint('❌ [pay] 失败: PrePay未返回有效订单号');
        totalStopwatch.stop();
        return PaymentResponse.failed(
          message: '创建订单失败，请稍后重试',
          data: {'error': 'PREPAY_NO_ORDER_ID'},
        );
      }

      // 获取产品详情（使用后端返回的 effectiveProductId）
      debugPrint('🔍 [pay] 正在获取产品详情: $effectiveProductId');
      final fetchProductDetailsStopwatch = Stopwatch()..start();
      final productDetails = await _fetchProductDetails(effectiveProductId);
      fetchProductDetailsStopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] fetchProductDetails finished in '
        '${fetchProductDetailsStopwatch.elapsedMilliseconds}ms '
        '(productId=$effectiveProductId, found=${productDetails != null})',
      );
      if (productDetails == null) {
        debugPrint('❌ [pay] 失败: 产品不存在 $effectiveProductId');
        totalStopwatch.stop();
        return PaymentResponse.failed(
          message: '产品不存在: $effectiveProductId',
        );
      }
      debugPrint('✅ [pay] 产品详情获取成功: ${productDetails.title}');

      // 构建购买参数
      final buildPurchaseParamStopwatch = Stopwatch()..start();
      final purchaseParam = await buildPurchaseParam(
        productDetails: productDetails,
        orderId: orderId,
        inAppParams: inAppParams,
      );
      buildPurchaseParamStopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] buildPurchaseParam finished in '
        '${buildPurchaseParamStopwatch.elapsedMilliseconds}ms '
        '(productId=$effectiveProductId)',
      );

      // 记录购买上下文
      _logPurchaseContext(orderId, inAppParams, productDetails);

      // 🍎 iOS: 精确检查是否为同组订阅变更（升级/降级）
      // 如果是同组订阅变更，更新上下文以便验证成功后显示正确提示
      if (platformName == 'ios' && eligibility == PurchaseEligibility.canUpgradeOrDowngrade) {
        if (callback != null) {
          final groupCheckResult = await _checkiOSSubscriptionGroup(productDetails);
          if (groupCheckResult['isSameGroup'] == true) {
            final context = Map<String, dynamic>.from(callback.getPendingContext() ?? {});
            context['isSubscriptionGroupChange'] = true;
            context['existingProductId'] = groupCheckResult['existingProductId'];
            callback.setPendingContext(context);
            debugPrint('📊 [pay] iOS 同组订阅变更: 现有订阅=${groupCheckResult['existingProductId']}');
          }
        }
      }

      // 启动购买流程
      bool purchaseStarted;
      try {
        final startPurchaseFlowStopwatch = Stopwatch()..start();
        purchaseStarted = await _startPurchaseFlow(
          productDetails: productDetails,
          purchaseParam: purchaseParam,
        );
        startPurchaseFlowStopwatch.stop();
        debugPrint(
          '⏱️ [IAP:$gatewayDisplayName] startPurchaseFlow finished in '
          '${startPurchaseFlowStopwatch.elapsedMilliseconds}ms '
          '(productId=$effectiveProductId, purchaseStarted=$purchaseStarted)',
        );
      } on UserCancelledException {
        // 用户取消购买
        debugPrint('📌 [pay] 用户取消了购买');
        totalStopwatch.stop();
        PaymentEventBus.instance.publish(PaymentEvent(
          PaymentEventType.cancelled,
          orderId: orderId,
          data: {
            'productId': effectiveProductId,
            'reason': 'user_cancelled',
          },
        ));
        return PaymentResponse.cancelled(
          message: '您已取消支付',
          data: {
            'productId': effectiveProductId,
            'orderId': orderId,
          },
        );
      }

      if (!purchaseStarted) {
        totalStopwatch.stop();
        return PaymentResponse.failed(
          message: '无法启动购买流程，请检查:\n1. 是否登录了账号\n2. 是否有有效的支付方式\n3. 网络连接是否正常',
          data: {
            'productId': effectiveProductId,
            'purchaseType': inAppParams.purchaseType,
          },
        );
      }

      // ✅ 支付弹窗已成功显示，发送事件通知
      PaymentEventBus.instance.publish(PaymentEvent(
        PaymentEventType.dialogShown,
        orderId: orderId,
        data: {
          'productId': productDetails.id,
          'message': '支付弹窗已显示',
        },
      ));
      debugPrint('✅ 支付弹窗已成功显示，已发送dialogShown事件');
      totalStopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] total time to dialogShown: '
        '${totalStopwatch.elapsedMilliseconds}ms '
        '(orderId=$orderId, productId=$effectiveProductId)',
      );

      return PaymentResponse.processing(
        message: '购买流程已启动，请在弹出的界面完成支付',
        data: {
          'productId': productDetails.id,
          'orderId': orderId,
          'purchaseStarted': purchaseStarted,
          'productTitle': productDetails.title,
          'productPrice': productDetails.price,
        },
      );
    } catch (e, s) {
      debugPrint('❌ [pay] 支付异常: $e\n$s');
      totalStopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] pay failed after '
        '${totalStopwatch.elapsedMilliseconds}ms '
        '(error=$e)',
      );
      return PaymentResponse.failed(message: '支付失败: $e');
    }
  }

  /// 获取产品详情
  Future<ProductDetails?> _fetchProductDetails(String productId) async {
    // 先检查缓存
    if (_productDetailsCache.containsKey(productId)) {
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] product details cache hit '
        '(productId=$productId)',
      );
      return _productDetailsCache[productId];
    }

    // 从商店查询
    final queryStopwatch = Stopwatch()..start();
    try {
      final response = await _inAppPurchase!.queryProductDetails({productId});
      queryStopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] queryProductDetails finished in '
        '${queryStopwatch.elapsedMilliseconds}ms '
        '(productId=$productId, found=${!response.notFoundIDs.contains(productId) && response.productDetails.isNotEmpty})',
      );
      if (response.notFoundIDs.contains(productId)) {
        debugPrint('⚠️ 产品未找到: $productId');
        return null;
      }

      if (response.productDetails.isNotEmpty) {
        final details = response.productDetails.first;
        _productDetailsCache[productId] = details;
        return details;
      }
    } catch (e) {
      queryStopwatch.stop();
      debugPrint(
        '⏱️ [IAP:$gatewayDisplayName] queryProductDetails failed after '
        '${queryStopwatch.elapsedMilliseconds}ms '
        '(productId=$productId, error=$e)',
      );
      debugPrint('❌ 查询产品详情失败: $e');
    }

    return null;
  }

  /// 准备订单：调用后端 PrePay API 创建订单并获取订单号
  ///
  /// 这是支付流程的关键步骤：
  /// 1. 调用 PrePay 创建后端订单
  /// 2. 从响应中提取 orderId 和 storeProductId
  /// 3. 返回 PrepayResult 供后续购买流程使用
  Future<PrepayResult> _prepareOrder(
    IParams<Map<String, dynamic>> params,
    InAppPurchaseParams inAppParams,
  ) async {
    debugPrint('📦 [_prepareOrder] 准备订单...');
    final prepareOrderStopwatch = Stopwatch()..start();

    final response = await PrePay(params);
    var orderId = inAppParams.extraParams?['orderId']?.toString();
    var productId = inAppParams.productId;
    final data = response.data;

    if (response.result == PaymentResult.success && data != null) {
      // 从响应中提取订单号
      orderId = data['order_num']?.toString() ??
          data['order_id']?.toString() ??
          data['ordernum']?.toString() ??
          data['orderId']?.toString() ??
          orderId;
      debugPrint('✅ [_prepareOrder] PrePay成功，获得订单ID: $orderId');

      // 从 payment_info 中提取 storeproductid
      String? serverStorePid;
      final paymentInfo = data['payment_info'];

      if (paymentInfo is Map<String, dynamic>) {
        // 尝试从 payment_info 中获取 storeproductid（全小写）或 storeProductId（驼峰命名）
        serverStorePid = paymentInfo['storeproductid']?.toString() ??
            paymentInfo['storeProductId']?.toString() ??
            paymentInfo['store_product_id']?.toString();
        debugPrint('📦 [_prepareOrder] 从 payment_info 提取 storeproductid: $serverStorePid');
      }

      // 降级方案：从根级别获取（兼容旧接口）
      serverStorePid ??= data['product_id']?.toString() ??
          data['store_product_id']?.toString();

      if (serverStorePid != null && serverStorePid.isNotEmpty) {
        productId = serverStorePid;
        debugPrint('📦 [_prepareOrder] 使用后端返回的商店商品ID: $productId');
      }

      // 🔑 更新支付上下文，包含后端返回的 orderNum
      final callback = _callbacks[CallbackType.payment];
      if (callback != null) {
        final context = StreamCallback.extractEventContext(params.toMap());
        context['orderNum'] = orderId;
        context['orderId'] = orderId; // 向后兼容
        callback.setPendingContext(context);
        debugPrint('✅ [_prepareOrder] 已更新支付上下文，orderNum: $orderId');
      }

      // 重置产品购买状态，允许新购买流程
      final payCallback = paymentCallback;
      if (payCallback != null) {
        payCallback.resetProductForNewPurchase(productId);
      }
    } else {
      debugPrint('⚠️ [_prepareOrder] PrePay失败或未返回订单ID，继续使用默认商品ID: $productId');
    }

    prepareOrderStopwatch.stop();
    debugPrint(
      '⏱️ [IAP:$gatewayDisplayName] _prepareOrder total finished in '
      '${prepareOrderStopwatch.elapsedMilliseconds}ms '
      '(result=${response.result}, orderId=$orderId, productId=$productId)',
    );

    return PrepayResult(
      orderId: orderId,
      productId: productId,
    );
  }

  /// 记录购买上下文
  void _logPurchaseContext(
    String orderId,
    InAppPurchaseParams params,
    ProductDetails productDetails,
  ) {
    debugPrint('📝 [购买上下文]');
    debugPrint('   订单ID: $orderId');
    debugPrint('   产品ID: ${params.productId}');
    debugPrint('   产品标题: ${productDetails.title}');
    debugPrint('   价格: ${productDetails.price}');
  }

  /// iOS 专用：精确检查订阅组
  ///
  /// 返回 Map 包含：
  /// - 'isSameGroup': bool - 是否同组
  /// - 'existingProductId': String? - 现有订阅的产品ID
  Future<Map<String, dynamic>> _checkiOSSubscriptionGroup(
      ProductDetails productDetails) async {
    if (!Platform.isIOS) {
      return {'isSameGroup': false};
    }

    try {
      final activeSubscriptions = await ios_helper.getiOSActiveSubscriptions();
      if (activeSubscriptions.isEmpty) {
        return {'isSameGroup': false};
      }

      final result = await ios_helper.checkSameSubscriptionGroupPrecise(
        productDetails,
        activeSubscriptions,
      );

      return {
        'isSameGroup': result.isSameGroup,
        'existingProductId': result.existingProductId,
        'existingGroupId': result.existingGroupId,
        'targetGroupId': result.targetGroupId,
      };
    } catch (e) {
      debugPrint('⚠️ [iOS订阅组检查] 失败: $e');
      return {'isSameGroup': false};
    }
  }

  /// 启动购买流程
  ///
  /// 返回值：
  /// - `true`: 购买流程成功启动
  /// - `false`: 购买流程启动失败
  ///
  /// 异常：
  /// - `UserCancelledException`: 用户取消了购买
  Future<bool> _startPurchaseFlow({
    required ProductDetails productDetails,
    required PurchaseParam purchaseParam,
  }) async {
    try {
      final result = await _inAppPurchase!.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      debugPrint('🚀 购买流程启动结果: $result');
      return result;
    } catch (e) {
      debugPrint('❌ 启动购买流程失败: $e');

      // 使用统一的错误检测函数（定义在 purchase_error_handler.dart）
      final errorStr = e.toString().toLowerCase();
      if (isUserCancelledError(errorStr)) {
        debugPrint('📌 检测到用户取消购买');
        throw const UserCancelledException();
      }

      return false;
    }
  }

  // ==================== 查询 ====================

  @override
  Future<IResponse<Map<String, dynamic>>> query(
      IParams<Map<String, dynamic>> params) async {
    try {
      if (!await isAvailable()) {
        return PaymentResponse.failed(message: '$gatewayDisplayName不可用');
      }

      return queryPlatform(params.toMap());
    } catch (e) {
      debugPrint('❌ 查询失败: $e');
      return PaymentResponse.failed(message: '查询失败: $e');
    }
  }

  /// 查询订阅状态
  Future<IResponse<Map<String, dynamic>>> querySubscriptionStatus() async {
    try {
      if (!await isAvailable()) {
        return PaymentResponse.failed(message: '$gatewayDisplayName不可用');
      }

      return querySubscriptionStatusPlatform();
    } catch (e) {
      debugPrint('❌ 查询订阅状态失败: $e');
      return PaymentResponse.failed(message: '查询订阅状态失败: $e');
    }
  }

  // ==================== 验证 ====================

  @override
  Future<IResponse<Map<String, dynamic>>> verifypay(
      IParams<Map<String, dynamic>> params) async {
    debugPrint('🔐 [verifypay] 开始验证购买');
    PurchaseDetails? purchaseDetails;

    try {
      final data = params.toMap();
      purchaseDetails = data['purchaseDetails'] as PurchaseDetails?;

      if (purchaseDetails == null) {
        return PaymentResponse.failed(message: '缺少购买详情');
      }

      final purchaseId = purchaseDetails.purchaseID;
      if (purchaseId == null) {
        return PaymentResponse.failed(message: '缺少购买ID');
      }

      // 防止重复验证
      if (_verifyingPurchaseIds.contains(purchaseId)) {
        debugPrint('⚠️ 购买正在验证中，跳过: $purchaseId');
        return PaymentResponse.processing(message: '验证进行中');
      }

      _verifyingPurchaseIds.add(purchaseId);

      try {
        // 构建基础验证数据
        final baseData = <String, dynamic>{
          'orderNum': data['orderNum']?.toString(),
          'productId': data['targetProductId']?.toString() ?? purchaseDetails.productID,
          'platform': platformName,
          'status': purchaseDetails.status.name,
          'purchaseId': purchaseId,
          'transactionDate': purchaseDetails.transactionDate,
          'isRestored': data['isRestored'] ?? false,
          'method': platformName == 'android'
              ? PaymentMethod.googlePay.value
              : PaymentMethod.applePay.value,
        };

        // 平台特定数据（异步获取，支持Android动态包名）
        final verifyData = await buildVerifyData(purchaseDetails, baseData);

        debugPrint('准备发送的验证数据: $verifyData');

        // 调用后端验证
        final serverVerifyResult = await _verifynotify(verifyData);

        if (serverVerifyResult['success'] != true) {
          final errorMessage = '服务端验证失败: ${serverVerifyResult['error'] ?? serverVerifyResult['message']}';
          debugPrint(errorMessage);
          _publishPurchaseFailed(
            errorMessage,
            purchaseDetails,
            extraData: {
              'verifyData': verifyData,
              'serverVerified': false,
            },
          );

          // 调用平台特定的验证失败处理
          await handleVerificationFailurePlatform(purchaseDetails);

          return PaymentResponse.failed(
            message: errorMessage,
            data: {'verifyData': verifyData},
          );
        }

        debugPrint('服务端验证成功: ${purchaseDetails.productID}');

        // 验证成功后的关键步骤：
        // 1. 发放商品给用户（这里应该调用具体的业务逻辑）
        final businessSuccess = await _deliverProduct(purchaseDetails);

        if (businessSuccess) {
          // 2. 业务逻辑完成后，安全地完成购买
          await _completePurchase(purchaseDetails);

          // 3. 同步订单状态
          if (ref != null) {
            final orderManager = ref!.read(orderManagerProvider.notifier);
            final order = await orderManager.syncOrderByStoreTransactionId(purchaseId);
            if (order != null) {
              debugPrint('✅ 订单状态已同步: ${order.orderNum}');
            } else {
              debugPrint('⚠️ 按storeTransactionId同步订单失败');
            }
          }

          // 4. 发送验证成功事件
          // 🍎 iOS: 如果是同组订阅变更，在事件中标记
          final isGroupChange = data['isSubscriptionGroupChange'] == true;
          final existingProdId = data['existingProductId']?.toString();

          PaymentEventBus.instance.publish(PaymentEvent(
            PaymentEventType.completed,
            orderId: purchaseId,
            data: {
              'verified': true,
              'productId': purchaseDetails.productID,
              'delivered': true,
              'completed': true,
              'serverVerified': true,
              if (isGroupChange) 'isSubscriptionGroupChange': true,
              if (existingProdId != null) 'existingProductId': existingProdId,
            },
          ));

          debugPrint('✅ [verifypay] 验证成功: $purchaseId');

          // 🍎 iOS: 检查是否为同组订阅变更（升级/降级）
          // 如果是同组变更，添加提示信息告知用户
          final isSubscriptionGroupChange = data['isSubscriptionGroupChange'] == true;
          final existingProductId = data['existingProductId']?.toString();
          String successMessage = '服务端验证成功，商品已发放，交易已完成';

          if (isSubscriptionGroupChange && existingProductId != null) {
            successMessage = '订阅变更成功！如为升级立即生效；如为降级或同级切换，将在当前订阅到期后生效';
            debugPrint('📊 [verifypay] iOS 同组订阅变更完成: 原订阅=$existingProductId');
          }

          return PaymentResponse.success(
            message: successMessage,
            data: {
              'verified': true,
              'delivered': true,
              'completed': true,
              'serverVerified': true,
              'transactionId': purchaseId,
              'isSubscriptionGroupChange': isSubscriptionGroupChange,
              'existingProductId': existingProductId,
            },
            transactionId: purchaseId,
          );
        } else {
          const msg = '服务端验证成功但商品发放失败，请重试';
          _publishPurchaseFailed(
            msg,
            purchaseDetails,
            extraData: {'serverVerified': true, 'delivered': false},
          );
          // 业务逻辑失败，不完成购买，保持交易状态以便重试
          return PaymentResponse.failed(
            message: msg,
            data: {'serverVerified': true},
          );
        }
      } finally {
        _verifyingPurchaseIds.remove(purchaseId);
      }
    } catch (e, s) {
      final errMsg = '验证过程出现异常: $e';
      debugPrint(errMsg);
      if (purchaseDetails != null) {
        _publishPurchaseFailed(
          errMsg,
          purchaseDetails,
          extraData: {'exception': e.toString()},
          error: e,
          stackTrace: s,
        );
      }
      return PaymentResponse.failed(message: errMsg);
    }
  }

  /// 发布购买失败事件
  void _publishPurchaseFailed(
    String message,
    PurchaseDetails purchaseDetails, {
    Map<String, dynamic>? extraData,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final data = <String, dynamic>{
      'productId': purchaseDetails.productID,
      'verified': false,
      if (extraData != null) ...extraData,
    };
    PaymentEventBus.instance.publish(PaymentEvent(
      PaymentEventType.failed,
      orderId: purchaseDetails.purchaseID,
      data: data,
      error: error ?? message,
      stackTrace: stackTrace,
    ));
  }

  /// 交付产品（业务逻辑占位，实际发放由服务端完成）
  Future<bool> _deliverProduct(PurchaseDetails purchase) async {
    // 商品发放由服务端验证时完成，此处仅记录日志
    // 订单同步在 verifypay 中统一处理，避免重复调用
    debugPrint('商品发放确认: ${purchase.productID}');
    return true;
  }

  /// 调用后端验证API
  Future<Map<String, dynamic>> _verifynotify(Map<String, dynamic> data) async {
    debugPrint('🔔 [_verifynotify] 开始调用后端验证API');
    debugPrint('🔔 [_verifynotify] 请求数据: $data');

    try {
      final payApi = ref?.read(payApiProvider);
      if (payApi == null) {
        debugPrint('❌ [_verifynotify] payApi 为空，无法调用验证API');
        return {'success': false, 'message': '支付API不可用'};
      }

      debugPrint('🚀 [_verifynotify] 调用 payApi.verifyNotify...');
      final result = await payApi.verifyNotify(data: data);

      return result.fold(
        (error) {
          debugPrint('❌ [_verifynotify] 后端验证失败: $error');
          return {'success': false, 'message': error};
        },
        (responseData) {
          debugPrint('✅ [_verifynotify] 后端验证成功');
          debugPrint('📦 [_verifynotify] 返回数据: $responseData');
          return {
            'success': true,
            'message': '验证成功',
            'data': responseData,
          };
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [_verifynotify] 后端验证调用异常: $e');
      debugPrint('❌ [_verifynotify] 堆栈: $stackTrace');
      return {'success': false, 'message': '验证请求失败: $e'};
    }
  }

  /// 完成购买
  Future<void> _completePurchase(PurchaseDetails purchase) async {
    try {
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase!.completePurchase(purchase);
        debugPrint('购买已完成: ${purchase.productID}');
      }
    } catch (e) {
      debugPrint('完成购买异常: $e');
    }
  }

  // ==================== 恢复购买 ====================

  /// 恢复购买（用户主动触发）
  Future<IResponse<Map<String, dynamic>>> restorePurchases() async {
    if (!await isAvailable()) {
      return PaymentResponse.failed(message: '$gatewayDisplayName不可用');
    }

    try {
      // 获取回调实例
      final callback = _callbacks[CallbackType.payment];

      // 🔑 设置恢复来源为用户触发
      callback?.setRestoreSource(RestoreSource.userTriggered);

      // 🔒 清除已恢复产品记录，允许重新验证
      // 用户每次点击"恢复购买"按钮时，重置 productId 去重集合
      if (callback is InAppPurchaseCallback) {
        callback.clearRestoredProducts();
      }

      await _inAppPurchase!.restorePurchases();

      // 🔑 延迟重置恢复来源（等待事件处理完成）
      Future.delayed(const Duration(seconds: 5), () {
        callback?.resetRestoreSource();
      });

      return PaymentResponse.processing(
        message: '恢复购买流程已启动，结果将通过回调返回',
      );
    } catch (e, s) {
      debugPrint('❌ 恢复购买失败: $e\n$s');
      _callbacks[CallbackType.payment]?.resetRestoreSource();
      return PaymentResponse.failed(message: '恢复购买失败: $e');
    }
  }

  // ==================== 待处理购买检查 ====================

  /// 检查待处理的购买
  Future<void> _checkPendingPurchases() async {
    _isInitRestorePhase = true;
    try {
      await checkPendingPurchasesPlatform();
    } finally {
      _isInitRestorePhase = false;
    }
  }

  // ==================== 产品加载 ====================

  /// 加载产品
  Future<ProductLoadResult> _loadProducts() async {
    if (_productIds.isEmpty) {
      return ProductLoadResult.empty();
    }

    try {
      // 从产品服务获取
      final productService = ref?.read(productServiceProvider);
      if (productService == null) {
        return ProductLoadResult.empty();
      }

      final platform = platformName == 'android'
          ? ProductPlatform.android
          : ProductPlatform.ios;
      final result = await productService.getProductsByPlatform(platform);

      return result.fold(
        (error) {
          debugPrint('⚠️ 产品服务返回错误: $error');
          final errorStr = error.toLowerCase();
          if (isNetworkError(errorStr)) {
            return ProductLoadResult.networkError(error);
          }
          return ProductLoadResult.fallback(0);
        },
        (products) async {
          if (products.isEmpty) {
            debugPrint('⚠️ 产品服务返回空列表');
            return ProductLoadResult.empty();
          }

          // 缓存产品详情
          await _cacheProductDetails(products);

          return ProductLoadResult.success(products.length);
        },
      );
    } catch (e) {
      debugPrint('❌ 加载产品失败: $e');
      final errorStr = e.toString().toLowerCase();
      if (isNetworkError(errorStr)) {
        return ProductLoadResult.networkError('加载产品失败: $e');
      }
      return ProductLoadResult.fallback(0);
    }
  }

  /// 缓存产品详情
  Future<void> _cacheProductDetails(List<ProductEntry> products) async {
    for (final product in products) {
      final details = createProductDetailsFromDb(product);
      if (details != null) {
        _productDetailsCache[product.productId] = details;
      }
    }
  }

  // ==================== 获取产品列表 ====================

  @override
  Future<IResponse<List<Map<String, dynamic>>>> getProducts([
      List<String>? productIds]) async {
    try {
      final productService = ref?.read(productServiceProvider);
      if (productService == null) {
        return ProductListResponse.failed(message: '产品服务不可用');
      }

      final platform = platformName == 'android'
          ? ProductPlatform.android
          : ProductPlatform.ios;
      final result = await productService.getProductsByPlatform(platform);

      return result.fold(
        (error) => ProductListResponse.failed(message: error),
        (products) {
          if (products.isEmpty) {
            return ProductListResponse.failed(message: '没有可用产品');
          }

          // 如果指定了产品ID，只返回匹配的产品
          final filteredProducts = productIds != null && productIds.isNotEmpty
              ? products.where((p) => productIds.contains(p.productId)).toList()
              : products;

          final productList = filteredProducts
              .map<Map<String, dynamic>>((p) => {
                    'productId': p.productId,
                    'title': p.title,
                    'description': p.description ?? '',
                    'price': p.priceFormatted,
                    'rawPrice': p.price,
                    'currency': p.currency,
                    'platform': p.platform,
                    'type': p.type,
                    'canPurchase': true,
                  })
              .toList();

          return ProductListResponse.success(
            products: productList,
            message: '成功获取商品列表: ${productList.length}个',
          );
        },
      );
    } catch (e, s) {
      debugPrint('获取商品列表异常: $e\n$s');
      return ProductListResponse.failed(message: '获取商品列表失败: $e');
    }
  }

  // ==================== 其他接口实现 ====================

  @override
  Future<IResponse<Map<String, dynamic>>> getPayResult(
      IParams<Map<String, dynamic>> params) async {
    return PaymentResponse.failed(message: '应用内购买不支持此操作');
  }

  @override
  Future<IResponse<Map<String, dynamic>>> refund(
      IParams<Map<String, dynamic>> params) async {
    return PaymentResponse.failed(message: '应用内购买不支持直接退款，请联系客服');
  }

  @override
  Future<IResponse<Map<String, dynamic>>> cancelorder(
      IParams<Map<String, dynamic>> params) async {
    try {
      if (ref == null) {
        return PaymentResponse.failed(message: '依赖不可用');
      }

      final map = params.toMap();

      // 提取可选参数（不做orderId必需校验）
      final orderId = map['orderId']?.toString() ?? map['order_id']?.toString() ?? map['orderNum']?.toString();
      final reason = map['reason']?.toString() ?? 'before pay cancel all unpaid order';
      final productId = map['productId']?.toString() ?? map['product_id']?.toString();

      debugPrint('🚫 开始取消订单');
      if (orderId != null) {
        debugPrint('   订单ID: $orderId');
      }
      debugPrint('   取消原因: $reason');
      if (productId != null) {
        debugPrint('   产品ID: $productId');
      }

      // 调用后端取消订单接口
      final api = ref!.read(payApiProvider);
      final cancelResult = await api.cancelOrder(
        orderId: orderId,
        reason: reason,
        productId: productId,
      );

      return await cancelResult.fold(
        (error) async {
          debugPrint('❌ 取消订单失败: $error');
          return PaymentResponse.failed(
            message: '取消订单失败: $error',
            data: {
              if (orderId != null) 'orderId': orderId,
              'reason': reason,
              'error': error,
            },
          );
        },
        (response) async {
          debugPrint('✅ 成功取消订单');

          // 处理批量删除响应: {order_ids: [...], deleted_count: n, status: "deleted", msg: "..."}
          final List<String> deletedOrderIds = [];

          // 提取order_ids数组
          final orderIdsField = response['order_ids'];
          if (orderIdsField is List) {
            deletedOrderIds.addAll(
              orderIdsField.map((id) => id.toString()).where((id) => id.isNotEmpty)
            );
          }

          debugPrint('📋 后端返回删除的订单ID: $deletedOrderIds');
          debugPrint('   删除数量: ${response['deleted_count'] ?? deletedOrderIds.length}');
          debugPrint('   状态: ${response['status']}');

          // 如果没有从响应中提取到订单ID，但传入了orderId，使用传入的orderId
          if (deletedOrderIds.isEmpty && orderId != null) {
            deletedOrderIds.add(orderId);
          }

          // 删除本地对应orderid的记录
          final List<String> localDeletedIds = [];
          final List<String> localDeleteFailedIds = [];

          if (deletedOrderIds.isNotEmpty) {
            try {
              final orderManager = ref!.read(orderManagerProvider.notifier);

              for (final orderNum in deletedOrderIds) {
                try {
                  await orderManager.deleteOrder(orderNum);
                  localDeletedIds.add(orderNum);
                  debugPrint('✅ 本地订单已删除: $orderNum');
                } catch (e) {
                  localDeleteFailedIds.add(orderNum);
                  debugPrint('⚠️ 删除本地订单失败: $orderNum - $e');
                }
              }

              // 发送取消事件（批量）
              for (final orderNum in localDeletedIds) {
                PaymentEventBus.instance.publish(PaymentEvent(
                  PaymentEventType.cancelled,
                  orderId: orderNum,
                  data: {
                    'reason': reason,
                    'cancelled_at': DateTime.now().toIso8601String(),
                    'deleted': true,
                  },
                ));
              }

              debugPrint('✅ 本地订单批量删除完成: ${localDeletedIds.length}/${deletedOrderIds.length}');
            } catch (e) {
              debugPrint('⚠️ 批量删除本地订单异常: $e');
            }
          }

          return PaymentResponse.success(
            message: '订单已取消并删除',
            data: {
              'order_ids': deletedOrderIds,
              'deleted_count': deletedOrderIds.length,
              'local_deleted_ids': localDeletedIds,
              'local_delete_failed_ids': localDeleteFailedIds,
              'reason': reason,
              'status': 'deleted',
              'response': response,
            },
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ 取消订单异常: $e');
      debugPrint('堆栈: $stackTrace');

      return PaymentResponse.failed(
        message: '取消订单异常: $e',
        data: {
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
    }
  }

  // ==================== 验证事件监听 ====================

  /// 监听验证事件
  void _listenVerifyEvent() {
    PaymentEventBus.instance.subscribe((event) async {
      debugPrint('📩 [_listenVerifyEvent] 收到事件: type=${event.type}, action=${event.data?['action']}');

      if (event.type != PaymentEventType.custom) return;
      if (event.data?['action'] != 'verify_needed') return;

      debugPrint('✅ [_listenVerifyEvent] 收到 verify_needed 事件');

      final purchaseDetails = event.data?['purchaseDetails'] as PurchaseDetails?;
      if (purchaseDetails == null) {
        debugPrint('❌ [_listenVerifyEvent] purchaseDetails 为空，跳过');
        return;
      }

      final purchaseId = purchaseDetails.purchaseID;
      if (purchaseId == null) {
        debugPrint('❌ [_listenVerifyEvent] purchaseId 为空，跳过');
        return;
      }

      // 检查是否已验证
      final callback = _callbacks[CallbackType.payment];
      if (callback is InAppPurchaseCallback && callback.isVerified(purchaseId)) {
        debugPrint('🔒 [_listenVerifyEvent] 购买ID已验证过，跳过: $purchaseId');
        return;
      }

      // 注意：不在这里检查 _verifyingPurchaseIds，避免与 verifypay 内部的检查形成双重锁
      // verifypay 内部会自己处理并发控制

      final orderNum = event.data?['orderNum']?.toString();
      final isRestored = event.data?['isRestored'] as bool? ?? false;
      final targetProductId = event.data?['productId']?.toString() ?? purchaseDetails.productID;

      debugPrint('🚀 [_listenVerifyEvent] 开始调用 verifypay:');
      debugPrint('   targetProductId: $targetProductId');
      debugPrint('   purchaseId: $purchaseId, orderNum: $orderNum, isRestored: $isRestored');

      try {
        final result = await verifypay(VerifyParams({
          'purchaseDetails': purchaseDetails,
          'orderNum': orderNum,
          'status': purchaseDetails.status.name,
          'isRestored': isRestored,
          'targetProductId': targetProductId,
        }));

        // 只有验证成功才标记为已验证
        if (result.result == PaymentResult.success) {
          if (callback is InAppPurchaseCallback) {
            callback.markAsVerified(purchaseId);
          }
          GchUmengSvc.onPurchase(productId: targetProductId);
          debugPrint('✅ [_listenVerifyEvent] verifypay 成功: $purchaseId');
        } else {
          debugPrint('❌ [_listenVerifyEvent] verifypay 失败: ${result.message}');
        }
      } catch (e) {
        debugPrint('❌ [_listenVerifyEvent] verifypay 异常: $e');
      }
      // 注意：不在这里移除 _verifyingPurchaseIds，verifypay 内部会自己处理
    });

    debugPrint('✅ 验证事件监听已设置');
  }

  // ==================== 参数转换 ====================

  /// 转换通用参数为 InAppPurchaseParams
  InAppPurchaseParams? _convertParams(IParams<Map<String, dynamic>> params) {
    try {
      final data = params.toMap();
      return InAppPurchaseParams(
        productId: data['productId']?.toString() ?? '',
        purchaseType: data['purchaseType']?.toString() ?? 'non_consumable',
        extraParams: data,
        autoConsume: data['autoConsume'] as bool? ?? true,
        oldSubscriptionId: data['oldSubscriptionId']?.toString(),
        prorationMode: null, // 子类处理
      );
    } catch (e) {
      debugPrint('参数转换失败: $e');
      return null;
    }
  }

  // ==================== 资源释放 ====================

  @override
  void dispose() {
    disposePlatform();

    for (final cb in _callbacks.values) {
      cb.dispose();
    }
    _callbacks.clear();
    _productDetailsCache.clear();
    _initialized = false;
    _isReady = false;
    debugPrint('应用内购买Provider已释放');
  }
}
