// Common user-related enums
// This file provides shared enum definitions used across the application
// to avoid duplication and type collision issues.

import 'package:json_annotation/json_annotation.dart';

/// 用户性别枚举
enum UserSex {
  /// 未知
  unknown(0),

  /// 男性
  male(1),

  /// 女性
  female(2);

  const UserSex(this.value);
  final int value;

  static UserSex fromValue(int value) {
    return UserSex.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserSex.unknown,
    );
  }
}

/// 用户状态枚举
enum UserStatus {
  /// 禁用
  disabled(0),

  /// 正常
  normal(1),

  /// 锁定
  locked(2);

  const UserStatus(this.value);
  final int value;

  static UserStatus fromValue(int value) {
    return UserStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserStatus.normal,
    );
  }
}

/// VIP类型枚举
enum VipType {
  /// 免费用户
  free(0),

  /// 标准会员
  basic(1),

  /// 高级会员
  premium(2);

  const VipType(this.value);
  final int value;

  static VipType fromValue(int value) {
    return VipType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VipType.free,
    );
  }

  /// 是否为付费会员
  bool get isPaid => this != VipType.free;

  /// 是否为高级会员
  bool get isPremium => this == VipType.premium;
}

/// JSON converters for custom types
class UserSexConverter implements JsonConverter<UserSex, int> {
  const UserSexConverter();

  @override
  UserSex fromJson(int json) => UserSex.fromValue(json);

  @override
  int toJson(UserSex object) => object.value;
}

class UserStatusConverter implements JsonConverter<UserStatus, int> {
  const UserStatusConverter();

  @override
  UserStatus fromJson(int json) => UserStatus.fromValue(json);

  @override
  int toJson(UserStatus object) => object.value;
}

class VipTypeConverter implements JsonConverter<VipType, int> {
  const VipTypeConverter();

  @override
  VipType fromJson(int json) => VipType.fromValue(json);

  @override
  int toJson(VipType object) => object.value;
}
