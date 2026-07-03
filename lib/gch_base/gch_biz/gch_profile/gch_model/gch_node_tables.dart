import 'package:drift/drift.dart';
import 'package:guichao/gch_base/gch_store/gch_crypt/gch_crypt_conv.dart';





// Table to store proxy group information
@DataClassName('ProxyGroupEntry')
class GchNodeGroupTable extends Table {
  // Profile ID - 外键关联到 ProfileEntries.id
  TextColumn get id => text()();

  // Unique tag identifying the group (e.g., "Proxy", "Direct") - 不加密，用于查询
  TextColumn get tag => text()();

  // Type of the group (e.g., "selector", "urltest") - 不加密，用于查询
  TextColumn get type => text()();

  // Tag of the currently selected item within this group - 不加密，用于查询
  TextColumn get selectedTag => text().nullable()();

  // Timestamp of the last health check/URL test (milliseconds since epoch)
  IntColumn get lastCheck => integer().nullable()();

  // Timestamp of when this group record was last updated (milliseconds since epoch)
  IntColumn get lastUpdate => integer()();

  // Optional memo or description for the group - 加密敏感信息
  TextColumn get memo => text().nullable().map(CryptoText.nullable)();

  // Optional role for the group - 默认值 free
  TextColumn get role => text().nullable()();

  // Access level for the group - 默认值 0
  IntColumn get access => integer().nullable()();

  // Group tag alias - 默认和tag一样
  TextColumn get tagAlias => text().nullable()();

  @override
  Set<Column> get primaryKey => {id, tag}; // 复合主键：id + tag
}

// Table to store individual proxy items within a group
@DataClassName('ProxyItemEntry')
class GchNodeItemTable extends Table {
  // Profile ID - 外键关联到 ProfileEntries.id
  TextColumn get id => text()();

  // Unique tag identifying the proxy item - 不加密，用于查询
  TextColumn get tag => text()();

  // Tag of the group this item belongs to - 不加密，用于外键关联
  TextColumn get groupTag => text()();

  // Type of the proxy item - 不加密，用于查询
  TextColumn get type => text()();

  // Tag of the selected item - 不加密，用于查询
  TextColumn get selectedTag => text().nullable()();

  // Last measured URL test delay in milliseconds (0 means untested/failed)
  IntColumn get urlTestDelay => integer().nullable()();

  // Optional memo or description for the proxy item - 加密敏感信息
  TextColumn get memo => text().nullable().map(CryptoText.nullable)();

  // Timestamp of the last health check/URL test for this item (milliseconds since epoch)
  IntColumn get lastCheck => integer().nullable()();

  // Timestamp of when this item record was last updated (milliseconds since epoch)
  IntColumn get lastUpdate => integer()();

  IntColumn get uplink => integer().nullable()();
  IntColumn get downlink => integer().nullable()();
  IntColumn get uplinkTotal => integer().nullable()();
  IntColumn get downlinkTotal => integer().nullable()();

  // Optional role for the item - 默认值 free
  TextColumn get role => text().nullable()();

  // Access level for the item - 默认值 0
  IntColumn get access => integer().nullable()();

  // Tag alias for the item - 默认和tag一样
  TextColumn get tagAlias => text().nullable()();

  // Group tag alias for the item - 默认和groupTag一样
  TextColumn get groupTagAlias => text().nullable()();

  // 虚拟节点标识 - true表示仅展示用，无实际配置文件
  BoolColumn get virtual => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id, tag, groupTag}; // 复合主键：id + tag + groupTag
}
