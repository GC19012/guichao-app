import 'package:flutter/material.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_signal/gch_signal_hub.dart';
import 'package:guichao/gch_base/gch_nav/gch_routes.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_setting/gch_ctrl/gch_user_setting_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 退出登录确认对话框
///
/// 从 setting_page.dart 的 _showLogoutDialog 方法提取为独立组件，
/// 仅做 UI 组件化提取，所有业务逻辑（signOut调用、导航、错误通知）完全保持不变。
///
/// 样式对标首次安装的隐私协议弹框（GchConsentPage），保持全局视觉一致。
class SettingLogoutDialog {
  /// 显示退出登录确认对话框 - 业务逻辑完全不变
  static void show(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: const Color(0xCC333333),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题
                Text(
                  GchText.userSettingConfirmLogout,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 20),

                // 说明文本
                Text(
                  GchText.userSettingLogoutConfirm,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.7,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 28),

                // 按钮组
                Row(
                  children: [
                    // 取消
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF0F0F0),
                            foregroundColor: const Color(0xFF666666),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            GchText.userSettingCancel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 确认退出 - 渐变色主按钮
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8EB5FF), Color(0xFF6C8EFF)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();

                              // 调用notifier的登出功能
                              final success = await ref
                                  .read(userSettingNotifierProvider.notifier)
                                  .signOut();

                              if (success) {
                                // 登出成功，跳转到登录页
                                if (context.mounted) {
                                  const NavLoginRoute().go(context);
                                }
                              } else {
                                // 登出失败，显示错误提示
                                if (context.mounted) {
                                  final notificationController =
                                      ref.read(gchSignalHubProvider);
                                  notificationController
                                      .flashError(GchText.userSettingLogoutFailed);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              GchText.userSettingConfirm,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
