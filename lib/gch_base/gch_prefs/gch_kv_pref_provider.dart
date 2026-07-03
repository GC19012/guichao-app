// core/gch_prefs/gch_kv_pref_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../gch_store/gch_kv/gch_kv_prefs.dart';
import '../gch_kit/gch_loggers.dart';

part 'gch_kv_pref_provider.g.dart';

/// GchKvPrefs provider - 替代SharedPreferences
@Riverpod(keepAlive: true)
Future<GchKvPrefs> gchKvPref(GchKvPrefRef ref) async {
  final logger = InfraLoggerMixin("kv_preferences");

  logger.loggy.debug("初始化Kv preferences");

  try {
    final preferences = await GchKvPrefs.getInstance();
    logger.loggy.debug("Kv preferences初始化成功");
    return preferences;
  } catch (e) {
    logger.loggy.error("Kv preferences初始化错误", e);



    rethrow;
  }
}

/// 兼容性包装器 - 保持现有代码的兼容性
@Riverpod(keepAlive: true)
Future<GchKvPrefs> sharedPreferences(SharedPreferencesRef ref) async {
  return ref.watch(gchKvPrefProvider.future);
}

/// 日志混入类
class InfraLoggerMixin with GchInfraLogger {
  final String name;
  InfraLoggerMixin(this.name);

  @override
  String toString() => name;
}
