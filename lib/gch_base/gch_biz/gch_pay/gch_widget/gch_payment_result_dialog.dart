import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';

/// 支付结果弹框 - 浅色主题
class PaymentResultDialog extends ConsumerWidget {
  final bool success;
  final String? message;
  final VoidCallback? onConfirm;

  // 浅色主题配色
  static const Color _dialogBg = Color(0xFFF7F6FF);
  static const Color _borderColor = Color(0xFFE4E6F5);
  static const Color _textDark = Color(0xFF2F2F3A);
  static const Color _textMuted = Color(0xFF8C8FAE);
  static const Color _accent = Color(0xFF5969FF);

  const PaymentResultDialog({
    super.key,
    required this.success,
    this.message,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // 如果是成功且未提供message，自动生成当前时间
    final displayMessage = success && message == null
        ? _formatDateTime(DateTime.now())
        : message;

    return Dialog(
      backgroundColor: _dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _borderColor, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: success
                    ? const Color(0xFFE8F7EE)
                    : const Color(0xFFFEECEE),
              ),
              child: Icon(
                success ? Icons.check : Icons.close,
                color: success ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // 标题
            Text(
              success ? GchText.userPayResultsPaymentSuccess : GchText.userPayResultsPaymentFailed,
              style: const TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            // 消息
            if (displayMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                displayMessage,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // 确认按钮 - 浅紫色主按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (success) {
                    // 成功时跳转到主页
                    const NavMainHomeRoute().go(context);
                  }
                  onConfirm?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  success ? GchText.userCommonBackToHome : GchText.userCommonConfirm,
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
    );
  }

  /// 格式化时间为 "2025.10.13 15:47:33"
  static String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');

    return '$year.$month.$day $hour:$minute:$second';
  }

  /// 显示支付成功对话框
  static Future<void> showSuccess(
    BuildContext context, {
    String? message,
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentResultDialog(
        success: true,
        message: message,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 显示支付失败对话框
  static Future<void> showFailure(
    BuildContext context, {
    String? message,
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentResultDialog(
        success: false,
        message: message,
        onConfirm: onConfirm,
      ),
    );
  }
}

/// 支付处理中对话框 - 浅色主题
class PaymentProcessingDialog extends ConsumerWidget {
  final String? message;
  static bool _isShowing = false;
  static NavigatorState? _dialogNavigator;

  // 浅色主题配色
  static const Color _dialogBg = Color(0xFFF7F6FF);
  static const Color _borderColor = Color(0xFFE4E6F5);
  static const Color _accent = Color(0xFF5969FF);
  static const Color _textDark = Color(0xFF2F2F3A);

  const PaymentProcessingDialog({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: _dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _borderColor, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 旋转loading - 浅色主题紫色
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
              ),
            ),
            const SizedBox(height: 20),

            // 提示文本
            Text(
              message ?? GchText.userPayProcessingMsg,
              style: const TextStyle(
                color: _textDark,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 显示支付处理中对话框
  static Future<void> show(
    BuildContext context, {
    String? message,
  }) {
    if (_isShowing) {
      return Future.value();
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    if (!navigator.mounted) return Future.value();

    _dialogNavigator = navigator;
    _isShowing = true;

    return showDialog(
      context: navigator.context,
      barrierDismissible: false, // 不可点击外部关闭
      builder: (ctx) => PaymentProcessingDialog(
        message: message,
      ),
    ).whenComplete(() {
      _isShowing = false;
      if (_dialogNavigator == navigator) {
        _dialogNavigator = null;
      }
    });
  }

  /// 关闭支付处理中对话框
  static void dismiss(BuildContext context) {
    if (!_isShowing) {
      _dialogNavigator = null;
      return;
    }

    final navigator = _dialogNavigator ?? Navigator.of(context, rootNavigator: true);
    if (!navigator.mounted) {
      _isShowing = false;
      _dialogNavigator = null;
      return;
    }

    if (navigator.canPop()) {
      navigator.pop();
    }

    _isShowing = false;
    _dialogNavigator = null;
  }

  /// 无需 BuildContext 的安全关闭 — 在终态（成功/失败/取消/超时）时调用
  static void dismissIfShowing() {
    if (!_isShowing) return;

    final navigator = _dialogNavigator;
    if (navigator != null && navigator.mounted && navigator.canPop()) {
      navigator.pop();
    }

    _isShowing = false;
    _dialogNavigator = null;
  }
}
