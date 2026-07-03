import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

/// MethodChannel 扩展：自动捕获 PlatformException
///
/// 使用方式：
/// ```dart
/// // 替换前：
/// await methodChannel.invokeMethod("method_name");
///
/// // 替换后：
/// await methodChannel.invokeMethodSafe("method_name");
/// ```
extension MethodChannelSafeExt on MethodChannel {
  /// 安全调用，自动捕获 PlatformException
  ///
  /// 【修复】所有异常都会记录日志，便于调试和问题排查
  Future<T?> invokeMethodSafe<T>(String method, [dynamic arguments]) async {
    try {
      return await invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      // 平台异常：记录警告日志（常见情况，如原生方法不存在）
      debugPrint('⚠️ MethodChannel[$name].$method PlatformException: ${e.code} - ${e.message}');
      return null;
    } on MissingPluginException catch (e) {
      // 插件未注册：记录警告日志
      debugPrint('⚠️ MethodChannel[$name].$method MissingPlugin: $e');
      return null;
    } catch (e, stackTrace) {
      // 【修复：错误静默吞噬】其他异常记录错误日志
      debugPrint('❌ MethodChannel[$name].$method unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// TaskEither 版本（用于已有 TaskEither 模式的代码）
  TaskEither<String, T?> invokeTask<T>(String method, [dynamic arguments]) {
    return TaskEither(() async {
      try {
        final result = await invokeMethod<T>(method, arguments);
        return right(result);
      } on PlatformException catch (e) {
        return left("${e.code}: ${e.message ?? ''}");
      } catch (e) {
        return left(e.toString());
      }
    });
  }
}
