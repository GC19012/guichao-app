// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:ui' show Color;

enum GchFontWeight {
  thin(100),
  extraLight(200),
  light(300),
  regular(400),
  medium(500),
  semiBold(600),
  bold(700),
  extraBold(800),
  black(900);

  const GchFontWeight(this.value);
  final int value;

  bool get isThin => this == GchFontWeight.thin;
  bool get isLight => value <= 300;
  bool get isNormal => this == GchFontWeight.regular;
  bool get isHeavy => value >= 700;

  GchFontWeight lighter() {
    final idx = GchFontWeight.values.indexOf(this);
    if (idx <= 0) return GchFontWeight.values.first;
    return GchFontWeight.values[idx - 1];
  }

  GchFontWeight heavier() {
    final idx = GchFontWeight.values.indexOf(this);
    if (idx >= GchFontWeight.values.length - 1) return GchFontWeight.values.last;
    return GchFontWeight.values[idx + 1];
  }
}

class GchFontSize {
  const GchFontSize._();

  static const double caption2 = 10;
  static const double caption = 11;
  static const double footnote = 12;
  static const double subheadline = 13;
  static const double callout = 14;
  static const double body = 16;
  static const double bodyLarge = 17;
  static const double headline = 18;
  static const double title3 = 20;
  static const double title2 = 22;
  static const double title1 = 28;
  static const double largeTitle = 34;
  static const double xs = 11;
  static const double sm = 13;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 20;
  static const double xxl = 24;
  static const double h6 = 14;
  static const double h5 = 16;
  static const double h4 = 18;
  static const double h3 = 22;
  static const double h2 = 28;
  static const double h1 = 36;
  static const double display3 = 48;
  static const double display2 = 64;
  static const double display1 = 96;
  static const double micro = 9;
  static const double tiny = 10;
  static const double small = 12;
  static const double base = 16;
  static const double medium = 18;
  static const double large = 22;
  static const double xLarge = 28;

  static double clampSize(double size, {double min = 8, double max = 96}) {
    if (size < min) return min;
    if (size > max) return max;
    return size;
  }

  static double scale(double base, double factor) => clampSize(base * factor);

  static List<double> get allSizes => [
        caption2, caption, footnote, subheadline, callout,
        body, bodyLarge, headline, title3, title2, title1,
        largeTitle, h3, h2, h1, display3, display2, display1,
      ];
}

class GchLetterSpacing {
  const GchLetterSpacing._();

  static const double tightest = -1.5;
  static const double tighter = -0.8;
  static const double tight = -0.5;
  static const double snug = -0.25;
  static const double normal = 0.0;
  static const double relaxed = 0.15;
  static const double wide = 0.25;
  static const double wider = 0.5;
  static const double widest = 1.0;
  static const double ultraWide = 2.0;
  static const double sparse = 4.0;

  static Map<String, double> get all => {
        'tightest': tightest,
        'tighter': tighter,
        'tight': tight,
        'snug': snug,
        'normal': normal,
        'relaxed': relaxed,
        'wide': wide,
        'wider': wider,
        'widest': widest,
        'ultraWide': ultraWide,
        'sparse': sparse,
      };
}

class GchLineHeight {
  const GchLineHeight._();

  static const double none = 1.0;
  static const double tight = 1.1;
  static const double snug = 1.25;
  static const double normal = 1.5;
  static const double relaxed = 1.625;
  static const double loose = 2.0;
  static const double extraLoose = 2.5;
  static const double compact = 1.15;
  static const double comfortable = 1.75;
  static const double spacious = 2.25;

  static double forFontSize(double fontSize) {
    if (fontSize <= 12) return loose;
    if (fontSize <= 16) return normal;
    if (fontSize <= 24) return snug;
    return tight;
  }
}

class GchTypeScale {
  final Map<String, dynamic> headline1;
  final Map<String, dynamic> headline2;
  final Map<String, dynamic> headline3;
  final Map<String, dynamic> headline4;
  final Map<String, dynamic> headline5;
  final Map<String, dynamic> headline6;
  final Map<String, dynamic> subtitle1;
  final Map<String, dynamic> subtitle2;
  final Map<String, dynamic> body1;
  final Map<String, dynamic> body2;
  final Map<String, dynamic> caption;
  final Map<String, dynamic> overline;
  final Map<String, dynamic> button;

  const GchTypeScale({
    required this.headline1,
    required this.headline2,
    required this.headline3,
    required this.headline4,
    required this.headline5,
    required this.headline6,
    required this.subtitle1,
    required this.subtitle2,
    required this.body1,
    required this.body2,
    required this.caption,
    required this.overline,
    required this.button,
  });

