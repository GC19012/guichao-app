import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:guichao/gch_base/gch_schema/gch_app_meta.dart';
import 'package:guichao/gch_base/gch_schema/gch_env.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_yingyong_xinxi.g.dart';

/// 应用安装来源枚举（仅 App Store）
enum AnzhuangLaiyuan {
  /// Apple App Store
  appStore,
  /// 未知来源
  weizhi,
}

@Riverpod(keepAlive: true)
GchEnv environment(EnvironmentRef ref) => throw Exception("override environmentProvider");

@Riverpod(keepAlive: true)
class GchYingyongXinxi extends _$GchYingyongXinxi {
  @override
  Future<GchAppMeta> build() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final environment = ref.watch(environmentProvider);

      return GchAppMeta(
        name: packageInfo.appName,
        version: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        release: GchRelease.read(),
        operatingSystem: Platform.operatingSystem,
        operatingSystemVersion: Platform.operatingSystemVersion,
        environment: environment,
      );
    } catch (e, stackTrace) {
      debugPrint('Failed to get app info: $e');
      debugPrint('Stack trace: $stackTrace');

      return GchAppMeta(
        name: 'guichao',
        version: '2.8.8',
        buildNumber: '0',
        release: GchRelease.general,
        operatingSystem: Platform.operatingSystem,
        operatingSystemVersion: Platform.operatingSystemVersion,
        environment: GchEnv.dev,
      );
    }
  }
}

/// 应用安装来源 Provider（仅 App Store）
@Riverpod(keepAlive: true)
Future<AnzhuangLaiyuan> anzhuangLaiyuan(AnzhuangLaiyuanRef ref) async {
  if (Platform.isIOS) {
    return AnzhuangLaiyuan.appStore;
  }
  return AnzhuangLaiyuan.weizhi;
}

/// 是否从 App Store 安装
@riverpod
Future<bool> shiAppStore(ShiAppStoreRef ref) async {
  final source = await ref.watch(anzhuangLaiyuanProvider.future);
  return source == AnzhuangLaiyuan.appStore;
}

/// 是否从官方应用商店安装
@riverpod
Future<bool> shiGuanfangShangdian(ShiGuanfangShangdianRef ref) async {
  final source = await ref.watch(anzhuangLaiyuanProvider.future);
  return source == AnzhuangLaiyuan.appStore;
}
