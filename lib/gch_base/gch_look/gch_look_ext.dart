import 'package:flutter/material.dart';

class GchBtnTheme extends ThemeExtension<GchBtnTheme> {
  const GchBtnTheme({
    this.idleColor,
    this.connectedColor,
  });

  final Color? idleColor;
  final Color? connectedColor;

  static const GchBtnTheme light = GchBtnTheme(
    idleColor: Color(0xFF4a4d8b),
    connectedColor: Color(0xFF44a334),
  );

  @override
  ThemeExtension<GchBtnTheme> copyWith({
    Color? idleColor,
    Color? connectedColor,
  }) =>
      GchBtnTheme(
        idleColor: idleColor ?? this.idleColor,
        connectedColor: connectedColor ?? this.connectedColor,
      );

  @override
  ThemeExtension<GchBtnTheme> lerp(
    covariant ThemeExtension<GchBtnTheme>? other,
    double t,
  ) {
    if (other is! GchBtnTheme) {
      return this;
    }
    return GchBtnTheme(
      idleColor: Color.lerp(idleColor, other.idleColor, t),
      connectedColor: Color.lerp(connectedColor, other.connectedColor, t),
    );
  }
}
