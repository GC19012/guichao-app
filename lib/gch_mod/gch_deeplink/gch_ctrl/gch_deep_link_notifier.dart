import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_aux/gch_common.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'gch_deep_link_notifier.g.dart';

typedef NewProfileLink = ({String? url, String? name});

/// 应用的 URL Scheme（用于识别认证回调）
const String _appUrlScheme = 'guichao';

/// OAuth重定向事件
@riverpod
class OAuthRedirectNotifier extends _$OAuthRedirectNotifier {
  @override
  String? build() {
    return null;
  }

  void redirectTo(String path) {
    state = path;
    // 清除状态，允许后续重定向
    Future.delayed(const Duration(milliseconds: 1000), () {
      state = null;
    });
  }
}

@Riverpod(keepAlive: true)
class DeepLinkNotifier extends _$DeepLinkNotifier with GchInfraLogger {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  /// 标记是否有待处理的认证回调（用于避免重复重定向）
  bool _pendingAuthCallback = false;

  @override
  Future<NewProfileLink?> build() async {
    try {
      _appLinks = AppLinks();
      loggy.debug('GchPreparing app_links on ${Platform.operatingSystem}');

      // 监听 Supabase 原生认证状态变化（用于 OAuth/Magic Link 登录成功后的重定向）
      _setupSupabaseAuthListener();

      // 监听incoming links (非阻塞，失败不影响初始化)
      try {
        await _setupLinkListener();
      } catch (e, stackTrace) {
        loggy.error('Failed to setup link listener, but continuing', e, stackTrace);
      }

      // 处理初始链接（应用启动时的链接）
      final initialLink = await _getInitialLink();
      if (initialLink != null) {
        loggy.debug('Initial link received: [$initialLink]');
        final url = initialLink.toString();

        // 检查是否是认证回调
        if (_isSupabaseAuthCallback(url)) {
          loggy.info('Initial link is auth callback, processing...');
          _pendingAuthCallback = true;

          // 🔧 手动调用 Supabase SDK 处理认证回调
          try {
            loggy.debug('Manually calling getSessionFromUrl for initial link...');
            await Supabase.instance.client.auth.getSessionFromUrl(initialLink);
            loggy.info('getSessionFromUrl completed successfully for initial link');
          } catch (e, stackTrace) {
            loggy.error('Failed to get session from initial link URL', e, stackTrace);
            _pendingAuthCallback = false;
          }
          return null;
        }

        return _processDeepLink(url);
      }
    } catch (e, stackTrace) {
      loggy.error('Failed to initialize app_links', e, stackTrace);
      // 优雅降级，不阻止应用启动
    }

    // 清理资源
    ref.onDispose(() {
      _linkSubscription?.cancel();
      _authSubscription?.cancel();
      _appLinks = null;
    });

    return null;
  }

  /// 设置 Supabase 原生认证状态监听器
  ///
  /// 关键机制：直接监听 Supabase.instance.client.auth.onAuthStateChange
  /// 当 Deep Link 回调被 SDK 处理后，会触发 signedIn 事件并携带 session
  void _setupSupabaseAuthListener() {
    try {
      final supabase = Supabase.instance.client;

      _authSubscription = supabase.auth.onAuthStateChange.listen(
        (AuthState data) async {
          final session = data.session;
          final event = data.event;

          loggy.info('Supabase auth state changed: event=$event, hasSession=${session != null}');

          // 只有在有待处理的认证回调时才处理
          if (!_pendingAuthCallback) {
            return;
          }

          // 如果捕获到 Deep Link 并成功交换 Session，会自动触发 signedIn
          if (event == AuthChangeEvent.signedIn && session != null) {
            loggy.info('Auth callback signedIn detected, user: ${session.user.email ?? session.user.phone}');
            _pendingAuthCallback = false;

            // 同步用户数据到本地（确保与正常登录流程一致）
            await _syncUserDataAfterAuth(session);

            // 触发重定向到主页
            // ✅ 守卫检查：确保 provider 仍然存活，防止延迟回调超出生命周期
            Future.delayed(const Duration(milliseconds: 2000), () {
              try {
                if (!ref.exists(deepLinkNotifierProvider)) {
                  loggy.debug('DeepLinkNotifier 已销毁，跳过重定向');
                  return;
                }
                ref.read(oAuthRedirectNotifierProvider.notifier)
                   .redirectTo('/nav/home');
                loggy.debug('OAuth/Magic Link login successful, redirecting to /nav/home');
              } catch (e) {
                loggy.error('Auth redirect notification failed', e);
              }
            });
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          loggy.error('Supabase auth state listener error', error, stackTrace);
        },
      );

      loggy.debug('Supabase auth state listener setup completed');
    } catch (e, stackTrace) {
      loggy.error('Failed to setup Supabase auth listener', e, stackTrace);
    }
  }

  /// 认证成功后同步用户数据
  ///
  /// 确保与正常登录流程保持一致，本地会话和用户信息已同步
  Future<void> _syncUserDataAfterAuth(Session session) async {
    try {
      final authManager = await ref.read(authManagerProvider.future);

      // 1. 刷新会话 token（确保本地 token 与 Supabase 同步）
      final refreshed = await authManager.refreshToken();
      if (refreshed) {
        loggy.debug('Auth callback: token refresh successful');
      } else {
        loggy.warning('Auth callback: token refresh failed, but continuing');
      }

      // 2. 刷新用户数据（获取最新的用户信息，包括 VIP 状态等）
      final user = await authManager.refreshUserData(refreshSession: false);
      if (user != null) {
        loggy.info('Auth callback: user data synced - email=${user.email}, phone=${user.phone}, vipType=${user.vipType}');
      } else {
        loggy.warning('Auth callback: failed to sync user data');
      }
    } catch (e, stackTrace) {
      loggy.error('Auth callback: user data sync failed', e, stackTrace);
      // 不抛出异常，允许继续重定向
    }
  }

  /// 设置链接监听器
  Future<void> _setupLinkListener() async {
    try {
      final linkStream = _appLinks!.uriLinkStream;
      _linkSubscription = linkStream.listen(
        (Uri uri) async {
          // ✅ 守卫检查：确保 provider 仍然存活，防止异步回调超出生命周期
          try {
            if (!ref.exists(deepLinkNotifierProvider)) {
              loggy.debug('DeepLinkNotifier 已销毁，跳过链接处理');
              return;
            }
            loggy.debug('Deep link received: [$uri]');
            await _handleIncomingLink(uri);
          } catch (e) {
            loggy.error('Deep link handling failed', e);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          loggy.error('Deep link stream error', error, stackTrace);
        },
      );

      loggy.debug('Deep link listener setup completed');
    } catch (e, stackTrace) {
      loggy.error('Failed to setup link listener', e, stackTrace);
      // 不抛出异常，允许应用继续启动（deep link功能可选）
      rethrow;
    }
  }

  /// 获取初始链接（应用启动时）
  Future<Uri?> _getInitialLink() async {
    try {
      // 添加超时保护，避免在某些设备上无限等待
      final initialUri = await _appLinks!.getInitialLink().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          loggy.warning('getInitialLink() timed out after 3 seconds');
          return null;
        },
      );
      return initialUri;
    } on MissingPluginException catch (e) {
      // 插件尚未注册（如 Windows 首次帧之前），直接返回 null 等待后续再次触发
      loggy.warning('app_links plugin not ready yet, skip initial link: $e');
      return null;
    } on PlatformException catch (e, stackTrace) {
      loggy.error('Platform error while getting initial link', e, stackTrace);
      return null;
    } catch (e, stackTrace) {
      loggy.error('Failed to get initial link', e, stackTrace);
      return null;
    }
  }

