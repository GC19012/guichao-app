// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';
import 'dart:ui' show Color;

/// Utility class for color manipulation and conversion.
class GchColorUtil {
  GchColorUtil._();

  /// Parses a hex color string (#RGB, #RRGGBB, #RRGGBBAA) into a [Color].
  static Color fromHex(String hex) {
    final s = hex.trim().replaceFirst('#', '');
    if (s.length == 3) {
      final r = int.parse(s[0] * 2, radix: 16);
      final g = int.parse(s[1] * 2, radix: 16);
      final b = int.parse(s[2] * 2, radix: 16);
      return Color.fromARGB(255, r, g, b);
    } else if (s.length == 6) {
      final value = int.parse(s, radix: 16);
      return Color(0xFF000000 | value);
    } else if (s.length == 8) {
      final value = int.parse(s, radix: 16);
      final a = (value >> 24) & 0xFF;
      final r = (value >> 16) & 0xFF;
      final g = (value >> 8) & 0xFF;
      final b = value & 0xFF;
      return Color.fromARGB(a, r, g, b);
    }
    throw ArgumentError('Invalid hex color: $hex');
  }

  /// Converts a [Color] to a hex string.
  static String toHex(Color color, {bool includeAlpha = false}) {
    final r = color.red.toRadixString(16).padLeft(2, '0');
    final g = color.green.toRadixString(16).padLeft(2, '0');
    final b = color.blue.toRadixString(16).padLeft(2, '0');
    if (includeAlpha) {
      final a = color.alpha.toRadixString(16).padLeft(2, '0');
      return '#$r$g$b$a'.toUpperCase();
    }
    return '#$r$g$b'.toUpperCase();
  }

  /// Creates a [Color] from HSL values (h: 0-360, s: 0-1, l: 0-1, a: 0-1).
  static Color fromHSL(double h, double s, double l, {double a = 1.0}) {
    final hNorm = h / 360.0;
    double r, g, b;
    if (s == 0) {
      r = g = b = l;
    } else {
      double hue2rgb(double p, double q, double t) {
        double tt = t;
        if (tt < 0) tt += 1;
        if (tt > 1) tt -= 1;
        if (tt < 1 / 6) return p + (q - p) * 6 * tt;
        if (tt < 1 / 2) return q;
        if (tt < 2 / 3) return p + (q - p) * (2 / 3 - tt) * 6;
        return p;
      }

      final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      final p = 2 * l - q;
      r = hue2rgb(p, q, hNorm + 1 / 3);
      g = hue2rgb(p, q, hNorm);
      b = hue2rgb(p, q, hNorm - 1 / 3);
    }
    return Color.fromARGB(
      (a * 255).round().clamp(0, 255),
      (r * 255).round().clamp(0, 255),
      (g * 255).round().clamp(0, 255),
      (b * 255).round().clamp(0, 255),
    );
  }

  /// Converts a [Color] to HSL components.
  static ({double h, double s, double l, double a}) toHSL(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;
    final a = color.alpha / 255.0;
    final max = [r, g, b].reduce((x, y) => x > y ? x : y);
    final min = [r, g, b].reduce((x, y) => x < y ? x : y);
    final l = (max + min) / 2;
    double h = 0, s = 0;
    if (max != min) {
      final d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      if (max == r) {
        h = (g - b) / d + (g < b ? 6 : 0);
      } else if (max == g) {
        h = (b - r) / d + 2;
      } else {
        h = (r - g) / d + 4;
      }
      h /= 6;
    }
    return (h: h * 360, s: s, l: l, a: a);
  }

