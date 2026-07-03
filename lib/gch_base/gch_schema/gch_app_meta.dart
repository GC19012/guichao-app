import 'package:freezed_annotation/freezed_annotation.dart';
import 'gch_env.dart';

part 'gch_app_meta.freezed.dart';

@freezed
abstract class GchAppMeta with _$GchAppMeta {
  const GchAppMeta._();

  const factory GchAppMeta({
    required String name,
    required String version,
    required String buildNumber,
    required GchRelease release,
    required String operatingSystem,
    required String operatingSystemVersion,
    required GchEnv environment,
  }) = _GchAppMeta;

  String get agentTag =>
      "GUICHAO/$version ($operatingSystem) ";

  String get displayVersion => environment == GchEnv.prod
      ? version
      : "$version ${environment.name}";

  /// formats app info for sharing
  String format() => '''
$name v$version ($buildNumber) [${environment.name}]
${release.name} release
$operatingSystem [$operatingSystemVersion]''';
}
