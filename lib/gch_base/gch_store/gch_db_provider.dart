import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_store/gch_storage/gch_manager.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_db_provider.g.dart';

/// SQLite 数据库 Provider - 只在 SQLite 模式下创建
///
/// ⚠️ 重要：在 Realm 模式下访问此 Provider 会抛出 StateError
///
/// 推荐做法：业务层应通过各模块的 StorageAdapter 访问存储，
/// 而不是直接使用此 Provider。参考 Proxy 模块的 GchNodeStoreAdapter 实现。
@Riverpod(keepAlive: true)
GchDatabase gchDatabase(GchDatabaseRef ref) {
  // ✅ 条件性创建：只在 SQLite 模式下实例化数据库
  final storageType = GchStorageManager.instance.gchCurrentType;

  if (storageType != StorageType.sqlite) {
    throw StateError(
      '❌ Cannot create SQLite database in ${storageType.displayName} mode.\n'
      '   Use StorageAdapter pattern for cross-storage compatibility.'
    );
  }

  return GchDatabase.connect();
}
