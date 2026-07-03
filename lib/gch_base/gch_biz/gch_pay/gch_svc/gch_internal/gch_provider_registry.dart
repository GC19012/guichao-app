import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_google_apple_pay_provider.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_providers/gch_payprovider_providers.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider注册与配置管理服务
/// 职责：
/// 1. 管理支付Provider的注册/注销
/// 2. 加载和管理支付配置
/// 3. 初始化已注册的Provider
class ProviderRegistry implements Disposable {
  final Map<PayProvider, PaymentProvider> _providers = {};
  final Ref? ref;
  bool _initialized = false;

  ProviderRegistry({this.ref});

  /// 注册单个Provider
  void register(PayProvider method, PaymentProvider provider) {
    // 🔑 重要：如果已存在同类型 Provider，先 dispose 旧实例
    // 避免多个实例同时监听同一个全局流（如 InAppPurchase.purchaseStream）
    final existing = _providers[method];
    if (existing != null && existing != provider) {
      debugPrint('⚠️ 替换已存在的支付提供者: ${method.name}，正在 dispose 旧实例');
      try {
        (existing as Disposable).dispose();
      } catch (e) {
        debugPrint('⚠️ dispose 旧 Provider 失败: $e');
      }
    }
    _providers[method] = provider;
    debugPrint('✅ 已注册支付提供者: ${method.name}');
  }

  /// 反注册Provider
  void unregister(PayProvider method) {
    final provider = _providers.remove(method);
    if (provider != null) {
      (provider as Disposable).dispose();
      debugPrint('✅ 已注销支付提供者: ${method.name}');
    }
  }

  /// 获取Provider
  PaymentProvider? get(PayProvider method) => _providers[method];

  /// 根据code获取Provider
  PaymentProvider? getByCode(String code) {
    final method = PayProviderExtension.fromCode(code);
    return method != null ? _providers[method] : null;
  }

  /// 获取所有已注册的Provider
  Map<PayProvider, PaymentProvider> get all => Map.unmodifiable(_providers);

  /// 检查Provider是否已注册
  bool contains(PayProvider method) => _providers.containsKey(method);

  /// 批量注册Provider（从数据库配置）
  Future<void> registerFromDatabase() async {
    if (ref == null) return;

    try {
      final providers = await ref!.read(currentPayProvidersProvider.future);
      debugPrint('🔄 从数据库加载到 ${providers.length} 个支付渠道配置');

      for (final config in providers) {
        await _registerProvider(config);
      }
    } catch (e) {
      debugPrint('❌ 从数据库注册Provider失败: $e，使用默认配置');
      await _registerDefaults();
    }
  }

  /// 注册单个Provider（从配置）
  Future<void> _registerProvider(PayProviderEntry config) async {
    if (ref == null) return;

    try {
      final code = config.code;

      // 🔑 先检查是否已存在同类型 Provider，避免重复创建
      // 这是解决多实例问题的关键：InAppPurchaseProvider 的回调会监听全局购买流，
      // 多个实例会导致事件被多次处理，且上下文无法正确传递
      final method = PayProviderExtension.fromCode(code);
      if (method != null && contains(method)) {
        debugPrint('ℹ️ 支付提供者已存在，跳过重复注册: $code -> $method');
        return;
      }

      debugPrint('📝 正在注册支付提供者: $code (status: ${config.status})');

      PaymentProvider? provider;
      // 根据code创建对应的支付提供者
      switch (code) {
        case 'in_app_purchase':
        case 'apple_pay':
        case 'applepay':
          provider = InAppPurchaseProvider(ref: ref);
          break;

        default:
          debugPrint('⚠️ 未支持的支付方式: $code，跳过注册');
          return;
      }

      // 注册
      if (method != null) {
        register(method, provider);
        debugPrint('✅ 成功注册支付提供者: $code -> $method (${config.name})');
      } else {
        debugPrint('❌ 无法找到对应的PayProvider枚举: $code');
      }
    } catch (e) {
      debugPrint('❌ 注册支付提供者失败 ${config.code}: $e');
    }
  }

  /// 注册默认Provider
  Future<void> _registerDefaults() async {
    if (ref == null) return;

    if (!contains(PayProvider.inAppPurchase)) {
      register(PayProvider.inAppPurchase, InAppPurchaseProvider(ref: ref));
    }

    debugPrint('✅ 默认支付提供者注册完成');
  }

  /// 初始化所有已注册的Provider
  Future<void> initializeAll() async {
    if (_initialized) return;

    try {
      final configs = await _loadConfigs();
      await _initProviders(configs);
      _initialized = true;
    } catch (e) {
      debugPrint('❌ 初始化Provider失败: $e');
      rethrow;
    }
  }

  /// 初始化Provider（使用配置）
  Future<void> _initProviders(Map<String, Map<String, dynamic>> configs) async {
    debugPrint('🚀 开始初始化支付提供者，配置数量: ${configs.length}');

    for (final entry in configs.entries) {
      final methodName = entry.key;
      final config = entry.value;

      debugPrint('🔧 正在初始化支付提供者: $methodName');

      final method = PayProviderExtension.fromCode(methodName);
      final provider = method != null ? _providers[method] : null;

      if (provider != null) {
        try {
          final success = await provider.initialize(config);
          if (success) {
            debugPrint('✅ $methodName 支付初始化成功');
          } else {
            debugPrint('❌ $methodName 支付初始化失败，从可用列表中移除');
            if (method != null) {
              unregister(method);
            }
          }
        } catch (e) {
          debugPrint('💥 $methodName 支付初始化异常: $e，从可用列表中移除');
          if (method != null) {
            unregister(method);
          }
        }
      } else {
        debugPrint('⚠️ 未找到已注册的支付提供者: $methodName');
      }
    }

    debugPrint('🎯 支付提供者初始化完成，当前可用数量: ${_providers.length}');
  }

  /// 加载配置（优先远程，失败用本地）
  Future<Map<String, Map<String, dynamic>>> _loadConfigs() async {
    // try {
    //   final remoteConfig = await _loadRemoteConfig();
    //   if (remoteConfig.isNotEmpty) {
    //     debugPrint('✅ 使用远程支付配置');
    //     return remoteConfig;
    //   }
    // } catch (e) {
    //   debugPrint('⚠️ 远程配置加载失败: $e');
    // }

    debugPrint('📋 使用默认配置');
    return _getDefaultConfigs();
  }

  /// 获取默认配置
  Map<String, Map<String, dynamic>> _getDefaultConfigs() {
    return {
      'apple_pay': {
        'verifyPurchase': !GchNucleus.isDevMode,
        'timeout': 30000,
        'retryAttempts': 3,
        'autoFinishTransactions': true,
      },
    };
  }

  /// 重新加载配置
  Future<bool> reload() async {
    try {
      debugPrint('🔄 开始重新加载支付配置...');

      // 清理现有提供者
      for (final provider in _providers.values) {
        (provider as Disposable).dispose();
      }
      _providers.clear();
      _initialized = false;

      // 重新注册和初始化
      await registerFromDatabase();
      await initializeAll();

      debugPrint('✅ 支付配置重新加载完成');
      return true;
    } catch (e) {
      debugPrint('❌ 重新加载支付配置失败: $e');
      return false;
    }
  }

  @override
  void dispose() {
    for (final provider in _providers.values) {
      (provider as Disposable).dispose();
    }
    _providers.clear();
    _initialized = false;
    debugPrint('✅ ProviderRegistry已销毁');
  }
}
