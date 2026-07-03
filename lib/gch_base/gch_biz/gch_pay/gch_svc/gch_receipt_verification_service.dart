import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:guichao/gch_base/gch_flux/gch_flux_engine.dart';
import 'package:guichao/gch_base/gch_biz/gch_wire/gch_appprovider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// 收据验证结果
class ReceiptVerificationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? serverResponse;
  final DateTime? expirationDate;
  final String? originalTransactionId;
  final bool isTestPurchase; // 是否为测试购买

  const ReceiptVerificationResult({
    required this.isValid,
    this.errorMessage,
    this.serverResponse,
    this.expirationDate,
    this.originalTransactionId,
    this.isTestPurchase = false,
  });

  factory ReceiptVerificationResult.success({
    Map<String, dynamic>? serverResponse,
    DateTime? expirationDate,
    String? originalTransactionId,
    bool isTestPurchase = false,
  }) {
    return ReceiptVerificationResult(
      isValid: true,
      serverResponse: serverResponse,
      expirationDate: expirationDate,
      originalTransactionId: originalTransactionId,
      isTestPurchase: isTestPurchase,
    );
  }

  factory ReceiptVerificationResult.failure(String errorMessage) {
    return ReceiptVerificationResult(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}

/// 应用内购买收据验证服务
/// 客户端负责基础验证，服务端调用Google/Apple官方API进行真实验证
class ReceiptVerificationService {
  final GchFluxEngine _httpClient;
  PackageInfo? _packageInfo;

  // 验证配置
  static const int _maxRetries = 3;

  ReceiptVerificationService(this._httpClient);

  /// 验证应用内购买收据
  /// [purchaseDetails] - 购买详情
  /// [orderId] - 本地订单ID（可选）
  Future<ReceiptVerificationResult> verifyInAppPurchase(
    PurchaseDetails purchaseDetails, {
    String? orderId,
  }) async {
    try {
      // 1. 客户端基础验证
      final clientValidation = _basicValidate(purchaseDetails);
      if (!clientValidation.isValid) {
        return clientValidation;
      }

      // 2. 发送到服务端验证（服务端会调用Google/Apple官方API）
      return await _serverVerify(purchaseDetails, orderId);
    } catch (e, stackTrace) {
      debugPrint('收据验证异常: $e\n$stackTrace');
      return ReceiptVerificationResult.failure('验证过程出现异常: $e');
    }
  }

  /// 基础验证（检查数据完整性和格式）
  ReceiptVerificationResult _basicValidate(PurchaseDetails purchaseDetails) {
    // 1. 检查购买状态
    if (purchaseDetails.status != PurchaseStatus.purchased) {
      return ReceiptVerificationResult.failure('购买状态无效: ${purchaseDetails.status}');
    }

    // 2. 检查必要字段
    if (purchaseDetails.purchaseID == null || purchaseDetails.purchaseID!.isEmpty) {
      return ReceiptVerificationResult.failure('购买ID为空');
    }

    if (purchaseDetails.productID.isEmpty) {
      return ReceiptVerificationResult.failure('产品ID为空');
    }

    // 3. 检查验证数据
    final verificationData = purchaseDetails.verificationData;
    if (verificationData.serverVerificationData.isEmpty) {
      return ReceiptVerificationResult.failure('收据数据为空');
    }

    // 4. iOS收据验证
    return _validateIOSPurchase(purchaseDetails);
  }

  /// iOS购买验证
  ReceiptVerificationResult _validateIOSPurchase(PurchaseDetails purchaseDetails) {
    try {
      // iOS收据是Base64编码的二进制数据
      final receiptData = purchaseDetails.verificationData.serverVerificationData;

      // 检查是否为有效的Base64
      if (!_isValidBase64(receiptData)) {
        return ReceiptVerificationResult.failure('iOS收据不是有效的Base64格式');
      }

      // iOS收据通常比较长
      if (receiptData.length < 100) {
        return ReceiptVerificationResult.failure('iOS收据长度异常');
      }

      return ReceiptVerificationResult.success();
    } catch (e) {
      return ReceiptVerificationResult.failure('iOS收据验证失败: $e');
    }
  }

  /// 检查是否为有效的Base64编码
  bool _isValidBase64(String str) {
    try {
      base64.decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 服务端验证
  Future<ReceiptVerificationResult> _serverVerify(
    PurchaseDetails purchaseDetails,
    String? orderId,
  ) async {
    const platform = 'ios';

    // 构建验证请求
    final requestBody = {
      'platform': platform,
      'product_id': purchaseDetails.productID,
      'purchase_id': purchaseDetails.purchaseID,
      'receipt_data': purchaseDetails.verificationData.serverVerificationData,
      'transaction_date': purchaseDetails.transactionDate,
      'order_id': orderId, // 本地订单ID
      'app_version': 'your_app_version', // 应用版本
      'client_timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _packageInfo ??= await PackageInfo.fromPlatform();
    requestBody['bundle_id'] = _packageInfo!.packageName;

    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        final response = await _httpClient.post(
          '/api/verify-iap-receipt', // 专门的应用内购买验证接口
          data: requestBody,
        );

        if (response.statusCode == 200) {
          final responseData = response.data as Map<String, dynamic>;
          return _parseServerResponse(responseData);
        } else {
          throw Exception('服务器返回错误状态码: ${response.statusCode}');
        }
      } catch (e) {
        attempts++;
        if (attempts >= _maxRetries) {
          return ReceiptVerificationResult.failure('服务端验证失败（重试$_maxRetries次后）: $e');
        }

        // 指数退避重试
        await Future.delayed(Duration(seconds: 2 * attempts));
        debugPrint('收据验证重试第$attempts次: $e');
      }
    }

    return ReceiptVerificationResult.failure('验证超时');
  }

  /// 解析服务端响应
  ReceiptVerificationResult _parseServerResponse(Map<String, dynamic> response) {
    final isValid = response['valid'] as bool? ?? false;

    if (!isValid) {
      final errorMessage = response['error'] as String? ?? '收据验证失败';
      final errorCode = response['error_code'] as String?;

      // 根据错误码提供更友好的错误信息
      String friendlyError = errorMessage;
      if (errorCode != null) {
        friendlyError = _getFriendlyErrorMessage(errorCode) ?? errorMessage;
      }

      return ReceiptVerificationResult.failure(friendlyError);
    }

    // 解析验证结果中的额外信息
    DateTime? expirationDate;
    if (response['expires_date_ms'] != null) {
      try {
        expirationDate = DateTime.fromMillisecondsSinceEpoch(
          response['expires_date_ms'] as int,
        );
      } catch (e) {
        debugPrint('解析到期时间失败: $e');
      }
    }

    final originalTransactionId = response['original_transaction_id'] as String?;
    final isTestPurchase = response['is_trial_period'] as bool? ?? response['is_in_intro_offer_period'] as bool? ?? false;

    return ReceiptVerificationResult.success(
      serverResponse: response,
      expirationDate: expirationDate,
      originalTransactionId: originalTransactionId,
      isTestPurchase: isTestPurchase,
    );
  }

  /// 根据错误码获取友好的错误信息
  String? _getFriendlyErrorMessage(String errorCode) {
    final errorMessages = {
      '21000': '收据数据格式错误',
      '21002': '收据数据已损坏',
      '21003': '收据无法通过身份验证',
      '21004': '共享密钥不匹配',
      '21005': '收据服务器暂时不可用',
      '21006': '订阅已过期',
      '21007': '收据来自测试环境',
      '21008': '收据来自生产环境',
      '21010': '收据已被处理',
      'INVALID_PURCHASE': '无效的购买',
      'ALREADY_OWNED': '商品已拥有',
      'NOT_OWNED': '未拥有该商品',
      'CONSUMED': '商品已消耗',
      'EXPIRED': '购买已过期',
    };

    return errorMessages[errorCode];
  }

  /// 验证订阅状态
  Future<ReceiptVerificationResult> verifySubscription(
    PurchaseDetails purchaseDetails, {
    String? orderId,
    bool checkExpirationDate = true,
  }) async {
    final result = await verifyInAppPurchase(purchaseDetails, orderId: orderId);

    if (!result.isValid) {
      return result;
    }

    // 对于订阅，额外检查到期时间
    if (checkExpirationDate && result.expirationDate != null) {
      final now = DateTime.now();
      if (result.expirationDate!.isBefore(now)) {
        return ReceiptVerificationResult.failure('订阅已过期');
      }

      // 检查即将到期（24小时内）
      final willExpireSoon = result.expirationDate!.isBefore(
        now.add(const Duration(hours: 24)),
      );

      if (willExpireSoon) {
        debugPrint('订阅即将在${result.expirationDate}到期');
        // 可以在这里触发续费提醒
      }
    }

    return result;
  }

  /// 批量验证购买
  Future<Map<String, ReceiptVerificationResult>> batchVerify(
    List<PurchaseDetails> purchases,
  ) async {
    final results = <String, ReceiptVerificationResult>{};

    // 使用Future.wait限制并发数量
    const batchSize = 3;
    for (var i = 0; i < purchases.length; i += batchSize) {
      final batch = purchases.skip(i).take(batchSize);
      final futures = batch.map((purchase) async {
        final result = await verifyInAppPurchase(purchase);
        final key = purchase.purchaseID ?? purchase.productID;
        results[key] = result;
      });
      await Future.wait(futures);
    }
    return results;
  }
}

// 已移除Semaphore类，使用更简单的批处理方式

/// Riverpod Provider
final receiptVerificationServiceProvider = Provider<ReceiptVerificationService>((ref) {
  final httpClient = ref.read(AppProvider.core.http);
  return ReceiptVerificationService(httpClient);
});
