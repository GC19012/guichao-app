// appprovider.dart
// 应用状态管理中心 - 基于增强网络接口的现代化架构

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_store/gch_db_provider.dart';
import 'package:guichao/gch_base/gch_flux/gch_flux_engine.dart';
import 'package:guichao/gch_base/gch_flux/gch_flux_provider.dart';
import 'package:guichao/gch_base/gch_kit/gch_anr.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_manager.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_providers/gch_api_client_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_dao/gch_order_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_dao/gch_order_dao_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_dao/gch_sqlite_order_dao_adapter.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_repo/gch_order_repository.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_svc/gch_order_service.dart';
import 'package:guichao/gch_base/gch_biz/gch_order/gch_vm/gch_order_viewmodel.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_manager.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_api/gch_user_api.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_dao/gch_user_dao.dart';
import 'package:guichao/gch_base/gch_biz/gch_user/gch_repo/gch_user_repository.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_event_bus.dart';

/// 应用配置
final appConfigProvider = Provider<GchNucleus>((ref) {
  return GchNucleus.instance;
});

// 注意：gchFluxProvider 统一使用 gch_flux_provider.dart 中的定义
// 不再在此处重复定义，避免职责混乱
// 使用方式: ref.watch(gchFluxProvider)

// 业务Provider

/// 全局支付事件总线（应用级生命周期）
///
/// 注意：此Provider管理PaymentEventBus的应用级生命周期
/// - 首次访问时自动创建
/// - 应用退出时自动销毁
/// - 独立于任何业务组件（PaymentManager只是订阅者之一）
final paymentEventBusProvider = Provider<PaymentEventBus>((ref) {
  final bus = PaymentEventBus.instance;

  // ⚠️ 只在应用退出时销毁事件总线
  // 业务组件（如PaymentManager）不应该销毁它
  ref.onDispose(() {
    debugPrint('⚠️ 应用退出，销毁全局PaymentEventBus');
    bus.dispose();
  });

  return bus;
});

/// 支付管理器（唯一正确的依赖注入入口）
///
/// ⚠️ 重要：
/// 1. 这是创建 PaymentManager 的唯一正确方式
/// 2. 使用前必须调用 `await manager.bootstrap()` 完成初始化
/// 3. 不要使用 payment_provider.dart 中的 paymentServiceProvider（已废弃）
///
/// 使用示例：
/// ```dart
/// final manager = ref.read(paymentManagerProvider);
/// await manager.bootstrap();  // 必须调用
/// manager.setPaymentMethod(PayProvider.alipay);
/// await manager.pay(...);
/// ```
///
/// 详细说明见：lib/core/gch_biz/gch_pay/service/DEPENDENCY_INJECTION.md
/// 🔑 重要：使用 keepAlive 确保全局单例
/// 防止多个 PaymentManager 实例导致多个 InAppPurchaseCallback 监听同一个购买流
/// 这会导致：
/// 1. 购买事件被多个回调接收
/// 2. `_pendingContext` 设置在一个实例上，但事件被另一个实例处理
/// 3. orderNum 无法正确传递到验证流程
final paymentManagerProvider = Provider<PaymentManager>((ref) {
  final mgr = PaymentManager(ref: ref);

  // ✅ 带 ref，可以访问所有 Riverpod 依赖
  // ⚠️ 注意: 不在这里调用 bootstrap()
  //    bootstrap() 需要在应用启动时或首次使用前手动调用
  //    原因: bootstrap() 包含异步初始化，不适合放在 Provider 构造中

  // 确保事件总线已初始化（通过访问Provider）
  ref.watch(paymentEventBusProvider);

  // 🔑 注册 dispose 回调，确保资源正确释放
  ref.onDispose(() {
    debugPrint('🧹 PaymentManager 正在释放...');
    mgr.dispose();
  });

  return mgr;
}, dependencies: [paymentEventBusProvider]);

