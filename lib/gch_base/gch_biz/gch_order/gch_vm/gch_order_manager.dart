import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_svc/gch_order_service.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_vm/gch_order_state.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_vm/gch_order_viewmodel.dart';

part 'gch_order_manager.g.dart';

/// 统一的订单管理器
///
/// - 不再维护本地缓存，所有数据直接来源于底层存储（Realm/SQLite）
/// - 只负责同步状态、错误信息和对外的增删改操作
@Riverpod(keepAlive: true)
class OrderManager extends _$OrderManager {
  Timer? _autoSyncTimer;

  /// 获取 OrderService
  ///
  /// 注意：apiClientProvider 使用 keepAlive + listen 模式，不会因用户认证变化重建
  /// 因此 orderServiceProvider 是稳定的，可以安全地 read
  OrderService get _service => ref.read(orderServiceProvider);

  @override
  Future<OrderManagerState> build() async {
    _setupAutoSync();
    _setupUserListener();
    ref.onDispose(() {
      _autoSyncTimer?.cancel();
    });
    return const OrderManagerState();
  }

  /// 监听用户切换，重置并同步
  void _setupUserListener() {
    String? prevUserId;
    ref.listen(currentUserProvider, (_, next) {
      final userId = next.valueOrNull?.userId;
      if (prevUserId != null && prevUserId != userId) {
        debugPrint('🔄 OrderManager: 用户切换 $prevUserId -> $userId');
        _resetState();
        if (userId != null) _syncRemoteOrders();
      }
      prevUserId = userId;
    });
  }

  /// 重置状态
  void _resetState() {
    state = const AsyncData(OrderManagerState());
    debugPrint('📋 OrderManager: 状态已重置');
  }

