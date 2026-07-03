import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:guichao/gch_base/gch_schema/gch_fault.dart';
import 'package:guichao/gch_base/gch_nav/gch_nav_engine.dart';
import 'package:guichao/gch_mod/gch_shared/gch_adaptive_root_scaffold.dart';
import 'package:guichao/gch_aux/gch_common.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:toastification/toastification.dart';

part 'gch_signal_hub.g.dart';

@Riverpod(keepAlive: true)
GchSignalHub gchSignalHub(
  GchSignalHubRef ref,
) {
  final controller = GchSignalHub();
  ref.onDispose(controller.dispose);
  return controller;
}

enum GchSignalKind {
  info,
  error,
  success,
}

/// 待显示的通知消息
class _QueuedSignal {
  _QueuedSignal({
    required this.message,
    required this.type,
    required this.duration,
    this.actionText,
    this.actionCallback,
  });

  final String message;
  final GchSignalKind type;
  final Duration duration;
  final String? actionText;
  final VoidCallback? actionCallback;
}

/// 应用内通知控制器
///
/// 提供统一的 Toast 和 Dialog 显示机制，解决以下问题：
/// 1. UI 未就绪时的消息显示（通过消息队列缓存）
/// 2. 多种 context 来源的优先级处理
/// 3. 统一的显示逻辑，消除代码重复
/// 4. 防抖去重，避免短时间内显示重复通知
class GchSignalHub with GchAppLogger {
  // ========== iOS 液态毛玻璃主题色 ==========

  /// 毛玻璃模糊强度
  static const double _blurSigma = 24.0;

  /// Toast 玻璃背景
  static const Color _toastGlassBg = Color(0xB8E6EAF6); // ~72% 不透明度
  static const Color _toastGlassBgLight = Color(0xA6EDF0FA); // ~65% 不透明度

  /// Dialog 玻璃背景
  static const Color _dialogGlassBg = Color(0xD9F0F2FA); // ~85% 不透明度

  /// 边框
  static final Color _glassBorder = Colors.white.withValues(alpha: 0.45);

