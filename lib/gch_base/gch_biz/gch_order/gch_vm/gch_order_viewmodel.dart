import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_store/gch_db_provider.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_providers/gch_api_client_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_dao/gch_order_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_dao/gch_order_dao_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_dao/gch_sqlite_order_dao_adapter.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_repo/gch_order_repository.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_svc/gch_order_service.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_vm/gch_order_manager.dart';

/// Order DAO Provider - SQLite 实现
final orderDaoProvider = Provider<OrderDaoInterface>((ref) {
  final db = ref.watch(gchDatabaseProvider);
  return SQLiteOrderDaoAdapter(OrderDAO(db));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  // ✅ 使用 watch 确保当 apiClient 重建时，Repository 也会重建
  return OrderRepository(
    ref.watch(orderDaoProvider),
    ref.watch(apiClientProvider),
  );
});

final orderServiceProvider = Provider<OrderService>((ref) {
  // ✅ 使用 watch 确保当 Repository 或 apiClient 重建时，Service 也会重建
  return OrderService(
    ref.watch(orderRepositoryProvider),
    ref.watch(apiClientProvider),
  );
});

// ===============================
// Orders 列表 ViewModel (向后兼容适配层)
// 实际功能已迁移至 OrderManager
// ===============================
class OrdersNotifier extends AsyncNotifier<List<OrderEntry>> {
  @override
  Future<List<OrderEntry>> build() async {
    final manager = ref.watch(orderManagerProvider.notifier);
    final stream = manager.watchOrders();

    final subscription = stream.listen((orders) {
      state = AsyncData(orders);
    });
    ref.onDispose(subscription.cancel);

    return stream.first;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final manager = ref.read(orderManagerProvider.notifier);
    await manager.syncNow();
    state = await AsyncValue.guard(manager.getAllOrders);
  }

  Future<void> create(OrderEntry order) async {
    state = const AsyncLoading();
    final manager = ref.read(orderManagerProvider.notifier);
    final success = await manager.createOrder(order);
    if (success) {
      await refresh();
    } else {
      state = AsyncError('创建订单失败', StackTrace.current);
    }
  }

  Future<void> updateOrderStatus(String ordernum, OrderStatus status) async {
    state = const AsyncLoading();
    final manager = ref.read(orderManagerProvider.notifier);
    final success = await manager.updateOrderStatus(ordernum, status);
    if (success) {
      await refresh();
    } else {
      state = AsyncError('更新订单状态失败', StackTrace.current);
    }
  }

  Future<void> updatePayStatus(String ordernum, PayStatus status) async {
    state = const AsyncLoading();
    final manager = ref.read(orderManagerProvider.notifier);
    final success = await manager.updatePayStatus(ordernum, status);
    if (success) {
      await refresh();
    } else {
      state = AsyncError('更新支付状态失败', StackTrace.current);
    }
  }

  Future<void> sync() async {
    state = const AsyncLoading();
    await ref.read(orderManagerProvider.notifier).syncNow();
    await refresh();
  }

  Future<void> delete(String ordernum) async {
    state = const AsyncLoading();
    final manager = ref.read(orderManagerProvider.notifier);
    final success = await manager.deleteOrder(ordernum);
    if (success) {
      await refresh();
    } else {
      state = AsyncError('删除订单失败', StackTrace.current);
    }
  }
}

final ordersProvider =
    AsyncNotifierProvider<OrdersNotifier, List<OrderEntry>>(OrdersNotifier.new);

// ===============================
// Order 详情 ViewModel (向后兼容适配层)
// ===============================
class OrderDetailNotifier extends FamilyAsyncNotifier<OrderEntry?, String> {
  @override
  Future<OrderEntry?> build(String ordernum) async {
    final manager = ref.watch(orderManagerProvider.notifier);

    OrderEntry? selector(List<OrderEntry> orders) {
      for (final order in orders) {
        if (order.orderNum == ordernum) {
          return order;
        }
      }
      return null;
    }

    final stream = manager.watchOrders().map(selector);
    final subscription = stream.listen((order) {
      state = AsyncData(order);
    });
    ref.onDispose(subscription.cancel);

    return stream.first;
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    final manager = ref.read(orderManagerProvider.notifier);
    await manager.syncOrderByNum(arg);
    state = await AsyncValue.guard(() => manager.getOrderByNum(arg));
  }

  Future<void> updateOrderStatus(OrderStatus status) async {
    state = const AsyncLoading();
    final manager = ref.read(orderManagerProvider.notifier);
    final success = await manager.updateOrderStatus(arg, status);
    if (success) {
      await reload();
    } else {
      state = AsyncError('更新订单状态失败', StackTrace.current);
    }
  }

  Future<void> updatePayStatus(PayStatus status) async {
    state = const AsyncLoading();
    final manager = ref.read(orderManagerProvider.notifier);
    final success = await manager.updatePayStatus(arg, status);
    if (success) {
      await reload();
    } else {
      state = AsyncError('更新支付状态失败', StackTrace.current);
    }
  }

  Future<void> sync() async {
    state = const AsyncLoading();
    await ref.read(orderManagerProvider.notifier).syncOrderByNum(arg);
    await reload();
  }

  Future<void> delete() async {
    state = const AsyncLoading();
    final manager = ref.read(orderManagerProvider.notifier);
    final success = await manager.deleteOrder(arg);
    if (success) {
      state = const AsyncData(null);
    } else {
      state = AsyncError('删除订单失败', StackTrace.current);
    }
  }

  String getOrderStatusDisplayName() {
    if (state.value == null) return '';
    return OrderStatus.fromValue(state.value!.status).displayName;
  }

  String getPayStatusDisplayName() {
    if (state.value == null) return '';
    return PayStatus.fromValue(state.value!.payStatus).displayName;
  }
}

final orderDetailProvider =
    AsyncNotifierProviderFamily<OrderDetailNotifier, OrderEntry?, String>(
        OrderDetailNotifier.new);

// ===============================
// CreateOrder ViewModel (向后兼容适配层)
// ===============================
class CreateOrderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(OrderEntry order) async {
    state = const AsyncLoading();
    final success =
        await ref.read(orderManagerProvider.notifier).createOrder(order);
    if (success) {
      state = const AsyncData(null);
    } else {
      state = AsyncError('创建订单失败', StackTrace.current);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final createOrderProvider =
    AsyncNotifierProvider<CreateOrderNotifier, void>(CreateOrderNotifier.new);

// ===============================
// 按状态/支付方式 查询 Providers (向后兼容)
// ===============================
final ordersByOrderStatusProvider =
    FutureProvider.family<List<OrderEntry>, OrderStatus>(
  (ref, status) async {
    final manager = ref.watch(orderManagerProvider.notifier);
    return manager.getOrdersByStatus(status);
  },
);

final ordersByPayStatusProvider =
    FutureProvider.family<List<OrderEntry>, PayStatus>(
  (ref, status) async {
    final manager = ref.watch(orderManagerProvider.notifier);
    return manager.getOrdersByPayStatus(status);
  },
);

final ordersByPayMethodProvider = FutureProvider.family<List<OrderEntry>, int?>(
  (ref, method) async {
    final manager = ref.watch(orderManagerProvider.notifier);
    return manager.getOrdersByPaymentMethod(method);
  },
);

// 辅助提供者 - 获取状态显示名称
final orderStatusDisplayNameProvider = Provider.family<String, int>(
  (ref, statusValue) => OrderStatus.fromValue(statusValue).displayName,
);

final payStatusDisplayNameProvider = Provider.family<String, int>(
  (ref, statusValue) => PayStatus.fromValue(statusValue).displayName,
);
