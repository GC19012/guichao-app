import 'package:drift/drift.dart';

enum PayStatus {
  unpaid(0),
  paid(1),
  failed(2),
  cancelled(3),
  refunded(4),
  partialRefunded(5),
  refunding(6);  // 退款处理中

  final int value;
  const PayStatus(this.value);

  factory PayStatus.fromValue(int value) {
    return PayStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PayStatus.unpaid,
    );
  }

  String get displayName {
    switch (this) {
      case PayStatus.unpaid:
        return '未支付';
      case PayStatus.paid:
        return '已支付';
      case PayStatus.failed:
        return '支付失败';
      case PayStatus.cancelled:
        return '已取消';
      case PayStatus.refunded:
        return '已退款';
      case PayStatus.partialRefunded:
        return '部分退款';
      case PayStatus.refunding:
        return '退款处理中';
    }
  }
}

/// 订单状态枚举
enum OrderStatus {
  pending(0),
  processing(1),
  completed(2),
  failed(3),
  cancelled(4),
  close(5),
  expired(6),
  refundApplied(7),    // 退款申请
  refundReviewing(8),  // 退款审核
  refundRejected(9);   // 退款拒绝

  final int value;
  const OrderStatus(this.value);

  factory OrderStatus.fromValue(int value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return '待处理';
      case OrderStatus.processing:
        return '处理中';
      case OrderStatus.completed:
        return '已完成';
      case OrderStatus.failed:
        return '已失败';
      case OrderStatus.cancelled:
        return '已取消';
      case OrderStatus.close:
        return '已关闭';
      case OrderStatus.expired:
        return '已过期';
      case OrderStatus.refundApplied:
        return '退款申请';
      case OrderStatus.refundReviewing:
        return '退款审核';
      case OrderStatus.refundRejected:
        return '退款拒绝';
    }
  }
}

/// 订单类型枚举
enum OrderType {
  /// 订阅
  subscription('subscription'),

  /// 一次性购买
  purchase('purchase'),

  /// 升级订单
  upgrade('upgrade'),

  /// 续费订单
  renewal('renewal'),

  /// 商品购买
  product('product'),

  /// 卡密兑换
  voucher('voucher'),

  /// 应用内购买
  inApp('in_app'),

  /// 退货单
  refund('refund');

  const OrderType(this.value);
  final String value;

  static OrderType fromValue(String value) {
    return OrderType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderType.subscription,
    );
  }

  String get displayName {
    switch (this) {
      case OrderType.subscription:
        return 'Subscription';
      case OrderType.purchase:
        return 'Purchase';
      case OrderType.upgrade:
        return '升级订单';
      case OrderType.renewal:
        return '续费订单';
      case OrderType.product:
        return '商品购买';
      case OrderType.voucher:
        return '卡密兑换';
      case OrderType.inApp:
        return '应用内购买';
      case OrderType.refund:
        return '退货单';
    }
  }
}

/// 支付平台枚举
enum PaymentPlatform {
  appStore('app_store'),
  stripe('stripe'),
  other('other');

  const PaymentPlatform(this.value);
  final String value;

  static PaymentPlatform fromValue(String value) {
    return PaymentPlatform.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentPlatform.other,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentPlatform.appStore:
        return 'App Store';
      case PaymentPlatform.stripe:
        return 'Stripe';
      case PaymentPlatform.other:
        return '其他';
    }
  }
}

/// 客户端类型枚举
enum ClientType {
  ios('IOS'),
  android('ANDROID'),
  web('WEB');

  const ClientType(this.value);
  final String value;

  static ClientType fromValue(String value) {
    return ClientType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ClientType.android,
    );
  }

  String get displayName {
    switch (this) {
      case ClientType.ios:
        return 'iOS';
      case ClientType.android:
        return 'Android';
      case ClientType.web:
        return 'Web';
    }
  }
}

/// 退款类型枚举
enum RefundType {
  full('FULL'),
  partial('PARTIAL'),
  chargeback('CHARGEBACK'),
  auto('AUTO');

  const RefundType(this.value);
  final String value;

  static RefundType fromValue(String value) {
    return RefundType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RefundType.full,
    );
  }
}

/// 退款方式枚举
enum RefundMethod {
  original('ORIGINAL'),
  voucher('VOUCHER'),
  balance('BALANCE'),
  manual('MANUAL');

  const RefundMethod(this.value);
  final String value;

  static RefundMethod fromValue(String value) {
    return RefundMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RefundMethod.original,
    );
  }
}

/// 订阅类型枚举
enum SubscriptionType {
  autoRenewable('AUTO_RENEWABLE'),
  nonRenewing('NON_RENEWING'),
  consumable('CONSUMABLE'),
  nonConsumable('NON_CONSUMABLE');

