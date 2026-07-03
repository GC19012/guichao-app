/// ProxyGroup JSON 映射器
///
/// 负责 API JSON ↔ GchNodeGroupTableCompanion 的转换
/// 适用于从服务器同步代理分组数据到本地存储（Realm/SQLite）
///
/// 【字段说明】
/// - id: Profile ID（外键）
/// - tag: 分组唯一标识（如 "Proxy", "Direct"）
/// - type: 分组类型（如 "selector", "urltest"）
/// - selectedTag: 当前选中的代理项标签
/// - lastCheck: 最后健康检查时间戳（毫秒）
/// - lastUpdate: 最后更新时间戳（毫秒）
/// - memo: 备注（加密字段）
/// - role: 角色（默认 "free"）
/// - access: 访问级别（默认 0）
/// - tagAlias: 标签别名（默认等于 tag）
library;

import 'package:drift/drift.dart' as drift;
import 'package:fpdart/fpdart.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';
import 'package:guichao/gch_base/gch_store/gch_json/gch_json_codec.dart';

/// ProxyGroup JSON 映射器
///
/// 实现完整的 JSON 转换、批量处理和验证能力
class GchNodeGroupJsonMapper implements GchJsonMapper<GchNodeGroupTableCompanion> {
  // ==================== GchJsonSerializable 实现 ====================

