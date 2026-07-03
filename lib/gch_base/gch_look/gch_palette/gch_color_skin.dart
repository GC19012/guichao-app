import 'package:flutter/material.dart';

/// A complete color palette definition. Pure data, no logic.
///
/// To add a new skin, simply add a new `static const` instance.
class GchColorSkin {
  const GchColorSkin({
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
    // Semantic status (fixed, not affected by tone)
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    // Signal quality (fixed, not affected by tone)
    required this.signalExcellent,
    required this.signalGood,
    required this.signalFair,
    required this.signalPoor,
    required this.signalBad,
  });

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

  // ===== Preset skins =====

  /// Dark blue tech (default dark theme, aligned with UserThemeColors)
  static const deepBlue = GchColorSkin(
    primaryBackground: Color(0xFF0A1628),
    secondaryBackground: Color(0xFF1E293B),
    cardBackground: Color(0xFF1E293B),
    inputBackground: Color(0xFF1E293B),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    textAccent: Color(0xFF60A5FA),
    brandPrimary: Color(0xFF6B5FED),
    brandAccent: Color(0xFF3B82F6),
    gradientStart: Color(0xFF7B61FF),
    gradientEnd: Color(0xFF5AA1FF),
    border: Color(0xFF334155),
    divider: Color(0xFF2A2A2A),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
    signalExcellent: Color(0xFF34C759),
    signalGood: Color(0xFF5DD68A),
    signalFair: Color(0xFFFBBF24),
    signalPoor: Color(0xFFF97316),
    signalBad: Color(0xFFEF4444),
  );

  /// Classic light (aligned with ProxyNodeColors + LoginPage)
  static const classicLight = GchColorSkin(
    primaryBackground: Color(0xFFF4F6FB),
    secondaryBackground: Color(0xFFF7F9FC),
    cardBackground: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFF5F5F5),
    textPrimary: Color(0xFF1F2430),
    textSecondary: Color(0xFF6C7485),
    textMuted: Color(0xFFA0A8B8),
    textAccent: Color(0xFF5969FF),
    brandPrimary: Color(0xFF6B5FED),
    brandAccent: Color(0xFF3B82F6),
    gradientStart: Color(0xFF7B61FF),
    gradientEnd: Color(0xFF5AA1FF),
    border: Color(0xFFE5EAF2),
    divider: Color(0xFFE0E0E0),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
    signalExcellent: Color(0xFF34C759),
    signalGood: Color(0xFF5DD68A),
    signalFair: Color(0xFFFBBF24),
    signalPoor: Color(0xFFF97316),
    signalBad: Color(0xFFEF4444),
  );
}
