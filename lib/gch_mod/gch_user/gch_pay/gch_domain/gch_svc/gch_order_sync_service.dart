import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_svc/gch_order_recovery_service.dart';
import 'package:guichao/gch_base/gch_biz/gch_wire/gch_appprovider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_order_sync_service.g.dart';

/// Order Sync Service Provider
@Riverpod(keepAlive: true)
OrderSyncService orderSyncService(OrderSyncServiceRef ref) {
  final service = OrderSyncService(ref: ref);
  ref.onDispose(service.dispose);
  return service;
}

/// Order Sync Service - Order State Management
///
/// Responsibilities:
/// 1. Check unpaid orders before payment
/// 2. Sync order state after cancellation
/// 3. Trigger order recovery
/// 4. Query recent paid orders
///
/// Design: Stateless service, depends on OrderService/OrderManager
class OrderSyncService {
  final Ref ref;

  Timer? _postCancelSyncTimer;

  OrderSyncService({required this.ref});

  // ========== Unpaid Order Check ==========

  /// Check for unpaid order before payment
  /// Returns the unpaid order if exists, null otherwise
  Future<OrderEntry?> checkUnpaidOrder({
    required String userId,
    required String productId,
  }) async {
    try {
      debugPrint('🔍 Checking unpaid order: userId=$userId, productId=$productId');

      final orderService = ref.read(AppProvider.orders.service);
      final unpaidOrder = await orderService.getUnpaidOrder(userId, productId);

      if (unpaidOrder != null) {
        final createTime = unpaidOrder.createAt;
        final now = DateTime.now();
        final timeDifference = now.difference(createTime);
        if (timeDifference.inMinutes >= 10) {
          debugPrint('ℹ️ 未支付订单已过期，跳过: ${unpaidOrder.orderNum}');
          return null;
        }
        debugPrint('📦 Found unpaid order: ${unpaidOrder.orderNum}');
      } else {
        debugPrint('✅ No unpaid order found');
      }

      return unpaidOrder;
    } catch (e) {
      debugPrint('❌ Check unpaid order failed: $e');
      return null;
    }
  }

  /// Check if user has any unpaid orders
  Future<List<OrderEntry>> getAllUnpaidOrders(String userId) async {
    try {
      final orderService = ref.read(AppProvider.orders.service);
      final orders = await orderService.getOrdersByPayStatus(PayStatus.unpaid);
      return orders.where((o) => o.userId == userId).toList();
    } catch (e) {
      debugPrint('❌ Get all unpaid orders failed: $e');
      return [];
    }
  }

  // ========== Order State Sync ==========

  /// Sync order state after cancellation
  /// Performs immediate sync + delayed sync (20s)
  Future<void> syncAfterCancellation({
    required String userId,
    required String? productId,
  }) async {
    // Cancel existing timer
    _postCancelSyncTimer?.cancel();

    // Immediate sync
    await _performSync(userId, productId);

    // Delayed sync (20s) to catch any delayed updates
    _postCancelSyncTimer = Timer(const Duration(seconds: 20), () async {
      try {
        await _performSync(userId, productId);
      } catch (e) {
        debugPrint('❌ Post-cancel sync failed: $e');
      }
    });
  }

  Future<void> _performSync(String userId, String? productId) async {
    try {
      debugPrint('🔄 Syncing order state: userId=$userId, productId=$productId');

      if (productId != null) {
        await checkUnpaidOrder(userId: userId, productId: productId);
      }

      debugPrint('✅ Order state sync completed');
    } catch (e) {
      debugPrint('❌ Order state sync failed: $e');
    }
  }

  // ========== Order Recovery ==========

  /// Trigger order recovery for incomplete orders
  Future<void> triggerOrderRecovery({String reason = 'manual'}) async {
    try {
      debugPrint('🔄 Triggering order recovery: reason=$reason');

      final recoveryService = ref.read(orderRecoveryServiceProvider);
      await recoveryService.processIncompleteOrders();

      debugPrint('✅ Order recovery completed');
    } catch (e) {
      debugPrint('❌ Order recovery failed ($reason): $e');
    }
  }

  // ========== Recent Paid Orders ==========

  /// Query recent paid orders (within specified duration)
  Future<List<OrderEntry>> getRecentPaidOrders({
    required String userId,
    Duration within = const Duration(minutes: 5),
  }) async {
    try {
      final orderService = ref.read(AppProvider.orders.service);
      final paidOrders = await orderService.getOrdersByPayStatus(PayStatus.paid);

      final now = DateTime.now();
      final recentOrders = paidOrders.where((order) {
        final timeDiff = now.millisecondsSinceEpoch - order.createAt.millisecondsSinceEpoch;
        return timeDiff < within.inMilliseconds && order.userId == userId;
      }).toList();

      debugPrint('📦 Found ${recentOrders.length} recent paid orders');
      return recentOrders;
    } catch (e) {
      debugPrint('❌ Get recent paid orders failed: $e');
      return [];
    }
  }

  /// Check if there's a recent successful payment
  Future<OrderEntry?> findRecentSuccessfulPayment({
    required String userId,
    Duration within = const Duration(minutes: 5),
  }) async {
    final recentOrders = await getRecentPaidOrders(userId: userId, within: within);
    return recentOrders.isNotEmpty ? recentOrders.first : null;
  }

  // ========== Cleanup ==========

  void dispose() {
    _postCancelSyncTimer?.cancel();
    _postCancelSyncTimer = null;
    debugPrint('✅ OrderSyncService disposed');
  }
}

/// Unpaid Order Info (for UI display)
class UnpaidOrderInfo {
  final String orderId;
  final String productName;
  final double amount;
  final String currency;
  final DateTime createdAt;

  const UnpaidOrderInfo({
    required this.orderId,
    required this.productName,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  factory UnpaidOrderInfo.fromOrderEntry(OrderEntry order) {
    return UnpaidOrderInfo(
      orderId: order.orderNum,
      productName: order.productName ?? 'Unknown Product',
      amount: order.total,
      currency: order.currency ?? 'USD',
      createdAt: order.createAt,
    );
  }
}
