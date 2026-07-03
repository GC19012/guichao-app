import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/cupertino.dart';
import 'package:fpdart/fpdart.dart';

import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_manager.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_client/gch_api_client.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_dao/gch_order_dao_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';

/// 订单失败类型
sealed class OrderFailure {
  const OrderFailure();
}

class OrderNotFoundFailure extends OrderFailure {
  const OrderNotFoundFailure();

  @override
  String toString() => 'OrderNotFoundFailure: 订单未找到';
}

class OrderNetworkFailure extends OrderFailure {
  final String message;
  const OrderNetworkFailure(this.message);

  @override
  String toString() => 'OrderNetworkFailure: $message';
}

class OrderValidationFailure extends OrderFailure {
  final String message;
  const OrderValidationFailure(this.message);

  @override
  String toString() => 'OrderValidationFailure: $message';
}

class OrderPaymentFailure extends OrderFailure {
  final String message;
  const OrderPaymentFailure(this.message);

  @override
  String toString() => 'OrderPaymentFailure: $message';
}

class OrderRefundFailure extends OrderFailure {
  final String message;
  const OrderRefundFailure(this.message);

  @override
  String toString() => 'OrderRefundFailure: $message';
}

class OrderUnexpectedFailure extends OrderFailure {
  final Object error;
  const OrderUnexpectedFailure(this.error);

  @override
  String toString() => 'OrderUnexpectedFailure: $error';
}

/// 订单仓库接口
abstract class OrderRepositoryInterface {
  /// 获取所有订单的流
  Stream<List<OrderEntry>> watchOrders();

  /// 按用户ID获取订单的流
  Stream<List<OrderEntry>> watchOrdersByUserId(String userId);

  /// 按订单状态获取订单的流
  Stream<List<OrderEntry>> watchOrdersByOrderStatus(OrderStatus status);

  /// 按支付状态获取订单的流
  Stream<List<OrderEntry>> watchOrdersByPayStatus(PayStatus status);

  /// 按订单类型获取订单的流
  Stream<List<OrderEntry>> watchOrdersByType(OrderType orderType);

  /// 按支付平台获取订单的流
  Stream<List<OrderEntry>> watchOrdersByPlatform(PaymentPlatform platform);

  /// 获取应用商店订单的流
  Stream<List<OrderEntry>> watchStoreOrders();

  /// 获取退款订单的流
  Stream<List<OrderEntry>> watchRefundOrders();

  /// 按订单号获取特定订单
  Future<Either<OrderFailure, OrderEntry>> getOrderByNum(String orderNum);

  /// 按第三方交易号获取订单
  Future<Either<OrderFailure, OrderEntry>> getOrderByTransactionId(String transactionId);

  /// 按应用商店交易ID获取订单
  Future<Either<OrderFailure, OrderEntry>> getOrderByStoreTransactionId(String storeTransactionId);

  /// 获取用户的最新订单
  Future<Either<OrderFailure, OrderEntry>> getLatestOrderByUserId(String userId);

  /// 创建新订单
  Future<Either<OrderFailure, OrderEntry>> createOrder(OrderEntry order);

  //取消订单
  Future<Either<OrderFailure,OrderEntry>> CancelOrder(String orderid,String reason);
  /// 更新现有订单
  Future<Either<OrderFailure, OrderEntry>> updateOrder(OrderEntry order);

  /// 更新订单状态
  Future<Either<OrderFailure, Unit>> updateOrderStatus(String orderNum, OrderStatus orderStatus);

  /// 更新支付状态
  Future<Either<OrderFailure, Unit>> updatePayStatus(String orderNum, PayStatus payStatus, {DateTime? payAt});

