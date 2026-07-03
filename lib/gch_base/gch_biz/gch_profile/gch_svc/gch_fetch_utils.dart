import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Hash any string content
String hash(String content) => sha256.convert(utf8.encode(content)).toString();

/// Hash file content (works for both text and binary)
String hashFile(File file) => sha256.convert(file.readAsBytesSync()).toString();

/// Check if two files have same content by hash
/// Returns null if files don't exist
/// Works for both text and binary files
/// Returns false if either file is empty (0 bytes)
bool? sameContent(File file1, File file2) {
  if (!file1.existsSync() || !file2.existsSync()) return null;
  try {
    // Verify both files have content (> 0 bytes)
    final size1 = file1.lengthSync();
    final size2 = file2.lengthSync();

    if (size1 == 0 || size2 == 0) {
      return false; // Empty files are considered "different" to prevent overwrites
    }

    final h1 = hashFile(file1);
    final h2 = hashFile(file2);
    return h1 == h2;
  } catch (_) {
    return null;
  }
}

/// Atomic write for string content
/// Write to .atomic temp then rename to prevent partial reads
/// Validates content is not empty and file size > 0 before writing
Future<void> atomicWrite(File target, String content) async {
  // Validate content before writing
  if (content.trim().isEmpty) {
    throw ArgumentError('Cannot write empty content to file: ${target.path}');
  }

  final temp = File('${target.path}.atomic');
  try {
    await temp.writeAsString(content);

    // Verify file was written successfully and has content
    final size = temp.lengthSync();
    if (size == 0) {
      throw Exception('Written file is empty (0 bytes): ${target.path}');
    }

    await temp.rename(target.path);
  } catch (e) {
    if (temp.existsSync()) await temp.delete();
    rethrow;
  }
}

/// Atomic rename for binary files
/// Rename temp file to target atomically
/// Validates file size > 0 before renaming
Future<void> atomicRename(File tempFile, File target) async {
  try {
    // Verify temp file has content before renaming
    if (!tempFile.existsSync()) {
      throw Exception('Temp file does not exist: ${tempFile.path}');
    }

    final size = tempFile.lengthSync();
    if (size == 0) {
      throw Exception('Temp file is empty (0 bytes), refusing to overwrite: ${target.path}');
    }

    await tempFile.rename(target.path);
  } catch (e) {
    if (tempFile.existsSync()) await tempFile.delete();
    rethrow;
  }
}

/// Extra 类型
enum ExtraType {
  url,       // URL 类型，需要下载文件
  content,   // 内容类型，直接保存到文件
  proxyData, // 代理数据类型，需要导入数据库
}

/// Extra 数据项
class ExtraItem {
  final String key;        // 字段名：extra, extra2...
  final ExtraType type;    // url=下载, content=保存, proxyData=导入数据库
  final String value;      // URL 或内容（字符串）
  final Map<String, dynamic>? proxyDataValue; // 代理数据（Map，仅 proxyData 类型）
  final String? proxyDataRaw; // 代理数据原始 JSON 字符串（用于 hash 计算）
  final String? name;      // 文件名（content 类型可选指定）

  const ExtraItem({
    required this.key,
    required this.type,
    required this.value,
    this.proxyDataValue,
    this.proxyDataRaw,
    this.name,
  });

  bool get isUrl => type == ExtraType.url;
  bool get isContent => type == ExtraType.content;
  bool get isProxyData => type == ExtraType.proxyData;

  /// 获取保存文件名
  String get fileName => name ?? '$key.dat';
}

/// 判断字符串是否为有效 URL
///
/// 规则：
/// 1. 必须以 http:// 或 https:// 开头
/// 2. 不能包含空格（URL 不含空格）
/// 3. 多个 URL 时，每个都必须有效
bool _isUrl(String value) {
  final trimmed = value.trim();

  // 单个 URL 检查
  if (_isValidUrl(trimmed)) return true;

  // 多个 URL（逗号/分号分隔）
  final parts = trimmed.split(RegExp('[,;，；]'));
  if (parts.length > 1) {
    return parts.every((p) => _isValidUrl(p.trim()));
  }

  return false;
}

