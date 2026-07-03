import 'package:flutter/material.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_biz/gch_channel/gch_model/gch_payprovider_model.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';

/// 支付相关的工具类 - 处理业务逻辑
class PaymentUtils {
  /// 根据支付提供者获取图标
  static Widget getPaymentIcon(PayProviderEntry provider) {
    final payMethod = PayMethod.fromValue(provider.method);
    
    switch (payMethod) {
      case PayMethod.appStore:
        return Icon(
          Icons.apple,
          color: Colors.white,
          size: 28.ri,
        );
      default:
        return Icon(
          Icons.payment,
          color: Colors.white,
          size: 28.ri,
        );
    }
  }
  
  /// 获取支付提供者显示名称
  static String getPaymentDisplayName(PayProviderEntry provider) {
    return provider.name;
  }
  
  /// 检查支付提供者是否可用
  static bool isPaymentProviderAvailable(PayProviderEntry provider) {
    return provider.status == 1; // 1表示有效
  }
  
  /// 根据当前平台过滤支付提供者
  static List<PayProviderEntry> filterPaymentProvidersForCurrentPlatform(
    List<PayProviderEntry> providers,
    TargetPlatform platform,
  ) {
    return providers.where((provider) {
      if (!isPaymentProviderAvailable(provider)) return false;
      
      final method = PayMethod.fromValue(provider.method);
      final clientTypes = provider.clientTypes ?? '';
      
      switch (platform) {
        case TargetPlatform.iOS:
          return method == PayMethod.appStore ||
                 method == PayMethod.wap ||
                 method == PayMethod.h5 ||
                 clientTypes.contains('ios');
        default:
          return method == PayMethod.pc ||
                 method == PayMethod.h5 ||
                 clientTypes.contains('desktop');
      }
    }).toList();
  }
  
  /// 获取支付类型显示文本
  static String getPayTypeDisplayText(PayType payType) {
    switch (payType) {
      case PayType.online:
        return '在线支付';
      case PayType.cardKey:
        return '卡密兑换';
      case PayType.inAppPurchase:
        return '应用内购买';
    }
  }
  
  /// 获取支付方式显示文本
  static String getPayMethodDisplayText(PayMethod method) {
    switch (method) {
      case PayMethod.pc:
        return 'PC端支付';
      case PayMethod.wap:
        return 'WAP支付';
      case PayMethod.h5:
        return 'H5支付';
      case PayMethod.appStore:
        return 'App Store';
    }
  }
  
  /// 检查支付提供者是否支持当前地区
  static bool isPaymentProviderAvailableInRegion(
    PayProviderEntry provider,
    String region,
  ) {
    if (provider.regions == null || provider.regions!.isEmpty) {
      return true; // 没有限制地区，默认支持
    }
    
    final supportedRegions = provider.regions!.split(',');
    return supportedRegions.contains(region) || supportedRegions.contains('*');
  }
  
  /// 获取推荐的支付提供者（按优先级排序）
  static List<PayProviderEntry> getRecommendedPaymentProviders(
    List<PayProviderEntry> providers,
    TargetPlatform platform,
  ) {
    final availableProviders = filterPaymentProvidersForCurrentPlatform(providers, platform);
    
    // 按优先级排序
    availableProviders.sort((a, b) {
      // 应用内购买优先
      final aMethod = PayMethod.fromValue(a.method);
      final bMethod = PayMethod.fromValue(b.method);
      
      if (aMethod == PayMethod.appStore) {
        return -1;
      }
      if (bMethod == PayMethod.appStore) {
        return 1;
      }
      
      // 其他按名称排序
      return a.name.compareTo(b.name);
    });
    
    return availableProviders;
  }
}