import 'package:flutter/material.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_ctrl/gch_user_setting_notifier.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_aux/gch_nav_ext.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 账号注销页面 - 浅色主题，与 setting_page 风格一致
///
/// **用户流程:**
/// 1. 阅读注销说明和条件
/// 2. 勾选同意复选框
/// 3. 点击"开始注销"按钮
/// 4. 确认后执行注销
class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  bool _agreedToTerms = false;
  bool _isProcessing = false;

  // 与 setting_page 一致的浅色调
  static const _pageBg = Color(0xFFF1EFF9);
  static const _textDark = Color(0xFF333333);
  static const _textGray = Color(0xFF9A98AA);
  static const _accentPurple = Color(0xFF4F4893);
  static const _borderGray = Color(0xFFEEEEEE);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: _pageBg,
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
                    Text(
                      GchText.userSettingDeleteAccountContent,
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 15.rf,
                        height: 1.6,
                        letterSpacing: 0.3.rw,
                      ),
                    ),
                    SizedBox(height: 40.rh),
                  ],
                ),
              ),
            ),
            _buildBottomSection(context),
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
              color: _textDark,
              size: 20.ri,
            ),
            onPressed: () => context.safePop(),
          ),
          Expanded(
            child: Text(
              GchText.userSettingDeleteAccountTitle,
              style: TextStyle(
                color: _textDark,
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

  Widget _buildBottomSection(BuildContext context) {
    return Container(
      padding: REdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _borderGray, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 同意复选框
          GestureDetector(
            onTap: () {
              setState(() {
                _agreedToTerms = !_agreedToTerms;
              });
            },
            child: Container(
              padding: REdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _pageBg,
                borderRadius: BorderRadius.circular(12.rr),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.rw,
                    height: 24.rh,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _agreedToTerms
                            ? _accentPurple
                            : _textGray,
                        width: 2,
                      ),
                      color: _agreedToTerms
                          ? _accentPurple
                          : Colors.transparent,
                    ),
                    child: _agreedToTerms
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16.ri,
                          )
                        : null,
                  ),
                  SizedBox(width: 12.rw),
                  Expanded(
                    child: Text(
                      GchText.userSettingDeleteAccountCheckbox,
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 14.rf,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.rh),

          // 开始注销按钮
          SizedBox(
            width: double.infinity,
            height: 52.rh,
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () => _handleDeleteAccount(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _agreedToTerms && !_isProcessing
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFD1D5DB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.rr),
                ),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFD1D5DB),
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: 20.rw,
                      height: 20.rh,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      GchText.userSettingDeleteAccountButton,
                      style: TextStyle(
                        fontSize: 16.rf,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理删除账号
  Future<void> _handleDeleteAccount(
    BuildContext context,
  ) async {
    if (!_agreedToTerms) {
      final notificationController = ref.read(gchSignalHubProvider);
      notificationController.flashError(GchText.userSettingMustAgreeTerms);
      return;
    }

    // 二次确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.rr),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: const Color(0xFFEF4444),
              size: 28.ri,
            ),
            SizedBox(width: 12.rw),
            Text(
              GchText.userSettingDeleteAccountDialogTitle,
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        content: Text(
          GchText.userSettingDeleteAccountDialogContent,
          style: TextStyle(
            color: _textGray,
            fontSize: 15.rf,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              GchText.userSettingCancel,
              style: const TextStyle(color: _textGray),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text(GchText.userSettingDeleteAccountConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await ref
          .read(userSettingNotifierProvider.notifier)
          .deleteAccount();

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      final notificationController = ref.read(gchSignalHubProvider);
      if (success) {
        notificationController.flashSuccess(GchText.userSettingDeleteAccountSuccess);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            const NavLoginRoute().go(context);
          }
        });
      } else {
        notificationController.flashError(GchText.userSettingDeleteAccountFailed);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      final notificationController = ref.read(gchSignalHubProvider);
      notificationController.flashError('${GchText.userSettingDeleteAccountFailed}: $e');
    }
  }
}
