/// 订阅管理器 - 极简单文件实现
/// 
/// 复刻SecureDownloadStrategy下载逻辑，支持固定时间循环和认证状态触发
/// 集成事件机制用于状态监控和调试
/// 生产级改进：并发控制、增强安全性、容错机制
library;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_providers/gch_auth_providers.dart';
import 'package:guichao/gch_base/gch_biz/gch_auth/gch_svc/gch_auth_provider_interface.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';
part 'gch_subscription_provider.g.dart';

// ============================================================================
// 事件定义 - 复刻subscription_events.dart的核心事件
// ============================================================================

/// 订阅事件基类
abstract class SubscriptionEvent {
  const SubscriptionEvent({
    required this.timestamp,
    this.data,
  });

  final DateTime timestamp;
  final Map<String, dynamic>? data;

  @override
  String toString() => '${runtimeType}(timestamp: $timestamp, data: $data)';
}

/// 订阅失败事件 - 极简版本
class SubscriptionFailed extends SubscriptionEvent {
  SubscriptionFailed({
    required this.profileId,
    required this.error,
    this.stackTrace,
    super.data,
  }) : super(timestamp: DateTime.now());

  final String profileId;
  final Object error;
  final StackTrace? stackTrace;

  @override
  String toString() => 'SubscriptionFailed(profileId: $profileId, error: $error)';
}

/// 认证状态变化事件
class AuthStateChanged extends SubscriptionEvent {
  AuthStateChanged({
    required this.isAuthenticated,
    required this.tokenRefreshed,
    this.userId,
    super.data,
  }) : super(timestamp: DateTime.now());

  final bool isAuthenticated;
  final bool tokenRefreshed;
  final String? userId;

  @override
  String toString() => 'AuthStateChanged(isAuthenticated: $isAuthenticated, tokenRefreshed: $tokenRefreshed)';
}

/// 订阅管理器实现类
class SubscriptionManagerImpl with GchInfraLogger {
  SubscriptionManagerImpl(this._ref);
  
  final Ref _ref;
  Timer? _periodicTimer;
  ProviderSubscription<AsyncValue<AuthProviderState>>? _authSubscription;

  // 事件流控制器
  final StreamController<SubscriptionEvent> _eventController = StreamController.broadcast();

  // 并发控制 - 防止重复更新
  bool _isUpdating = false;
  final Set<String> _updatingProfiles = {};

  // 防循环状态标记 - 防止认证状态触发的循环调用
  bool _isUpdatingFromAuth = false;

  // 【修复：内存泄漏】可取消的延迟任务 - 替代 Future.delayed
  Timer? _authDebounceTimer;
  Timer? _authResetTimer;

  // 内容hash缓存 - 用于检测内容变化
  final Map<String, int> _contentHashes = {};
  
  void initialize() {
    _startServices();
  }
  
  /// 事件流 - 对外暴露事件监听
  Stream<SubscriptionEvent> get eventStream => _eventController.stream;
  
