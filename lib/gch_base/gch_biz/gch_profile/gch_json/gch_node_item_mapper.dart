/// ProxyItem JSON 映射器
///
/// 负责 API JSON ↔ GchNodeItemTableCompanion 的转换
/// 适用于从服务器同步代理节点数据到本地存储（Realm/SQLite）
///
/// 【字段说明】
/// - id: Profile ID（外键）
/// - tag: 代理项唯一标识
/// - groupTag: 所属分组标签
/// - type: 代理类型（如 "vmess", "vless", "trojan", "shadowsocks"）
/// - selectedTag: 选中的代理项标签
/// - urlTestDelay: URL 测试延迟（毫秒，0 表示未测试/失败）
/// - memo: 备注（加密字段）
/// - lastCheck: 最后健康检查时间戳（毫秒）
/// - lastUpdate: 最后更新时间戳（毫秒）
/// - uplink/downlink: 实时上传/下载速率
/// - uplinkTotal/downlinkTotal: 累计上传/下载流量
/// - role: 角色（默认 "free"）
/// - access: 访问级别（默认 0）
/// - tagAlias: 标签别名（默认等于 tag）
/// - groupTagAlias: 分组标签别名（默认等于 groupTag）
library;

import 'package:drift/drift.dart' as drift;
import 'package:fpdart/fpdart.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_store/gch_json/gch_json_codec.dart';

/// ProxyItem JSON 映射器
///
/// 实现完整的 JSON 转换、批量处理和验证能力
class GchNodeItemJsonMapper implements GchJsonMapper<GchNodeItemTableCompanion> {
  // ==================== GchJsonSerializable 实现 ====================

