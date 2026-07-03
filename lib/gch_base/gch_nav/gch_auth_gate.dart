import 'package:guichao/gch_base/gch_biz/gch_auth/gch_model/gch_authuser_model.dart';
import 'dart:async';
import 'package:guichao/gch_base/gch_biz/gch_common/gch_enums.dart';

/// VipType 扩展方法 - 用于权限检查
extension VipTypePermission on VipType {
  /// 检查是否可以访问指定等级的功能
  bool canAccess(VipType required) => value >= required.value;
}

/// 权限检查结果
sealed class GchAuthResult {
  const GchAuthResult();

  T when<T>({
    required T Function() allowed,
    required T Function(String reason, String redirect) denied,
  }) {
    return switch (this) {
      GchAllowed() => allowed(),
      GchDenied(:final reason, :final redirect) => denied(reason, redirect),
    };
  }
}

class GchAllowed extends GchAuthResult {
  const GchAllowed();
}

class GchDenied extends GchAuthResult {
  const GchDenied(this.reason, this.redirect);
  final String reason;
  final String redirect;
}

/// 权限检查器接口
abstract class PermissionChecker {
  FutureOr<GchAuthResult?> check(String path, AuthUser? user, Map<String, dynamic> context);
}

/// 登录状态检查器
class AuthRequiredChecker implements PermissionChecker {
  const AuthRequiredChecker();

  @override
  GchAuthResult? check(String path, AuthUser? user, Map<String, dynamic> context) {
    if (user == null) {
      // 使用 /nav/login 确保有完整的 Shell 上下文
      return const GchDenied('auth_required', '/nav/login');
    }
    return null; // 继续下一个检查
  }
}

/// 用户等级检查器
class LevelChecker implements PermissionChecker {
  const LevelChecker(this.requiredLevel, [this.fallback = '/checkout']);

  final VipType requiredLevel;
  final String fallback;

  @override
  GchAuthResult? check(String path, AuthUser? user, Map<String, dynamic> context) {
    if (user == null) return null;

    final userLevel = user.currentVip;
    if (!userLevel.canAccess(requiredLevel)) {
      return GchDenied('insufficient_level', fallback);
    }
    return null;
  }
}

/// 功能权限检查器
class FeatureChecker implements PermissionChecker {
  const FeatureChecker(this.features, [this.fallback = '/checkout']);

  final Set<String> features;
  final String fallback;

  static const _featureRequirements = <String, VipType>{
    'vpn': VipType.free,
    'profiles': VipType.free,
    'advanced': VipType.basic,
    'logs': VipType.premium,
    'per_app': VipType.premium,
  };

  @override
  GchAuthResult? check(String path, AuthUser? user, Map<String, dynamic> context) {
    if (user == null || features.isEmpty) return null;

    final userLevel = user.currentVip;
    for (final feature in features) {
      final requiredLevel = _featureRequirements[feature] ?? VipType.premium;
      if (!userLevel.canAccess(requiredLevel)) {
        return GchDenied('feature_unavailable', fallback);
      }
    }
    return null;
  }
}

/// 自定义条件检查器
class CustomChecker implements PermissionChecker {
  const CustomChecker(this.condition, this.fallback);

  final bool Function(AuthUser? user, Map<String, dynamic> context) condition;
  final String fallback;

  @override
  GchAuthResult? check(String path, AuthUser? user, Map<String, dynamic> context) {
    if (!condition(user, context)) {
      return GchDenied('custom_condition_failed', fallback);
    }
    return null;
  }
}

/// 路由配置
class RouteConfig {
  const RouteConfig({
    this.isPublic = false,
    this.checkers = const [],
  });

  final bool isPublic;
  final List<PermissionChecker> checkers;

  /// 便捷构造器 - 基础认证路由
  const RouteConfig.authenticated({
    VipType minLevel = VipType.free,
    Set<String> features = const {},
    String fallback = '/checkout',
  })  : isPublic = false,
        checkers = const [
          AuthRequiredChecker(),
          // 动态添加的 checkers 需要在运行时处理
        ];

