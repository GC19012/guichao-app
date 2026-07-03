import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:guichao/gch_base/gch_biz/gch_api/gch_client/gch_api_client.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_providers/gch_api_client_providers.dart';

// 支付方法枚举
enum PaymentMethod {
  applePay,
  googlePay,
}

// 支付状态枚举
enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
  expired,
  refunding,
  refunded,
}

// 支付方法扩展
extension PaymentMethodExtension on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.applePay:
        return 'apple_pay';
      case PaymentMethod.googlePay:
        return 'google_pay';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'apple_pay':
        return PaymentMethod.applePay;
      case 'google_pay':
        return PaymentMethod.googlePay;
      default:
        throw ArgumentError('Unknown payment method: $value');
    }
  }
}

// 支付状态扩展
extension PaymentStatusExtension on PaymentStatus {
  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.processing:
        return 'processing';
      case PaymentStatus.success:
        return 'success';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.cancelled:
        return 'cancelled';
      case PaymentStatus.expired:
        return 'expired';
      case PaymentStatus.refunding:
        return 'refunding';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'success':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'expired':
        return PaymentStatus.expired;
      case 'refunding':
        return PaymentStatus.refunding;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        throw ArgumentError('Unknown payment status: $value');
    }
  }
}

// 支付请求模型 - 基于Go结构体PaymentRequest
class PaymentRequest {
  final String orderId;           // Your system's unique order identifier
  final double amount;            // Payment amount in standard currency units
  final String currency;          // 3-letter ISO currency code (e.g., "USD", "CNY")
  final String subject;           // Brief title or subject for the payment
  final String description;       // Detailed description of the payment
  final PaymentMethod method;     // Payment method to be used
  final String notifyUrl;         // URL for asynchronous notifications
  final String returnUrl;         // URL to redirect user after payment completion
  final String clientIp;          // IP address of the client
  final int timeout;              // Payment timeout in seconds
  final String? appId;            // Optional: Application ID
  final String? userId;           // Optional: Your system's user identifier
  final String? productId;           // Optional: Your system's product ID
  final int id;
  final Map<String, dynamic>? extendParams; // Channel-specific parameters