  /// Creates a [Color] from HSV values (h: 0-360, s: 0-1, v: 0-1).
  static Color fromHSV(double h, double s, double v) {
    final hh = h / 60.0;
    final i = hh.floor() % 6;
    final f = hh - hh.floor();
    final p = v * (1 - s);
    final q = v * (1 - f * s);
    final t = v * (1 - (1 - f) * s);
    double r, g, b;
    switch (i) {
      case 0:
        r = v; g = t; b = p;
        break;
      case 1:
        r = q; g = v; b = p;
        break;
      case 2:
        r = p; g = v; b = t;
        break;
      case 3:
        r = p; g = q; b = v;
        break;
      case 4:
        r = t; g = p; b = v;
        break;
      default:
        r = v; g = p; b = q;
    }
    return Color.fromARGB(
      255,
      (r * 255).round().clamp(0, 255),
      (g * 255).round().clamp(0, 255),
      (b * 255).round().clamp(0, 255),
    );
  }

  /// Converts a [Color] to HSV components.
  static ({double h, double s, double v}) toHSV(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;
    final max = [r, g, b].reduce((x, y) => x > y ? x : y);
    final min = [r, g, b].reduce((x, y) => x < y ? x : y);
    final d = max - min;
    double h = 0;
    final s = max == 0 ? 0.0 : d / max;
    final v = max;
    if (d != 0) {
      if (max == r) {
        h = (g - b) / d + (g < b ? 6 : 0);
      } else if (max == g) {
        h = (b - r) / d + 2;
      } else {
        h = (r - g) / d + 4;
      }
      h /= 6;
    }
    return (h: h * 360, s: s, v: v);
  }

  /// Returns a lighter version of [color] by [amount] (0.0 - 1.0).
  static Color lighter(Color color, double amount) {
    final hsl = toHSL(color);
    final newL = (hsl.l + amount).clamp(0.0, 1.0);
    return fromHSL(hsl.h, hsl.s, newL, a: hsl.a);
  }

  /// Returns a darker version of [color] by [amount] (0.0 - 1.0).
  static Color darker(Color color, double amount) {
    final hsl = toHSL(color);
    final newL = (hsl.l - amount).clamp(0.0, 1.0);
    return fromHSL(hsl.h, hsl.s, newL, a: hsl.a);
  }

  /// Mixes two colors by [ratio] (0.0 = all [a], 1.0 = all [b]).
  static Color mix(Color a, Color b, double ratio) {
    final r = ratio.clamp(0.0, 1.0);
    return Color.fromARGB(
      (a.alpha + (b.alpha - a.alpha) * r).round().clamp(0, 255),
      (a.red + (b.red - a.red) * r).round().clamp(0, 255),
      (a.green + (b.green - a.green) * r).round().clamp(0, 255),
      (a.blue + (b.blue - a.blue) * r).round().clamp(0, 255),
    );
  }

  /// Returns the complementary color (opposite on the hue wheel).
  static Color complement(Color color) {
    final hsl = toHSL(color);
    final newH = (hsl.h + 180) % 360;
    return fromHSL(newH, hsl.s, hsl.l, a: hsl.a);
  }

