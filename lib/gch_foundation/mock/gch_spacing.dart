// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:ui' show Size, Offset, Rect, Color;

class GchSpacing {
  const GchSpacing._();

  static const double none = 0;
  static const double px1 = 1;
  static const double px2 = 2;
  static const double px4 = 4;
  static const double px6 = 6;
  static const double px8 = 8;
  static const double px10 = 10;
  static const double px12 = 12;
  static const double px14 = 14;
  static const double px16 = 16;
  static const double px18 = 18;
  static const double px20 = 20;
  static const double px24 = 24;
  static const double px28 = 28;
  static const double px32 = 32;
  static const double px36 = 36;
  static const double px40 = 40;
  static const double px48 = 48;
  static const double px56 = 56;
  static const double px64 = 64;
  static const double px80 = 80;
  static const double px96 = 96;
  static const double px112 = 112;
  static const double px128 = 128;
  static const double px160 = 160;
  static const double px192 = 192;
  static const double px224 = 224;
  static const double px256 = 256;

  static const double xs = px4;
  static const double sm = px8;
  static const double md = px16;
  static const double lg = px24;
  static const double xl = px32;
  static const double xxl = px48;
  static const double xxxl = px64;

  static const double micro = px2;
  static const double tiny = px4;
  static const double small = px8;
  static const double medium = px16;
  static const double large = px24;
  static const double huge = px48;
  static const double massive = px96;

  static const double componentSmall = px32;
  static const double componentMedium = px48;
  static const double componentLarge = px64;

  static const double iconSmall = px16;
  static const double iconMedium = px24;
  static const double iconLarge = px32;
  static const double iconXl = px48;

  static const double touchTarget = px44;
  static const double px44 = 44;

  static const double sectionSpacing = px40;
  static const double cardPadding = px20;
  static const double listItemHeight = px56;
  static const double appBarHeight = px56;
  static const double bottomNavHeight = px64;

  static double lerp(double a, double b, double t) => a + (b - a) * t;
  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static double rem(double remValue, {double baseFontSize = 16}) => remValue * baseFontSize;
  static double em(double emValue, double parentSize) => emValue * parentSize;

  static List<double> get scale4 => [px4, px8, px12, px16, px20, px24, px32, px40, px48, px64, px80, px96, px128];
  static List<double> get scale8 => [px8, px16, px24, px32, px48, px64, px96, px128];
}

class GchInsets {
  final double top;
  final double bottom;
  final double left;
  final double right;

  const GchInsets({
    this.top = 0,
    this.bottom = 0,
    this.left = 0,
    this.right = 0,
  });

  const GchInsets.all(double value)
      : top = value,
        bottom = value,
        left = value,
        right = value;

  const GchInsets.symmetric({double h = 0, double v = 0})
      : top = v,
        bottom = v,
        left = h,
        right = h;

  const GchInsets.only({
    double top = 0,
    double bottom = 0,
    double left = 0,
    double right = 0,
  })  : this.top = top,
        this.bottom = bottom,
        this.left = left,
        this.right = right;

  static const GchInsets zero = GchInsets.all(0);
  static const GchInsets tiny = GchInsets.all(GchSpacing.tiny);
  static const GchInsets small = GchInsets.all(GchSpacing.small);
  static const GchInsets medium = GchInsets.all(GchSpacing.medium);
  static const GchInsets large = GchInsets.all(GchSpacing.large);
  static const GchInsets huge = GchInsets.all(GchSpacing.huge);

  static GchInsets get topOnly => const GchInsets.only(top: GchSpacing.md);
  static GchInsets get bottomOnly => const GchInsets.only(bottom: GchSpacing.md);
  static GchInsets get leftOnly => const GchInsets.only(left: GchSpacing.md);
  static GchInsets get rightOnly => const GchInsets.only(right: GchSpacing.md);
  static GchInsets get horizontalMd => const GchInsets.symmetric(h: GchSpacing.md);
  static GchInsets get verticalMd => const GchInsets.symmetric(v: GchSpacing.md);
  static GchInsets get horizontalLg => const GchInsets.symmetric(h: GchSpacing.lg);
  static GchInsets get verticalLg => const GchInsets.symmetric(v: GchSpacing.lg);
  static GchInsets get cardDefault => const GchInsets.all(GchSpacing.cardPadding);

