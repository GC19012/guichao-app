// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';

class GchEasing {
  const GchEasing._();

  static double linear(double t) => t;

  static double easeIn(double t) => t * t * t;

  static double easeOut(double t) {
    final s = 1 - t;
    return 1 - s * s * s;
  }

  static double easeInOut(double t) {
    if (t < 0.5) return 4 * t * t * t;
    final s = -2 * t + 2;
    return 1 - s * s * s / 2;
  }

  static double easeInSine(double t) => 1 - cos((t * pi) / 2);

  static double easeOutSine(double t) => sin((t * pi) / 2);

  static double easeInOutSine(double t) => -(cos(pi * t) - 1) / 2;

  static double easeInQuad(double t) => t * t;

  static double easeOutQuad(double t) => 1 - (1 - t) * (1 - t);

  static double easeInOutQuad(double t) {
    if (t < 0.5) return 2 * t * t;
    return 1 - pow(-2 * t + 2, 2) / 2;
  }

  static double easeInCubic(double t) => t * t * t;

  static double easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();

  static double easeInOutCubic(double t) {
    if (t < 0.5) return 4 * t * t * t;
    return 1 - pow(-2 * t + 2, 3) / 2;
  }

  static double easeInQuart(double t) => t * t * t * t;

  static double easeOutQuart(double t) => 1 - pow(1 - t, 4).toDouble();

  static double easeInOutQuart(double t) {
    if (t < 0.5) return 8 * t * t * t * t;
    return 1 - pow(-2 * t + 2, 4) / 2;
  }

  static double easeInQuint(double t) => t * t * t * t * t;

  static double easeOutQuint(double t) => 1 - pow(1 - t, 5).toDouble();

  static double easeInOutQuint(double t) {
    if (t < 0.5) return 16 * t * t * t * t * t;
    return 1 - pow(-2 * t + 2, 5) / 2;
  }

  static double easeInExpo(double t) {
    if (t == 0) return 0;
    return pow(2, 10 * t - 10).toDouble();
  }

  static double easeOutExpo(double t) {
    if (t == 1) return 1;
    return 1 - pow(2, -10 * t).toDouble();
  }

  static double easeInOutExpo(double t) {
    if (t == 0) return 0;
    if (t == 1) return 1;
    if (t < 0.5) return pow(2, 20 * t - 10) / 2;
    return (2 - pow(2, -20 * t + 10)) / 2;
  }

  static double easeInCirc(double t) => 1 - sqrt(1 - pow(t, 2).toDouble());

  static double easeOutCirc(double t) => sqrt(1 - pow(t - 1, 2).toDouble());

  static double easeInOutCirc(double t) {
    if (t < 0.5) return (1 - sqrt(1 - pow(2 * t, 2).toDouble())) / 2;
    return (sqrt(1 - pow(-2 * t + 2, 2).toDouble()) + 1) / 2;
  }

  static double easeInBack(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return c3 * t * t * t - c1 * t * t;
  }