  const PaymentRequest({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.subject,
    required this.description,
    required this.method,
    required this.notifyUrl,
    required this.returnUrl,
    required this.clientIp,
    required this.timeout,
    this.appId,
    this.userId,
    this.productId,
    this.extendParams,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: (json['product_id'] as num).toInt(),
      orderId: json['order_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      method: PaymentMethodExtension.fromString(json['method'] as String),
      notifyUrl: json['notify_url'] as String,
      returnUrl: json['return_url'] as String,
      clientIp: json['client_ip'] as String,
      timeout: json['timeout'] as int,
      appId: json['app_id'] as String?,
      userId: json['userid'] as String?,
      productId: json['product_code'] as String?,
      extendParams: json['extend_params'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'amount': amount,
      'currency': currency,
      'subject': subject,
      'description': description,
      'method': method.value,
      'notify_url': notifyUrl,
      'return_url': returnUrl,
      'client_ip': clientIp,
      'timeout': timeout,
      if (appId != null) 'app_id': appId,
      if (userId != null) 'userid': userId,
      if (id != 0) 'product_id': id,
      if (productId != null) 'product_code': productId,
      if (extendParams != null) 'extend_params': extendParams,
    };
  }

  PaymentRequest copyWith({
    String? orderId,
    double? amount,
    String? currency,
    String? subject,
    String? description,
    PaymentMethod? method,
    String? notifyUrl,
    String? returnUrl,
    String? clientIp,
    int? timeout,
    String? appId,
    String? userId,
    String? productId,
    Map<String, dynamic>? extendParams,
  }) {
    return PaymentRequest(
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      method: method ?? this.method,
      notifyUrl: notifyUrl ?? this.notifyUrl,
      returnUrl: returnUrl ?? this.returnUrl,
      clientIp: clientIp ?? this.clientIp,
      timeout: timeout ?? this.timeout,
      appId: appId ?? this.appId,
      userId: userId ?? this.userId,
      id: this.id,
      productId: productId ?? this.productId,
      extendParams: extendParams ?? this.extendParams,
    );
  }
}

// 支付API响应模型 - 基于Go结构体PaymentResponse
class PaymentApiResponse {
  final String tradeNo;                    // Gateway's unique trade number
  final String orderId;                    // Your system's order identifier
  final PaymentMethod method;              // Payment method used
  final PaymentStatus status;              // Current status of the payment
  final double amount;                     // Payment amount
  final String currency;                   // Currency code
  final String? payUrl;                    // URL for redirecting user to payment page
  final String? qrCodeUrl;                 // URL for QR code image
  final String? formHtml;                  // HTML form content for auto-submitting
  final dynamic paymentInfo;               // Channel-specific information
  final String? prepayId;
  final String? errorCode;                 // Error code if payment failed
  final String? errorMsg;                  // Error message if payment failed
  final Map<String, dynamic>? channelExtra; // Additional data from payment channel
  final String? subscriptionId;            // Subscription ID if applicable
  final DateTime? subscriptionExpiresAt;   // Subscription expiry time
  final DateTime? paidAt;                  // Time of successful payment
  final String? productId;                 // Platform-specific product ID
  final String? originalTradeNo;           // Original transaction ID

  const PaymentApiResponse({
    required this.tradeNo,
    required this.orderId,
    required this.method,
    required this.status,
    required this.amount,
    required this.currency,
    this.payUrl,
    this.qrCodeUrl,
    this.formHtml,
    this.paymentInfo,
    this.prepayId,
    this.errorCode,
    this.errorMsg,
    this.channelExtra,
    this.subscriptionId,
    this.subscriptionExpiresAt,
    this.paidAt,
    this.productId,
    this.originalTradeNo,
  });

  factory PaymentApiResponse.fromJson(Map<String, dynamic> json) {
    return PaymentApiResponse(
      tradeNo: json['trade_no'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      method: PaymentMethodExtension.fromString(json['method'] as String? ?? 'google_pay'),
      status: PaymentStatusExtension.fromString(json['status'] as String? ?? 'pending'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      payUrl: json['pay_url'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
      formHtml: json['form_html'] as String?,
      paymentInfo: json['payment_info'],
      prepayId: json['prepay_id'] as String?,
      errorCode: json['error_code'] as String?,
      errorMsg: json['error_msg'] as String?,
      channelExtra: json['channel_extra'] as Map<String, dynamic>?,
      subscriptionId: json['subscription_id'] as String?,
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.tryParse(json['subscription_expires_at'] as String? ?? '')
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String? ?? '')
          : null,
      productId: json['product_id'] as String?,
      originalTradeNo: json['original_trade_no'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trade_no': tradeNo,
      'order_id': orderId,
      'method': method.value,
      'status': status.value,
      'amount': amount,
      'currency': currency,
      if (payUrl != null) 'pay_url': payUrl,
      if (qrCodeUrl != null) 'qr_code_url': qrCodeUrl,
      if (formHtml != null) 'form_html': formHtml,
      if (paymentInfo != null) 'payment_info': paymentInfo,
      if (prepayId != null) 'prepay_id': prepayId,
      if (errorCode != null) 'error_code': errorCode,
      if (errorMsg != null) 'error_msg': errorMsg,
      if (channelExtra != null) 'channel_extra': channelExtra,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      if (subscriptionExpiresAt != null)
        'subscription_expires_at': subscriptionExpiresAt!.toIso8601String(),
      if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
      if (productId != null) 'product_id': productId,
      if (originalTradeNo != null) 'original_trade_no': originalTradeNo,
    };
  }
}

// 支付查询响应模型
class PaymentStatusResponse {
  final String orderId;
  final String transactionId;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? expiredAt;
  final double? amount;
  final String? currency;

  const PaymentStatusResponse({
    required this.orderId,
    required this.transactionId,
    required this.status,
    required this.createdAt,
    this.paidAt,
    this.expiredAt,
    this.amount,
    this.currency,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      orderId: json['order_id'] as String,
      transactionId: json['transaction_id'] as String,
      status: PaymentStatusExtension.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      expiredAt: json['expired_at'] != null ? DateTime.parse(json['expired_at'] as String) : null,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      currency: json['currency'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'transaction_id': transactionId,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
      if (expiredAt != null) 'expired_at': expiredAt!.toIso8601String(),
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
    };
  }
}

// 支付方法信息模型
class PaymentMethodInfo {
  final String id;
  final String name;
  final PaymentMethod type;
  final bool enabled;
    final String? icon;
  final Map<String, dynamic>? config;

  const PaymentMethodInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.enabled,
    this.icon,
    this.config,
  });

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PaymentMethodExtension.fromString(json['type'] as String),
      enabled: json['enabled'] as bool,
      icon: json['icon'] as String?,
      config: json['config'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'enabled': enabled,
      if (icon != null) 'icon': icon,
      if (config != null) 'config': config,
    };
  }
}

// 支付历史记录模型
class PaymentHistory {
  final String orderId;
  final String transactionId;
  final String productId;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;

  const PaymentHistory({
    required this.orderId,
    required this.transactionId,
    required this.productId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.completedAt,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      orderId: json['orderId'] as String,
      transactionId: json['transactionId'] as String,
      productId: json['productId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'transactionId': transactionId,
      'productId': productId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }
}

// 验证通知请求模型 - 基于Go结构体VerifyNotifyRequest
class VerifyNotifyRequest {
  /// 支付方式标识，例如 google_pay, apple_pay
  final PaymentMethod method;

  /// Google Play 相关参数
  final String? packageName;
  final String? productId;
  final String? subscriptionId;
  final String? purchaseToken;
  final String? purchaseId;       // 交易ID（如 GPA.*）
  final String? transactionDate;  // 交易时间戳字符串
  final Map<String, dynamic>? purchaseData; // 原始purchaseData（Android本地收据JSON）
  final String? platform;         // 平台：android/ios（冗余传递，便于后端判定）

  /// Apple App Store 相关参数
  final String? signedTransactionInfo;
  final String? signedRenewalInfo;
  final String? originalTransactionId;
  final String? receiptData;

  /// 扩展参数，用于前向兼容
  final Map<String, dynamic>? extend;

  const VerifyNotifyRequest({
    required this.method,
    this.packageName,
    this.productId,
    this.subscriptionId,
    this.purchaseToken,
    this.purchaseId,
    this.transactionDate,
    this.purchaseData,
    this.platform,
    this.signedTransactionInfo,
    this.signedRenewalInfo,
    this.originalTransactionId,
    this.receiptData,
    this.extend,
  });

  factory VerifyNotifyRequest.fromJson(Map<String, dynamic> json) {
    return VerifyNotifyRequest(
      method: PaymentMethodExtension.fromString(json['method'] as String),
      packageName: json['package_name'] as String?,
      productId: json['product_id'] as String?,
      subscriptionId: json['subscription_id'] as String?,
      purchaseToken: json['purchase_token'] as String?,
      purchaseId: json['purchase_id'] as String?,
      transactionDate: json['transaction_date']?.toString(),
      purchaseData: json['purchase_data'] as Map<String, dynamic>?,
      platform: json['platform'] as String?,
      signedTransactionInfo: json['signed_transaction_info'] as String?,
      signedRenewalInfo: json['signed_renewal_info'] as String?,
      originalTransactionId: json['original_transaction_id'] as String?,
      receiptData: json['receipt_data'] as String?,
      extend: json['extend'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method.value,
      if (packageName != null) 'package_name': packageName,
      if (productId != null) 'product_id': productId,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      if (purchaseToken != null) 'purchase_token': purchaseToken,
      if (purchaseId != null) 'purchase_id': purchaseId,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (purchaseData != null) 'purchase_data': purchaseData,
      if (platform != null) 'platform': platform,
      if (signedTransactionInfo != null) 'signed_transaction_info': signedTransactionInfo,
      if (signedRenewalInfo != null) 'signed_renewal_info': signedRenewalInfo,
      if (originalTransactionId != null) 'original_transaction_id': originalTransactionId,
      if (receiptData != null) 'receipt_data': receiptData,
      if (extend != null) 'extend': extend,
    };
  }
}

// 验证通知响应模型 - 基于Go结构体VerifyNotifyResponse
class VerifyNotifyResponse {
  final PaymentMethod method;
  final bool valid;

  /// 事件元数据
  final String? eventType;
  final String? uniqueEventId;

  /// 标准化标识符
  final String? productId;
  final String? subscriptionId;
  final String? transactionId;
  final String? originalTransactionId;

  /// 状态和属性
  final String? purchaseState; // purchased|pending|canceled|active|expired
  final bool acknowledged;
  final bool autoRenewing;
  final DateTime? expiresAt;
  final String? environment; // Apple: Sandbox|Production

  /// 原始平台数据
  final Map<String, dynamic>? raw;

  /// 错误信息（当valid == false时）
  final String? errorCode;
  final String? errorMessage;

  const VerifyNotifyResponse({
    required this.method,
    required this.valid,
    this.eventType,
    this.uniqueEventId,
    this.productId,
    this.subscriptionId,
    this.transactionId,
    this.originalTransactionId,
    this.purchaseState,
    this.acknowledged = false,
    this.autoRenewing = false,
    this.expiresAt,
    this.environment,
    this.raw,
    this.errorCode,
    this.errorMessage,
  });

  factory VerifyNotifyResponse.fromJson(Map<String, dynamic> json) {
    return VerifyNotifyResponse(
      method: PaymentMethodExtension.fromString(json['method'] as String? ?? 'google_pay'),
      valid: json['valid'] as bool? ?? false,
      eventType: json['event_type'] as String?,
      uniqueEventId: json['unique_event_id'] as String?,
      productId: json['product_id'] as String?,
      subscriptionId: json['subscription_id'] as String?,
      transactionId: json['transaction_id'] as String?,
      originalTransactionId: json['original_transaction_id'] as String?,
      purchaseState: json['purchase_state'] as String?,
      acknowledged: json['acknowledged'] as bool? ?? false,
      autoRenewing: json['auto_renewing'] as bool? ?? false,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      environment: json['environment'] as String?,
      raw: json['raw'] as Map<String, dynamic>?,
      errorCode: json['error_code'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method.value,
      'valid': valid,
      if (eventType != null) 'event_type': eventType,
      if (uniqueEventId != null) 'unique_event_id': uniqueEventId,
      if (productId != null) 'product_id': productId,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (originalTransactionId != null) 'original_transaction_id': originalTransactionId,
      if (purchaseState != null) 'purchase_state': purchaseState,
      'acknowledged': acknowledged,
      'auto_renewing': autoRenewing,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      if (environment != null) 'environment': environment,
      if (raw != null) 'raw': raw,
      if (errorCode != null) 'error_code': errorCode,
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }
}

/// 支付API接口
class PayApi {
  final Ref _ref;

  PayApi({required Ref ref}) : _ref = ref;

  /// 获取API客户端
  DataApiClient get _apiClient => _ref.read(apiClientProvider);

  /// 初始化API客户端
  void initializeApiClient() {
    // 这里可以添加支付相关的API初始化逻辑
  }

  /// 创建支付订单
  Future<Either<String, PaymentApiResponse>> Pay({
    required PaymentRequest request,
  }) async {
    final stopwatch = Stopwatch()..start();
    final requestJson = request.toJson();
    debugPrint(
      '🚀 [PayApi.Pay] start '
      '(productCode=${request.productId}, productId=${request.id}, '
      'method=${request.method.value}, amount=${request.amount})',
    );
    try {
      final postStopwatch = Stopwatch()..start();
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/payment/pay',
        data: requestJson,
      );
      postStopwatch.stop();
      debugPrint(
        '⏱️ [PayApi.Pay] _apiClient.post finished in '
        '${postStopwatch.elapsedMilliseconds}ms '
        '(status=${response.statusCode}, '
        'productCode=${request.productId}, method=${request.method.value})',
      );

      if (response.data == null) {
        stopwatch.stop();
        debugPrint(
          '⏱️ [PayApi.Pay] failed after ${stopwatch.elapsedMilliseconds}ms '
          '(reason=null response data, productCode=${request.productId})',
        );
        return const Left('创建支付订单失败：无响应数据');
      }

      // 提取嵌套的data字段
      final parseStopwatch = Stopwatch()..start();
      final responseData = response.data!;
      final paymentData = responseData['data'] as Map<String, dynamic>?;

      if (paymentData == null) {
        parseStopwatch.stop();
        stopwatch.stop();
        debugPrint(
          '⏱️ [PayApi.Pay] failed after ${stopwatch.elapsedMilliseconds}ms '
          '(reason=invalid response format, '
          'parse=${parseStopwatch.elapsedMilliseconds}ms, '
          'productCode=${request.productId})',
        );
        return const Left('创建支付订单失败：响应数据格式错误');
      }

      final paymentResponse = PaymentApiResponse.fromJson(paymentData);
      parseStopwatch.stop();
      stopwatch.stop();
      debugPrint(
        '⏱️ [PayApi.Pay] total finished in ${stopwatch.elapsedMilliseconds}ms '
        '(parse=${parseStopwatch.elapsedMilliseconds}ms, '
        'orderId=${paymentResponse.orderId}, productCode=${request.productId})',
      );
      return Right(paymentResponse);
    } on DioException catch (e) {
      stopwatch.stop();
      debugPrint(
        '⏱️ [PayApi.Pay] dio failed after ${stopwatch.elapsedMilliseconds}ms '
        '(productCode=${request.productId}, method=${request.method.value}, error=${e.message})',
      );
      return Left('创建支付订单失败: ${e.message}');
    } catch (e) {
      stopwatch.stop();
      debugPrint(
        '⏱️ [PayApi.Pay] failed after ${stopwatch.elapsedMilliseconds}ms '
        '(productCode=${request.productId}, method=${request.method.value}, error=$e)',
      );
      return Left('创建支付订单失败: $e');
    }
  }

  /// 验证支付通知
  Future<Either<String, PaymentStatusResponse>> verifyPayment({
    required String transactionId,
    required PaymentMethod paymentMethod,
    Map<String, dynamic>? notifyData,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'transaction_id': transactionId,
        'payment_method': paymentMethod.value,
        if (notifyData != null) 'notify_data': notifyData,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/payment/verify',
        data: requestData,
      );

      if (response.data == null) {
        return const Left('验证支付失败：无响应数据');
      }

      final status = PaymentStatusResponse.fromJson(response.data!);
      return Right(status);
    } on DioException catch (e) {
      return Left('验证支付失败: ${e.message}');
    } catch (e) {
      return Left('验证支付失败: $e');
    }
  }

  /// 查询支付状态
  Future<Either<String, PaymentStatusResponse>> queryPaymentStatus({
    required String orderId,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/payment/status/$orderId',
      );

      if (response.data == null) {
        return const Left('查询支付状态失败：无响应数据');
      }

      final status = PaymentStatusResponse.fromJson(response.data!);
      return Right(status);
    } on DioException catch (e) {
      return Left('查询支付状态失败: ${e.message}');
    } catch (e) {
      return Left('查询支付状态失败: $e');
    }
  }

  /// 取消支付订单
  Future<Either<String, bool>> cancelPayment({
    required String orderId,
    String? reason,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'order_id': orderId,
        if (reason != null) 'reason': reason,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/payment/cancel',
        data: requestData,
      );

      final success = response.data?['success'] as bool? ?? false;
      return Right(success);
    } on DioException catch (e) {
      return Left('取消支付失败: ${e.message}');
    } catch (e) {
      return Left('取消支付失败: $e');
    }
  }

  /// 申请退款
  Future<Either<String, Map<String, dynamic>>> Refund({
    required String transactionId,
    required String reason,
    double? amount,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'transaction_id': transactionId,
        'reason': reason,
        if (amount != null) 'amount': amount,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/payment/refund',
        data: requestData,
      );

      if (response.data == null) {
        return const Left('申请退款失败：无响应数据');
      }

      return Right(response.data!);
    } on DioException catch (e) {
      return Left('申请退款失败: ${e.message}');
    } catch (e) {
      return Left('申请退款失败: $e');
    }
  }

  /// 获取支付历史记录
  Future<Either<String, List<PaymentHistory>>> getPaymentHistory({
    int page = 1,
    int pageSize = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (status != null) 'status': status,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/payment/history',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        return const Left('获取支付历史失败：无响应数据');
      }

      final items = response.data?['items'] as List<dynamic>? ?? <dynamic>[];
      final history = items
          .map((item) => PaymentHistory.fromJson(item as Map<String, dynamic>))
          .toList();

      return Right(history);
    } on DioException catch (e) {
      return Left('获取支付历史失败: ${e.message}');
    } catch (e) {
      return Left('获取支付历史失败: $e');
    }
  }

  /// 获取支持的支付方式列表
  Future<Either<String, List<PaymentMethodInfo>>> getPaymentMethods() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/payment/methods',
      );

      if (response.data == null) {
        return const Left('获取支付方式失败：无响应数据');
      }

      final items = response.data?['methods'] as List<dynamic>? ?? <dynamic>[];
      final methods = items
          .map((item) => PaymentMethodInfo.fromJson(item as Map<String, dynamic>))
          .toList();

      return Right(methods);
    } on DioException catch (e) {
      return Left('获取支付方式失败: ${e.message}');
    } catch (e) {
      return Left('获取支付方式失败: $e');
    }
  }

  /// 处理支付回调通知
  Future<Either<String, bool>> handlePaymentCallback({
    required PaymentMethod paymentMethod,
    required Map<String, dynamic> callbackData,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'payment_method': paymentMethod.value,
        'callback_data': callbackData,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/payment/callback',
        data: requestData,
      );

      final success = response.data?['success'] as bool? ?? false;
      return Right(success);
    } on DioException catch (e) {
      return Left('处理支付回调失败: ${e.message}');
    } catch (e) {
      return Left('处理支付回调失败: $e');
    }
  }

  /// 预检查支付可用性
  Future<Either<String, Map<String, dynamic>>> checkPaymentAvailability({
    required String productId,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'product_id': productId,
        'payment_method': paymentMethod.value,
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/payment/check',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        return const Left('检查支付可用性失败：无响应数据');
      }

      return Right(response.data!);
    } on DioException catch (e) {
      return Left('检查支付可用性失败: ${e.message}');
    } catch (e) {
      return Left('检查支付可用性失败: $e');
    }
  }


  /// 获取支付配置（原payment_manager中的_loadRemoteConfig）
  Future<Either<String, Map<String, Map<String, dynamic>>>> getPayConfig() async {
    try {
      final response = await _apiClient.get('/api/v1/payment/getpayconfig')
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final paymentConfig = data['payment_config'] as Map<String, dynamic>?;

        if (paymentConfig != null) {
          return Right(paymentConfig.cast<String, Map<String, dynamic>>());
        }
        return const Left('响应中没有支付配置数据');
      }
      return Left('获取支付配置失败: 状态码 ${response.statusCode}');
    } on DioException catch (e) {
      return Left('获取支付配置请求失败: ${e.message}');
    } catch (e) {
      return Left('获取支付配置失败: $e');
    }
  }

  /// 统一的购买验证通知接口（支持Android、iOS、微信、支付宝等）
  Future<Either<String, Map<String, dynamic>>> verifyNotify({
    required Map<String, dynamic> data,
  }) async {
    try {
      // 🔑 优先使用传入的 method，否则自动检测平台
      final platform = data['platform'] as String? ?? _detectPlatform(data);
      PaymentMethod method;
      final methodStr = data['method'] as String?;
      if (methodStr != null) {
        method = PaymentMethodExtension.fromString(methodStr);
      } else {
        method = platform == 'android' ? PaymentMethod.googlePay : PaymentMethod.applePay;
      }

      final request = VerifyNotifyRequest(
        method: method,
        packageName: data['packageName'] as String?,
        productId: data['productId'] as String?,
        purchaseToken: data['purchaseToken'] as String?,
        purchaseId: data['purchaseId'] as String?,
        transactionDate: data['transactionDate']?.toString(),
        purchaseData: data['purchaseData'] as Map<String, dynamic>?,
        platform: platform,
        receiptData: data['receiptData'] as String?,
        originalTransactionId: data['originalTransactionId'] as String?,
        extend: data['extend'] as Map<String, dynamic>?,
      );

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/payment/verifynotify',
        data: request.toJson(),
      );

      if (response.data == null) {
        return const Left('验证响应为空');
      }

      final responseData = response.data!;
      debugPrint('verify notify data=$responseData, method=$method');

      // 🔑 根据支付方式使用不同的验证逻辑
      final isSuccess = _isVerifySuccessful(method, responseData);
      if (isSuccess) {
        return Right(responseData);
      } else {
        final errorMsg = responseData['msg'] as String?;
        return Left('验证失败: ${errorMsg ?? '购买状态不符合要求'}');
      }
    } on DioException catch (e) {
      // 🔒 修复：DioException.message 可能为 null，提供更友好的错误信息
      final errorMsg = e.message ?? _getDioExceptionMessage(e.type);
      return Left('验证请求失败: $errorMsg');
    } catch (e) {
      return Left('验证异常: $e');
    }
  }

  /// 根据支付方式判断验证是否成功
  bool _isVerifySuccessful(PaymentMethod method, Map<String, dynamic> responseData) {
    return isPurchaseSuccessfulAndAcknowledged(responseData);
  }

  /// 根据 DioExceptionType 获取友好的错误信息
  String _getDioExceptionMessage(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.sendTimeout:
        return '发送超时';
      case DioExceptionType.receiveTimeout:
        return '接收超时';
      case DioExceptionType.badCertificate:
        return '证书验证失败';
      case DioExceptionType.badResponse:
        return '服务器响应异常';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '网络连接错误';
      case DioExceptionType.unknown:
        return '网络请求失败';
    }
  }

  /// 从数据中检测平台类型
  String _detectPlatform(Map<String, dynamic> data) {
    // 如果有purchaseToken说明是Android
    if (data['purchaseToken'] != null || data['packageName'] != null) {
      return 'android';
    }
    // 如果有receiptData或originalTransactionId说明是iOS
    if (data['receiptData'] != null || data['originalTransactionId'] != null) {
      return 'ios';
    }
    // 默认返回android
    return 'android';
  }

  /// 取消订单 - 用于在新支付请求前取消未支付的订单
  ///
  /// 在每次发起支付请求前，应先检查本地是否有未支付的订单。
  /// 如果存在未支付订单，调用此接口取消该订单后再发起新的支付请求。
  ///
  /// 参数：
  /// - [orderId]: 订单ID（可选，不传时后端会根据其他条件查找）
  /// - [reason]: 取消原因（必需）
  /// - [productId]: 产品ID（可选）
  Future<Either<String, Map<String, dynamic>>> cancelOrder({
    String? orderId,
    required String reason,
    String? productId,
  }) async {
    try {
      final requestData = <String, dynamic>{
        if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
        'reason': reason,
        if (productId != null) 'product_id': productId,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/payment/cancelorder',
        data: requestData,
      );

      if (response.data == null) {
        return const Left('取消订单失败：无响应数据');
      }

      // 检查响应格式
      final responseData = response.data!;
      final code = responseData['code'] as int?;
      final msg = responseData['msg'] as String?;

      if (code != null && code != 0) {
        return Left('取消订单失败: ${msg ?? '未知错误'}');
      }

      return Right(responseData);
    } on DioException catch (e) {
      return Left('取消订单请求失败: ${e.message}');
    } catch (e) {
      return Left('取消订单异常: $e');
    }
  }
}

