import 'dart:io';

import 'package:guichao/gch_base/gch_biz/gch_profile/gch_svc/gch_fetch_utils.dart' as utils;
import 'package:guichao/gch_aux/gch_log_mix.dart';

/// 持久化结果
class SaveResult {
  final bool changed;
  final String hash;
  final int bytes;

  const SaveResult({
    required this.changed,
    required this.hash,
    required this.bytes,
  });
}

/// 配置持久化器接口 - 存储层
///
/// 职责：
/// - 原子写入
/// - 备份恢复
/// - Hash 比较
/// - 缓存管理
abstract interface class ConfigPersister {
  /// 保存配置（带变更检测）
  Future<SaveResult> save(
    String path,
    String content, {
    bool force = false,
  });

  /// 保存 Extra 内容到文件
  Future<SaveResult> saveExtra(
    String dir,
    String fileName,
    String content,
  );

  /// 创建备份
  Future<bool> backup(String path);

  /// 恢复备份
  Future<bool> restore(String path);

  /// 清理临时文件
  Future<void> cleanup(String path);
}

/// 原子写入配置持久化器
class AtomicConfigPersister with GchInfraLogger implements ConfigPersister {
  @override
  Future<SaveResult> save(
    String path,
    String content, {
    bool force = false,
  }) async {
    final file = File(path);
    final cache = File('$path.cache');
    final tempCache = File('$path.cache.tmp');

    final hash = utils.hash(content);

    // 写入临时缓存用于比较
    await tempCache.writeAsString(content);

    final size = tempCache.lengthSync();
    if (size == 0) {
      throw Exception('Write temp cache failed (0 bytes)');
    }

    // Hash 比较
    final same = utils.sameContent(cache, tempCache);
    final shouldWrite = force || same != true;

    if (!shouldWrite) {
      loggy.info("Unchanged (${hash.substring(0, 8)}...)");
      await tempCache.delete();
      return SaveResult(changed: false, hash: hash, bytes: 0);
    }

    loggy.info("${same == null ? 'New' : 'Changed'} (${hash.substring(0, 8)}...)");

    // 原子写入目标文件
    await utils.atomicWrite(file, content);

    final bytes = file.lengthSync();
    if (bytes == 0) {
      throw Exception('Write target failed (0 bytes)');
    }

    // 验证临时缓存再重命名
    final tempSize = tempCache.lengthSync();
    if (tempSize == 0) {
      throw Exception('Temp cache empty before rename');
    }
    // 重命名，跨文件系统时使用 copy + delete
    try {
      await tempCache.rename(cache.path);
    } on FileSystemException {
      await tempCache.copy(cache.path);
      await tempCache.delete();
    }

    loggy.info("Saved ($bytes bytes)");

    return SaveResult(changed: true, hash: hash, bytes: bytes);
  }

  @override
  Future<SaveResult> saveExtra(
    String dir,
    String fileName,
    String content,
  ) async {
    final path = '$dir/$fileName';
    loggy.debug("Saving extra: $fileName");
    return save(path, content);
  }

  @override
  Future<bool> backup(String path) async {
    final file = File(path);
    final backupFile = File('$path.backup');

    if (file.existsSync()) {
      final size = file.lengthSync();
      if (size > 0) {
        await file.copy(backupFile.path);
        loggy.debug("Backup created ($size bytes)");
        return true;
      }
    }
    return false;
  }

  @override
  Future<bool> restore(String path) async {
    final file = File(path);
    final backupFile = File('$path.backup');

    if (backupFile.existsSync()) {
      final backupSize = backupFile.lengthSync();
      if (backupSize > 0) {
        if (!file.existsSync() || file.lengthSync() == 0) {
          await backupFile.copy(file.path);
          loggy.warning("Restored from backup ($backupSize bytes)");
          return true;
        }
      }
      await backupFile.delete();
    }
    return false;
  }

  @override
  Future<void> cleanup(String path) async {
    final files = [
      File('$path.backup'),
      File('$path.tmp'),
      File('$path.cache.tmp'),
    ];

    for (final file in files) {
      try {
        if (file.existsSync()) await file.delete();
      } catch (e) {
        // 删除失败不影响后续清理
        loggy.debug('cleanup failed: ${file.path}', e);
      }
    }
  }
}