  /// 启动服务
  void _startServices() {
    loggy.info('启动订阅服务...');

    // ✅ 防止资源泄漏：创建新资源前先释放可能存在的旧资源
    _periodicTimer?.cancel();
    _authSubscription?.close();

    // 固定时间循环：生产环境1小时，调试模式30秒
    final interval = GchNucleus.isDevMode ? Duration(seconds: 3000) : Duration(hours: 1);
    _periodicTimer = Timer.periodic(interval, (_) {
      loggy.info('定时触发订阅更新');
      UpdateAll();
    });

    // 认证状态变化触发更新 - 使用正确的provider
    String? _prevUserId;
    _authSubscription = _ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((authState) {
        final currentUserId = authState.user?.userId;

        // 用户切换时清理缓存
        if (_prevUserId != null && _prevUserId != currentUserId) {
          loggy.info('用户切换 $_prevUserId -> $currentUserId，清理订阅缓存');
          _contentHashes.clear();
        }
        _prevUserId = currentUserId;

        // 防循环检查 - 避免认证状态变化引起的循环调用
        if (_isUpdatingFromAuth) {
          loggy.debug('正在处理认证状态更新，跳过循环触发');
          return;
        }

        // 【修复：内存泄漏】使用可取消的 Timer 替代 Future.delayed
        // 防抖处理 - 避免频繁触发
        _authDebounceTimer?.cancel();
        _authDebounceTimer = Timer(Duration(seconds: 2), () {
          if (authState.isAuthenticated && !_isUpdatingFromAuth) {
            _isUpdatingFromAuth = true;
            loggy.info('认证状态变化，触发订阅更新');

            // 发送认证状态变化事件
            final event = AuthStateChanged(
              isAuthenticated: authState.isAuthenticated,
              tokenRefreshed: authState.session != null,
              userId: authState.user?.userId,
            );
            _emitEvent(event);

            UpdateAll().whenComplete(() {
              // 【修复：内存泄漏】使用可取消的 Timer 替代 Future.delayed
              // 更新完成后重置标记
              _authResetTimer?.cancel();
              _authResetTimer = Timer(Duration(seconds: 1), () {
                _isUpdatingFromAuth = false;
              });
            });
          }
        });
      });
    });
  }
  
  /// 安全的批量更新 - 带并发控制
  Future<void> UpdateAll() async {
    if (_isUpdating) {
      loggy.debug('已有更新任务在执行，跳过本次触发');
      return;
    }
    
    _isUpdating = true;
    try {
      await updateAllSubscriptions();
    } finally {
      _isUpdating = false;
    }
  }
  
  /// 清理资源 - 增强版
  void _cleanup() {
    loggy.info('清理订阅服务资源');
    _periodicTimer?.cancel();
    _authSubscription?.close();

    // 【修复：内存泄漏】取消所有延迟任务
    _authDebounceTimer?.cancel();
    _authDebounceTimer = null;
    _authResetTimer?.cancel();
    _authResetTimer = null;

    // 确保事件流正确关闭
    if (!_eventController.isClosed) {
      _eventController.close();
    }

    _updatingProfiles.clear();
    _contentHashes.clear();
    _isUpdatingFromAuth = false; // 重置循环保护标记
  }
  
  /// 发送事件 - 内部使用
  void _emitEvent(SubscriptionEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
      loggy.debug('发送事件: $event');
    }
  }
  
  /// 更新单个订阅 - 占位实现（VPN 模块已移除）
  Future<bool> updateSubscription(String profileId) async {
    loggy.debug('订阅更新暂不支持（VPN模块已移除）: $profileId');
    return false;
  }
  
  /// 验证订阅内容是否有效
  bool _isValidSubscriptionContent(String content) {
    // 内容不能为空
    if (content.trim().isEmpty) return false;

    // 内容长度合理性检查 (至少要有基本的配置信息)
    if (content.length < 10) return false;

    // 检查是否是错误页面或无效响应
    final lowerContent = content.toLowerCase();
    final errorPatterns = [
      '404 not found',
      '403 forbidden',
      '500 internal server error',
      'access denied',
      'page not found',
      'timeout',
      'connection failed',
      '<html>',  // HTML页面通常不是订阅内容
      '<!doctype html>',
    ];

    for (final pattern in errorPatterns) {
      if (lowerContent.contains(pattern)) {
        return false;
      }
    }

    return true;
  }

  /// 增强的URL验证 - 生产级安全检查
  bool _isValidUrl(String url) {
    if (url.isEmpty || url.length > 2048) return false;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // 只允许http和https
    if (!['http', 'https'].contains(uri.scheme)) return false;
    return true;
  }
  
  /// URL脱敏处理
  String _sanitizeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'invalid_url';
    return '${uri.scheme}://${uri.host}/...';
  }
  
  /// 错误信息脱敏
  Object _sanitizeError(Object error) {
    // 生产环境不暴露详细错误
    if (kReleaseMode) {
      return 'Subscription update failed';
    }
    return error.toString();
  }
  
  /// 更新所有订阅 - 占位实现（VPN 模块已移除）
  Future<void> updateAllSubscriptions() async {
    loggy.debug('批量订阅更新暂不支持（VPN模块已移除）');
  }
  
  /// 手动更新订阅 - 对外API
  Future<bool> manualUpdate(String profileId) async {
    loggy.info('手动触发订阅更新: $profileId');
    return await updateSubscription(profileId);
  }
  
  /// 手动更新所有订阅 - 对外API
  Future<void> manualUpdateAll() async {
    loggy.info('手动触发全部订阅更新');
    await UpdateAll();
  }
}

/// 订阅管理器Provider
@Riverpod(keepAlive: true)
class SubscriptionManager extends _$SubscriptionManager {
  late final SubscriptionManagerImpl _impl;
  
  @override
  SubscriptionManagerImpl build() {
    _impl = SubscriptionManagerImpl(ref);
    _impl.initialize();
    
    ref.onDispose(() {
      _impl._cleanup();
    });
    
    return _impl;
  }
}

/// 对外暴露的订阅服务接口
@Riverpod(keepAlive: true)
SubscriptionService subscriptionService(SubscriptionServiceRef ref) {
  final manager = ref.watch(subscriptionManagerProvider);
  return SubscriptionService._(manager);
}

/// 订阅事件流提供者
@Riverpod(keepAlive: true)
Stream<SubscriptionEvent> subscriptionEventStream(SubscriptionEventStreamRef ref) {
  final manager = ref.watch(subscriptionManagerProvider);
  return manager.eventStream;
}

/// 简化的订阅服务包装类
class SubscriptionService {
  SubscriptionService._(this._manager);
  
  final SubscriptionManagerImpl _manager;
  
  /// 手动更新单个订阅
  Future<bool> updateSubscription(String profileId) => 
      _manager.manualUpdate(profileId);
  
  /// 手动更新所有订阅
  Future<void> updateAllSubscriptions() => 
      _manager.manualUpdateAll();
  
  /// 订阅事件流 - 用于监听订阅状态变化
  Stream<SubscriptionEvent> get eventStream => _manager.eventStream;
  
  /// 监听特定类型的事件
  Stream<T> listenToEventType<T extends SubscriptionEvent>() =>
      eventStream.where((event) => event is T).cast<T>();
}