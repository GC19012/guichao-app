import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

/// 通用胶囊按钮 — 基于 button.png 多层像素采样还原
///
/// 五层立体结构（从底到顶）：
///
/// | 层        | 效果                                        |
/// |-----------|---------------------------------------------|
/// | ① 外发光  | #5969FF 四周柔光，底部加重                    |
/// | ② 主体    | 垂直渐变 #E8EDFD → #CDD7FC → #D0D9FC → #E8EDFD |
/// | ③ 内侧光晕 | 白色描边 blur 内扩，模拟玻璃边缘折射          |
/// | ④ 高光描边 | 1px 白色 88% 描边                            |
/// | ⑤ 中心反光 | 上半部白色 → 透明渐变，模拟凸面高光            |
///
/// 用法：
/// ```dart
/// GchBtn(
///   onTap: () {},
///   child: Text('提交', style: TextStyle(color: Colors.black)),
/// )
/// ```
class GchBtn extends StatelessWidget {
  const GchBtn({
    super.key,
    required this.onTap,
    required this.child,
    this.enabled = true,
    this.height,
    this.fillGradient,
    this.glowColor,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool enabled;

  /// 按钮高度，默认 52.rh
  final double? height;

  /// 自定义填充渐变，覆盖默认主体渐变
  final Gradient? fillGradient;

  /// 自定义外发光颜色，覆盖默认 #5969FF
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final h = height ?? 52.rh;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: CustomPaint(
          painter: _CommonButtonPainter(
            buttonHeight: h,
            fillGradient: fillGradient,
            glowColor: glowColor ?? const Color(0xFF5969FF),
          ),
          child: SizedBox(
            height: h,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// 五层质感绘制器
class _CommonButtonPainter extends CustomPainter {
  _CommonButtonPainter({
    required this.buttonHeight,
    this.fillGradient,
    required this.glowColor,
  });

  final double buttonHeight;
  final Gradient? fillGradient;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = buttonHeight;
    final r = h / 2;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // ① 外发光 — 四周柔光 + 底部加重
    _drawOuterGlow(canvas, rrect, w, h);

    // ② 主体填充 — 亮色渐变
    _drawBody(canvas, rrect, w, h);

    // ③ 内侧光晕 — clip 内模糊白边
    _drawInnerGlow(canvas, rrect);

    // ④ 高光描边 — 白色 88%
    _drawBorderStroke(canvas, rrect);

    // ⑤ 中心反光 — 上半部白色高光渐变
    _drawCenterHighlight(canvas, w, h, r);
  }

  /// ① 外发光：四周 + 底部加重
  void _drawOuterGlow(Canvas canvas, RRect rrect, double w, double h) {
    // 四周均匀发光
    final allGlow = Paint()
      ..color = glowColor.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(rrect, allGlow);

    // 底部加重阴影
    final bottomGlow = Paint()
      ..color = glowColor.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rrect.shift(const Offset(0, 3)), bottomGlow);
  }

  /// ② 主体填充
  void _drawBody(Canvas canvas, RRect rrect, double w, double h) {
    final fill = Paint()
      ..shader = (fillGradient ??
              const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFDBE2FB), // 顶部亮边
                  Color(0xFFB8C5F8), // 上部主体
                  Color(0xFFBCC8F9), // 下部主体
                  Color(0xFFDBE2FB), // 底部亮边
                ],
                stops: [0.0, 0.15, 0.85, 1.0],
              ))
          .createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(rrect, fill);
  }

  /// ③ 内侧光晕：clip 后画模糊白描边
  void _drawInnerGlow(Canvas canvas, RRect rrect) {
    canvas.save();
    canvas.clipRRect(rrect);
    final glow = Paint()
      ..color = const Color(0xB0FFFFFF) // 白 69%
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(rrect, glow);
    canvas.restore();
  }

  /// ④ 高光描边：外侧深色锐边 + 内侧亮边，形成锐利轮廓
  void _drawBorderStroke(Canvas canvas, RRect rrect) {
    // 外侧深色锐边 — 与主体形成明度差，产生锐度
    final outerEdge = Paint()
      ..color = const Color(0x409099CC) // 深蓝灰 25%
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, outerEdge);

    // 内侧亮边 — 缩进 1px，白色高光
    final innerRRect = rrect.deflate(1.0);
    final innerEdge = Paint()
      ..color = const Color(0xC0FFFFFF) // 白 75%
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(innerRRect, innerEdge);
  }

  /// ⑤ 中心反光：上半部白色椭圆渐变
  void _drawCenterHighlight(Canvas canvas, double w, double h, double r) {
    final highlightRect = Rect.fromLTWH(w * 0.1, 0, w * 0.8, h * 0.55);
    final highlightRRect =
        RRect.fromRectAndRadius(highlightRect, Radius.circular(r));

    final highlight = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x50FFFFFF), // 白 31%
          Color(0x18FFFFFF), // 白 9%
          Color(0x00FFFFFF), // 透明
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(highlightRect);

    canvas.drawRRect(highlightRRect, highlight);
  }

  @override
  bool shouldRepaint(covariant _CommonButtonPainter old) =>
      buttonHeight != old.buttonHeight ||
      fillGradient != old.fillGradient ||
      glowColor != old.glowColor;
}