  double get horizontal => left + right;
  double get vertical => top + bottom;
  double get total => left + right + top + bottom;

  GchInsets copyWith({
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return GchInsets(
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
      right: right ?? this.right,
    );
  }

  GchInsets inflate(double delta) {
    return GchInsets(
      top: top + delta,
      bottom: bottom + delta,
      left: left + delta,
      right: right + delta,
    );
  }

  GchInsets deflate(double delta) {
    return GchInsets(
      top: (top - delta).clamp(0, double.infinity),
      bottom: (bottom - delta).clamp(0, double.infinity),
      left: (left - delta).clamp(0, double.infinity),
      right: (right - delta).clamp(0, double.infinity),
    );
  }

  GchInsets operator +(GchInsets other) {
    return GchInsets(
      top: top + other.top,
      bottom: bottom + other.bottom,
      left: left + other.left,
      right: right + other.right,
    );
  }

  GchInsets operator -(GchInsets other) {
    return GchInsets(
      top: (top - other.top).clamp(0, double.infinity),
      bottom: (bottom - other.bottom).clamp(0, double.infinity),
      left: (left - other.left).clamp(0, double.infinity),
      right: (right - other.right).clamp(0, double.infinity),
    );
  }

  GchInsets operator *(double factor) {
    return GchInsets(
      top: top * factor,
      bottom: bottom * factor,
      left: left * factor,
      right: right * factor,
    );
  }

  bool get isZero => top == 0 && bottom == 0 && left == 0 && right == 0;
  bool get isUniform => top == bottom && left == right && top == left;

  Rect deflateRect(Rect rect) {
    return Rect.fromLTRB(
      rect.left + left,
      rect.top + top,
      rect.right - right,
      rect.bottom - bottom,
    );
  }

  Rect inflateRect(Rect rect) {
    return Rect.fromLTRB(
      rect.left - left,
      rect.top - top,
      rect.right + right,
      rect.bottom + bottom,
    );
  }

  Size inflateSize(Size size) {
    return Size(size.width + horizontal, size.height + vertical);
  }

  Size deflateSize(Size size) {
    return Size(
      (size.width - horizontal).clamp(0, double.infinity),
      (size.height - vertical).clamp(0, double.infinity),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GchInsets) return false;
    return top == other.top &&
        bottom == other.bottom &&
        left == other.left &&
        right == other.right;
  }

  @override
  int get hashCode => Object.hash(top, bottom, left, right);

  @override
  String toString() => 'GchInsets(t=$top, b=$bottom, l=$left, r=$right)';

  Map<String, double> toMap() => {'top': top, 'bottom': bottom, 'left': left, 'right': right};

  factory GchInsets.fromMap(Map<String, double> map) {
    return GchInsets(
      top: map['top'] ?? 0,
      bottom: map['bottom'] ?? 0,
      left: map['left'] ?? 0,
      right: map['right'] ?? 0,
    );
  }

  static GchInsets lerp(GchInsets a, GchInsets b, double t) {
    return GchInsets(
      top: a.top + (b.top - a.top) * t,
      bottom: a.bottom + (b.bottom - a.bottom) * t,
      left: a.left + (b.left - a.left) * t,
      right: a.right + (b.right - a.right) * t,
    );
  }
}

class GchRadius {
  final double topLeft;
  final double topRight;
  final double bottomLeft;
  final double bottomRight;

  const GchRadius({
    this.topLeft = 0,
    this.topRight = 0,
    this.bottomLeft = 0,
    this.bottomRight = 0,
  });

  const GchRadius.all(double value)
      : topLeft = value,
        topRight = value,
        bottomLeft = value,
        bottomRight = value;

  const GchRadius.only({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  })  : this.topLeft = topLeft,
        this.topRight = topRight,
        this.bottomLeft = bottomLeft,
        this.bottomRight = bottomRight;

  const GchRadius.circular(double radius) : this.all(radius);

  const GchRadius.elliptical(double horizontal, double vertical)
      : topLeft = horizontal,
        topRight = horizontal,
        bottomLeft = vertical,
        bottomRight = vertical;

