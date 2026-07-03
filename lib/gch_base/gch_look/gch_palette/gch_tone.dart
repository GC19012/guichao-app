import 'package:flutter/material.dart';

/// Pure function: applies a brightness shift to a color.
///
/// [delta] ranges from -1.0 (darkest) to 1.0 (lightest).
/// Positive values lerp toward white, negative toward black.
class GchTone {
  const GchTone(this.delta)
      : assert(delta >= -1.0 && delta <= 1.0, 'delta must be in [-1.0, 1.0]');

  final double delta;

  Color apply(Color color) {
    if (delta == 0.0) return color;
    final target = delta > 0 ? Colors.white : Colors.black;
    return Color.lerp(color, target, delta.abs())!;
  }

  static const none = GchTone(0.0);
}
