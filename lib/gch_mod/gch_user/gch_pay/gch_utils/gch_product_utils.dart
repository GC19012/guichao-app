import 'package:flutter/material.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';

enum ProductBadgeType { trial, hot, discount, recommend, value }

/// 产品相关的工具类 - 处理业务逻辑
class ProductUtils {
  /// 根据 duration 生成标签类型
  static ProductBadgeType? getTagByDuration(int? duration) {
    if (duration == null) return null;
    if (duration <= 7) return ProductBadgeType.trial;
    if (duration <= 30) return ProductBadgeType.hot;
    if (duration <= 90) return ProductBadgeType.discount;
    if (duration <= 180) return ProductBadgeType.recommend;
    return ProductBadgeType.value;
  }

  /// 获取标签对应的颜色
  static Color getTagColor(ProductBadgeType? tag) {
    switch (tag) {
      case ProductBadgeType.hot:
        return const Color(0xFFFF6B6B);
      case ProductBadgeType.discount:
        return const Color(0xFF4ECDC4);
      case ProductBadgeType.value:
        return const Color(0xFFFFE66D);
      case ProductBadgeType.recommend:
        return const Color(0xFF4A6CF7);
      case ProductBadgeType.trial:
        return const Color(0xFF95E1D3);
      case null:
        return Colors.grey;
    }
  }

  /// 获取标签对应的展示文案
  static String? getTagLabel(ProductBadgeType? tag) {
    switch (tag) {
      case ProductBadgeType.trial:   return '试用';
      case ProductBadgeType.hot:     return '热门';
      case ProductBadgeType.discount: return '优惠';
      case ProductBadgeType.recommend: return '推荐';
      case ProductBadgeType.value:   return '超值';
      case null: return null;
    }
  }

  /// 格式化价格显示
  static String formatPrice(ProductEntry product) {
    return '${product.currency} ${product.price.toStringAsFixed(1)}';
  }

  /// 判断产品是否为推荐产品
  static bool isRecommended(ProductEntry product) {
    final tag = getTagByDuration(product.duration);
    return tag == ProductBadgeType.recommend ||
        tag == ProductBadgeType.value ||
        tag == ProductBadgeType.hot;
  }

  /// 计算产品优惠信息
  static String? getDiscountInfo(ProductEntry product) {
    if (product.duration == null) return null;
    if (product.duration! >= 365) return '年付享8折优惠';
    if (product.duration! >= 90) return '季付享9折优惠';
    return null;
  }
}
