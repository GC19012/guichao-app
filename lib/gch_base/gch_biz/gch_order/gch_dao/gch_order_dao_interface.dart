import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';

/// Order DAO 统一接口 - 类型安全的订单数据访问抽象
///
/// 【设计原则】
/// - 完整性：包含所有订单操作，从CRUD到统计分析
/// - 响应式：Stream API 支持实时数据监听
/// - 类型安全：编译时检查，避免运行时错误
/// - 存储无关：支持 SQLite、Realm 等多种实现
abstract interface class OrderDaoInterface {
  // ==================== 响应式查询 (Watch) ====================

  /// 监听所有订单变化
  Stream<List<OrderEntry>> watchOrders();

  /// 按用户ID监听订单
  Stream<List<OrderEntry>> watchOrdersByUserId(String userId);

  /// 按订单状态监听
  Stream<List<OrderEntry>> watchOrdersByOrderStatus(OrderStatus orderStatus);

  /// 按支付状态监听
  Stream<List<OrderEntry>> watchOrdersByPayStatus(PayStatus payStatus);

  /// 按订单类型监听
  Stream<List<OrderEntry>> watchOrdersByType(OrderType orderType);

  /// 按支付平台监听
  Stream<List<OrderEntry>> watchOrdersByPlatform(PaymentPlatform platform);

  /// 监听应用商店订单
  Stream<List<OrderEntry>> watchStoreOrders();

  /// 监听退款订单
  Stream<List<OrderEntry>> watchRefundOrders();

  // ==================== 单订单查询 ====================

  /// 按订单号获取订单
  Future<OrderEntry?> getOrderByNum(String orderNum);

  /// 按第三方交易号获取订单
  Future<OrderEntry?> getOrderByTransactionId(String transactionId);

  /// 按应用商店交易ID获取订单
  Future<OrderEntry?> getOrderByStoreTransactionId(String storeTransactionId);

  /// 获取用户的最新订单
  Future<OrderEntry?> getLatestOrderByUserId(String userId);

  // ==================== 批量查询 ====================

  /// 分页获取订单列表
  Future<List<OrderEntry>> getOrdersPaginated({
    String? userId,
    OrderStatus? orderStatus,
    PayStatus? payStatus,
    OrderType? orderType,
    PaymentPlatform? platform,
    int offset = 0,
    int limit = 20,
  });

  /// 搜索订单
  Future<List<OrderEntry>> searchOrders({
    required String searchTerm,
    String? userId,
    int limit = 50,
  });

  /// 获取过期未支付的订单
  Future<List<OrderEntry>> getExpiredUnpaidOrders();

  // ==================== 创建和更新 ====================

  /// 插入新订单
  Future<void> insertOrder(OrderEntry order);

  /// 更新现有订单
  Future<void> updateOrder(OrderEntry order);

  /// 插入或更新订单（Upsert）
  Future<void> upsertOrder(OrderEntry order);

  /// 批量插入或更新订单
  Future<void> upsertOrders(List<OrderEntry> orders);

  // ==================== 状态更新 ====================

  /// 更新订单状态
  Future<void> updateOrderStatus(String orderNum, OrderStatus orderStatus);

  /// 更新支付状态
  Future<void> updatePayStatus(String orderNum, PayStatus payStatus, {DateTime? payAt});

  /// 更新第三方交易ID
  Future<void> updateTransactionId(String orderNum, String transactionId);

  /// 标记过期订单
  Future<void> markExpiredOrders();

  // ==================== 退款操作 ====================

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
  });

  /// 审批退款
  Future<void> approveRefund(String orderNum, String approverId);

  // ==================== 应用商店操作 ====================

  /// 更新应用商店相关信息
  Future<void> updateStoreInfo({
    required String orderNum,
    String? storeReceiptData,
    String? storeProductId,
    String? storeTransactionId,
    SubscriptionType? subscriptionType,
    SubscriptionStatus? subscriptionStatus,
  });

  // ==================== 删除操作 ====================

  /// 删除订单
  Future<void> deleteOrder(String orderNum);

  /// 删除用户的所有订单
  Future<void> deleteOrdersByUserId(String userId);

  // ==================== 统计分析 ====================

  /// 获取订单统计信息
  Future<Map<String, dynamic>> getOrderStats({String? userId});

  /// 获取按状态分组的订单数量
  Future<Map<OrderStatus, int>> getOrderCountByStatus({String? userId});

  /// 获取按支付状态分组的订单数量
  Future<Map<PayStatus, int>> getOrderCountByPayStatus({String? userId});
}