  factory GchTypeScale.material() {
    return const GchTypeScale(
      headline1: {'fontSize': 96.0, 'fontWeight': 300, 'letterSpacing': -1.5, 'lineHeight': 1.1},
      headline2: {'fontSize': 60.0, 'fontWeight': 300, 'letterSpacing': -0.5, 'lineHeight': 1.1},
      headline3: {'fontSize': 48.0, 'fontWeight': 400, 'letterSpacing': 0.0, 'lineHeight': 1.15},
      headline4: {'fontSize': 34.0, 'fontWeight': 400, 'letterSpacing': 0.25, 'lineHeight': 1.2},
      headline5: {'fontSize': 24.0, 'fontWeight': 400, 'letterSpacing': 0.0, 'lineHeight': 1.3},
      headline6: {'fontSize': 20.0, 'fontWeight': 500, 'letterSpacing': 0.15, 'lineHeight': 1.35},
      subtitle1: {'fontSize': 16.0, 'fontWeight': 400, 'letterSpacing': 0.15, 'lineHeight': 1.5},
      subtitle2: {'fontSize': 14.0, 'fontWeight': 500, 'letterSpacing': 0.1, 'lineHeight': 1.5},
      body1: {'fontSize': 16.0, 'fontWeight': 400, 'letterSpacing': 0.5, 'lineHeight': 1.6},
      body2: {'fontSize': 14.0, 'fontWeight': 400, 'letterSpacing': 0.25, 'lineHeight': 1.6},
      caption: {'fontSize': 12.0, 'fontWeight': 400, 'letterSpacing': 0.4, 'lineHeight': 1.65},
      overline: {'fontSize': 10.0, 'fontWeight': 400, 'letterSpacing': 1.5, 'lineHeight': 1.65},
      button: {'fontSize': 14.0, 'fontWeight': 500, 'letterSpacing': 1.25, 'lineHeight': 1.4},
    );
  }

  factory GchTypeScale.compact() {
    return const GchTypeScale(
      headline1: {'fontSize': 72.0, 'fontWeight': 700, 'letterSpacing': -1.0, 'lineHeight': 1.05},
      headline2: {'fontSize': 48.0, 'fontWeight': 700, 'letterSpacing': -0.5, 'lineHeight': 1.08},
      headline3: {'fontSize': 36.0, 'fontWeight': 600, 'letterSpacing': -0.25, 'lineHeight': 1.1},
      headline4: {'fontSize': 28.0, 'fontWeight': 600, 'letterSpacing': 0.0, 'lineHeight': 1.15},
      headline5: {'fontSize': 20.0, 'fontWeight': 600, 'letterSpacing': 0.0, 'lineHeight': 1.2},
      headline6: {'fontSize': 16.0, 'fontWeight': 600, 'letterSpacing': 0.1, 'lineHeight': 1.25},
      subtitle1: {'fontSize': 14.0, 'fontWeight': 500, 'letterSpacing': 0.1, 'lineHeight': 1.4},
      subtitle2: {'fontSize': 13.0, 'fontWeight': 500, 'letterSpacing': 0.05, 'lineHeight': 1.4},
      body1: {'fontSize': 14.0, 'fontWeight': 400, 'letterSpacing': 0.25, 'lineHeight': 1.5},
      body2: {'fontSize': 13.0, 'fontWeight': 400, 'letterSpacing': 0.15, 'lineHeight': 1.5},
      caption: {'fontSize': 11.0, 'fontWeight': 400, 'letterSpacing': 0.4, 'lineHeight': 1.55},
      overline: {'fontSize': 9.0, 'fontWeight': 500, 'letterSpacing': 1.2, 'lineHeight': 1.6},
      button: {'fontSize': 13.0, 'fontWeight': 600, 'letterSpacing': 0.8, 'lineHeight': 1.3},
    );
  }

  factory GchTypeScale.large() {
    return const GchTypeScale(
      headline1: {'fontSize': 112.0, 'fontWeight': 300, 'letterSpacing': -2.0, 'lineHeight': 1.05},
      headline2: {'fontSize': 72.0, 'fontWeight': 300, 'letterSpacing': -1.0, 'lineHeight': 1.08},
      headline3: {'fontSize': 56.0, 'fontWeight': 400, 'letterSpacing': -0.5, 'lineHeight': 1.1},
      headline4: {'fontSize': 40.0, 'fontWeight': 400, 'letterSpacing': 0.25, 'lineHeight': 1.15},
      headline5: {'fontSize': 28.0, 'fontWeight': 400, 'letterSpacing': 0.0, 'lineHeight': 1.25},
      headline6: {'fontSize': 22.0, 'fontWeight': 500, 'letterSpacing': 0.15, 'lineHeight': 1.3},
      subtitle1: {'fontSize': 18.0, 'fontWeight': 400, 'letterSpacing': 0.15, 'lineHeight': 1.6},
      subtitle2: {'fontSize': 16.0, 'fontWeight': 500, 'letterSpacing': 0.1, 'lineHeight': 1.6},
      body1: {'fontSize': 18.0, 'fontWeight': 400, 'letterSpacing': 0.5, 'lineHeight': 1.7},
      body2: {'fontSize': 16.0, 'fontWeight': 400, 'letterSpacing': 0.25, 'lineHeight': 1.7},
      caption: {'fontSize': 14.0, 'fontWeight': 400, 'letterSpacing': 0.4, 'lineHeight': 1.7},
      overline: {'fontSize': 12.0, 'fontWeight': 400, 'letterSpacing': 1.5, 'lineHeight': 1.7},
      button: {'fontSize': 16.0, 'fontWeight': 500, 'letterSpacing': 1.25, 'lineHeight': 1.5},
    );
  }