  static double easeOutBack(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2);
  }

  static double easeInOutBack(double t) {
    const c1 = 1.70158;
    const c2 = c1 * 1.525;
    if (t < 0.5) {
      return (pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2;
    }
    return (pow(2 * t - 2, 2) * ((c2 + 1) * (2 * t - 2) + c2) + 2) / 2;
  }

  static double easeInElastic(double t) {
    const c4 = (2 * pi) / 3;
    if (t == 0) return 0;
    if (t == 1) return 1;
    return -pow(2, 10 * t - 10) * sin((t * 10 - 10.75) * c4);
  }

  static double easeOutElastic(double t) {
    const c4 = (2 * pi) / 3;
    if (t == 0) return 0;
    if (t == 1) return 1;
    return pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1;
  }

  static double easeInOutElastic(double t) {
    const c5 = (2 * pi) / 4.5;
    if (t == 0) return 0;
    if (t == 1) return 1;
    if (t < 0.5) {
      return -(pow(2, 20 * t - 10) * sin((20 * t - 11.125) * c5)) / 2;
    }
    return (pow(2, -20 * t + 10) * sin((20 * t - 11.125) * c5)) / 2 + 1;
  }

  static double easeOutBounce(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;
    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      final tt = t - 1.5 / d1;
      return n1 * tt * tt + 0.75;
    } else if (t < 2.5 / d1) {
      final tt = t - 2.25 / d1;
      return n1 * tt * tt + 0.9375;
    } else {
      final tt = t - 2.625 / d1;
      return n1 * tt * tt + 0.984375;
    }
  }

  static double easeInBounce(double t) => 1 - easeOutBounce(1 - t);

  static double easeInOutBounce(double t) {
    if (t < 0.5) return (1 - easeOutBounce(1 - 2 * t)) / 2;
    return (1 + easeOutBounce(2 * t - 1)) / 2;
  }

  static double Function(double) spring(double stiffness, double damping, double mass) {
    final omega = sqrt(stiffness / mass);
    final zeta = damping / (2 * sqrt(stiffness * mass));
    if (zeta < 1) {
      final omegaD = omega * sqrt(1 - zeta * zeta);
      return (double t) {
        if (t <= 0) return 0;
        if (t >= 1) return 1;
        final scaled = t * 10;
        final decay = exp(-zeta * omega * scaled);
        final osc = cos(omegaD * scaled) + (zeta * omega / omegaD) * sin(omegaD * scaled);
        return 1 - decay * osc;
      };
    } else {
      return (double t) {
        if (t <= 0) return 0;
        if (t >= 1) return 1;
        final scaled = t * 10;
        final decay = exp(-zeta * omega * scaled);
        return 1 - decay * (1 + zeta * omega * scaled);
      };
    }
  }

  static double Function(double) steps(int count, {bool jumpStart = false}) {
    return (double t) {
      if (t <= 0) return 0;
      if (t >= 1) return 1;
      final step = jumpStart ? (t * count).ceil() : (t * count).floor();
      return step / count;
    };
  }

  static double Function(double) cubicBezier(double x1, double y1, double x2, double y2) {
    double calcBezier(double t, double p1, double p2) {
      return 3 * (1 - t) * (1 - t) * t * p1 + 3 * (1 - t) * t * t * p2 + t * t * t;
    }

    double getTForX(double xTarget) {
      double t = xTarget;
      for (int i = 0; i < 8; i++) {
        final x = calcBezier(t, x1, x2) - xTarget;
        final dx = 3 * (1 - t) * (1 - t) * x1 + 6 * (1 - t) * t * (x2 - x1) + 3 * t * t * (1 - x2);
        if (dx.abs() < 1e-6) break;
        t -= x / dx;
        t = t.clamp(0.0, 1.0);
      }
      return t;
    }

    return (double t) {
      if (t <= 0) return 0;
      if (t >= 1) return 1;
      final tForX = getTForX(t);
      return calcBezier(tForX, y1, y2);
    };
  }
}

class GchInterpolator {
  const GchInterpolator._();

  static double lerp(double a, double b, double t) => a + (b - a) * t;

  static double inverseLerp(double a, double b, double value) {
    if ((b - a).abs() < 1e-10) return 0;
    return (value - a) / (b - a);
  }

