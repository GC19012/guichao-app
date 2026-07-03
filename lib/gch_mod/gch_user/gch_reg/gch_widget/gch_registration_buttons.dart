// registration_buttons.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_model/gch_registration_state.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_ctrl/gch_registration_notifier.dart';

/// 注册按钮组件
class RegistrationButtons extends ConsumerWidget {
  final RegistrationState state;
  final VoidCallback onRegister;

  const RegistrationButtons({
    super.key,
    required this.state,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(registrationNotifierProvider.notifier);
    // 错误消息统一由 register_page.dart 的 _handleRegistrationFeedback() 通过 toast 显示
    // 不再在按钮下方显示内联错误，避免重复提示
    return _buildMainButton(notifier);
  }

  /// 构建主要注册按钮（图片背景风格，与 LoginPage 一致）
  Widget _buildMainButton(RegistrationNotifier notifier) {
    final isEnabled = _isButtonEnabled();
    final buttonText = notifier.registerButtonText();
    final isLoading = state.isLoading;

    return GestureDetector(
      onTap: isEnabled && !isLoading ? onRegister : null,
      child: Container(
        width: double.infinity,
        height: 48.72.rh,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.5.rr),
          image: const DecorationImage(
            image: AssetImage('assets/gch_pics/gch_e2992f.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 18.ri,
                  height: 18.ri,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF5969FF)),
                  ),
                )
              : Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: 16.rf,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5969FF),
                  ),
                ),
        ),
      ),
    );
  }

  /// 是否启用按钮
  bool _isButtonEnabled() {
    switch (state.phase) {
      case RegistrationPhase.initial:
        return state.canSendCode;
      case RegistrationPhase.codeSent:
      case RegistrationPhase.error:
        return state.canVerify;
      case RegistrationPhase.sendingCode:
      case RegistrationPhase.verifying:
        return false;
      case RegistrationPhase.completed:
        return false;
    }
  }
}
