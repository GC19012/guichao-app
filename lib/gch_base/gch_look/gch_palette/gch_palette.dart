import 'package:flutter/material.dart';
import 'package:guichao/gch_base/gch_look/gch_palette/gch_color_skin.dart';
import 'package:guichao/gch_base/gch_look/gch_palette/gch_tone.dart';

/// Unified ThemeExtension that combines a [GchColorSkin] with a [GchTone].
///
/// Access via `context.colors` (see theme_context_extensions.dart).
class GchPalette extends ThemeExtension<GchPalette> {
  const GchPalette({
    // Background
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.cardBackground,
    required this.inputBackground,
    // Text
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textAccent,
    // Brand
    required this.brandPrimary,
    required this.brandAccent,
    required this.gradientStart,
    required this.gradientEnd,
    // Border
    required this.border,
    required this.divider,
    // Semantic status
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    // Signal quality
    required this.signalExcellent,
    required this.signalGood,
    required this.signalFair,
    required this.signalPoor,
    required this.signalBad,
  });

  /// Build from a [GchColorSkin] with optional [GchTone].
  factory GchPalette.fromSkin(GchColorSkin skin, {GchTone tone = GchTone.none}) {
    return GchPalette(
      // Background/text/brand/border are affected by tone
      primaryBackground: tone.apply(skin.primaryBackground),
      secondaryBackground: tone.apply(skin.secondaryBackground),
      cardBackground: tone.apply(skin.cardBackground),
      inputBackground: tone.apply(skin.inputBackground),
      textPrimary: tone.apply(skin.textPrimary),
      textSecondary: tone.apply(skin.textSecondary),
      textMuted: tone.apply(skin.textMuted),
      textAccent: tone.apply(skin.textAccent),
      brandPrimary: tone.apply(skin.brandPrimary),
      brandAccent: tone.apply(skin.brandAccent),
      gradientStart: tone.apply(skin.gradientStart),
      gradientEnd: tone.apply(skin.gradientEnd),
      border: tone.apply(skin.border),
      divider: tone.apply(skin.divider),
      // Semantic status and signal colors are fixed
      success: skin.success,
      warning: skin.warning,
      error: skin.error,
      info: skin.info,
      signalExcellent: skin.signalExcellent,
      signalGood: skin.signalGood,
      signalFair: skin.signalFair,
      signalPoor: skin.signalPoor,
      signalBad: skin.signalBad,
    );
  }

  // --- Background ---
  final Color primaryBackground;
  final Color secondaryBackground;
  final Color cardBackground;
  final Color inputBackground;

  // --- Text ---
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textAccent;

  // --- Brand ---
  final Color brandPrimary;
  final Color brandAccent;
  final Color gradientStart;
  final Color gradientEnd;

  // --- Border ---
  final Color border;
  final Color divider;

  // --- Semantic status ---
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // --- Signal quality ---
  final Color signalExcellent;
  final Color signalGood;
  final Color signalFair;
  final Color signalPoor;
  final Color signalBad;

  /// Returns a signal color based on network delay in milliseconds.
  Color signalByDelay(int delay) {
    if (delay <= 0 || delay > 65000) return signalBad;
    if (delay < 100) return signalExcellent;
    if (delay < 200) return signalGood;
    if (delay < 500) return signalFair;
    if (delay < 1000) return signalPoor;
    return signalBad;
  }

  /// Primary brand gradient shortcut.
  LinearGradient get primaryGradient => LinearGradient(
        colors: [gradientStart, gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  GchPalette copyWith({
    Color? primaryBackground,
    Color? secondaryBackground,
    Color? cardBackground,
    Color? inputBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textAccent,
    Color? brandPrimary,
    Color? brandAccent,
    Color? gradientStart,
    Color? gradientEnd,
    Color? border,
    Color? divider,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? signalExcellent,
    Color? signalGood,
    Color? signalFair,
    Color? signalPoor,
    Color? signalBad,
  }) {
    return GchPalette(
      primaryBackground: primaryBackground ?? this.primaryBackground,
      secondaryBackground: secondaryBackground ?? this.secondaryBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      inputBackground: inputBackground ?? this.inputBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textAccent: textAccent ?? this.textAccent,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandAccent: brandAccent ?? this.brandAccent,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      signalExcellent: signalExcellent ?? this.signalExcellent,
      signalGood: signalGood ?? this.signalGood,
      signalFair: signalFair ?? this.signalFair,
      signalPoor: signalPoor ?? this.signalPoor,
      signalBad: signalBad ?? this.signalBad,
    );
  }

  @override
  GchPalette lerp(covariant GchPalette? other, double t) {
    if (other is! GchPalette) return this;
    return GchPalette(
      primaryBackground: Color.lerp(primaryBackground, other.primaryBackground, t)!,
      secondaryBackground: Color.lerp(secondaryBackground, other.secondaryBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textAccent: Color.lerp(textAccent, other.textAccent, t)!,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandAccent: Color.lerp(brandAccent, other.brandAccent, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      signalExcellent: Color.lerp(signalExcellent, other.signalExcellent, t)!,
      signalGood: Color.lerp(signalGood, other.signalGood, t)!,
      signalFair: Color.lerp(signalFair, other.signalFair, t)!,
      signalPoor: Color.lerp(signalPoor, other.signalPoor, t)!,
      signalBad: Color.lerp(signalBad, other.signalBad, t)!,
    );
  }
}