  static double remap(
    double value,
    double inMin,
    double inMax,
    double outMin,
    double outMax,
  ) {
    final t = inverseLerp(inMin, inMax, value).clamp(0.0, 1.0);
    return lerp(outMin, outMax, t);
  }

  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static double smoothStep(double edge0, double edge1, double t) {
    final x = clamp((t - edge0) / (edge1 - edge0), 0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static double smootherStep(double edge0, double edge1, double t) {
    final x = clamp((t - edge0) / (edge1 - edge0), 0.0, 1.0);
    return x * x * x * (x * (x * 6 - 15) + 10);
  }

  static double lerpList(List<double> values, double t) {
    if (values.isEmpty) return 0;
    if (values.length == 1) return values[0];
    final clamped = t.clamp(0.0, 1.0);
    final scaledT = clamped * (values.length - 1);
    final idx = scaledT.floor();
    if (idx >= values.length - 1) return values.last;
    final localT = scaledT - idx;
    return lerp(values[idx], values[idx + 1], localT);
  }

  static int lerpColor(int aInt, int bInt, double t) {
    final aA = (aInt >> 24) & 0xFF;
    final aR = (aInt >> 16) & 0xFF;
    final aG = (aInt >> 8) & 0xFF;
    final aB = aInt & 0xFF;
    final bA = (bInt >> 24) & 0xFF;
    final bR = (bInt >> 16) & 0xFF;
    final bG = (bInt >> 8) & 0xFF;
    final bB = bInt & 0xFF;
    final rA = (aA + (bA - aA) * t).round();
    final rR = (aR + (bR - aR) * t).round();
    final rG = (aG + (bG - aG) * t).round();
    final rB = (aB + (bB - aB) * t).round();
    return (rA << 24) | (rR << 16) | (rG << 8) | rB;
  }

  static double pingPong(double t) {
    final mod = t % 2.0;
    if (mod <= 1.0) return mod;
    return 2.0 - mod;
  }

  static double repeat(double t, double length) {
    if (length <= 0) return 0;
    return t % length;
  }

  static double damp(double current, double target, double lambda, double dt) {
    return lerp(target, current, exp(-lambda * dt));
  }

  static List<double> sampleCurve(
    double Function(double) curve, {
    int count = 100,
    double start = 0,
    double end = 1,
  }) {
    return List.generate(count, (i) {
      final t = start + (end - start) * i / (count - 1);
      return curve(t);
    });
  }

  static double bezier1D(double t, double p0, double p1, double p2, double p3) {
    final u = 1 - t;
    return u * u * u * p0 + 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t * p3;
  }
}

class GchAnimationCurveData {
  final List<double> samples;
  final int sampleCount;

  GchAnimationCurveData._({required this.samples}) : sampleCount = samples.length;

  factory GchAnimationCurveData.fromEasing(
    double Function(double) easing, {
    int sampleCount = 100,
  }) {
    final s = List<double>.generate(sampleCount, (i) {
      final t = i / (sampleCount - 1);
      return easing(t);
    });
    return GchAnimationCurveData._(samples: s);
  }

  double evaluate(double t) {
    if (t <= 0) return samples.first;
    if (t >= 1) return samples.last;
    final scaledT = t * (sampleCount - 1);
    final idx = scaledT.floor();
    if (idx >= sampleCount - 1) return samples.last;
    final localT = scaledT - idx;
    return samples[idx] + (samples[idx + 1] - samples[idx]) * localT;
  }

  GchAnimationCurveData get reverse {
    return GchAnimationCurveData._(samples: samples.reversed.toList());
  }

  GchAnimationCurveData compose(GchAnimationCurveData other) {
    final composed = List<double>.generate(sampleCount, (i) {
      final t = i / (sampleCount - 1);
      final firstValue = evaluate(t);
      return other.evaluate(firstValue);
    });
    return GchAnimationCurveData._(samples: composed);
  }

  GchAnimationCurveData blend(GchAnimationCurveData other, double weight) {
    final blended = List<double>.generate(sampleCount, (i) {
      final t = i / (sampleCount - 1);
      return evaluate(t) * (1 - weight) + other.evaluate(t) * weight;
    });
    return GchAnimationCurveData._(samples: blended);
  }

  static GchAnimationCurveData get linear =>
      GchAnimationCurveData.fromEasing(GchEasing.linear);
  static GchAnimationCurveData get easeIn =>
      GchAnimationCurveData.fromEasing(GchEasing.easeIn);
  static GchAnimationCurveData get easeOut =>
      GchAnimationCurveData.fromEasing(GchEasing.easeOut);
  static GchAnimationCurveData get easeInOut =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInOut);
  static GchAnimationCurveData get easeInSine =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInSine);
  static GchAnimationCurveData get easeOutSine =>
      GchAnimationCurveData.fromEasing(GchEasing.easeOutSine);
  static GchAnimationCurveData get easeInOutSine =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInOutSine);
  static GchAnimationCurveData get easeInQuad =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInQuad);
  static GchAnimationCurveData get easeOutQuad =>
      GchAnimationCurveData.fromEasing(GchEasing.easeOutQuad);
  static GchAnimationCurveData get easeInOutQuad =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInOutQuad);
  static GchAnimationCurveData get easeInCubic =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInCubic);
  static GchAnimationCurveData get easeOutCubic =>
      GchAnimationCurveData.fromEasing(GchEasing.easeOutCubic);
  static GchAnimationCurveData get easeInOutCubic =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInOutCubic);
  static GchAnimationCurveData get easeInQuart =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInQuart);
  static GchAnimationCurveData get easeOutQuart =>
      GchAnimationCurveData.fromEasing(GchEasing.easeOutQuart);
  static GchAnimationCurveData get easeInOutQuart =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInOutQuart);
  static GchAnimationCurveData get easeInBack =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInBack);
  static GchAnimationCurveData get easeOutBack =>
      GchAnimationCurveData.fromEasing(GchEasing.easeOutBack);
  static GchAnimationCurveData get easeInOutBack =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInOutBack);
  static GchAnimationCurveData get easeInElastic =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInElastic);
  static GchAnimationCurveData get easeOutElastic =>
      GchAnimationCurveData.fromEasing(GchEasing.easeOutElastic);
  static GchAnimationCurveData get easeInOutElastic =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInOutElastic);
  static GchAnimationCurveData get easeInBounce =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInBounce);
  static GchAnimationCurveData get easeOutBounce =>
      GchAnimationCurveData.fromEasing(GchEasing.easeOutBounce);
  static GchAnimationCurveData get easeInOutBounce =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInOutBounce);
  static GchAnimationCurveData get easeInExpo =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInExpo);
  static GchAnimationCurveData get easeOutExpo =>
      GchAnimationCurveData.fromEasing(GchEasing.easeOutExpo);
  static GchAnimationCurveData get easeInOutExpo =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInOutExpo);
  static GchAnimationCurveData get easeInCirc =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInCirc);
  static GchAnimationCurveData get easeOutCirc =>
      GchAnimationCurveData.fromEasing(GchEasing.easeOutCirc);
  static GchAnimationCurveData get easeInOutCirc =>
      GchAnimationCurveData.fromEasing(GchEasing.easeInOutCirc);
}