  /// Computes relative luminance as per WCAG 2.1.
  static double luminance(Color color) {
    double linearize(double channel) {
      final c = channel / 255.0;
      return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = linearize(color.red.toDouble());
    final g = linearize(color.green.toDouble());
    final b = linearize(color.blue.toDouble());
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Computes the WCAG contrast ratio between two colors.
  static double contrastRatio(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Checks WCAG accessibility (AA: 4.5:1 normal, 3:1 large text).
  static bool isAccessible(Color fg, Color bg, {bool largeText = false}) {
    final ratio = contrastRatio(fg, bg);
    return largeText ? ratio >= 3.0 : ratio >= 4.5;
  }

  /// Returns three triadic colors (120° apart on the hue wheel).
  static List<Color> triadic(Color color) {
    final hsl = toHSL(color);
    return [
      color,
      fromHSL((hsl.h + 120) % 360, hsl.s, hsl.l, a: hsl.a),
      fromHSL((hsl.h + 240) % 360, hsl.s, hsl.l, a: hsl.a),
    ];
  }

  /// Returns analogous colors spaced [angle] degrees apart.
  static List<Color> analogous(Color color, {int count = 3, double angle = 30}) {
    final hsl = toHSL(color);
    final result = <Color>[];
    final half = (count - 1) / 2;
    for (int i = 0; i < count; i++) {
      final offset = (i - half) * angle;
      result.add(fromHSL((hsl.h + offset) % 360, hsl.s, hsl.l, a: hsl.a));
    }
    return result;
  }

  /// Returns split-complementary colors (color + two adjacent to complement).
  static List<Color> splitComplementary(Color color) {
    final hsl = toHSL(color);
    return [
      color,
      fromHSL((hsl.h + 150) % 360, hsl.s, hsl.l, a: hsl.a),
      fromHSL((hsl.h + 210) % 360, hsl.s, hsl.l, a: hsl.a),
    ];
  }

  /// Returns four tetradic (rectangle) colors (90° apart).
  static List<Color> tetradic(Color color) {
    final hsl = toHSL(color);
    return [
      color,
      fromHSL((hsl.h + 90) % 360, hsl.s, hsl.l, a: hsl.a),
      fromHSL((hsl.h + 180) % 360, hsl.s, hsl.l, a: hsl.a),
      fromHSL((hsl.h + 270) % 360, hsl.s, hsl.l, a: hsl.a),
    ];
  }

  /// Generates a gradient of [steps] colors between [from] and [to].
  static List<Color> gradient(Color from, Color to, int steps) {
    if (steps < 2) return [from, to];
    final result = <Color>[];
    for (int i = 0; i < steps; i++) {
      final ratio = i / (steps - 1);
      result.add(mix(from, to, ratio));
    }
    return result;
  }

  /// Generates a random color.
  static Color randomColor({Random? rng}) {
    final random = rng ?? Random();
    return Color.fromARGB(255, random.nextInt(256), random.nextInt(256), random.nextInt(256));
  }

  /// Generates a random pastel color (high lightness, low-moderate saturation).
  static Color randomPastel({Random? rng}) {
    final random = rng ?? Random();
    final h = random.nextDouble() * 360;
    final s = 0.3 + random.nextDouble() * 0.3;
    final l = 0.7 + random.nextDouble() * 0.15;
    return fromHSL(h, s, l);
  }

  /// Generates a random vibrant color (high saturation, medium lightness).
  static Color randomVibrant({Random? rng}) {
    final random = rng ?? Random();
    final h = random.nextDouble() * 360;
    final s = 0.7 + random.nextDouble() * 0.3;
    final l = 0.4 + random.nextDouble() * 0.2;
    return fromHSL(h, s, l);
  }

  /// Converts a color temperature in Kelvin (2000-8000) to an approximate RGB color.
  static Color temperature(double kelvin) {
    final temp = kelvin.clamp(2000.0, 8000.0) / 100.0;
    double r, g, b;

    // Red channel
    if (temp <= 66) {
      r = 255;
    } else {
      r = 329.698727446 * pow(temp - 60, -0.1332047592);
      r = r.clamp(0, 255);
    }

    // Green channel
    if (temp <= 66) {
      g = 99.4708025861 * log(temp) - 161.1195681661;
      g = g.clamp(0, 255);
    } else {
      g = 288.1221695283 * pow(temp - 60, -0.0755148492);
      g = g.clamp(0, 255);
    }

    // Blue channel
    if (temp >= 66) {
      b = 255;
    } else if (temp <= 19) {
      b = 0;
    } else {
      b = 138.5177312231 * log(temp - 10) - 305.0447927307;
      b = b.clamp(0, 255);
    }

    return Color.fromARGB(255, r.round(), g.round(), b.round());
  }
}

/// A large palette of named color constants.
class GchColorPalette {
  GchColorPalette._();

  // Reds
  static const Color red = Color(0xFFFF0000);
  static const Color crimson = Color(0xFFDC143C);
  static const Color firebrick = Color(0xFFB22222);
  static const Color darkRed = Color(0xFF8B0000);
  static const Color indianRed = Color(0xFFCD5C5C);
  static const Color lightCoral = Color(0xFFF08080);
  static const Color salmon = Color(0xFFFA8072);
  static const Color darkSalmon = Color(0xFFE9967A);
  static const Color lightSalmon = Color(0xFFFFA07A);
  static const Color tomato = Color(0xFFFF6347);
  static const Color orangeRed = Color(0xFFFF4500);

  // Oranges
  static const Color orange = Color(0xFFFFA500);
  static const Color darkOrange = Color(0xFFFF8C00);
  static const Color coral = Color(0xFFFF7F50);
  static const Color peach = Color(0xFFFFCBA4);
  static const Color amber = Color(0xFFFFBF00);
  static const Color tangerine = Color(0xFFF28500);

  // Yellows
  static const Color yellow = Color(0xFFFFFF00);
  static const Color gold = Color(0xFFFFD700);
  static const Color khaki = Color(0xFFF0E68C);
  static const Color darkKhaki = Color(0xFFBDB76B);
  static const Color lemon = Color(0xFFFFF44F);
  static const Color cream = Color(0xFFFFFDD0);
  static const Color champagne = Color(0xFFF7E7CE);

  // Greens
  static const Color green = Color(0xFF008000);
  static const Color lime = Color(0xFF00FF00);
  static const Color limeGreen = Color(0xFF32CD32);
  static const Color lawnGreen = Color(0xFF7CFC00);
  static const Color chartreuse = Color(0xFF7FFF00);
  static const Color greenYellow = Color(0xFFADFF2F);
  static const Color springGreen = Color(0xFF00FF7F);
  static const Color mediumSpringGreen = Color(0xFF00FA9A);
  static const Color darkGreen = Color(0xFF006400);
  static const Color forestGreen = Color(0xFF228B22);
  static const Color seaGreen = Color(0xFF2E8B57);
  static const Color mediumSeaGreen = Color(0xFF3CB371);
  static const Color lightSeaGreen = Color(0xFF20B2AA);
  static const Color paleGreen = Color(0xFF98FB98);
  static const Color darkSeaGreen = Color(0xFF8FBC8F);
  static const Color mediumAquamarine = Color(0xFF66CDAA);
  static const Color aquamarine = Color(0xFF7FFFD4);
  static const Color emerald = Color(0xFF50C878);
  static const Color jade = Color(0xFF00A86B);
  static const Color mint = Color(0xFF98FF98);
  static const Color sage = Color(0xFF87AE73);
  static const Color olive = Color(0xFF808000);
  static const Color darkOliveGreen = Color(0xFF556B2F);

  // Blues
  static const Color blue = Color(0xFF0000FF);
  static const Color navy = Color(0xFF000080);
  static const Color darkBlue = Color(0xFF00008B);
  static const Color mediumBlue = Color(0xFF0000CD);
  static const Color royalBlue = Color(0xFF4169E1);
  static const Color steelBlue = Color(0xFF4682B4);
  static const Color dodgerBlue = Color(0xFF1E90FF);
  static const Color deepSkyBlue = Color(0xFF00BFFF);
  static const Color cornflowerBlue = Color(0xFF6495ED);
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color lightSkyBlue = Color(0xFF87CEFA);
  static const Color lightBlue = Color(0xFFADD8E6);
  static const Color powderBlue = Color(0xFFB0E0E6);
  static const Color cobalt = Color(0xFF0047AB);
  static const Color periwinkle = Color(0xFFCCCCFF);
  static const Color cerulean = Color(0xFF007BA7);
  static const Color azure = Color(0xFFF0FFFF);
  static const Color cadetBlue = Color(0xFF5F9EA0);
  static const Color teal = Color(0xFF008080);
  static const Color darkTeal = Color(0xFF004D4D);
  static const Color cyan = Color(0xFF00FFFF);
  static const Color darkCyan = Color(0xFF008B8B);

  // Purples
  static const Color purple = Color(0xFF800080);
  static const Color darkPurple = Color(0xFF4B0082);
  static const Color indigo = Color(0xFF4B0082);
  static const Color violet = Color(0xFFEE82EE);
  static const Color darkViolet = Color(0xFF9400D3);
  static const Color darkOrchid = Color(0xFF9932CC);
  static const Color mediumOrchid = Color(0xFFBA55D3);
  static const Color orchid = Color(0xFFDA70D6);
  static const Color plum = Color(0xFFDDA0DD);
  static const Color thistle = Color(0xFFD8BFD8);
  static const Color lavender = Color(0xFFE6E6FA);
  static const Color lavenderBlush = Color(0xFFFFF0F5);
  static const Color magenta = Color(0xFFFF00FF);
  static const Color fuchsia = Color(0xFFFF00FF);
  static const Color mediumPurple = Color(0xFF9370DB);
  static const Color slateBlue = Color(0xFF6A5ACD);
  static const Color mediumSlateBlue = Color(0xFF7B68EE);
  static const Color amethyst = Color(0xFF9966CC);
  static const Color lilac = Color(0xFFC8A2C8);

  // Pinks
  static const Color pink = Color(0xFFFFC0CB);
  static const Color lightPink = Color(0xFFFFB6C1);
  static const Color hotPink = Color(0xFFFF69B4);
  static const Color deepPink = Color(0xFFFF1493);
  static const Color mediumVioletRed = Color(0xFFC71585);
  static const Color paleVioletRed = Color(0xFFDB7093);
  static const Color rose = Color(0xFFFF007F);
  static const Color blush = Color(0xFFDE5D83);

  // Browns
  static const Color brown = Color(0xFFA52A2A);
  static const Color saddleBrown = Color(0xFF8B4513);
  static const Color sienna = Color(0xFFA0522D);
  static const Color chocolate = Color(0xFFD2691E);
  static const Color peru = Color(0xFFCD853F);
  static const Color tan = Color(0xFFD2B48C);
  static const Color burlywood = Color(0xFFDEB887);
  static const Color wheat = Color(0xFFF5DEB3);
  static const Color sandyBrown = Color(0xFFF4A460);
  static const Color goldenrod = Color(0xFFDAA520);
  static const Color darkGoldenrod = Color(0xFFB8860B);
  static const Color coffee = Color(0xFF6F4E37);
  static const Color mahogany = Color(0xFFC04000);
  static const Color maroon = Color(0xFF800000);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color lightGray = Color(0xFFD3D3D3);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color gray = Color(0xFF808080);
  static const Color darkGray = Color(0xFFA9A9A9);
  static const Color dimGray = Color(0xFF696969);
  static const Color slateGray = Color(0xFF708090);
  static const Color lightSlateGray = Color(0xFF778899);
  static const Color charcoal = Color(0xFF36454F);
  static const Color jet = Color(0xFF343434);
  static const Color offWhite = Color(0xFFFAF9F6);
  static const Color snow = Color(0xFFFFFAFA);
  static const Color ivory = Color(0xFFFFFFF0);
  static const Color linen = Color(0xFFFAF0E6);
  static const Color beige = Color(0xFFF5F5DC);
  static const Color seashell = Color(0xFFFFF5EE);
  static const Color alabaster = Color(0xFFF2F0EB);

  // Metallic
  static const Color gold2 = Color(0xFFFFD700);
  static const Color platinum = Color(0xFFE5E4E2);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color copper = Color(0xFFB87333);
  static const Color titanium = Color(0xFF878681);
}

/// A theme grouping of semantic colors.
class GchColorTheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color error;
  final Color success;
  final Color warning;
  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onSurface;
  final Color onError;

  const GchColorTheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.error,
    required this.success,
    required this.warning,
    required this.onPrimary,
    required this.onSecondary,
    required this.onBackground,
    required this.onSurface,
    required this.onError,
  });