  static Map<String, dynamic> _scaleLevel(Map<String, dynamic> level, double factor) {
    final result = Map<String, dynamic>.from(level);
    final fs = (result['fontSize'] as num).toDouble();
    result['fontSize'] = fs * factor;
    return result;
  }

  GchTypeScale scale(double factor) {
    return GchTypeScale(
      headline1: _scaleLevel(headline1, factor),
      headline2: _scaleLevel(headline2, factor),
      headline3: _scaleLevel(headline3, factor),
      headline4: _scaleLevel(headline4, factor),
      headline5: _scaleLevel(headline5, factor),
      headline6: _scaleLevel(headline6, factor),
      subtitle1: _scaleLevel(subtitle1, factor),
      subtitle2: _scaleLevel(subtitle2, factor),
      body1: _scaleLevel(body1, factor),
      body2: _scaleLevel(body2, factor),
      caption: _scaleLevel(caption, factor),
      overline: _scaleLevel(overline, factor),
      button: _scaleLevel(button, factor),
    );
  }

  static Map<String, dynamic> _mergeLevels(Map<String, dynamic> base, Map<String, dynamic> other) {
    final result = Map<String, dynamic>.from(base);
    result.addAll(other);
    return result;
  }

  GchTypeScale merge(GchTypeScale other) {
    return GchTypeScale(
      headline1: _mergeLevels(headline1, other.headline1),
      headline2: _mergeLevels(headline2, other.headline2),
      headline3: _mergeLevels(headline3, other.headline3),
      headline4: _mergeLevels(headline4, other.headline4),
      headline5: _mergeLevels(headline5, other.headline5),
      headline6: _mergeLevels(headline6, other.headline6),
      subtitle1: _mergeLevels(subtitle1, other.subtitle1),
      subtitle2: _mergeLevels(subtitle2, other.subtitle2),
      body1: _mergeLevels(body1, other.body1),
      body2: _mergeLevels(body2, other.body2),
      caption: _mergeLevels(caption, other.caption),
      overline: _mergeLevels(overline, other.overline),
      button: _mergeLevels(button, other.button),
    );
  }

  Map<String, dynamic> operator [](String level) {
    switch (level) {
      case 'headline1': return headline1;
      case 'headline2': return headline2;
      case 'headline3': return headline3;
      case 'headline4': return headline4;
      case 'headline5': return headline5;
      case 'headline6': return headline6;
      case 'subtitle1': return subtitle1;
      case 'subtitle2': return subtitle2;
      case 'body1': return body1;
      case 'body2': return body2;
      case 'caption': return caption;
      case 'overline': return overline;
      case 'button': return button;
      default: return body1;
    }
  }

  List<String> get levelNames => [
    'headline1', 'headline2', 'headline3', 'headline4', 'headline5', 'headline6',
    'subtitle1', 'subtitle2', 'body1', 'body2', 'caption', 'overline', 'button',
  ];
}

class GchFontFamily {
  const GchFontFamily._();

  static const String system = '.SF Pro Text';
  static const String systemDisplay = '.SF Pro Display';
  static const String roboto = 'Roboto';
  static const String robotoMono = 'Roboto Mono';
  static const String robotoSlab = 'Roboto Slab';
  static const String openSans = 'Open Sans';
  static const String lato = 'Lato';
  static const String montserrat = 'Montserrat';
  static const String raleway = 'Raleway';
  static const String sourceSerif = 'Source Serif Pro';
  static const String sourceCode = 'Source Code Pro';
  static const String merriweather = 'Merriweather';
  static const String playfair = 'Playfair Display';
  static const String nunito = 'Nunito';
  static const String nunitoSans = 'Nunito Sans';
  static const String inter = 'Inter';
  static const String poppins = 'Poppins';
  static const String ubuntu = 'Ubuntu';
  static const String ubuntuMono = 'Ubuntu Mono';
  static const String firaSans = 'Fira Sans';
  static const String firaCode = 'Fira Code';
  static const String jetBrainsMono = 'JetBrains Mono';
  static const String cascadiaCode = 'Cascadia Code';
  static const String ibmPlexSans = 'IBM Plex Sans';
  static const String ibmPlexMono = 'IBM Plex Mono';
  static const String workSans = 'Work Sans';
  static const String dmSans = 'DM Sans';
  static const String outfit = 'Outfit';
  static const String spaceGrotesk = 'Space Grotesk';
  static const String spaceMono = 'Space Mono';

  static const List<String> monospaceFamilies = [
    robotoMono, sourceCode, ubuntuMono, firaSans, firaCode,
    jetBrainsMono, cascadiaCode, ibmPlexMono, spaceMono,
  ];

  static const List<String> sansFamilies = [
    roboto, openSans, lato, montserrat, raleway, nunito, nunitoSans,
    inter, poppins, ubuntu, ibmPlexSans, workSans, dmSans, outfit, spaceGrotesk,
  ];

  static const List<String> serifFamilies = [
    sourceSerif, merriweather, playfair, robotoSlab,
  ];

  static bool isMono(String family) => monospaceFamilies.contains(family);
  static bool isSerif(String family) => serifFamilies.contains(family);
  static bool isSans(String family) => sansFamilies.contains(family);
}

