import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guichao/gch_base/gch_kit/gch_catch.dart';
import 'package:guichao/gch_mod/gch_settings/gch_model/gch_settings_failure.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';

abstract interface class SettingsRepository {
  TaskEither<SettingsFailure, bool> isIgnoringBatteryOptimizations();
  TaskEither<SettingsFailure, bool> requestIgnoreBatteryOptimizations();
}

class SettingsRepositoryImpl
    with GchErrHandler, GchInfraLogger
    implements SettingsRepository {
  final _methodChannel = const MethodChannel("com.example.app/gch.pf");

  @override
  TaskEither<SettingsFailure, bool> isIgnoringBatteryOptimizations() {
    return exceptionHandler(
      () async {
        loggy.debug("checking battery optimization status");
        final result = await _methodChannel
            .invokeMethod<bool>("is_ignoring_battery_optimizations");
        loggy.debug("is ignoring battery optimizations? [$result]");
        return right(result!);
      },
      SettingsUnexpectedFailure.new,
    );
  }

  @override
  TaskEither<SettingsFailure, bool> requestIgnoreBatteryOptimizations() {
    return exceptionHandler(
      () async {
        loggy.debug("requesting ignore battery optimization");
        final result = await _methodChannel
            .invokeMethod<bool>("request_ignore_battery_optimizations");
        loggy.debug("ignore battery optimization result: [$result]");
        return right(result!);
      },
      SettingsUnexpectedFailure.new,
    );
  }
}
