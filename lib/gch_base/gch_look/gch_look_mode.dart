import 'package:flutter/material.dart';
import 'package:guichao/gch_gen/gch_text.dart';

enum GchLookMode {
  system,
  light,
  dark,
  black;

  String present() => switch (this) {
        system => GchText.settingsGeneralThemeModesSystem,
        light => GchText.settingsGeneralThemeModesLight,
        dark => GchText.settingsGeneralThemeModesDark,
        black => GchText.settingsGeneralThemeModesBlack,
      };

  ThemeMode get flutterMode => switch (this) {
        system => ThemeMode.system,
        light => ThemeMode.light,
        dark => ThemeMode.dark,
        black => ThemeMode.dark,
      };

  bool get isBlack => this == black;
}
