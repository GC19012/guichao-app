import 'package:freezed_annotation/freezed_annotation.dart';

class GchIntervalConv implements JsonConverter<Duration, int> {
  const GchIntervalConv();

  @override
  Duration fromJson(int json) => Duration(seconds: json);

  @override
  int toJson(Duration object) => object.inSeconds;
}