  /// 便捷构造器 - 公开路由
  const RouteConfig.public()
      : isPublic = true,
        checkers = const [];
}

/// 路由匹配器接口
abstract class RouteMatcher {
  RouteConfig? match(String path);
}

/// 精确匹配器
class ExactMatcher implements RouteMatcher {
  const ExactMatcher(this.routes);
  final Map<String, RouteConfig> routes;

  @override
  RouteConfig? match(String path) => routes[path];
}

/// 模式匹配器 (支持通配符和参数)
class PatternMatcher implements RouteMatcher {
  const PatternMatcher(this.patterns);
  final Map<RegExp, RouteConfig> patterns;

  @override
  RouteConfig? match(String path) {
    for (final entry in patterns.entries) {
      if (entry.key.hasMatch(path)) {
        return entry.value;
      }
    }
    return null;
  }
}

/// 组合匹配器
class CompositeRouteMatcher implements RouteMatcher {
  const CompositeRouteMatcher(this.matchers);
  final List<RouteMatcher> matchers;

  @override
  RouteConfig? match(String path) {
    for (final matcher in matchers) {
      final config = matcher.match(path);
      if (config != null) return config;
    }
    return null;
  }
}

/// 优化后的认证守卫
class GchAuthGuard {
  GchAuthGuard._({
    required RouteMatcher routeMatcher,
    RouteConfig? defaultConfig,
  })  : _routeMatcher = routeMatcher,
        _defaultConfig = defaultConfig ?? const RouteConfig();

  final RouteMatcher _routeMatcher;
  final RouteConfig _defaultConfig;

  // 缓存最近的路由配置查询结果
  final _routeCache = <String, RouteConfig>{};
  static const _maxCacheSize = 50;

  /// 创建默认实例
  static final GchAuthGuard instance = GchAuthGuard._create();

  /// 工厂方法创建默认配置
  static GchAuthGuard _create() {
    // 公开路由
    const publicRoutes = {
      '/intro': RouteConfig.public(),
      '/login': RouteConfig.public(),
      '/register': RouteConfig.public(),
      '/usermode': RouteConfig.public(),
      '/about': RouteConfig.public(),
      '/orders': RouteConfig.public(), // 订单列表无需验证（独立路由）
      '/user/about-us': RouteConfig.public(), // 关于我们（独立路由）
      '/nav/setting/about-us': RouteConfig.public(), // 关于我们（shell 嵌套路由，未登录可直接访问）
      '/pprof-debug': RouteConfig.public(), // Pprof 性能调试（Debug 模式）
    };

    // 需要认证的路由
    final authenticatedRoutes = {
      '/': RouteConfig(
        checkers: [AuthRequiredChecker()],
      ),
      '/mainhome': RouteConfig(
        checkers: [AuthRequiredChecker()],
      ),
      '/user/password-change': RouteConfig(
        checkers: [AuthRequiredChecker()],
      ),
      '/user/setting': RouteConfig(
        checkers: [AuthRequiredChecker()],
      ),
      '/user/delete-account': RouteConfig(
        checkers: [AuthRequiredChecker()],
      ),
      '/proxies': RouteConfig(
        checkers: [
          AuthRequiredChecker(),
          FeatureChecker({'vpn'}),
        ],
      ),
      '/settings': RouteConfig(
        checkers: [AuthRequiredChecker()],
      ),
      '/profile': RouteConfig(
        checkers: [AuthRequiredChecker()],
      ),
      '/profiles': RouteConfig(
        checkers: [
          AuthRequiredChecker(),
          FeatureChecker({'profiles'}),
        ],
      ),
      '/add-profile': RouteConfig(
        checkers: [
          AuthRequiredChecker(),
          FeatureChecker({'profiles'}),
        ],
      ),
      '/config-options': RouteConfig(
        checkers: [
          AuthRequiredChecker(),
          LevelChecker(VipType.basic),
          FeatureChecker({'advanced'}),
        ],
      ),
      '/logs': RouteConfig(
        checkers: [
          AuthRequiredChecker(),
          LevelChecker(VipType.premium),
          FeatureChecker({'logs'}),
        ],
      ),
      '/app_proxy': RouteConfig(
        checkers: [
          AuthRequiredChecker(),
        ],
      ),
    };

    // 动态路由模式
    final patterns = {
      RegExp(r'^/profiles/[\w-]+$'): RouteConfig(
        checkers: [
          AuthRequiredChecker(),
          FeatureChecker({'profiles'}),
        ],
      ),
      // Shell 路由下的公开页面
      RegExp(r'^/nav/setting/orders$'): const RouteConfig.public(),
      RegExp(r'^/nav/setting/about-us$'): const RouteConfig.public(),
    };

    // 组合所有匹配器
    final matcher = CompositeRouteMatcher([
      ExactMatcher({...publicRoutes, ...authenticatedRoutes}),
      PatternMatcher(patterns),
    ]);

    return GchAuthGuard._(
      routeMatcher: matcher,
      defaultConfig: const RouteConfig(
        checkers: [AuthRequiredChecker()],
      ),
    );
  }