/// 检查单个 URL 是否有效
bool _isValidUrl(String url) {
  if (url.isEmpty) return false;
  // 必须以 http(s):// 开头，且不含空格
  if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
  if (url.contains(' ')) return false;
  // 尝试解析 URI
  try {
    final uri = Uri.parse(url);
    return uri.hasScheme && uri.host.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// 解析单个 extra 字段
///
/// 旧格式兼容：只处理 URL，非 URL 忽略（保持原有行为）
/// 新格式：根据 type 字段明确指定
///
/// 支持的类型：
/// - `url`: URL 下载
/// - `content`: 内容保存到文件
/// - `proxy_data`: 代理数据导入数据库
ExtraItem? _parseExtraField(String key, dynamic value) {
  if (value == null) return null;

  // 格式1: String（旧格式）
  // 兼容原有逻辑：只处理 URL，非 URL 忽略
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    // 旧格式只支持 URL，非 URL 跳过
    if (!_isUrl(trimmed)) return null;
    return ExtraItem(
      key: key,
      type: ExtraType.url,
      value: trimmed,
    );
  }

  // 格式2: Map（新格式，明确类型）
  if (value is Map<String, dynamic>) {
    final typeStr = value['type'] as String?;
    if (typeStr == null) return null;

    // proxy_data 类型特殊处理：value 是 Map 或可解析为 Map 的 JSON 字符串
    if (typeStr == 'proxy_data') {
      final rawValue = value['value'];
      Map<String, dynamic>? proxyData;
      String? rawJsonString;

      if (rawValue is Map<String, dynamic>) {
        proxyData = rawValue;
        // Map 类型需要序列化为字符串（保持键顺序一致）
        rawJsonString = jsonEncode(rawValue);
      } else if (rawValue is String) {
        // 保存原始字符串用于 hash 计算
        rawJsonString = rawValue;
        // 尝试解析 JSON 字符串
        try {
          final parsed = jsonDecode(rawValue);
          if (parsed is Map<String, dynamic>) {
            proxyData = parsed;
          }
        } catch (_) {
          return null; // JSON 解析失败
        }
      }

      if (proxyData == null) return null;

      // 验证代理数据格式（必须有 groups/items 或 gch_pgroups）
      final hasFlat = proxyData.containsKey('groups') && proxyData.containsKey('items');
      final hasNested = proxyData.containsKey('gch_pgroups');
      if (!hasFlat && !hasNested) return null;

      return ExtraItem(
        key: key,
        type: ExtraType.proxyData,
        value: '', // proxyData 类型不使用 value 字符串
        proxyDataValue: proxyData,
        proxyDataRaw: rawJsonString,
      );
    }

    // url/content 类型
    final val = value['value'] as String?;
    if (val == null || val.trim().isEmpty) return null;

    final type = typeStr == 'url' ? ExtraType.url : ExtraType.content;
    return ExtraItem(
      key: key,
      type: type,
      value: val.trim(),
      name: value['name'] as String?,
    );
  }

  return null;
}

/// 增量响应结果
class IncrementalResponse {
  final String? content;            // 配置内容（null 表示未变更）
  final List<ExtraItem> extras;     // extra 列表
  final bool configUnchanged;       // 配置是否未变更
  final Set<String> unchangedExtras; // 未变更的 extra key 集合
  final List<String> manifest;      // 资源清单（必需文件列表）

  const IncrementalResponse({
    this.content,
    this.extras = const [],
    this.configUnchanged = false,
    this.unchangedExtras = const {},
    this.manifest = const [],
  });

  /// 是否有需要下载的 extras
  bool get hasExtras => extras.isNotEmpty;

  /// 是否完全无变化（配置和所有 extras 都没变）
  bool get fullyUnchanged => configUnchanged && extras.isEmpty;

  /// URL 类型（需下载）
  List<ExtraItem> get urlExtras => extras.where((e) => e.isUrl).toList();

  /// 内容类型（需保存）
  List<ExtraItem> get contentExtras => extras.where((e) => e.isContent).toList();

  /// 代理数据类型（需导入数据库）
  List<ExtraItem> get proxyDataExtras => extras.where((e) => e.isProxyData).toList();

  /// 是否有代理数据需要导入
  bool get hasProxyDataExtras => proxyDataExtras.isNotEmpty;
}

/// Parse API response（增量版本）
///
/// 支持格式：
/// 1. 旧格式: "extra": "https://..." (自动判断URL/内容)
/// 2. 新格式: "extra": {"type": "url|content", "value": "...", "name": "..."}
/// 3. 增量格式: "unchanged": true 或 "unchanged": ["extra", "extra2"]
IncrementalResponse parseResponseIncremental(Object? data) {
  if (data is String) {
    return IncrementalResponse(content: data);
  }

  if (data is! Map) {
    throw FormatException('Invalid response type: expected Map, got ${data.runtimeType}');
  }

  final map = _toStringMap(data);

  // Standard API format: {code, success, data: {config, extra...}}
  if (map.containsKey('code') && map.containsKey('data')) {
    final code = map['code'];
    final success = map['success'];

    // 兼容多种成功标识
    final isOk = (code == 0 || code == 200) && (success == true || success == 1);
    if (!isOk) {
      throw Exception('API error: code=$code, msg=${map['msg'] ?? map['message']}');
    }

    final rawPayload = map['data'];
    if (rawPayload == null) {
      throw FormatException('Missing data field');
    }
    if (rawPayload is! Map) {
      throw FormatException('data field must be Map, got ${rawPayload.runtimeType}');
    }

    final payload = _toStringMap(rawPayload);

    // 解析 unchanged 字段
    final unchanged = payload['unchanged'];
    var configUnchanged = false;
    var unchangedExtras = <String>{};

    if (unchanged == true) {
      // 全部未变更
      return const IncrementalResponse(configUnchanged: true);
    } else if (unchanged is List) {
      // 部分未变更：["config"] 或 ["extra", "extra2"]
      unchangedExtras = unchanged.whereType<String>().toSet();
      configUnchanged = unchangedExtras.contains('config');
      unchangedExtras.remove('config'); // config 单独处理
    }

    // 解析 config（如果存在且非 unchanged）
    String? content;
    if (!configUnchanged && payload.containsKey('config')) {
      final rawConfig = payload['config'];
      if (rawConfig is String) {
        content = rawConfig;
      } else if (rawConfig is Map || rawConfig is List) {
        content = jsonEncode(rawConfig);
      } else if (rawConfig != null) {
        content = rawConfig.toString();
      }

      if (content != null && content.trim().isEmpty) {
        throw FormatException('Config content is empty');
      }
    }

    // 收集需要更新的 extra* 字段（排除 unchanged 的）
    final extras = <ExtraItem>[];
    for (final key in payload.keys) {
      if (key.startsWith('extra') && !unchangedExtras.contains(key)) {
        final item = _parseExtraField(key, payload[key]);
        if (item != null) extras.add(item);
      }
    }

    // 解析 manifest（资源清单）
    // 支持格式：
    // 1. 数组: ["config", "geosite.dat"]
    // 2. 字符串: "config,geosite.dat" 或 "{config,geosite.dat}"
    final manifest = _parseManifest(payload['manifest']);

    return IncrementalResponse(
      content: content,
      extras: extras,
      configUnchanged: configUnchanged,
      unchangedExtras: unchangedExtras,
      manifest: manifest,
    );
  }

  // Fallback: entire JSON as content
  return IncrementalResponse(content: jsonEncode(map));
}

/// 将 Map 转换为 Map<String, Object?>
Map<String, Object?> _toStringMap(Map<Object?, Object?> source) {
  final result = <String, Object?>{};
  for (final entry in source.entries) {
    if (entry.key is String) {
      result[entry.key as String] = entry.value;
    }
  }
  return result;
}

/// 解析 manifest
///
/// 支持格式：
/// - 数组: ["config", "geosite.dat"]
/// - 字符串: "config,geosite.dat"
/// - 花括号: "{config,geosite.dat}"
List<String> _parseManifest(Object? raw) {
  if (raw == null) return [];

  // 格式1: 数组
  if (raw is List) {
    return raw.whereType<String>().where((s) => s.isNotEmpty).toList();
  }

  // 格式2: 字符串
  if (raw is String) {
    var s = raw.trim();
    if (s.isEmpty) return [];

    // 去除花括号 {xxx} -> xxx
    if (s.startsWith('{') && s.endsWith('}')) {
      s = s.substring(1, s.length - 1);
    }

    // 按逗号分隔
    return s
        .split(RegExp(r'[,;，；]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  return [];
}

/// Parse API response（兼容旧接口）
///
/// 支持格式：
/// 1. 旧格式: "extra": "https://..." (自动判断URL/内容)
/// 2. 新格式: "extra": {"type": "url|content", "value": "...", "name": "..."}
({String content, List<ExtraItem> extras}) parseResponse(Object? data) {
  final result = parseResponseIncremental(data);

  // 兼容旧接口：如果 configUnchanged，抛出异常（旧逻辑不支持增量）
  if (result.configUnchanged && result.content == null) {
    throw Exception('Config unchanged but no content provided');
  }

  return (content: result.content ?? '', extras: result.extras);
}
