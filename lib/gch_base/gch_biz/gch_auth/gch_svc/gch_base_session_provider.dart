// base_session_provider.dart

import 'dart:async';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';
import 'gch_auth_provider_interface.dart';

/// 基础会话提供者，实现通用的事件处理逻辑
abstract class BaseSessionProvider with GchAppLogger implements SessionProvider {
  // 事件流控制器
  final StreamController<AuthEvent> _eventController = StreamController<AuthEvent>.broadcast();
  final StreamController<AuthProviderState> _stateController = StreamController<AuthProviderState>.broadcast();
  
  // 当前状态
  AuthProviderState _currentState = const AuthProviderState(isAuthenticated: false);
  
  @override
  Stream<AuthEvent> get authEvents => _eventController.stream;
  
  @override
  Stream<AuthProviderState> get authStateChanges => _stateController.stream;
  
  @override
  AuthProviderState get currentState => _currentState;
  
  /// 发出认证事件
  void emitEvent(AuthEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
      loggy.debug('发出认证事件: ${event.type}');
    }
  }
  
  /// 更新认证状态
  void updateState(AuthProviderState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
      loggy.debug('认证状态更新: isAuthenticated=${newState.isAuthenticated}');
    }
  }
  
  /// 处理登录成功
  void handleSignIn(AuthUser user, AuthSession session) {
    updateState(AuthProviderState(
      isAuthenticated: true,
      user: user,
      session: session,
      lastActivity: DateTime.now(),
    ));
    emitEvent(AuthEvent.signedIn(user, session));
  }
  
  /// 处理登出
  void handleSignOut([String? reason]) {
    updateState(const AuthProviderState(isAuthenticated: false));
    emitEvent(AuthEvent.signedOut(reason));
  }
  
  /// 处理Token刷新
  void handleTokenRefresh(AuthSession session) {
    updateState(_currentState.copyWith(
      session: session,
      lastActivity: DateTime.now(),
    ));
    emitEvent(AuthEvent.tokenRefreshed(session));
  }
  
  /// 处理Token过期
  void handleTokenExpired([String? sessionId]) {
    updateState(const AuthProviderState(isAuthenticated: false));
    emitEvent(AuthEvent.tokenExpired(sessionId));
  }
  
  /// 处理用户信息更新
  void handleUserUpdate(AuthUser user) {
    updateState(_currentState.copyWith(
      user: user,
      lastActivity: DateTime.now(),
    ));
    emitEvent(AuthEvent.userUpdated(user));
  }
  
  /// 处理错误
  void handleError(String message, [Map<String, dynamic>? data]) {
    emitEvent(AuthEvent.error(message, data));
  }
  
  /// 清理资源
  void dispose() {
    _eventController.close();
    _stateController.close();
  }
}