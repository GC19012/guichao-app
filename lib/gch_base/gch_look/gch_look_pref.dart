import 'package:guichao/gch_base/gch_prefs/gch_store.dart';
import 'package:guichao/gch_base/gch_prefs/gch_store_provider.dart';
import 'package:guichao/gch_base/gch_look/gch_look_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_look_pref.g.dart';

@Riverpod(keepAlive: true)
class GchLookPref extends _$GchLookPref {
  bool _initialized = false;

  @override
  GchLookMode build() {
    final storeAsync = ref.watch(gchStoreProvider);

    return storeAsync.when(
      data: (store) {
        if (!_initialized) {
          _initialized = true;
          _loadPersistedTheme(store);
        }
        return GchLookMode.system;
      },
      loading: () => GchLookMode.system,
      error: (_, __) => GchLookMode.system,
    );
  }

  Future<void> _loadPersistedTheme(GchStore store) async {
    try {
      final persisted = await store.getString("theme_mode");
      if (persisted != null) {
        state = GchLookMode.values.byName(persisted);
      }
    } catch (e) {
      // 处理错误，保持默认值 GchLookMode.system
    }
  }

  Future<void> switchMode(GchLookMode value) async {
    state = value;
    final store = await ref.read(gchStoreProvider.future);
    await store.setString("theme_mode", value.name);
  }
}
