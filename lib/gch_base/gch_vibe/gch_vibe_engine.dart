import 'package:flutter/services.dart';
import 'package:guichao/gch_base/gch_prefs/gch_store_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_vibe_engine.g.dart';

@Riverpod(keepAlive: true)
class GchVibeEngine extends _$GchVibeEngine {
  static const String vibePrefKey = "haptic_feedback";
  static const Duration _vibeTimeout = Duration(milliseconds: 100);

  bool _ready = false;

  @override
  bool build() {
    final storeAsync = ref.watch(gchStoreProvider);

    return storeAsync.when(
      data: (store) {
        _loadVibeSetting(store);
        return true;
      },
      loading: () => true,
      error: (_, __) => true,
    );
  }

  Future<void> _loadVibeSetting(store) async {
    if (_ready) return;
    _ready = true;

    try {
      final saved = await store.getBool(vibePrefKey);
      if (saved != null && saved != state) {
        state = saved as bool;
      }
    } catch (e) {
      // silent
    }
  }

  Future<void> toggleVibe(bool value) async {
    state = value;
    _persistAsync(value);
  }

  Future<void> _persistAsync(bool value) async {
    try {
      final store = await ref.read(gchStoreProvider.future);
      await store.setBool(vibePrefKey, value);
    } catch (e) {
      // silent
    }
  }

  Future<void> _fireVibe(Future<void> Function() fn) async {
    if (!state) return;
    try {
      await fn().timeout(_vibeTimeout);
    } catch (e) {
      // silent
    }
  }

  Future<void> tapSoft() => _fireVibe(HapticFeedback.lightImpact);

  Future<void> tapMid() => _fireVibe(HapticFeedback.mediumImpact);

  Future<void> tapHard() => _fireVibe(HapticFeedback.heavyImpact);

  Future<void> tapSelect() => _fireVibe(HapticFeedback.selectionClick);

  Future<void> buzz() => _fireVibe(HapticFeedback.vibrate);

  static Future<bool> canVibe() async {
    try {
      await HapticFeedback.lightImpact();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> runPattern({
    List<GchVibeMode> pattern = const [GchVibeMode.soft],
    Duration gap = const Duration(milliseconds: 50),
  }) async {
    if (!state) return;
    for (int i = 0; i < pattern.length; i++) {
      await _fireVibeByMode(pattern[i]);
      if (i < pattern.length - 1) {
        await Future.delayed(gap);
      }
    }
  }

  Future<void> _fireVibeByMode(GchVibeMode mode) async {
    switch (mode) {
      case GchVibeMode.soft:
        await tapSoft();
      case GchVibeMode.mid:
        await tapMid();
      case GchVibeMode.hard:
        await tapHard();
      case GchVibeMode.select:
        await tapSelect();
      case GchVibeMode.pulse:
        await buzz();
    }
  }
}

enum GchVibeMode {
  soft,
  mid,
  hard,
  select,
  pulse,
}
