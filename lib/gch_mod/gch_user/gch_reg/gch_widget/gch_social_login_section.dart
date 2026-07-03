import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_mod/gch_user/gch_login/gch_ctrl/gch_login_notifier.dart';

/// 注册页第三方登录 —— 微信 + Apple（大小 / 样式与 LoginPage 一致）
class SocialLoginSection extends ConsumerStatefulWidget {
  /// 登录前协议校验回调：返回 true 表示已同意可继续，false 表示未同意需阻止
  final bool Function()? onCheckAgreement;

  const SocialLoginSection({super.key, this.onCheckAgreement});

  @override
  ConsumerState<SocialLoginSection> createState() => _SocialLoginSectionState();
}

class _SocialLoginSectionState extends ConsumerState<SocialLoginSection> {
  bool _isAppleSigningIn = false;

  bool get _anySigningIn => _isAppleSigningIn;

  @override
  Widget build(BuildContext context) {
    final showApple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showApple)
          _buildSocialButton(
            imagePath: 'assets/gch_pics/gch_d6bd89.webp',
            isLoading: _isAppleSigningIn,
            isDisabled: _anySigningIn,
            onTap: _handleAppleLogin,
          ),
      ],
    );
  }

  /// 社交登录按钮（Apple）—— 与 LoginPage 视觉一致（50×50 白色圆 + 36 图片）
  Widget _buildSocialButton({
    required String imagePath,
    required bool isLoading,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1,
        child: Container(
          width: 50.rw,
          height: 50.rh,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10.rh,
                offset: Offset(0, 3.rh),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 17.ri,
                    height: 17.ri,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                  )
                : Image.asset(
                    imagePath,
                    width: 36.rw,
                    height: 36.rh,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAppleLogin() async {
    if (_anySigningIn) return;
    if (widget.onCheckAgreement != null && !widget.onCheckAgreement!()) return;

    setState(() => _isAppleSigningIn = true);

    final notifier = ref.read(loginNotifierProvider.notifier);
    final notificationController = ref.read(gchSignalHubProvider);

    try {
      final result = await notifier.loginWithApple();
      if (!mounted) return;

      if (result.success) {
        notificationController.flashSuccess(GchText.userLoginSuccessAppleLoginSuccess);
        const NavMainHomeRoute().go(context);
      } else if (result.errorMessage != null) {
        notificationController.flashError(
          result.errorMessage!,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) setState(() => _isAppleSigningIn = false);
    }
  }

}
