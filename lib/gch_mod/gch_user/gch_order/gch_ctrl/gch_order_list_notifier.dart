import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_svc/gch_order_service.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_vm/gch_order_viewmodel.dart';
import 'package:guichao/gch_base/gch_kit/gch_uuid.dart';

/// 订单列表的只读分页状态
class OrderListState {
  final List<OrderData> items;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasMore;
  final String? errorMessage;
  final int offset;
  final int limit;

  const OrderListState({
    this.items = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasMore = true,
    this.errorMessage,
    this.offset = 0,
    this.limit = 20,
  });

  OrderListState copyWith({
    List<OrderData>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasMore,
    String? errorMessage,
    int? offset,
    int? limit,
  }) {
    return OrderListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
    );
  }
}

/// 特性层订单列表分页 Notifier（只负责拉取和分页，不修改数据）
class OrderListNotifier extends StateNotifier<OrderListState> {
  final OrderService _orderService;

  OrderListNotifier(this._orderService) : super(const OrderListState());

  bool _inFlight = false;
  final Set<int> _loadedPages = <int>{};

  Future<void> loadInitial() => _runLocked(() => _loadFirstPage(isRefresh: false));

  Future<void> refresh() => _runLocked(() => _loadFirstPage(isRefresh: true));

  Future<void> loadMore() async {
    if (!state.hasMore) return;
    await _runLocked(() async {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true, errorMessage: null);

      try {
        final nextPage = _nextPage(state.offset, state.limit);
        if (_loadedPages.contains(nextPage)) {
          state = state.copyWith(isLoading: false, hasMore: false);
          return;
        }

        final result = await _orderService.fetchOrdersFromServer(page: nextPage, limit: state.limit);
        final incoming = result.orders;
        if (incoming.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            hasMore: !result.hasError ? false : state.hasMore,
            errorMessage: result.errorMessage,
          );
          return;
        }

        final merged = _mergeOrders(state.items, incoming);
        if (!result.hasError) {
          _loadedPages.add(nextPage);
        }
        final addedCount = merged.length - state.items.length;
        state = state.copyWith(
          items: merged,
          isLoading: false,
          hasMore: addedCount >= state.limit,
          offset: merged.length,
          errorMessage: result.errorMessage,
        );
      } catch (e) {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
      }
    });
  }

  Future<void> _loadFirstPage({required bool isRefresh}) async {
    final previous = state;
    state = state.copyWith(
      isLoading: isRefresh ? state.isLoading : true,
      isRefreshing: isRefresh,
      errorMessage: null,
      offset: 0,
      hasMore: true,
    );

    try {
      _loadedPages.clear();
      final result = await _orderService.fetchOrdersFromServer(page: 1, limit: state.limit);
      if (!result.hasError) {
        _loadedPages.add(1);
      }
      state = state.copyWith(
        items: result.orders,
        isLoading: false,
        isRefreshing: false,
        hasMore: result.orders.length >= state.limit,
        offset: result.orders.length,
        errorMessage: result.errorMessage,
      );
    } catch (e) {
      state = state.copyWith(
        items: isRefresh ? previous.items : const [],
        isLoading: false,
        isRefreshing: false,
        hasMore: isRefresh ? previous.hasMore : false,
        offset: isRefresh ? previous.offset : 0,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _runLocked(Future<void> Function() action) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      await action();
    } finally {
      _inFlight = false;
    }
  }

  /// 重置状态（用户切换时调用）
  void reset() {
    _loadedPages.clear();
    _inFlight = false;
    state = const OrderListState();
    debugPrint('📋 OrderListNotifier: 状态已重置');
  }

  int _nextPage(int currentOffset, int limit) => (currentOffset ~/ limit) + 1;

  List<OrderData> _mergeOrders(List<OrderData> existing, List<OrderData> incoming) {
    if (existing.isEmpty) {
      return List<OrderData>.from(incoming);
    }

    final orderNums = <String>{for (final order in existing) order.orderNum};
    final merged = List<OrderData>.from(existing);

    for (final order in incoming) {
      if (orderNums.add(order.orderNum)) {
        merged.add(order);
      }
    }

    merged.sort((a, b) => b.createAt.compareTo(a.createAt));
    return merged;
  }
}

/// Provider：供 UI 使用，解耦特性层与核心层
///
/// 自动监听用户变化，用户切换时重置状态并重新加载。
final orderListNotifierProvider = StateNotifierProvider<OrderListNotifier, OrderListState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  final notifier = OrderListNotifier(orderService);

  // 监听用户变化
  String? prevUserId;
  ref.listen(currentUserProvider, (_, next) {
    final userId = next.valueOrNull?.userId;
    if (prevUserId != null && prevUserId != userId) {
      debugPrint('🔄 订单列表: 用户切换 $prevUserId -> $userId');
      notifier.reset();
      if (userId != null) notifier.loadInitial();
    }
    prevUserId = userId;
  });

  return notifier;
});