  /// A standard light theme.
  factory GchColorTheme.light() {
    return const GchColorTheme(
      primary: Color(0xFF1565C0),
      secondary: Color(0xFF0277BD),
      accent: Color(0xFF00ACC1),
      background: Color(0xFFF5F5F5),
      surface: Color(0xFFFFFFFF),
      error: Color(0xFFB00020),
      success: Color(0xFF388E3C),
      warning: Color(0xFFF57F17),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onBackground: Color(0xFF212121),
      onSurface: Color(0xFF212121),
      onError: Color(0xFFFFFFFF),
    );
  }

  /// A standard dark theme.
  factory GchColorTheme.dark() {
    return const GchColorTheme(
      primary: Color(0xFF90CAF9),
      secondary: Color(0xFF80DEEA),
      accent: Color(0xFFB39DDB),
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      error: Color(0xFFCF6679),
      success: Color(0xFF81C784),
      warning: Color(0xFFFFD54F),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onBackground: Color(0xFFEEEEEE),
      onSurface: Color(0xFFEEEEEE),
      onError: Color(0xFF000000),
    );
  }

  /// A solarized theme.
  factory GchColorTheme.solarized() {
    return const GchColorTheme(
      primary: Color(0xFF268BD2),
      secondary: Color(0xFF2AA198),
      accent: Color(0xFFD33682),
      background: Color(0xFFFDF6E3),
      surface: Color(0xFFEEE8D5),
      error: Color(0xFFDC322F),
      success: Color(0xFF859900),
      warning: Color(0xFFCB4B16),
      onPrimary: Color(0xFFFDF6E3),
      onSecondary: Color(0xFFFDF6E3),
      onBackground: Color(0xFF657B83),
      onSurface: Color(0xFF586E75),
      onError: Color(0xFFFDF6E3),
    );
  }

