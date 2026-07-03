import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 首次安装隐私协议弹框
///
/// 以居中对话框形式展示，背景半透明遮罩可透出主页内容。
/// 用户点击"同意"继续使用，点击"不同意"退出 App。
class GchConsentPage extends StatelessWidget {
  final VoidCallback onAgreed;
  final VoidCallback onDeclined;
  final String title;
  final String agreeText;
  final String declineText;

  const GchConsentPage({
    super.key,
    required this.onAgreed,
    required this.onDeclined,
    required this.title,
    required this.agreeText,
    required this.declineText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC333333),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '温馨提示',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.7,
                  ),
                  children: [
                    const TextSpan(
                      text: '感谢您使用GUICHAO，在您使用我们的产品之前，请完整阅读并充分理解我们的',
                    ),
                    TextSpan(
                      text: '《服务条款》',
                      style: const TextStyle(color: Color(0xFF5969FF)),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(
                              Uri.parse('https://example.com/terms.html'),
                              mode: LaunchMode.inAppBrowserView,
                            ),
                    ),
                    const TextSpan(text: '和'),
                    TextSpan(
                      text: '《隐私协议》',
                      style: const TextStyle(color: Color(0xFF5969FF)),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(
                              Uri.parse('https://example.com/privacyA.html'),
                              mode: LaunchMode.inAppBrowserView,
                            ),
                    ),
                    const TextSpan(text: '的所有条款。'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '我们非常重视您的个人信息和隐私保护，我们将按照您同意的条款使用您的个人信息，为您提供服务。若您选择不同意，将无法使用我们的产品和服务。',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.7,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  // 不同意
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onDeclined,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF0F0F0),
                          foregroundColor: const Color(0xFF666666),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          declineText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 同意
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
                          onPressed: onAgreed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            agreeText,
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
      ),
    );
  }
}
