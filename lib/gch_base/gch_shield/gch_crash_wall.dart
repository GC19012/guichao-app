
import 'dart:async';
import 'dart:math' show cos, sin;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_aux/gch_crash_report/gch_reporter.dart';

/// 错误严重程度 - 简化为3级
enum GchSeverity {
  /// 静默处理：网络、资源加载、超时等
  silent,
  /// 局部处理：Widget构建错误等
  local,
  /// 全局处理：崩溃、内存溢出、路由错误等
  critical,
}

/// 轻量级错误信息
class GchCrashInfo {
  final Object error;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final GchSeverity severity;

  GchCrashInfo({
    required this.error,
    this.stackTrace,
    DateTime? timestamp,
  })  : timestamp = timestamp ?? DateTime.now(),
        severity = _evaluateSeverity(error);

  /// 快速评估错误严重程度
  static GchSeverity _evaluateSeverity(Object error) {
    final errorStr = error.toString().toLowerCase();

    // 严重错误特征 - 需要显示错误界面
    if (errorStr.contains('sigsegv') ||
        errorStr.contains('sigabrt') ||
        errorStr.contains('signal') ||
        errorStr.contains('outofmemory') ||
        errorStr.contains('currentconfiguration.isnotempty') ||
        errorStr.contains('pages left to show') ||
        errorStr.contains('popped the last page') ||
        (errorStr.contains('router') && errorStr.contains('null'))) {
      return GchSeverity.critical;
    }

    // 局部错误 - Widget构建失败
    if (error is FlutterError ||
        errorStr.contains('renderflex') ||
        errorStr.contains('widget')) {
      return GchSeverity.local;
    }

    // 其他都静默处理
    return GchSeverity.silent;
  }

  String get userMessage {
    switch (severity) {
      case GchSeverity.critical:
        return '应用需要重新启动';
      case GchSeverity.local:
        return '页面加载失败';
      case GchSeverity.silent:
        return '';
    }
  }
}

/// 极简崩溃边界
class GchCrashWall extends StatefulWidget {
  final Widget child;
  final Function(GchCrashInfo)? onError;
  final bool enableDebugInfo;

  const GchCrashWall({
    super.key,
    required this.child,
    this.onError,
    this.enableDebugInfo = false, // 生产环境默认关闭
  });

  @override
  State<GchCrashWall> createState() => _GchCrashWallState();
}

class _GchCrashWallState extends State<GchCrashWall> {
  GchCrashInfo? _criticalError;
  Timer? _autoRecoveryTimer;

  // 防抖：避免短时间内多次显示错误
  DateTime? _lastErrorTime;
  static const _errorDebounceMs = 1000;

  @override
  void initState() {
    super.initState();
    _setupErrorHandling();
  }

  void _setupErrorHandling() {
    // Flutter错误处理
    FlutterError.onError = (details) {
      if (!mounted) return;

      final errorInfo = GchCrashInfo(
        error: details.exception,
        stackTrace: details.stack,
      );

      _handleError(errorInfo);
    };

    // Platform错误处理
    PlatformDispatcher.instance.onError = (error, stack) {
      if (!mounted) return true;

      final errorInfo = GchCrashInfo(
        error: error,
        stackTrace: stack,
      );

      _handleError(errorInfo);
      return true;
    };
  }

  void _handleError(GchCrashInfo errorInfo) {
    // 防抖检查
    final now = DateTime.now();
    if (_lastErrorTime != null &&
        now.difference(_lastErrorTime!).inMilliseconds < _errorDebounceMs) {
      return;
    }
    _lastErrorTime = now;

    // 上报到错误监控平台
    if (ErrorReporterFactory.hasReporter) {
      ErrorReporterFactory.instance!.recordError(
        errorInfo.error,
        errorInfo.stackTrace,
      );
    }

    // 通知回调
    widget.onError?.call(errorInfo);

    // 根据严重程度处理
    switch (errorInfo.severity) {
      case GchSeverity.silent:
      // 静默处理，不影响用户
        if (widget.enableDebugInfo) {
          debugPrint('📝 Silent error: ${errorInfo.error}');
        }
        break;

      case GchSeverity.local:
      // 局部处理，Widget级别错误已由ErrorWidget处理
        if (widget.enableDebugInfo) {
          debugPrint('⚠️ Local error: ${errorInfo.error}');
        }
        break;

      case GchSeverity.critical:
      // 严重错误，显示错误界面
        if (widget.enableDebugInfo) {
          debugPrint('🔴 Critical error: ${errorInfo.error}');
        }
        _showCriticalError(errorInfo);
        break;
    }
  }

