/// 数据库初始数据插入
///
/// 简单的初始化数据插入，支持SQLite

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_store/gch_crypt/gch_crypt_conv.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_model/gch_payprovider_model.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';

/// 初始化数据管理器
class InitData with GchInfraLogger {

  /// 初始化 SQLite 数据
  static Future<void> init({
    GchDatabase? db,
  }) async {
    if (db == null) {
      throw ArgumentError(
        'GchDatabase 实例为空，无法初始化。'
        '请确保在调用 InitData.init() 时传入 db 参数。'
      );
    }
    await initSqlite(db);
  }

  /// SQLite初始化
  static Future<void> initSqlite(GchDatabase db) async {
    try {
      // 确保FieldEncryptor已初始化
      await _initCrypto();

      final deviceId = await GchNucleus.fetchDeviceFingerprint();

      // 检查是否已存在
      final exists = await _checkExists(db, deviceId);
      if (exists) {
        print('设备 $deviceId 的初始数据已存在，跳过初始化');
        return;
      }

      // 插入初始数据
      await _insertProfile(db, deviceId, GchNucleus.defaultInitDataUrl, GchNucleus.defaultInitName);

      // 插入支付渠道初始数据
      await _insertPayProviders(db);

      print('SQLite初始数据插入成功，设备ID: $deviceId');

    } catch (e, _) {
      print('SQLite初始化失败: $e');
      rethrow;
    }
  }

  /// 确保FieldEncryptor已初始化 - 增强版本
  static Future<void> _initCrypto() async {
    if (FieldEncryptor.isReady) {
      print('[InitData] FieldEncryptor已初始化');
      return;
    }

    print('[InitData] FieldEncryptor未初始化，正在初始化...');
    try {
      await FieldEncryptor.setup();
      print('[InitData] ✅ FieldEncryptor初始化完成');

      // 验证初始化是否成功
      FieldEncryptor.encryptValue('test');
      print('[InitData] ✅ FieldEncryptor功能验证成功');
    } catch (e, stackTrace) {
      print('[InitData] ❌ FieldEncryptor初始化或验证失败: $e');
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 检查记录是否存在
  static Future<bool> _checkExists(GchDatabase db, String deviceId) async {
    final query = db.select(db.gchPeizhiBiao)
      ..where((p) => p.id.equals(deviceId));

    final existing = await query.getSingleOrNull();
    return existing != null;
  }

  /// 插入Profile记录
  static Future<void> _insertProfile(GchDatabase db, String id, String url, String name) async {
    final entry = GchPeizhiBiaoCompanion.insert(
      id: id,
      type: 'remote',
      active: true,
      name: name,
      url: Value(url),
      lastUpdate: DateTime.now(),
    );

    await db.into(db.gchPeizhiBiao).insert(entry);
    print('插入Profile成功: id=$id, url=$url, name=$name');
  }

  /// 插入支付渠道初始数据
  static Future<void> _insertPayProviders(GchDatabase db) async {
    try {
      // 检查是否已存在支付渠道数据
      final existing = await db.select(db.payProviderEntries).get();
      if (existing.isNotEmpty) {
        print('支付渠道数据已存在，跳过初始化');
        return;
      }

      // 获取初始支付渠道数据
      final initialData = _getInitialPayProviders();

      // 批量插入
      for (final providerData in initialData) {
        await db.into(db.payProviderEntries).insert(providerData);
      }

      print('支付渠道初始数据插入成功，共 ${initialData.length} 个渠道');
    } catch (e) {
      print('插入支付渠道初始数据失败: $e');
      rethrow;
    }
  }

  /// 获取支付渠道初始数据
  static List<PayProviderEntriesCompanion> _getInitialPayProviders() {
    return [
      // Apple App Store 应用内购买
      PayProviderEntriesCompanion.insert(
        code: 'applepay',
        name: 'app store',
        method: Value(PayMethod.appStore.value),
        payType: Value(PayType.inAppPurchase.value),
        iconUrl: const Value('assets/icons/app_store.png'),
        status: const Value(1),
        config: const Value('{"product_ids":["premium_monthly","premium_yearly","remove_ads"],"auto_finish":true}'),
        regions: const Value('GLOBAL'),
        environment: const Value('production'),
        clientTypes: const Value('ios'),
      ),


    ];
  }
}
