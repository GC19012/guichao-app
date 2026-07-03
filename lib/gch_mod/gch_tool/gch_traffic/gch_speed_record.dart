import 'dart:convert';

class GchSpeedRecord {
  final DateTime time;
  final int peakBps;
  final int avgBps;
  final int pingMs;
  final int totalBytes;

  const GchSpeedRecord({
    required this.time,
    required this.peakBps,
    required this.avgBps,
    required this.pingMs,
    required this.totalBytes,
  });

  Map<String, dynamic> toJson() => {
        't': time.millisecondsSinceEpoch,
        'p': peakBps,
        'a': avgBps,
        'g': pingMs,
        'b': totalBytes,
      };

  factory GchSpeedRecord.fromJson(Map<String, dynamic> j) => GchSpeedRecord(
        time: DateTime.fromMillisecondsSinceEpoch(j['t'] as int),
        peakBps: j['p'] as int? ?? 0,
        avgBps: j['a'] as int? ?? 0,
        pingMs: j['g'] as int? ?? 0,
        totalBytes: j['b'] as int? ?? 0,
      );

  static List<GchSpeedRecord> listFromJsonString(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => GchSpeedRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJsonString(List<GchSpeedRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());
}
