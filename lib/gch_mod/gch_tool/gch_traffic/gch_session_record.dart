import 'dart:convert';

class GchSessionRecord {
  final DateTime startTime;
  final DateTime endTime;
  final int downTotal;
  final int upTotal;

  const GchSessionRecord({
    required this.startTime,
    required this.endTime,
    required this.downTotal,
    required this.upTotal,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
        's': startTime.millisecondsSinceEpoch,
        'e': endTime.millisecondsSinceEpoch,
        'd': downTotal,
        'u': upTotal,
      };

  factory GchSessionRecord.fromJson(Map<String, dynamic> j) => GchSessionRecord(
        startTime: DateTime.fromMillisecondsSinceEpoch(j['s'] as int),
        endTime: DateTime.fromMillisecondsSinceEpoch(j['e'] as int),
        downTotal: j['d'] as int,
        upTotal: j['u'] as int,
      );

  static List<GchSessionRecord> listFromJsonString(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => GchSessionRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJsonString(List<GchSessionRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());
}
