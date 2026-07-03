
/// 生产级 KV 存储框架统一导出
export 'gch_kv_api.dart';
export 'gch_kv_box.dart';
export 'gch_kv_mgr.dart';
export 'gch_kv_ex.dart';
export 'gch_kv_enc.dart';

/// 使用示例 - 生产级用法:
///
/// ```dart
/// // 1. 应用启动时初始化
/// await gchKv.init();
///
/// // 2. 注册适配器
/// await gchKv.adapter(UserAdapter());
///
/// // 3. 创建盒子并使用
/// final userBox = await gchOpenKvBox<User>('users', secure: true);
///
/// try {
///   // 存储
///   await userBox.put('current', user);
///
///   // 获取
///   final user = await userBox.get('current');
///
///   // 批量操作
///   await userBox.putAll({
///     'user1': user1,
///     'user2': user2,
///   });
///
///   // 监听变化
///   userBox.watch().listen((event) {
///     print('用户数据变化: ${event.key}');
///   });
///
/// } finally {
///   // 确保资源释放
///   await userBox.dispose();
/// }
///
/// // 4. 应用关闭时清理
/// await gchKv.dispose();
/// ```
///
/// 生产级特性:
/// - 完整的错误处理和异常管理
/// - 智能线程安全策略（依赖Hive内部锁 + 资源管理锁）
/// - 自动资源管理和内存泄漏防护
/// - 安全的加密密钥管理
/// - 严格的类型检查和空安全
/// - 数据完整性检查和健康监控
/// - 优雅的资源释放机制
/// - 高性能：移除冗余锁，避免双重锁开销
///
/// 性能优化:
/// - 简化架构：移除复杂锁机制，依赖Hive内部安全
/// - 性能提升：减少锁竞争，提高并发性能
/// - 保持安全：完整的错误处理和资源管理