  /// 文字色
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF555570);

  /// 类型色
  static const Color _accentBlue = Color(0xFF6366F1); // 蓝紫，匹配参考设计
  static const Color _errorColor = Color(0xFFEF4444);

  /// 按钮色
  static const Color _btnPrimary = Color(0xFF6366F1);
  static const Color _btnPrimaryText = Colors.white;
  static const Color _btnSecondaryText = Color(0xFF666680);
  static final Color _btnSecondaryBorder = const Color(0xFF999AAB).withValues(alpha: 0.3);

  /// 关闭图标色
  static const Color _closeIconColor = Color(0xFF9CA3AF);

  /// 待显示的通知队列（UI 未就绪时缓存）
  final Queue<_QueuedSignal> _pendingQueue = Queue();

  /// 队列处理定时器
  Timer? _queueTimer;

  /// 最大队列长度，防止内存泄漏
  static const int _maxQueueSize = 20;

  /// 队列处理间隔
  static const Duration _queueProcessInterval = Duration(milliseconds: 500);

  /// 防抖时间窗口 - 同一消息在此时间内不重复显示
  static const Duration _debounceWindow = Duration(seconds: 3);

  /// 最大调度重试次数（防止无限递归）
  static const int _maxScheduleRetries = 10;

  /// 最近显示的通知记录（用于防抖去重）
  /// key: 消息+类型的hash, value: 显示时间
  final Map<int, DateTime> _recentNotifications = {};

  /// 是否已释放
  bool _disposed = false;

  // ========== 公共 API ==========

  /// 显示错误 Toast
  ToastificationItem? flashError(String message, {Duration? duration}) {
    return _showToast(
      message,
      type: GchSignalKind.error,
      duration: duration ?? const Duration(seconds: 10),
    );
  }

  /// 显示成功 Toast
  ToastificationItem? flashSuccess(String message, {Duration? duration}) {
    return _showToast(
      message,
      type: GchSignalKind.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// 显示信息 Toast
  ToastificationItem? flashInfo(String message, {Duration? duration}) {
    return _showToast(
      message,
      type: GchSignalKind.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// 显示带 Context 的 Toast（直接调用，不走队列）
  ToastificationItem? flash(
    BuildContext context,
    String message, {
    GchSignalKind type = GchSignalKind.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // 防抖检查
    if (_isDuplicate(message, type)) {
      return null;
    }

    // 清除旧通知
    toastification.dismissAll();

    // 记录本次通知
    _recordNotification(message, type);

    return _doShowToast(context: context, message: message, type: type, duration: duration);
  }

  /// 显示错误对话框
  Future<void> alertError(GchPresentableError error) async {
    final context = _getContext();
    if (context == null) {
      _scheduleCallback(() => alertError(error));
      return;
    }
    GchAlertDialog.fromErr(error).show(context);
  }

  /// 显示重试对话框（用于配置下载失败等需要重试的场景）
  ///
  /// @param title 对话框标题
  /// @param message 错误消息
  /// @param retryText 重试按钮文本
  /// @param cancelText 取消按钮文本
  /// @param onRetry 重试回调
  Future<void> alertRetry({
    required String title,
    required String message,
    required String retryText,
    required String cancelText,
    required VoidCallback onRetry,
  }) async {
    final context = _getContext();
    if (context == null) {
      _scheduleCallback(() => alertRetry(
        title: title,
        message: message,
        retryText: retryText,
        cancelText: cancelText,
        onRetry: onRetry,
      ));
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildRetryDialog(
        ctx,
        title: title,
        message: message,
        retryText: retryText,
        cancelText: cancelText,
        onRetry: onRetry,
      ),
    );
  }

  /// 构建重试对话框 - iOS 液态毛玻璃风格
  Widget _buildRetryDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String retryText,
    required String cancelText,
    required VoidCallback onRetry,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: _dialogGlassBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _glassBorder, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 错误图标
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _errorColor.withValues(alpha:0.12),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: _errorColor,
                    size: 30,
                  ),
                ),
                const Gap(18),
                // 标题
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(10),
                // 消息内容
                Text(
                  message,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(24),
                // 按钮行
                Row(
                  children: [
                    // 取消按钮 - 玻璃边框
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _btnSecondaryText,
                          side: BorderSide(color: _btnSecondaryBorder),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    // 重试按钮 - 蓝紫实心
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onRetry();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _btnPrimary,
                          foregroundColor: _btnPrimaryText,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          retryText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示确认弹窗（双按钮：取消/确认）
  /// 返回 true 表示用户点击确认，false 表示取消
  Future<bool> alertConfirm({
    required String title,
    String? message,
    required String confirmText,
    required String cancelText,
    IconData icon = Icons.warning_amber_outlined,
    Color iconColor = const Color(0xFFF59E0B),
    bool barrierDismissible = false,
  }) async {
    final context = _getContext();
    if (context == null) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => _buildConfirmDialog(
        ctx,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        iconColor: iconColor,
      ),
    );
    return result ?? false;
  }

  /// 显示强制更新弹窗（单按钮，不可关闭）
  /// 返回 true 表示用户点击了确认按钮
  Future<bool> alertForceUpdate({
    required String title,
    String? message,
    required String confirmText,
    IconData icon = Icons.system_update,
    Color iconColor = const Color(0xFF3B82F6),
  }) async {
    final context = _getContext();
    if (context == null) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildForceUpdateDialog(
        ctx,
        title: title,
        message: message,
        confirmText: confirmText,
        icon: icon,
        iconColor: iconColor,
      ),
    );
    return result ?? false;
  }

  Widget _buildForceUpdateDialog(
    BuildContext context, {
    required String title,
    String? message,
    required String confirmText,
    required IconData icon,
    required Color iconColor,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: _dialogGlassBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _glassBorder, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, color: iconColor, size: 30),
                ),
                const Gap(18),
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (message != null && message.isNotEmpty) ...[
                  const Gap(10),
                  Text(
                    message,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Gap(24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _btnPrimary,
                      foregroundColor: _btnPrimaryText,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建确认弹窗 - iOS 液态毛玻璃风格
  Widget _buildConfirmDialog(
    BuildContext context, {
    required String title,
    String? message,
    required String confirmText,
    required String cancelText,
    required IconData icon,
    required Color iconColor,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: _dialogGlassBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _glassBorder, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图标
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha:0.12),
                  ),
                  child: Icon(icon, color: iconColor, size: 30),
                ),
                const Gap(18),
                // 标题
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                // 消息内容（可选）
                if (message != null && message.isNotEmpty) ...[
                  const Gap(10),
                  Text(
                    message,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Gap(24),
                // 按钮行
                Row(
                  children: [
                    // 取消按钮 - 玻璃边框
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _btnSecondaryText,
                          side: BorderSide(color: _btnSecondaryBorder),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    // 确认按钮 - 蓝紫实心
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _btnPrimary,
                          foregroundColor: _btnPrimaryText,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示带操作按钮的 Toast
  void flashAction(
    String message, {
    required String actionText,
    required VoidCallback callback,
    Duration duration = const Duration(seconds: 5),
  }) {
    // 防抖检查
    if (_isDuplicate(message, GchSignalKind.info)) {
      return;
    }

    final overlay = _getOverlay();
    final context = _getContext();

    if (overlay == null && context == null) {
      // 加入队列等待
      _enqueue(_QueuedSignal(
        message: message,
        type: GchSignalKind.info,
        duration: duration,
        actionText: actionText,
        actionCallback: callback,
      ));
      return;
    }

    // 显示前清除旧通知
    toastification.dismissAll();

    // 记录本次通知
    _recordNotification(message, GchSignalKind.info);

    toastification.showCustom(
      context: context,
      overlayState: overlay,
      autoCloseDuration: duration,
      alignment: Alignment.bottomLeft,
      builder: (ctx, holder) => _buildActionToast(ctx, holder, message, actionText, callback),
    );
  }

  /// 清除所有当前显示的通知
  void silenceAll() {
    toastification.dismissAll();
  }

  /// 释放资源
  void dispose() {
    _disposed = true;
    _queueTimer?.cancel();
    _queueTimer = null;
    _pendingQueue.clear();
    _recentNotifications.clear();
  }

  // ========== 私有方法 ==========

  /// 获取可用的 OverlayState（优先使用 Navigator 的 overlay）
  OverlayState? _getOverlay() {
    return gchRootNavKey.currentState?.overlay;
  }

  /// 获取可用的 BuildContext（多来源优先级）
  BuildContext? _getContext() {
    // 优先级 1: Navigator context（应用启动后即可用）
    final navigatorContext = gchRootNavKey.currentContext;
    if (navigatorContext != null) return navigatorContext;

    // 优先级 2: RootScaffold context（主页面可用）
    return RootScaffold.stateKey.currentContext;
  }

  /// 显示 Toast 的统一入口
  ToastificationItem? _showToast(
    String message, {
    required GchSignalKind type,
    required Duration duration,
  }) {
    // 防抖检查：相同消息在时间窗口内不重复显示
    if (_isDuplicate(message, type)) {
      return null;
    }

    final overlay = _getOverlay();
    final context = _getContext();

    // 如果 overlay 和 context 都不可用，加入队列
    if (overlay == null && context == null) {
      _enqueue(_QueuedSignal(
        message: message,
        type: type,
        duration: duration,
      ));
      return null;
    }

    // 显示前清除旧通知，避免堆叠
    toastification.dismissAll();

    // 记录本次通知
    _recordNotification(message, type);

    return _doShowToast(
      context: context,
      overlay: overlay,
      message: message,
      type: type,
      duration: duration,
    );
  }

  /// 实际显示 Toast - 深色主题自定义样式
  ToastificationItem _doShowToast({
    BuildContext? context,
    OverlayState? overlay,
    required String message,
    required GchSignalKind type,
    required Duration duration,
  }) {
    return toastification.showCustom(
      context: context,
      overlayState: overlay,
      alignment: Alignment.bottomLeft,
      autoCloseDuration: duration,
      builder: (ctx, holder) => _buildCustomToast(ctx, holder, message, type),
    );
  }

  /// 构建自定义 Toast Widget - iOS 液态毛玻璃风格
  Widget _buildCustomToast(
    BuildContext context,
    ToastificationItem holder,
    String message,
    GchSignalKind type,
  ) {
    // 根据类型选择图标和颜色
    final (IconData icon, Color iconColor) = switch (type) {
      GchSignalKind.success => (Icons.check, _accentBlue),
      GchSignalKind.error => (Icons.close, _errorColor),
      GchSignalKind.info => (Icons.info_outline, _accentBlue),
    };

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
                  colors: [_toastGlassBg, _toastGlassBgLight],
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
                  const Gap(12),
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
                  const Gap(10),
                  // 关闭按钮
                  GestureDetector(
                    onTap: () => toastification.dismiss(holder),
                    child: const Icon(
                      Icons.close,
                      color: _closeIconColor,
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
  }

  /// 构建带操作按钮的 Toast Widget - iOS 液态毛玻璃风格
  Widget _buildActionToast(
    BuildContext context,
    ToastificationItem holder,
    String message,
    String actionText,
    VoidCallback callback,
  ) {
    return GestureDetector(
      onTap: () => toastification.dismiss(holder),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_toastGlassBg, _toastGlassBgLight],
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // 信息图标 - 填充圆形
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accentBlue,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const Gap(12),
                  // 消息文本
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Gap(8),
                  // 操作按钮 - 蓝紫色胶囊
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        toastification.dismiss(holder);
                        callback();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _btnPrimary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          actionText,
                          style: const TextStyle(
                            color: _btnPrimaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 将通知加入待处理队列
  void _enqueue(_QueuedSignal notification) {
    // 防止队列过长导致内存问题
    if (_pendingQueue.length >= _maxQueueSize) {
      _pendingQueue.removeFirst();
      loggy.warning('通知队列已满，丢弃最早的通知');
    }

    _pendingQueue.addLast(notification);
    _startQueueProcessor();
  }

  /// 启动队列处理器
  void _startQueueProcessor() {
    if (_queueTimer != null) return;

    _queueTimer = Timer.periodic(_queueProcessInterval, (_) {
      _processQueue();
    });
  }

  /// 处理待显示队列
  void _processQueue() {
    // 已释放则直接返回
    if (_disposed) {
      _queueTimer?.cancel();
      _queueTimer = null;
      return;
    }

    if (_pendingQueue.isEmpty) {
      _queueTimer?.cancel();
      _queueTimer = null;
      return;
    }

    final overlay = _getOverlay();
    final context = _getContext();

    // UI 仍未就绪，继续等待
    if (overlay == null && context == null) return;

    // 只处理队列中的第一个通知（防抖：每次只显示一个）
    final notification = _pendingQueue.removeFirst();

    // 清除旧通知避免堆叠
    toastification.dismissAll();

    // 记录并检查防抖
    if (!_isDuplicate(notification.message, notification.type)) {
      _recordNotification(notification.message, notification.type);

      if (notification.actionText != null && notification.actionCallback != null) {
        // 带操作按钮的 Toast
        toastification.showCustom(
          context: context,
          overlayState: overlay,
          autoCloseDuration: notification.duration,
          alignment: Alignment.bottomLeft,
          builder: (ctx, holder) => _buildActionToast(
            ctx,
            holder,
            notification.message,
            notification.actionText!,
            notification.actionCallback!,
          ),
        );
      } else {
        // 普通 Toast
        _doShowToast(
          context: context,
          overlay: overlay,
          message: notification.message,
          type: notification.type,
          duration: notification.duration,
        );
      }
    }

    // 队列已清空，停止定时器
    if (_pendingQueue.isEmpty) {
      _queueTimer?.cancel();
      _queueTimer = null;
    }
  }

  /// 调度下一帧回调（用于 Dialog 等需要完整 context 的场景）
  void _scheduleCallback(VoidCallback callback, [int retryCount = 0]) {
    // 防止无限递归
    if (_disposed || retryCount >= _maxScheduleRetries) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;

      if (_getContext() != null) {
        callback();
      } else {
        // 继续等待，带重试计数
        Future.delayed(_queueProcessInterval, () {
          _scheduleCallback(callback, retryCount + 1);
        });
      }
    });
  }

  /// 检查是否为重复通知（防抖）
  bool _isDuplicate(String message, GchSignalKind type) {
    final key = _getNotificationKey(message, type);
    final lastShown = _recentNotifications[key];

    if (lastShown == null) return false;

    final elapsed = DateTime.now().difference(lastShown);
    return elapsed < _debounceWindow;
  }

  /// 记录通知显示时间
  void _recordNotification(String message, GchSignalKind type) {
    final key = _getNotificationKey(message, type);
    _recentNotifications[key] = DateTime.now();

    // 清理过期记录，防止内存泄漏
    _cleanupExpiredRecords();
  }

  /// 生成通知的唯一key
  int _getNotificationKey(String message, GchSignalKind type) {
    return Object.hash(message, type);
  }

  /// 清理过期的通知记录
  void _cleanupExpiredRecords() {
    final now = DateTime.now();
    _recentNotifications.removeWhere((_, time) {
      return now.difference(time) > _debounceWindow;
    });
  }
}
