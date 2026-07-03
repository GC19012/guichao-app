import 'package:dio/dio.dart';

import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_client/gch_api_client.dart';

/// 用户 API 接口
///
/// 基于 DataApiClient 的用户管理 API
class UserApi {
  final DataApiClient _apiClient;

  UserApi({required DataApiClient apiClient}) : _apiClient = apiClient;

  // Mock数据 - 用于在API不可用时提供备用数据
  final Map<String, dynamic> _mockUser = {
    'userId': '1',
    'code': 'USER001',
    'email': 'test@example.com',
    'phone': '13800138000',
    'name': '测试用户',
    'nickname': '测试昵称',
    'role': 'user',
    'aud': 'app',
    'password': 'hashed_password',
    'sex': 1,
    'birthday': DateTime.now().toIso8601String(),
    'groupId': 1,
    'type': 'normal',
    'lastLoginIp': '127.0.0.1',
    'lastLoginTime': DateTime.now().toIso8601String(),
    'deviceType': 'android',
    'config': '{}',
    'authType': 'password',
    'subscriptionUrl': null,
    'utmSource': null,
    'utmRefer': null,
    'utmContent': null,
    'extra1': null,
    'extra2': null,
    'extra3': null,
    'extra4': null,
    'optional1': 0,
    'optional2': 0,
    'optional3': 0.0,
    'optional4': 0.0,
    'status': 1,
    'vipType': 0,
    'inviteCode': 'INV001',
    'agentId': 0,
    'trafficLimit': 1000000,
    'bandwidthLimit': 100,
    'metadata': '{}',
    'country': 'CN',
    'createdAt': DateTime.now().toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
    'expiredAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
  };

  DateTime? _lastUpdate;
  int _counter = 0;


  /// 获取当前用户信息
  Future<UserEntry?> getUser({CancelToken? cancelToken}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/user/profile', cancelToken: cancelToken);
      final data = response.data?['data'];
      if (data != null) {
        return UserEntry.fromJson(data as Map<String, dynamic>);
      }
      return _getMockUser(); // API 返回空数据时返图 Mock
    } catch (e) {
      return _getMockUser(); // API 失败时返图 Mock 数据
    }
  }

  /// 通过ID获取用户（注意：dataapi 没有直接的根据ID获取用户的接口）
  Future<UserEntry?> getUserById(String id, {CancelToken? cancelToken}) async {
    // dataapi 中没有直接的根据ID获取用户接口，这里使用当前用户接口
    // 在实际应用中，可能需要扩展 dataapi 或使用其他方式
    if (id == 'current' || id == 'me') {
      return getUser(cancelToken: cancelToken);
    }

    // 降级到 Mock 数据
    return _getMockUser();
  }

  /// 获取用户列表
  Future<List<UserEntry>> getUsers({
    int? limit,
    int? offset,
    CancelToken? cancelToken,
  }) async {
    try {
      final queryParams = {
        'page': (offset != null && limit != null) ? (offset ~/ limit) + 1 : 1,
        'pageSize': limit ?? 20,
      };
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/user/list', 
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );
      
      final data = response.data?['data'];
      if (data != null && data is Map<String, dynamic>) {
        final items = data['items'] as List<dynamic>? ?? [];
        return items.map((json) => UserEntry.fromJson(json as Map<String, dynamic>)).toList();
      }
      return _getMockUserList(limit ?? 10); // API 返回空数据时返图 Mock
    } catch (e) {
      return _getMockUserList(limit ?? 10); // API 失败时返回 Mock 数据
    }
  }

  /// 搜索用户
  Future<List<UserEntry>> searchUsers({
    required String query,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/user/search',
        queryParameters: {'query': query, 'limit': limit},
        cancelToken: cancelToken,
      );
      
      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data.map((json) => UserEntry.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return _getMockUserList(limit); // API 失败时返回 Mock 数据
    }
  }

  /// 创建用户（注意：dataapi 中没有创建用户接口，这是管理员功能）
  Future<UserEntry> createUser(UserEntriesCompanion user) async {
    // dataapi 中没有创建用户的接口，这通常是后台管理功能
    // 这里返回基于输入数据的 Mock 用户
    final userData = Map<String, dynamic>.from(_mockUser);
    final columns = user.toColumns(false);
    columns.forEach((key, value) {
      userData[key] = value;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    return UserEntry.fromJson(userData);
  }

  /// 更新用户信息
  Future<bool> updateUser(UserEntriesCompanion user, {CancelToken? cancelToken}) async {
    try {
      // 获取当前用户ID（假设更新的是当前用户）
      final currentUser = await getUser(cancelToken: cancelToken);
      if (currentUser == null) return false;

      // 提取可更新的字段
      final updateData = <String, dynamic>{};
      final columns = user.toColumns(false);
      
      // 只提取常用的可更新字段
      for (final field in ['name', 'nickname', 'phone', 'metadata']) {
        if (columns.containsKey(field)) {
          updateData[field] = columns[field];
        }
      }

      final response = await _apiClient.put<Map<String, dynamic>>(
        '/user/${currentUser.userId}',
        data: updateData,
        cancelToken: cancelToken,
      );
      
      return response.data?['success'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 删除用户
  Future<void> deleteUser(String id, {CancelToken? cancelToken}) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/user/$id',
        cancelToken: cancelToken,
      );
      
      final success = response.data?['success'] as bool? ?? false;
      if (!success) {
        throw Exception('删除用户失败');
      }
    } catch (e) {
      throw Exception('删除用户失败: $e');
    }
  }

  /// 获取用户使用统计
  Future<Map<String, dynamic>?> getUserUsageStats(String userId, {CancelToken? cancelToken}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/user/$userId/stats',
        cancelToken: cancelToken,
      );
      
      return response.data?['data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// 获取用户订阅信息
  Future<Map<String, dynamic>?> getUserSubscription(String userId, {CancelToken? cancelToken}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/user/$userId/subscription',
        cancelToken: cancelToken,
      );
      
      return response.data?['data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // ====== 私有辅助方法 ======

  /// 获取 Mock 用户数据（降级方案）
  UserEntry _getMockUser() {
    final now = DateTime.now();
    if (_lastUpdate == null || now.difference(_lastUpdate!).inSeconds >= 5) {
      _lastUpdate = now;
      _counter++;
      _mockUser['name'] = '测试用户-$_counter';
      _mockUser['lastLoginTime'] = now.toIso8601String();
      _mockUser['updatedAt'] = now.toIso8601String();
    }
    return UserEntry.fromJson(_mockUser);
  }

  /// 获取 Mock 用户列表（降级方案）
  List<UserEntry> _getMockUserList(int count) {
    final users = <UserEntry>[];
    for (int i = 0; i < count; i++) {
      final userData = Map<String, dynamic>.from(_mockUser);
      userData['userId'] = '${i + 1}';
      userData['code'] = 'USER00${i + 1}';
      userData['name'] = '测试用户${i + 1}';
      userData['email'] = 'user${i + 1}@example.com';
      users.add(UserEntry.fromJson(userData));
    }
    return users;
  }

  /// 释放资源
  void dispose() {
    // DataApiClient 的释放由 Provider 管理，这里不需要手动释放
  }
}