  static const GchRadius none = GchRadius.all(0);
  static const GchRadius xs = GchRadius.all(2);
  static const GchRadius sm = GchRadius.all(4);
  static const GchRadius md = GchRadius.all(8);
  static const GchRadius lg = GchRadius.all(12);
  static const GchRadius xl = GchRadius.all(16);
  static const GchRadius xxl = GchRadius.all(24);
  static const GchRadius card = GchRadius.all(12);
  static const GchRadius button = GchRadius.all(8);
  static const GchRadius chip = GchRadius.all(20);
  static const GchRadius dialog = GchRadius.all(16);
  static const GchRadius sheet = GchRadius.only(topLeft: 20, topRight: 20);
  static const GchRadius topSheet = GchRadius.only(bottomLeft: 20, bottomRight: 20);
  static const GchRadius full = GchRadius.all(9999);

  static const GchRadius avatar = GchRadius.all(9999);
  static const GchRadius badge = GchRadius.all(9999);
  static const GchRadius input = GchRadius.all(8);
  static const GchRadius banner = GchRadius.all(4);
  static const GchRadius tooltip = GchRadius.all(4);

  GchRadius copyWith({
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
  }) {
    return GchRadius(
      topLeft: topLeft ?? this.topLeft,
      topRight: topRight ?? this.topRight,
      bottomLeft: bottomLeft ?? this.bottomLeft,
      bottomRight: bottomRight ?? this.bottomRight,
    );
  }

  GchRadius scale(double factor) {
    return GchRadius(
      topLeft: topLeft * factor,
      topRight: topRight * factor,
      bottomLeft: bottomLeft * factor,
      bottomRight: bottomRight * factor,
    );
  }

  bool get isCircular => topLeft == topRight && topLeft == bottomLeft && topLeft == bottomRight;
  bool get isNone => topLeft == 0 && topRight == 0 && bottomLeft == 0 && bottomRight == 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GchRadius) return false;
    return topLeft == other.topLeft &&
        topRight == other.topRight &&
        bottomLeft == other.bottomLeft &&
        bottomRight == other.bottomRight;
  }

  @override
  int get hashCode => Object.hash(topLeft, topRight, bottomLeft, bottomRight);

  @override
  String toString() => 'GchRadius(tl=$topLeft, tr=$topRight, bl=$bottomLeft, br=$bottomRight)';

  Map<String, double> toMap() => {
        'topLeft': topLeft,
        'topRight': topRight,
        'bottomLeft': bottomLeft,
        'bottomRight': bottomRight,
      };

  static GchRadius lerp(GchRadius a, GchRadius b, double t) {
    return GchRadius(
      topLeft: a.topLeft + (b.topLeft - a.topLeft) * t,
      topRight: a.topRight + (b.topRight - a.topRight) * t,
      bottomLeft: a.bottomLeft + (b.bottomLeft - a.bottomLeft) * t,
      bottomRight: a.bottomRight + (b.bottomRight - a.bottomRight) * t,
    );
  }
}

class GchShadow {
  final Color color;
  final Offset offset;
  final double blur;
  final double spread;

  const GchShadow({
    this.color = const Color(0x1A000000),
    this.offset = Offset.zero,
    this.blur = 0,
    this.spread = 0,
  });

  factory GchShadow.none() => const GchShadow();

  factory GchShadow.subtle() => const GchShadow(
        color: Color(0x0D000000),
        offset: Offset(0, 1),
        blur: 2,
        spread: 0,
      );

