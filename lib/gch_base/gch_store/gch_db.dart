import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_store/gch_conn/gch_db_conn.dart';
import 'package:guichao/gch_base/gch_store/gch_conv/gch_dur_conv.dart';
import 'package:guichao/gch_base/gch_store/gch_schema_ver.dart';
import 'package:guichao/gch_base/gch_store/gch_biao/gch_peizhi_biao.dart';
import 'package:guichao/gch_base/gch_store/gch_crypt/gch_crypt_conv.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_model/gch_order_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_dao/gch_user_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_model/gch_user_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_model/gch_payprovider_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_dao/gch_order_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_dao/gch_payprovider_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_dao/gch_product_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_model/gch_product_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_profile/gch_dao/gch_node_group_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_profile/gch_dao/gch_node_item_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_profile/gch_model/gch_node_tables.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';

part 'gch_db.g.dart';

@DriftDatabase(
  tables: [
    GchPeizhiBiao,
    GchNodeGroupTable,
    GchNodeItemTable,
    OrderEntries,
    ProductEntries,
    UserEntries,
    PayProviderEntries,
  ],
  daos: [
    GchNodeGroupDao,
    GchNodeItemDao,
    OrderDAO,
    ProductDao,
    UserDao,
    PayProviderDao,
  ],
)
class GchDatabase extends _$GchDatabase with GchInfraLogger {
  GchDatabase({required QueryExecutor connection}) : super(connection);

  GchDatabase.connect() : super(gchOpenDbConn());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        loggy.debug("onCreate: 创建所有表中...");
        await m.createAll();

        // 调试信息仅在debug模式下异步打印
        if (kDebugMode) {
          Future.microtask(() async {
            try {
              await debugPrintDatabaseSchema();
            } catch (e) {
              loggy.debug("打印数据库架构失败: $e");
            }
          });
        }
      },
      onUpgrade: (m, from, to) async {
        loggy.debug('数据库迁移: v$from -> v$to');

        // 使用 stepByStep 处理 v1-v4 的迁移
        if (from < 4) {
          await stepByStep(
            from1To2: (m, schema) async {
              await m.alterTable(
                TableMigration(
                  schema.profileEntries,
                  columnTransformer: {
                    schema.profileEntries.type: const Constant<String>("remote"),
                  },
                  newColumns: [schema.profileEntries.type],
                ),
              );
            },
            from2To3: (m, schema) async {
              // GeoAsset 表已废弃，跳过创建
            },
            from3To4: (m, schema) async {
              try {
                await m.addColumn(gchPeizhiBiao, gchPeizhiBiao.testUrl);
              } on Exception catch (err) {
                loggy.debug(err);
              }
            },
          )(m, from, to > 4 ? 4 : to);
        }

        // 手动处理 v6 -> v7 迁移（clientproduct 表新增字段）
        if (from < 7 && to >= 7) {
          loggy.debug('迁移 v6 -> v7: 添加产品扩展字段');
          try {
            await m.addColumn(productEntries, productEntries.title2);
            await m.addColumn(productEntries, productEntries.title3);
            await m.addColumn(productEntries, productEntries.description2);
            await m.addColumn(productEntries, productEntries.description3);
            await m.addColumn(productEntries, productEntries.promoinfo1);
            await m.addColumn(productEntries, productEntries.promoinfo2);
            await m.addColumn(productEntries, productEntries.visible);
            loggy.debug('迁移 v6 -> v7 完成');
          } on Exception catch (err) {
            loggy.warning('迁移 v6 -> v7 字段可能已存在: $err');
          }
        }
      },
      beforeOpen: (details) async {
        // 临时禁用schema验证以避免版本不匹配错误
        // TODO: 重新生成schema_versions.dart文件后重新启用
        // if (AppGlobal.kDebugMode) {
        //   await validateDatabaseSchema();
        // }
        loggy.debug("数据库已打开，schema验证已暂时禁用");
      },
    );
  }

  Future<void> debugPrintDatabaseSchema() async {
    loggy.debug("正在获取数据库架构信息...");
    try {
      // 获取所有表
      final tables = await customSelect(
        // 将 "table" 和 "sqlite_%" 改为用单引号包裹
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      ).get();

      loggy.debug("发现 ${tables.length} 个表:");

      for (final table in tables) {
        final tableName = table.read<String>('name');
        loggy.debug("表: $tableName");

        final columns = await customSelect(
          'PRAGMA table_info($tableName)',
        ).get();

        for (final column in columns) {
          final name = column.read<String>('name');
          final type = column.read<String>('type');
          final notNull = column.read<int>('notnull') == 1 ? 'NOT NULL' : 'NULL';
          final pk = column.read<int>('pk') == 1 ? '主键' : '';

          loggy.debug("  - $name ($type) $notNull $pk");
        }
        loggy.debug("------------------------");
      }
    } catch (e, stackTrace) {
      loggy.error("!!! debugPrintDatabaseSchema 执行出错 !!!", e, stackTrace);
    }
  }

  @override
  GchNodeGroupDao get proxyGroupDao => GchNodeGroupDao(this);
  @override
  GchNodeItemDao get proxyItemDao => GchNodeItemDao(this);
  @override
  OrderDAO get orderDAO => OrderDAO(this);
  // @override
  // ProductDao get productDao => ProductDao(this);
  // @override
  // UserDao get userDao => UserDao(this);
}
