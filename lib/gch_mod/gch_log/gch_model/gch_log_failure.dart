import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_schema/gch_fault.dart';

part 'gch_log_failure.freezed.dart';

@freezed
sealed class GchTraceFault with _$GchTraceFault, GchFault {
  const GchTraceFault._();

  @With<GchUnexpectedFault>()
  const factory GchTraceFault.unexpected([
    Object? error,
    StackTrace? stackTrace,
  ]) = GchTraceUnexpected;

  @override
  GchPresentableError describe() {
    return switch (this) {
      GchTraceUnexpected() => (
          type: GchText.faultUnexpected,
          message: null,
        ),
    };
  }
}
