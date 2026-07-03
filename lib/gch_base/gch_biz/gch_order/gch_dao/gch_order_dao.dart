import 'package:drift/drift.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';

part 'gch_order_dao.g.dart';

/// 订单数据访问对象
/// 注意：暂时注释掉部分实现，需要在 build_runner 生成代码后才能使用
@DriftAccessor(tables: [OrderEntries])
class OrderDAO extends DatabaseAccessor<GchDatabase> with _$OrderDAOMixin {
  OrderDAO(super.db);

  /// 获取所有订单的流
  Stream<List<OrderEntry>> watchOrders() {
    final query = select(orderEntries);
    query.orderBy([(t) => OrderingTerm.desc(t.createAt)]);
    return query.watch();
  }

  /// 按用户ID获取订单的流
  Stream<List<OrderEntry>> watchOrdersByUserId(String userId) {
    final query = select(orderEntries);
    query.where((t) => orderEntries.userId.equals(userId));
    query.orderBy([(t) => OrderingTerm.desc(orderEntries.createAt)]);
    return query.watch();
  }

  /// 按订单状态获取订单的流
  Stream<List<OrderEntry>> watchOrdersByOrderStatus(OrderStatus orderStatus) {
    final query = select(orderEntries);
    query.where((t) => orderEntries.status.equals(orderStatus.value));
    query.orderBy([(t) => OrderingTerm.desc(orderEntries.createAt)]);
    return query.watch();
  }

  /// 按支付状态获取订单的流
  Stream<List<OrderEntry>> watchOrdersByPayStatus(PayStatus payStatus) {
    final query = select(orderEntries);
    query.where((t) => orderEntries.payStatus.equals(payStatus.value));
    query.orderBy([(t) => OrderingTerm.desc(orderEntries.createAt)]);
    return query.watch();
  }

  /// 按订单类型获取订单的流
  Stream<List<OrderEntry>> watchOrdersByType(OrderType orderType) {
    final query = select(orderEntries);
    query.where((t) => orderEntries.orderType.equals(orderType.value));
    query.orderBy([(t) => OrderingTerm.desc(orderEntries.createAt)]);
    return query.watch();
  }

  /// 按支付平台获取订单的流
  Stream<List<OrderEntry>> watchOrdersByPlatform(PaymentPlatform platform) {
    final query = select(orderEntries);
    query.where((t) => orderEntries.platform.equals(platform.value));
    query.orderBy([(t) => OrderingTerm.desc(orderEntries.createAt)]);
    return query.watch();
  }

  /// 获取应用商店订单的流
  Stream<List<OrderEntry>> watchStoreOrders() {
    final query = select(orderEntries);
    query.where((t) => orderEntries.platform.equals('app_store'));
    query.orderBy([(t) => OrderingTerm.desc(orderEntries.createAt)]);
    return query.watch();
  }

  /// 获取退款订单的流
  Stream<List<OrderEntry>> watchRefundOrders() {
    final query = select(orderEntries);
    query.where((t) => orderEntries.refundTotal.isBiggerThanValue(0));
    query.orderBy([(t) => OrderingTerm.desc(orderEntries.refundAt)]);
    return query.watch();
  }

  /// 按订单号获取特定订单
  Future<OrderEntry?> getOrderByNum(String orderNum) async {
    final query = select(orderEntries);
    query.where((t) => orderEntries.orderNum.equals(orderNum));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return row;
  }