class GchKeyframe<T> {
  final double time;
  final T value;
  final double Function(double)? easing;

  const GchKeyframe({
    required this.time,
    required this.value,
    this.easing,
  });

  GchKeyframe<T> copyWith({
    double? time,
    T? value,
    double Function(double)? easing,
  }) {
    return GchKeyframe<T>(
      time: time ?? this.time,
      value: value ?? this.value,
      easing: easing ?? this.easing,
    );
  }

  @override
  String toString() => 'GchKeyframe(time=$time, value=$value)';
}

class GchTimeline<T> {
  final List<GchKeyframe<T>> _keyframes = [];

  void addKeyframe(GchKeyframe<T> kf) {
    _keyframes.add(kf);
    _keyframes.sort((a, b) => a.time.compareTo(b.time));
  }

  void removeKeyframeAt(double time) {
    _keyframes.removeWhere((kf) => (kf.time - time).abs() < 1e-9);
  }

  double get duration {
    if (_keyframes.isEmpty) return 0;
    return _keyframes.last.time;
  }

  int get keyframeCount => _keyframes.length;
  bool get isEmpty => _keyframes.isEmpty;
  List<GchKeyframe<T>> get keyframes => List.unmodifiable(_keyframes);

  T evaluate(double time, T Function(T a, T b, double t) lerp) {
    if (_keyframes.isEmpty) throw StateError('Timeline has no keyframes');
    if (_keyframes.length == 1) return _keyframes[0].value;

    if (time <= _keyframes.first.time) return _keyframes.first.value;
    if (time >= _keyframes.last.time) return _keyframes.last.value;

    for (int i = 0; i < _keyframes.length - 1; i++) {
      final a = _keyframes[i];
      final b = _keyframes[i + 1];
      if (time >= a.time && time <= b.time) {
        final duration = b.time - a.time;
        if (duration <= 0) return a.value;
        double t = (time - a.time) / duration;
        final easingFn = b.easing ?? GchEasing.linear;
        t = easingFn(t);
        return lerp(a.value, b.value, t);
      }
    }

    return _keyframes.last.value;
  }

  T evaluateNormalized(double normalizedTime, T Function(T a, T b, double t) lerp) {
    final d = duration;
    if (d <= 0) return _keyframes.isEmpty ? throw StateError('Empty') : _keyframes.first.value;
    return evaluate(normalizedTime * d, lerp);
  }

  List<T> sample(int count, T Function(T a, T b, double t) lerp) {
    if (count <= 0) return [];
    return List.generate(count, (i) {
      final t = i / (count - 1);
      return evaluateNormalized(t, lerp);
    });
  }

  void clear() => _keyframes.clear();

  @override
  String toString() => 'GchTimeline(keyframes=${_keyframes.length}, duration=$duration)';
}

class GchDoubleTimeline extends GchTimeline<double> {
  double evaluateDouble(double time) {
    return evaluate(time, (a, b, t) => a + (b - a) * t);
  }

