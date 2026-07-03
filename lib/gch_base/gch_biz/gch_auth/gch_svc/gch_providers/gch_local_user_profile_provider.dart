// providers/local_user_profile_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guichao/gch_base/gch_ink/gch_ink.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';

/// 本地用户配置文件提供者
class LocalUserProfile implements UserProfileProvider {
  static const String _userProfilePrefix = 'guichao_user_profile_';
  static const String _currentUserKey = 'guichao_current_user';
  static const String _userListKey = 'guichao_user_list';

  final FlutterSecureStorage _storage;
  final Map<String, AuthUser> _userCache = {};
  final _profileChangeController = StreamController<UserProfileEvent>.broadcast();

  /// 解析 expiredAt 字段，支持多种格式
  /// 服务端存储的是 UTC 时间，确保解析后统一为 UTC
  static DateTime _parseExpiredAt(dynamic value) {
    if (value == null) return DateTime.now().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      // 如果字符串不含时区信息，视为 UTC
      final hasTimezone = value.contains('Z') ||
          RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value);
      return DateTime.tryParse(hasTimezone ? value : '${value}Z')?.toUtc() ??
          DateTime.now().toUtc();
    }
    if (value is int) {
      // 支持秒或毫秒时间戳
      return value > 9999999999
          ? DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)
          : DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
    }
    return DateTime.now().toUtc();
  }

  LocalUserProfile({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<AuthUser?> getUserProfile(String userId) async {
    // 首先检查缓存
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final profileData = await _storage.read(key: '$_userProfilePrefix$userId');
      if (profileData != null) {
        final data = jsonDecode(profileData) as Map<String, dynamic>;
        final user = AuthUser.fromJson(data);
        _userCache[userId] = user;
        return user;
      }
    } catch (e) {
      GchInk.app.debug('Failed to load user profile: $e');
    }

    return null;
  }

  @override
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      AuthUser? currentUser = await getUserProfile(userId);

      if (currentUser == null) {
        // 如果用户不存在，创建新用户
        currentUser = AuthUser(
          userId: userId,
          code: (DateTime.now().millisecondsSinceEpoch % 1000000).toString(),
          email: updates['email']?.toString(),
          phone: updates['phone']?.toString(),
          name: updates['name']?.toString() ?? 'New User',
          nickname: updates['nickname']?.toString(),
          password: '',
          vipType: VipType.fromValue((updates['vipType'] as num?)?.toInt() ?? 0),
          country: updates['country']?.toString() ?? 'CN',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          expiredAt: _parseExpiredAt(updates['expiredAt'] ?? updates['expired_at']),
        );
      } else {
        // 更新现有用户
        currentUser = currentUser.copyWith(
          email: updates.containsKey('email') ? updates['email']?.toString() : currentUser.email,
          phone: updates.containsKey('phone') ? updates['phone']?.toString() : currentUser.phone,
          name: updates.containsKey('name') ? updates['name']?.toString() ?? currentUser.name : currentUser.name,
          nickname: updates.containsKey('nickname') ? updates['nickname']?.toString() : currentUser.nickname,
          vipType: updates.containsKey('vipType')
              ? VipType.fromValue((updates['vipType'] as num?)?.toInt() ?? currentUser.vipType.value)
              : currentUser.vipType,
          country: updates.containsKey('country') ? updates['country']?.toString() ?? currentUser.country : currentUser.country,
          updatedAt: DateTime.now(),
          expiredAt: (updates.containsKey('expiredAt') || updates.containsKey('expired_at'))
              ? _parseExpiredAt(updates['expiredAt'] ?? updates['expired_at'])
              : currentUser.expiredAt,
        );
      }

      return await _saveUserProfile(currentUser);
    } catch (e) {
      GchInk.app.debug('Failed to update user profile: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteUserProfile(String userId) async {
    try {
      // 从缓存中移除
      _userCache.remove(userId);

      // 从存储中删除
      await _storage.delete(key: '$_userProfilePrefix$userId');

      // 更新用户列表
      await _removeFromUserList(userId);

      // 如果删除的是当前用户，清除当前用户记录
      final currentUserId = await _storage.read(key: _currentUserKey);
      if (currentUserId == userId) {
        await _storage.delete(key: _currentUserKey);
      }

      _profileChangeController.add(UserProfileEvent(
        type: UserProfileEventType.deleted,
        userId: userId,
        timestamp: DateTime.now(),
      ));

      return true;
    } catch (e) {
      GchInk.app.debug('Failed to delete user profile: $e');
      return false;
    }
  }

  /// 保存用户配置文件
  Future<bool> _saveUserProfile(AuthUser user) async {
    try {
      final profileData = jsonEncode(user.toJson());
      await _storage.write(key: '$_userProfilePrefix${user.userId}', value: profileData);

      // 更新缓存
      _userCache[user.userId] = user;

      // 添加到用户列表
      await _addToUserList(user.userId);

      _profileChangeController.add(UserProfileEvent(
        type: UserProfileEventType.updated,
        userId: user.userId,
        user: user,
        timestamp: DateTime.now(),
      ));

      return true;
    } catch (e) {
      GchInk.app.debug('Failed to save user profile: $e');
      return false;
    }
  }

  /// 设置当前活跃用户
  Future<bool> setCurrentUser(String userId) async {
    try {
      final user = await getUserProfile(userId);
      if (user != null) {
        await _storage.write(key: _currentUserKey, value: userId);
        _profileChangeController.add(UserProfileEvent(
          type: UserProfileEventType.activated,
          userId: userId,
          user: user,
          timestamp: DateTime.now(),
        ));
        return true;
      }
      return false;
    } catch (e) {
      GchInk.app.debug('Failed to set current user: $e');
      return false;
    }
  }

  /// 获取当前活跃用户
  Future<AuthUser?> getCurrentUser() async {
    try {
      final currentUserId = await _storage.read(key: _currentUserKey);
      if (currentUserId != null) {
        return await getUserProfile(currentUserId);
      }
    } catch (e) {
      GchInk.app.debug('Failed to get current user: $e');
    }
    return null;
  }

  /// 获取当前活跃用户ID
  Future<String?> getCurrentUserId() async {
    return await _storage.read(key: _currentUserKey);
  }

  /// 清除当前用户
  Future<void> clearCurrentUser() async {
    await _storage.delete(key: _currentUserKey);
    _profileChangeController.add(UserProfileEvent(
      type: UserProfileEventType.deactivated,
      timestamp: DateTime.now(),
    ));
  }

  /// 获取所有用户ID列表
  Future<List<String>> getAllUserIds() async {
    try {
      final userListData = await _storage.read(key: _userListKey);
      if (userListData != null) {
        final userList = jsonDecode(userListData) as List<dynamic>;
        return userList.cast<String>();
      }
    } catch (e) {
      GchInk.app.debug('Failed to get user list: $e');
    }
    return [];
  }

  /// 获取所有用户配置文件
  Future<List<AuthUser>> getAllUsers() async {
    final userIds = await getAllUserIds();
    final users = <AuthUser>[];

    for (final userId in userIds) {
      final user = await getUserProfile(userId);
      if (user != null) {
        users.add(user);
      }
    }

    return users;
  }

  /// 添加用户到用户列表
  Future<void> _addToUserList(String userId) async {
    try {
      final userIds = await getAllUserIds();
      if (!userIds.contains(userId)) {
        userIds.add(userId);
        await _storage.write(key: _userListKey, value: jsonEncode(userIds));
      }
    } catch (e) {
      GchInk.app.debug('Failed to add to user list: $e');
    }
  }

  /// 从用户列表中移除用户
  Future<void> _removeFromUserList(String userId) async {
    try {
      final userIds = await getAllUserIds();
      userIds.remove(userId);
      await _storage.write(key: _userListKey, value: jsonEncode(userIds));
    } catch (e) {
      GchInk.app.debug('Failed to remove from user list: $e');
    }
  }

  /// 用户配置文件变化事件流
  Stream<UserProfileEvent> get profileChanges => _profileChangeController.stream;

  /// 清除所有用户数据
  Future<void> clearAllUsers() async {
    try {
      final userIds = await getAllUserIds();

      // 删除所有用户配置文件
      for (final userId in userIds) {
        await _storage.delete(key: '$_userProfilePrefix$userId');
      }

      // 清空缓存
      _userCache.clear();

      // 清除用户列表和当前用户
      await _storage.delete(key: _userListKey);
      await _storage.delete(key: _currentUserKey);

      _profileChangeController.add(UserProfileEvent(
        type: UserProfileEventType.allCleared,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      GchInk.app.debug('Failed to clear all users: $e');
    }
  }

  /// 检查用户是否存在
  Future<bool> userExists(String userId) async {
    final user = await getUserProfile(userId);
    return user != null;
  }

  /// 通过邮箱查找用户
  Future<AuthUser?> getUserByEmail(String email) async {
    final users = await getAllUsers();
    for (final user in users) {
      if (user.email == email) {
        return user;
      }
    }
    return null;
  }

  /// 通过手机号查找用户
  Future<AuthUser?> getUserByPhone(String phone) async {
    final users = await getAllUsers();
    for (final user in users) {
      if (user.phone == phone) {
        return user;
      }
    }
    return null;
  }

  /// 获取用户统计信息
  Future<UserStats> getUserStats() async {
    final users = await getAllUsers();
    final now = DateTime.now();

    int activeUsers = 0;
    int expiredUsers = 0;
    int vipUsers = 0;

    for (final user in users) {
      if (user.expiredAt.isAfter(now)) {
        activeUsers++;
      } else {
        expiredUsers++;
      }

      if (user.vipType != VipType.free) {
        vipUsers++;
      }
    }

    return UserStats(
      totalUsers: users.length,
      activeUsers: activeUsers,
      expiredUsers: expiredUsers,
      vipUsers: vipUsers,
    );
  }

  /// 销毁提供者，清理资源
  Future<void> dispose() async {
    _userCache.clear();
    await _profileChangeController.close();
  }
}

/// 用户配置文件事件类型
enum UserProfileEventType {
  created,
  updated,
  deleted,
  activated,
  deactivated,
  allCleared,
}

/// 用户配置文件事件
class UserProfileEvent {
  final UserProfileEventType type;
  final String? userId;
  final AuthUser? user;
  final DateTime timestamp;
  final String? reason;

  const UserProfileEvent({
    required this.type,
    this.userId,
    this.user,
    required this.timestamp,
    this.reason,
  });

  @override
  String toString() {
    return 'UserProfileEvent(type: $type, userId: $userId, timestamp: $timestamp, reason: $reason)';
  }
}

/// 用户统计信息
class UserStats {
  final int totalUsers;
  final int activeUsers;
  final int expiredUsers;
  final int vipUsers;

  const UserStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.expiredUsers,
    required this.vipUsers,
  });

  @override
  String toString() {
    return 'UserStats(total: $totalUsers, active: $activeUsers, expired: $expiredUsers, vip: $vipUsers)';
  }
}
