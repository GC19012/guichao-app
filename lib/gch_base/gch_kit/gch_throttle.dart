import 'package:flutter/foundation.dart';

class GchThrottler {
  GchThrottler(this.throttleFor);

  final Duration throttleFor;
  DateTime? _lastCall;

  void call(VoidCallback callback) {
    if (_lastCall == null ||
        DateTime.now().difference(_lastCall!) > throttleFor) {
      callback();
      _lastCall = DateTime.now();
    }
  }
}