  List<double> sampleDoubles(int count) {
    return sample(count, (a, b, t) => a + (b - a) * t);
  }

  static GchDoubleTimeline fromValues(List<double> values) {
    final tl = GchDoubleTimeline();
    for (int i = 0; i < values.length; i++) {
      tl.addKeyframe(GchKeyframe(time: i.toDouble(), value: values[i]));
    }
    return tl;
  }
}

class GchPresetTimelines {
  static GchDoubleTimeline fadeIn({double duration = 1.0}) {
    final tl = GchDoubleTimeline();
    tl.addKeyframe(GchKeyframe(time: 0, value: 0.0, easing: GchEasing.easeOutCubic));
    tl.addKeyframe(GchKeyframe(time: duration, value: 1.0));
    return tl;
  }

  static GchDoubleTimeline fadeOut({double duration = 1.0}) {
    final tl = GchDoubleTimeline();
    tl.addKeyframe(GchKeyframe(time: 0, value: 1.0, easing: GchEasing.easeInCubic));
    tl.addKeyframe(GchKeyframe(time: duration, value: 0.0));
    return tl;
  }

  static GchDoubleTimeline pulse({double duration = 1.0}) {
    final tl = GchDoubleTimeline();
    tl.addKeyframe(GchKeyframe(time: 0, value: 1.0, easing: GchEasing.easeInOutSine));
    tl.addKeyframe(GchKeyframe(time: duration * 0.5, value: 1.2, easing: GchEasing.easeInOutSine));
    tl.addKeyframe(GchKeyframe(time: duration, value: 1.0));
    return tl;
  }

  static GchDoubleTimeline shake({double duration = 0.5, double amplitude = 10}) {
    final tl = GchDoubleTimeline();
    tl.addKeyframe(GchKeyframe(time: 0, value: 0));
    tl.addKeyframe(GchKeyframe(time: duration * 0.1, value: amplitude));
    tl.addKeyframe(GchKeyframe(time: duration * 0.2, value: -amplitude));
    tl.addKeyframe(GchKeyframe(time: duration * 0.4, value: amplitude * 0.7));
    tl.addKeyframe(GchKeyframe(time: duration * 0.6, value: -amplitude * 0.5));
    tl.addKeyframe(GchKeyframe(time: duration * 0.8, value: amplitude * 0.3));
    tl.addKeyframe(GchKeyframe(time: duration, value: 0));
    return tl;
  }

  static GchDoubleTimeline spring({double duration = 1.0, double overshoot = 0.2}) {
    final tl = GchDoubleTimeline();
    tl.addKeyframe(GchKeyframe(time: 0, value: 0.0, easing: GchEasing.easeOutElastic));
    tl.addKeyframe(GchKeyframe(time: duration * 0.6, value: 1.0 + overshoot));
    tl.addKeyframe(GchKeyframe(time: duration * 0.8, value: 1.0 - overshoot * 0.4));
    tl.addKeyframe(GchKeyframe(time: duration, value: 1.0));
    return tl;
  }

  static GchDoubleTimeline bounce({double duration = 0.8}) {
    final tl = GchDoubleTimeline();
    tl.addKeyframe(GchKeyframe(time: 0, value: 0.0, easing: GchEasing.easeOutBounce));
    tl.addKeyframe(GchKeyframe(time: duration, value: 1.0));
    return tl;
  }

  static GchDoubleTimeline elastic({double duration = 1.0}) {
    final tl = GchDoubleTimeline();
    tl.addKeyframe(GchKeyframe(time: 0, value: 0.0, easing: GchEasing.easeOutElastic));
    tl.addKeyframe(GchKeyframe(time: duration, value: 1.0));
    return tl;
  }
}

class GchAnimationBuilder {
  final GchDoubleTimeline _timeline = GchDoubleTimeline();
  String _name = '';

  GchAnimationBuilder named(String name) {
    _name = name;
    return this;
  }

  GchAnimationBuilder addPoint(double time, double value, {double Function(double)? easing}) {
    _timeline.addKeyframe(GchKeyframe(time: time, value: value, easing: easing));
    return this;
  }

  GchAnimationBuilder addLinearSegment(double fromTime, double toTime, double fromValue, double toValue) {
    _timeline.addKeyframe(GchKeyframe(time: fromTime, value: fromValue, easing: GchEasing.linear));
    _timeline.addKeyframe(GchKeyframe(time: toTime, value: toValue));
    return this;
  }

