import 'dart:io';

import 'package:guichao/gch_base/gch_bridge/gch_platform_link.dart';
import 'package:path/path.dart' as p;

class GchTraceLocator {
  const GchTraceLocator(this._workingDir, {UniversalPlatformBridge? bridge})
      : _bridge = bridge;

  final Directory _workingDir;
  final UniversalPlatformBridge? _bridge;

  Directory get directory => _workingDir;

  /// 获取 core 日志文件
  /// 在 Android/iOS 平台优先从原生层获取实际路径
  Future<File> coreFile() async {
    if (_bridge != null) {
      try {
        final nativePath = await _bridge.getLogPath();
        if (nativePath != null && nativePath.isNotEmpty) {
          return File(nativePath);
        }
      } catch (e) {
        // 如果获取失败，使用默认路径
      }
    }
    return File(p.join(directory.path, "box.log"));
  }

  File appFile() {
    return File(p.join(directory.path, "app.log"));
  }
}
