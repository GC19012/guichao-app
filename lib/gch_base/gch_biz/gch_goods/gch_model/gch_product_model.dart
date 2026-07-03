import 'package:drift/drift.dart';
/// 产品平台枚举
enum ProductPlatform {
  /// Android平台 (Google Play)
  android('google'),
  /// iOS平台 (Apple App Store)
  ios('apple'),
  /// Stripe平台
  stripe('stripe');


  const ProductPlatform(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case ProductPlatform.android:
        return 'Android';
      case ProductPlatform.ios:
        return 'iOS';
      case ProductPlatform.stripe:
        return 'Stripe';
    }
  }

  static ProductPlatform fromValue(String value) {
    return ProductPlatform.values.firstWhere((e) => e.value == value);
  }
}

/// 产品类型枚举
enum ProductType {
  /// 订阅类型
  subscription('subscription'),
  /// 消耗品
  consumable('consumable'),
  /// 非消耗品
  nonConsumable('non_consumable');

  const ProductType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case ProductType.subscription:
        return 'Subscription';
      case ProductType.consumable:
        return 'Consumable';
      case ProductType.nonConsumable:
        return 'Non-Consumable';
    }
  }

  static ProductType fromValue(String value) {
    return ProductType.values.firstWhere((e) => e.value == value);
  }
}


/// Drift 产品表定义
@DataClassName('ProductEntry')
class ProductEntries extends Table {
  /// 主键ID - 必须与服务端保持一致，不允许本地自动生成
  /// 注意：这个 ID 必须在插入时提供，来源于服务端
  IntColumn get id => integer()();

  @override
  Set<Column> get primaryKey => {id};

  /// 产品ID，对应store的product_id
  TextColumn get productId => text().unique()();

  /// 产品标题/名称
  TextColumn get title => text()();

  /// 产品描述
  TextColumn get description => text().nullable()();

  /// 价格
  RealColumn get price => real()();

  /// 格式化的价格字符串
  TextColumn get priceFormatted => text()();

  /// 货币代码
  TextColumn get currency =>  text()();

  /// 平台: 'android' | 'ios' | 'stripe'
  TextColumn get platform => text()();

  /// 产品类型: 'subscription' | 'consumable' | 'non_consumable'
  TextColumn get type => text()();

  /// 订阅时长(天)，仅订阅类型需要
  IntColumn get duration => integer().nullable()();

  /// 价格ID，用于标识特定价格配置
  TextColumn get priceId => text().withLength(min: 0, max: 200).nullable()();

  /// 标题2（副标题，服务端可配置）
  TextColumn get title2 => text().withLength(min: 0, max: 200).nullable()();

  /// 标题3
  TextColumn get title3 => text().withLength(min: 0, max: 200).nullable()();

  /// 描述2
  TextColumn get description2 => text().withLength(min: 0, max: 200).nullable()();

  /// 描述3
  TextColumn get description3 => text().withLength(min: 0, max: 200).nullable()();

  /// 促销信息1
  TextColumn get promoinfo1 => text().withLength(min: 0, max: 200).nullable()();

  /// 促销信息2
  TextColumn get promoinfo2 => text().withLength(min: 0, max: 200).nullable()();

  /// 是否在前端显示（服务端控制）
  BoolColumn get visible => boolean().withDefault(const Constant(true))();
}
