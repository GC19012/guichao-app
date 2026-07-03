// auth_time_service.dart
//
// 目的：提供一个不受设备时钟回拨攻击影响的"估算当前时间"。
//
// 原理：
//   每次 Supabase 下发 JWT（accessToken），其 payload 中的 `iat`（issued-at）
//   字段是服务端签名的颁发时刻（Unix 秒）。我们将其作为"已知可信时间锚点"，
//   同时记录本地墙上时钟此刻的值。
//
//   estimatedNow = serverAnchor + max(0, DateTime.now() - wallAnchor)
//
//   若用户回拨时钟（ DateTime.now() < wallAnchor ），wall delta 为负，
//   夹紧为 0 → estimatedNow 停在 serverAnchor（过期前的值）→ isExpired 依然为 true。
//   若用户将时钟向前拨（DateTime.now() > wallAnchor），delta 仍然是真实经过时间，
//   正常流逝，不受影响。
//
//   锚点持久化到 FlutterSecureStorage，跨会话保留。

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_kit/gch_loggers.dart';

class AuthTimeService with GchInfraLogger {
  static const _kServerMs = 'auth_time_anchor_server_ms';
  static const _kWallMs = 'auth_time_anchor_wall_ms';

  final FlutterSecureStorage _storage;

  DateTime? _serverTimeAtAnchor;
  DateTime? _wallTimeAtAnchor;

  AuthTimeService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ---------------------------------------------------------------------------
  // JWT helpers
  // ---------------------------------------------------------------------------

  /// 从 JWT access token 的 payload 中解析 `iat`（服务端签发时间）。
  /// 返回 null 表示无法解析（非标准 JWT、字段缺失等）。
  static DateTime? extractIatFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Base64url → 补齐填充 → 解码
      String payload = parts[1];
      final rem = payload.length % 4;
      if (rem != 0) payload += '=' * (4 - rem);

      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;

      final iat = map['iat'];
      if (iat is int) {
        return DateTime.fromMillisecondsSinceEpoch(iat * 1000);
      } else if (iat is double) {
        return DateTime.fromMillisecondsSinceEpoch((iat * 1000).toInt());
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Anchor management
  // ---------------------------------------------------------------------------

  /// 更新时间锚点（在每次获得新 JWT 时调用）。
  /// [serverTime] 是从 JWT iat 解析的服务端签发时间。
  Future<void> setAnchor(DateTime serverTime) async {
    final wallNow = DateTime.now();
    _serverTimeAtAnchor = serverTime;
    _wallTimeAtAnchor = wallNow;

    // 持久化，下次冷启动时恢复（两次写入并行，互相独立）
    try {
      await Future.wait([
        _storage.write(
          key: _kServerMs,
          value: serverTime.millisecondsSinceEpoch.toString(),
        ),
        _storage.write(
          key: _kWallMs,
          value: wallNow.millisecondsSinceEpoch.toString(),
        ),
      ]);
    } catch (e) {
      loggy.warning('AuthTimeService: 持久化锚点失败: $e');
    }
  }

  /// 冷启动时从 SecureStorage 恢复上一次的锚点。
  Future<void> loadFromStorage() async {
    try {
      // 两次读取并行，互相独立
      final results = await Future.wait([
        _storage.read(key: _kServerMs),
        _storage.read(key: _kWallMs),
      ]);
      final serverMs = results[0];
      final wallMs = results[1];
      if (serverMs != null && wallMs != null) {
        _serverTimeAtAnchor =
            DateTime.fromMillisecondsSinceEpoch(int.parse(serverMs));
        _wallTimeAtAnchor =
            DateTime.fromMillisecondsSinceEpoch(int.parse(wallMs));
        loggy.debug(
          'AuthTimeService: 已恢复锚点 server=$_serverTimeAtAnchor '
          'wall=$_wallTimeAtAnchor',
        );
      }
    } catch (e) {
      loggy.warning('AuthTimeService: 恢复锚点失败: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Core API
  // ---------------------------------------------------------------------------

  /// 返回防时钟回拨的"当前时间"估算值。
  ///
  /// - 有锚点时：serverAnchor + max(0, wallDelta)
  /// - 无锚点时：回退到 DateTime.now()（无锚点场景下无历史过期判断依据）
  DateTime get estimatedNow {
    final server = _serverTimeAtAnchor;
    final wall = _wallTimeAtAnchor;
    if (server == null || wall == null) return DateTime.now();

    final wallDelta = DateTime.now().difference(wall);
    // 回拨场景：wallDelta < 0 → 夹紧为 0，时间冻结在服务端锚点
    final effectiveDelta =
        wallDelta.isNegative ? Duration.zero : wallDelta;
    return server.add(effectiveDelta);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// 全局 AuthTimeService 单例。
///
/// 启动时从 SecureStorage 恢复锚点；
/// 每次 authStateChanges 触发时，用 JWT iat 更新锚点。
final authTimeServiceProvider = Provider<AuthTimeService>((ref) {
  final service = AuthTimeService(
    storage: ref.watch(secureStorageProvider),
  );

  // 异步加载持久化锚点（不阻塞 provider 构建）
  unawaited(service.loadFromStorage());

  // 监听认证状态变化 → 提取 JWT iat → 更新锚点
  ref.listen(
    authStateChangesProvider,
    (_, next) {
      final state = next.value;
      if (state == null) return;

      // 从 Session 的 token（JWT）中提取服务端签发时间
      final token = state.session?.token;
      final serverTime = AuthTimeService.extractIatFromToken(token);
      if (serverTime != null) {
        unawaited(service.setAnchor(serverTime));
      }
    },
    fireImmediately: true,
  );

  return service;
});