/// 判断Google Play购买是否成功且已确认
///
/// 根据Google Play验证响应判断购买是否成功。
///
/// 判断逻辑：
/// 1. 基础通信成功：success == true
/// 2. 令牌技术合法：data.valid == true
/// 3. 订阅业务活跃：data.purchase_state == "active" 或 "purchased"
///
/// ⚠️ 警告处理：
/// 如果购买成功但 acknowledgementState 为 PENDING，将打印警告，
/// 提示需要立即执行 Acknowledge 操作以防止退款。
///
/// 参数：
/// - [responseData]: 从 verifyNotify API 返回的完整响应数据
///
/// 返回：
/// - true: 购买成功且订阅活跃（授予访问权限）
/// - false: 购买失败或状态不符合要求
bool isPurchaseSuccessfulAndAcknowledged(Map<String, dynamic> responseData) {
  // Step 1: 基础通信成功？
  if (responseData['success'] != true) {
    return false;
  }

  final data = responseData['data'] as Map<String, dynamic>?;
  if (data == null) {
    return false;
  }

  // Step 2: 令牌技术合法？
  if (data['valid'] != true) {
    return false;
  }

  // Step 3: 订阅业务活跃？
  final purchaseState = data['purchase_state'] as String?;
  final transactionReason = data['transaction_reason'] as String?;

  // 🔑 有效状态：active, purchased
  // 🔑 特殊情况：expired 但 transaction_reason=PURCHASE 且 valid=true
  //    这在 Sandbox 环境常见（订阅快速过期/续费），或者是续费通知
  final isValidState = purchaseState == 'active' || purchaseState == 'purchased';
  final isNewPurchaseWithExpired = purchaseState == 'expired' &&
      transactionReason == 'PURCHASE' &&
      data['valid'] == true;

  if (!isValidState && !isNewPurchaseWithExpired) {
    debugPrint('⚠️ [验证] 状态不符: state=$purchaseState, reason=$transactionReason');
    return false;
  }

  // 所有成功条件都满足，现在检查警告/风险
  final raw = data['raw'] as Map<String, dynamic>?;
  final subscriptionV2 = raw?['subscriptionV2'] as Map<String, dynamic>?;
  final ackState = subscriptionV2?['acknowledgementState'] as String?;

  if (ackState == 'ACKNOWLEDGEMENT_STATE_PENDING') {
    // 打印高优先级警告
    print('🚨 WARNING: Purchase successful but Acknowledge is PENDING. '
        'Immediate Acknowledge action required to prevent refund.');
  }

  // 理想状态或已确认状态，授予访问权限
  return true;
}

/// PayApi Provider - 极简设计
final payApiProvider = Provider<PayApi>((ref) {
  return PayApi(ref: ref);
});
