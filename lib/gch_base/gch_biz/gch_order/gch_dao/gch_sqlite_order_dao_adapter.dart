import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_dao/gch_order_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_dao/gch_order_dao_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';

/// SQLite OrderDao 适配器 - 零开销包装
///
/// 【设计理由】
/// - Drift 的 OrderDAO 是自动生成的，无法直接修改让其实现接口
/// - 使用适配器模式包装，提供统一的接口实现
/// - 所有方法直接转发到底层的 OrderDAO
///
/// 【性能】
/// - 零开销：方法调用直接转发，无额外逻辑
/// - 编译器可内联优化
final class SQLiteOrderDaoAdapter implements OrderDaoInterface {
  SQLiteOrderDaoAdapter(this._dao);

  final OrderDAO _dao;

  // ==================== 直接转发所有方法 ====================

  @override
  Stream<List<OrderEntry>> watchOrders() => _dao.watchOrders();

  @override
  Stream<List<OrderEntry>> watchOrdersByUserId(String userId) =>
      _dao.watchOrdersByUserId(userId);

  @override
  Stream<List<OrderEntry>> watchOrdersByOrderStatus(OrderStatus orderStatus) =>
      _dao.watchOrdersByOrderStatus(orderStatus);

  @override
  Stream<List<OrderEntry>> watchOrdersByPayStatus(PayStatus payStatus) =>
      _dao.watchOrdersByPayStatus(payStatus);

  @override
  Stream<List<OrderEntry>> watchOrdersByType(OrderType orderType) =>
      _dao.watchOrdersByType(orderType);

  @override
  Stream<List<OrderEntry>> watchOrdersByPlatform(PaymentPlatform platform) =>
      _dao.watchOrdersByPlatform(platform);

  @override
  Stream<List<OrderEntry>> watchStoreOrders() => _dao.watchStoreOrders();

  @override
  Stream<List<OrderEntry>> watchRefundOrders() => _dao.watchRefundOrders();

  @override
  Future<OrderEntry?> getOrderByNum(String orderNum) =>
      _dao.getOrderByNum(orderNum);

  @override
  Future<OrderEntry?> getOrderByTransactionId(String transactionId) =>
      _dao.getOrderByTransactionId(transactionId);

  @override
  Future<OrderEntry?> getOrderByStoreTransactionId(String storeTransactionId) =>
      _dao.getOrderByStoreTransactionId(storeTransactionId);

  @override
  Future<OrderEntry?> getLatestOrderByUserId(String userId) =>
      _dao.getLatestOrderByUserId(userId);

  @override
  Future<List<OrderEntry>> getOrdersPaginated({
    String? userId,
    OrderStatus? orderStatus,
    PayStatus? payStatus,
    OrderType? orderType,
    PaymentPlatform? platform,
    int offset = 0,
    int limit = 20,
  }) =>
      _dao.getOrdersPaginated(
        userId: userId,
        orderStatus: orderStatus,
        payStatus: payStatus,
        orderType: orderType,
        platform: platform,
        offset: offset,
        limit: limit,
      );

  @override
  Future<List<OrderEntry>> searchOrders({
    required String searchTerm,
    String? userId,
    int limit = 50,
  }) =>
      _dao.searchOrders(
        searchTerm: searchTerm,
        userId: userId,
        limit: limit,
      );

  @override
  Future<List<OrderEntry>> getExpiredUnpaidOrders() =>
      _dao.getExpiredUnpaidOrders();

  @override
  Future<void> insertOrder(OrderEntry order) => _dao.insertOrder(order);

  @override
  Future<void> updateOrder(OrderEntry order) => _dao.updateOrder(order);

  @override
  Future<void> upsertOrder(OrderEntry order) => _dao.upsertOrder(order);

  @override
  Future<void> upsertOrders(List<OrderEntry> orders) =>
      _dao.upsertOrders(orders);

  @override
  Future<void> updateOrderStatus(String orderNum, OrderStatus orderStatus) =>
      _dao.updateOrderStatus(orderNum, orderStatus);

  @override
  Future<void> updatePayStatus(String orderNum, PayStatus payStatus, {DateTime? payAt}) =>
      _dao.updatePayStatus(orderNum, payStatus, payAt: payAt);

  @override
  Future<void> updateTransactionId(String orderNum, String transactionId) =>
      _dao.updateTransactionId(orderNum, transactionId);

  @override
  Future<void> markExpiredOrders() => _dao.markExpiredOrders();

  @override
  Future<void> processRefund({
    required String orderNum,
    required double refundAmount,
    String? refundTransactionId,
    String? refundOrderNum,
    String? refundReason,
    RefundType? refundType,
    RefundMethod? refundMethod,
    String? refundApprover,
  }) =>
      _dao.processRefund(
        orderNum: orderNum,
        refundAmount: refundAmount,
        refundTransactionId: refundTransactionId,
        refundOrderNum: refundOrderNum,
        refundReason: refundReason,
        refundType: refundType,
        refundMethod: refundMethod,
        refundApprover: refundApprover,
      );

  @override
  Future<void> approveRefund(String orderNum, String approverId) =>
      _dao.approveRefund(orderNum, approverId);

  @override
  Future<void> updateStoreInfo({
    required String orderNum,
    String? storeReceiptData,
    String? storeProductId,
    String? storeTransactionId,
    SubscriptionType? subscriptionType,
    SubscriptionStatus? subscriptionStatus,
  }) =>
      _dao.updateStoreInfo(
        orderNum: orderNum,
        storeReceiptData: storeReceiptData,
        storeProductId: storeProductId,
        storeTransactionId: storeTransactionId,
        subscriptionType: subscriptionType,
        subscriptionStatus: subscriptionStatus,
      );

  @override
  Future<void> deleteOrder(String orderNum) => _dao.deleteOrder(orderNum);

  @override
  Future<void> deleteOrdersByUserId(String userId) =>
      _dao.deleteOrdersByUserId(userId);

  @override
  Future<Map<String, dynamic>> getOrderStats({String? userId}) =>
      _dao.getOrderStats(userId: userId);

  @override
  Future<Map<OrderStatus, int>> getOrderCountByStatus({String? userId}) =>
      _dao.getOrderCountByStatus(userId: userId);

  @override
  Future<Map<PayStatus, int>> getOrderCountByPayStatus({String? userId}) =>
      _dao.getOrderCountByPayStatus(userId: userId);
}
