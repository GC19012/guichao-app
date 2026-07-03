import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:sizer/sizer.dart';

/// 是否启用响应式自适应
/// 设为 false 或移除 sizer 时，所有扩展降级为硬编码原始数值
const bool _enableResponsive = true;

/// 响应式配置（全局）
abstract final class ResponsiveConfig {
  static double minScale = 0.6;
  static double maxScale = 1.6;
}

/// 设计稿基准尺寸（iPhone X）
abstract final class DesignSpec {
  static const double width = 375.0;
  static const double height = 812.0;
}

/// 通用自适应扩展 — sizer 中间层
///
/// 接收**绝对像素值**，按屏幕与设计稿的比例等比缩放。
/// 数字不变，只换后缀。换库或去掉自适应时，只改这一个文件。
///
/// 重要：sizer 的 .w/.h/.sp 是**百分比 API**（100.w = 屏幕宽度），
/// 不能直接 `200.w`（那是 200% 屏幕宽度 = 750px！）。
/// 本扩展将像素值除以设计稿基准，转换为正确的缩放结果。
///
/// 公式：value * (screenWidth / designWidth)
///   200.rw → 200 * (375/375) = 200px（375pt屏幕）
///   200.rw → 200 * (414/375) = 220.8px（414pt屏幕）
///
/// | 属性类型              | 后缀 | 示例                              |
/// |-----------------------|------|-----------------------------------|
/// | 宽度 / 水平间距       | .rw  | `width: 200.rw`                  |
/// | 高度 / 垂直间距       | .rh  | `height: 100.rh`                 |
/// | 字号                  | .rf  | `fontSize: 14.rf`                |
/// | 图标尺寸              | .ri  | `size: 24.ri`                    |
/// | 圆角                  | .rr  | `BorderRadius.circular(8.rr)`    |
/// | 水平 padding / margin | .rw  | `EdgeInsets.symmetric(h: 16.rw)` |
/// | 垂直 padding / margin | .rh  | `EdgeInsets.symmetric(v: 12.rh)` |
/// | 等比间距 (SizedBox)   | .rw  | `SizedBox(width: 8.rw)`          |
extension ResponsiveExtension on num {
  static double get _sizerSw => (100.0.w) / DesignSpec.width;
  static double get _sizerSh => (100.0.h) / DesignSpec.height;
  static double get _sizerSf => math.min(_sizerSw, _sizerSh);

  static double _safeScale(double candidate) {
    if (candidate.isNaN || candidate.isInfinite) return 1.0;
    if (candidate < ResponsiveConfig.minScale ||
        candidate > ResponsiveConfig.maxScale) {
      return 1.0;
    }
    return candidate;
  }

  static double get _sw => _safeScale(_sizerSw);
  static double get _sh => _safeScale(_sizerSh);
  static double get _sf => _safeScale(_sizerSf);

  /// 相对宽度 — 水平尺寸、水平间距、水平 padding/margin
  double get rw => _enableResponsive ? toDouble() * _sw : toDouble();

  /// 相对高度 — 垂直尺寸、垂直间距、垂直 padding/margin
  double get rh => _enableResponsive ? toDouble() * _sh : toDouble();

  /// 相对字号
  double get rf => _enableResponsive ? toDouble() * _sf : toDouble();

  /// 相对图标尺寸（与字号同比例缩放）
  double get ri => _enableResponsive ? toDouble() * _sf : toDouble();

  /// 相对圆角半径（与宽度同比例缩放）
  double get rr => _enableResponsive ? toDouble() * _sw : toDouble();

  /// 短边相对尺寸 — 版心约束等需要横竖屏一致宽度的场景
  ///
  /// 始终基于 min(screenW, screenH) / designWidth，
  /// 横竖屏返回相同值，适合 ConstrainedBox maxWidth 等场景。
  double get rs => _enableResponsive ? toDouble() * _sw : toDouble();
}

/// 响应式 EdgeInsets 快捷构造
///
/// 用法：
/// ```dart
/// padding: REdgeInsets.all(16),
/// padding: REdgeInsets.symmetric(horizontal: 20, vertical: 12),
/// margin:  REdgeInsets.only(left: 16, top: 8),
/// ```
abstract final class REdgeInsets {
  static EdgeInsets all(double value) =>
      EdgeInsets.all(value.rw);

  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: horizontal.rw, vertical: vertical.rh);

  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(
        left: left.rw,
        top: top.rh,
        right: right.rw,
        bottom: bottom.rh,
      );

  static EdgeInsets fromLTRB(double left, double top, double right, double bottom) =>
      EdgeInsets.fromLTRB(left.rw, top.rh, right.rw, bottom.rh);
}

/// iOS 26 标准排版尺寸（Apple HIG - Dynamic Type "Large" 默认级别）
///
/// 基于 Apple Human Interface Guidelines 的 Dynamic Type 文字样式。
/// 字体：San Francisco Pro — Flutter 在 iOS 上默认使用，无需额外设置 fontFamily。
///
/// 用法：作为 .rf 响应式缩放的基准值
/// ```dart
/// fontSize: IOSTextStyle.subheadline.rf  // 15pt × 屏幕缩放因子
/// fontSize: IOSTextStyle.caption1.rf     // 12pt × 屏幕缩放因子
/// ```
///
/// 参考：https://developer.apple.com/design/human-interface-guidelines/typography
abstract final class IOSTextStyle {
  /// Large Title - 34pt Regular
  static const double largeTitle = 34;

  /// Title 1 - 28pt Regular
  static const double title1 = 28;

  /// Title 2 - 22pt Regular
  static const double title2 = 22;

  /// Title 3 - 20pt Regular
  static const double title3 = 20;

  /// Headline - 17pt Semibold (w600)
  static const double headline = 17;

  /// Body - 17pt Regular
  static const double body = 17;

  /// Callout - 16pt Regular
  static const double callout = 16;

  /// Subheadline - 15pt Regular
  static const double subheadline = 15;

  /// Footnote - 13pt Regular
  static const double footnote = 13;

  /// Caption 1 - 12pt Regular
  static const double caption1 = 12;

  /// Caption 2 - 11pt Regular
  static const double caption2 = 11;
}

/// 带 clamp 的缩放因子辅助
/// 替代重复的 (100.w / 375).clamp(0.85, 1.0) 样板代码
abstract final class ResponsiveScale {
  static double get _screenWidth =>
      _enableResponsive ? math.min(100.0.w, 100.0.h) : DesignSpec.width;
  static double get _screenHeight =>
      _enableResponsive ? math.max(100.0.w, 100.0.h) : DesignSpec.height;

  static double width({
    double min = 0.85,
    double max = 1.0,
    double baseWidth = DesignSpec.width,
  }) {
    return (_screenWidth / baseWidth).clamp(min, max);
  }

  static double height({
    double min = 0.85,
    double max = 1.25,
    double baseHeight = DesignSpec.height,
  }) {
    return (_screenHeight / baseHeight).clamp(min, max);
  }
}
