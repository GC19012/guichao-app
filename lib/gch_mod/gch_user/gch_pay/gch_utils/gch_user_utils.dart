import 'package:flutter/material.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';

/// 用户相关的工具类 - 处理业务逻辑
class UserUtils {
  /// 格式化用户显示名称
  static String formatUserDisplayName(AuthUser? user) {
    if (user == null) return '${GchText.userCenterGuichaoUser} 197377820';

    final userIdSuffix = user.userId.length > 9
        ? user.userId.substring(0, 9)
        : user.userId;

    return '${GchText.userCenterGuichao} $userIdSuffix';
  }

  /// 获取VIP类型显示文本
  /// VipType.free(0) = 免费用户, VipType.basic(1) = 标准会员, VipType.premium(2) = 高级会员
  static String getVipTypeDisplayText(VipType vipType) {
    switch (vipType) {
      case VipType.free:
        return GchText.userCenterFreeUser;
      case VipType.basic:
        return GchText.userCenterBasicMember;
      case VipType.premium:
        return GchText.userCenterPremiumMember;
    }
  }

  /// 获取VIP类型颜色
  static Color getVipTypeColor(VipType vipType) {
    switch (vipType) {
      case VipType.free:
        return Colors.grey;
      case VipType.basic:
        return const Color(0xFFFFD700); // 金色
      case VipType.premium:
        return const Color(0xFFFF6B6B); // 红色
    }
  }

  /// 格式化到期时间显示
  ///
  /// 返回人类可读的剩余时间文本，如 "3天到期"、"2小时到期"、"已过期"。
  /// 当 expiredAt <= now 时统一返回"已过期"。
  static String formatExpiredTime(DateTime expiredAt) {
    final now = DateTime.now();

    if (!expiredAt.isAfter(now)) {
      return GchText.userCenterExpired;
    }

    final difference = expiredAt.difference(now);
    if (difference.inDays > 0) {
      return '${difference.inDays}${GchText.userCenterDaysToExpire}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${GchText.userCenterHoursToExpire}';
    } else {
      final minutes = difference.inMinutes;
      return '${minutes < 1 ? 1 : minutes}${GchText.userCenterMinutesToExpire}';
    }
  }

  /// 格式化流量限制显示
  static String formatTrafficLimit(int trafficLimitMB) {
    if (trafficLimitMB >= 1024 * 1024) {
      final tb = (trafficLimitMB / (1024 * 1024)).toStringAsFixed(1);
      return '${tb}TB';
    } else if (trafficLimitMB >= 1024) {
      final gb = (trafficLimitMB / 1024).toStringAsFixed(1);
      return '${gb}GB';
    } else {
      return '${trafficLimitMB}MB';
    }
  }

  /// 格式化带宽限制显示
  static String formatBandwidthLimit(int bandwidthLimitMbps) {
    if (bandwidthLimitMbps >= 1000) {
      final gbps = (bandwidthLimitMbps / 1000).toStringAsFixed(1);
      return '${gbps}Gbps';
    } else {
      return '${bandwidthLimitMbps}Mbps';
    }
  }

  /// 检查用户是否为VIP（考虑本地过期状态）
  static bool isVipUser(AuthUser? user) {
    return user?.currentVip != VipType.free;
  }

  /// 检查用户是否为高级VIP（考虑本地过期状态）
  static bool isPremiumUser(AuthUser? user) {
    return user?.currentVip == VipType.premium;
  }

  /// 检查用户账户是否活跃
  static bool isUserActive(AuthUser? user) {
    if (user == null) return false;
    return user.status == UserStatus.normal && !user.isExpired;
  }

  /// 获取用户状态显示文本
  static String getUserStatusText(AuthUser? user) {
    if (user == null) return GchText.userCenterUnknownStatus;

    if (user.isExpired) return GchText.userCenterExpired;

    switch (user.status) {
      case UserStatus.normal:
        return GchText.userCenterStatusNormal;
      case UserStatus.disabled:
        return GchText.userCenterStatusDisabled;
      case UserStatus.locked:
        return GchText.userCenterStatusLocked;
    }
  }

  /// 获取用户状态颜色
  static Color getUserStatusColor(AuthUser? user) {
    if (user == null || user.isExpired) return Colors.red;

    switch (user.status) {
      case UserStatus.normal:
        return Colors.green;
      case UserStatus.disabled:
        return Colors.orange;
      case UserStatus.locked:
        return Colors.red;
    }
  }

  /// 格式化用户创建时间
  static String formatUserCreatedTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years${GchText.userCenterYearsAgoJoined}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months${GchText.userCenterMonthsAgoJoined}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}${GchText.userCenterDaysAgoJoined}';
    } else {
      return GchText.userCenterJoinedToday;
    }
  }

  /// 获取用户头像背景色
  static Color getUserAvatarColor(AuthUser? user) {
    if (user == null) return const Color(0xFF5B7FFF);

    // 根据用户ID生成一致的颜色
    final hash = user.userId.hashCode;
    final colors = [
      const Color(0xFF5B7FFF),
      const Color(0xFF7C3AED),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    return colors[hash.abs() % colors.length];
  }

  /// 隐藏敏感信息（如手机号、邮箱）
  static String maskSensitiveInfo(String? info) {
    if (info == null || info.isEmpty) return GchText.userCenterNotSet;

    if (info.contains('@')) {
      // 邮箱脱敏
      final parts = info.split('@');
      if (parts.length == 2) {
        final username = parts[0];
        final domain = parts[1];
        if (username.length > 2) {
          return '${username.substring(0, 2)}****@$domain';
        }
        return info; // 如果用户名太短就不脱敏
      }
    } else if (info.contains(' ')) {
      // 手机号脱敏 (如 +86 138****8888)
      return info;
    } else if (info.length > 6) {
      // 一般字符串脱敏
      return '${info.substring(0, 3)}****${info.substring(info.length - 3)}';
    }

    return info;
  }
}
