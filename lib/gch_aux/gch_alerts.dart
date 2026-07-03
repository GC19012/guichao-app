import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// 自定义警告对话框 - iOS 液态毛玻璃风格
class GchAlertDialog extends StatelessWidget {
  const GchAlertDialog({
    super.key,
    this.title,
    required this.message,
    this.isError = false,
  });

  final String? title;
  final String message;
  final bool isError;

  // iOS 液态毛玻璃主题色
  static const double _blurSigma = 24.0;
  static const Color _glassBg = Color(0xD9F0F2FA);
  static final Color _glassBorder = Colors.white.withValues(alpha:0.45);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF555570);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _accentBlue = Color(0xFF6366F1);
  static const Color _btnPrimary = Color(0xFF6366F1);

  factory GchAlertDialog.fromErr(({String type, String? message}) err) =>
      GchAlertDialog(
        title: err.message == null ? null : err.type,
        message: err.message ?? err.type,
        isError: true,
      );

  /// 配置文件错误弹框
  factory GchAlertDialog.configError({
    required String title,
    required String message,
  }) =>
      GchAlertDialog(
        title: title,
        message: message,
        isError: true,
      );

  Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final iconColor = isError ? _errorColor : _accentBlue;

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
              color: _glassBg,
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
                  child: Icon(
                    isError ? Icons.error_outline : Icons.info_outline,
                    color: iconColor,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 18),

                // 标题
                if (title != null)
                  Text(
                    title!,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                if (title != null) const SizedBox(height: 10),

                // 内容
                SingleChildScrollView(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                // 确认按钮 - 蓝紫实心
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _btnPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      localizations.okButtonLabel,
                      style: const TextStyle(
                        fontSize: 16,
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
}

enum GchAlertType {
  info,
  error,
  success;
}

/// 自定义 Toast - iOS 液态毛玻璃风格
class GchToast extends StatelessWidget {
  const GchToast(
    this.message, {
    this.type = GchAlertType.info,
    this.icon,
    this.duration = const Duration(seconds: 3),
  });

  const GchToast.error(
    this.message, {
    this.duration = const Duration(seconds: 5),
  })  : type = GchAlertType.error,
        icon = Icons.error_outline;

  const GchToast.success(
    this.message, {
    this.duration = const Duration(seconds: 3),
  })  : type = GchAlertType.success,
        icon = Icons.check_circle_outline;

  final String message;
  final GchAlertType type;
  final IconData? icon;
  final Duration duration;

  // iOS 液态毛玻璃主题色
  static const double _blurSigma = 24.0;
  static const Color _glassBg = Color(0xB8E6EAF6);
  static const Color _glassBgLight = Color(0xA6EDF0FA);
  static final Color _glassBorder = Colors.white.withValues(alpha:0.45);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _accentBlue = Color(0xFF6366F1);
  static const Color _errorColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    // 根据类型选择图标颜色（填充圆形）
    final iconColor = switch (type) {
      GchAlertType.info => _accentBlue,
      GchAlertType.error => _errorColor,
      GchAlertType.success => _accentBlue,
    };

    return ClipRRect(
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
              if (icon != null) ...[
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
              ],
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
            ],
          ),
        ),
      ),
    );
  }

  void show(BuildContext context) {
    toastification.showCustom(
      context: context,
      alignment: Alignment.bottomLeft,
      autoCloseDuration: duration,
      builder: (ctx, holder) => GestureDetector(
        onTap: () => toastification.dismiss(holder),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: this,
        ),
      ),
    );
  }
}
