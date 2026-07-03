/// 统一通知服务
///
/// 【设计理念】
/// - SystemNotification (flutter_local_notifications): 系统级通知，应用在后台时显示
/// - InAppToast (toastification): 应用内轻量提示，仅应用在前台时显示
///
/// 【差异化场景】
/// - SystemNotification: 节点切换、连接状态变化、重要事件（应用可能在后台）
/// - InAppToast: 操作反馈、即时提示、临时信息（应用必须在前台）
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:guichao/gch_mod/gch_shared/gch_adaptive_root_scaffold.dart';
import 'package:toastification/toastification.dart';

/// 统一通知服务
///
/// 【使用示例】
/// ```dart
/// // 系统通知（应用在后台也会显示）
/// await GchSignalSvc.instance.systemNotification.success('节点切换成功');
///
/// // 应用内Toast（仅前台显示）
/// GchSignalSvc.instance.inAppToast.success('操作成功');
/// ```
class GchSignalSvc {
  GchSignalSvc._();
  static final instance = GchSignalSvc._();

  /// 系统级通知（flutter_local_notifications）
  final systemNotification = _SystemNotification();

  /// 应用内Toast（toastification）
  final inAppToast = _InAppToast();
}

/// 系统级通知（后台也可显示）
class _SystemNotification {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 初始化（自动调用）
  Future<void> _init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: iOS);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// 成功通知（绿色）
  Future<void> success(String message, {String? title}) async {
    await _show(
      title: title ?? '成功',
      message: message,
      importance: Importance.high,
      color: const Color(0xFF2159EA), // 绿色
    );
  }

  /// 错误通知（红色）
  Future<void> error(String message, {String? title}) async {
    await _show(
      title: title ?? '错误',
      message: message,
      importance: Importance.max,
      color: const Color(0xFFE53935), // 红色
    );
  }

  /// 信息通知（蓝色）
  Future<void> info(String message, {String? title}) async {
    await _show(
      title: title ?? '提示',
      message: message,
      importance: Importance.defaultImportance,
      color: const Color(0xFF2196F3), // 蓝色
    );
  }

  /// 警告通知（橙色）
  Future<void> warning(String message, {String? title}) async {
    await _show(
      title: title ?? '警告',
      message: message,
      importance: Importance.high,
      color: const Color(0xFFFF9800), // 橙色
    );
  }

  // 内部显示逻辑
  Future<void> _show({
    required String title,
    required String message,
    required Importance importance,
    Color? color,
  }) async {
    await _init();

    final android = AndroidNotificationDetails(
      'default_channel',
      '默认通知',
      channelDescription: '应用默认通知频道',
      importance: importance,
      priority: Priority.high,
      color: color,
      colorized: true,
    );

    const iOS = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: iOS);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
    );
  }
}

/// 应用内Toast（仅前台显示）- iOS 液态毛玻璃风格
class _InAppToast {
  /// 防抖时间窗口
  static const Duration _debounceWindow = Duration(seconds: 3);

  /// 最大重试次数
  static const int _maxRetries = 5;

  /// 毛玻璃模糊强度
  static const double _blurSigma = 24.0;

  /// 玻璃色
  static const Color _glassBg = Color(0xB8E6EAF6);
  static const Color _glassBgLight = Color(0xA6EDF0FA);
  static final Color _glassBorder = Colors.white.withValues(alpha:0.45);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _closeColor = Color(0xFF9CA3AF);

  /// 最近显示的通知记录（用于防抖）
  final Map<int, DateTime> _recentNotifications = {};

  /// 成功提示
  void success(String message, {Duration? duration}) {
    _show(
      message,
      type: ToastificationType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// 错误提示
  void error(String message, {Duration? duration}) {
    _show(
      message,
      type: ToastificationType.error,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  /// 信息提示
  void info(String message, {Duration? duration}) {
    _show(
      message,
      type: ToastificationType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// 警告提示
  void warning(String message, {Duration? duration}) {
    _show(
      message,
      type: ToastificationType.warning,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// 清除所有通知
  void dismissAll() {
    toastification.dismissAll();
  }

  // 内部显示逻辑
  void _show(String message, {required ToastificationType type, required Duration duration}) {
    // 防抖检查
    if (_isDuplicate(message, type)) {
      return;
    }

    final context = RootScaffold.stateKey.currentContext;
    if (context == null) {
      // 延迟重试，带最大重试限制
      _scheduleShow(message, type, duration, 0);
      return;
    }

    _doShowToast(context, message, type, duration);
  }

  /// 调度显示（带重试限制）
  void _scheduleShow(String message, ToastificationType type, Duration duration, int retryCount) {
    if (retryCount >= _maxRetries) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = RootScaffold.stateKey.currentContext;
      if (context != null) {
        _doShowToast(context, message, type, duration);
      } else {
        // 继续重试
        Future.delayed(const Duration(milliseconds: 500), () {
          _scheduleShow(message, type, duration, retryCount + 1);
        });
      }
    });
  }

  /// 根据类型获取图标和颜色
  (IconData, Color) _iconForType(ToastificationType type) {
    return switch (type) {
      ToastificationType.success => (Icons.check, const Color(0xFF6366F1)),
      ToastificationType.error => (Icons.close, const Color(0xFFEF4444)),
      ToastificationType.warning => (Icons.warning_amber_rounded, const Color(0xFFF59E0B)),
      _ => (Icons.info_outline, const Color(0xFF6366F1)),
    };
  }

  /// 实际显示Toast - iOS 液态毛玻璃风格
  void _doShowToast(BuildContext context, String message, ToastificationType type, Duration duration) {
    // 清除旧通知
    toastification.dismissAll();

    // 记录本次通知
    _recordNotification(message, type);

    toastification.showCustom(
      context: context,
      autoCloseDuration: duration,
      alignment: Alignment.bottomLeft,
      builder: (ctx, holder) {
        final (icon, iconColor) = _iconForType(type);

        return GestureDetector(
          onTap: () => toastification.dismiss(holder),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            constraints: const BoxConstraints(maxWidth: 420),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [_glassBg, _glassBgLight],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _glassBorder, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha:0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 类型图标 - 填充圆形
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconColor,
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      // 消息文本
                      Flexible(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 关闭按钮
                      GestureDetector(
                        onTap: () => toastification.dismiss(holder),
                        child: const Icon(
                          Icons.close,
                          color: _closeColor,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 检查是否为重复通知
  bool _isDuplicate(String message, ToastificationType type) {
    final key = Object.hash(message, type);
    final lastShown = _recentNotifications[key];

    if (lastShown == null) return false;

    final elapsed = DateTime.now().difference(lastShown);
    return elapsed < _debounceWindow;
  }

  /// 记录通知显示时间
  void _recordNotification(String message, ToastificationType type) {
    final key = Object.hash(message, type);
    _recentNotifications[key] = DateTime.now();

    // 清理过期记录
    final now = DateTime.now();
    _recentNotifications.removeWhere((_, time) {
      return now.difference(time) > _debounceWindow;
    });
  }
}
