import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_store/gch_storage/gch_adapter.dart';

class GchStorageFactory {
  GchStorageFactory._();
  static final GchStorageFactory _instance = GchStorageFactory._();
  static GchStorageFactory get instance => _instance;

  /// Stub: no adapters available after gch_profile module removal
  Future<dynamic> gchBuildAdapter(
    GchStorageConfig config, {
    GchDatabase? database,
    dynamic mapper,
  }) async {
    throw UnsupportedError('Profile storage adapters removed with gch_profile module');
  }

  dynamic gchGetAdapter(StorageType type, String name) => null;

  Future<void> gchCloseAdapter(StorageType type, String name) async {}

  Future<void> gchCloseAll() async {}

  Future<void> gchMigrate({
    required dynamic fromAdapter,
    required dynamic toAdapter,
    void Function(int current, int total)? onProgress,
  }) async {}

  static bool gchIsTypeSupported(StorageType type) => type == StorageType.sqlite;
  static List<StorageType> gchSupportedTypes() => StorageType.values.where(gchIsTypeSupported).toList();
  static GchStorageConfig gchDefaultConfig(StorageType type, {String? customPath}) =>
    GchSqliteConfig(name: 'profiles.db', path: customPath, enableForeignKeys: true, enableWAL: true);
}
