// network.dart
// 极简网络状态管理器 - 使用 Riverpod StateNotifier

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 网络状态
enum GchNetStatus {
  connected,
  disconnected,
  checking,
  unknown;

  bool get isOnline => this == GchNetStatus.connected;
}

/// 网络状态模型
@immutable
class GchNetState {
  final GchNetStatus status;
  final DateTime lastCheck;
  final String? error;
  final Map<String, GchHostCheckState> hostStates;

  const GchNetState({
    required this.status,
    required this.lastCheck,
    this.error,
    this.hostStates = const {},
  });

  factory GchNetState.initial() => GchNetState(
    status: GchNetStatus.unknown,
    lastCheck: DateTime.now(),
    hostStates: const {},
  );

  GchNetState copyWith({
    GchNetStatus? status,
    DateTime? lastCheck,
    String? error,
    Map<String, GchHostCheckState>? hostStates,
  }) {
    return GchNetState(
      status: status ?? this.status,
      lastCheck: lastCheck ?? this.lastCheck,
      error: error,
      hostStates: hostStates ?? this.hostStates,
    );
  }

  bool get isOnline => status.isOnline;
}

/// 主动探测配置
class GchHostCheckConfig {
  final String key;
  final List<GchHostCheckTarget> targets;
  final Duration ttl;

  const GchHostCheckConfig({
    required this.key,
    required this.targets,
    this.ttl = const Duration(seconds: 45),
  });
}

/// 单个探测目标
class GchHostCheckTarget {
  final String host;
  final int port;

  const GchHostCheckTarget(this.host, this.port);
}

/// 域名可达性状态
@immutable
class GchHostCheckState {
  static const Duration defaultTtl = Duration(seconds: 45);
  final bool? reachable;
  final DateTime? checkedAt;
  final Duration ttl;
  final String? error;

  const GchHostCheckState({
    this.reachable,
    this.checkedAt,
    this.ttl = defaultTtl,
    this.error,
  });

  bool get isFresh {
    if (reachable == null || checkedAt == null) return false;
    return DateTime.now().difference(checkedAt!) < ttl;
  }
}

/// 网络状态通知器 - 使用 StateNotifier
class GchNetNotifier extends StateNotifier<GchNetState> {
  StreamSubscription<List<ConnectivityResult>>? _listener;
  Timer? _periodicTimer;
  Timer? _debounceTimer; // 防抖计时器
  bool _disposed = false; // 添加 disposed 标记
  bool _isChecking = false; // 防止并发检查
  final Map<String, GchHostCheckConfig> _hostConfigs;
  final Map<String, GchHostCheckState> _hostCache = <String, GchHostCheckState>{};

  static const Duration _defaultHostTtl = Duration(seconds: 45);
  static const List<GchHostCheckTarget> _defaultSocketTargets = [
    GchHostCheckTarget('8.8.8.8', 53),
    GchHostCheckTarget('1.1.1.1', 53),
    GchHostCheckTarget('223.5.5.5', 53),
  ];

  GchNetNotifier({List<GchHostCheckConfig> hostConfigs = const []})
      : _hostConfigs = {for (final cfg in hostConfigs) cfg.key: cfg},
        super(GchNetState.initial()) {
    _init();
  }