  GchAnimationBuilder addEasedSegment(
    double fromTime,
    double toTime,
    double fromValue,
    double toValue,
    double Function(double) easing,
  ) {
    _timeline.addKeyframe(GchKeyframe(time: fromTime, value: fromValue, easing: easing));
    _timeline.addKeyframe(GchKeyframe(time: toTime, value: toValue));
    return this;
  }

  GchDoubleTimeline build() => _timeline;

  double evaluate(double time) => _timeline.evaluateDouble(time);

  @override
  String toString() => 'GchAnimationBuilder(name=$_name, keyframes=${_timeline.keyframeCount})';
}

class GchAnimationSequencer {
  final List<({GchDoubleTimeline timeline, double startTime, double endTime, String label})> _segments = [];

  void addSegment(GchDoubleTimeline timeline, {required double startTime, String label = ''}) {
    final endTime = startTime + timeline.duration;
    _segments.add((timeline: timeline, startTime: startTime, endTime: endTime, label: label));
  }

  double get totalDuration {
    if (_segments.isEmpty) return 0;
    return _segments.map((s) => s.endTime).reduce(max);
  }

  double evaluate(double time) {
    for (final seg in _segments) {
      if (time >= seg.startTime && time <= seg.endTime) {
        final local = time - seg.startTime;
        return seg.timeline.evaluateDouble(local);
      }
    }
    if (_segments.isEmpty) return 0;
    if (time < _segments.first.startTime) return _segments.first.timeline.evaluateDouble(0);
    return _segments.last.timeline.evaluateDouble(_segments.last.timeline.duration);
  }

  List<double> sample(int count) {
    final d = totalDuration;
    if (d <= 0 || count <= 0) return [];
    return List.generate(count, (i) {
      final t = i / (count - 1) * d;
      return evaluate(t);
    });
  }

  int get segmentCount => _segments.length;

  void clear() => _segments.clear();
}

class GchFrameRateCalculator {
  final int _windowSize;
  final List<DateTime> _frameTimes = [];

  GchFrameRateCalculator({int windowSize = 60}) : _windowSize = windowSize;

  void recordFrame() {
    _frameTimes.add(DateTime.now());
    while (_frameTimes.length > _windowSize) {
      _frameTimes.removeAt(0);
    }
  }

  double get fps {
    if (_frameTimes.length < 2) return 0;
    final duration = _frameTimes.last.difference(_frameTimes.first);
    if (duration.inMicroseconds == 0) return 0;
    return (_frameTimes.length - 1) / duration.inSeconds;
  }

  double get averageFrameTime {
    if (_frameTimes.length < 2) return 0;
    final duration = _frameTimes.last.difference(_frameTimes.first);
    return duration.inMilliseconds / (_frameTimes.length - 1);
  }

  void clear() => _frameTimes.clear();
}

class GchPhysics {
  const GchPhysics._();

  static double gravity = 9.81;

  static double projectileX(double v0, double angle, double t) {
    return v0 * cos(angle) * t;
  }

  static double projectileY(double v0, double angle, double t) {
    return v0 * sin(angle) * t - 0.5 * gravity * t * t;
  }

  static double springForce(double displacement, double stiffness) {
    return -stiffness * displacement;
  }

  static double dampingForce(double velocity, double damping) {
    return -damping * velocity;
  }

  static List<double> simulateSpring({
    required double initialDisplacement,
    required double stiffness,
    required double damping,
    required double mass,
    int steps = 100,
    double dt = 0.016,
  }) {
    double x = initialDisplacement;
    double v = 0;
    final result = [x];
    for (int i = 0; i < steps; i++) {
      final force = springForce(x, stiffness) + dampingForce(v, damping);
      final a = force / mass;
      v += a * dt;
      x += v * dt;
      result.add(x);
    }
    return result;
  }

  static double lerp(double a, double b, double t) => a + (b - a) * t;

  static double exponentialDecay(double value, double target, double speed, double dt) {
    return target + (value - target) * exp(-speed * dt);
  }

  static double criticalDamping(double current, double target, double velocity, double dt, double omega) {
    final c = current - target;
    final result = (c + (velocity + omega * c) * dt) * exp(-omega * dt);
    return target + result;
  }
}
