// authuser_model.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';

part 'gch_authuser_model.freezed.dart';
part 'gch_authuser_model.g.dart';

/// AuthUser model class that maps to the "user" table in the database
@freezed
abstract class AuthUser with _$AuthUser {
  const AuthUser._();

  /// 用户类的主构造函数
  @Assert('country.length <= 5', 'Country code must be 5 characters or less')
  const factory AuthUser({
    /// 用户ID (UUID)
    required String userId,

    /// 用户CODE
    required String code,

    /// 邮箱
    String? email,

    /// 手机
    String? phone,

    /// 用户姓名
    required String name,

    /// 用户昵称
    String? nickname,

    /// 角色
    String? role,

    /// 审计
    String? aud,

    /// 用户密码（存储哈希）
    required String password,

    /// 性别: 0-未知, 1-男, 2-女
    @Default(UserSex.unknown) @UserSexConverter() UserSex sex,

    /// 生日
    DateTime? birthday,

    /// 用户所属分组ID
    @Default(0) int groupId,

    /// 用户类型
    @Default('normal') String type,

    /// 最近一次登录IP
    String? lastLoginIp,

    /// 最近一次登录时间
    DateTime? lastLoginTime,

    /// 注册设备类型
    @Default('android') String deviceType,

    /// 用户配置参数 (JSON)
    Map<String, dynamic>? config,

    /// 认证类型
    String? authType,

    /// 订阅地址
    String? subscriptionUrl,

    /// 流量来源
    String? utmSource,

    /// 引荐来源
    String? utmRefer,

    /// 引入内容
    String? utmContent,

    /// 扩展参数1
    String? extra1,

    /// 扩展参数2
    String? extra2,

    /// 扩展参数3
    String? extra3,

    /// 扩展参数4
    String? extra4,

    /// 可选参数1
    @Default(0) int optional1,

    /// 可选参数2
    @Default(0) int optional2,

    /// 可选参数3 (DECIMAL(10,2))
    @Default(0.0) double optional3,

    /// 可选参数4 (DECIMAL(10,2))
    @Default(0.0) double optional4,

    /// 用户状态: 1-正常, 0-禁用, 2-锁定
    @Default(UserStatus.normal) @UserStatusConverter() UserStatus status,

    /// VIP类型: 0-非会员, 1-普通会员, 2-高级会员
    @Default(VipType.free) @VipTypeConverter() VipType vipType,

    /// 邀请码
    String? inviteCode,

    /// 代理用户ID
    @Default(0) int agentId,

    /// 流量限制(MB)
    @Default(1000000) int trafficLimit,

    /// 带宽限制(Mbps)
    @Default(100) int bandwidthLimit,

    /// 元数据 (JSON)
    Map<String, dynamic>? metadata,

    /// 用户国家（ISO 3166-1 alpha-2）
    @Default('CN') String country,

    /// 创建时间
    required DateTime createdAt,

    /// 更新时间
    required DateTime updatedAt,

    /// 会员到期时间
    required DateTime expiredAt,
  }) = _AuthUser;

  /// 从JSON创建用户对象
  factory AuthUser.fromJson(Map<String, dynamic> json) => _$AuthUserFromJson(json);

  /// 处理数据库字段名与模型字段名之间的差异
  factory AuthUser.fromDbMap(Map<String, dynamic> map) {
    // 创建一个新的map，将数据库字段名转换为模型字段名
    final normalizedMap = {
      'userId': map['USERID'],
      'code': map['CODE'],
      'email': map['EMAIL'],
      'phone': map['PHONE'],
      'name': map['NAME'],
      'nickname': map['NICKNAME'],
      'role': map['ROLE'],
      'aud': map['AUD'],
      'password': map['PASSWORD'],
      'sex': map['SEX'] ?? 0,
      'birthday': map['BIRTHDAY'] != null ? DateTime.parse(map['BIRTHDAY'] as String) : null,
      'groupId': map['GROUPID'] ?? 0,
      'type': map['TYPE'] ?? 'normal',
      'lastLoginIp': map['LASTLOGINIP'],
      'lastLoginTime': map['LASTLOGINTIME'] != null ? DateTime.parse(map['LASTLOGINTIME'] as String) : null,
      'deviceType': map['DEVICETYPE'] ?? 'android',
      'config': map['CONFIG'] != null ? (map['CONFIG'] is String ? jsonDecode(map['CONFIG'] as String) : map['CONFIG']) : null,
      'authType': map['AUTHTYPE'],
      'subscriptionUrl': map['SUBSCRIPTIONURL'],
      'utmSource': map['UTMSOURCE'],
      'utmRefer': map['UTMREFER'],
      'utmContent': map['UTMCONTENT'],
      'extra1': map['EXTRA1'],
      'extra2': map['EXTRA2'],
      'extra3': map['EXTRA3'],
      'extra4': map['EXTRA4'],
      'optional1': map['OPTIONAL1'] ?? 0,
      'optional2': map['OPTIONAL2'] ?? 0,
      'optional3': (map['OPTIONAL3'] ?? 0.0).toDouble(),
      'optional4': (map['OPTIONAL4'] ?? 0.0).toDouble(),
      'status': map['STATUS'] ?? 1,
      'vipType': map['VIPTYPE'] ?? 0,
      'inviteCode': map['INVITECODE'],
      'agentId': map['AGENTID'] ?? 0,
      'trafficLimit': map['TRAFFICLIMIT'] ?? 1000000,
      'bandwidthLimit': map['BANDWIDTHLIMIT'] ?? 100,
      'metadata': map['METADATA'] != null ? (map['METADATA'] is String ? jsonDecode(map['METADATA'] as String) : map['METADATA']) : null,
      'country': map['COUNTRY'] ?? 'CN',
      'createdAt': map['CREATEDAT'] != null ? (map['CREATEDAT'] is String ? DateTime.parse(map['CREATEDAT'] as String) : (map['CREATEDAT'] as DateTime)).toIso8601String() : DateTime.now().toIso8601String(),
      'updatedAt': map['UPDATEDAT'] != null ? (map['UPDATEDAT'] is String ? DateTime.parse(map['UPDATEDAT'] as String) : (map['UPDATEDAT'] as DateTime)).toIso8601String() : DateTime.now().toIso8601String(),
      'expiredAt': map['EXPIREDAT'] != null ? (map['EXPIREDAT'] is String ? DateTime.parse(map['EXPIREDAT'] as String) : (map['EXPIREDAT'] as DateTime)).toIso8601String() : DateTime.now().toIso8601String(),
    };

    return AuthUser.fromJson(normalizedMap);
  }