  /// 处理退款
  Future<Either<OrderFailure, Unit>> processRefund({
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
  Future<Either<OrderFailure, Unit>> approveRefund(String orderNum, String approverId);

  /// 更新应用商店相关信息
  Future<Either<OrderFailure, Unit>> updateStoreInfo({
    required String orderNum,
    String? storeReceiptData,
    String? storeProductId,
    String? storeTransactionId,
    SubscriptionType? subscriptionType,
    SubscriptionStatus? subscriptionStatus,
  });

  /// 删除订单
  Future<Either<OrderFailure, Unit>> deleteOrder(String orderNum);

  /// 删除用户的所有订单
  Future<Either<OrderFailure, Unit>> deleteOrdersByUserId(String userId);

  /// 获取订单统计信息
  Future<Either<OrderFailure, Map<String, dynamic>>> getOrderStats({String? userId});

  /// 获取按状态分组的订单数量
  Future<Either<OrderFailure, Map<OrderStatus, int>>> getOrderCountByStatus({String? userId});

  /// 获取按支付状态分组的订单数量
  Future<Either<OrderFailure, Map<PayStatus, int>>> getOrderCountByPayStatus({String? userId});

  /// 分页获取订单列表
  Future<Either<OrderFailure, List<OrderEntry>>> getOrdersPaginated({
    String? userId,
    OrderStatus? orderStatus,
    PayStatus? payStatus,
    OrderType? orderType,
    PaymentPlatform? platform,
    int offset = 0,
    int limit = 20,
  });

  /// 搜索订单
  Future<Either<OrderFailure, List<OrderEntry>>> searchOrders({
    required String searchTerm,
    String? userId,
    int limit = 50,
  });

  /// 从服务器同步订单列表
  Future<Either<OrderFailure, Unit>> syncOrdersFromServer({
    String? userId,
    int page = 1,
    int pageSize = 50,
  });

  /// 从服务器获取单个订单
  Future<Either<OrderFailure, OrderEntry>> syncOrderFromServer(String orderNum);

  /// 按应用商店交易ID从服务器同步订单
  Future<Either<OrderFailure, OrderEntry>> syncOrderByStoreTransactionId(String storeTransactionId);

  /// 向服务器提交退款申请
  Future<Either<OrderFailure, Unit>> requestRefundOnServer({
    required String orderNum,
    required double refundAmount,
    required String refundReason,
    RefundType refundType = RefundType.full,
  });

  /// 验证应用商店收据
  Future<Either<OrderFailure, Unit>> verifyStoreReceiptOnServer({
    required String orderNum,
    required String receiptData,
    required PaymentPlatform platform,
  });

  /// 获取订单统计信息
  Future<Either<OrderFailure, Map<String, dynamic>>> getOrderStatsFromServer({String? userId});

  /// 标记过期订单
  Future<Either<OrderFailure, Unit>> markExpiredOrders();
}

/// 订单仓库实现类
class OrderRepository implements OrderRepositoryInterface {
  final OrderDaoInterface _localDao; // ✅ 类型安全：支持任何实现 OrderDaoInterface 的 DAO
  final DataApiClient _apiClient;

  OrderRepository(this._localDao, this._apiClient);

  /// 初始化 API 客户端
  void initializeApiClient(AuthManager authManager) {
    _apiClient.useAuth(authManager);
    // 加密已在Provider层统一配置
  }

  @override
  Stream<List<OrderEntry>> watchOrders() {
    return _localDao.watchOrders();
  }

  @override
  Stream<List<OrderEntry>> watchOrdersByUserId(String userId) {
    return _localDao.watchOrdersByUserId(userId);
  }

  @override
  Stream<List<OrderEntry>> watchOrdersByOrderStatus(OrderStatus status) {
    return _localDao.watchOrdersByOrderStatus(status);
  }

  @override
  Stream<List<OrderEntry>> watchOrdersByPayStatus(PayStatus status) {
    return _localDao.watchOrdersByPayStatus(status);
  }

  @override
  Stream<List<OrderEntry>> watchOrdersByType(OrderType orderType) {
    return _localDao.watchOrdersByType(orderType);
  }

  @override
  Stream<List<OrderEntry>> watchOrdersByPlatform(PaymentPlatform platform) {
    return _localDao.watchOrdersByPlatform(platform);
  }

  @override
  Stream<List<OrderEntry>> watchStoreOrders() {
    return _localDao.watchStoreOrders();
  }

  @override
  Stream<List<OrderEntry>> watchRefundOrders() {
    return _localDao.watchRefundOrders();
  }

  @override
  Future<Either<OrderFailure, OrderEntry>> getOrderByNum(String orderNum) async {
    try {
      final order = await _localDao.getOrderByNum(orderNum);
      if (order == null) {
        return const Left(OrderNotFoundFailure());
      }
      return Right(order);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, OrderEntry>> getOrderByTransactionId(String transactionId) async {
    try {
      final order = await _localDao.getOrderByTransactionId(transactionId);
      if (order == null) {
        return const Left(OrderNotFoundFailure());
      }
      return Right(order);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, OrderEntry>> getOrderByStoreTransactionId(String storeTransactionId) async {
    try {
      final order = await _localDao.getOrderByStoreTransactionId(storeTransactionId);
      if (order == null) {
        return const Left(OrderNotFoundFailure());
      }
      return Right(order);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, OrderEntry>> getLatestOrderByUserId(String userId) async {
    try {
      final order = await _localDao.getLatestOrderByUserId(userId);
      if (order == null) {
        return const Left(OrderNotFoundFailure());
      }
      return Right(order);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, OrderEntry>> createOrder(OrderEntry order) async {
    try {
      // 验证订单数据
      final validationResult = _validateOrder(order);
      if (validationResult != null) {
        return Left(OrderValidationFailure(validationResult));
      }

      await _localDao.insertOrder(order);
      return Right(order);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, OrderEntry>> CancelOrder(String orderid, String reason) async {
    try {
      // 先获取订单
      final orderResult = await getOrderByNum(orderid);
      if (orderResult.isLeft()) {
        return orderResult;
      }

      final order = orderResult.getRight().getOrElse(() => throw StateError('Order should exist'));

      // 检查订单是否可以取消
      if (!canCancelOrder(order)) {
        return const Left(OrderValidationFailure('订单状态不允许取消'));
      }

      // 更新本地订单状态
      final cancelledOrder = order.copyWith(
        status: OrderStatus.cancelled.value,
        payStatus: PayStatus.cancelled.value,
        updateAt: DateTime.now(),
        remark: Value('${order.remark ?? ''} [取消原因: $reason]'),
      );

      await _localDao.updateOrder(cancelledOrder);
      return Right(cancelledOrder);

    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, OrderEntry>> updateOrder(OrderEntry order) async {
    try {
      // 验证订单数据
      final validationResult = _validateOrder(order);
      if (validationResult != null) {
        return Left(OrderValidationFailure(validationResult));
      }

      await _localDao.updateOrder(order);
      return Right(order);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Unit>> updateOrderStatus(String orderNum, OrderStatus orderStatus) async {
    try {
      await _localDao.updateOrderStatus(orderNum, orderStatus);
      return const Right(unit);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Unit>> updatePayStatus(String orderNum, PayStatus payStatus, {DateTime? payAt}) async {
    try {
      await _localDao.updatePayStatus(orderNum, payStatus, payAt: payAt);
      return const Right(unit);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Unit>> processRefund({
    required String orderNum,
    required double refundAmount,
    String? refundTransactionId,
    String? refundOrderNum,
    String? refundReason,
    RefundType? refundType,
    RefundMethod? refundMethod,
    String? refundApprover,
  }) async {
    try {
      // 验证退款金额
      if (refundAmount <= 0) {
        return const Left(OrderRefundFailure('退款金额必须大于0'));
      }

      await _localDao.processRefund(
        orderNum: orderNum,
        refundAmount: refundAmount,
        refundTransactionId: refundTransactionId,
        refundOrderNum: refundOrderNum,
        refundReason: refundReason,
        refundType: refundType,
        refundMethod: refundMethod,
        refundApprover: refundApprover,
      );
      return const Right(unit);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Unit>> approveRefund(String orderNum, String approverId) async {
    try {
      await _localDao.approveRefund(orderNum, approverId);
      return const Right(unit);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Unit>> updateStoreInfo({
    required String orderNum,
    String? storeReceiptData,
    String? storeProductId,
    String? storeTransactionId,
    SubscriptionType? subscriptionType,
    SubscriptionStatus? subscriptionStatus,
  }) async {
    try {
      await _localDao.updateStoreInfo(
        orderNum: orderNum,
        storeReceiptData: storeReceiptData,
        storeProductId: storeProductId,
        storeTransactionId: storeTransactionId,
        subscriptionType: subscriptionType,
        subscriptionStatus: subscriptionStatus,
      );
      return const Right(unit);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Unit>> deleteOrder(String orderNum) async {
    try {
      await _localDao.deleteOrder(orderNum);
      return const Right(unit);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Unit>> deleteOrdersByUserId(String userId) async {
    try {
      await _localDao.deleteOrdersByUserId(userId);
      return const Right(unit);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Map<String, dynamic>>> getOrderStats({String? userId}) async {
    try {
      final stats = await _localDao.getOrderStats(userId: userId);
      return Right(stats);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Map<OrderStatus, int>>> getOrderCountByStatus({String? userId}) async {
    try {
      final statusCounts = await _localDao.getOrderCountByStatus(userId: userId);
      return Right(statusCounts);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Map<PayStatus, int>>> getOrderCountByPayStatus({String? userId}) async {
    try {
      final payStatusCounts = await _localDao.getOrderCountByPayStatus(userId: userId);
      return Right(payStatusCounts);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, List<OrderEntry>>> getOrdersPaginated({
    String? userId,
    OrderStatus? orderStatus,
    PayStatus? payStatus,
    OrderType? orderType,
    PaymentPlatform? platform,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final orders = await _localDao.getOrdersPaginated(
        userId: userId,
        orderStatus: orderStatus,
        payStatus: payStatus,
        orderType: orderType,
        platform: platform,
        offset: offset,
        limit: limit,
      );
      return Right(orders);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, List<OrderEntry>>> searchOrders({
    required String searchTerm,
    String? userId,
    int limit = 50,
  }) async {
    try {
      final orders = await _localDao.searchOrders(
        searchTerm: searchTerm,
        userId: userId,
        limit: limit,
      );
      return Right(orders);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Unit>> syncOrdersFromServer({
    String? userId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      // 计算 offset: page 从 1 开始，offset = (page - 1) * pageSize
      final offset = (page - 1) * pageSize;

      final requestBody = <String, dynamic>{
        'limit': pageSize,
        'offset': offset,
        'sort_by': 'createat',
        'sort_desc': true,
      };

      if (userId != null && userId.isNotEmpty) {
        requestBody['user_id'] = userId;
      }

      final result = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/orders/list',
        data: requestBody,
      );

      // 处理响应数据：{ code, data: { count, items, limit, offset }, msg, success }
      if (result.data != null) {
        final dataObj = result.data!['data'];
        if (dataObj == null || dataObj is! Map<String, dynamic>) {
          return const Left(OrderNetworkFailure('返回数据格式不正确：缺少 data 字段'));
        }

        final items = dataObj['items'];
        if (items == null || items is! List) {
          return const Left(OrderNetworkFailure('返回数据格式不正确：items 不是数组'));
        }

        for (final item in items) {
          final order = _orderFromJson(item as Map<String, dynamic>);
          // 使用 upsert 逻辑避免主键冲突
          final existingOrder = await _localDao.getOrderByNum(order.orderNum);
          if (existingOrder != null) {
            await _localDao.updateOrder(order);
          } else {
            await _localDao.insertOrder(order);
          }
        }
        return const Right(unit);
      } else {
        return const Left(OrderNetworkFailure('No data received'));
      }
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }



  @override
  Future<Either<OrderFailure, OrderEntry>> syncOrderFromServer(String orderNum) async {
    try {
      final result = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/orders/$orderNum',
      );

      if (result.data != null) {
        final order = _orderFromJson(result.data!);
        return Right(order);
      } else {
        return const Left(OrderNetworkFailure('No data received'));
      }
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, OrderEntry>> syncOrderByStoreTransactionId(String storeTransactionId) async {
    try {
      final result = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/orders/getorderbystoretransaction',
        data: {'store_transaction_id': storeTransactionId},
      );

      if (result.data != null) {
        // 后端返回格式: { code, message, data: {...order} }
        // 需要从 data 字段中提取订单数据
        final responseData = result.data!;
        debugPrint('responseData: $result');
        final orderData = responseData['data'] as Map<String, dynamic>? ?? responseData;

        final order = _orderFromJson(orderData);
        // 验证订单号不为空
        if (order.orderNum.isEmpty) {
          return const Left(OrderValidationFailure('订单号为空，无法同步'));
        }
        // 同步到本地数据库（使用 upsert 避免主键冲突）
        final existingOrder = await _localDao.getOrderByNum(order.orderNum);
        if (existingOrder != null) {
          await _localDao.updateOrder(order);
        } else {
          await _localDao.insertOrder(order);
        }
        return Right(order);
      } else {
        return const Left(OrderNetworkFailure('No data received'));
      }
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Unit>> requestRefundOnServer({
    required String orderNum,
    required double refundAmount,
    required String refundReason,
    RefundType refundType = RefundType.full,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/api/orders/$orderNum/refund',
        data: {
          'refundAmount': refundAmount,
          'refundReason': refundReason,
          'refundType': refundType.name,
        },
      );

      return const Right(unit);
    } catch (e) {
      if (e is DioException) {
        return Left(OrderRefundFailure(e.message ?? 'Network error'));
      }
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Unit>> verifyStoreReceiptOnServer({
    required String orderNum,
    required String receiptData,
    required PaymentPlatform platform,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/api/orders/$orderNum/verify-receipt',
        data: {
          'receiptData': receiptData,
          'platform': platform.name,
        },
      );

      return const Right(unit);
    } catch (e) {
      if (e is DioException) {
        return Left(OrderPaymentFailure(e.message ?? 'Network error'));
      }
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Map<String, dynamic>>> getOrderStatsFromServer({String? userId}) async {
    try {
      final queryParams = userId != null ? {'userId': userId} : null;

      final result = await _apiClient.get<Map<String, dynamic>>(
        '/api/orders/stats',
        queryParameters: queryParams,
      );

      if (result.data != null) {
        return Right(result.data!);
      } else {
        return const Left(OrderNetworkFailure('No data received'));
      }
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  @override
  Future<Either<OrderFailure, Unit>> markExpiredOrders() async {
    try {
      await _localDao.markExpiredOrders();
      return const Right(unit);
    } catch (e) {
      return Left(OrderUnexpectedFailure(e));
    }
  }

  /// 获取订单状态的显示名称
  String getOrderStatusDisplayName(int statusValue) {
    return OrderStatus.fromValue(statusValue).displayName;
  }

  /// 获取支付状态的显示名称
  String getPayStatusDisplayName(int statusValue) {
    return PayStatus.fromValue(statusValue).displayName;
  }

  /// 获取订单类型的显示名称
  String getOrderTypeDisplayName(String typeValue) {
    return OrderType.fromValue(typeValue).displayName;
  }

  /// 获取支付平台的显示名称
  String getPaymentPlatformDisplayName(String platformValue) {
    return PaymentPlatform.fromValue(platformValue).displayName;
  }

  /// 检查订单是否可以取消
  bool canCancelOrder(OrderEntry order) {
    return order.payStatus == PayStatus.unpaid.value && order.status == OrderStatus.pending.value && (order.expireAt == null || order.expireAt!.isAfter(DateTime.now()));
  }

  /// 检查订单是否可以申请退款
  bool canRequestRefund(OrderEntry order) {
    return order.payStatus == PayStatus.paid.value && order.refundTotal == 0.0 && order.status == OrderStatus.completed.value;
  }

  /// 检查订单是否已过期
  bool isOrderExpired(OrderEntry order) {
    return order.expireAt != null && order.expireAt!.isBefore(DateTime.now()) && order.payStatus == PayStatus.unpaid.value;
  }

  /// 计算订单的净收入
  double calculateNetRevenue(OrderEntry order) {
    return order.total - order.refundTotal;
  }

  /// 验证订单数据的私有方法
  String? _validateOrder(OrderEntry order) {
    if (order.orderNum.isEmpty) {
      return '订单号不能为空';
    }
    if (order.userId.isEmpty) {
      return '用户ID不能为空';
    }
    if (order.productId <= 0) {
      return '产品ID无效';
    }
    if (order.originalTotal < 0) {
      return '原价金额不能为负数';
    }
    if (order.discountTotal < 0) {
      return '折扣金额不能为负数';
    }
    if (order.total <= 0) {
      return '支付金额必须大于0';
    }
    if (order.discountTotal > order.originalTotal) {
      return '折扣金额不能大于原价';
    }
    if (order.agentId < 0) {
      return '代理商ID无效';
    }
    return null;
  }

  /// 从 JSON 创建 OrderEntry（兼容三种命名格式）
  /// - camelCase: orderNum, userId
  /// - snake_case: order_num, user_id
  /// - lowercase: ordernum, userid (后端实际返回格式)
  OrderEntry _orderFromJson(Map<String, dynamic> json) {
    // 辅助函数：按优先级查找字段（camelCase > snake_case > lowercase）
    String? getStringValue(String camelKey, String snakeKey, String lowerKey) {
      return json[camelKey] as String? ??
             json[snakeKey] as String? ??
             json[lowerKey] as String?;
    }

    int? getIntValue(String camelKey, String snakeKey, String lowerKey) {
      final value = json[camelKey] ?? json[snakeKey] ?? json[lowerKey];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }

    double getDoubleValue(String camelKey, String snakeKey, String lowerKey, {double defaultValue = 0.0}) {
      final value = json[camelKey] ?? json[snakeKey] ?? json[lowerKey];
      if (value is num) return value.toDouble();
      return defaultValue;
    }

    DateTime? getDateTimeValue(String camelKey, String snakeKey, String lowerKey) {
      final value = getStringValue(camelKey, snakeKey, lowerKey);
      if (value == null || value.isEmpty) return null;
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return OrderEntry(
      orderNum: getStringValue('orderNum', 'order_num', 'ordernum') ?? '',
      srcOrderNum: getStringValue('srcOrderNum', 'src_order_num', 'srcordernum'),
      userId: getStringValue('userId', 'user_id', 'userid') ?? '',
      productId: getIntValue('productId', 'product_id', 'productid') ?? 0,
      productName: getStringValue('productName', 'product_name', 'productname'),
      originalTotal: getDoubleValue('originalTotal', 'original_total', 'originaltotal'),
      discountTotal: getDoubleValue('discountTotal', 'discount_total', 'discounttotal'),
      total: getDoubleValue('total', 'total', 'total'),
      currency: getStringValue('currency', 'currency', 'currency') ?? 'USD',
      voucherId: getStringValue('voucherId', 'voucher_id', 'voucherid') ?? '',
      payProvider: getIntValue('payProvider', 'pay_provider', 'payprovider'),
      orderType: getStringValue('orderType', 'order_type', 'ordertype') ?? 'subscription',
      clientIp: getStringValue('clientIp', 'client_ip', 'clientip'),
      clientType: getStringValue('clientType', 'client_type', 'clienttype'),
      payStatus: getIntValue('payStatus', 'pay_status', 'paystatus') ?? 0,
      status: getIntValue('status', 'status', 'status') ?? 0,
      transactionId: getStringValue('transactionId', 'transaction_id', 'transactionid'),
      agentChannel: getStringValue('agentChannel', 'agent_channel', 'agentchannel'),
      agentId: getIntValue('agentId', 'agent_id', 'agentid') ?? 0,
      platform: getStringValue('platform', 'platform', 'platform') ?? '',
      refundTotal: getDoubleValue('refundTotal', 'refund_total', 'refundtotal'),
      refundTransactionId: getStringValue('refundTransactionId', 'refund_transaction_id', 'refundtransactionid'),
      refundOrderNum: getStringValue('refundOrderNum', 'refund_order_num', 'refundordernum'),
      refundReason: getStringValue('refundReason', 'refund_reason', 'refundreason'),
      refundAt: getDateTimeValue('refundAt', 'refund_at', 'refundat'),
      refundType: getStringValue('refundType', 'refund_type', 'refundtype'),
      refundMethod: getStringValue('refundMethod', 'refund_method', 'refundmethod'),
      refundApprover: getStringValue('refundApprover', 'refund_approver', 'refundapprover'),
      refundApprovedAt: getDateTimeValue('refundApprovedAt', 'refund_approved_at', 'refundapprovedat'),
      storeReceiptData: getStringValue('storeReceiptData', 'store_receipt_data', 'storereceiptdata'),
      storeProductId: getStringValue('storeProductId', 'store_product_id', 'storeproductid'),
      storeTransactionId: getStringValue('storeTransactionId', 'store_transaction_id', 'storetransactionid'),
      subscriptionType: getStringValue('subscriptionType', 'subscription_type', 'subscriptiontype'),
      subscriptionStatus: getStringValue('subscriptionStatus', 'subscription_status', 'subscriptionstatus'),
      extra1: getIntValue('extra1', 'extra1', 'extra1'),
      extra2: getIntValue('extra2', 'extra2', 'extra2'),
      extra3: getStringValue('extra3', 'extra3', 'extra3'),
      extra4: getStringValue('extra4', 'extra4', 'extra4'),
      createAt: getDateTimeValue('createAt', 'create_at', 'createat') ?? DateTime.now(),
      updateAt: getDateTimeValue('updateAt', 'update_at', 'updateat') ?? DateTime.now(),
      expireAt: getDateTimeValue('expireAt', 'expire_at', 'expireat'),
      payAt: getDateTimeValue('payAt', 'pay_at', 'payat'),
      notifyUrl: getStringValue('notifyUrl', 'notify_url', 'notifyurl'),
      qty: getDoubleValue('qty', 'qty', 'qty', defaultValue: 1.0),
      acknowledgementState: getStringValue('acknowledgementState', 'acknowledgement_state', 'acknowledgementstate'),
      remark: getStringValue('remark', 'remark', 'remark'),
      price: getDoubleValue('price', 'price', 'price'),
      tax: getDoubleValue('tax', 'tax', 'tax'),
      rate: getDoubleValue('rate', 'rate', 'rate'),
    );
  }
}