  /// Creates a copy of this theme with given fields overridden.
  GchColorTheme copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? error,
    Color? success,
    Color? warning,
    Color? onPrimary,
    Color? onSecondary,
    Color? onBackground,
    Color? onSurface,
    Color? onError,
  }) {
    return GchColorTheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onBackground: onBackground ?? this.onBackground,
      onSurface: onSurface ?? this.onSurface,
      onError: onError ?? this.onError,
    );
  }

  @override
  String toString() {
    return 'GchColorTheme(primary: ${GchColorUtil.toHex(primary)}, '
        'secondary: ${GchColorUtil.toHex(secondary)}, '
        'accent: ${GchColorUtil.toHex(accent)})';
  }

  /// Returns a map representation of all theme colors.
  Map<String, String> toMap() {
    return {
      'primary': GchColorUtil.toHex(primary),
      'secondary': GchColorUtil.toHex(secondary),
      'accent': GchColorUtil.toHex(accent),
      'background': GchColorUtil.toHex(background),
      'surface': GchColorUtil.toHex(surface),
      'error': GchColorUtil.toHex(error),
      'success': GchColorUtil.toHex(success),
      'warning': GchColorUtil.toHex(warning),
      'onPrimary': GchColorUtil.toHex(onPrimary),
      'onSecondary': GchColorUtil.toHex(onSecondary),
      'onBackground': GchColorUtil.toHex(onBackground),
      'onSurface': GchColorUtil.toHex(onSurface),
      'onError': GchColorUtil.toHex(onError),
    };
  }

  /// Returns a suggested text color (black or white) for the given background.
  static Color suggestedTextColor(Color background) {
    final lum = GchColorUtil.luminance(background);
    return lum > 0.179 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }

  /// Generates a monochromatic palette from the primary color.
  List<Color> monochromaticScale({int steps = 5}) {
    return GchColorUtil.gradient(
      GchColorUtil.lighter(primary, 0.4),
      GchColorUtil.darker(primary, 0.4),
      steps,
    );
  }

  /// Checks whether primary meets WCAG AA against background.
  bool get primaryAccessible {
    return GchColorUtil.isAccessible(primary, background);
  }

  /// Checks whether the error color meets WCAG AA against surface.
  bool get errorAccessible {
    return GchColorUtil.isAccessible(error, surface);
  }

  /// Returns an analogous palette from the primary color (3 colors).
  List<Color> analogousPalette() {
    return GchColorUtil.analogous(primary, count: 3, angle: 30);
  }

  /// Returns the triadic palette from the primary color.
  List<Color> triadicPalette() {
    return GchColorUtil.triadic(primary);
  }

  /// Returns the split-complementary palette from the primary color.
  List<Color> splitComplementaryPalette() {
    return GchColorUtil.splitComplementary(primary);
  }

  /// Returns the complementary color of primary.
  Color get complementaryPrimary {
    return GchColorUtil.complement(primary);
  }

  /// Returns the luminance of the primary color.
  double get primaryLuminance {
    return GchColorUtil.luminance(primary);
  }

  /// Returns the contrast ratio of primary against background.
  double get primaryContrastRatio {
    return GchColorUtil.contrastRatio(primary, background);
  }

  /// Returns a gradient from primary to secondary with [steps] stops.
  List<Color> primaryToSecondaryGradient({int steps = 5}) {
    return GchColorUtil.gradient(primary, secondary, steps);
  }

  /// Returns a gradient from primary lighter to primary darker.
  List<Color> primaryShades({int steps = 5}) {
    final lighter = GchColorUtil.lighter(primary, 0.3);
    final darker = GchColorUtil.darker(primary, 0.3);
    return GchColorUtil.gradient(lighter, darker, steps);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GchColorTheme &&
        other.primary == primary &&
        other.secondary == secondary &&
        other.accent == accent &&
        other.background == background &&
        other.surface == surface;
  }

  @override
  int get hashCode => Object.hash(primary, secondary, accent, background, surface);
}