  const SubscriptionType(this.value);
  final String value;

  static SubscriptionType fromValue(String value) {
    return SubscriptionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubscriptionType.autoRenewable,
    );
  }
}

/// 订阅状态枚举
enum SubscriptionStatus {
  active('ACTIVE'),
  expired('EXPIRED'),
  cancelled('CANCELLED'),
  pending('PENDING');

  const SubscriptionStatus(this.value);
  final String value;

  static SubscriptionStatus fromValue(String value) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubscriptionStatus.pending,
    );
  }
}

/// 订单领域模型 - 存储无关的纯Dart类
///
/// 【设计目的】
/// - 解耦业务逻辑与存储实现（SQLite/Realm）
/// - 为UI层提供统一的数据模型
/// - 支持多存储后端无缝切换
class OrderData {
  final String orderNum;
  final String? srcOrderNum;
  final String userId;
  final int productId;
  final String? productName;
  final double originalTotal;
  final double discountTotal;
  final double total;
  final String currency;
  final String voucherId;
  final int? payProvider;
  final String orderType;
  final String? clientIp;
  final String? clientType;
  final int payStatus;
  final int status;
  final String? transactionId;
  final String? agentChannel;
  final int agentId;
  final String platform;
  final double refundTotal;
  final String? refundTransactionId;
  final String? refundOrderNum;
  final String? refundReason;
  final DateTime? refundAt;
  final String? refundType;
  final String? refundMethod;
  final String? refundApprover;
  final DateTime? refundApprovedAt;
  final String? storeReceiptData;
  final String? storeProductId;
  final String? storeTransactionId;
  final String? subscriptionType;
  final String? subscriptionStatus;
  final int? extra1;
  final int? extra2;
  final String? extra3;
  final String? extra4;
  final DateTime createAt;
  final DateTime updateAt;
  final DateTime? expireAt;
  final DateTime? payAt;
  final String? notifyUrl;
  final double qty;
  final String? acknowledgementState;
  final String? remark;
  final double price;
  final double tax;
  final double rate;
  final DateTime? cancelledAt;

  const OrderData({
    required this.orderNum,
    this.srcOrderNum,
    required this.userId,
    required this.productId,
    this.productName,
    required this.originalTotal,
    this.discountTotal = 0.0,
    required this.total,
    this.currency = 'USD',
    required this.voucherId,
    this.payProvider,
    required this.orderType,
    this.clientIp,
    this.clientType,
    this.payStatus = 0,
    this.status = 0,
    this.transactionId,
    this.agentChannel,
    required this.agentId,
    required this.platform,
    this.refundTotal = 0.0,
    this.refundTransactionId,
    this.refundOrderNum,
    this.refundReason,
    this.refundAt,
    this.refundType,
    this.refundMethod,
    this.refundApprover,
    this.refundApprovedAt,
    this.storeReceiptData,
    this.storeProductId,
    this.storeTransactionId,
    this.subscriptionType,
    this.subscriptionStatus,
    this.extra1,
    this.extra2,
    this.extra3,
    this.extra4,
    required this.createAt,
    required this.updateAt,
    this.expireAt,
    this.payAt,
    this.notifyUrl,
    this.qty = 1.0,
    this.acknowledgementState,
    this.remark,
    this.price = 0.0,
    this.tax = 0.0,
    this.rate = 0.0,
    this.cancelledAt,
  });

  /// 便捷方法：获取枚举类型
  OrderType get orderTypeEnum => OrderType.fromValue(orderType);
  PayStatus get payStatusEnum => PayStatus.fromValue(payStatus);
  OrderStatus get statusEnum => OrderStatus.fromValue(status);
  PaymentPlatform get platformEnum => PaymentPlatform.fromValue(platform);
  ClientType? get clientTypeEnum => clientType != null ? ClientType.fromValue(clientType!) : null;

  /// 便捷方法：状态判断
  bool get isPaid => payStatus == PayStatus.paid.value;
  bool get isCancelled => payStatus == PayStatus.cancelled.value;
  bool get isRefunded => payStatus == PayStatus.refunded.value || payStatus == PayStatus.partialRefunded.value;
  bool get isCompleted => status == OrderStatus.completed.value;
  bool get isExpired => status == OrderStatus.expired.value || (expireAt != null && expireAt!.isBefore(DateTime.now()));
}

/// Drift 订单表定义
@DataClassName('OrderEntry')
class OrderEntries extends Table {
  /// 订单编号(主键)
  TextColumn get orderNum => text()();

  /// 源订单编号(退货单关联原订单)
  TextColumn get srcOrderNum => text().withLength(max: 64).nullable()();

  /// 用户ID
  TextColumn get userId => text()();

