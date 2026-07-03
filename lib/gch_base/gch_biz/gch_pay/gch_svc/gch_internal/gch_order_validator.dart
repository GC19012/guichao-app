import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_wire/gch_appprovider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 订单校验服务
/// 职责：
/// 1. 检查未支付订单
/// 2. 校验订单有效期
/// 3. 提供订单预检查结果
class OrderValidator {
  final Ref? ref;

  OrderValidator({this.ref});

  /// 检查是否存在未支付订单
  /// 返回值：
  /// - null: 无未支付订单或已过期，可以创建新订单
  /// - IResponse: 存在有效的未支付订单，需要用户处理
  Future<IResponse?> checkUnpaidOrder({
    required String? userId,
    required String? productId,
    required String? productName,
  }) async {
    if (ref == null || userId == null || productId == null) {
      return null;
    }

    try {
      final orderService = ref!.read(orderServiceProvider);
      debugPrint('🔎 Unpaid precheck: sessionUserId=${userId.trim()}, productId=$productId');

      // 查询该用户该产品的未支付订单
      final unpaidOrder = await orderService.getUnpaidOrder(userId, productId);
      if (unpaidOrder == null) {
        return null; // 无未支付订单
      }
      debugPrint(
        '🔎 Unpaid precheck hit: orderNum=${unpaidOrder.orderNum}, '
        'orderUserId=${unpaidOrder.userId}, productId=${unpaidOrder.productId}, '
        'storeProductId=${unpaidOrder.storeProductId}',
      );

      // 检查订单是否还在有效期内（10分钟）
      final createTime = unpaidOrder.createAt;
      final now = DateTime.now();
      final timeDifference = now.difference(createTime);

      if (timeDifference.inMinutes < 10) {
        // 订单仍在有效期内，返回提示信息
        debugPrint('⚠️ 发现有效的未支付订单: ${unpaidOrder.orderNum}');
        return PaymentResponse.processing(
          message: '存在未完成订单，请提示用户继续支付或取消',
          data: {
            'hasUnpaidOrder': true,
            'action': 'show_unpaid_order_dialog',
            'unpaidOrder': {
              'orderNum': unpaidOrder.orderNum,
              'productName': unpaidOrder.productName,
              'total': unpaidOrder.total,
              'currency': unpaidOrder.currency,
              'createAt': unpaidOrder.createAt.toIso8601String(),
              'remainingMinutes': 10 - timeDifference.inMinutes,
              'remainingSeconds': (10 * 60) - timeDifference.inSeconds,
            }
          },
        );
      } else {
        // 订单已过期，可以创建新订单
        debugPrint('ℹ️ 找到过期的未支付订单，将创建新订单');
        return null;
      }
    } catch (e) {
      debugPrint('❌ 检查未支付订单失败: $e');
      return null; // 出错时允许继续
    }
  }

  /// 批量检查多个订单状态
  Future<Map<String, bool>> checkMultipleOrders(List<String> orderIds) async {
    final results = <String, bool>{};

    if (ref == null) return results;

    try {
      for (final orderId in orderIds) {
        try {
          // 这里可以调用orderService的相关方法检查订单状态
          // 示例：检查订单是否存在且未支付
          results[orderId] = true; // placeholder
        } catch (e) {
          debugPrint('❌ 检查订单 $orderId 失败: $e');
          results[orderId] = false;
        }
      }
    } catch (e) {
      debugPrint('❌ 批量检查订单失败: $e');
    }

    return results;
  }

  /// 验证订单参数
  bool validateOrderParams(Map<String, dynamic> params) {
    final userId = params['userId']?.toString();
    final productId = params['productId']?.toString();

    if (userId == null || userId.isEmpty) {
      debugPrint('❌ 订单参数校验失败: userId为空');
      return false;
    }

    if (productId == null || productId.isEmpty) {
      debugPrint('❌ 订单参数校验失败: productId为空');
      return false;
    }

    return true;
  }
}
