import 'package:flutter/widgets.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

/// 预组装文字样式 — 基于 iOS 26 HIG Dynamic Type
///
/// 每个 getter 组合：
/// - **字号**：`IOSTextStyle.xxx.rf`（响应式）
/// - **字重**：遵循 iOS HIG 标准（headline = w600, 其余 = regular）
/// - **不设 fontFamily**：继承 GchLookEngine 的 locale 字体
/// - **不设颜色**：由调用方通过 `.copyWith(color: xxx)` 设置
///
/// 用法：
/// ```dart
/// AppTextStyles.headline                                    // 17pt semibold
/// AppTextStyles.subheadline.copyWith(color: Colors.black)   // 15pt regular + 黑色
/// ```
abstract final class AppTextStyles {
  /// Large Title - 34pt Regular — 极大标题
  static TextStyle get largeTitle =>
      TextStyle(fontSize: IOSTextStyle.largeTitle.rf);

  /// Title 1 - 28pt Regular — 一级标题
  static TextStyle get title1 =>
      TextStyle(fontSize: IOSTextStyle.title1.rf);

  /// Title 2 - 22pt Regular — 二级标题
  static TextStyle get title2 =>
      TextStyle(fontSize: IOSTextStyle.title2.rf);

  /// Title 3 - 20pt Regular — 三级标题
  static TextStyle get title3 =>
      TextStyle(fontSize: IOSTextStyle.title3.rf);

  /// Headline - 17pt Semibold — 区块标题
  static TextStyle get headline =>
      TextStyle(fontSize: IOSTextStyle.headline.rf, fontWeight: FontWeight.w600);

  /// Body - 17pt Regular — 正文
  static TextStyle get body =>
      TextStyle(fontSize: IOSTextStyle.body.rf);

  /// Callout - 16pt Regular — 按钮/输入框标签
  static TextStyle get callout =>
      TextStyle(fontSize: IOSTextStyle.callout.rf);

  /// Subheadline - 15pt Regular — 副标题/次要正文
  static TextStyle get subheadline =>
      TextStyle(fontSize: IOSTextStyle.subheadline.rf);

  /// Footnote - 13pt Regular — 脚注/辅助说明
  static TextStyle get footnote =>
      TextStyle(fontSize: IOSTextStyle.footnote.rf);

  /// Caption 1 - 12pt Regular — 小标签
  static TextStyle get caption1 =>
      TextStyle(fontSize: IOSTextStyle.caption1.rf);

  /// Caption 2 - 11pt Regular — 最小文字
  static TextStyle get caption2 =>
      TextStyle(fontSize: IOSTextStyle.caption2.rf);
}
