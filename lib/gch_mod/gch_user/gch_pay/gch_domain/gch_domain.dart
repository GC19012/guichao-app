/// 支付领域层导出
///
/// 包含：
/// - 实体定义（PaymentFlowState, CheckoutUIEvent, ProductInfo）
/// - 策略接口和实现（PaymentStrategy, 各支付方式策略）
/// - 策略工厂（PaymentStrategyFactory）
library;

// 实体
export 'gch_entity/gch_payment_flow_state.dart';
export 'gch_entity/gch_checkout_ui_event.dart';

// 策略
export 'gch_strategy/gch_payment_strategy.dart';
export 'gch_strategy/gch_payment_strategy_factory.dart';
export 'gch_strategy/gch_strategies/gch_strategies.dart';
