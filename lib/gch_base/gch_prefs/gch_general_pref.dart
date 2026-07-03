import 'package:guichao/gch_base/gch_app_xinxi/gch_yingyong_xinxi.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_schema/gch_env.dart';
import 'package:guichao/gch_base/gch_prefs/gch_close_action.dart';
// import 'package:guichao/gch_base/gch_schema/gch_zone.dart';
import 'package:guichao/gch_base/gch_prefs/gch_store_provider.dart';
import 'package:guichao/gch_base/gch_kit/gch_pref_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_general_pref.g.dart';

bool _debugIntroPage = false;

abstract class GchPrefs {
  static final introCompleted = GchPrefNotifier.create(
    "intro_completed",
    false,
    overrideValue: _debugIntroPage && GchNucleus.isDevMode ? false : null,
  );

  /// 用户是否已同意隐私政策
  static final privacyAgreed = GchPrefNotifier.create<bool, bool>(
    "privacy_agreed",
    false,
  );

  static final silentStart = GchPrefNotifier.create<bool, bool>(
    "silent_start",
    false,
  );

  static final disableMemoryLimit = GchPrefNotifier.create<bool, bool>(
    "disable_memory_limit",
    false,
  );

  static final markNewProfileActive = GchPrefNotifier.create<bool, bool>(
    "mark_new_profile_active",
    true,
  );

  static final dynamicNotification = GchPrefNotifier.create<bool, bool>(
    "dynamic_notification",
    true,
  );

  static final autoCheckIp = GchPrefNotifier.create<bool, bool>(
    "auto_check_ip",
    true,
  );

  static final startedByUser = GchPrefNotifier.create<bool, bool>(
    "started_by_user",
    false,
  );

  static final storeReviewedByUser = GchPrefNotifier.create<bool, bool>(
    "store_reviewed_by_user",
    false,
  );

  /// VPN 历史上是否成功连接过（首次安装时 Extension cold-start 需更长超时）
  static final hasEverConnected = GchPrefNotifier.create<bool, bool>(
    "has_ever_connected",
    false,
  );

  /// VIP降级后配置需重新下载（持久化标记，跨重启有效）
  static final configDirty = GchPrefNotifier.create<bool, bool>(
    "config_dirty",
    false,
  );

  static final actionAtClose = GchPrefNotifier.create<GchCloseAction, String>(
    "action_at_close",
    GchCloseAction.ask,
    mapFrom: GchCloseAction.values.byName,
    mapTo: (value) => value.name,
  );
}

@Riverpod(keepAlive: true)
class GchDebugMode extends _$GchDebugMode {
  GchPrefEntry<bool, bool>? _pref;

  @override
  bool build() {
    final defaultValue = ref.read(environmentProvider) == GchEnv.dev;
    // 异步读取并更新状态
    _loadValue();
    return defaultValue;
  }

  Future<GchPrefEntry<bool, bool>> _getPref() async {
    if (_pref != null) return _pref!;
    
    final store = await ref.read(gchStoreProvider.future);
    _pref = GchPrefEntry(
      preferences: store,
      key: "debug_mode",
      defaultValue: ref.read(environmentProvider) == GchEnv.dev,
    );
    return _pref!;
  }

  Future<void> _loadValue() async {
    try {
      final pref = await _getPref();
      final value = await pref.read();
      state = value;
    } catch (e) {
      // 使用默认值
    }
  }

  Future<void> update(bool value) async {
    final pref = await _getPref();
    state = value;
    await pref.write(value);
  }
}

