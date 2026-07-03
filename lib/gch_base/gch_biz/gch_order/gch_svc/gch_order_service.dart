import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_client/gch_api_client.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_extensions.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_repo/gch_order_repository.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_svc/gch_order_converter.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';

/// 分页获取订单的结果
class FetchOrdersResult {
  const FetchOrdersResult({
    required this.orders,
    this.errorMessage,
  });

  final List<OrderData> orders;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

/// 订单服务类，处理订单相关业务逻辑
class OrderService {
  final OrderRepository _repository;
  final DataApiClient? _apiClient;

  // 🔄 订单过期清理定时器
  Timer? _expirationTimer;
  static const _cleanupInterval = Duration(minutes: 5); // 每5分钟清理一次

  OrderService(this._repository, [this._apiClient]);

  /// 获取所有订单的流
  Stream<List<OrderEntry>> watchOrders() {
    return _repository.watchOrders();
  }

  /// 按订单状态获取订单的流
  Stream<List<OrderEntry>> watchOrdersByOrderStatus(OrderStatus status) {
    return _repository.watchOrdersByOrderStatus(status);
  }

  /// 按支付状态获取订单的流
  Stream<List<OrderEntry>> watchOrdersByPayStatus(PayStatus status) {
    return _repository.watchOrdersByPayStatus(status);
  }

  /// 按ID获取特定订单
  Future<OrderEntry?> getOrderById(String ordernum) async {
    final result = await _repository.getOrderByNum(ordernum);
    return result.fold(
      (failure) => null,
      (order) => order,
    );
  }

  /// 创建新订单
  Future<void> createOrder(OrderEntry order) async {
    // 设置创建时间和更新时间
    final now = DateTime.now();
    final newOrder = order.copyWith(
      createAt: now,
      updateAt: now,
    );

    final result = await _repository.createOrder(newOrder);
    result.fold(
      (failure) => debugPrint('Create order failed: $failure'),
      (_) => debugPrint('Order created successfully'),
    );
  }

  /// 新增或更新订单（存在则更新，不存在则创建）
  Future<void> upsertOrder(OrderEntry order) async {
    try {
      final existingResult = await _repository.getOrderByNum(order.orderNum);

      OrderFailure? failure;
      OrderEntry? existingOrder;
      existingResult.fold((l) => failure = l, (r) => existingOrder = r);

      if (existingOrder != null) {
        // 已存在：保留原创建时间，仅更新更新时间
        final updated = order.copyWith(
          createAt: existingOrder!.createAt,
          updateAt: DateTime.now(),
        );
        final updateResult = await _repository.updateOrder(updated);
        updateResult.fold(
          (f) => debugPrint('Upsert (update) failed: $f'),
          (_) => debugPrint('Order upserted (updated) successfully'),
        );
      } else if (failure is OrderNotFoundFailure) {
        // 不存在：按创建逻辑新增
        final now = DateTime.now();
        final created = order.copyWith(createAt: now, updateAt: now);
        final createResult = await _repository.createOrder(created);
        createResult.fold(
          (f) => debugPrint('Upsert (create) failed: $f'),
          (_) => debugPrint('Order upserted (created) successfully'),
        );
      } else if (failure != null) {
        // 其他错误：仅记录
        debugPrint('Check existing order failed: $failure');
      }
    } catch (e) {
      debugPrint('Upsert order exception: $e');
    }
  }

  /// 更新订单状态
  Future<void> updateOrderStatus(String ordernum, OrderStatus status) async {
    final result = await _repository.updateOrderStatus(ordernum, status);
    result.fold(
      (failure) => debugPrint('Update order status failed: $failure'),
      (_) => debugPrint('Order status updated successfully'),
    );
  }

  /// 更新支付状态
  Future<void> updatePayStatus(String ordernum, PayStatus status) async {
    final result = await _repository.updatePayStatus(ordernum, status);
    result.fold(
      (failure) => debugPrint('Update pay status failed: $failure'),
      (_) => debugPrint('Pay status updated successfully'),
    );
  }

  /// 从服务器同步订单
  Future<void> syncOrders() async {
    // 从服务器获取最新数据
    final result = await _repository.syncOrdersFromServer();
    result.fold(
      (failure) => debugPrint('Sync orders failed: $failure'),
      (_) => debugPrint('Orders synced successfully'),
    );
  }

  /// 从服务器同步指定订单
  Future<void> syncOrderById(String ordernum) async {
    final result = await _repository.syncOrderFromServer(ordernum);
    result.fold(
      (failure) => debugPrint('Sync order failed: $failure'),
      (order) => debugPrint('Order synced successfully: ${order.orderNum}'),
    );
  }

