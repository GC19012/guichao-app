import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';

/// 订单数据转换工具类
class OrderConverter {
  /// 从服务端JSON转换为OrderEntry
  static OrderEntry fromServerJson(Map<String, dynamic> json, {
    String? defaultUserId,
    int? defaultProductId,
    double? defaultAmount,
    String? defaultCurrency,
    String? defaultProductName,
    String? defaultPlatform,
    String? defaultClientIp,
    int? defaultPayProvider,
    String? defaultOrderType,
  }) {
    return OrderEntry(
      // 主键 - 订单号
      orderNum: json['order_num']?.toString() ??
                json['order_id']?.toString() ??
                json['ordernum']?.toString() ?? '',

      // 源订单号（退款关联）
      srcOrderNum: json['src_order_num']?.toString() ??
                   json['srcOrderNum']?.toString(),

      // 用户信息
      userId: json['user_id']?.toString() ??
              json['userId']?.toString() ??
              json['userid']?.toString() ??
              defaultUserId ?? '',

      // 产品信息
      productId: _parseIntSafe(json['product_id']) ??
                 _parseIntSafe(json['productId']) ??
                 _parseIntSafe(json['productid']) ??
                 defaultProductId ?? 0,
      productName: json['product_name']?.toString() ??
                   json['productName']?.toString() ??
                   json['productname']?.toString() ??
                   defaultProductName,
      
      // 金额信息
      originalTotal: _parseDoubleSafe(json['original_total']) ?? 
                     _parseDoubleSafe(json['originalTotal']) ?? 
                     defaultAmount ?? 0.0,
      discountTotal: _parseDoubleSafe(json['discount_total']) ?? 
                     _parseDoubleSafe(json['discountTotal']) ?? 0.0,
      total: _parseDoubleSafe(json['total']) ?? 
             _parseDoubleSafe(json['amount']) ?? 
             defaultAmount ?? 0.0,
      currency: json['currency']?.toString() ?? 
                defaultCurrency ?? 'USD',
      
      // 支付信息
      voucherId: json['voucher_id']?.toString() ??
                 json['voucherId']?.toString() ?? '',
      payProvider: _parseIntSafe(json['pay_provider']) ??
                   _parseIntSafe(json['payProvider']) ??
                   defaultPayProvider,

      // 订单类型
      orderType: json['order_type']?.toString() ??
                 json['orderType']?.toString() ??
                 defaultOrderType ??
                 OrderType.subscription.value,  // 默认为订阅类型
      
      // 客户端信息
      clientIp: json['client_ip']?.toString() ??
                json['clientIp']?.toString() ??
                defaultClientIp,
      clientType: json['client_type']?.toString() ??
                  json['clientType']?.toString(),
      
      // 状态信息
      payStatus: _parseIntSafe(json['pay_status']) ?? 
                 _parseIntSafe(json['payStatus']) ?? 
                 PayStatus.unpaid.value,
      status: _parseIntSafe(json['status']) ?? 
              _parseIntSafe(json['order_status']) ?? 
              OrderStatus.pending.value,
      
      // 交易信息
      transactionId: json['transaction_id']?.toString() ??
                     json['transactionId']?.toString() ??
                     json['trade_no']?.toString(),
      agentChannel: json['agent_channel']?.toString() ??
                    json['agentChannel']?.toString(),
      agentId: _parseIntSafe(json['agent_id']) ??
               _parseIntSafe(json['agentId']) ?? 0,
      platform: json['platform']?.toString() ??
                json['pay_platform']?.toString() ??
                json['payPlatform']?.toString() ??
                defaultPlatform ?? '',
      
      // 退款信息
      refundTotal: _parseDoubleSafe(json['refund_total']) ?? 
                   _parseDoubleSafe(json['refundTotal']) ?? 0.0,
      refundTransactionId: json['refund_transaction_id']?.toString() ?? 
                           json['refundTransactionId']?.toString(),
      refundOrderNum: json['refund_order_num']?.toString() ?? 
                      json['refundOrderNum']?.toString(),
      refundReason: json['refund_reason']?.toString() ?? 
                    json['refundReason']?.toString(),
      refundAt: _parseDateTimeSafe(json['refund_at']) ?? 
                _parseDateTimeSafe(json['refundAt']),
      refundType: json['refund_type']?.toString() ?? 
                  json['refundType']?.toString(),
      refundMethod: json['refund_method']?.toString() ?? 
                    json['refundMethod']?.toString(),
      refundApprover: json['refund_approver']?.toString() ?? 
                      json['refundApprover']?.toString(),
      refundApprovedAt: _parseDateTimeSafe(json['refund_approved_at']) ?? 
                        _parseDateTimeSafe(json['refundApprovedAt']),
      
      // 应用商店信息
      storeReceiptData: json['store_receipt_data']?.toString() ?? 
                        json['storeReceiptData']?.toString(),
      storeProductId: json['store_product_id']?.toString() ?? 
                      json['storeProductId']?.toString(),
      storeTransactionId: json['store_transaction_id']?.toString() ?? 
                          json['storeTransactionId']?.toString(),
      
      // 订阅信息
      subscriptionType: json['subscription_type']?.toString() ?? 
                        json['subscriptionType']?.toString(),
      subscriptionStatus: json['subscription_status']?.toString() ?? 
                          json['subscriptionStatus']?.toString(),
      
      // 扩展字段
      extra1: _parseIntSafe(json['extra1']),
      extra2: _parseIntSafe(json['extra2']),
      extra3: json['extra3']?.toString(),
      extra4: json['extra4']?.toString(),
      
      // 时间信息
      createAt: _parseDateTimeSafe(json['create_at']) ?? 
                _parseDateTimeSafe(json['createAt']) ?? 
                _parseDateTimeSafe(json['created_at']) ?? 
                _parseDateTimeSafe(json['createat']) ??
                DateTime.now(),
      updateAt: _parseDateTimeSafe(json['update_at']) ?? 
                _parseDateTimeSafe(json['updateAt']) ?? 
                _parseDateTimeSafe(json['updated_at']) ?? 
                _parseDateTimeSafe(json['updateat']) ??
                DateTime.now(),
      expireAt: _parseDateTimeSafe(json['expire_at']) ??
                _parseDateTimeSafe(json['expireAt']) ??
                _parseDateTimeSafe(json['expireat']),
      payAt: _parseDateTimeSafe(json['pay_at']) ?? 
             _parseDateTimeSafe(json['payAt']) ?? 
             _parseDateTimeSafe(json['paid_at']) ??
             _parseDateTimeSafe(json['payat']),
      
      // 其他信息
      notifyUrl: json['notify_url']?.toString() ??
                 json['notifyUrl']?.toString(),
      qty: _parseDoubleSafe(json['qty']) ??
           _parseDoubleSafe(json['quantity']) ?? 1.0,
      acknowledgementState: json['acknowledgement_state']?.toString() ??
                            json['acknowledgementState']?.toString() ??
                            json['acknowledgementstate']?.toString(),
      remark: json['remark']?.toString() ??
              json['note']?.toString() ??
              json['description']?.toString(),

      // 价格税费信息
      price: _parseDoubleSafe(json['price']) ??
             _parseDoubleSafe(json['unit_price']) ?? 0.0,
      tax: _parseDoubleSafe(json['tax']) ??
           _parseDoubleSafe(json['tax_amount']) ?? 0.0,
      rate: _parseDoubleSafe(json['rate']) ??
            _parseDoubleSafe(json['tax_rate']) ?? 0.0,

      // 取消时间
      cancelledAt: _parseDateTimeSafe(json['cancelled_at']) ??
                   _parseDateTimeSafe(json['cancelledAt']) ??
                   _parseDateTimeSafe(json['cancelledat']),
    );
  }

  /// 批量转换订单列表
  static List<OrderEntry> fromServerJsonList(List<dynamic> jsonList, {
    String? defaultUserId,
    String? defaultCurrency,
  }) {
    return jsonList
        .map((json) => fromServerJson(
              json as Map<String, dynamic>,
              defaultUserId: defaultUserId,
              defaultCurrency: defaultCurrency,
            ))
        .toList();
  }

  /// 安全解析整数
  static int? _parseIntSafe(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 安全解析浮点数
  static double? _parseDoubleSafe(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// 安全解析日期时间
  static DateTime? _parseDateTimeSafe(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return value.isUtc ? value.toLocal() : value;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;

      final iso = DateTime.tryParse(trimmed);
      if (iso != null) {
        return iso.isUtc ? iso.toLocal() : iso;
      }

      final timestamp = int.tryParse(trimmed);
      if (timestamp != null && timestamp > 0) {
        return _fromEpoch(timestamp);
      }
    }
    if (value is int && value > 0) {
      return _fromEpoch(value);
    }
    return null;
  }

  static DateTime _fromEpoch(int timestamp) {
    final millis = timestamp < 10000000000 ? timestamp * 1000 : timestamp;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
  }
}
