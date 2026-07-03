import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_widget/gch_setting_gradient_button.dart';
import 'package:guichao/gch_aux/gch_nav_ext.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

import 'gch_ctrl/gch_password_change_notifier.dart';

/// 页面主题颜色 - 与 setting_page / delete_account_page 保持一致的浅紫色风格
class _PageColors {
  static const Color background = Color(0xFFF1EFF9);
  static const Color cardBackground = Colors.white;
  static const Color primaryText = Color(0xFF333333);
  static const Color secondaryText = Color(0xFF9A98AA);
  static const Color hintText = Color(0xFFB7B7B7);
  static const Color inputBorder = Color(0xFFEEEEEE);
  static const Color tipsBackground = Color(0xFFF5F3FF);
  static const Color accentPurple = Color(0xFF4F4893);
}

class PasswordChangePage extends HookConsumerWidget {
  const PasswordChangePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(passwordChangeNotifierProvider);
    final notifier = ref.read(passwordChangeNotifierProvider.notifier);

    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();

    // 使用 ref.listen 监听状态变化，只在状态真正变化时显示通知
    ref.listen<PasswordChangeState>(passwordChangeNotifierProvider, (previous, next) {
      final notificationController = ref.read(gchSignalHubProvider);

      // 只在 errorMessage 从 null 变为有值时显示错误
      if (previous?.errorMessage != next.errorMessage && next.errorMessage != null) {
        notificationController.flashError(next.errorMessage!);
      }

      // 只在 successMessage 从 null 变为有值时显示成功并返回
      if (previous?.successMessage != next.successMessage && next.successMessage != null) {
        notificationController.flashSuccess(next.successMessage!);
        // Navigate back after showing success message
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            context.safePop();
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: _PageColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: REdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.rh),
                    _buildTitle(),
                    SizedBox(height: 24.rh),
                    _buildPasswordField(
                      controller: newPasswordController,
                      label: GchText.userSettingNewPassword,
                      hint: GchText.userSettingNewPasswordHint,
                      isVisible: state.isNewPasswordVisible,
                      onToggleVisibility: notifier.toggleNewPasswordVisibility,
                    ),
                    SizedBox(height: 16.rh),
                    _buildPasswordField(
                      controller: confirmPasswordController,
                      label: GchText.userSettingConfirmNewPassword,
                      hint: GchText.userSettingConfirmPasswordHint,
                      isVisible: state.isConfirmPasswordVisible,
                      onToggleVisibility: notifier.toggleConfirmPasswordVisibility,
                    ),
                    SizedBox(height: 32.rh),
                    SettingGradientButton(
                      text: state.isLoading
                          ? '...'
                          : GchText.userSettingConfirmChange,
                      onTap: state.isLoading
                          ? () {}
                          : () async {
                              final success = await notifier.changePassword(
                                newPassword: newPasswordController.text,
                                confirmPassword: confirmPasswordController.text,
                              );
                              if (success) {
                                newPasswordController.clear();
                                confirmPasswordController.clear();
                              }
                            },
                    ),
                    SizedBox(height: 20.rh),
                    _buildPasswordTips(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56.rh,
      padding: REdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: _PageColors.primaryText,
              size: 20.ri,
            ),
            onPressed: () => context.safePop(),
          ),
          Expanded(
            child: Text(
              GchText.userSettingChangePassword,
              style: TextStyle(
                color: _PageColors.primaryText,
                fontSize: 18.rf,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 48.rw),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          GchText.userSettingSetNewPassword,
          style: TextStyle(
            color: _PageColors.primaryText,
            fontSize: 22.rf,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.rh),
        Text(
          GchText.userSettingSecurityTip,
          style: TextStyle(
            color: _PageColors.secondaryText,
            fontSize: 14.rf,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _PageColors.primaryText,
            fontSize: 14.rf,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.rh),
        Container(
          height: 52.rh,
          decoration: BoxDecoration(
            color: _PageColors.cardBackground,
            borderRadius: BorderRadius.circular(12.rr),
            border: Border.all(color: _PageColors.inputBorder, width: 1),
          ),
          child: Row(
            children: [
              SizedBox(width: 16.rw),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: !isVisible,
                  style: TextStyle(
                    fontSize: 14.rf,
                    color: _PageColors.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 14.rf,
                      color: _PageColors.hintText,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggleVisibility,
                child: Padding(
                  padding: REdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    color: _PageColors.secondaryText,
                    size: 20.ri,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTips() {
    return Container(
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _PageColors.tipsBackground,
        borderRadius: BorderRadius.circular(12.rr),
        border: Border.all(
          color: _PageColors.accentPurple.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16.ri,
                color: _PageColors.accentPurple,
              ),
              SizedBox(width: 8.rw),
              Text(
                GchText.userSettingPasswordSuggestion,
                style: TextStyle(
                  color: _PageColors.primaryText,
                  fontSize: 14.rf,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.rh),
          _buildTipItem(GchText.userSettingMinLength),
          _buildTipItem(GchText.userSettingComplexRule),
          _buildTipItem(GchText.userSettingAvoidEasyPassword),
          _buildTipItem(GchText.userSettingSecurityTipDetail),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: REdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4.rw,
            height: 4.rh,
            margin: REdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: _PageColors.secondaryText,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.rw),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _PageColors.secondaryText,
                fontSize: 12.rf,
              ),
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
