import 'package:flutter/material.dart';
import 'package:guichao/gch_base/gch_look/gch_look_mode.dart';
import 'package:guichao/gch_base/gch_look/gch_palette/gch_palette.dart';
import 'package:guichao/gch_base/gch_look/gch_palette/gch_color_skin.dart';
import 'package:guichao/gch_base/gch_look/gch_palette/gch_tone.dart';
import 'package:guichao/gch_base/gch_look/gch_look_ext.dart';

class GchLookEngine {
  GchLookEngine(this.mode, this.fontFamily, {this.skin = GchColorSkin.deepBlue, this.tone = GchTone.none});
  final GchLookMode mode;
  final String fontFamily;
  final GchColorSkin skin;
  final GchTone tone;

  ThemeData dayTheme(ColorScheme? lightColorScheme) {
    final ColorScheme scheme = lightColorScheme ??
        ColorScheme.fromSeed(seedColor: const Color(0xFF0F7B6C));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF5969FF),
        unselectedItemColor: Color(0xFF9E9E9E),
      ),
      extensions: <ThemeExtension<dynamic>>{
        GchBtnTheme.light,
        GchPalette.fromSkin(skin, tone: tone),
      },
    );
  }

  ThemeData nightTheme(ColorScheme? darkColorScheme) {
    final ColorScheme scheme = darkColorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F7B6C),
          brightness: Brightness.dark,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          mode.isBlack ? Colors.black : scheme.surface,
      fontFamily: fontFamily,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF5969FF),
        unselectedItemColor: Color(0xFF9E9E9E),
      ),
      extensions: <ThemeExtension<dynamic>>{
        GchBtnTheme.light,
        GchPalette.fromSkin(skin, tone: tone),
      },
    );
  }
}
