import 'dart:async';

import 'package:guichao/gch_base/gch_ink/gch_ink.dart';
import 'package:guichao/gch_base/gch_biz/gch_wire/gch_appprovider.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 启动过程扩展类
/// 
/// 此类包含对应用启动过程的扩展，用于添加自动订阅服务
class BootstrapExtension with GchAppLogger {
  /// 初始化自动订阅服务
  /// 
  /// 在 bootstrap.dart 文件中的 gchVpnConfRepo 初始化之后调用
  /// 使用异步初始化避免阻塞UI
  // static Future<void> initializeAutoSubscription() async {
  //   final stopWatch = Stopwatch()..start();
  //   GchInk.boot.info("初始化自动订阅服务");
  //
  //   try {
  //     // 异步初始化自动订阅服务，不等待网络请求完成
  //     unawaited(_initializeAutoSubscriptionAsync());
  //
  //     GchInk.boot.info("自动订阅服务初始化调度完成 [${stopWatch.elapsedMilliseconds}ms]");
  //   } catch (e, stackTrace) {
  //     GchInk.boot.error("自动订阅服务初始化调度失败", e, stackTrace);
  //   } finally {
  //     stopWatch.stop();
  //   }
  // }

  /// 初始化支付系统
  static Future<void> initPayment() async {
    final stopWatch = Stopwatch()..start();
    GchInk.boot.info("初始化支付系统");
    
    try {
      // 异步初始化支付系统，不等待完成
      unawaited(_initPaymentAsync());
      
      GchInk.boot.info("支付系统初始化调度完成 [${stopWatch.elapsedMilliseconds}ms]");
    } catch (e, stackTrace) {
      GchInk.boot.error("支付系统初始化调度失败", e, stackTrace);
    } finally {
      stopWatch.stop();
    }
  }

  /// 异步初始化支付系统
  static Future<void> _initPaymentAsync() async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 5);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        GchInk.boot.info("开始后台初始化支付系统 (尝试 $attempt/$maxRetries)");
        
        // 等待UI完全加载后再执行
        await Future.delayed(const Duration(seconds: 1));
        
        // 初始化支付系统
        await _initWithHandler();
        
        GchInk.boot.info("后台支付系统初始化完成");
        return; // 成功则退出重试循环
      } catch (e, stackTrace) {
        GchInk.boot.error("后台支付系统初始化第$attempt次失败", e, stackTrace);
        
        if (attempt < maxRetries) {
          GchInk.boot.warning("${retryDelay.inSeconds}秒后进行第${attempt + 1}次重试");
          await Future.delayed(retryDelay);
        } else {
          GchInk.boot.error("支付系统初始化最终失败，已达到最大重试次数");
        }
      }
    }
  }

  /// 使用PaymentManager的bootstrap功能
  static Future<void> _initWithHandler() async {
    try {
      if (_container == null) {
        throw Exception("容器未设置，无法初始化支付系统");
      }
      
      final paymentManager = _container!.read(AppProvider.payment.manager);
      final result = await paymentManager.bootstrap();
      
      if (!result) {
        throw Exception("PaymentManager.bootstrap() 返回 false");
      }
      
      GchInk.boot.info("PaymentManager bootstrap成功");
    } catch (e) {
      GchInk.boot.error("PaymentManager bootstrap失败: $e");
      rethrow;
    }
  }

  /// 全局容器引用
  static ProviderContainer? _container;
  
  /// 设置容器引用
  static void setContainer(ProviderContainer container) {
    _container = container;
  }

  /// 异步初始化自动订阅服务
  /// 
  /// 此方法在后台执行，不会阻塞应用启动
  // static Future<void> _initializeAutoSubscriptionAsync() async {
  //   try {
  //     GchInk.boot.info("开始后台初始化自动订阅服务");
  //
  //     // 等待UI完全加载后再执行网络请求
  //     await Future.delayed(const Duration(seconds: 2));
  //
  //     // TODO: 初始化自动订阅服务
  //     // 暂时注释掉，等待订阅系统完全实现后启用
  //     // final subscriptionService = subscriptionService();
  //     // if (subscriptionService != null) {
  //     //   await subscriptionService.initialize();
  //     // }
  //
  //     GchInk.boot.info("后台自动订阅服务初始化完成（暂时跳过）");
  //   } catch (e, stackTrace) {
  //     GchInk.boot.error("后台自动订阅服务初始化失败", e, stackTrace);
  //   }
  // }
  //

}


