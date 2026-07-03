import 'package:guichao/gch_mod/gch_tool/gch_traffic/gch_speed_record.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSpeedPrefsKey = 'gch_speed_history_v1';
const _kMaxRecords = 50;

final gchSpeedHistoryProvider =
    NotifierProvider<GchSpeedHistoryNotifier, List<GchSpeedRecord>>(
  GchSpeedHistoryNotifier.new,
);

class GchSpeedHistoryNotifier extends Notifier<List<GchSpeedRecord>> {
  @override
  List<GchSpeedRecord> build() {
    Future.microtask(_loadFromDisk);
    return [];
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSpeedPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        final records = GchSpeedRecord.listFromJsonString(raw);
        if (records.isNotEmpty) state = records;
      }
    } catch (_) {}
  }

  void addRecord(GchSpeedRecord record) {
    final updated = [record, ...state];
    state = updated.length > _kMaxRecords
        ? updated.sublist(0, _kMaxRecords)
        : updated;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_kSpeedPrefsKey, GchSpeedRecord.listToJsonString(state));
    }).catchError((_) {});
  }

  void clearAll() {
    state = [];
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_kSpeedPrefsKey);
    }).catchError((_) {});
  }
}