// ─── GchColorConverter ────────────────────────────────────────────────────

/// Converts between various color models.
class GchColorConverter {
  GchColorConverter._();

  /// Converts RGB (0-255 each) to XYZ color space (D65 illuminant).
  static ({double x, double y, double z}) rgbToXyz(int r, int g, int b) {
    double linearize(double c) {
      c /= 255.0;
      return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    final lr = linearize(r.toDouble());
    final lg = linearize(g.toDouble());
    final lb = linearize(b.toDouble());

    return (
      x: lr * 0.4124564 + lg * 0.3575761 + lb * 0.1804375,
      y: lr * 0.2126729 + lg * 0.7151522 + lb * 0.0721750,
      z: lr * 0.0193339 + lg * 0.1191920 + lb * 0.9503041,
    );
  }

  /// Converts XYZ to CIELAB (L*, a*, b*).
  static ({double l, double a, double b}) xyzToLab(double x, double y, double z) {
    double f(double t) {
      const delta = 6.0 / 29.0;
      return t > delta * delta * delta
          ? pow(t, 1.0 / 3.0).toDouble()
          : t / (3 * delta * delta) + 4.0 / 29.0;
    }

    // D65 reference white
    final fx = f(x / 0.95047);
    final fy = f(y / 1.00000);
    final fz = f(z / 1.08883);
    return (
      l: 116 * fy - 16,
      a: 500 * (fx - fy),
      b: 200 * (fy - fz),
    );
  }

  /// Converts a [Color] to CIELAB components.
  static ({double l, double a, double b}) colorToLab(Color color) {
    final xyz = rgbToXyz(color.red, color.green, color.blue);
    return xyzToLab(xyz.x, xyz.y, xyz.z);
  }

  /// Computes Delta-E 76 perceptual color difference between two colors.
  static double deltaE76(Color c1, Color c2) {
    final lab1 = colorToLab(c1);
    final lab2 = colorToLab(c2);
    final dl = lab1.l - lab2.l;
    final da = lab1.a - lab2.a;
    final db = lab1.b - lab2.b;
    return sqrt(dl * dl + da * da + db * db);
  }

  /// Finds the perceptually closest color from [palette] to [target].
  static Color closestColor(Color target, List<Color> palette) {
    if (palette.isEmpty) return target;
    Color closest = palette[0];
    double minDist = deltaE76(target, palette[0]);
    for (int i = 1; i < palette.length; i++) {
      final dist = deltaE76(target, palette[i]);
      if (dist < minDist) {
        minDist = dist;
        closest = palette[i];
      }
    }
    return closest;
  }

  /// Converts HSL to CMYK (approximate).
  static ({double c, double m, double y, double k}) colorToCmyk(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;
    final k = 1 - [r, g, b].reduce((a, b) => a > b ? a : b);
    if (k == 1.0) return (c: 0, m: 0, y: 0, k: 1);
    return (
      c: (1 - r - k) / (1 - k),
      m: (1 - g - k) / (1 - k),
      y: (1 - b - k) / (1 - k),
      k: k,
    );
  }

  /// Creates a [Color] from CMYK values (0.0-1.0 each).
  static Color fromCmyk(double c, double m, double y, double k) {
    final r = ((1 - c) * (1 - k) * 255).round().clamp(0, 255);
    final g = ((1 - m) * (1 - k) * 255).round().clamp(0, 255);
    final b = ((1 - y) * (1 - k) * 255).round().clamp(0, 255);
    return Color.fromARGB(255, r, g, b);
  }
}

// ─── GchColorSchemeGenerator ──────────────────────────────────────────────

/// Generates cohesive color schemes from a seed color.
class GchColorSchemeGenerator {
  GchColorSchemeGenerator._();

