import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:guichao/gch_base/gch_widget/gch_bone.dart';

class GchShimmer extends StatelessWidget {
  const GchShimmer({
    this.width,
    this.height,
    this.widthFactor,
    this.heightFactor,
    this.color,
    this.duration = const Duration(seconds: 1),
    super.key,
  });

  final double? width;
  final double? height;
  final double? widthFactor;
  final double? heightFactor;
  final Color? color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return GchBone(
      width: width,
      height: height,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
    )
        .animate(
          onPlay: (controller) => controller.loop(),
        )
        .shimmer(
          duration: duration,
          angle: 45,
          color: color ?? Theme.of(context).colorScheme.secondary,
        );
  }
}
