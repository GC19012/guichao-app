import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

/// 渐变按钮 - 用于设置页面的登录/退出按钮
///
/// 从 setting_page.dart 中的内联按钮构建提取为独立组件。
/// UI 重构：背景由代码渐变改为 bg_login_button.webp 图片，
/// 文字颜色改为蓝色，布局改为固定高度容器。
/// 公共 API（text + onTap）保持不变。
///
/// 横屏适配：ConstrainedBox 限制最大宽度为设计稿短边，
/// 避免图片在横屏下 fitWidth 导致按钮高度不成比例。
class SettingGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const SettingGradientButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: DesignSpec.width.rw),
        child: GestureDetector(
          onTap: onTap,
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
              child: Padding(
                padding: REdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16.rf,
                    color: const Color(0xFF5969FF),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