  /// 按第三方交易号获取订单
  Future<OrderEntry?> getOrderByTransactionId(String transactionId) async {
    final query = select(orderEntries);
    query.where((t) => orderEntries.transactionId.equals(transactionId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return row;
  }

  /// 按应用商店交易ID获取订单
  Future<OrderEntry?> getOrderByStoreTransactionId(String storeTransactionId) async {
    final query = select(orderEntries);
    query.where((t) => orderEntries.storeTransactionId.equals(storeTransactionId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return row;
  }

  /// 获取用户的最新订单
  Future<OrderEntry?> getLatestOrderByUserId(String userId) async {
    final query = select(orderEntries);
    query.where((t) => orderEntries.userId.equals(userId));
    query.orderBy([(t) => OrderingTerm.desc(orderEntries.createAt)]);
    query.limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return row;
  }

  /// 添加新订单
  Future<void> insertOrder(OrderEntry order) async {
    final companion = _orderToCompanion(order, includeDefaults: true);
    await into(orderEntries).insert(companion);
  }

  /// 更新现有订单
  Future<void> updateOrder(OrderEntry order) async {
    final companion = _orderToCompanion(order, includeDefaults: false);
    await (update(orderEntries)..where((t) => orderEntries.orderNum.equals(order.orderNum)))
        .write(companion);
  }

  /// 添加或更新订单
  Future<void> upsertOrder(OrderEntry order) async {
    final companion = _orderToCompanion(order, includeDefaults: true);
    await into(orderEntries).insertOnConflictUpdate(companion);
  }

  /// 批量添加或更新订单
  Future<void> upsertOrders(List<OrderEntry> orders) async {
    if (orders.isEmpty) return;
    await batch((batch) {
      for (final order in orders) {
        final companion = _orderToCompanion(order, includeDefaults: true);
        batch.insert(orderEntries, companion, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// 将OrderEntry转换为OrderEntriesCompanion
  ///
  /// [includeDefaults] 是否包含默认值字段（insert时为true，update时为false）
  OrderEntriesCompanion _orderToCompanion(OrderEntry order, {required bool includeDefaults}) {
    return OrderEntriesCompanion(
      orderNum: Value(order.orderNum),
      srcOrderNum: Value(order.srcOrderNum),
      userId: Value(order.userId),
      productId: Value(order.productId),
      productName: Value(order.productName),
      originalTotal: Value(order.originalTotal),
      discountTotal: Value(order.discountTotal),
      total: Value(order.total),
      currency: Value(order.currency),
      voucherId: Value(order.voucherId),
      payProvider: Value(order.payProvider),
      orderType: Value(order.orderType),
      clientIp: Value(order.clientIp),
      clientType: Value(order.clientType),
      payStatus: Value(order.payStatus),
      status: Value(order.status),
      transactionId: Value(order.transactionId),
      agentChannel: Value(order.agentChannel),
      agentId: Value(order.agentId),
      platform: Value(order.platform),
      refundTotal: Value(order.refundTotal),
      refundTransactionId: Value(order.refundTransactionId),
      refundOrderNum: Value(order.refundOrderNum),
      refundReason: Value(order.refundReason),
      refundAt: Value(order.refundAt),
      refundType: Value(order.refundType),
      refundMethod: Value(order.refundMethod),
      refundApprover: Value(order.refundApprover),
      refundApprovedAt: Value(order.refundApprovedAt),
      storeReceiptData: Value(order.storeReceiptData),
      storeProductId: Value(order.storeProductId),
      storeTransactionId: Value(order.storeTransactionId),
      subscriptionType: Value(order.subscriptionType),
      subscriptionStatus: Value(order.subscriptionStatus),
      extra1: Value(order.extra1),
      extra2: Value(order.extra2),
      extra3: Value(order.extra3),
      extra4: Value(order.extra4),
      createAt: Value(order.createAt),
      updateAt: Value(order.updateAt),
      expireAt: Value(order.expireAt),
      payAt: Value(order.payAt),
      notifyUrl: Value(order.notifyUrl),
      remark: Value(order.remark),
    );
  }

  /// 更新订单状态
  Future<void> updateOrderStatus(String orderNum, OrderStatus orderStatus) async {
    final now = DateTime.now();
    await (update(orderEntries)..where((t) => orderEntries.orderNum.equals(orderNum))).write(
      OrderEntriesCompanion(
        status: Value(orderStatus.value),
        updateAt: Value(now),
      ),
    );
  }

  /// 更新支付状态
  Future<void> updatePayStatus(String orderNum, PayStatus payStatus, {DateTime? payAt}) async {
    final now = DateTime.now();
    await (update(orderEntries)..where((t) => orderEntries.orderNum.equals(orderNum))).write(
      OrderEntriesCompanion(
        payStatus: Value(payStatus.value),
        payAt: Value(payAt ?? (payStatus == PayStatus.paid ? now : null)),
        updateAt: Value(now),
      ),
    );
  }

  /// 更新第三方交易ID
  Future<void> updateTransactionId(String orderNum, String transactionId) async {
    await (update(orderEntries)..where((t) => orderEntries.orderNum.equals(orderNum))).write(
      OrderEntriesCompanion(
        transactionId: Value(transactionId),
        updateAt: Value(DateTime.now()),
      ),
    );
  }

  /// 处理退款
  Future<void> processRefund({
    required String orderNum,
    required double refundAmount,
    String? refundTransactionId,
    String? refundOrderNum,
    String? refundReason,
    RefundType? refundType,
    RefundMethod? refundMethod,
    String? refundApprover,
  }) async {
    final now = DateTime.now();
    await (update(orderEntries)..where((t) => orderEntries.orderNum.equals(orderNum))).write(
      OrderEntriesCompanion(
        refundTotal: Value(refundAmount),
        refundTransactionId: Value(refundTransactionId),
        refundOrderNum: Value(refundOrderNum), 
        refundReason: Value(refundReason),
        refundType: Value(refundType?.value),
        refundMethod: Value(refundMethod?.value),
        refundApprover: Value(refundApprover),
        refundAt: Value(now),
        payStatus: Value(refundAmount > 0 ? PayStatus.refunded.value : PayStatus.partialRefunded.value),
        updateAt: Value(now),
      ),
    );
  }

  /// 审批退款
  Future<void> approveRefund(String orderNum, String approverId) async {
    final now = DateTime.now();
    await (update(orderEntries)..where((t) => orderEntries.orderNum.equals(orderNum))).write(
      OrderEntriesCompanion(
        refundApprover: Value(approverId),
        refundApprovedAt: Value(now),
        status: Value(OrderStatus.completed.value),
        updateAt: Value(now),
      ),
    );
  }

  /// 更新应用商店相关信息
  Future<void> updateStoreInfo({
    required String orderNum,
    String? storeReceiptData,
    String? storeProductId,
    String? storeTransactionId,
    SubscriptionType? subscriptionType,
    SubscriptionStatus? subscriptionStatus,
  }) async {
    await (update(orderEntries)..where((t) => orderEntries.orderNum.equals(orderNum))).write(
      OrderEntriesCompanion(
        storeReceiptData: Value(storeReceiptData),
        storeProductId: Value(storeProductId),
        storeTransactionId: Value(storeTransactionId),
        subscriptionType: Value(subscriptionType?.value),
        subscriptionStatus: Value(subscriptionStatus?.value),
        updateAt: Value(DateTime.now()),
      ),
    );
  }

  /// 删除订单
  Future<void> deleteOrder(String orderNum) async {
    await (delete(orderEntries)..where((t) => orderEntries.orderNum.equals(orderNum))).go();
  }

  /// 删除用户的所有订单
  Future<void> deleteOrdersByUserId(String userId) async {
    await (delete(orderEntries)..where((t) => orderEntries.userId.equals(userId))).go();
  }

  /// 获取订单统计信息
  Future<Map<String, dynamic>> getOrderStats({String? userId}) async {
    var query = selectOnly(orderEntries);
    
    if (userId != null) {
      query.where(orderEntries.userId.equals(userId));
    }

    query.addColumns([
      orderEntries.total.sum(),
      orderEntries.refundTotal.sum(),
      orderEntries.orderNum.count(),
    ]);

    final result = await query.getSingle();
    final totalAmount = result.read(orderEntries.total.sum()) ?? 0.0;
    final refundAmount = result.read(orderEntries.refundTotal.sum()) ?? 0.0;
    final orderCount = result.read(orderEntries.orderNum.count()) ?? 0;

    return {
      'totalAmount': totalAmount,
      'refundAmount': refundAmount,
      'netRevenue': totalAmount - refundAmount,
      'orderCount': orderCount,
    };
  }

  /// 获取按状态分组的订单数量
  Future<Map<OrderStatus, int>> getOrderCountByStatus({String? userId}) async {
    var query = selectOnly(orderEntries);
    
    if (userId != null) {
      query.where(orderEntries.userId.equals(userId));
    }

    query.addColumns([orderEntries.status, orderEntries.orderNum.count()]);
    query.groupBy([orderEntries.status]);

    final results = await query.get();
    final Map<OrderStatus, int> statusCounts = {};

    for (final result in results) {
      final statusValue = result.read(orderEntries.status);
      final count = result.read(orderEntries.orderNum.count()) ?? 0;
      if (statusValue != null) {
        statusCounts[OrderStatus.fromValue(statusValue)] = count;
      }
    }

    return statusCounts;
  }

  /// 获取按支付状态分组的订单数量
  Future<Map<PayStatus, int>> getOrderCountByPayStatus({String? userId}) async {
    var query = selectOnly(orderEntries);
    
    if (userId != null) {
      query.where(orderEntries.userId.equals(userId));
    }

    query.addColumns([orderEntries.payStatus, orderEntries.orderNum.count()]);
    query.groupBy([orderEntries.payStatus]);

    final results = await query.get();
    final Map<PayStatus, int> payStatusCounts = {};

    for (final result in results) {
      final statusValue = result.read(orderEntries.payStatus);
      final count = result.read(orderEntries.orderNum.count()) ?? 0;
      if (statusValue != null) {
        payStatusCounts[PayStatus.fromValue(statusValue)] = count;
      }
    }

    return payStatusCounts;
  }

  /// 获取过期未支付的订单
  Future<List<OrderEntry>> getExpiredUnpaidOrders() async {
    final now = DateTime.now();
    final query = select(orderEntries);
    query.where((t) => 
      orderEntries.payStatus.equals(PayStatus.unpaid.value) & 
      orderEntries.expireAt.isSmallerThanValue(now)
    );
    final rows = await query.get();
    return rows;
  }

  /// 标记过期订单
  Future<void> markExpiredOrders() async {
    final now = DateTime.now();
    await (update(orderEntries)
      ..where((t) => 
        orderEntries.payStatus.equals(PayStatus.unpaid.value) & 
        orderEntries.expireAt.isSmallerThanValue(now)
      )
    ).write(
      OrderEntriesCompanion(
        status: Value(OrderStatus.expired.value),
        updateAt: Value(now),
      ),
    );
  }

  /// 分页获取订单列表
  Future<List<OrderEntry>> getOrdersPaginated({
    String? userId,
    OrderStatus? orderStatus,
    PayStatus? payStatus,
    OrderType? orderType,
    PaymentPlatform? platform,
    int offset = 0,
    int limit = 20,
  }) async {
    var query = select(orderEntries);

    // 应用过滤条件
    if (userId != null) {
      query.where((t) => orderEntries.userId.equals(userId));
    }
    if (orderStatus != null) {
      query.where((t) => orderEntries.status.equals(orderStatus.value));
    }
    if (payStatus != null) {
      query.where((t) => orderEntries.payStatus.equals(payStatus.value));
    }
    if (orderType != null) {
      query.where((t) => orderEntries.orderType.equals(orderType.value));
    }
    if (platform != null) {
      query.where((t) => orderEntries.platform.equals(platform.value));
    }

    query.orderBy([(t) => OrderingTerm.desc(orderEntries.createAt)]);
    query.limit(limit, offset: offset);

    final rows = await query.get();
    return rows;
  }

  /// 搜索订单
  Future<List<OrderEntry>> searchOrders({
    required String searchTerm,
    String? userId,
    int limit = 50,
  }) async {
    var query = select(orderEntries);
    
    if (userId != null) {
      query.where((t) => orderEntries.userId.equals(userId));
    }

    // 支持多字段搜索
    query.where((t) => 
      orderEntries.orderNum.like('%$searchTerm%') |
      orderEntries.productName.like('%$searchTerm%') |
      orderEntries.transactionId.like('%$searchTerm%') |
      orderEntries.storeTransactionId.like('%$searchTerm%') |
      orderEntries.remark.like('%$searchTerm%')
    );

    query.orderBy([(t) => OrderingTerm.desc(orderEntries.createAt)]);
    query.limit(limit);

    final rows = await query.get();
    return rows;
  }
}

/// 远程订单数据访问对象