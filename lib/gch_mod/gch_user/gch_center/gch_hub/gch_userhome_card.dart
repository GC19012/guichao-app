import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

class UserHomeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final List<Color>? gradientColors;

  const UserHomeCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius = 16,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? REdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: padding ?? REdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ??
              [
                Colors.black45, // 深蓝
                Colors.blueAccent, // 亮蓝
              ],
        ),
        borderRadius: BorderRadius.circular(borderRadius.rr),
      ),
      child: child,
    );
  }
}