  /// 自定义配置创建
  factory GchAuthGuard.custom({
    required RouteMatcher routeMatcher,
    RouteConfig? defaultConfig,
  }) {
    return GchAuthGuard._(
      routeMatcher: routeMatcher,
      defaultConfig: defaultConfig,
    );
  }

  /// 检查路由是否公开
  bool isPublicRoute(String path) {
    return _getRouteConfig(path).isPublic;
  }

  /// 检查访问权限
  Future<GchAuthResult> canAccess(
    String path,
    AuthUser? user, [
    Map<String, dynamic>? context,
  ]) async {
    final config = _getRouteConfig(path);

    // 公开路由直接允许
    if (config.isPublic) {
      return const GchAllowed();
    }

    // 执行所有检查器
    final ctx = context ?? {};
    for (final checker in config.checkers) {
      final result = await checker.check(path, user, ctx);
      if (result != null && result is GchDenied) {
        return result;
      }
    }

    return const GchAllowed();
  }

  /// 获取路由配置（带缓存）
  RouteConfig _getRouteConfig(String path) {
    // 检查缓存
    if (_routeCache.containsKey(path)) {
      return _routeCache[path]!;
    }

    // 查找配置
    final config = _routeMatcher.match(path) ?? _defaultConfig;

    // 更新缓存（LRU策略）
    if (_routeCache.length >= _maxCacheSize) {
      _routeCache.remove(_routeCache.keys.first);
    }
    _routeCache[path] = config;

    return config;
  }

  /// 清除缓存
  void clearCache() {
    _routeCache.clear();
  }
}

/// 扩展示例：实名认证检查器
class RealNameChecker implements PermissionChecker {
  const RealNameChecker();

  @override
  Future<GchAuthResult?> check(String path, AuthUser? user, Map<String, dynamic> context) async {
    if (user == null) return null;

    // 假设 AuthUser 有 isRealNameVerified 属性
    // if (!user.isRealNameVerified) {
    //   return const GchDenied('real_name_required', '/verify');
    // }

    return null;
  }
}

/// 扩展示例：设备限制检查器
class DeviceLimitChecker implements PermissionChecker {
  const DeviceLimitChecker(this.maxDevices);
  final int maxDevices;

  @override
  Future<GchAuthResult?> check(String path, AuthUser? user, Map<String, dynamic> context) async {
    if (user == null) return null;

    // 从 context 或其他地方获取设备数量
    final deviceCount = context['deviceCount'] as int? ?? 0;
    if (deviceCount >= maxDevices) {
      return const GchDenied('device_limit_exceeded', '/upgrade');
    }

    return null;
  }
}
