import 'dart:async';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';

/// 通用存储适配器接口
///
/// 为不同的存储后端（SQLite/Realm/Hive）提供统一的数据访问接口
/// 采用泛型设计，支持任意实体类型的CRUD操作
abstract interface class GchStorageAdapter<TEntity, TKey> {
  /// 初始化存储
  Future<void> gchInit();

  /// 关闭存储连接
  Future<void> gchShutdown();

  /// 根据主键获取单个实体
  Future<TEntity?> gchFetchOne(TKey id);

  /// 根据条件查询实体列表
  Future<List<TEntity>> gchFetchAll({
    Map<String, dynamic>? where,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  });

  /// 监听实体变化流
  Stream<List<TEntity>> gchObserveAll({
    Map<String, dynamic>? where,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  });

  /// 监听单个实体变化
  Stream<TEntity?> gchObserveOne(TKey id);

  /// 插入新实体
  Future<void> gchPut(TEntity entity);

  /// 批量插入
  Future<void> gchPutBatch(List<TEntity> entities);

  /// 更新实体
  Future<void> gchPatch(TKey id, Map<String, dynamic> updates);

  /// 删除实体
  Future<void> gchRemove(TKey id);

  /// 批量删除
  Future<void> gchRemoveWhere(Map<String, dynamic> where);

  /// 清空所有数据
  Future<void> gchPurge();

  /// 获取实体数量
  Future<int> gchCount({Map<String, dynamic>? where});

  /// 事务支持
  Future<T> gchTransact<T>(Future<T> Function() action);
}

/// 存储适配器异常
sealed class GchStorageException implements Exception {
  const GchStorageException(this.message);
  final String message;

  const factory GchStorageException.notFound(String key) = GchNotFoundException;
  const factory GchStorageException.duplicate(String key) = GchDuplicateException;
  const factory GchStorageException.constraint(String message) = GchConstraintException;
  const factory GchStorageException.connection(String message) = GchConnectionException;
  const factory GchStorageException.transaction(String message) = GchTransactionException;
}

class GchNotFoundException extends GchStorageException {
  const GchNotFoundException(super.message);
}

class GchDuplicateException extends GchStorageException {
  const GchDuplicateException(super.message);
}

class GchConstraintException extends GchStorageException {
  const GchConstraintException(super.message);
}

class GchConnectionException extends GchStorageException {
  const GchConnectionException(super.message);
}

class GchTransactionException extends GchStorageException {
  const GchTransactionException(super.message);
}

/// 存储配置
abstract class GchStorageConfig {
  const GchStorageConfig();

  StorageType get type;
  String get name;
  Map<String, dynamic> get options;
}

class GchSqliteConfig extends GchStorageConfig {
  const GchSqliteConfig({
    required this.name,
    this.path,
    this.enableForeignKeys = true,
    this.enableWAL = true,
  });

  @override
  final String name;
  final String? path;
  final bool enableForeignKeys;
  final bool enableWAL;

  @override
  StorageType get type => StorageType.sqlite;

  @override
  Map<String, dynamic> get options => {
    'path': path,
    'enableForeignKeys': enableForeignKeys,
    'enableWAL': enableWAL,
  };
}