  factory GchShadow.soft() => const GchShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 2),
        blur: 4,
        spread: 0,
      );

  factory GchShadow.medium() => const GchShadow(
        color: Color(0x26000000),
        offset: Offset(0, 4),
        blur: 8,
        spread: -2,
      );

  factory GchShadow.large() => const GchShadow(
        color: Color(0x33000000),
        offset: Offset(0, 8),
        blur: 16,
        spread: -4,
      );

  factory GchShadow.xl() => const GchShadow(
        color: Color(0x40000000),
        offset: Offset(0, 16),
        blur: 32,
        spread: -8,
      );

  factory GchShadow.colored(Color color, {double blur = 8, Offset offset = Offset.zero, double spread = 0}) {
    return GchShadow(color: color, blur: blur, offset: offset, spread: spread);
  }

  GchShadow copyWith({
    Color? color,
    Offset? offset,
    double? blur,
    double? spread,
  }) {
    return GchShadow(
      color: color ?? this.color,
      offset: offset ?? this.offset,
      blur: blur ?? this.blur,
      spread: spread ?? this.spread,
    );
  }

  GchShadow scale(double factor) {
    return GchShadow(
      color: color,
      offset: Offset(offset.dx * factor, offset.dy * factor),
      blur: blur * factor,
      spread: spread * factor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'colorHex': color.value.toRadixString(16).padLeft(8, '0'),
      'offsetX': offset.dx,
      'offsetY': offset.dy,
      'blur': blur,
      'spread': spread,
    };
  }

  factory GchShadow.fromMap(Map<String, dynamic> map) {
    final colorHex = map['colorHex'] as String? ?? '1a000000';
    final colorVal = int.parse(colorHex, radix: 16);
    return GchShadow(
      color: Color(colorVal),
      offset: Offset(
        (map['offsetX'] as num?)?.toDouble() ?? 0,
        (map['offsetY'] as num?)?.toDouble() ?? 0,
      ),
      blur: (map['blur'] as num?)?.toDouble() ?? 0,
      spread: (map['spread'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get isNone => blur == 0 && spread == 0 && offset == Offset.zero;

  static const GchShadow elevation1 = GchShadow(
    color: Color(0x1F000000),
    offset: Offset(0, 1),
    blur: 3,
    spread: 0,
  );

  static const GchShadow elevation2 = GchShadow(
    color: Color(0x29000000),
    offset: Offset(0, 2),
    blur: 6,
    spread: 0,
  );

  static const GchShadow elevation4 = GchShadow(
    color: Color(0x33000000),
    offset: Offset(0, 4),
    blur: 8,
    spread: -1,
  );

  static const GchShadow elevation8 = GchShadow(
    color: Color(0x3D000000),
    offset: Offset(0, 8),
    blur: 16,
    spread: -2,
  );

  static const GchShadow elevation16 = GchShadow(
    color: Color(0x47000000),
    offset: Offset(0, 16),
    blur: 32,
    spread: -4,
  );

  static const GchShadow elevation24 = GchShadow(
    color: Color(0x52000000),
    offset: Offset(0, 24),
    blur: 48,
    spread: -8,
  );

  static const GchShadow inner = GchShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 2),
    blur: 4,
    spread: -1,
  );

  static const GchShadow cardShadow = GchShadow(
    color: Color(0x14000000),
    offset: Offset(0, 2),
    blur: 8,
    spread: 0,
  );

  static const GchShadow dialogShadow = GchShadow(
    color: Color(0x40000000),
    offset: Offset(0, 12),
    blur: 40,
    spread: 0,
  );

  static const GchShadow popupShadow = GchShadow(
    color: Color(0x29000000),
    offset: Offset(0, 6),
    blur: 20,
    spread: 0,
  );

  static const GchShadow buttonShadow = GchShadow(
    color: Color(0x33000000),
    offset: Offset(0, 2),
    blur: 6,
    spread: 0,
  );

  static const GchShadow headerShadow = GchShadow(
    color: Color(0x1F000000),
    offset: Offset(0, 2),
    blur: 4,
    spread: 0,
  );

  static const GchShadow focusRing = GchShadow(
    color: Color(0x401976D2),
    offset: Offset.zero,
    blur: 0,
    spread: 3,
  );

  static const GchShadow errorRing = GchShadow(
    color: Color(0x40D32F2F),
    offset: Offset.zero,
    blur: 0,
    spread: 3,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GchShadow) return false;
    return color == other.color &&
        offset == other.offset &&
        blur == other.blur &&
        spread == other.spread;
  }

  @override
  int get hashCode => Object.hash(color, offset, blur, spread);

  @override
  String toString() => 'GchShadow(color=${color.value.toRadixString(16)}, offset=$offset, blur=$blur, spread=$spread)';
}

class GchBreakpoint {
  const GchBreakpoint._();

  static const double xs = 0;
  static const double sm = 640;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1280;
  static const double xxl = 1536;

  static const Map<String, double> values = {
    'xs': xs,
    'sm': sm,
    'md': md,
    'lg': lg,
    'xl': xl,
    'xxl': xxl,
  };