  /// 按应用商店交易ID从服务器同步订单
  Future<OrderEntry?> syncOrderByStoreTransactionId(String storeTransactionId) async {
    final result = await _repository.syncOrderByStoreTransactionId(storeTransactionId);
    return result.fold(
      (failure) {
        debugPrint('Sync order by storeTransactionId failed: $failure');
        return null;
      },
      (order) {
        debugPrint('Order synced by storeTransactionId successfully: ${order.orderNum}');
        return order;
      },
    );
  }

  /// 取消订单
  Future<OrderEntry?> cancelOrder(String orderid, String reason) async {
    final result = await _repository.CancelOrder(orderid, reason);
    return result.fold(
      (failure) {
        debugPrint('Cancel order failed: $failure');
        return null;
      },
      (order) {
        debugPrint('Order cancelled successfully: ${order.orderNum}');
        return order;
      },
    );
  }

  /// 删除订单
  Future<void> deleteOrder(String ordernum) async {
    final result = await _repository.deleteOrder(ordernum);
    result.fold(
      (failure) => debugPrint('Delete order failed: $failure'),
      (_) => debugPrint('Order deleted successfully'),
    );
  }


  /// 删除用户的所有订单
  Future<void> deleteOrdersByUserId(String userId) async {
    final result = await _repository.deleteOrdersByUserId(userId);
    result.fold(
      (failure) => debugPrint('Delete orders by user failed: $failure'),
      (_) => debugPrint('Orders deleted successfully for user: $userId'),
    );
  }

  /// 获取指定时间段内的订单
  Future<List<OrderEntry>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    // 获取所有订单，然后进行过滤
    final allOrders = await _repository.watchOrders().first;

    return allOrders.where((order) {
      return order.createAt.isAfter(startDate) && order.createAt.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// 按订单状态获取订单
  Future<List<OrderEntry>> getOrdersByOrderStatus(OrderStatus status) async {
    return await _repository.watchOrdersByOrderStatus(status).first;
  }

  /// 按支付状态获取订单
  Future<List<OrderEntry>> getOrdersByPayStatus(PayStatus status) async {
    return await _repository.watchOrdersByPayStatus(status).first;
  }

  /// 按支付方式获取订单
  Future<List<OrderEntry>> getOrdersByPaymentMethod(int? payprovider) async {
    final allOrders = await _repository.watchOrders().first;
    if (payprovider == null) {
      return allOrders.where((order) => order.payProvider == null).toList();
    }
    return allOrders.where((order) => order.payProvider == payprovider).toList();
  }

  String getOrderStatusDisplayName(int statusValue) {
    return _repository.getOrderStatusDisplayName(statusValue);
  }

  /// 获取支付状态显示名称
  String getPayStatusDisplayName(int statusValue) {
    return _repository.getPayStatusDisplayName(statusValue);
  }

  /// 获取用户未支付订单
  Future<OrderEntry?> getUnpaidOrder(String userId, String _productId) async {
    debugPrint('📋 [未支付订单检查] 开始查询...');
    debugPrint('📋 [未支付订单检查] 查询条件: userId=$userId, productId=$_productId');

    final orders = await _repository.watchOrdersByPayStatus(PayStatus.unpaid).first;
    final productId = int.tryParse(_productId);
    final normalizedUserId = userId.trim();

    debugPrint('📋 [未支付订单检查] PayStatus.unpaid=${PayStatus.unpaid.value}');
    debugPrint('📋 [未支付订单检查] 数据库中未支付订单总数: ${orders.length}');

    if (normalizedUserId.isEmpty) {
      debugPrint('⚠️ [未支付订单检查] userId为空，返回null');
      return null;
    }

    for (final order in orders) {
      debugPrint('-------------------------------------------');
      debugPrint('📋 [未支付订单检查] 遍历订单: ${order.orderNum}');
      debugPrint('   订单userId: ${order.userId}');
      debugPrint('   订单productId(数字): ${order.productId}');
      debugPrint('   订单storeProductId(字符串): ${order.storeProductId}');
      debugPrint('   订单payStatus: ${order.payStatus} (0=未支付, 1=已支付)');
      debugPrint('   订单createAt: ${order.createAt}');

      if (order.userId.trim() != normalizedUserId) {
        debugPrint('   ⏭️ 跳过: userId不匹配 (${order.userId} != $normalizedUserId)');
        continue;
      }

      final matchesByNumericId = productId != null && order.productId == productId;
      final matchesByStoreId = order.storeProductId != null && order.storeProductId == _productId;

      debugPrint('   🔍 数字ID匹配: $matchesByNumericId (订单productId=${order.productId} vs 查询productId=$productId)');
      debugPrint('   🔍 商店ID匹配: $matchesByStoreId (订单storeProductId=${order.storeProductId} vs 查询productId=$_productId)');

      if (matchesByNumericId || matchesByStoreId) {
        debugPrint('   ✅ 找到匹配的未支付订单: ${order.orderNum}');
        debugPrint('-------------------------------------------');
        return order;
      }
    }
    debugPrint('-------------------------------------------');
    debugPrint('✅ [未支付订单检查] 未找到匹配的未支付订单');
    return null;
  }

  // ============================================================================
  // 🔄 订单自动过期清理机制
  // ============================================================================

  /// 启动订单过期清理定时器
  void startExpirationMonitor() {
    // 避免重复启动
    if (_expirationTimer != null && _expirationTimer!.isActive) {
      debugPrint('订单过期监控已运行，跳过启动');
      return;
    }

    debugPrint('🔄 启动订单过期清理定时器，间隔: $_cleanupInterval');

    // 立即执行一次清理
    _cleanupExpiredOrders();

    // 启动定期清理
    _expirationTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupExpiredOrders();
    });
  }

