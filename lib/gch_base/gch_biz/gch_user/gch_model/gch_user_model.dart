import 'package:drift/drift.dart';


/// Drift 用户表定义
@DataClassName('UserEntry')
class UserEntries extends Table {
  /// 用户ID (UUID)
  TextColumn get userId => text().named('USERID')();

  /// 用户CODE
  TextColumn get code => text().withLength(max: 100).named('CODE')();

  /// 邮箱
  TextColumn get email => text().withLength(max: 100).nullable().named('EMAIL')();

  /// 手机
  TextColumn get phone => text().withLength(max: 20).nullable().named('PHONE')();

  /// 用户姓名
  TextColumn get name => text().withLength(max: 50).named('NAME')();

  /// 用户昵称
  TextColumn get nickname => text().withLength(max: 50).nullable().named('NICKNAME')();

  /// 角色
  TextColumn get role => text().withLength(max: 250).nullable().named('ROLE')();

  /// 审计
  TextColumn get aud => text().withLength(max: 250).nullable().named('AUD')();

  /// 用户密码（存储哈希）
  TextColumn get password => text().withLength(max: 255).named('PASSWORD')();

  /// 性别: 0-未知, 1-男, 2-女
  IntColumn get sex => integer().withDefault(const Constant(0)).named('SEX')();

  /// 生日
  DateTimeColumn get birthday => dateTime().nullable().named('BIRTHDAY')();

  /// 用户所属分组ID
  IntColumn get groupId => integer().withDefault(const Constant(0)).named('GROUPID')();

  /// 用户类型
  TextColumn get type => text().withDefault(const Constant('normal')).named('TYPE')();

  /// 最近一次登录IP
  TextColumn get lastLoginIp => text().withLength(max: 50).nullable().named('LASTLOGINIP')();

  /// 最近一次登录时间
  DateTimeColumn get lastLoginTime => dateTime().nullable().named('LASTLOGINTIME')();

  /// 注册设备类型
  TextColumn get deviceType => text().withDefault(const Constant('android')).named('DEVICETYPE')();

  /// 用户配置参数 (JSON)
  TextColumn get config => text().nullable().named('CONFIG')();

  /// 认证类型
  TextColumn get authType => text().nullable().named('AUTHTYPE')();

  /// 订阅地址
  TextColumn get subscriptionUrl => text().withLength(max: 255).nullable().named('SUBSCRIPTIONURL')();

  /// 流量来源
  TextColumn get utmSource => text().withLength(max: 255).nullable().named('UTMSOURCE')();

  /// 引荐来源
  TextColumn get utmRefer => text().withLength(max: 255).nullable().named('UTMREFER')();

  /// 引入内容
  TextColumn get utmContent => text().withLength(max: 255).nullable().named('UTMCONTENT')();

  /// 扩展参数1
  TextColumn get extra1 => text().withLength(max: 255).nullable().named('EXTRA1')();

  /// 扩展参数2
  TextColumn get extra2 => text().withLength(max: 255).nullable().named('EXTRA2')();

  /// 扩展参数3
  TextColumn get extra3 => text().nullable().named('EXTRA3')();

  /// 扩展参数4
  TextColumn get extra4 => text().nullable().named('EXTRA4')();

  /// 可选参数1
  IntColumn get optional1 => integer().withDefault(const Constant(0)).named('OPTIONAL1')();

  /// 可选参数2
  IntColumn get optional2 => integer().withDefault(const Constant(0)).named('OPTIONAL2')();

  /// 可选参数3 (DECIMAL(10,2))
  RealColumn get optional3 => real().withDefault(const Constant(0.0)).named('OPTIONAL3')();

  /// 可选参数4 (DECIMAL(10,2))
  RealColumn get optional4 => real().withDefault(const Constant(0.0)).named('OPTIONAL4')();

  /// 用户状态: 1-正常, 0-禁用, 2-锁定
  IntColumn get status => integer().withDefault(const Constant(1)).named('STATUS')();

  /// VIP类型: 0-非会员, 1-普通会员, 2-高级会员
  IntColumn get vipType => integer().withDefault(const Constant(0)).named('VIPTYPE')();

  /// 邀请码
  TextColumn get inviteCode => text().withLength(max: 50).nullable().named('INVITECODE')();

  /// 代理用户ID
  IntColumn get agentId => integer().withDefault(const Constant(0)).named('AGENTID')();

  /// 流量限制(MB)
  IntColumn get trafficLimit => integer().withDefault(const Constant(1000000)).named('TRAFFICLIMIT')();

  /// 带宽限制(Mbps)
  IntColumn get bandwidthLimit => integer().withDefault(const Constant(100)).named('BANDWIDTHLIMIT')();

  /// 元数据 (JSON)
  TextColumn get metadata => text().nullable().named('METADATA')();

  /// 用户国家（ISO 3166-1 alpha-2）
  TextColumn get country => text().withLength(max: 5).withDefault(const Constant('CN')).named('COUNTRY')();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('CREATEDAT')();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).named('UPDATEDAT')();

  /// 会员到期时间
  DateTimeColumn get expiredAt => dateTime().withDefault(currentDateAndTime).named('EXPIREDAT')();

  @override
  Set<Column> get primaryKey => {userId};

  @override
  List<Set<Column>> get uniqueKeys => [
        {email}, // 邮箱唯一
        {phone}, // 手机唯一
        {inviteCode}, // 邀请码唯一
      ];
}