  @override
  GchNodeItemTableCompanion fromJson(Map<String, dynamic> json) {
    // 验证和清洗数据
    final sanitizedJson = sanitize(json);

    return GchNodeItemTableCompanion(
      id: drift.Value(GchJsonHelper.parseString(sanitizedJson, 'id')),
      tag: drift.Value(GchJsonHelper.parseString(sanitizedJson, 'tag')),
      groupTag: drift.Value(GchJsonHelper.parseString(sanitizedJson, 'group_tag')),
      type: drift.Value(GchJsonHelper.parseString(sanitizedJson, 'type')),
      selectedTag: drift.Value(
        GchJsonHelper.optional<String>(
          sanitizedJson,
          'selected_tag',
          GchJsonHelper.parseString,
        ),
      ),
      urlTestDelay: drift.Value(
        GchJsonHelper.optional<int>(
          sanitizedJson,
          'url_test_delay',
          GchJsonHelper.parseInt,
        ),
      ),
      memo: drift.Value(
        GchJsonHelper.optional<String>(
          sanitizedJson,
          'memo',
          GchJsonHelper.parseString,
        ),
      ),
      lastCheck: drift.Value(
        GchJsonHelper.optional<int>(
          sanitizedJson,
          'last_check',
          GchJsonHelper.parseInt,
        ),
      ),
      lastUpdate: drift.Value(
        GchJsonHelper.parseInt(
          sanitizedJson,
          'last_update',
          defaultValue: DateTime.now().millisecondsSinceEpoch,
        ),
      ),
      uplink: drift.Value(
        GchJsonHelper.optional<int>(
          sanitizedJson,
          'uplink',
          GchJsonHelper.parseInt,
        ),
      ),
      downlink: drift.Value(
        GchJsonHelper.optional<int>(
          sanitizedJson,
          'downlink',
          GchJsonHelper.parseInt,
        ),
      ),
      uplinkTotal: drift.Value(
        GchJsonHelper.optional<int>(
          sanitizedJson,
          'uplink_total',
          GchJsonHelper.parseInt,
        ),
      ),
      downlinkTotal: drift.Value(
        GchJsonHelper.optional<int>(
          sanitizedJson,
          'downlink_total',
          GchJsonHelper.parseInt,
        ),
      ),
      role: drift.Value(
        GchJsonHelper.parseString(
          sanitizedJson,
          'role',
          defaultValue: 'free',
        ),
      ),
      access: drift.Value(
        GchJsonHelper.parseInt(
          sanitizedJson,
          'access',
          defaultValue: 0,
        ),
      ),
      tagAlias: drift.Value(
        GchJsonHelper.parseString(
          sanitizedJson,
          'tag_alias',
          defaultValue: sanitizedJson['tag'] as String,
        ),
      ),
      groupTagAlias: drift.Value(
        GchJsonHelper.parseString(
          sanitizedJson,
          'group_tag_alias',
          defaultValue: sanitizedJson['group_tag'] as String,
        ),
      ),
      virtual: drift.Value(
        GchJsonHelper.parseBool(
          sanitizedJson,
          'virtual',
          defaultValue: false,
        ),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    // ProxyItem 通常只需要从 JSON 导入，不需要导出到服务器
    throw UnimplementedError('ProxyItem toJson not implemented');
  }

  // ==================== GchJsonBatchConverter 实现 ====================

  @override
  List<GchNodeItemTableCompanion> fromJsonList(List<dynamic> jsonList) {
    final results = <GchNodeItemTableCompanion>[];

    for (final json in jsonList) {
      if (json is! Map<String, dynamic>) {
        print('⚠️ [ProxyItem] 跳过非 Map 类型: ${json.runtimeType}');
        continue;
      }

      try {
        if (validate(json)) {
          results.add(fromJson(json));
        } else {
          print('⚠️ [ProxyItem] 跳过验证失败: ${json['tag'] ?? 'unknown'}');
        }
      } catch (e) {
        print('❌ [ProxyItem] 转换失败: $e, JSON: $json');
        // 继续处理其他数据
      }
    }

    return results;
  }

  @override
  List<Map<String, dynamic>> toJsonList(List<GchNodeItemTableCompanion> items) {
    throw UnimplementedError('ProxyItem batch toJson not implemented');
  }

  // ==================== GchJsonValidator 实现 ====================

  @override
  bool validate(Map<String, dynamic> json) {
    // 必填字段检查
    final requiredFields = ['id', 'tag', 'group_tag', 'type'];
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        print('验证失败: 缺少必填字段 "$field"');
        return false;
      }

      // 检查字符串字段非空
      if (json[field] is String && (json[field] as String).isEmpty) {
        print('验证失败: 字段 "$field" 不能为空字符串');
        return false;
      }
    }

    // 代理类型枚举检查
    final validTypes = [
      'vmess',
      'vless',
      'trojan',
      'shadowsocks',
      'ss',
      'socks',
      'http',
      'https',
      'wireguard',
      'tuic',
      'hysteria',
      'hysteria2',
      'selector',
      'urltest',
      'direct',
      'reject',
      'dns',
    ];
    if (json.containsKey('type')) {
      final type = json['type']?.toString().toLowerCase();
      if (type != null && !validTypes.contains(type)) {
        print('⚠️ 警告: 未知的代理类型 "$type"（将继续处理）');
        // 不阻止导入，只是警告
      }
    }

    // URL 测试延迟合法性检查
    if (json.containsKey('url_test_delay') && json['url_test_delay'] != null) {
      try {
        final delay = GchJsonHelper.parseInt(json, 'url_test_delay');
        if (delay < 0) {
          print('验证失败: url_test_delay 不能为负数');
          return false;
        }
      } catch (e) {
        print('验证失败: url_test_delay 格式错误');
        return false;
      }
    }

    // 流量数据合法性检查
    for (final field in ['uplink', 'downlink', 'uplink_total', 'downlink_total']) {
      if (json.containsKey(field) && json[field] != null) {
        try {
          final value = GchJsonHelper.parseInt(json, field);
          if (value < 0) {
            print('验证失败: $field 不能为负数');
            return false;
          }
        } catch (e) {
          print('验证失败: $field 格式错误');
          return false;
        }
      }
    }

    // access 级别检查
    if (json.containsKey('access') && json['access'] != null) {
      try {
        final access = GchJsonHelper.parseInt(json, 'access');
        if (access < 0) {
          print('验证失败: access 级别不能为负数');
          return false;
        }
      } catch (e) {
        print('验证失败: access 格式错误');
        return false;
      }
    }

    return true;
  }

