// providers/local_session_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_base_session_provider.dart';

/// 本地会话管理提供者
class LocalSession extends BaseSessionProvider {
  static const String _sessionKey = 'guichao_auth_session';
  static const String _refreshTokenKey = 'guichao_refresh_token';
  static const String _userIdKey = 'guichao_user_id';
  
  final FlutterSecureStorage _storage;
  final _sessionController = StreamController<AuthSession?>.broadcast();
  AuthSession? _currentSession;
  Timer? _refreshTimer;
  
  /// 自动刷新令牌的时间窗口（令牌过期前5分钟）
  static const Duration _refreshWindow = Duration(minutes: 5);
  
  LocalSession({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage() {
    _initializeSession();
  }
  
  /// 初始化会话，从本地存储加载
  Future<void> _initializeSession() async {
    try {
      final sessionData = await _storage.read(key: _sessionKey);
      if (sessionData != null) {
        final data = jsonDecode(sessionData) as Map<String, dynamic>;
        _currentSession = AuthSession(
          userId: data['userId'] as String,
          token: data['token'] as String,
          refreshToken: data['refreshToken'] as String?,
          expiresAt: DateTime.parse(data['expiresAt'] as String),
          metadata: data['metadata'] as Map<String, dynamic>? ?? {},
        );
        
        // 检查会话是否仍然有效
        if (_currentSession!.isValid) {
          _sessionController.add(_currentSession);
          // 使用基类方法更新状态
          updateState(AuthProviderState(
            isAuthenticated: true,
            session: _currentSession,
            lastActivity: DateTime.now(),
          ));
          _scheduleRefresh();
        } else {
          // 会话已过期，尝试刷新
          final refreshed = await refreshSession();
          if (!refreshed) {
            await clearSession();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize session: $e');
      await clearSession();
    }
  }
  
  @override
  Future<AuthSession?> getCurrentSession() async {
    return _currentSession;
  }

  @override
  Future<AuthUser?> getUser({String? accessToken}) async {
    return currentState.user;
  }
  
  @override
  Future<bool> refreshSession() async {
    if (_currentSession?.refreshToken == null) {
      return false;
    }
    
    try {
      // 这里应该调用实际的令牌刷新API
      // 为了演示，我们模拟一个成功的刷新
      final newExpiresAt = DateTime.now().add(const Duration(hours: 1));
      final refreshedSession = AuthSession(
        userId: _currentSession!.userId,
        token: '${_currentSession!.token}_refreshed_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: _currentSession!.refreshToken,
        expiresAt: newExpiresAt,
        metadata: _currentSession!.metadata,
      );
      
      await _updateSession(refreshedSession);
      // 使用基类方法处理Token刷新
      handleTokenRefresh(refreshedSession);
      return true;
    } catch (e) {
      debugPrint('Failed to refresh session: $e');
      return false;
    }
  }
  
  @override
  Future<void> clearSession() async {
    _cancelRefreshTimer();
    _currentSession = null;
    _sessionController.add(null);
    
    // 清除本地存储
    await Future.wait([
      _storage.delete(key: _sessionKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userIdKey),
    ]);
    
    // 使用基类方法处理登出
    handleSignOut('Session cleared');
  }
  
  /// 更新会话
  Future<void> _updateSession(AuthSession session) async {
    _currentSession = session;
    _sessionController.add(session);
    
    // 保存到本地存储
    final sessionData = {
      'userId': session.userId,
      'token': session.token,
      'refreshToken': session.refreshToken,
      'expiresAt': session.expiresAt.toIso8601String(),
      'metadata': session.metadata,
    };
    
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(sessionData),
    );
    
    // 安排自动刷新
    _scheduleRefresh();
  }
  
  /// 安排令牌刷新
  void _scheduleRefresh() {
    _cancelRefreshTimer();
    
    if (_currentSession == null || _currentSession!.refreshToken == null) {
      return;
    }
    
    final now = DateTime.now();
    final refreshTime = _currentSession!.expiresAt.subtract(_refreshWindow);
    
    if (refreshTime.isAfter(now)) {
      final delay = refreshTime.difference(now);
      _refreshTimer = Timer(delay, () async {
        final success = await refreshSession();
        if (!success) {
          debugPrint('Auto refresh failed, clearing session');
          await clearSession();
        }
      });
    } else {
      // 令牌即将过期或已过期，立即尝试刷新
      Timer.run(() async {
        final success = await refreshSession();
        if (!success) {
          await clearSession();
        }
      });
    }
  }
  
  void _cancelRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
  
  /// 检查会话是否有效（包括即将过期的情况）
  bool isSessionValid({Duration? buffer}) {
    if (_currentSession == null) return false;
    
    final now = DateTime.now();
    final bufferTime = buffer ?? _refreshWindow;
    return _currentSession!.expiresAt.subtract(bufferTime).isAfter(now);
  }
  
  /// 获取会话的剩余有效时间
  Duration? getSessionRemainingTime() {
    if (_currentSession == null) return null;
    
    final now = DateTime.now();
    if (_currentSession!.expiresAt.isBefore(now)) {
      return Duration.zero;
    }
    
    return _currentSession!.expiresAt.difference(now);
  }
  
  /// 获取用户ID（如果会话存在）
  Future<String?> getCurrentUserId() async {
    return _currentSession?.userId ?? await _storage.read(key: _userIdKey);
  }
  
  /// 获取当前令牌
  Future<String?> getCurrentToken() async {
    return _currentSession?.token;
  }
  
  /// 获取刷新令牌
  Future<String?> getRefreshToken() async {
    return _currentSession?.refreshToken ?? await _storage.read(key: _refreshTokenKey);
  }
  
  /// 会话流
  @override
  Stream<AuthSession?> get sessionStream => _sessionController.stream;
  
  /// 更新会话信息
  Future<void> updateSession(AuthSession session) async {
    await _updateSession(session);
  }
  
  /// 销毁提供者，清理资源
  @override
  void dispose() {
    _cancelRefreshTimer();
    _sessionController.close();
    super.dispose();
  }
}

/// 会话事件类型
enum SessionEventType {
  created,
  refreshed,
  expired,
  cleared,
}

/// 会话事件
class SessionEvent {
  final SessionEventType type;
  final AuthSession? session;
  final DateTime timestamp;
  final String? reason;
  
  const SessionEvent({
    required this.type,
    this.session,
    required this.timestamp,
    this.reason,
  });
  
  @override
  String toString() {
    return 'SessionEvent(type: $type, session: ${session?.userId}, timestamp: $timestamp, reason: $reason)';
  }
}

/// 会话管理器（带事件通知）
class SessionManager extends LocalSession {
  final _eventController = StreamController<SessionEvent>.broadcast();
  
  SessionManager({super.storage});
  
  /// 会话事件流
  Stream<SessionEvent> get sessionEvents => _eventController.stream;
  
  @override
  Future<void> updateSession(AuthSession session) async {
    await _updateSession(session);
    _eventController.add(SessionEvent(
      type: SessionEventType.created,
      session: session,
      timestamp: DateTime.now(),
    ));
  }
  
  @override
  Future<bool> refreshSession() async {
    final success = await super.refreshSession();
    if (success) {
      _eventController.add(SessionEvent(
        type: SessionEventType.refreshed,
        session: _currentSession,
        timestamp: DateTime.now(),
      ));
    }
    return success;
  }
  
  @override
  Future<void> clearSession() async {
    final oldSession = _currentSession;
    await super.clearSession();
    
    _eventController.add(SessionEvent(
      type: SessionEventType.cleared,
      session: oldSession,
      timestamp: DateTime.now(),
      reason: 'Manual logout or session cleanup',
    ));
  }
  
  /// 通知会话过期
  void notifySessionExpired(String reason) {
    _eventController.add(SessionEvent(
      type: SessionEventType.expired,
      session: _currentSession,
      timestamp: DateTime.now(),
      reason: reason,
    ));
  }
  
  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }
}
