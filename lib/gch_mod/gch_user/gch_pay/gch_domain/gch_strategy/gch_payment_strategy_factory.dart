import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_interface.dart';
import 'package:guichao/gch_base/gch_biz/gch_pay/gch_svc/gch_payment_manager.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_strategy/gch_payment_strategy.dart';
import 'package:guichao/gch_mod/gch_user/gch_pay/gch_domain/gch_strategy/gch_strategies/gch_in_app_purchase_strategy.dart';

/// 支付策略工厂
///
/// 职责：根据 PayProvider 创建对应的 Strategy 实例
///
/// 与 ProviderRegistry 的区别：
/// - ProviderRegistry：管理底层 Provider（SDK封装），返回 IResponse
/// - PaymentStrategyFactory：管理 Strategy（业务流程编排），返回 PaymentFlowState
///
/// Strategy 包装 Provider，添加：
/// 1. 统一的状态模型（PaymentFlowState）
/// 2. 各支付方式特有错误码转换
/// 3. 业务层可用性语义
class PaymentStrategyFactory {
  final PaymentManager _paymentManager;

  /// 策略缓存
  final Map<PayProvider, PaymentStrategy> _cache = {};

  PaymentStrategyFactory(this._paymentManager);

  /// 获取指定支付方式的策略
  PaymentStrategy? getStrategy(PayProvider method) {
    if (_cache.containsKey(method)) {
      return _cache[method];
    }

    final strategy = _createStrategy(method);
    if (strategy != null) {
      _cache[method] = strategy;
    }
    return strategy;
  }

  /// 根据 code 获取策略
  PaymentStrategy? getStrategyByCode(String code) {
    final method = PayProviderExtension.fromCode(code);
    return method != null ? getStrategy(method) : null;
  }

  /// 获取所有可用的策略
  Future<List<PaymentStrategy>> getAvailableStrategies() async {
    final strategies = <PaymentStrategy>[];

    for (final method in PayProvider.values) {
      final strategy = getStrategy(method);
      if (strategy != null) {
        final availability = await strategy.checkAvailability();
        if (availability.isAvailable) {
          strategies.add(strategy);
        }
      }
    }

    return strategies;
  }

  /// 创建策略实例
  PaymentStrategy? _createStrategy(PayProvider method) {
    switch (method) {
      case PayProvider.inAppPurchase:
        return InAppPurchaseStrategy(_paymentManager);
    }
  }

  /// 清除缓存
  void clearCache() => _cache.clear();
}
