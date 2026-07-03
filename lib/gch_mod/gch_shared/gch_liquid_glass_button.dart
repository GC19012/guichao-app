import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

/// iOS 风格液态玻璃按钮
///
/// 三层结构：
/// | 层           | 效果                                          |
/// |--------------|-----------------------------------------------|
/// | ① 毛玻璃底层  | BackdropFilter 高斯模糊，透出背景内容            |
/// | ② 渐变填充    | 白→灰半透明渐变 + 白色半透明描边，模拟液态玻璃质感 |
/// | ③ 顶部高光    | 上→下白色渐变，模拟凸面折射                      |
///
/// 用法：
/// ```dart
/// LiquidGlassButton(
///   onTap: () {},
///   child: Text('确定', style: TextStyle(color: Colors.white)),
/// )
/// ```
class LiquidGlassButton extends StatefulWidget {
  const LiquidGlassButton({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.blurSigma = 15.0,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsets padding;
  final double blurSigma;
  final bool enabled;

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  bool get _isInteractive => widget.enabled && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final r = widget.borderRadius.rr;
    final sigma = widget.blurSigma;

    return GestureDetector(
      onTapDown: _isInteractive ? _onTapDown : null,
      onTapUp: _isInteractive ? _onTapUp : null,
      onTapCancel: _isInteractive ? _onTapCancel : null,
      onTap: _isInteractive
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedOpacity(
          opacity: !widget.enabled && widget.onTap != null ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0.1),
                      Colors.grey.withValues(alpha: 0.1),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
