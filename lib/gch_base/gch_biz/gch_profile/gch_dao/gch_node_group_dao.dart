import 'package:drift/drift.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_profile/gch_model/gch_node_tables.dart';
import 'package:guichao/gch_aux/gch_common.dart';

part 'gch_node_group_dao.g.dart';

abstract interface class GchNodeGroupDataSrc {
  // 监听分组，profileId 为 null 时返回所有
  Stream<List<ProxyGroupEntry>> watchAllGroups([String? profileId]);

  // 获取指定配置文件下的所有分组
  Future<List<ProxyGroupEntry>> getAllGroups(String profileId);

  // 获取指定配置文件下的特定分组
  Future<ProxyGroupEntry?> getGroup(String profileId, String tag);

  // 插入或更新单个分组
  Future<void> upsertGroup(GchNodeGroupTableCompanion entry);

  // 批量插入或更新分组
  Future<void> upsertGroups(String profileId, List<GchNodeGroupTableCompanion> entries);

  // 更新分组的选中项
  Future<void> updateSelected(String profileId, String groupTag, String? selectedItemTag);

  // 删除指定分组
  Future<void> deleteGroup(String profileId, String tag);

  // 删除不在保留列表中的分组（用于同步时清理）
  Future<void> deleteGroupsNotIn(String profileId, List<String> tagsToKeep);

  // 删除指定配置文件的所有分组
  Future<void> deleteAllGroups(String profileId);
}

@DriftAccessor(tables: [GchNodeGroupTable])
class GchNodeGroupDao extends DatabaseAccessor<GchDatabase> with _$GchNodeGroupDaoMixin, GchInfraLogger implements GchNodeGroupDataSrc {
  GchNodeGroupDao(super.db);

  @override
  Stream<List<ProxyGroupEntry>> watchAllGroups([String? profileId]) {
    final query = select(proxyGroupEntries)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.tag)]);
    if (profileId != null) {
      query.where((tbl) => tbl.id.equals(profileId));
    }
    return query.watch();
  }

  @override
  Future<List<ProxyGroupEntry>> getAllGroups(String profileId) {
    return (select(proxyGroupEntries)
          ..where((tbl) => tbl.id.equals(profileId))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.tag),
          ]))
        .get();
  }

  @override
  Future<ProxyGroupEntry?> getGroup(String profileId, String tag) {
    return (select(proxyGroupEntries)..where((tbl) => tbl.id.equals(profileId) & tbl.tag.equals(tag))).getSingleOrNull();
  }

  @override
  Future<void> upsertGroup(GchNodeGroupTableCompanion entry) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final fixedEntry = entry.copyWith(
      role: entry.role,
      access: entry.access,
      tagAlias: entry.tagAlias,
      lastUpdate: Value(now),
    );
    return into(proxyGroupEntries).insert(
      fixedEntry,
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<void> upsertGroups(String profileId, List<GchNodeGroupTableCompanion> entries) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return batch(
      (batch) {
        batch.insertAllOnConflictUpdate(
          proxyGroupEntries,
          entries.map((e) => e.copyWith(
                id: Value(profileId),
                role: e.role,
                access: e.access,
                tagAlias: e.tagAlias,
                lastUpdate: Value(now),
              ),),
        );
      },
    );
  }

  @override
  Future<void> updateSelected(String profileId, String groupTag, String? selectedItemTag) {
    return (update(proxyGroupEntries)..where((tbl) => tbl.id.equals(profileId) & tbl.tag.equals(groupTag))).write(
      GchNodeGroupTableCompanion(
        selectedTag: Value(selectedItemTag),
        lastUpdate: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> deleteGroup(String profileId, String tag) {
    return (delete(proxyGroupEntries)..where((tbl) => tbl.id.equals(profileId) & tbl.tag.equals(tag))).go();
  }

  @override
  Future<void> deleteGroupsNotIn(String profileId, List<String> tagsToKeep) {
    return (delete(proxyGroupEntries)..where((tbl) => tbl.id.equals(profileId) & tbl.tag.isNotIn(tagsToKeep))).go();
  }

  @override
  Future<void> deleteAllGroups(String profileId) {
    return (delete(proxyGroupEntries)..where((tbl) => tbl.id.equals(profileId))).go();
  }
}
