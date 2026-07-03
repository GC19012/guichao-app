import 'package:dart_mappable/dart_mappable.dart';
import 'package:dartx/dartx.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guichao/gch_gen/gch_text.dart';

part 'gch_span.mapper.dart';

@MappableClass()
class GchSpan with GchSpanMappable {
  const GchSpan({this.min, this.max});

  final int? min;
  final int? max;

  String format() => [min, max].whereNotNull().join("-");
  String present() =>
      format().isEmpty ? GchText.generalNotSet : format();

  factory GchSpan.parse(
    String input, {
    bool allowEmpty = false,
  }) =>
      switch (input.split("-")) {
        [final String val] when val.isEmpty && allowEmpty =>
          const GchSpan(),
        [final String min] => GchSpan(min: int.parse(min)),
        [final String min, final String max] => GchSpan(
            min: int.parse(min),
            max: int.parse(max),
          ),
        _ => throw Exception("Invalid range: $input"),
      };

  static GchSpan? tryParse(
    String input, {
    bool allowEmpty = false,
  }) {
    try {
      return GchSpan.parse(input, allowEmpty: allowEmpty);
    } catch (_) {
      return null;
    }
  }
}

class GchSpanJsonConverter
    implements JsonConverter<GchSpan, String> {
  const GchSpanJsonConverter();

  @override
  GchSpan fromJson(String json) =>
      GchSpan.parse(json, allowEmpty: true);

  @override
  String toJson(GchSpan object) => object.format();
}