  /// 初始化
  void _init() {
    // 立即检查一次
    probeNetwork();

    // 设置监听
    _setupListener();

    // 🔧 减少频繁检查：5分钟检查一次，降低资源占用
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) {
        // 检查是否已 dispose
        if (!_disposed && mounted) {
          probeNetwork();
        }
      },
    );
  }

  /// 主动检测特定域名
  Future<bool> probeHost(String key) async {
    if (_disposed || !mounted) return false;

    final config = _hostConfigs[key];
    final mapKey = config?.key ?? key;
    final cached = state.hostStates[mapKey];
    final ttl = config?.ttl ?? _defaultHostTtl;
    if (cached != null && cached.ttl == ttl && cached.isFresh) {
      return cached.reachable ?? false;
    }

    final targets = config?.targets ?? [GchHostCheckTarget(key, 443)];
    final result = await _socketCheck(customTargets: targets);
    if (_disposed || !mounted) return result;

    final entry = GchHostCheckState(
      reachable: result,
      checkedAt: DateTime.now(),
      ttl: ttl,
      error: result ? null : 'Host unreachable',
    );
    _setHostState(mapKey, entry);
    return result;
  }

  void _setHostState(String key, GchHostCheckState stateData) {
    _hostCache[key] = stateData;
    state = GchNetState(
      status: state.status,
      lastCheck: state.lastCheck,
      error: state.error,
      hostStates: Map<String, GchHostCheckState>.unmodifiable(_hostCache),
    );
  }

  /// 设置网络监听
  void _setupListener() {
    try {
      _listener = Connectivity().onConnectivityChanged.listen(
        (results) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(seconds: 1), () {
            if (_disposed) return;
            Future.microtask(() async {
              if (_disposed || !mounted) return;
              final hasConnectivity = results.any((r) => r != ConnectivityResult.none);
              if (!hasConnectivity) {
                final socketVerified = await _socketCheck();
                if (!socketVerified) {
                  debugPrint('GchNetNotifier: Disconnect confirmed');
                  state = state.copyWith(
                    status: GchNetStatus.disconnected,
                    lastCheck: DateTime.now(),
                  );
                  return;
                }
              }
              await probeNetwork();
              debugPrint('GchNetNotifier: Status updated to ${state.status}');
            });
          });
        },
        onError: (error) {
          debugPrint('GchNetNotifier: Listener error - $error');
          Future.microtask(() async {
            if (_disposed || !mounted) return;
            await probeNetwork();
          });
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('GchNetNotifier: Setup failed - $e');
    }
  }

  /// 主动检查网络
  Future<void> probeNetwork() async {
    // 检查是否已 dispose 或正在检查中
    if (_disposed || !mounted || _isChecking) return;

    _isChecking = true; // 标记检查中
    state = state.copyWith(status: GchNetStatus.checking);

    try {
      // 主检测
      final hasAccess = await _primaryCheck();

      // 再次检查是否已 dispose（异步操作后）
      if (_disposed || !mounted) return;

      if (!hasAccess) {
        // 回退检测
        final socketOk = await _socketCheck();

        // 再次检查是否已 dispose
        if (_disposed || !mounted) return;

        // ✅ 正确传播失败信号，不再假设在线
        state = state.copyWith(
          status: socketOk ? GchNetStatus.connected : GchNetStatus.disconnected,
          lastCheck: DateTime.now(),
          error: socketOk ? null : 'All network checks failed',
        );
      } else {
        if (_disposed || !mounted) return;

        state = state.copyWith(
          status: GchNetStatus.connected,
          lastCheck: DateTime.now(),
          error: null, // 成功时清除错误
        );
      }
    } catch (e) {
      // 检查是否已 dispose
      if (_disposed || !mounted) return;

      // ❌ 不再默认假设在线，而是设置为 unknown 状态并记录错误
      debugPrint('GchNetNotifier: probeNetwork exception - $e');
      state = state.copyWith(
        status: GchNetStatus.unknown,
        lastCheck: DateTime.now(),
        error: 'Network check exception: $e',
      );
    } finally {
      _isChecking = false; // 检查完成，解除标记
    }
  }

  /// 主要检测方法 - 优先使用 Socket 检测（更快更可靠）
  Future<bool> _primaryCheck() async {
    // 🚀 优先尝试 Socket 检测（更快，模拟器友好）
    final socketResult = await _socketCheck();
    if (socketResult) {
      debugPrint('GchNetNotifier: Primary check succeeded via socket');
      return true;
    }

    debugPrint('GchNetNotifier: All primary check methods failed');
    return false;
  }

  /// Socket 检测方法 - 快速端口探测，任一成功即在线
  Future<bool> _socketCheck({List<GchHostCheckTarget>? customTargets}) async {
    final targets = (customTargets != null && customTargets.isNotEmpty)
        ? customTargets
        : _defaultSocketTargets;

    if (targets.isEmpty) {
      return false;
    }

    // 并发检测前2个目标，提高速度
    final futures = targets.take(2).map((target) async {
      try {
        final socket = await Socket.connect(
          target.host,
          target.port,
          timeout: const Duration(milliseconds: 1500), // 1.5秒超时
        );
        socket.destroy();
        debugPrint('GchNetNotifier: Socket check succeeded via ${target.host}:${target.port}');
        return true;
      } catch (e) {
        debugPrint('GchNetNotifier: Socket check failed for ${target.host}:${target.port} - $e');
        return false;
      }
    }).toList();

    // 等待任一成功或全部失败
    final results = await Future.wait(futures);
    if (results.any((r) => r)) {
      return true;
    }

    // 如果前2个都失败，再尝试更多目标（兜底）
    if (targets.length > 2) {
      for (var i = 2; i < targets.length; i++) {
        final target = targets[i];
        try {
          final socket = await Socket.connect(
            target.host,
            target.port,
            timeout: const Duration(milliseconds: 1500),
          );
          socket.destroy();
          debugPrint('GchNetNotifier: Socket check succeeded via ${target.host}:${target.port}');
          return true;
        } catch (e) {
          debugPrint('GchNetNotifier: Socket check failed for ${target.host}:${target.port} - $e');
        }
      }
    }

    debugPrint('GchNetNotifier: All socket check targets failed');
    return false;
  }

  @override
  void dispose() {
    _disposed = true; // 标记为已销毁
    _listener?.cancel();
    _periodicTimer?.cancel();
    _debounceTimer?.cancel(); // 清理防抖计时器
    super.dispose();
  }
}

