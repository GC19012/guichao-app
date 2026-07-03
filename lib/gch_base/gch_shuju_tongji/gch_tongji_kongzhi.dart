import 'package:guichao/gch_base/gch_prefs/gch_store_provider.dart';
import 'package:guichao/gch_base/gch_prefs/gch_store.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'gch_tongji_kongzhi.g.dart';
const String tongjiKaiguanKey = "enable_analytics";

@Riverpod(keepAlive: true)
class TongjiKongzhi extends _$TongjiKongzhi with GchAppLogger {
  @override
  Future<bool> build() async {
    return await _store.getBool(tongjiKaiguanKey) ?? true;
  }

  GchStore get _store => ref.read(gchStoreProvider).requireValue;

  Future<void> qiyongTongji() async {
    if (state case AsyncData(value: final enabled)) {
      loggy.debug("enabling analytics (local logging only)");
      state = const AsyncLoading();
      if (!enabled) {
        await _store.setBool(tongjiKaiguanKey, true);
      }
      loggy.info("Analytics enabled - using local logging system");
      state = const AsyncData(true);
    }
  }

  Future<void> tingzhiTongji() async {
    if (state case AsyncData()) {
      loggy.debug("disabling analytics");
      state = const AsyncLoading();
      await _store.setBool(tongjiKaiguanKey, false);
      loggy.info("Analytics disabled");
      state = const AsyncData(false);
    }
  }
}
