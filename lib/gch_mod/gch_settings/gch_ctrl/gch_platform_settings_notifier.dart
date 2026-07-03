import 'package:guichao/gch_mod/gch_settings/gch_repo/gch_settings_data_providers.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_platform_settings_notifier.g.dart';

@riverpod
class IgnoreBatteryOptimizations extends _$IgnoreBatteryOptimizations {
  @override
  Future<bool> build() async {
    return ref
        .watch(settingsRepositoryProvider)
        .isIgnoringBatteryOptimizations()
        .getOrElse((l) => false)
        .run();
  }

  Future<void> request() async {
    await ref
        .read(settingsRepositoryProvider)
        .requestIgnoreBatteryOptimizations()
        .run();
    await Future.delayed(const Duration(seconds: 1));
    ref.invalidateSelf();
  }
}

@riverpod
class ResetTunnel extends _$ResetTunnel with GchAppLogger {
  @override
  Future<void> build() async {}

  Future<void> run() async {
    // VPN kernel removed — no-op
    loggy.warning("ResetTunnel: VPN kernel has been removed");
  }
}
