// lib/core/gch_prefs/gch_store_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../gch_kit/gch_loggers.dart';
import 'gch_store.dart';
import 'gch_store_factory.dart';

part 'gch_store_provider.g.dart';

/// 统一的存储Provider - 替代原有的sharedPreferencesProvider
@Riverpod(keepAlive: true)
Future<GchStore> gchStore(GchStoreRef ref) async {
  final logger = InfraLoggerMixin("gchStore");

  logger.loggy.debug("初始化GchStore...");
  try {
    final store = await GchStoreFactory.getInstance();
    logger.loggy.debug("GchStore初始化成功: ${store.type}");
    return store;
  } catch (e) {
    logger.loggy.error("GchStore初始化失败", e);
    rethrow;
  }
}

/// 为了向后兼容，保留原名称
@Riverpod(keepAlive: true)
Future<GchStore> sharedPreferences(SharedPreferencesRef ref) async {
  return ref.watch(gchStoreProvider.future);
}

class InfraLoggerMixin with GchInfraLogger {
  final String name;
  InfraLoggerMixin(this.name);
  
  @override
  String toString() => name;
}