  void _setupAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _syncRemoteOrders(),
    );
  }

  void _updateState(OrderManagerState Function(OrderManagerState) reducer) {
    final current = state.valueOrNull ?? const OrderManagerState();
    state = AsyncData(reducer(current));
  }

  Future<void> _syncRemoteOrders() async {
    _updateState((s) => s.copyWith(syncStatus: SyncStatus.syncing));
    try {
      await _service.syncOrders();
      _updateState(
        (s) => s.copyWith(
          syncStatus: SyncStatus.success,
          lastSyncTime: DateTime.now(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      _updateState(
        (s) => s.copyWith(
          syncStatus: SyncStatus.failed,
          errorMessage: '同步失败: $e',
        ),
      );
    }
  }

  // ==================== CRUD 操作 ====================

  Future<bool> createOrder(OrderEntry order) async {
    _updateState((s) => s.copyWith(isLoading: true, errorMessage: null));
    try {
      await _service.createOrder(order);
      _updateState((s) => s.copyWith(isLoading: false));
      return true;
    } catch (e) {
      _updateState(
        (s) => s.copyWith(isLoading: false, errorMessage: '创建订单失败: $e'),
      );
      return false;
    }
  }

  Future<bool> upsertOrder(OrderEntry order) async {
    _updateState((s) => s.copyWith(isLoading: true, errorMessage: null));
    try {
      await _service.upsertOrder(order);
      _updateState((s) => s.copyWith(isLoading: false));
      return true;
    } catch (e) {
      _updateState(
        (s) => s.copyWith(isLoading: false, errorMessage: '更新订单失败: $e'),
      );
      return false;
    }
  }

  Future<OrderEntry?> cancelOrder(String orderId, String reason) async {
    _updateState((s) => s.copyWith(isLoading: true, errorMessage: null));
    try {
      final result = await _service.cancelOrder(orderId, reason);
      _updateState((s) => s.copyWith(isLoading: false));
      return result;
    } catch (e) {
      _updateState(
        (s) => s.copyWith(isLoading: false, errorMessage: '取消订单失败: $e'),
      );
      return null;
    }
  }

  Future<bool> deleteOrder(String orderNum) async {
    _updateState((s) => s.copyWith(isLoading: true, errorMessage: null));
    try {
      await _service.deleteOrder(orderNum);
      _updateState((s) => s.copyWith(isLoading: false));
      return true;
    } catch (e) {
      _updateState(
        (s) => s.copyWith(isLoading: false, errorMessage: '删除订单失败: $e'),
      );
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderNum, OrderStatus status) async {
    try {
      await _service.updateOrderStatus(orderNum, status);
      return true;
    } catch (e) {
      _updateState(
        (s) => s.copyWith(errorMessage: '更新订单状态失败: $e'),
      );
      return false;
    }
  }

  Future<bool> updatePayStatus(String orderNum, PayStatus status) async {
    try {
      await _service.updatePayStatus(orderNum, status);
      return true;
    } catch (e) {
      _updateState(
        (s) => s.copyWith(errorMessage: '更新支付状态失败: $e'),
      );
      return false;
    }
  }

  Future<bool> batchUpsertOrders(List<OrderEntry> orders) async {
    _updateState((s) => s.copyWith(isLoading: true, errorMessage: null));
    try {
      for (final order in orders) {
        await _service.upsertOrder(order);
      }
      _updateState((s) => s.copyWith(isLoading: false));
      return true;
    } catch (e) {
      _updateState(
        (s) => s.copyWith(isLoading: false, errorMessage: '批量更新失败: $e'),
      );
      return false;
    }
  }

  // ==================== 同步控制 ====================

  Future<void> syncNow() async {
    await _syncRemoteOrders();
  }

  Future<bool> syncOrderByNum(String orderNum) async {
    try {
      await _service.syncOrderById(orderNum);
      return true;
    } catch (e) {
      _updateState(
        (s) => s.copyWith(errorMessage: '同步订单失败: $e'),
      );
      return false;
    }
  }

  /// 按应用商店交易ID同步订单（Apple transactionId）
  Future<OrderEntry?> syncOrderByStoreTransactionId(String storeTransactionId) async {
    try {
      final order = await _service.syncOrderByStoreTransactionId(storeTransactionId);
      return order;
    } catch (e) {
      _updateState(
        (s) => s.copyWith(errorMessage: '按交易ID同步订单失败: $e'),
      );
      return null;
    }
  }

  void clearError() {
    _updateState((s) => s.copyWith(errorMessage: null));
  }

  String getSyncStatusDescription() {
    final status = state.valueOrNull?.syncStatus ?? SyncStatus.idle;
    switch (status) {
      case SyncStatus.idle:
        return '空闲';
      case SyncStatus.syncing:
        return '同步中...';
      case SyncStatus.success:
        return '同步成功';
      case SyncStatus.failed:
        return '同步失败';
    }
  }

  // ==================== 数据访问 ====================

  /// 获取当前用户ID
  String? get _currentUserId => ref.read(currentUserProvider).valueOrNull?.userId;

  /// 按当前用户筛选订单流
  Stream<List<OrderEntry>> watchOrders() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);
    return _service.watchOrders().map(
      (orders) => orders.where((o) => o.userId == userId).toList(),
    );
  }

  Future<List<OrderEntry>> getAllOrders() => watchOrders().first;

  Future<OrderEntry?> getOrderByNum(String orderNum) =>
      _service.getOrderById(orderNum);

  Future<List<OrderEntry>> getOrdersByStatus(OrderStatus status) async {
    final orders = await getAllOrders();
    return orders.where((o) => o.status == status.value).toList();
  }

  Future<List<OrderEntry>> getOrdersByPayStatus(PayStatus status) async {
    final orders = await getAllOrders();
    return orders.where((o) => o.payStatus == status.value).toList();
  }

  Future<List<OrderEntry>> getOrdersByUserId(String userId) async {
    final orders = await _service.watchOrders().first;
    return orders.where((o) => o.userId == userId).toList();
  }

  Future<List<OrderEntry>> getOrdersByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final orders = await getAllOrders();
    return orders.where((o) =>
      o.createAt.isAfter(start) && o.createAt.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  Future<List<OrderEntry>> getOrdersByProductId(int productId) async {
    final orders = await getAllOrders();
    return orders.where((o) => o.productId == productId).toList();
  }

  Future<List<OrderEntry>> getOrdersByPaymentMethod(int? payProvider) async {
    final orders = await getAllOrders();
    if (payProvider == null) {
      return orders.where((o) => o.payProvider == null).toList();
    }
    return orders.where((o) => o.payProvider == payProvider).toList();
  }

  Future<List<OrderEntry>> getRecentOrders({int limit = 10}) async {
    final orders = await getAllOrders();
    orders.sort((a, b) => b.createAt.compareTo(a.createAt));
    return orders.take(limit).toList();
  }

  Future<List<OrderEntry>> getPendingOrders() async {
    final orders = await getAllOrders();
    return orders
        .where((o) =>
            o.payStatus == PayStatus.unpaid.value &&
            o.status == OrderStatus.pending.value)
        .toList();
  }

  Future<List<OrderEntry>> getCompletedOrders() async {
    final orders = await getAllOrders();
    return orders
        .where((o) => o.status == OrderStatus.completed.value)
        .toList();
  }

  Future<OrderEntry?> getUnpaidOrder(String userId, int productId) =>
      _service.getUnpaidOrder(userId, productId.toString());
}

// ==================== 便捷访问 Providers ====================

@riverpod
Future<List<OrderEntry>> allOrders(AllOrdersRef ref) {
  final manager = ref.watch(orderManagerProvider.notifier);
  return manager.getAllOrders();
}

@riverpod
Future<OrderEntry?> orderByNum(OrderByNumRef ref, String orderNum) {
  final manager = ref.watch(orderManagerProvider.notifier);
  return manager.getOrderByNum(orderNum);
}

@riverpod
Future<List<OrderEntry>> pendingOrders(PendingOrdersRef ref) async {
  final manager = ref.watch(orderManagerProvider.notifier);
  return manager.getPendingOrders();
}

@riverpod
Future<List<OrderEntry>> completedOrders(CompletedOrdersRef ref) async {
  final manager = ref.watch(orderManagerProvider.notifier);
  return manager.getCompletedOrders();
}

@riverpod
SyncStatus orderSyncStatus(OrderSyncStatusRef ref) {
  final manager = ref.watch(orderManagerProvider);
  return manager.when(
    data: (state) => state.syncStatus,
    loading: () => SyncStatus.syncing,
    error: (_, __) => SyncStatus.failed,
  );
}

@riverpod
DateTime? lastSyncTime(LastSyncTimeRef ref) {
  final manager = ref.watch(orderManagerProvider);
  return manager.when(
    data: (state) => state.lastSyncTime,
    loading: () => null,
    error: (_, __) => null,
  );
}