  static String current(double width) {
    if (width >= xxl) return 'xxl';
    if (width >= xl) return 'xl';
    if (width >= lg) return 'lg';
    if (width >= md) return 'md';
    if (width >= sm) return 'sm';
    return 'xs';
  }

  static bool isXs(double width) => width < sm;
  static bool isSm(double width) => width >= sm && width < md;
  static bool isMd(double width) => width >= md && width < lg;
  static bool isLg(double width) => width >= lg && width < xl;
  static bool isXl(double width) => width >= xl && width < xxl;
  static bool isXxl(double width) => width >= xxl;

  static bool isMobile(double width) => width < md;
  static bool isTablet(double width) => width >= md && width < lg;
  static bool isDesktop(double width) => width >= lg;

  static T responsive<T>(
    double width, {
    required T xs,
    T? sm,
    T? md,
    T? lg,
    T? xl,
    T? xxl,
  }) {
    if (width >= GchBreakpoint.xxl && xxl != null) return xxl;
    if (width >= GchBreakpoint.xl && xl != null) return xl;
    if (width >= GchBreakpoint.lg && lg != null) return lg;
    if (width >= GchBreakpoint.md && md != null) return md;
    if (width >= GchBreakpoint.sm && sm != null) return sm;
    return xs;
  }

  static double columns(double width) {
    if (width >= xxl) return 12;
    if (width >= xl) return 12;
    if (width >= lg) return 10;
    if (width >= md) return 8;
    if (width >= sm) return 6;
    return 4;
  }

  static double gutter(double width) {
    if (width >= lg) return GchSpacing.px24;
    if (width >= md) return GchSpacing.px20;
    return GchSpacing.px16;
  }

  static double margin(double width) {
    if (width >= xxl) return GchSpacing.px96;
    if (width >= xl) return GchSpacing.px64;
    if (width >= lg) return GchSpacing.px48;
    if (width >= md) return GchSpacing.px32;
    return GchSpacing.px16;
  }

  static double containerMaxWidth(double width) {
    if (width >= xxl) return 1536;
    if (width >= xl) return 1280;
    if (width >= lg) return 1024;
    if (width >= md) return 768;
    if (width >= sm) return 640;
    return double.infinity;
  }

  static int gridColumns(double width) {
    if (isMobile(width)) return 1;
    if (isTablet(width)) return 2;
    if (isLg(width)) return 3;
    return 4;
  }
}

class GchLayout {
  const GchLayout._();

  static const double maxContentWidth = 1200;
  static const double sidebarWidth = 280;
  static const double navRailWidth = 72;
  static const double drawerWidth = 320;
  static const double minTouchTarget = 44;
  static const double minClickTarget = 32;
  static const double statusBarHeight = 24;
  static const double navigationBarHeight = 48;
  static const double tabBarHeight = 48;
  static const double toolbarHeight = 56;
  static const double floatingBarHeight = 64;
  static const double bottomSheetMinHeight = 100;
  static const double snackbarHeight = 48;
  static const double toastHeight = 40;
  static const double chipHeight = 32;
  static const double chipHeightSmall = 24;
  static const double chipHeightLarge = 40;
  static const double inputHeight = 48;
  static const double inputHeightSmall = 36;
  static const double inputHeightLarge = 56;
  static const double buttonHeightSmall = 32;
  static const double buttonHeightMedium = 40;
  static const double buttonHeightLarge = 48;
  static const double buttonHeightXl = 56;
  static const double avatarSizeXs = 24;
  static const double avatarSizeSm = 32;
  static const double avatarSizeMd = 40;
  static const double avatarSizeLg = 56;
  static const double avatarSizeXl = 72;
  static const double cardMinHeight = 80;
  static const double listTileHeight = 56;
  static const double listTileDenseHeight = 40;
  static const double dividerHeight = 1;
  static const double dividerThickness = 1;
  static const double borderWidth = 1;
  static const double borderWidthMedium = 2;
  static const double borderWidthThick = 4;
  static const double iconButtonSize = 48;
  static const double iconButtonSizeSmall = 36;
  static const double iconButtonSizeLarge = 56;
  static const double progressBarHeight = 4;
  static const double progressBarHeightThick = 8;
  static const double sliderHeight = 4;
  static const double sliderThumbSize = 20;
  static const double checkboxSize = 18;
  static const double radioSize = 20;
  static const double switchWidth = 51;
  static const double switchHeight = 31;