  /// 产品ID
  IntColumn get productId => integer()();

  /// 产品名称
  TextColumn get productName => text().withLength(max: 100).nullable()();

  /// 产品原价金额
  RealColumn get originalTotal => real()();

  /// 优惠折扣金额
  RealColumn get discountTotal => real()();

  /// 实际支付金额(原价-优惠)
  RealColumn get total => real()();

  /// 货币类型(ISO 4217标准)
  TextColumn get currency => text().withLength(max: 10).withDefault(const Constant('USD'))();

  /// 卡密ID(关联VOUCHER表)
  TextColumn get voucherId => text()();

  /// 支付方式ID(关联PAYPROVIDER表)
  IntColumn get payProvider => integer().nullable()();

  /// 订单类型
  TextColumn get orderType => text().withDefault(const Constant('subscription'))();

  /// 客户端IP地址
  TextColumn get clientIp => text().withLength(max: 50).nullable()();

  /// 客户端类型
  TextColumn get clientType => text().nullable()();

  /// 支付状态
  IntColumn get payStatus => integer().withDefault(const Constant(0))();

  /// 订单状态
  IntColumn get status => integer().withDefault(const Constant(0))();

  /// 第三方支付平台交易号
  TextColumn get transactionId => text().withLength(max: 64).nullable()();

  /// 分销代理渠道
  TextColumn get agentChannel => text().withLength(max: 64).nullable()();

  /// 代理商ID
  IntColumn get agentId => integer()();

  /// 支付平台
  TextColumn get platform => text()();

  // 退款相关字段
  /// 退款金额
  RealColumn get refundTotal => real().withDefault(const Constant(0.0))();

  /// 第三方支付平台退款单号
  TextColumn get refundTransactionId => text().withLength(max: 64).nullable()();

  /// 第三方支付平台退款订单号
  TextColumn get refundOrderNum => text().nullable()();

  /// 退款原因说明
  TextColumn get refundReason => text().withLength(max: 255).nullable()();

  /// 退款处理时间
  DateTimeColumn get refundAt => dateTime().nullable()();

  /// 退款类型
  TextColumn get refundType => text().nullable()();

  /// 退款方式
  TextColumn get refundMethod => text().nullable()();

  /// 退款审批人ID
  TextColumn get refundApprover => text().nullable()();

  /// 退款审批时间
  DateTimeColumn get refundApprovedAt => dateTime().nullable()();

  // 应用商店特有字段
  /// 应用商店收据数据(Apple原始收据)
  TextColumn get storeReceiptData => text().nullable()();

  /// 应用商店产品ID(SKU)
  TextColumn get storeProductId => text().withLength(max: 100).nullable()();

  /// 应用商店内部交易ID
  TextColumn get storeTransactionId => text().withLength(max: 100).nullable()();

  /// 订阅类型
  TextColumn get subscriptionType => text().nullable()();

  /// 订阅状态
  TextColumn get subscriptionStatus => text().nullable()();

  // EXTRA扩展字段
  /// 扩展数值字段1：试用天数、订阅周期、退款优先级等
  IntColumn get extra1 => integer().nullable()();

  /// 扩展数值字段2：原始价格分、优惠力度、退款手续费等
  IntColumn get extra2 => integer().nullable()();

  /// 扩展文本字段3：应用商店环境、退款证据、营销标签等
  TextColumn get extra3 => text().nullable()();

  /// 扩展文本字段4：用户说明、退款备注、处理记录等
  TextColumn get extra4 => text().nullable()();

  /// 创建时间
  DateTimeColumn get createAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间
  DateTimeColumn get updateAt => dateTime().withDefault(currentDateAndTime)();

  /// 订单支付超时失效时间
  DateTimeColumn get expireAt => dateTime().nullable()();

  /// 支付完成时间
  DateTimeColumn get payAt => dateTime().nullable()();

  /// 支付结果异步通知回调地址
  TextColumn get notifyUrl => text().withLength(max: 255).nullable()();

  /// 订单数量
  RealColumn get qty => real().withDefault(const Constant(1.0))();

  /// 订单确认状态
  TextColumn get acknowledgementState => text().withLength(max: 250).nullable()();

  /// 订单备注信息
  TextColumn get remark => text().withLength(max: 500).nullable()();

  /// 单价 - 商品单价金额
  RealColumn get price => real().withDefault(const Constant(0.0))();

  /// 税额 - 订单税费金额
  RealColumn get tax => real().withDefault(const Constant(0.0))();

  /// 税率 - 订单税率(小数形式，如0.13表示13%)
  RealColumn get rate => real().withDefault(const Constant(0.0))();

  /// 订单取消时间
  DateTimeColumn get cancelledAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {orderNum};
}
