import 'package:flutter/material.dart';

/// 用户模块统一颜色主题 - 深蓝科技风格
class UserThemeColors {
  // ===== 背景色系 =====
  /// 主背景色 - 深邃蓝黑
  static const Color primaryBackground = Color(0xFF0A1628);
  /// 次要背景色 - 深蓝灰
  static const Color secondaryBackground = Color(0xFF1E293B);
  /// 卡片背景色 - 半透明深蓝
  static Color cardBackground = const Color(0xFF1E3A8A).withValues(alpha: 0.2);
  /// 底部导航背景
  static const Color bottomNavBackground = Color(0xFF1A1A1A);

  // ===== 渐变色系 =====
  /// 主渐变 - 蓝色科技感
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 紫蓝渐变 - 用于高亮
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF4A6CF7), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 深蓝渐变 - 用于背景
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E293B),
    ],
  );

  /// 绿色渐变 - 用于成功状态
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857)],
  );

  // ===== 文字色系 =====
  /// 主文字色 - 白色
  static const Color primaryText = Colors.white;
  /// 次要文字色 - 灰白
  static const Color secondaryText = Color(0xFF94A3B8);
  /// 禁用文字色 - 深灰
  static const Color disabledText = Color(0xFF64748B);
  /// 高亮文字色 - 亮蓝
  static const Color accentText = Color(0xFF60A5FA);

  // ===== 透明度变体 =====
  /// 60% 透明度主文字色
  static Color primaryText60 = primaryText.withOpacity(0.6);
  /// 24% 透明度主文字色
  static Color primaryText24 = primaryText.withOpacity(0.24);
  /// 70% 透明度主文字色
  static Color primaryText70 = primaryText.withOpacity(0.7);
  /// 12% 透明度主文字色
  static Color primaryText12 = primaryText.withOpacity(0.12);

  // ===== 边框色系 =====
  /// 主边框色 - 深蓝边框
  static Color primaryBorder = const Color(0xFF1E3A8A).withValues(alpha: 0.3);
  /// 次要边框色 - 灰色边框
  static const Color secondaryBorder = Color(0xFF334155);
  /// 分割线颜色
  static const Color divider = Color(0xFF2A2A2A);

  // ===== 状态色系 =====
  /// 成功色 - 绿色
  static const Color success = Color(0xFF10B981);
  /// 警告色 - 橙色
  static const Color warning = Color(0xFFF59E0B);
  /// 错误色 - 红色
  static const Color error = Color(0xFFEF4444);
  /// 信息色 - 蓝色
  static const Color info = Color(0xFF3B82F6);

  // ===== 阴影效果 =====
  /// 卡片阴影
  static BoxShadow cardShadow = BoxShadow(
    color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
    blurRadius: 20,
    spreadRadius: 0,
    offset: const Offset(0, 8),
  );

  /// 按钮阴影
  static BoxShadow buttonShadow = BoxShadow(
    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  /// 底部导航阴影
  static BoxShadow bottomNavShadow = BoxShadow(
    color: const Color(0xFF000000).withValues(alpha: 0.3),
    blurRadius: 8,
    offset: const Offset(0, -2),
  );

  // ===== 组件样式 =====
  /// 获取卡片装饰
  static BoxDecoration getCardDecoration({
    BorderRadius? borderRadius,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      gradient: gradient ?? backgroundGradient,
      boxShadow: [cardShadow],
      border: Border.all(color: primaryBorder, width: 1),
    );
  }

  /// 获取按钮装饰
  static BoxDecoration getButtonDecoration({
    bool isActive = false,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      gradient: isActive ? primaryGradient : null,
      color: isActive ? null : cardBackground,
      boxShadow: isActive ? [buttonShadow] : null,
      border: Border.all(
        color: isActive ? Colors.transparent : secondaryBorder,
        width: 1,
      ),
    );
  }

  /// 获取输入框装饰
  static InputDecoration getInputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: disabledText),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: info, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
    );
  }

  /// 获取AppBar样式
  static AppBar getAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      iconTheme: const IconThemeData(color: primaryText),
    );
  }
}

/// 页面基础容器 - 提供统一的背景样式
class UserThemedContainer extends StatelessWidget {
  final Widget child;
  final bool useGradient;
  final EdgeInsetsGeometry? padding;

  const UserThemedContainer({
    super.key,
    required this.child,
    this.useGradient = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: useGradient ? null : UserThemeColors.primaryBackground,
        gradient: useGradient ? UserThemeColors.backgroundGradient : null,
      ),
      padding: padding,
      child: child,
    );
  }
}

/// 科技感光晕效果
class TechGlowEffect extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double blurRadius;

  const TechGlowEffect({
    super.key,
    required this.child,
    this.glowColor = UserThemeColors.info,
    this.blurRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: blurRadius,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}