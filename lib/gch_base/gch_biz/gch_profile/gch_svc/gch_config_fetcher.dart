import 'dart:io';

import 'package:dio/dio.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_client/gch_api_client.dart';
import 'package:guichao/gch_base/gch_biz/gch_profile/gch_svc/gch_config_transport.dart';
import 'package:guichao/gch_base/gch_biz/gch_profile/gch_svc/gch_fetch_utils.dart' as utils;
import 'package:guichao/gch_aux/gch_log_mix.dart';

/// 从 TransportResponse 提取数据用于解析
Object? _extractData(TransportResponse response) {
  return switch (response) {
    MapResponse(:final data) => data,
    StringResponse(:final data) => data,
    ListResponse(:final data) => data,
    EmptyResponse() => null,
  };
}

/// 获取结果
class FetchResult {
  final String content;
  final List<utils.ExtraItem> extras;

  const FetchResult({required this.content, this.extras = const []});

  /// URL 类型（需下载）
  List<utils.ExtraItem> get urlExtras => extras.where((e) => e.isUrl).toList();

  /// 内容类型（需保存）
  List<utils.ExtraItem> get contentExtras => extras.where((e) => e.isContent).toList();

  /// 代理数据类型（需导入数据库）
  List<utils.ExtraItem> get proxyDataExtras => extras.where((e) => e.isProxyData).toList();

  /// 所有 URL 合并
  String get allUrls => urlExtras.map((e) => e.value).join(',');

  bool get hasUrlExtras => urlExtras.isNotEmpty;
  bool get hasContentExtras => contentExtras.isNotEmpty;
  bool get hasProxyDataExtras => proxyDataExtras.isNotEmpty;
  bool get hasExtras => extras.isNotEmpty;
}

/// 增量获取结果
class IncrementalFetchResult {
  final String? content;             // 配置内容（null 表示未变更）
  final List<utils.ExtraItem> extras; // 需要更新的 extras
  final bool configUnchanged;         // 配置是否未变更
  final Set<String> unchangedExtras;  // 未变更的 extra keys
  final List<String> manifest;        // 资源清单

  const IncrementalFetchResult({
    this.content,
    this.extras = const [],
    this.configUnchanged = false,
    this.unchangedExtras = const {},
    this.manifest = const [],
  });

  bool get hasManifest => manifest.isNotEmpty;

  /// URL 类型（需下载）
  List<utils.ExtraItem> get urlExtras => extras.where((e) => e.isUrl).toList();

  /// 内容类型（需保存）
  List<utils.ExtraItem> get contentExtras => extras.where((e) => e.isContent).toList();

  /// 代理数据类型（需导入数据库）
  List<utils.ExtraItem> get proxyDataExtras => extras.where((e) => e.isProxyData).toList();

  /// 所有 URL 合并
  String get allUrls => urlExtras.map((e) => e.value).join(',');

  bool get hasUrlExtras => urlExtras.isNotEmpty;
  bool get hasContentExtras => contentExtras.isNotEmpty;
  bool get hasProxyDataExtras => proxyDataExtras.isNotEmpty;
  bool get hasExtras => extras.isNotEmpty;

  /// 是否完全无变化
  bool get fullyUnchanged => configUnchanged && extras.isEmpty;

  /// 转换为传统 FetchResult（用于兼容旧逻辑）
  FetchResult toFetchResult() {
    if (content == null) {
      throw StateError('Cannot convert unchanged result to FetchResult');
    }
    return FetchResult(content: content!, extras: extras);
  }
}

/// 配置获取器接口 - 网络层
///
/// 职责：
/// - POST 请求获取配置
/// - 解析响应
/// - 下载 extra 文件
abstract interface class ConfigFetcher {
  /// 获取配置
  Future<FetchResult> fetch(
    String url, {
    required String profileId,
    CancelToken? cancelToken,
  });

  /// 增量获取配置（带 hash 比较）
  ///
  /// [hashes] 本地文件 hash 集合：{"config": "abc...", "extra": "def...", "extra2": "ghi..."}
  /// 服务端比较后返回：
  /// - 未变更: {"unchanged": true} 或 {"unchanged": ["config", "extra"]}
  /// - 有变更: 返回变更的内容
  Future<IncrementalFetchResult> fetchIncremental(
    String url, {
    required String profileId,
    Map<String, String>? hashes,
    CancelToken? cancelToken,
  });

  /// 下载 extra 文件
  ///
  /// [skipInterceptors] 跳过拦截器，用于外部URL（如S3）避免自定义header导致400错误
  Future<void> fetchExtra(
    String urls,
    String saveDir, {
    CancelToken? cancelToken,
    void Function(int done, int total)? onProgress,
    bool skipInterceptors = false,
  });

  /// 下载单个文件
  ///
  /// [skipInterceptors] 跳过拦截器，用于外部URL（如S3）避免自定义header导致400错误
  Future<void> fetchFile(
    String url,
    String saveDir, {
    CancelToken? cancelToken,
    bool skipInterceptors = false,
  });
}

/// 默认配置获取器 - 组合 Transport 实现协议无关
class DefaultConfigFetcher with GchInfraLogger implements ConfigFetcher {
  DefaultConfigFetcher({required this.transport});

  final ConfigTransport transport;

  /// 构建请求数据
  Map<String, dynamic> _buildRequestData(String profileId, {Map<String, String>? hashes}) {
    final data = <String, dynamic>{
      'uuid': profileId,
      'platform': Platform.operatingSystem,
      'version': GchNucleus.version,
    };
    if (hashes != null && hashes.isNotEmpty) {
      data['hashes'] = hashes;
    }
    return data;
  }

