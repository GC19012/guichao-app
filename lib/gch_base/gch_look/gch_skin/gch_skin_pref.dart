import 'package:guichao/gch_base/gch_prefs/gch_store.dart';
import 'package:guichao/gch_base/gch_prefs/gch_store_provider.dart';
import 'package:guichao/gch_base/gch_look/gch_palette/gch_color_skin.dart';
import 'package:guichao/gch_base/gch_look/gch_palette/gch_tone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_skin_pref.g.dart';

/// Available skin presets.
enum GchSkinType {
  deepBlue,
  classicLight;

  GchColorSkin get skin => switch (this) {
        deepBlue => GchColorSkin.deepBlue,
        classicLight => GchColorSkin.classicLight,
      };
}

/// Persisted skin + tone preferences.
class GchSkinState {
  const GchSkinState({
    this.skinType = GchSkinType.deepBlue,
    this.toneDelta = 0.0,
  });

  final GchSkinType skinType;
  final double toneDelta;

  GchColorSkin get skin => skinType.skin;
  GchTone get tone => GchTone(toneDelta);
}

@Riverpod(keepAlive: true)
class GchSkinPref extends _$GchSkinPref {
  bool _initialized = false;

  @override
  GchSkinState build() {
    final storeAsync = ref.watch(gchStoreProvider);

    return storeAsync.when(
      data: (store) {
        if (!_initialized) {
          _initialized = true;
          _loadPersisted(store);
        }
        return const GchSkinState();
      },
      loading: () => const GchSkinState(),
      error: (_, __) => const GchSkinState(),
    );
  }

  Future<void> _loadPersisted(GchStore store) async {
    try {
      final skinName = await store.getString('skin_type');
      final toneDelta = await store.getDouble('tone_delta');

      GchSkinType skinType = GchSkinType.deepBlue;
      if (skinName != null) {
        skinType = GchSkinType.values.byName(skinName);
      }

      state = GchSkinState(
        skinType: skinType,
        toneDelta: toneDelta ?? 0.0,
      );
    } catch (_) {
      // Keep defaults on error
    }
  }

  Future<void> switchSkin(GchSkinType value) async {
    state = GchSkinState(skinType: value, toneDelta: state.toneDelta);
    final store = await ref.read(gchStoreProvider.future);
    await store.setString('skin_type', value.name);
  }

  Future<void> adjustTone(double value) async {
    state = GchSkinState(skinType: state.skinType, toneDelta: value.clamp(-1.0, 1.0));
    final store = await ref.read(gchStoreProvider.future);
    await store.setDouble('tone_delta', state.toneDelta);
  }
}
