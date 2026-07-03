import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:guichao/gch_base/gch_pathfinder/gch_pathfinder.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

LazyDatabase gchOpenDbConn() {
  return LazyDatabase(() async {
    final dbDir = await GchPathfinder.locateDbPath();
    await dbDir.create(recursive: true);
    final dbFile = File(p.join(dbDir.path, 'db.sqlite'));

    // 一次性迁移：将旧 sandbox 路径的 DB 复制到 App Group 路径（iOS 重装修复）
    if (Platform.isIOS && !await dbFile.exists()) {
      try {
        final oldDir = await getLibraryDirectory();
        final oldFile = File(p.join(oldDir.path, 'db.sqlite'));
        if (await oldFile.exists()) {
          await oldFile.copy(dbFile.path);
          await oldFile.delete();
        }
      } catch (_) {
        // 迁移失败时忽略，直接创建全新数据库
      }
    }

    return NativeDatabase(dbFile);
  });
}