  void _showCriticalError(GchCrashInfo errorInfo) {
    if (!mounted) return;

    setState(() {
      _criticalError = errorInfo;
    });

    // 3秒后自动尝试恢复
    _autoRecoveryTimer?.cancel();
    _autoRecoveryTimer = Timer(const Duration(seconds: 3), _recover);
  }

  void _recover() {
    if (!mounted) return;

    setState(() {
      _criticalError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 显示严重错误界面
    if (_criticalError != null) {
      return _buildErrorScreen(_criticalError!);
    }

    // 设置Widget错误构建器
    ErrorWidget.builder = (details) => _buildLocalErrorWidget(details);

    return widget.child;
  }

  /// 严重错误界面 - 全面自适应高科技设计
  Widget _buildErrorScreen(GchCrashInfo errorInfo) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B1426), // 深蓝黑
                Color(0xFF1A237E), // 深蓝紫
                Color(0xFF0D47A1), // 深蓝
                Color(0xFF01579B), // 暗蓝
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final responsiveHelper = _ResponsiveHelper(constraints);
                  
                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsiveHelper.horizontalPadding,
                        vertical: responsiveHelper.verticalPadding,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - (responsiveHelper.verticalPadding * 2),
                          maxWidth: responsiveHelper.maxContentWidth,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                    // 高科技错误图标 - 自适应
                    TweenAnimationBuilder(
                      duration: const Duration(seconds: 2),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Container(
                          padding: EdgeInsets.all(responsiveHelper.iconPadding),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.cyan.withOpacity(0.2 * value),
                                Colors.blue.withOpacity(0.1 * value),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.3 * value),
                                blurRadius: responsiveHelper.glowRadius,
                                spreadRadius: responsiveHelper.glowSpread,
                              ),
                            ],
                          ),
                          child: Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Icon(
                              Icons.warning_rounded,
                              size: responsiveHelper.iconSize,
                              color: Colors.cyan.withOpacity(0.9),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: responsiveHelper.sectionSpacing),

                    // 主标题 - 自适应科技感字体
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 1500),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Text(
                              '系统异常',
                              style: TextStyle(
                                fontSize: responsiveHelper.titleFontSize,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: responsiveHelper.titleLetterSpacing,
                                shadows: [
                                  Shadow(
                                    color: Colors.cyan,
                                    blurRadius: responsiveHelper.textShadowBlur,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: responsiveHelper.itemSpacing),

                    // 副标题 - 自适应
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 2000),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsiveHelper.subtitlePadding,
                              vertical: responsiveHelper.subtitlePadding * 0.4,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: responsiveHelper.subtitleMaxWidth,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.cyan.withOpacity(0.3),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.black.withOpacity(0.2),
                            ),
                            child: Text(
                              '正在执行自动恢复程序...',
                              style: TextStyle(
                                fontSize: responsiveHelper.subtitleFontSize,
                                color: Colors.cyan.withOpacity(0.8),
                                fontWeight: FontWeight.w400,
                                letterSpacing: responsiveHelper.subtitleLetterSpacing,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: responsiveHelper.sectionSpacing),

                    // 进度指示器 - 自适应
                    TweenAnimationBuilder(
                      duration: const Duration(seconds: 3),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Column(
                          children: [
                            Container(
                              width: responsiveHelper.progressBarWidth,
                              height: responsiveHelper.progressBarHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(responsiveHelper.progressBarHeight / 2),
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(responsiveHelper.progressBarHeight / 2),
                                    gradient: const LinearGradient(
                                      colors: [Colors.cyan, Colors.blue],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyan.withOpacity(0.5),
                                        blurRadius: responsiveHelper.progressGlowBlur,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: responsiveHelper.progressTextSpacing),
                            Text(
                              '${(value * 100).toInt()}%',
                              style: TextStyle(
                                color: Colors.cyan.withOpacity(0.7),
                                fontSize: responsiveHelper.progressTextSize,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: responsiveHelper.sectionSpacing),

                    // 操作按钮组 - 全面自适应布局
                    _buildResponsiveButtons(responsiveHelper),

                    // Debug信息 - 全面自适应设计
                    if (widget.enableDebugInfo && GchNucleus.isDevMode) ...[
                      SizedBox(height: responsiveHelper.sectionSpacing),
                      _buildResponsiveDebugInfo(responsiveHelper, errorInfo),
                    ],
                  ],
                ),
              ),
            ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建响应式按钮组
  Widget _buildResponsiveButtons(_ResponsiveHelper helper) {
    if (helper.isMobile) {
      // 移动端：垂直排列，全宽按钮
      return Column(
        children: [
          _buildTechButton(
            helper: helper,
            label: '立即重试',
            onPressed: _recover,
            isPrimary: true,
            fullWidth: true,
          ),
          SizedBox(height: helper.buttonSpacing),
          _buildTechButton(
            helper: helper,
            label: '退出应用',
            onPressed: () {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            },
            isPrimary: false,
            fullWidth: true,
          ),
        ],
      );
    } else {
      // 平板/桌面：水平排列
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTechButton(
            helper: helper,
            label: '立即重试',
            onPressed: _recover,
            isPrimary: true,
          ),
          SizedBox(width: helper.buttonSpacing * 1.5),
          _buildTechButton(
            helper: helper,
            label: '退出应用',
            onPressed: () {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            },
            isPrimary: false,
          ),
        ],
      );
    }
  }

  /// 构建高科技风格按钮 - 全面自适应
  Widget _buildTechButton({
    required _ResponsiveHelper helper,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    bool fullWidth = false,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 2500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Container(
              width: fullWidth ? double.infinity : null,
              constraints: BoxConstraints(
                minWidth: helper.buttonMinWidth,
                minHeight: helper.buttonHeight,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(helper.buttonHeight / 2),
                gradient: isPrimary
                    ? const LinearGradient(
                        colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                      )
                    : null,
                border: isPrimary
                    ? null
                    : Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.4),
                          blurRadius: helper.isMobile ? 12 : 15,
                          offset: Offset(0, helper.isMobile ? 3 : 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(helper.buttonHeight / 2),
                  onTap: onPressed,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: helper.isMobile ? 20 : 24,
                      vertical: helper.isMobile ? 12 : 16,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isPrimary
                            ? Colors.white
                            : Colors.white.withOpacity(0.8),
                        fontSize: helper.buttonFontSize,
                        fontWeight: FontWeight.w500,
                        letterSpacing: helper.isMobile ? 0.8 : 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建响应式Debug信息区域
  Widget _buildResponsiveDebugInfo(_ResponsiveHelper helper, GchCrashInfo errorInfo) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: helper.isMobile ? 120 : 180,
        maxWidth: helper.maxContentWidth,
      ),
      padding: EdgeInsets.all(helper.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(helper.isMobile ? 8 : 12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with responsive sizing
          Row(
            children: [
              Icon(
                Icons.bug_report,
                size: helper.isMobile ? 12 : 16,
                color: Colors.red.withOpacity(0.7),
              ),
              SizedBox(width: helper.isMobile ? 6 : 8),
              Flexible(
                child: Text(
                  'DEBUG INFO',
                  style: TextStyle(
                    fontSize: helper.isMobile ? 8 : 10,
                    color: Colors.red.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    letterSpacing: helper.isMobile ? 0.5 : 1.0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: helper.isMobile ? 6 : 8),
          
          // Scrollable error content with responsive text
          Flexible(
            child: SingleChildScrollView(
              child: SelectableText(
                errorInfo.error.toString(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: helper.isSmallMobile ? 7 : (helper.isMobile ? 8 : 10),
                  color: Colors.red,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 局部Widget错误 - 内联显示
  Widget _buildLocalErrorWidget(FlutterErrorDetails details) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade100,
      child: const Center(
        child: Text(
          '加载失败',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoRecoveryTimer?.cancel();
    super.dispose();
  }
}

/// 高科技六边形网格背景绘制 - 全屏幕自适应
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 确保绘制区域覆盖整个画布
    if (size.width <= 0 || size.height <= 0) return;
    
    _drawHexagonalGrid(canvas, size);
    _drawCircuitLines(canvas, size);
    _drawGlowNodes(canvas, size);
  }

  /// 绘制六边形网格 - 优化超宽屏显示
  void _drawHexagonalGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.05)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // 根据屏幕宽度调整网格密度
    final hexSize = size.width > 1920 ? 50.0 : (size.width > 1200 ? 45.0 : 40.0);
    final hexWidth = hexSize * 1.73205; // sqrt(3)
    final hexHeight = hexSize * 1.5;

    // 扩展绘制范围确保覆盖所有可能的屏幕尺寸
    final startY = -hexHeight * 2;
    final endY = size.height + hexHeight * 2;
    final startX = -hexWidth * 2;
    final endX = size.width + hexWidth * 2;

    for (double y = startY; y <= endY; y += hexHeight) {
      for (double x = startX; x <= endX; x += hexWidth) {
        // 奇数行偏移
        final offsetX = (y / hexHeight % 2 == 0) ? x : x + hexWidth / 2;
        _drawHexagon(canvas, Offset(offsetX, y), hexSize * 0.7, paint);
      }
    }
  }

  /// 绘制单个六边形
  void _drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (3.14159 / 180);
      final x = center.dx + size * cos(angle);
      final y = center.dy + size * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// 绘制电路连接线 - 自适应超宽屏
  void _drawCircuitLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.08)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // 根据屏幕宽度调整线条间距
    final horizontalSpacing = size.width > 1920 ? 150.0 : (size.width > 1200 ? 130.0 : 120.0);
    final verticalSpacing = size.width > 1920 ? 160.0 : (size.width > 1200 ? 150.0 : 140.0);

    // 水平线条 - 确保覆盖整个宽度
    for (double y = 80; y < size.height; y += horizontalSpacing) {
      final path = Path();
      path.moveTo(-20, y); // 从屏幕外开始绘制
      path.lineTo(size.width * 0.3, y);
      path.lineTo(size.width * 0.4, y - 10);
      path.lineTo(size.width * 0.6, y - 10);
      path.lineTo(size.width * 0.7, y);
      path.lineTo(size.width + 20, y); // 延伸到屏幕外
      canvas.drawPath(path, paint);
    }

    // 垂直连接线 - 适应超宽屏幕
    for (double x = 100; x <= size.width + verticalSpacing; x += verticalSpacing) {
      final path = Path();
      path.moveTo(x, -20); // 从屏幕外开始
      path.lineTo(x, size.height * 0.25);
      path.lineTo(x + 15, size.height * 0.35);
      path.lineTo(x + 15, size.height * 0.65);
      path.lineTo(x, size.height * 0.75);
      path.lineTo(x, size.height + 20); // 延伸到屏幕外
      canvas.drawPath(path, paint);
    }
  }

  /// 绘制发光节点 - 适应超宽屏分布
  void _drawGlowNodes(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final corePaint = Paint()
      ..color = Colors.cyan.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // 根据屏幕比例动态分布发光节点
    final aspectRatio = size.width / size.height;
    List<Offset> nodes;

    if (aspectRatio > 2.0) {
      // 超宽屏：增加更多水平分布的节点
      nodes = [
        Offset(size.width * 0.1, size.height * 0.25),
        Offset(size.width * 0.3, size.height * 0.15),
        Offset(size.width * 0.5, size.height * 0.85),
        Offset(size.width * 0.7, size.height * 0.35),
        Offset(size.width * 0.9, size.height * 0.75),
        Offset(size.width * 0.2, size.height * 0.65),
        Offset(size.width * 0.8, size.height * 0.55),
      ];
    } else if (aspectRatio > 1.5) {
      // 宽屏：标准分布加额外节点
      nodes = [
        Offset(size.width * 0.15, size.height * 0.25),
        Offset(size.width * 0.85, size.height * 0.35),
        Offset(size.width * 0.25, size.height * 0.75),
        Offset(size.width * 0.75, size.height * 0.15),
        Offset(size.width * 0.65, size.height * 0.85),
        Offset(size.width * 0.5, size.height * 0.5),
      ];
    } else {
      // 标准屏幕：原始分布
      nodes = [
        Offset(size.width * 0.15, size.height * 0.25),
        Offset(size.width * 0.85, size.height * 0.35),
        Offset(size.width * 0.25, size.height * 0.75),
        Offset(size.width * 0.75, size.height * 0.15),
        Offset(size.width * 0.65, size.height * 0.85),
      ];
    }

    // 根据屏幕大小调整节点大小
    final nodeSize = size.width > 1920 ? 10.0 : (size.width > 1200 ? 9.0 : 8.0);
    final coreSize = nodeSize * 0.375; // 保持比例

    for (final node in nodes) {
      // 外层发光效果
      canvas.drawCircle(node, nodeSize, glowPaint);
      // 内核
      canvas.drawCircle(node, coreSize, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 响应式设计辅助类
class _ResponsiveHelper {
  final BoxConstraints constraints;
  
  _ResponsiveHelper(this.constraints);
  
  // 屏幕类型判断
  bool get isMobile => constraints.maxWidth < 480;
  bool get isTablet => constraints.maxWidth >= 480 && constraints.maxWidth < 1024;
  bool get isDesktop => constraints.maxWidth >= 1024;
  bool get isSmallMobile => constraints.maxWidth < 360;
  bool get isLandscape => constraints.maxWidth > constraints.maxHeight;
  
  // 基础间距
  double get horizontalPadding {
    if (isSmallMobile) return 12.0;
    if (isMobile) return 16.0;
    if (isTablet) return 24.0;
    return 32.0;
  }
  
  double get verticalPadding {
    if (isMobile) return 16.0;
    if (isTablet) return 24.0;
    return 32.0;
  }
  
  double get maxContentWidth {
    if (isMobile) return constraints.maxWidth;
    if (isTablet) return 600.0;
    // 对于超宽屏幕，内容宽度不应该无限增长
    if (constraints.maxWidth > 2560) return 1000.0; // 4K超宽屏
    if (constraints.maxWidth > 1920) return 900.0;  // 2K宽屏
    return 800.0; // 标准桌面
  }
  
  // 图标相关
  double get iconSize {
    if (isSmallMobile) return 40.0;
    if (isMobile) return 48.0;
    if (isTablet) return 56.0;
    return 64.0;
  }
  
  double get iconPadding {
    if (isSmallMobile) return 16.0;
    if (isMobile) return 20.0;
    if (isTablet) return 24.0;
    return 28.0;
  }
  
  double get glowRadius {
    if (isMobile) return 20.0;
    if (isTablet) return 25.0;
    return 30.0;
  }
  
  double get glowSpread {
    if (isMobile) return 3.0;
    if (isTablet) return 4.0;
    return 5.0;
  }
  
  // 字体大小
  double get titleFontSize {
    if (isSmallMobile) return 20.0;
    if (isMobile) return 24.0;
    if (isTablet) return 28.0;
    return 32.0;
  }
  
  double get subtitleFontSize {
    if (isSmallMobile) return 12.0;
    if (isMobile) return 13.0;
    if (isTablet) return 14.0;
    return 16.0;
  }
  
  double get progressTextSize {
    if (isSmallMobile) return 10.0;
    if (isMobile) return 11.0;
    if (isTablet) return 12.0;
    return 14.0;
  }
  
  // 间距
  double get sectionSpacing {
    if (isSmallMobile) return 24.0;
    if (isMobile) return 32.0;
    if (isTablet) return 40.0;
    return 48.0;
  }
  
  double get itemSpacing {
    if (isSmallMobile) return 12.0;
    if (isMobile) return 16.0;
    if (isTablet) return 20.0;
    return 24.0;
  }
  
  // 文字效果
  double get titleLetterSpacing {
    if (isMobile) return 1.5;
    if (isTablet) return 2.0;
    return 2.5;
  }
  
  double get subtitleLetterSpacing {
    if (isMobile) return 0.8;
    if (isTablet) return 1.0;
    return 1.2;
  }
  
  double get textShadowBlur {
    if (isMobile) return 8.0;
    if (isTablet) return 10.0;
    return 12.0;
  }
  
  // 副标题相关
  double get subtitlePadding {
    if (isSmallMobile) return 16.0;
    if (isMobile) return 18.0;
    if (isTablet) return 20.0;
    return 24.0;
  }
  
  double get subtitleMaxWidth {
    if (isMobile) return constraints.maxWidth * 0.9;
    if (isTablet) return 400.0;
    return 500.0;
  }
  
  // 进度条相关
  double get progressBarWidth {
    if (isSmallMobile) return constraints.maxWidth * 0.7;
    if (isMobile) return constraints.maxWidth * 0.6;
    if (isTablet) return 250.0;
    return 300.0;
  }
  
  double get progressBarHeight {
    if (isMobile) return 3.0;
    if (isTablet) return 4.0;
    return 5.0;
  }
  
  double get progressGlowBlur {
    if (isMobile) return 6.0;
    if (isTablet) return 8.0;
    return 10.0;
  }
  
  double get progressTextSpacing {
    if (isMobile) return 6.0;
    if (isTablet) return 8.0;
    return 10.0;
  }
  
  // 按钮相关
  double get buttonMinWidth {
    if (isMobile) return 120.0;
    if (isTablet) return 140.0;
    return 160.0;
  }
  
  double get buttonHeight {
    if (isMobile) return 44.0;
    if (isTablet) return 48.0;
    return 52.0;
  }
  
  double get buttonSpacing {
    if (isMobile) return 12.0;
    if (isTablet) return 16.0;
    return 20.0;
  }
  
  double get buttonFontSize {
    if (isSmallMobile) return 13.0;
    if (isMobile) return 14.0;
    if (isTablet) return 15.0;
    return 16.0;
  }
}