/// UI 层只需要读取该 Provider，业务逻辑都在 Notifier 中处理完毕。
final orderListUiProvider = Provider<OrderListUiState>((ref) {
  final state = ref.watch(orderListNotifierProvider);
  return const OrderListUiMapper().mapToUiState(state);
});

/// 页面动作封装到 notifier 模块，避免 UI 直接依赖状态实现细节。
class OrderListActionHandler {
  OrderListActionHandler(this._ref);

  final WidgetRef _ref;

  Future<void> load() {
    return _ref.read(orderListNotifierProvider.notifier).loadInitial();
  }

  Future<void> refresh() {
    return _ref.read(orderListNotifierProvider.notifier).refresh();
  }

  void handleScroll(ScrollController controller) {
    final state = _ref.read(orderListNotifierProvider);
    if (!state.hasMore || state.isLoading) return;
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 200) {
      _ref.read(orderListNotifierProvider.notifier).loadMore();
    }
  }
}

/// UI 使用的视图状态，包含格式化好展示所需内容。
class OrderListUiState {
  const OrderListUiState({
    required this.items,
    required this.hasMore,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<OrderListItemUi> items;
  final bool hasMore;
  final bool isLoading;
  final String? errorMessage;
}

class OrderListItemUi {
  const OrderListItemUi({
    required this.orderNo,
    required this.title,
    required this.secondary,
    required this.amount,
    required this.currency,
    required this.orderTime,
    required this.payMethod,
    required this.status,
    required this.statusLabel,
  });

  final String orderNo;
  final String title;
  final String secondary;
  final double amount;
  final String currency;
  final String orderTime;
  final String payMethod;
  final OrderListItemStatus status;
  final String statusLabel;
}

enum OrderListItemStatus { completed, pending, canceled }

/// 将核心层订单数据转换为 UI 可直接消费的内容。
class OrderListUiMapper {
  const OrderListUiMapper();
  OrderListUiState mapToUiState(OrderListState state) {
    final items = state.items.map(_mapOrder).toList(growable: false);
    return OrderListUiState(
      items: items,
      hasMore: state.hasMore,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
    );
  }

  OrderListItemUi _mapOrder(OrderData data) {
    final status = _mapOrderStatus(data);
    final orderTime = _fmtDateTime(data.createAt);

    return OrderListItemUi(
      orderNo: _displayOrderNumber(data.orderNum),
      title: data.productName ?? '${GchText.userOrderProduct} ${data.productId}',
      secondary: data.expireAt != null
          ? '${GchText.userOrderExpired}${_fmtDateTime(data.expireAt!)}'
          : _orderTypeLabel(data.orderType),
      amount: data.total,
      currency: data.currency,
      orderTime: orderTime,
      payMethod: _paymentMethodLabel(data.platform),
      status: status,
      statusLabel: _statusLabel(status),
    );
  }

  OrderListItemStatus _mapOrderStatus(OrderData data) {
    final parsed = _toOrderStatus(data.status);
    final status = parsed ?? OrderStatus.pending;
    if (status == OrderStatus.completed) {
      return OrderListItemStatus.completed;
    }
    if (status == OrderStatus.cancelled ||
        status == OrderStatus.failed ||
        status == OrderStatus.expired) {
      return OrderListItemStatus.canceled;
    }
    return OrderListItemStatus.pending;
  }

  OrderStatus? _toOrderStatus(int status) {
    try {
      return OrderStatus.fromValue(status);
    } catch (_) {
      return null;
    }
  }

  String _orderTypeLabel(String typeValue) {
    try {
      return OrderType.fromValue(typeValue).displayName;
    } catch (_) {
      return typeValue.isEmpty ? '未知类型' : typeValue;
    }
  }

  String _paymentMethodLabel(String? platformValue) {
    if (platformValue == null || platformValue.isEmpty) {
      return GchText.generalUnknown;
    }
    final normalized = platformValue.toLowerCase();
    if (_matchesAny(normalized, const ['app_store', 'ios', 'apple'])) {
      return 'App Store';
    }
    try {
      return PaymentPlatform.fromValue(platformValue).displayName;
    } catch (_) {
      return platformValue;
    }
  }

  String _statusLabel(OrderListItemStatus status) {
    switch (status) {
      case OrderListItemStatus.completed:
        return GchText.userOrderCompleted;
      case OrderListItemStatus.pending:
        return GchText.userOrderPending;
      case OrderListItemStatus.canceled:
        return GchText.userOrderCanceled;
    }
  }

  bool _matchesAny(String value, List<String> keywords) {
    for (final keyword in keywords) {
      if (value.contains(keyword)) return true;
    }
    return false;
  }

  String _displayOrderNumber(String orderNum) {
    try {
      if (orderNum.contains('-') && orderNum.length >= 36) {
        return uuidV7ToDateTimeString(orderNum, useLocalTime: true);
      }
      return orderNum;
    } catch (_) {
      return orderNum;
    }
  }

  String _fmtDateTime(DateTime dt) {
    final local = dt.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd $hh:$mi';
  }
}