  @override
  GchNodeGroupTableCompanion fromJson(Map<String, dynamic> json) {
    // 验证和清洗数据
    final sanitizedJson = sanitize(json);

    return GchNodeGroupTableCompanion(
      id: drift.Value(GchJsonHelper.parseString(sanitizedJson, 'id')),
      tag: drift.Value(GchJsonHelper.parseString(sanitizedJson, 'tag')),
      type: drift.Value(GchJsonHelper.parseString(sanitizedJson, 'type')),
      selectedTag: drift.Value(
        GchJsonHelper.optional<String>(
          sanitizedJson,
          'selected_tag',
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
      memo: drift.Value(
        GchJsonHelper.optional<String>(
          sanitizedJson,
          'memo',
          GchJsonHelper.parseString,
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
    );
  }

  @override
  Map<String, dynamic> toJson() {
    // ProxyGroup 通常只需要从 JSON 导入，不需要导出到服务器
    throw UnimplementedError('ProxyGroup toJson not implemented');
  }

  // ==================== GchJsonBatchConverter 实现 ====================

  @override
  List<GchNodeGroupTableCompanion> fromJsonList(List<dynamic> jsonList) {
    final results = <GchNodeGroupTableCompanion>[];

    for (final json in jsonList) {
      if (json is! Map<String, dynamic>) {
        print('⚠️ [ProxyGroup] 跳过非 Map 类型: ${json.runtimeType}');
        continue;
      }

      try {
        if (validate(json)) {
          results.add(fromJson(json));
        } else {
          print('⚠️ [ProxyGroup] 跳过验证失败: ${json['tag'] ?? 'unknown'}');
        }
      } catch (e) {
        print('❌ [ProxyGroup] 转换失败: $e, JSON: $json');
        // 继续处理其他数据
      }
    }

    return results;
  }

  @override
  List<Map<String, dynamic>> toJsonList(List<GchNodeGroupTableCompanion> items) {
    throw UnimplementedError('ProxyGroup batch toJson not implemented');
  }

  // ==================== GchJsonValidator 实现 ====================

  @override
  bool validate(Map<String, dynamic> json) {
    // 必填字段检查
    final requiredFields = ['id', 'tag', 'type'];
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

    // 分组类型枚举检查
    final validTypes = [
      'selector',
      'urltest',
      'fallback',
      'loadbalance',
      'relay',
      'direct',
      'reject',
      'dns',
    ];
    if (json.containsKey('type')) {
      final type = json['type']?.toString().toLowerCase();
      if (type != null && !validTypes.contains(type)) {
        print('⚠️ 警告: 未知的分组类型 "$type"（将继续处理）');
        // 不阻止导入，只是警告
      }
    }

    // 时间戳合法性检查
    if (json.containsKey('last_check') && json['last_check'] != null) {
      try {
        final timestamp = GchJsonHelper.parseInt(json, 'last_check');
        if (timestamp < 0) {
          print('验证失败: last_check 时间戳不能为负数');
          return false;
        }
      } catch (e) {
        print('验证失败: last_check 格式错误');
        return false;
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
        message: 'Cannot sanitize invalid ProxyGroup data',
        violations: _getViolations(json),
        json: json,
      );
    }

    final sanitized = Map<String, dynamic>.from(json);

    // 清洗字符串字段（去除空白）
    for (final key in ['id', 'tag', 'type', 'selected_tag', 'memo', 'role', 'tag_alias']) {
      if (sanitized[key] is String) {
        sanitized[key] = (sanitized[key] as String).trim();
      }
    }

    // 统一分组类型小写
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

    // 确保 lastUpdate 时间戳
    if (!sanitized.containsKey('last_update') || sanitized['last_update'] == null) {
      sanitized['last_update'] = DateTime.now().millisecondsSinceEpoch;
    }

    return sanitized;
  }

  // ==================== 辅助方法 ====================

  List<String> _getViolations(Map<String, dynamic> json) {
    final violations = <String>[];

    final requiredFields = ['id', 'tag', 'type'];
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        violations.add('缺少必填字段: $field');
      } else if (json[field] is String && (json[field] as String).isEmpty) {
        violations.add('字段 "$field" 不能为空字符串');
      }
    }

    if (json.containsKey('last_check') && json['last_check'] != null) {
      try {
        final timestamp = GchJsonHelper.parseInt(json, 'last_check');
        if (timestamp < 0) {
          violations.add('last_check 时间戳不能为负数');
        }
      } catch (e) {
        violations.add('last_check 格式错误');
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

/// ProxyGroup JSON 映射器（函数式版本）
///
/// 使用 Either 类型处理错误，避免异常抛出
class GchNodeGroupJsonMapperEither implements GchJsonEither<GchNodeGroupTableCompanion> {
  @override
  Either<GchJsonFailure, GchNodeGroupTableCompanion> fromEither(
    Map<String, dynamic> json,
  ) {
    // 验证必填字段
    final requiredFields = ['id', 'tag', 'type'];
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
      final companion = GchNodeGroupTableCompanion(
        id: drift.Value(json['id'] as String),
        tag: drift.Value(json['tag'] as String),
        type: drift.Value((json['type'] as String).toLowerCase()),
        selectedTag: drift.Value(json['selected_tag'] as String?),
        lastCheck: drift.Value(json['last_check'] as int?),
        lastUpdate: drift.Value(
          json['last_update'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
        memo: drift.Value(json['memo'] as String?),
        role: drift.Value(json['role'] as String? ?? 'free'),
        access: drift.Value(json['access'] as int? ?? 0),
        tagAlias: drift.Value(json['tag_alias'] as String? ?? json['tag'] as String),
      );

      return Right(companion);
    } catch (e) {
      return Left(GchJsonFailure.error(e.toString()));
    }
  }

  @override
  Either<GchJsonFailure, List<GchNodeGroupTableCompanion>> fromListEither(
    List<dynamic> jsonList,
  ) {
    final results = <GchNodeGroupTableCompanion>[];

    for (final json in jsonList) {
      if (json is! Map<String, dynamic>) {
        return Left(GchJsonFailure.invalidFormat('Expected Map<String, dynamic> but got ${json.runtimeType}'));
      }

      final result = fromEither(json);
      if (result.isLeft()) {
        return result.map((r) => <GchNodeGroupTableCompanion>[]);
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

/// GchNodeGroupTableCompanion 扩展
extension ProxyGroupCompanionExt on GchNodeGroupTableCompanion {
  /// 转换为 Map（用于调试）
  Map<String, dynamic> toDebugMap() {
    return {
      'id': id.present ? id.value : null,
      'tag': tag.present ? tag.value : null,
      'type': type.present ? type.value : null,
      'selectedTag': selectedTag.present ? selectedTag.value : null,
      'lastCheck': lastCheck.present ? lastCheck.value : null,
      'lastUpdate': lastUpdate.present ? lastUpdate.value : null,
      'memo': memo.present ? memo.value : null,
      'role': role.present ? role.value : null,
      'access': access.present ? access.value : null,
      'tagAlias': tagAlias.present ? tagAlias.value : null,
    };
  }
}