  @override
  Map<String, dynamic> sanitize(Map<String, dynamic> json) {
    // 验证数据
    if (!validate(json)) {
      throw GchJsonValidationError(
        message: 'Cannot sanitize invalid ProxyItem data',
        violations: _getViolations(json),
        json: json,
      );
    }

    final sanitized = Map<String, dynamic>.from(json);

    // 清洗字符串字段（去除空白）
    for (final key in [
      'id',
      'tag',
      'group_tag',
      'type',
      'selected_tag',
      'memo',
      'role',
      'tag_alias',
      'group_tag_alias'
    ]) {
      if (sanitized[key] is String) {
        sanitized[key] = (sanitized[key] as String).trim();
      }
    }

    // 统一代理类型小写
    if (sanitized.containsKey('type')) {
      sanitized['type'] = (sanitized['type'] as String).toLowerCase();
    }

    // 确保 role 默认值
    if (!sanitized.containsKey('role') || sanitized['role'] == null) {
      sanitized['role'] = 'free';
    }

    // 确保 access 默认值
    if (!sanitized.containsKey('access') || sanitized['access'] == null) {
      sanitized['access'] = 0;
    }

    // 确保 tagAlias 默认值
    if (!sanitized.containsKey('tag_alias') || sanitized['tag_alias'] == null) {
      sanitized['tag_alias'] = sanitized['tag'];
    }

    // 确保 groupTagAlias 默认值
    if (!sanitized.containsKey('group_tag_alias') || sanitized['group_tag_alias'] == null) {
      sanitized['group_tag_alias'] = sanitized['group_tag'];
    }

    // 确保 lastUpdate 时间戳
    if (!sanitized.containsKey('last_update') || sanitized['last_update'] == null) {
      sanitized['last_update'] = DateTime.now().millisecondsSinceEpoch;
    }

    return sanitized;
  }

  // ==================== 辅助方法 ====================

  List<String> _getViolations(Map<String, dynamic> json) {
    final violations = <String>[];

    final requiredFields = ['id', 'tag', 'group_tag', 'type'];
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        violations.add('缺少必填字段: $field');
      } else if (json[field] is String && (json[field] as String).isEmpty) {
        violations.add('字段 "$field" 不能为空字符串');
      }
    }

    if (json.containsKey('url_test_delay') && json['url_test_delay'] != null) {
      try {
        final delay = GchJsonHelper.parseInt(json, 'url_test_delay');
        if (delay < 0) {
          violations.add('url_test_delay 不能为负数');
        }
      } catch (e) {
        violations.add('url_test_delay 格式错误');
      }
    }

    for (final field in ['uplink', 'downlink', 'uplink_total', 'downlink_total']) {
      if (json.containsKey(field) && json[field] != null) {
        try {
          final value = GchJsonHelper.parseInt(json, field);
          if (value < 0) {
            violations.add('$field 不能为负数');
          }
        } catch (e) {
          violations.add('$field 格式错误');
        }
      }
    }

    if (json.containsKey('access') && json['access'] != null) {
      try {
        final access = GchJsonHelper.parseInt(json, 'access');
        if (access < 0) {
          violations.add('access 级别不能为负数');
        }
      } catch (e) {
        violations.add('access 格式错误');
      }
    }

    return violations;
  }
}

// ==================== 函数式实现 ====================

/// ProxyItem JSON 映射器（函数式版本）
///
/// 使用 Either 类型处理错误，避免异常抛出
class GchNodeItemJsonMapperEither implements GchJsonEither<GchNodeItemTableCompanion> {
  @override
  Either<GchJsonFailure, GchNodeItemTableCompanion> fromEither(
    Map<String, dynamic> json,
  ) {
    // 验证必填字段
    final requiredFields = ['id', 'tag', 'group_tag', 'type'];
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        return Left(GchJsonFailure.missingField(field));
      }

