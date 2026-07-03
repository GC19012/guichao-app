library circle_flags;

import 'package:flutter/material.dart';

class CircleFlag extends StatelessWidget {
  final String isoCode;
  final double size;
  final ShapeBorder? shape;
  final Clip clipBehavior;

  const CircleFlag(
    this.isoCode, {
    super.key,
    this.size = 48,
    this.shape = const CircleBorder(eccentricity: 0),
    this.clipBehavior = Clip.antiAlias,
  });

  static Future<void> preload(Iterable<String> isoCodes) => Future.value();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
