import 'package:drift/drift.dart';

/// 支付方式类型枚举
enum PayMethod {
  /// PC端支付
  pc(0),

  /// WAP支付
  wap(1),

  /// H5支付
  h5(2),

  /// 应用商店支付
  appStore(3);

  const PayMethod(this.value);
  final int value;

  static PayMethod fromValue(int value) {
    return PayMethod.values.firstWhere((e) => e.value == value);
  }
}

/// 支付类型枚举
enum PayType {
  /// 在线支付
  online(0),

  /// 卡密兑换
  cardKey(1),

  /// 应用内购买
  inAppPurchase(2);

  const PayType(this.value);
  final int value;

  static PayType fromValue(int value) {
    return PayType.values.firstWhere((e) => e.value == value);
  }
}

/// 环境标识枚举
enum Environment {
  /// 生产环境
  production('production'),

  /// 沙箱环境
  sandbox('sandbox');

  const Environment(this.value);
  final String value;

  static Environment fromValue(String value) {
    return Environment.values.firstWhere((e) => e.value == value);
  }
}

/// Drift 支付渠道表定义
@DataClassName('PayProviderEntry')
class PayProviderEntries extends Table {
  /// 主键ID
  IntColumn get id => integer().autoIncrement()();

  /// 支付代码（唯一）
  TextColumn get code => text().unique()();

  /// 支付名称
  TextColumn get name => text()();

  /// 支付方式类型
  IntColumn get method => integer().withDefault(const Constant(0))();

  /// 支付类型
  IntColumn get payType => integer().withDefault(const Constant(0))();

  /// 支付方式图标地址
  TextColumn get iconUrl => text().nullable()();

  /// 状态：0-无效, 1-有效
  IntColumn get status => integer().withDefault(const Constant(1))();

  /// 支付配置（JSON格式）
  TextColumn get config => text().nullable()();

  /// 支持的国家/地区，逗号分隔
  TextColumn get regions => text().nullable()();

  /// 环境标识
  TextColumn get environment => text().withDefault(const Constant('production'))();

  /// 支持的客户端类型
  TextColumn get clientTypes => text().nullable()();

  /// 扩展字段1（数值型）
  IntColumn get extra1 => integer().nullable()();

  /// 扩展字段2（数值型）
  IntColumn get extra2 => integer().nullable()();

  /// 扩展字段3（文本型）
  TextColumn get extra3 => text().nullable()();

  /// 扩展字段4（文本型）
  TextColumn get extra4 => text().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