  /// 转换为数据库Map (用于数据库操作)
  Map<String, dynamic> toDbMap() {
    final json = toJson();

    return {
      'USERID': json['userId'],
      'CODE': json['code'],
      'EMAIL': json['email'],
      'PHONE': json['phone'],
      'NAME': json['name'],
      'NICKNAME': json['nickname'],
      'ROLE': json['role'],
      'AUD': json['aud'],
      'PASSWORD': json['password'],
      'SEX': json['sex'],
      'BIRTHDAY': json['birthday'],
      'GROUPID': json['groupId'],
      'TYPE': json['type'],
      'LASTLOGINIP': json['lastLoginIp'],
      'LASTLOGINTIME': json['lastLoginTime'],
      'DEVICETYPE': json['deviceType'],
      'CONFIG': json['config'] != null ? jsonEncode(json['config']) : null,
      'AUTHTYPE': json['authType'],
      'SUBSCRIPTIONURL': json['subscriptionUrl'],
      'UTMSOURCE': json['utmSource'],
      'UTMREFER': json['utmRefer'],
      'UTMCONTENT': json['utmContent'],
      'EXTRA1': json['extra1'],
      'EXTRA2': json['extra2'],
      'EXTRA3': json['extra3'],
      'EXTRA4': json['extra4'],
      'OPTIONAL1': json['optional1'],
      'OPTIONAL2': json['optional2'],
      'OPTIONAL3': json['optional3'],
      'OPTIONAL4': json['optional4'],
      'STATUS': json['status'],
      'VIPTYPE': json['vipType'],
      'INVITECODE': json['inviteCode'],
      'AGENTID': json['agentId'],
      'TRAFFICLIMIT': json['trafficLimit'],
      'BANDWIDTHLIMIT': json['bandwidthLimit'],
      'METADATA': json['metadata'] != null ? jsonEncode(json['metadata']) : null,
      'COUNTRY': json['country'],
      'CREATEDAT': json['createdAt'],
      'UPDATEDAT': json['updatedAt'],
      'EXPIREDAT': json['expiredAt'],
    };
  }

  /// 创建不包含敏感数据的公开用户对象
  AuthUser toPublicUser() {
    return copyWith(password: '********');
  }

  /// 检查用户账户是否已过期
  bool get isExpired => DateTime.now().isAfter(expiredAt);

  /// 检查用户账户是否活跃
  bool get isActive => status == UserStatus.normal && !isExpired;

  /// 当前有效的VIP类型（考虑本地过期状态）
  ///
  /// 安全策略：如果本地 expiredAt 已过期，强制返回 free
  /// 确保即使服务端不可用，过期用户也无法享受会员权益
  ///
  /// 调试专用：kDebugMode 下强制返回最高等级会员，方便模拟器本地联调；
  /// kDebugMode 在 release 构建中恒为 false 且会被编译期裁剪，不影响生产逻辑。
  VipType get currentVip =>
      kDebugMode ? VipType.premium : (isExpired ? VipType.free : vipType);

  /// 使用指定时间判断 VIP 有效性（防时钟回拨专用）。
  ///
  /// 调用方应传入 AuthTimeService.estimatedNow 而非 DateTime.now()，
  /// 以防止用户回拨设备时钟绕过过期检查。
  VipType currentVipAt(DateTime now) => kDebugMode
      ? VipType.premium
      : (now.isAfter(expiredAt) ? VipType.free : vipType);
}
