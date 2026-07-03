import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

/// 设置菜单项 - 支持独立模式和分组模式
///
/// 独立模式（默认）：自带背景色和圆角，用于非分组场景。
/// 分组模式（inGroup=true）：无背景无圆角，由外部分组容器统一包裹。
///
/// 所有 onTap 回调逻辑由调用方传入，本组件不包含任何业务逻辑。
class SettingItem extends StatelessWidget {
  /// Material图标
  final IconData? icon;

  /// SVG图标路径
  final String? svgIcon;

  /// webp/png 图片图标路径（优先级高于 svgIcon 和 icon）
  final String? imageIcon;

  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? value;
  final VoidCallback? onTap;

  /// 是否已登录状态（影响独立模式下的背景透明度）
  final bool isLoggedIn;

  /// 是否在分组容器内使用（为 true 时不渲染自身背景和圆角）
  final bool inGroup;

  const SettingItem({
    super.key,
    this.icon,
    this.svgIcon,
    this.imageIcon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.value,
    this.onTap,
    this.isLoggedIn = true,
    this.inGroup = false,
  });

  // 静态化颜色常量 - 浅色主题
  static const Color _menuBg = Colors.white;
  static const Color _titleColor = Color(0xFF333333);
  static const Color _valueColor = Color(0xFF999999);
  static final Color _menuBgAlpha = Colors.white.withValues(alpha: 0.9);

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: inGroup ? null : BorderRadius.circular(16.rr),
        child: Padding(
          padding: REdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // 左侧图标 - 优先级: imageIcon > svgIcon > icon
              if (imageIcon != null)
                Image.asset(
                  imageIcon!,
                  width: 24.ri,
                  height: 24.ri,
                )
              else if (svgIcon != null)
                SvgPicture.asset(
                  svgIcon!,
                  width: 14.ri,
                  height: 14.ri,
                  colorFilter: ColorFilter.mode(
                    titleColor ?? _titleColor,
                    BlendMode.srcIn,
                  ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 16.ri,
                  color: titleColor ?? _titleColor,
                ),

              SizedBox(width: 12.rw),

              // 标题
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.rf,
                    color: titleColor ?? _titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 值（如果有）— 右对齐
              // Expanded 使 Text 填满分配空间，textAlign.right 才能生效
              if (value != null) ...[
                Expanded(
                  child: Text(
                    value!,
                    style: TextStyle(
                      color: _valueColor,
                      fontSize: 12.rf,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 8.rw),
              ],

              // 右箭头 - 使用 webp 图片与参考页面一致
              Image.asset(
                'assets/gch_pics/gch_72de26.webp',
                width: 16.ri,
                height: 16.ri,
              ),
            ],
          ),
        ),
      ),
    );

    // 分组模式下不需要外层容器
    if (inGroup) {
      return content;
    }

    // 独立模式：保持原有的容器背景和圆角
    return Container(
      height: 48.rh,
      decoration: BoxDecoration(
        color: isLoggedIn ? _menuBgAlpha : _menuBg,
        borderRadius: BorderRadius.circular(16.rr),
      ),
      child: content,
    );
  }
}