  /// Generates a monochromatic scheme with [steps] lightness levels.
  static List<Color> monochromatic(Color seed, {int steps = 7}) {
    final hsl = GchColorUtil.toHSL(seed);
    return List.generate(steps, (i) {
      final l = (i + 1) / (steps + 1);
      return GchColorUtil.fromHSL(hsl.h, hsl.s, l);
    });
  }

  /// Generates a tint scale (seed mixed with white).
  static List<Color> tints(Color seed, {int steps = 5}) {
    const white = Color(0xFFFFFFFF);
    return List.generate(steps, (i) {
      final ratio = (i + 1) / (steps + 1);
      return GchColorUtil.mix(seed, white, ratio);
    });
  }

  /// Generates a shade scale (seed mixed with black).
  static List<Color> shades(Color seed, {int steps = 5}) {
    const black = Color(0xFF000000);
    return List.generate(steps, (i) {
      final ratio = (i + 1) / (steps + 1);
      return GchColorUtil.mix(seed, black, ratio);
    });
  }

  /// Generates a tone scale (seed mixed with gray).
  static List<Color> tones(Color seed, {int steps = 5}) {
    const gray = Color(0xFF808080);
    return List.generate(steps, (i) {
      final ratio = (i + 1) / (steps + 1);
      return GchColorUtil.mix(seed, gray, ratio);
    });
  }

  /// Generates a full Material-style color swatch (50, 100, 200...900).
  static Map<int, Color> materialSwatch(Color seed) {
    final white = const Color(0xFFFFFFFF);
    final black = const Color(0xFF000000);
    return {
      50: GchColorUtil.mix(seed, white, 0.9),
      100: GchColorUtil.mix(seed, white, 0.8),
      200: GchColorUtil.mix(seed, white, 0.6),
      300: GchColorUtil.mix(seed, white, 0.4),
      400: GchColorUtil.mix(seed, white, 0.2),
      500: seed,
      600: GchColorUtil.mix(seed, black, 0.1),
      700: GchColorUtil.mix(seed, black, 0.25),
      800: GchColorUtil.mix(seed, black, 0.4),
      900: GchColorUtil.mix(seed, black, 0.55),
    };
  }
}