// ========== Providers ==========

/// 网络状态 Provider
final gchNetProvider = StateNotifierProvider<GchNetNotifier, GchNetState>((ref) {
  return GchNetNotifier();
});

/// 简化的在线状态 Provider
final gchOnlineProvider = Provider<bool>((ref) {
  final networkState = ref.watch(gchNetProvider);
  return networkState.isOnline;
});

/// 网络状态选择器 Provider
final gchNetStatusProvider = Provider<GchNetStatus>((ref) {
  return ref.watch(gchNetProvider.select((state) => state.status));
});

/// 指定域名的可达性状态
final gchHostStatusProvider = Provider.family<GchHostCheckState?, String>((ref, key) {
  return ref.watch(gchNetProvider.select((state) => state.hostStates[key]));
});

// ========== 全局辅助类 ==========

/// 网络工具类 - 极简静态API
class GchNetGuard {
  GchNetGuard._();

  // 全局容器实例，由应用初始化时设置
  static ProviderContainer? _container;
  static bool _isReady = false;

  /// 设置全局容器（在应用启动时调用）
  static void setup(ProviderContainer container) {
    _container = container;
    _isReady = true;
    debugPrint('GchNetGuard: Initialized with container');
  }

  /// 获取在线状态（同步访问）
  static bool get isReachable {
    // ❌ 未初始化时抛出警告，而不是默认返回 true
    if (!_isReady || _container == null) {
      debugPrint('⚠️ GchNetGuard: Not initialized, cannot determine network status');
      // VPN应用特殊处理：未初始化时假设在线，但记录警告
      return true;
    }

    try {
      final state = _container!.read(gchNetProvider);
      // ✅ 只有明确为 connected 时才返回 true
      final isOnline = state.status == GchNetStatus.connected;
      return isOnline;
    } catch (e) {
      debugPrint('⚠️ GchNetGuard: Error reading network state - $e');
      // 发生错误时返回 unknown 状态（false）
      return false;
    }
  }

  /// 获取网络状态（包含详细信息）
  static GchNetStatus get currentStatus {
    if (!_isReady || _container == null) {
      debugPrint('⚠️ GchNetGuard: Not initialized');
      return GchNetStatus.unknown;
    }

    try {
      return _container!.read(gchNetStatusProvider);
    } catch (e) {
      debugPrint('⚠️ GchNetGuard: Error reading network status - $e');
      return GchNetStatus.unknown;
    }
  }

  /// 网络状态变化流（响应式）
  static Stream<bool> get reachabilityStream {
    if (!_isReady || _container == null) {
      debugPrint('⚠️ GchNetGuard: Not initialized, returning unknown stream');
      return Stream.value(false); // ❌ 未初始化时返回 false，而不是 true
    }

    try {
      return _container!.read(gchNetProvider.notifier).stream
          .map((state) => state.status == GchNetStatus.connected);
    } catch (e) {
      debugPrint('⚠️ GchNetGuard: Error creating stream - $e');
      return Stream.value(false);
    }
  }

  /// 检查网络（通过 ref）
  static Future<void> probeNetwork(WidgetRef ref) async {
    await ref.read(gchNetProvider.notifier).probeNetwork();
  }

  /// 主动检测指定 host，可在关键操作前调用
  static Future<bool> probeHost(String key) async {
    if (!_isReady || _container == null) {
      debugPrint('⚠️ GchNetGuard: Not initialized, host reach check aborted');
      return false;
    }

    try {
      return _container!.read(gchNetProvider.notifier).probeHost(key);
    } catch (e) {
      debugPrint('⚠️ GchNetGuard: probeHost error - $e');
      return false;
    }
  }

  /// 检查是否已初始化
  static bool get isReady => _isReady && _container != null;
}
