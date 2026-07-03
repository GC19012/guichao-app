import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_schema/gch_fault.dart';

part 'gch_settings_failure.freezed.dart';

@freezed
sealed class SettingsFailure with _$SettingsFailure, GchFault {
  const SettingsFailure._();

  @With<GchUnexpectedFault>()
  const factory SettingsFailure.unexpected([
    Object? error,
    StackTrace? stackTrace,
  ]) = SettingsUnexpectedFailure;

  @override
  GchPresentableError describe() {
    return switch (this) {
      SettingsUnexpectedFailure() => (
          type: GchText.faultUnexpected,
          message: null,
        ),
    };
  }
}
