// providers/supabase_session_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_base_session_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';
/// Supabase会话提供者
class SupabaseSessionProvider extends BaseSessionProvider {
  final SupabaseClient _client;
  final FlutterSecureStorage _storage;
  late final StreamSubscription _authSubscription;

  // 内部缓存
  AuthSession? _session;
  DateTime? _lastSyncTime;
  String? _lastSyncSignature;
  static const Duration _minSyncInterval = Duration(seconds: 1);

  SupabaseSessionProvider(this._client) : _storage = const FlutterSecureStorage() {

    // 延迟初始化，避免阻塞构造函数
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSessionListener();
    });
  }

  /// 安全访问 Supabase Auth 实例
  GoTrueClient? get _auth {
    try {
      return _client.auth;
    } catch (e) {
      loggy.error('访问 Supabase Auth 失败', e);
      return null;
    }
  }

  /// 初始化会话监听
  void _initializeSessionListener() {
    loggy.info('初始化 Supabase 会话监听');

    final auth = _auth;
    if (auth == null) {
      loggy.error('无法获取 Supabase Auth 实例');
      handleError('Failed to initialize Supabase auth');
      return;
    }

    // 监听原生 Supabase 认证状态变化
    _authSubscription = auth.onAuthStateChange.listen(
      (AuthState authState) {
        _handleSupabaseAuthStateChange(authState);
      },
      onError: (error, stackTrace) {
        loggy.error('Supabase 认证状态监听出错', error, stackTrace as StackTrace?);
        handleError('Auth state change error: $error');
      },
    );

    // 检查初始状态
    _checkInitialState();
  }

  /// 检查初始认证状态
  void _checkInitialState() {
    final auth = _auth;
    if (auth == null) {
      loggy.warning('无法访问认证实例，跳过初始状态检查');
      handleSignOut();
      return;
    }

    try {
      final session = auth.currentSession;
      final user = auth.currentUser;

      if (session != null && user != null) {
        try {
          loggy.info('检测到已存在的会话，用户: ${user.email}');
          final authUser = _convertSupabaseUser(user);
          final authSession = _convertSupabaseSession(session);
          _sync(authSession, authUser); // 使用统一同步
        } catch (e) {
          loggy.error('初始状态检查失败，转换会话出错', e);
          _sync(null, null); // 使用统一同步
          _clearSession();
        }
      } else {
        loggy.info('无活跃会话');
        _sync(null, null); // 使用统一同步
      }
    } catch (e) {
      loggy.error('检查初始状态时发生异常', e);
      _sync(null, null); // 使用统一同步
    }
  }

  /// 处理 Supabase 原生认证状态变化
  void _handleSupabaseAuthStateChange(AuthState authState) {
    final event = authState.event;
    final session = authState.session;
    final user = session?.user;

    loggy.info('接收到 Supabase 认证状态变化: $event');

    switch (event) {
      case AuthChangeEvent.signedIn:
        if (session != null && user != null) {
          try {
            final authUser = _convertSupabaseUser(user);
            final authSession = _convertSupabaseSession(session);
            if (_sync(authSession, authUser)) {
              emitEvent(AuthEvent.signedIn(authUser, authSession));

            }
            _saveSession(authSession);
          } catch (e) {
            loggy.error('处理登录状态变化失败', e);
            _sync(null, null);
            _clearSession();
          }
        }
        break;

      case AuthChangeEvent.signedOut:
        if (_sync(null, null)) {
          emitEvent(AuthEvent.signedOut());
        }
        _clearSession();
        break;

      case AuthChangeEvent.tokenRefreshed:
        if (session != null && user != null) {
          try {
            final authSession = _convertSupabaseSession(session);
            final authUser = _convertSupabaseUser(user);
            if (_sync(authSession, authUser)) {
              emitEvent(AuthEvent.tokenRefreshed(authSession));
            }
            _saveSession(authSession);
            //loggy.info('Token刷新成功，用户VIP类型: ${authUser.vipType}');
          } catch (e) {
            loggy.error('处理令牌刷新失败', e);
          }
        }
        break;

      case AuthChangeEvent.userUpdated:
        if (user != null) {
          final authUser = _convertSupabaseUser(user);
          if (_sync(_session, authUser)) {
            emitEvent(AuthEvent.userUpdated(authUser));
          }
        }
        break;

      case AuthChangeEvent.passwordRecovery:
        if (user?.email != null) {
          emitEvent(AuthEvent.passwordRecovery(user!.email!));
        }
        break;

      case AuthChangeEvent.initialSession:
        // 处理初始会话状态
        if (session != null && user != null) {
          try {
            //loggy.info('处理初始会话: ${user.email}');
            final authUser = _convertSupabaseUser(user);
            final authSession = _convertSupabaseSession(session);
            _sync(authSession, authUser); // 同步初始会话
            _saveSession(authSession);
          } catch (e) {
            loggy.error('处理初始会话失败', e);
            _sync(null, null);
            _clearSession();
          }
        } else {
          loggy.info('初始会话为空，设置为未认证状态');
          _sync(null, null);
        }
        break;

      default:
        loggy.warning('未处理的认证事件: $event');
    }
  }

  /// 转换 Supabase User 为 AuthUser
  AuthUser _convertSupabaseUser(User user) {
    final data = user.userMetadata ?? {};
    final appMetadata = user.appMetadata;

    // 提取 authType：优先从 user_metadata，其次从 app_metadata.provider
    final authType = data['auth_type']?.toString() ??
        data['authType']?.toString() ??
        appMetadata['provider']?.toString();

    loggy.debug('_convertSupabaseUser - user_metadata: $data');
    loggy.debug('_convertSupabaseUser - app_metadata: $appMetadata');
    loggy.debug('_convertSupabaseUser - authType: $authType, name: ${data['name']}, nickname: ${data['nickname']}');

    return AuthUser(
      userId: user.id,
      code: data['code']?.toString() ??
          (DateTime.now().millisecondsSinceEpoch % 1000000).toString(),
      email: user.email,
      phone: user.phone,
      name: data['name']?.toString() ?? 'New User',
      nickname: data['nickname']?.toString(),
      password: '',
      vipType: VipType.fromValue(_parseInt(data['viptype'] ?? data['vip_type'])),
      country: data['country']?.toString() ?? 'CN',
      createdAt: DateTime.parse(user.createdAt),
      updatedAt: user.updatedAt != null ? DateTime.parse(user.updatedAt!) : DateTime.now(),
      expiredAt: _parseExpiredAt(data['expiredat'] ?? data['expired_at']),
      authType: authType,
    );
  }

  /// 解析过期时间字段
  /// 服务端存储的是 UTC 时间，确保解析后统一为 UTC
  DateTime _parseExpiredAt(dynamic value) {
    if (value == null) return DateTime.now().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      try {
        // 如果字符串不含时区信息，视为 UTC
        final hasTimezone = value.contains('Z') ||
            RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value);
        final parsed = DateTime.parse(hasTimezone ? value : '${value}Z');
        return parsed.toUtc();
      } catch (_) {
        return DateTime.now().toUtc();
      }
    }
    if (value is int) {
      // Unix timestamp (seconds or milliseconds)
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
      }
    }
    return DateTime.now().toUtc();
  }

  /// 安全解析 int
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// 转换 Supabase Session 为 AuthSession
  AuthSession _convertSupabaseSession(Session session) {
    final user = session.user;
    final accessToken = session.accessToken;
    if (accessToken.isEmpty) {
      throw StateError('Supabase session access token is empty');
    }

    // 根据 expiresIn 计算 expiresAt
    // expiresIn 是秒数，需要基于当前时间计算过期时间
    final expiresAt = session.expiresIn != null
        ? DateTime.now().add(Duration(seconds: session.expiresIn!))
        : DateTime.now().add(const Duration(hours: 1)); // 默认1小时

    return AuthSession(
      userId: user.id,
      token: accessToken,
      refreshToken: session.refreshToken,
      expiresAt: expiresAt,
      metadata: {
        'provider': 'supabase',
        'tokenType': session.tokenType,
        'user': user.toJson(),
        'expiresIn': session.expiresIn,
      },
    );
  }

  @override
  Future<AuthUser?> getUser({String? accessToken}) async {
    final auth = _auth;
    if (auth == null) {
      loggy.warning('无法访问认证实例，无法获取用户信息');
      return null;
    }

    try {
      //loggy.debug('SupabaseSessionProvider.getUser - 请求 GoTrue getUser');
      final response = await auth.getUser(accessToken);
      final supabaseUser = response.user;
      if (supabaseUser == null) {
        loggy.warning('Supabase 返回的用户信息为空');
        return null;
      }

      final authUser = _convertSupabaseUser(supabaseUser);

      AuthSession? session = _session;
      if (session == null) {
        final supabaseSession = auth.currentSession;
        if (supabaseSession != null) {
          try {
            session = _convertSupabaseSession(supabaseSession);
          } catch (e) {
            loggy.error('转换当前会话失败', e);
          }
        }
      }

      if (session != null) {
        //loggy.debug('SupabaseSessionProvider.getUser - 同步会话与用户信息');
        _sync(session, authUser);
      } else {
        //loggy.debug('SupabaseSessionProvider.getUser - 无 session，仅更新用户信息');
        handleUserUpdate(authUser);
      }

      return authUser;
    } catch (e) {
      loggy.error('调用 Supabase getUser 失败', e);
      handleError('Failed to get user: $e');
      return null;
    }
  }

  @override
  Future<AuthSession?> getCurrentSession() async {
    // 优先返回有效缓存
    if (_session?.isValid == true) {
      return _session;
    }

    final auth = _auth;
    if (auth == null) {
      loggy.warning('无法访问认证实例');
      // 尝试从本地存储恢复
      final session = await _loadSession();
      if (session != null) {
        _sync(session, null); // 同步到缓存
      }
      return _session;
    }

    try {
      final session = auth.currentSession;
      if (session != null) {
        try {
          final authSession = _convertSupabaseSession(session);
          final authUser = _convertSupabaseUser(session.user);
          _sync(authSession, authUser); // 统一同步
          return _session;
        } catch (e) {
          loggy.error('转换 Supabase Session 失败', e);
          await _clearSession();
          _sync(null, null);
          return null;
        }
      }
    } catch (e) {
      loggy.error('获取当前会话时发生异常', e);
    }

    // 尝试从本地存储恢复
    final session = await _loadSession();
    if (session != null) {
      _sync(session, null); // 同步到缓存
    }
    return _session;
  }

  @override
  Future<bool> refreshSession() async {
    final auth = _auth;
    if (auth == null) {
      loggy.error('无法访问认证实例，刷新失败');
      return false;
    }

    try {
      final response = await auth.refreshSession();
      return response.session != null;
    } catch (e) {
      loggy.error('刷新会话失败', e);
      handleError('Failed to refresh session: $e');
      return false;
    }
  }

  @override
  Future<void> clearSession() async {
    final auth = _auth;
    if (auth != null) {
      try {
        await auth.signOut();
      } catch (e) {
        loggy.error('Supabase 登出失败', e);
      }
    }
    await _clearSession();
  }

  @override
  Stream<AuthSession?> get sessionStream {
    final auth = _auth;
    if (auth == null) {
      loggy.error('无法访问认证实例，返回空流');
      return Stream.value(null);
    }

    return auth.onAuthStateChange.map((authState) {
      final session = authState.session;
      if (session != null) {
        try {
          return _convertSupabaseSession(session);
        } catch (e) {
          loggy.error('Stream 中转换会话失败', e);
          return null;
        }
      }
      return null;
    }).handleError((error) {
      loggy.error('会话流发生错误', error);
    });
  }

  /// 保存会话到本地存储
  Future<void> _saveSession(AuthSession session) async {
    try {
      final sessionJson = {
        'userId': session.userId,
        'token': session.token,
        'refreshToken': session.refreshToken,
        'expiresAt': session.expiresAt.toIso8601String(),
        'metadata': session.metadata,
      };

      await _storage.write(
        key: 'supabase_session',
        value: sessionJson.toString(),
      );
    } catch (e) {
      loggy.error('保存会话失败', e);
    }
  }

  /// 从本地存储加载会话
  Future<AuthSession?> _loadSession() async {
    try {
      final sessionStr = await _storage.read(key: 'supabase_session');
      if (sessionStr != null) {
        // 解析存储的会话数据
        final sessionData = jsonDecode(sessionStr) as Map<String, dynamic>;

        // 验证必要字段
        final userId = sessionData['userId'] as String?;
        final token = sessionData['token'] as String?;
        final expiresAtStr = sessionData['expiresAt'] as String?;
        final metadata = sessionData['metadata'] as Map<String, dynamic>?;

        if (userId == null || token == null || expiresAtStr == null) {
          loggy.warning('存储的会话数据不完整，清除无效数据');
          await _clearSession();
          return null;
        }

        // 解析过期时间
        final expiresAt = DateTime.parse(expiresAtStr);

        // 验证会话是否过期
        if (expiresAt.isBefore(DateTime.now())) {
          loggy.info('存储的会话已过期，清除无效数据');
          await _clearSession();
          return null;
        }

        // 验证令牌是否还有效（可选：可以添加额外的令牌验证逻辑）
        if (token.isEmpty) {
          loggy.warning('存储的令牌为空，清除无效数据');
          await _clearSession();
          return null;
        }

        // 构造 AuthSession
        return AuthSession(
          userId: userId,
          token: token,
          refreshToken: sessionData['refreshToken'] as String?,
          expiresAt: expiresAt,
          metadata: metadata ?? {},
        );
      }
    } catch (e) {
      loggy.error('加载会话失败，清除损坏的数据', e);
      // 如果解析失败，清除可能损坏的数据
      await _clearSession();
    }
    return null;
  }

  /// 清除本地存储的会话
  Future<void> _clearSession() async {
    try {
      await _storage.delete(key: 'supabase_session');
    } catch (e) {
      loggy.error('清除会话失败', e);
    }
  }

  String _buildSyncSignature(AuthSession? session, AuthUser? user) {
    final sessionStamp = session == null
        ? 'nosession'
        : '${session.userId}:${session.expiresAt.microsecondsSinceEpoch}:${session.token.hashCode}';
    final userStamp = user == null
        ? 'nouser'
        : '${user.userId}:${user.updatedAt.microsecondsSinceEpoch}:${user.vipType.value}:${user.expiredAt.microsecondsSinceEpoch}';
    return '$sessionStamp|$userStamp';
  }

  /// 统一同步方法 - 确保缓存与状态一致
  /// 返回 true 表示执行了同步，false 表示被节流跳过
  bool _sync(AuthSession? session, AuthUser? user) {
    final signature = _buildSyncSignature(session, user);
    if (_lastSyncSignature == signature) {
      final withinWindow = _lastSyncTime != null &&
          DateTime.now().difference(_lastSyncTime!) < _minSyncInterval;
      if (withinWindow) {
        loggy.debug('跳过重复同步（节流窗口内）');
      } else {
        loggy.debug('跳过重复同步（状态未变化）');
      }
      return false;
    }

    _lastSyncSignature = signature;
    _lastSyncTime = DateTime.now();
    _session = session;
    updateState(AuthProviderState(
      isAuthenticated: session?.isValid ?? false,
      session: session,
      user: user,
      lastActivity: DateTime.now(),
    ));
    return true;
  }


  /// 检测是否为 PKCE 相关错误
  ///
  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
