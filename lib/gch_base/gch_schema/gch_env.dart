import 'package:dartx/dartx.dart';

enum GchEnv {
  prod,
  dev;
}

enum GchRelease {
  general("general");

  const GchRelease(this.key);

  final String key;

  bool get allowCustomUpdateChecker => this == general;

  static GchRelease read() =>
      GchRelease.values.firstOrNullWhere(
        (e) => e.key == const String.fromEnvironment("release"),
      ) ??
      GchRelease.general;
}
