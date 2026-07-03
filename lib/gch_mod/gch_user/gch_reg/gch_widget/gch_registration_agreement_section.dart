// registration_agreement_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_aux/gch_uri.dart';
import 'package:guichao/gch_base/gch_schema/gch_const.dart';
import 'package:guichao/gch_gen/gch_text.dart';

/// 注册协议同意区域组件
class RegistrationAgreementSection extends ConsumerStatefulWidget {
  final bool agreed;
  final VoidCallback onToggle;
  final VoidCallback? onUserAgreementTap;
  final VoidCallback? onPrivacyPolicyTap;

  const RegistrationAgreementSection({
    super.key,
    required this.agreed,
    required this.onToggle,
    this.onUserAgreementTap,
    this.onPrivacyPolicyTap,
  });

  @override
  ConsumerState<RegistrationAgreementSection> createState() => RegistrationAgreementSectionState();
}

class RegistrationAgreementSectionState extends ConsumerState<RegistrationAgreementSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// 触发抖动动画
  void shake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = _shakeAnimation.value * 10 *
            ((_shakeAnimation.value * 10).toInt() % 2 == 0 ? 1 : -1) *
            (1 - _shakeAnimation.value);
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCheckbox(),
          SizedBox(width: 3.75.rw), // 减少间距，因为复选框已有padding
          Expanded(child: _buildAgreementText()),
        ],
      ),
    );
  }

  /// 构建复选框（图片风格，与 LoginPage 一致）
  /// 扩大可点击区域至 36ri，但图片素材保持 15ri 不变
  Widget _buildCheckbox() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onToggle,
      child: SizedBox(
        width: 36.ri,
        height: 36.ri,
        child: Center(
          child: widget.agreed
              ? Image.asset(
                  'assets/gch_pics/gch_ede35d.webp',
                  width: 15.ri,
                  height: 15.ri,
                )
              : Container(
                  width: 15.ri,
                  height: 15.ri,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 1.5,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  /// 构建协议文本
  Widget _buildAgreementText() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            GchText.userLoginAgreePrefix,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.rf,
            ),
          ),
          _buildLinkText(
            GchText.userLoginTerms,
            widget.onUserAgreementTap ?? () => UriUtils.tryLaunch(Uri.parse(GchConst.termsUrl)),
          ),
          Text(
            GchText.userCommonAnd,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.rf,
            ),
          ),
          _buildLinkText(
            GchText.userLoginPrivacy,
            widget.onPrivacyPolicyTap ?? () => UriUtils.tryLaunch(Uri.parse(GchConst.privacyUrl)),
          ),
        ],
      ),
    );
  }

  /// 构建链接文本（与 LoginPage 一致，无下划线）
  Widget _buildLinkText(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF6366F1),
          fontSize: 14.rf,
        ),
      ),
    );
  }

}