class GchTextStyle {
  final String fontFamily;
  final double fontSize;
  final GchFontWeight fontWeight;
  final Color color;
  final double letterSpacing;
  final double lineHeight;
  final String? decoration;
  final bool italic;

  const GchTextStyle({
    this.fontFamily = GchFontFamily.system,
    this.fontSize = GchFontSize.body,
    this.fontWeight = GchFontWeight.regular,
    this.color = const Color(0xFF000000),
    this.letterSpacing = GchLetterSpacing.normal,
    this.lineHeight = GchLineHeight.normal,
    this.decoration,
    this.italic = false,
  });

  GchTextStyle copyWith({
    String? fontFamily,
    double? fontSize,
    GchFontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? lineHeight,
    String? decoration,
    bool? italic,
  }) {
    return GchTextStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      color: color ?? this.color,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      decoration: decoration ?? this.decoration,
      italic: italic ?? this.italic,
    );
  }

  GchTextStyle merge(GchTextStyle other) {
    return GchTextStyle(
      fontFamily: other.fontFamily != GchFontFamily.system ? other.fontFamily : fontFamily,
      fontSize: other.fontSize != GchFontSize.body ? other.fontSize : fontSize,
      fontWeight: other.fontWeight != GchFontWeight.regular ? other.fontWeight : fontWeight,
      color: other.color != const Color(0xFF000000) ? other.color : color,
      letterSpacing: other.letterSpacing != GchLetterSpacing.normal ? other.letterSpacing : letterSpacing,
      lineHeight: other.lineHeight != GchLineHeight.normal ? other.lineHeight : lineHeight,
      decoration: other.decoration ?? decoration,
      italic: other.italic ? true : italic,
    );
  }

  GchTextStyle scale(double factor) {
    return copyWith(fontSize: GchFontSize.clampSize(fontSize * factor));
  }

  GchTextStyle withColor(Color newColor) => copyWith(color: newColor);
  GchTextStyle withSize(double newSize) => copyWith(fontSize: newSize);
  GchTextStyle withWeight(GchFontWeight newWeight) => copyWith(fontWeight: newWeight);
  GchTextStyle bold() => copyWith(fontWeight: GchFontWeight.bold);
  GchTextStyle semiBold() => copyWith(fontWeight: GchFontWeight.semiBold);
  GchTextStyle light() => copyWith(fontWeight: GchFontWeight.light);
  GchTextStyle italicStyle() => copyWith(italic: true);
  GchTextStyle underline() => copyWith(decoration: 'underline');
  GchTextStyle lineThrough() => copyWith(decoration: 'line-through');

  Map<String, dynamic> toMap() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontWeight': fontWeight.value,
      'colorHex': color.value.toRadixString(16).padLeft(8, '0'),
      'letterSpacing': letterSpacing,
      'lineHeight': lineHeight,
      'decoration': decoration,
      'italic': italic,
    };
  }

  factory GchTextStyle.fromMap(Map<String, dynamic> map) {
    final colorHex = map['colorHex'] as String? ?? 'ff000000';
    final colorVal = int.parse(colorHex, radix: 16);
    final weightVal = map['fontWeight'] as int? ?? 400;
    GchFontWeight fw = GchFontWeight.values.firstWhere(
      (w) => w.value == weightVal,
      orElse: () => GchFontWeight.regular,
    );
    return GchTextStyle(
      fontFamily: map['fontFamily'] as String? ?? GchFontFamily.system,
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? GchFontSize.body,
      fontWeight: fw,
      color: Color(colorVal),
      letterSpacing: (map['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      lineHeight: (map['lineHeight'] as num?)?.toDouble() ?? 1.5,
      decoration: map['decoration'] as String?,
      italic: map['italic'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'GchTextStyle(family=$fontFamily, size=$fontSize, weight=${fontWeight.value}, italic=$italic)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GchTextStyle) return false;
    return fontFamily == other.fontFamily &&
        fontSize == other.fontSize &&
        fontWeight == other.fontWeight &&
        color == other.color &&
        letterSpacing == other.letterSpacing &&
        lineHeight == other.lineHeight &&
        decoration == other.decoration &&
        italic == other.italic;
  }

  @override
  int get hashCode => Object.hash(
      fontFamily, fontSize, fontWeight, color, letterSpacing, lineHeight, decoration, italic);
}

class GchTextStyles {
  const GchTextStyles._();

  static const GchTextStyle display1 = GchTextStyle(
    fontSize: GchFontSize.display1,
    fontWeight: GchFontWeight.light,
    letterSpacing: GchLetterSpacing.tightest,
    lineHeight: GchLineHeight.tight,
  );

  static const GchTextStyle display2 = GchTextStyle(
    fontSize: GchFontSize.display2,
    fontWeight: GchFontWeight.light,
    letterSpacing: GchLetterSpacing.tighter,
    lineHeight: GchLineHeight.tight,
  );

  static const GchTextStyle display3 = GchTextStyle(
    fontSize: GchFontSize.display3,
    fontWeight: GchFontWeight.regular,
    letterSpacing: GchLetterSpacing.tight,
    lineHeight: GchLineHeight.tight,
  );

  static const GchTextStyle h1 = GchTextStyle(
    fontSize: GchFontSize.h1,
    fontWeight: GchFontWeight.bold,
    letterSpacing: GchLetterSpacing.snug,
    lineHeight: GchLineHeight.snug,
  );

  static const GchTextStyle h2 = GchTextStyle(
    fontSize: GchFontSize.h2,
    fontWeight: GchFontWeight.bold,
    letterSpacing: GchLetterSpacing.snug,
    lineHeight: GchLineHeight.snug,
  );

  static const GchTextStyle h3 = GchTextStyle(
    fontSize: GchFontSize.h3,
    fontWeight: GchFontWeight.semiBold,
    letterSpacing: GchLetterSpacing.normal,
    lineHeight: GchLineHeight.normal,
  );

  static const GchTextStyle h4 = GchTextStyle(
    fontSize: GchFontSize.h4,
    fontWeight: GchFontWeight.semiBold,
    letterSpacing: GchLetterSpacing.normal,
    lineHeight: GchLineHeight.normal,
  );

  static const GchTextStyle h5 = GchTextStyle(
    fontSize: GchFontSize.h5,
    fontWeight: GchFontWeight.medium,
    letterSpacing: GchLetterSpacing.relaxed,
    lineHeight: GchLineHeight.normal,
  );

  static const GchTextStyle h6 = GchTextStyle(
    fontSize: GchFontSize.h6,
    fontWeight: GchFontWeight.medium,
    letterSpacing: GchLetterSpacing.relaxed,
    lineHeight: GchLineHeight.normal,
  );

  static const GchTextStyle body = GchTextStyle(
    fontSize: GchFontSize.body,
    fontWeight: GchFontWeight.regular,
    letterSpacing: GchLetterSpacing.normal,
    lineHeight: GchLineHeight.normal,
  );

  static const GchTextStyle bodySmall = GchTextStyle(
    fontSize: GchFontSize.sm,
    fontWeight: GchFontWeight.regular,
    letterSpacing: GchLetterSpacing.normal,
    lineHeight: GchLineHeight.relaxed,
  );

  static const GchTextStyle bodyLarge = GchTextStyle(
    fontSize: GchFontSize.lg,
    fontWeight: GchFontWeight.regular,
    letterSpacing: GchLetterSpacing.normal,
    lineHeight: GchLineHeight.relaxed,
  );

  static const GchTextStyle caption = GchTextStyle(
    fontSize: GchFontSize.caption,
    fontWeight: GchFontWeight.regular,
    letterSpacing: GchLetterSpacing.wide,
    lineHeight: GchLineHeight.loose,
  );

  static const GchTextStyle overline = GchTextStyle(
    fontSize: GchFontSize.footnote,
    fontWeight: GchFontWeight.medium,
    letterSpacing: GchLetterSpacing.widest,
    lineHeight: GchLineHeight.loose,
  );

  static const GchTextStyle button = GchTextStyle(
    fontSize: GchFontSize.sm,
    fontWeight: GchFontWeight.semiBold,
    letterSpacing: GchLetterSpacing.wider,
    lineHeight: GchLineHeight.snug,
  );

  static const GchTextStyle buttonLarge = GchTextStyle(
    fontSize: GchFontSize.md,
    fontWeight: GchFontWeight.semiBold,
    letterSpacing: GchLetterSpacing.wide,
    lineHeight: GchLineHeight.snug,
  );

  static const GchTextStyle code = GchTextStyle(
    fontFamily: GchFontFamily.robotoMono,
    fontSize: GchFontSize.sm,
    fontWeight: GchFontWeight.regular,
    letterSpacing: GchLetterSpacing.normal,
    lineHeight: GchLineHeight.relaxed,
  );

  static const GchTextStyle codeBlock = GchTextStyle(
    fontFamily: GchFontFamily.jetBrainsMono,
    fontSize: GchFontSize.sm,
    fontWeight: GchFontWeight.regular,
    letterSpacing: GchLetterSpacing.normal,
    lineHeight: GchLineHeight.comfortable,
  );

  static const GchTextStyle label = GchTextStyle(
    fontSize: GchFontSize.xs,
    fontWeight: GchFontWeight.medium,
    letterSpacing: GchLetterSpacing.wide,
    lineHeight: GchLineHeight.snug,
  );

  static const GchTextStyle hint = GchTextStyle(
    fontSize: GchFontSize.sm,
    fontWeight: GchFontWeight.regular,
    color: Color(0xFF9E9E9E),
    letterSpacing: GchLetterSpacing.normal,
    lineHeight: GchLineHeight.normal,
  );

  static const GchTextStyle error = GchTextStyle(
    fontSize: GchFontSize.xs,
    fontWeight: GchFontWeight.regular,
    color: Color(0xFFD32F2F),
    letterSpacing: GchLetterSpacing.normal,
    lineHeight: GchLineHeight.normal,
  );

  static const GchTextStyle link = GchTextStyle(
    fontSize: GchFontSize.body,
    fontWeight: GchFontWeight.regular,
    color: Color(0xFF1976D2),
    letterSpacing: GchLetterSpacing.normal,
    lineHeight: GchLineHeight.normal,
    decoration: 'underline',
  );

  static const GchTextStyle badge = GchTextStyle(
    fontSize: GchFontSize.caption2,
    fontWeight: GchFontWeight.bold,
    color: Color(0xFFFFFFFF),
    letterSpacing: GchLetterSpacing.wide,
    lineHeight: GchLineHeight.none,
  );

  static const GchTextStyle tabLabel = GchTextStyle(
    fontSize: GchFontSize.xs,
    fontWeight: GchFontWeight.medium,
    letterSpacing: GchLetterSpacing.normal,
    lineHeight: GchLineHeight.snug,
  );

  static const GchTextStyle sectionHeader = GchTextStyle(
    fontSize: GchFontSize.footnote,
    fontWeight: GchFontWeight.semiBold,
    color: Color(0xFF757575),
    letterSpacing: GchLetterSpacing.widest,
    lineHeight: GchLineHeight.snug,
  );

  static const GchTextStyle tooltip = GchTextStyle(
    fontSize: GchFontSize.xs,
    fontWeight: GchFontWeight.regular,
    color: Color(0xFFFFFFFF),
    letterSpacing: GchLetterSpacing.normal,
    lineHeight: GchLineHeight.normal,
  );

  static Map<String, GchTextStyle> get all => {
        'display1': display1,
        'display2': display2,
        'display3': display3,
        'h1': h1,
        'h2': h2,
        'h3': h3,
        'h4': h4,
        'h5': h5,
        'h6': h6,
        'body': body,
        'bodySmall': bodySmall,
        'bodyLarge': bodyLarge,
        'caption': caption,
        'overline': overline,
        'button': button,
        'buttonLarge': buttonLarge,
        'code': code,
        'codeBlock': codeBlock,
        'label': label,
        'hint': hint,
        'error': error,
        'link': link,
        'badge': badge,
        'tabLabel': tabLabel,
        'sectionHeader': sectionHeader,
        'tooltip': tooltip,
      };

  static GchTextStyle? byName(String name) => all[name];
}

class GchTextTheme {
  final GchTextStyle displayLarge;
  final GchTextStyle displayMedium;
  final GchTextStyle displaySmall;
  final GchTextStyle headlineLarge;
  final GchTextStyle headlineMedium;
  final GchTextStyle headlineSmall;
  final GchTextStyle titleLarge;
  final GchTextStyle titleMedium;
  final GchTextStyle titleSmall;
  final GchTextStyle bodyLarge;
  final GchTextStyle bodyMedium;
  final GchTextStyle bodySmall;
  final GchTextStyle labelLarge;
  final GchTextStyle labelMedium;
  final GchTextStyle labelSmall;

  const GchTextTheme({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });

  factory GchTextTheme.material3() {
    return const GchTextTheme(
      displayLarge: GchTextStyle(fontSize: 57, fontWeight: GchFontWeight.regular, letterSpacing: -0.25, lineHeight: 1.12),
      displayMedium: GchTextStyle(fontSize: 45, fontWeight: GchFontWeight.regular, letterSpacing: 0, lineHeight: 1.16),
      displaySmall: GchTextStyle(fontSize: 36, fontWeight: GchFontWeight.regular, letterSpacing: 0, lineHeight: 1.22),
      headlineLarge: GchTextStyle(fontSize: 32, fontWeight: GchFontWeight.regular, letterSpacing: 0, lineHeight: 1.25),
      headlineMedium: GchTextStyle(fontSize: 28, fontWeight: GchFontWeight.regular, letterSpacing: 0, lineHeight: 1.29),
      headlineSmall: GchTextStyle(fontSize: 24, fontWeight: GchFontWeight.regular, letterSpacing: 0, lineHeight: 1.33),
      titleLarge: GchTextStyle(fontSize: 22, fontWeight: GchFontWeight.regular, letterSpacing: 0, lineHeight: 1.27),
      titleMedium: GchTextStyle(fontSize: 16, fontWeight: GchFontWeight.medium, letterSpacing: 0.15, lineHeight: 1.5),
      titleSmall: GchTextStyle(fontSize: 14, fontWeight: GchFontWeight.medium, letterSpacing: 0.1, lineHeight: 1.43),
      bodyLarge: GchTextStyle(fontSize: 16, fontWeight: GchFontWeight.regular, letterSpacing: 0.5, lineHeight: 1.5),
      bodyMedium: GchTextStyle(fontSize: 14, fontWeight: GchFontWeight.regular, letterSpacing: 0.25, lineHeight: 1.43),
      bodySmall: GchTextStyle(fontSize: 12, fontWeight: GchFontWeight.regular, letterSpacing: 0.4, lineHeight: 1.33),
      labelLarge: GchTextStyle(fontSize: 14, fontWeight: GchFontWeight.medium, letterSpacing: 0.1, lineHeight: 1.43),
      labelMedium: GchTextStyle(fontSize: 12, fontWeight: GchFontWeight.medium, letterSpacing: 0.5, lineHeight: 1.33),
      labelSmall: GchTextStyle(fontSize: 11, fontWeight: GchFontWeight.medium, letterSpacing: 0.5, lineHeight: 1.45),
    );
  }

  factory GchTextTheme.compact() {
    return const GchTextTheme(
      displayLarge: GchTextStyle(fontSize: 48, fontWeight: GchFontWeight.bold, letterSpacing: -1.0, lineHeight: 1.08),
      displayMedium: GchTextStyle(fontSize: 36, fontWeight: GchFontWeight.bold, letterSpacing: -0.5, lineHeight: 1.11),
      displaySmall: GchTextStyle(fontSize: 28, fontWeight: GchFontWeight.bold, letterSpacing: -0.25, lineHeight: 1.14),
      headlineLarge: GchTextStyle(fontSize: 24, fontWeight: GchFontWeight.semiBold, letterSpacing: 0, lineHeight: 1.17),
      headlineMedium: GchTextStyle(fontSize: 22, fontWeight: GchFontWeight.semiBold, letterSpacing: 0, lineHeight: 1.18),
      headlineSmall: GchTextStyle(fontSize: 20, fontWeight: GchFontWeight.semiBold, letterSpacing: 0, lineHeight: 1.2),
      titleLarge: GchTextStyle(fontSize: 18, fontWeight: GchFontWeight.semiBold, letterSpacing: 0, lineHeight: 1.22),
      titleMedium: GchTextStyle(fontSize: 15, fontWeight: GchFontWeight.medium, letterSpacing: 0.1, lineHeight: 1.4),
      titleSmall: GchTextStyle(fontSize: 13, fontWeight: GchFontWeight.medium, letterSpacing: 0.1, lineHeight: 1.38),
      bodyLarge: GchTextStyle(fontSize: 15, fontWeight: GchFontWeight.regular, letterSpacing: 0.25, lineHeight: 1.47),
      bodyMedium: GchTextStyle(fontSize: 13, fontWeight: GchFontWeight.regular, letterSpacing: 0.25, lineHeight: 1.46),
      bodySmall: GchTextStyle(fontSize: 11, fontWeight: GchFontWeight.regular, letterSpacing: 0.4, lineHeight: 1.45),
      labelLarge: GchTextStyle(fontSize: 13, fontWeight: GchFontWeight.semiBold, letterSpacing: 0.1, lineHeight: 1.38),
      labelMedium: GchTextStyle(fontSize: 11, fontWeight: GchFontWeight.semiBold, letterSpacing: 0.5, lineHeight: 1.45),
      labelSmall: GchTextStyle(fontSize: 10, fontWeight: GchFontWeight.semiBold, letterSpacing: 0.5, lineHeight: 1.6),
    );
  }

  GchTextTheme copyWith({
    GchTextStyle? displayLarge,
    GchTextStyle? displayMedium,
    GchTextStyle? displaySmall,
    GchTextStyle? headlineLarge,
    GchTextStyle? headlineMedium,
    GchTextStyle? headlineSmall,
    GchTextStyle? titleLarge,
    GchTextStyle? titleMedium,
    GchTextStyle? titleSmall,
    GchTextStyle? bodyLarge,
    GchTextStyle? bodyMedium,
    GchTextStyle? bodySmall,
    GchTextStyle? labelLarge,
    GchTextStyle? labelMedium,
    GchTextStyle? labelSmall,
  }) {
    return GchTextTheme(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
    );
  }

  GchTextTheme scale(double factor) {
    return GchTextTheme(
      displayLarge: displayLarge.scale(factor),
      displayMedium: displayMedium.scale(factor),
      displaySmall: displaySmall.scale(factor),
      headlineLarge: headlineLarge.scale(factor),
      headlineMedium: headlineMedium.scale(factor),
      headlineSmall: headlineSmall.scale(factor),
      titleLarge: titleLarge.scale(factor),
      titleMedium: titleMedium.scale(factor),
      titleSmall: titleSmall.scale(factor),
      bodyLarge: bodyLarge.scale(factor),
      bodyMedium: bodyMedium.scale(factor),
      bodySmall: bodySmall.scale(factor),
      labelLarge: labelLarge.scale(factor),
      labelMedium: labelMedium.scale(factor),
      labelSmall: labelSmall.scale(factor),
    );
  }

  GchTextTheme withColor(Color color) {
    return GchTextTheme(
      displayLarge: displayLarge.withColor(color),
      displayMedium: displayMedium.withColor(color),
      displaySmall: displaySmall.withColor(color),
      headlineLarge: headlineLarge.withColor(color),
      headlineMedium: headlineMedium.withColor(color),
      headlineSmall: headlineSmall.withColor(color),
      titleLarge: titleLarge.withColor(color),
      titleMedium: titleMedium.withColor(color),
      titleSmall: titleSmall.withColor(color),
      bodyLarge: bodyLarge.withColor(color),
      bodyMedium: bodyMedium.withColor(color),
      bodySmall: bodySmall.withColor(color),
      labelLarge: labelLarge.withColor(color),
      labelMedium: labelMedium.withColor(color),
      labelSmall: labelSmall.withColor(color),
    );
  }

  GchTextStyle? byRole(String role) {
    switch (role) {
      case 'displayLarge': return displayLarge;
      case 'displayMedium': return displayMedium;
      case 'displaySmall': return displaySmall;
      case 'headlineLarge': return headlineLarge;
      case 'headlineMedium': return headlineMedium;
      case 'headlineSmall': return headlineSmall;
      case 'titleLarge': return titleLarge;
      case 'titleMedium': return titleMedium;
      case 'titleSmall': return titleSmall;
      case 'bodyLarge': return bodyLarge;
      case 'bodyMedium': return bodyMedium;
      case 'bodySmall': return bodySmall;
      case 'labelLarge': return labelLarge;
      case 'labelMedium': return labelMedium;
      case 'labelSmall': return labelSmall;
      default: return null;
    }
  }

  List<String> get roleNames => [
        'displayLarge', 'displayMedium', 'displaySmall',
        'headlineLarge', 'headlineMedium', 'headlineSmall',
        'titleLarge', 'titleMedium', 'titleSmall',
        'bodyLarge', 'bodyMedium', 'bodySmall',
        'labelLarge', 'labelMedium', 'labelSmall',
      ];

  Map<String, Map<String, dynamic>> toMap() {
    return {for (final role in roleNames) role: byRole(role)!.toMap()};
  }
}

class GchReadability {
  static double fleschKincaidScore(String text) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final sentences = text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;
    if (words.isEmpty || sentences == 0) return 0;
    final syllables = words.fold<int>(0, (sum, word) => sum + _countSyllables(word));
    final wordsCount = words.length;
    return 206.835 - 1.015 * (wordsCount / sentences) - 84.6 * (syllables / wordsCount);
  }

  static int _countSyllables(String word) {
    final cleaned = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (cleaned.isEmpty) return 1;
    int count = 0;
    bool prevVowel = false;
    for (final c in cleaned.split('')) {
      final isVowel = 'aeiou'.contains(c);
      if (isVowel && !prevVowel) count++;
      prevVowel = isVowel;
    }
    if (cleaned.endsWith('e') && count > 1) count--;
    return count < 1 ? 1 : count;
  }

  static int estimatedReadingTimeSeconds(String text, {int wordsPerMinute = 200}) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return ((words / wordsPerMinute) * 60).ceil();
  }

  static String readingTimeLabel(String text, {int wordsPerMinute = 200}) {
    final seconds = estimatedReadingTimeSeconds(text, wordsPerMinute: wordsPerMinute);
    if (seconds < 60) return '< 1 min read';
    final minutes = (seconds / 60).ceil();
    return '$minutes min read';
  }

  static int wordCount(String text) {
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  static int characterCount(String text, {bool includeSpaces = true}) {
    return includeSpaces ? text.length : text.replaceAll(' ', '').length;
  }

  static int sentenceCount(String text) {
    return text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;
  }

  static double averageWordLength(String text) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 0;
    final totalChars = words.fold<int>(0, (sum, w) => sum + w.length);
    return totalChars / words.length;
  }
}

class GchTextTransform {
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    if (maxLength <= ellipsis.length) return ellipsis.substring(0, maxLength);
    return text.substring(0, maxLength - ellipsis.length) + ellipsis;
  }

  static String truncateWords(String text, int maxWords, {String ellipsis = '...'}) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= maxWords) return text;
    return words.take(maxWords).join(' ') + ellipsis;
  }

  static String toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static String toCamelCase(String text) {
    final words = text.split(RegExp(r'[\s_\-]+'));
    if (words.isEmpty) return text;
    return words[0].toLowerCase() +
        words.skip(1).map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join('');
  }

  static String toPascalCase(String text) {
    final words = text.split(RegExp(r'[\s_\-]+'));
    return words.map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join('');
  }

  static String toSnakeCase(String text) {
    return text
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp(r'^_'), '')
        .toLowerCase();
  }

  static String toKebabCase(String text) {
    return toSnakeCase(text).replaceAll('_', '-');
  }

  static String repeat(String text, int count) {
    final buffer = StringBuffer();
    for (int i = 0; i < count; i++) {
      buffer.write(text);
    }
    return buffer.toString();
  }

  static String pad(String text, int totalLength, {String padChar = ' ', bool padRight = true}) {
    if (text.length >= totalLength) return text;
    final padding = padChar * (totalLength - text.length);
    return padRight ? text + padding : padding + text;
  }

  static String center(String text, int totalLength, {String padChar = ' '}) {
    if (text.length >= totalLength) return text;
    final totalPad = totalLength - text.length;
    final leftPad = totalPad ~/ 2;
    final rightPad = totalPad - leftPad;
    return padChar * leftPad + text + padChar * rightPad;
  }

  static List<String> wrap(String text, int lineWidth) {
    final words = text.split(' ');
    final lines = <String>[];
    final buffer = StringBuffer();
    for (final word in words) {
      if (buffer.isNotEmpty && buffer.length + 1 + word.length > lineWidth) {
        lines.add(buffer.toString());
        buffer.clear();
      }
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(word);
    }
    if (buffer.isNotEmpty) lines.add(buffer.toString());
    return lines;
  }

  static String initials(String name, {int maxChars = 2}) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final chars = parts
        .where((p) => p.isNotEmpty)
        .take(maxChars)
        .map((p) => p[0].toUpperCase())
        .join('');
    return chars;
  }

  static String highlight(String text, String query, {String before = '**', String after = '**'}) {
    if (query.isEmpty) return text;
    return text.replaceAll(query, '$before$query$after');
  }
}
