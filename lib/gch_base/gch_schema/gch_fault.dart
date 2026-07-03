import 'package:dio/dio.dart';
import 'package:guichao/gch_gen/gch_text.dart';

typedef GchPresentableError = ({String type, String? message});

mixin GchFault {
  GchPresentableError describe();
}

/// failures that are not expected to happen but depending on [error] type might not be relevant (eg network errors)
mixin GchUnexpectedFault {
  Object? get error;
  StackTrace? get stackTrace;
}

/// failures that are expected to happen and should be handled by the app
/// and should be logged, eg missing permissions
mixin GchMeasuredFault {}

/// failures ignored by analytics service etc.
mixin GchExpectedFault {}

class GchFaultPresenter {
  GchFaultPresenter._();

  static GchPresentableError faultToPair(Object error) => switch (error) {
        GchUnexpectedFault(error: final nestedErr?) => faultToPair(nestedErr),
        GchFault() => error.describe(),
        DioException() => error.describe(),
        String s when s.startsWith('SERVICE_TIMEOUT:') => (
            type: GchText.faultVpnConnUnexpected,
            message: GchText.faultEngineServiceTimeout(s.substring('SERVICE_TIMEOUT:'.length)),
          ),
        _ => (type: GchText.faultUnexpected, message: error.toString()),
      };

  static GchPresentableError describeFault(
    Object error, {
    String? action,
  }) {
    final pair = faultToPair(error);
    if (action == null) return pair;
    return (
      type: action,
      message: pair.type + (pair.message == null ? "" : "\n${pair.message!}"),
    );
  }

  static String briefFault(
    Object error, {
    String? action,
  }) {
    final pair = faultToPair(error);
    if (action == null) return pair.type;
    return "$action: ${pair.type}";
  }
}

extension GchDioFaultDescriber on DioException {
  GchPresentableError describe() => switch (type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          (type: GchText.faultHttpReqTimeout, message: null),
        DioExceptionType.badCertificate => (
            type: GchText.faultHttpReqBadCertificate,
            message: message,
          ),
        DioExceptionType.badResponse => (
            type: GchText.faultHttpReqBadResponse,
            message: message,
          ),
        DioExceptionType.connectionError => (
            type: GchText.faultHttpReqConnectionError,
            message: message,
          ),
        _ => (type: GchText.faultHttpReqUnexpected, message: message),
      };
}