  /// 处理传入的链接
  ///
  /// 对于 OAuth/Magic Link 回调，需要手动调用 Supabase SDK 的 getSessionFromUrl
  /// 因为项目使用 app_links 插件统一管理 deep link，SDK 的内部监听器可能无法接收到链接
  Future<void> _handleIncomingLink(Uri uri) async {
    final url = uri.toString();

    // 1. 检查是否是 Supabase 认证回调链接
    if (_isSupabaseAuthCallback(url)) {
      loggy.info('Supabase auth callback detected: [$url]');
      _pendingAuthCallback = true;

      // 🔧 手动调用 Supabase SDK 处理认证回调
      // 因为项目使用 app_links 统一管理 deep link，需要手动将 URL 传递给 SDK
      try {
        loggy.debug('Manually calling getSessionFromUrl...');
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        loggy.info('getSessionFromUrl completed successfully');
        // SDK 会自动触发 onAuthStateChange 事件
        // _setupSupabaseAuthListener 中会处理后续的用户数据同步和重定向
      } catch (e, stackTrace) {
        loggy.error('Failed to get session from URL', e, stackTrace);
        _pendingAuthCallback = false;
      }
      return;
    }

    // 2. 处理其他深度链接（如配置文件导入链接）
    final profileLink = _processDeepLink(url);
    if (profileLink != null) {
      // 更新状态，触发UI响应
      state = AsyncValue.data(profileLink);
    } else {
      loggy.debug('Invalid deep link received: [$url]');
    }
  }

  /// 检查是否是 Supabase 认证回调链接
  ///
  /// Supabase 认证回调包括：
  /// - Magic Link (邮箱登录链接): 包含 access_token, refresh_token, type=magiclink/email
  /// - OAuth 回调: 包含 code 参数（PKCE 流程）或 access_token（Implicit 流程）
  /// - 密码重置链接: 包含 type=recovery
  ///
  bool _isSupabaseAuthCallback(String url) {
    // Magic Link / Email OTP 回调（Implicit 流程，URL 中直接包含 token）
    if (url.contains('access_token') && url.contains('refresh_token')) {
      return true;
    }

    // PKCE OAuth 回调（包含 code 参数）
    if (url.contains('code=') &&
        (url.contains('auth-callback') ||
            url.contains('callback') ||
            url.contains('oauth'))) {
      return true;
    }

    // 检查是否匹配应用的回调 URL scheme
    try {
      final uri = Uri.parse(url);
      if (uri.scheme == _appUrlScheme &&
          (uri.host == 'auth-callback' ||
              uri.host == 'callback' ||
              uri.path.contains('callback'))) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// 处理深度链接并返回配置文件链接
  NewProfileLink? _processDeepLink(String url) {
    try {
      final link = LinkParser.deep(url);
      if (link != null) {
        loggy.debug('Valid profile link parsed: url=${link.url}, name=${link.name}');
        return (url: link.url, name: link.name);
      }
      return null;
    } catch (e, stackTrace) {
      loggy.error('Deep link processing failed', e, stackTrace);
      return null;
    }
  }

  /// 手动处理链接（用于测试或外部调用）
  Future<void> handleLink(String url) async {
    loggy.debug('Manually handling link: [$url]');
    try {
      final uri = Uri.parse(url);
      await _handleIncomingLink(uri);
    } catch (e, stackTrace) {
      loggy.error('Manual link handling failed', e, stackTrace);
    }
  }
}

/// 深度链接异常类
class DeepLinkException implements Exception {
  final String message;
  final dynamic cause;

  const DeepLinkException(this.message, [this.cause]);

  @override
  String toString() =>
      'DeepLinkException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}