      if (json[field] is String && (json[field] as String).isEmpty) {
        return Left(GchJsonFailure.validation(['字段 "$field" 不能为空']));
      }
    }

    try {
      // 构建 Companion 对象
      final companion = GchNodeItemTableCompanion(
        id: drift.Value(json['id'] as String),
        tag: drift.Value(json['tag'] as String),
        groupTag: drift.Value(json['group_tag'] as String),
        type: drift.Value((json['type'] as String).toLowerCase()),
        selectedTag: drift.Value(json['selected_tag'] as String?),
        urlTestDelay: drift.Value(json['url_test_delay'] as int?),
        memo: drift.Value(json['memo'] as String?),
        lastCheck: drift.Value(json['last_check'] as int?),
        lastUpdate: drift.Value(
          json['last_update'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
        uplink: drift.Value(json['uplink'] as int?),
        downlink: drift.Value(json['downlink'] as int?),
        uplinkTotal: drift.Value(json['uplink_total'] as int?),
        downlinkTotal: drift.Value(json['downlink_total'] as int?),
        role: drift.Value(json['role'] as String? ?? 'free'),
        access: drift.Value(json['access'] as int? ?? 0),
        tagAlias: drift.Value(json['tag_alias'] as String? ?? json['tag'] as String),
        groupTagAlias: drift.Value(
          json['group_tag_alias'] as String? ?? json['group_tag'] as String,
        ),
        virtual: drift.Value(json['virtual'] as bool? ?? false),
      );

      return Right(companion);
    } catch (e) {
      return Left(GchJsonFailure.error(e.toString()));
    }
  }

  @override
  Either<GchJsonFailure, List<GchNodeItemTableCompanion>> fromListEither(
    List<dynamic> jsonList,
  ) {
    final results = <GchNodeItemTableCompanion>[];

    for (final json in jsonList) {
      if (json is! Map<String, dynamic>) {
        return Left(GchJsonFailure.invalidFormat('Expected Map<String, dynamic> but got ${json.runtimeType}'));
      }

      final result = fromEither(json);
      if (result.isLeft()) {
        return result.map((r) => <GchNodeItemTableCompanion>[]);
      }

      result.fold(
        (failure) => null,
        (companion) => results.add(companion),
      );
    }

    return Right(results);
  }
}

// ==================== 便捷扩展方法 ====================

/// GchNodeItemTableCompanion 扩展
extension ProxyItemCompanionExt on GchNodeItemTableCompanion {
  /// 转换为 Map（用于调试）
  Map<String, dynamic> toDebugMap() {
    return {
      'id': id.present ? id.value : null,
      'tag': tag.present ? tag.value : null,
      'groupTag': groupTag.present ? groupTag.value : null,
      'type': type.present ? type.value : null,
      'selectedTag': selectedTag.present ? selectedTag.value : null,
      'urlTestDelay': urlTestDelay.present ? urlTestDelay.value : null,
      'memo': memo.present ? memo.value : null,
      'lastCheck': lastCheck.present ? lastCheck.value : null,
      'lastUpdate': lastUpdate.present ? lastUpdate.value : null,
      'uplink': uplink.present ? uplink.value : null,
      'downlink': downlink.present ? downlink.value : null,
      'uplinkTotal': uplinkTotal.present ? uplinkTotal.value : null,
      'downlinkTotal': downlinkTotal.present ? downlinkTotal.value : null,
      'role': role.present ? role.value : null,
      'access': access.present ? access.value : null,
      'tagAlias': tagAlias.present ? tagAlias.value : null,
      'groupTagAlias': groupTagAlias.present ? groupTagAlias.value : null,
      'virtual': virtual.present ? virtual.value : null,
    };
  }

  /// 判断是否为健康节点（延迟 < 500ms）
  bool get isHealthy {
    if (!urlTestDelay.present || urlTestDelay.value == null) return false;
    return urlTestDelay.value! > 0 && urlTestDelay.value! < 500;
  }

  /// 判断是否为快速节点（延迟 < 200ms）
  bool get isFast {
    if (!urlTestDelay.present || urlTestDelay.value == null) return false;
    return urlTestDelay.value! > 0 && urlTestDelay.value! < 200;
  }

  /// 获取延迟等级描述
  String get delayLevel {
    if (!urlTestDelay.present || urlTestDelay.value == null || urlTestDelay.value == 0) {
      return '未测试';
    }

    final delay = urlTestDelay.value!;
    if (delay < 100) return '极快';
    if (delay < 200) return '快速';
    if (delay < 500) return '正常';
    if (delay < 1000) return '较慢';
    return '很慢';
  }
}

