import 'package:drift/drift.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_profile/gch_model/gch_node_tables.dart';
import 'package:guichao/gch_aux/gch_common.dart';

part 'gch_node_item_dao.g.dart';

abstract interface class GchNodeItemDataSrc {
  // 监听代理项，profileId 为 null 时返回所有
  Stream<List<ProxyItemEntry>> watchAllItems([String? profileId]);

  // 获取指定配置文件下的所有代理项
  Future<List<ProxyItemEntry>> getAllItems(String profileId);

  // 监听指定配置文件下指定分组的代理项
  Stream<List<ProxyItemEntry>> watchItemsByGroup(String profileId, String groupTag);

  // 获取指定代理项
  Future<ProxyItemEntry?> getItem(String profileId, String itemTag);

  // 插入或更新单个代理项
  Future<void> upsertItem(GchNodeItemTableCompanion entry);

  // 批量插入或更新代理项
  Future<void> upsertItems(String profileId, List<GchNodeItemTableCompanion> entries);

  // 更新代理项延迟
  Future<void> updateItemDelay(String profileId, String itemTag, int delay);

  // 删除指定代理项
  Future<void> deleteItem(String profileId, String itemTag);

  // 删除不在保留列表中的代理项（用于同步时清理）
  // [userVipType] 当前用户的 VIP 等级值
  // 保留规则：虚拟节点 (virtual=true) 且 access > userVipType 的节点会被保留
  Future<void> deleteItemsNotIn(String profileId, List<String> tagsToKeep, int userVipType);

  // 删除指定配置文件的所有代理项
  Future<void> deleteAllItems(String profileId);

  // 删除指定分组下的所有代理项（级联删除用）
  Future<void> deleteItemsByGroupTag(String profileId, String groupTag);
}

@DriftAccessor(tables: [GchNodeItemTable])
class GchNodeItemDao extends DatabaseAccessor<GchDatabase> with _$GchNodeItemDaoMixin, GchInfraLogger implements GchNodeItemDataSrc {
  GchNodeItemDao(super.db);

  @override
  Stream<List<ProxyItemEntry>> watchAllItems([String? profileId]) {
    final query = select(proxyItemEntries)
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.urlTestDelay),
        (tbl) => OrderingTerm(expression: tbl.tag),
      ]);
    if (profileId != null) {
      query.where((tbl) => tbl.id.equals(profileId));
    }
    return query.watch();
  }

  @override
  Stream<List<ProxyItemEntry>> watchItemsByGroup(String profileId, String groupTag) {
    return (select(proxyItemEntries)..where((tbl) => tbl.id.equals(profileId) & tbl.groupTag.equals(groupTag))).watch();
  }

  @override
  Future<ProxyItemEntry?> getItem(String profileId, String itemTag) {
    return (select(proxyItemEntries)..where((tbl) => tbl.id.equals(profileId) & tbl.tag.equals(itemTag))).getSingleOrNull();
  }

  @override
  Future<void> upsertItem(GchNodeItemTableCompanion entry) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final fixedEntry = entry.copyWith(
      role: entry.role,
      access: entry.access,
      tagAlias: entry.tagAlias,
      groupTagAlias: entry.groupTagAlias,
      lastUpdate: Value(now),
    );
    return into(proxyItemEntries).insert(
      fixedEntry,
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<void> upsertItems(String profileId, List<GchNodeItemTableCompanion> entries) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return batch(
      (batch) {
        batch.insertAllOnConflictUpdate(
          proxyItemEntries,
          entries.map((e) => e.copyWith(
                id: Value(profileId),
                role: e.role,
                access: e.access,
                tagAlias: e.tagAlias,
                groupTagAlias: e.groupTagAlias,
                lastUpdate: Value(now),
              ),),
        );
      },
    );
  }

  @override
  Future<void> updateItemDelay(String profileId, String itemTag, int delay) {
    return (update(proxyItemEntries)..where((tbl) => tbl.id.equals(profileId) & tbl.tag.equals(itemTag))).write(
      GchNodeItemTableCompanion(
        urlTestDelay: Value(delay),
        lastCheck: Value(DateTime.now().millisecondsSinceEpoch),
        lastUpdate: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> deleteItem(String profileId, String itemTag) {
    return (delete(proxyItemEntries)..where((tbl) => tbl.id.equals(profileId) & tbl.tag.equals(itemTag))).go();
  }

  @override
  Future<void> deleteItemsNotIn(String profileId, List<String> tagsToKeep, int userVipType) {
    // 删除逻辑：
    // 1. 不在 tagsToKeep 中的节点需要考虑删除
    // 2. 但保留：virtual=true 且 access > userVipType 的节点（用户无权访问的高级节点）
    // 3. 删除：virtual=false 的节点，或 virtual=true 但 access <= userVipType 的节点（异常情况）
    //
    // 简化逻辑：删除条件 = 不在列表中 且 (非虚拟节点 或 虚拟但用户等级已足够)
    return (delete(proxyItemEntries)
          ..where((tbl) =>
              tbl.id.equals(profileId) &
              tbl.tag.isNotIn(tagsToKeep) &
              (tbl.virtual.equals(false) | tbl.access.isSmallerOrEqualValue(userVipType))))
        .go();
  }

  @override
  Future<void> deleteAllItems(String profileId) {
    return (delete(proxyItemEntries)..where((tbl) => tbl.id.equals(profileId))).go();
  }

  @override
  Future<List<ProxyItemEntry>> getAllItems(String profileId) {
    return (select(proxyItemEntries)
          ..where((tbl) => tbl.id.equals(profileId))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.urlTestDelay),
            (tbl) => OrderingTerm(expression: tbl.tag),
          ]))
        .get();
  }

  @override
  Future<void> deleteItemsByGroupTag(String profileId, String groupTag) {
    return (delete(proxyItemEntries)
          ..where((tbl) => tbl.id.equals(profileId) & tbl.groupTag.equals(groupTag)))
        .go();
  }
}
