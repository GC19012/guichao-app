import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';

/// OrderEntry (Drift/SQLite) 扩展 - 转换为领域模型
extension OrderEntryExt on OrderEntry {
  /// 转换为 OrderData 领域模型
  OrderData toData() {
    return OrderData(
      orderNum: orderNum,
      srcOrderNum: srcOrderNum,
      userId: userId,
      productId: productId,
      productName: productName,
      originalTotal: originalTotal,
      discountTotal: discountTotal,
      total: total,
      currency: currency,
      voucherId: voucherId,
      payProvider: payProvider,
      orderType: orderType,
      clientIp: clientIp,
      clientType: clientType,
      payStatus: payStatus,
      status: status,
      transactionId: transactionId,
      agentChannel: agentChannel,
      agentId: agentId,
      platform: platform,
      refundTotal: refundTotal,
      refundTransactionId: refundTransactionId,
      refundOrderNum: refundOrderNum,
      refundReason: refundReason,
      refundAt: refundAt,
      refundType: refundType,
      refundMethod: refundMethod,
      refundApprover: refundApprover,
      refundApprovedAt: refundApprovedAt,
      storeReceiptData: storeReceiptData,
      storeProductId: storeProductId,
      storeTransactionId: storeTransactionId,
      subscriptionType: subscriptionType,
      subscriptionStatus: subscriptionStatus,
      extra1: extra1,
      extra2: extra2,
      extra3: extra3,
      extra4: extra4,
      createAt: createAt,
      updateAt: updateAt,
      expireAt: expireAt,
      payAt: payAt,
      notifyUrl: notifyUrl,
      qty: qty,
      acknowledgementState: acknowledgementState,
      remark: remark,
      price: price,
      tax: tax,
      rate: rate,
    );
  }
}

/// List<OrderEntry> 批量转换扩展
extension OrderEntryListExt on List<OrderEntry> {
  /// 批量转换为 OrderData 列表
  List<OrderData> toDataList() => map((e) => e.toData()).toList();
}