  @override
  Future<FetchResult> fetch(
    String url, {
    required String profileId,
    CancelToken? cancelToken,
  }) async {
    final response = await transport.post(url.trim(), _buildRequestData(profileId), cancelToken: cancelToken);
    final data = _extractData(response);

    final parsed = utils.parseResponse(data);
    final content = parsed.content;

    if (content.trim().isEmpty) {
      throw Exception('Downloaded content is empty');
    }

    final urlCount = parsed.extras.where((e) => e.isUrl).length;
    final contentCount = parsed.extras.where((e) => e.isContent).length;
    loggy.info("Downloaded: ${content.length} bytes, extras: $urlCount urls, $contentCount contents");

    return FetchResult(content: content, extras: parsed.extras);
  }

  @override
  Future<IncrementalFetchResult> fetchIncremental(
    String url, {
    required String profileId,
    Map<String, String>? hashes,
    CancelToken? cancelToken,
  }) async {
    final response = await transport.post(
      url.trim(),
      _buildRequestData(profileId, hashes: hashes),
      cancelToken: cancelToken,
    );
    final data = _extractData(response);

    final parsed = utils.parseResponseIncremental(data);

    // 日志记录
    if (parsed.fullyUnchanged) {
      loggy.info("All unchanged, skip download");
    } else if (parsed.configUnchanged) {
      loggy.info("Config unchanged, extras: ${parsed.extras.length} to update");
    } else {
      final contentLen = parsed.content?.length ?? 0;
      final urlCount = parsed.urlExtras.length;
      final contentCount = parsed.contentExtras.length;
      loggy.info("Downloaded: $contentLen bytes, extras: $urlCount urls, $contentCount contents");
    }

    return IncrementalFetchResult(
      content: parsed.content,
      extras: parsed.extras,
      configUnchanged: parsed.configUnchanged,
      unchangedExtras: parsed.unchangedExtras,
      manifest: parsed.manifest,
    );
  }

  @override
  Future<void> fetchExtra(
    String urls,
    String saveDir, {
    CancelToken? cancelToken,
    void Function(int done, int total)? onProgress,
    bool skipInterceptors = false,
  }) async {
    final list = urls.split(RegExp('[,;，；]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (list.isEmpty) {
      loggy.debug("Extra urls empty, skip");
      return;
    }

    loggy.info("Downloading ${list.length} extra files");

    int done = 0;
    final tasks = list.map((url) async {
      try {
        await fetchFile(url, saveDir, cancelToken: cancelToken, skipInterceptors: skipInterceptors);
        done++;
        onProgress?.call(done, list.length);
      } catch (e) {
        if (e is DioException && e.type == DioExceptionType.cancel) {
          loggy.debug("Download canceled: $url");
        } else {
          loggy.warning("Download failed: $url", e);
        }
        rethrow;
      }
    }).toList();

    await Future.wait(tasks);
    loggy.info("Extra files done");
  }

  @override
  Future<void> fetchFile(
    String url,
    String saveDir, {
    CancelToken? cancelToken,
    bool skipInterceptors = false,
  }) async {
    final segments = Uri.parse(url).pathSegments;
    if (segments.isEmpty) {
      throw ArgumentError('URL has no path segments: $url');
    }
    final name = segments.last;
    final target = File('$saveDir/$name');
    final cache = File('${target.path}.cache');
    final temp = File('${target.path}.download');
    final backup = File('${target.path}.backup');

    try {
      // 备份
      if (target.existsSync() && target.lengthSync() > 0) {
        await target.copy(backup.path);
        loggy.debug("Backup: $name (${target.lengthSync()} bytes)");
      }

      loggy.debug("Downloading: $url");

      // 下载到临时文件（通过 Transport）
      await transport.download(url, temp.path, cancelToken: cancelToken, skipInterceptors: skipInterceptors);

      if (!temp.existsSync()) {
        throw Exception('Download failed: $temp');
      }

      final size = temp.lengthSync();
      if (size == 0) {
        throw Exception('Downloaded empty: $name');
      }

      loggy.debug("Downloaded: $name ($size bytes)");

      // Hash 比较
      final same = utils.sameContent(cache, temp);

      if (same == true) {
        final hash = utils.hashFile(temp);
        loggy.info("Unchanged: $name (${hash.substring(0, 8)}...)");
        await temp.delete();
        if (backup.existsSync()) await backup.delete();
      } else {
        final hash = utils.hashFile(temp);
        loggy.info("${same == null ? 'New' : 'Changed'}: $name (${hash.substring(0, 8)}...)");

        // 原子重命名
        await utils.atomicRename(temp, target);

        final newSize = target.lengthSync();
        if (newSize == 0) {
          throw Exception('Write failed: $name');
        }

        // 更新缓存
        await target.copy(cache.path);

        loggy.info("Updated: $name ($newSize bytes)");

        if (backup.existsSync()) {
          await backup.delete();
        }
      }
    } catch (e, st) {
      // 恢复备份
      if (backup.existsSync()) {
        final backupSize = backup.lengthSync();
        if (backupSize > 0 && (!target.existsSync() || target.lengthSync() == 0)) {
          await backup.copy(target.path);
          loggy.warning("Restored: $name ($backupSize bytes)");
        }
        await backup.delete();
      }

      if (temp.existsSync()) await temp.delete();

      if (e is DioException && e.type == DioExceptionType.cancel) {
        loggy.debug("Canceled: $url");
      } else {
        loggy.error("Failed: $url", e, st);
      }
      rethrow;
    }
  }
}

/// 兼容旧代码：PostConfigFetcher = DefaultConfigFetcher + HttpTransport
class PostConfigFetcher extends DefaultConfigFetcher {
  PostConfigFetcher({required DataApiClient client}) : super(transport: HttpTransport(client: client));
}