  static double safeAreaTop({double statusBarHeight = 44}) => statusBarHeight;
  static double safeAreaBottom({double homeIndicator = 34}) => homeIndicator;

  static double contentPadding(double screenWidth) {
    if (screenWidth >= GchBreakpoint.xl) return GchSpacing.px48;
    if (screenWidth >= GchBreakpoint.lg) return GchSpacing.px32;
    if (screenWidth >= GchBreakpoint.md) return GchSpacing.px24;
    return GchSpacing.px16;
  }

  static double centeredContentMaxWidth(double screenWidth) {
    return screenWidth > maxContentWidth ? maxContentWidth : screenWidth;
  }
}

class GchZIndex {
  const GchZIndex._();

  static const int below = -1;
  static const int base = 0;
  static const int raised = 1;
  static const int dropdown = 100;
  static const int sticky = 200;
  static const int fixed = 300;
  static const int overlay = 400;
  static const int modal = 500;
  static const int popover = 600;
  static const int toast = 700;
  static const int tooltip = 800;
  static const int max = 9999;
}

class GchMotion {
  const GchMotion._();

  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration faster = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slower = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration deliberate = Duration(milliseconds: 500);
  static const Duration gentle = Duration(milliseconds: 700);
  static const Duration lazy = Duration(milliseconds: 1000);

  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration dialogOpen = Duration(milliseconds: 250);
  static const Duration dialogClose = Duration(milliseconds: 200);
  static const Duration sheetOpen = Duration(milliseconds: 350);
  static const Duration sheetClose = Duration(milliseconds: 280);
  static const Duration menuOpen = Duration(milliseconds: 200);
  static const Duration menuClose = Duration(milliseconds: 150);
  static const Duration fadeIn = Duration(milliseconds: 250);
  static const Duration fadeOut = Duration(milliseconds: 200);
  static const Duration snackbar = Duration(milliseconds: 300);
  static const Duration skeleton = Duration(milliseconds: 1500);

  static Duration scaled(Duration base, double factor) {
    return Duration(microseconds: (base.inMicroseconds * factor).round());
  }

  static Duration lerp(Duration a, Duration b, double t) {
    return Duration(
      microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t).round(),
    );
  }
}

class GchIconSize {
  const GchIconSize._();

  static const double micro = 12;
  static const double xs = 14;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double hero = 48;
  static const double display = 64;
  static const double avatar = 24;
  static const double navIcon = 24;
  static const double tabIcon = 22;
  static const double buttonIconSmall = 16;
  static const double buttonIconMedium = 18;
  static const double buttonIconLarge = 20;
  static const double inputPrefix = 20;
  static const double inputSuffix = 20;
  static const double listLeading = 24;
  static const double listTrailing = 20;
  static const double chipIcon = 16;
  static const double badgeIcon = 12;

  static double forButton(double buttonHeight) {
    if (buttonHeight <= 32) return sm;
    if (buttonHeight <= 40) return md;
    if (buttonHeight <= 48) return lg;
    return xl;
  }
}

class GchOpacity {
  const GchOpacity._();

  static const double transparent = 0.0;
  static const double subtle = 0.04;
  static const double faint = 0.08;
  static const double light = 0.12;
  static const double muted = 0.20;
  static const double low = 0.32;
  static const double medium = 0.48;
  static const double high = 0.64;
  static const double strong = 0.80;
  static const double heavy = 0.90;
  static const double nearOpaque = 0.95;
  static const double opaque = 1.0;

  static const double hoverOverlay = 0.08;
  static const double pressOverlay = 0.12;
  static const double focusOverlay = 0.16;
  static const double selectedOverlay = 0.20;
  static const double disabledContent = 0.38;
  static const double disabledSurface = 0.12;
  static const double scrim = 0.54;
  static const double heavyScrim = 0.72;

  static double lerp(double a, double b, double t) => a + (b - a) * t;
  static double clamp(double v) => v.clamp(0.0, 1.0);
  static int toAlpha(double opacity) => (opacity * 255).round().clamp(0, 255);
  static double fromAlpha(int alpha) => alpha / 255.0;
}