/// 用户仓库
final userRepositoryProvider = Provider<UserRepositoryInterface>((ref) {
  final db = ref.watch(gchDatabaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  final userDao = UserDao(db);
  final userApi = UserApi(apiClient: apiClient);
  return UserRepository(userApi, userDao);
});

/// ANR检测器
final anrDetectorProvider = Provider<ANRDetector>((ref) {
  final detector = ANRDetector();

  // 只在debug模式下启动ANR检测
  if (GchNucleus.isDevMode) {
    detector.startWatching();
  }

  ref.onDispose(() {
    // ✅ 调用dispose()完全销毁，而不是stopWatching()
    detector.dispose();
  });

  return detector;
});


/// Order DAO Provider - SQLite 实现
final orderDaoProvider = Provider<OrderDaoInterface>((ref) {
  final db = ref.watch(gchDatabaseProvider);
  return SQLiteOrderDaoAdapter(OrderDAO(db));
});

/// 订单服务
final orderServiceProvider = Provider<OrderService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final dao = ref.watch(orderDaoProvider);
  final repo = OrderRepository(dao, apiClient);
  final service = OrderService(repo);

  // 🔄 启动订单过期清理监控（每5分钟自动清理10分钟未支付订单）
  service.startExpirationMonitor();

  // 注册清理回调
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// 状态管理

/// 订单列表管理
final ordersProvider = AsyncNotifierProvider<OrdersNotifier, List<OrderEntry>>(OrdersNotifier.new);

/// 订单详情管理
final orderDetailProvider = AsyncNotifierProviderFamily<OrderDetailNotifier, OrderEntry?, String>(OrderDetailNotifier.new);

// 应用门面类

/// 应用状态管理门面类
/// 提供类型安全、语义清晰的状态访问接口
class AppProvider {
  AppProvider._();

  /// 认证模块
  static final auth = _AuthModule();

  /// 用户模块
  static final user = _UserModule();

  /// 订单模块
  static final orders = _OrderModule();

  /// 支付模块
  static final payment = _PaymentModule();

  /// 配置文件模块
  static final profile = _ProfileModule();

  /// 连接模块
  static final connection = _ConnectionModule();

  /// 核心服务模块
  static final core = _CoreModule();
}

class _AuthModule {
  /// 认证管理器 - 提供 AuthManager 实例
  FutureProvider<AuthManager> get manager => authManagerProvider;

  /// 认证状态 - 基于认证管理器的状态
  Provider<AsyncValue<AuthManager>> get state => Provider((ref) => ref.watch(authManagerProvider));
}

class _UserModule {
  /// 用户仓库
  Provider<UserRepositoryInterface> get repository => userRepositoryProvider;
}

class _OrderModule {
  /// 订单列表
  AsyncNotifierProvider<OrdersNotifier, List<OrderEntry>> get list => ordersProvider;

  /// 订单详情
  AsyncNotifierProviderFamily<OrderDetailNotifier, OrderEntry?, String> get detail => orderDetailProvider;

  /// 订单服务
  Provider<OrderService> get service => orderServiceProvider;
}

class _PaymentModule {
  /// 支付管理器
  Provider<PaymentManager> get manager => paymentManagerProvider;
}

class _ProfileModule {
  // VPN 模块已移除，配置文件相关功能不再可用
}

class _ConnectionModule {
  // VPN 连接模块已移除，连接和统计功能不再可用
}

class _CoreModule {
  /// 数据库
  Provider<GchDatabase> get database => gchDatabaseProvider;

  /// 网络客户端
  Provider<GchFluxEngine> get http => gchFluxProvider;

  /// 应用配置
  Provider<GchNucleus> get config => appConfigProvider;

  /// ANR检测器
  Provider<ANRDetector> get anrDetector => anrDetectorProvider;
}


/*
使用示例:

// 1. 状态监听
final authState = ref.watch(AppProvider.auth.state);
final orders = ref.watch(AppProvider.orders.list);
final connection = ref.watch(AppProvider.connection.notifier);
final activeProxy = ref.watch(AppProvider.profile.active);
final ipInfo = ref.watch(AppProvider.profile.ipInfo);

// 2. 操作执行
final authManager = await ref.read(AppProvider.auth.manager.future);
await authManager.signIn(request);

final addProfile = ref.read(AppProvider.profile.add.notifier);
await addProfile.add(profileUrl);

// 3. 代理操作
final ipNotifier = ref.read(AppProvider.profile.ipInfo.notifier);
await ipNotifier.refresh(); // 刷新IP信息

final activeProxyNotifier = ref.read(AppProvider.profile.active.notifier);
await activeProxyNotifier.pingTest('proxy_group_tag'); // 测试代理延迟

// 4. 认证连接操作
final authConnectionRepo = await ref.read(AppProvider.connection.authRepository.future);
final connectResult = await authConnectionRepo.engage(
  'profile.json',
  'My VPN Profile', 
  false,
  'https://www.google.com',
).run();
// 连接操作会自动进行认证检查

// 5. 实时统计监听
final stats = ref.watch(AppProvider.connection.stats);
stats.when(
  data: (statsEntity) {
    print('上行速度: ${statsEntity.txRate.speed()}');
    print('下行速度: ${statsEntity.rxRate.speed()}');
    print('总上行流量: ${statsEntity.txTotal.size()}');
    print('总下行流量: ${statsEntity.rxTotal.size()}');
  },
  loading: () => print('统计数据加载中...'),
  error: (error, stack) => print('统计数据错误: $error'),
);

// 6. 统计仓库操作
final statsRepo = ref.read(AppProvider.connection.gchStatsRepo);
final statsStream = statsRepo.streamMetrics();
statsStream.listen((either) {
  either.fold(
    (failure) => print('统计获取失败: $failure'),
    (stats) => print('实时统计: ${stats.txRate.speed()} ↑ ${stats.rxRate.speed()} ↓'),
  );
});

// 7. 初始化
void main() {
  runApp(ProviderScope(child: MyApp()));
}
*/

