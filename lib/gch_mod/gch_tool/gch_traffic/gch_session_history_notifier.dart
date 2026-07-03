import 'package:guichao/gch_mod/gch_tool/gch_traffic/gch_session_record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'gch_session_history_notifier.g.dart';

const _kPrefsKey = 'gch_session_history_v1';
const _kMaxRecords = 100;

@Riverpod(keepAlive: true)
class GchSessionHistoryNotifier extends _$GchSessionHistoryNotifier {
  @override
  List<GchSessionRecord> build() {
    // 异步从磁盘加载历史，build() 先返回空列表
    Future.microtask(_loadFromDisk);
    // VPN stats/connection providers removed — no longer listening to traffic events
    return [];
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        final records = GchSessionRecord.listFromJsonString(raw);
        if (records.isNotEmpty) {
          state = records;
        }
      }
    } catch (_) {
      // 读取失败静默处理，不影响正常流程
    }
  }

  void _saveToDisk(List<GchSessionRecord> records) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_kPrefsKey, GchSessionRecord.listToJsonString(records));
    }).catchError((_) {});
  }

  /// 清空所有历史记录
  void clearAll() {
    state = [];
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_kPrefsKey);
    }).catchError((_) {});
  }
}