  /// 停止订单过期清理定时器
  void stopExpirationMonitor() {
    _expirationTimer?.cancel();
    _expirationTimer = null;
    debugPrint('⏹ 订单过期清理定时器已停止');
  }

  /// 清理过期订单（10分钟未支付）
  Future<void> _cleanupExpiredOrders() async {
    try {
      final result = await _repository.markExpiredOrders();
      result.fold(
        (failure) => debugPrint('❌ 清理过期订单失败: $failure'),
        (_) => debugPrint('✅ 过期订单清理完成'),
      );
    } catch (e) {
      debugPrint('❌ 清理过期订单异常: $e');
    }
  }

  /// 释放资源
  void dispose() {
    stopExpirationMonitor();
  }

  // ============================================================================
  // 📄 分页获取订单（从服务器）
  // ============================================================================

  /// 分页获取订单列表
  ///
  /// [page] 页码，从1开始
  /// [limit] 每页数量
  /// [payStatus] 支付状态过滤，默认1（已支付）
  /// [status] 订单状态过滤，默认2（已完成）
  /// [sortBy] 排序字段，默认按创建时间
  /// [sortDesc] 是否降序，默认true
  Future<FetchOrdersResult> fetchOrdersFromServer({
    required int page,
    int limit = 20,
    int payStatus = 1,
    int status = 2,
    String sortBy = 'createat',
    bool sortDesc = true,
  }) async {
    if (_apiClient == null) {
      return const FetchOrdersResult(
        orders: [],
        errorMessage: 'API客户端未初始化',
      );
    }

    try {
      // 计算 offset：从第1页开始，offset = (page - 1) * limit
      final offset = (page - 1) * limit;

      // 调用订单列表接口（POST 方式）
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/orders/list',
        data: {
          'paystatus': payStatus,
          'status': status,
          'limit': limit,
          'offset': offset,
          'sort_by': sortBy,
          'sort_desc': sortDesc,
        },
      );

      final data = response.data;
      if (data == null) {
        return const FetchOrdersResult(
          orders: [],
          errorMessage: '服务端返回空数据',
        );
      }

      // 解析嵌套的 data 对象：{ code, data: { count, items, limit, offset }, msg, success }
      final dataObj = data['data'];
      if (dataObj == null || dataObj is! Map<String, dynamic>) {
        return const FetchOrdersResult(
          orders: [],
          errorMessage: '返回数据格式不正确：缺少 data 字段',
        );
      }

      final items = dataObj['items'];
      if (items == null || items is! List) {
        return const FetchOrdersResult(
          orders: [],
          errorMessage: '返回数据格式不正确：items 不是数组',
        );
      }

      final orderEntries = OrderConverter.fromServerJsonList(items);
      // 转换为领域模型 OrderData，支持多种存储后端
      final orders = orderEntries.toDataList();
      return FetchOrdersResult(orders: orders);
    } on DioException catch (e) {
      return FetchOrdersResult(
        orders: const [],
        errorMessage: e.message ?? '网络请求失败',
      );
    } catch (e) {
      return FetchOrdersResult(
        orders: const [],
        errorMessage: e.toString(),
      );
    }
  }
}
