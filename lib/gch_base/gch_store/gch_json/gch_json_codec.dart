/// JSON 序列化核心接口定义
///
/// 提供统一的 JSON 转换、验证和清洗能力
/// 用于 API 数据与本地存储（Realm/SQLite）之间的转换
///
/// 【设计理念】
/// - 类型安全：编译时检查，避免运行时错误
/// - 职责分离：序列化、批量转换、验证各司其职
/// - 易于扩展：新增实体只需实现接口
/// - 存储无关：适用于 Realm 和 SQLite
library;

import 'package:fpdart/fpdart.dart';

// ==================== 核心接口定义 ====================

/// JSON 可序列化接口
///
/// 所有需要从 JSON 转换的模型都应实现此接口
///
/// 【使用场景】
/// - API 响应 → Domain Model
/// - Domain Model → API 请求
/// - 本地持久化的序列化/反序列化
///
/// 【类型参数】
/// - [T] 目标类型（如 ProductEntriesCompanion、UserEntry）
///
/// 【示例】
/// ```dart
/// class ProductGchJsonMapper implements GchJsonSerializable<ProductEntriesCompanion> {
///   @override
///   ProductEntriesCompanion fromJson(Map<String, dynamic> json) {
///     return ProductEntriesCompanion(
///       id: Value(json['id'] as int),
///       title: Value(json['title'] as String),
///     );
///   }
///
///   @override
///   Map<String, dynamic> toJson() {
///     // 通常用于将 Domain Model 转换为 API 请求
///     throw UnimplementedError();
///   }
/// }
/// ```
abstract class GchJsonSerializable<T> {
  /// 从 JSON Map 创建实例
  ///
  /// [json] 原始 JSON 数据（通常来自 API 响应）
  ///
  /// 返回类型安全的目标对象
  ///
  /// 抛出 [GchJsonConversionError] 如果转换失败
  T fromJson(Map<String, dynamic> json);

  /// 转换为 JSON Map
  ///
  /// 将对象序列化为 JSON（通常用于 API 请求）
  ///
  /// 返回可序列化的 Map
  Map<String, dynamic> toJson();
}

// ==================== 批量转换接口 ====================

/// JSON 批量转换器接口
///
/// 提供高效的批量数据转换能力
///
/// 【性能优化】
/// - 单次事务批量插入
/// - 减少函数调用开销
/// - 支持进度回调
///
/// 【类型参数】
/// - [T] 目标类型
///
/// 【示例】
/// ```dart
/// class ProductGchJsonMapper implements GchJsonBatchConverter<ProductEntriesCompanion> {
///   @override
///   List<ProductEntriesCompanion> fromJsonList(List<dynamic> jsonList) {
///     return jsonList
///         .whereType<Map<String, dynamic>>()
///         .map((json) => fromJson(json))
///         .toList();
///   }
/// }
/// ```
abstract class GchJsonBatchConverter<T> {
  /// 批量从 JSON 转换
  ///
  /// [jsonList] JSON 数组（通常来自 API 的列表响应）
  ///
  /// 返回转换后的对象列表
  ///
  /// 【错误处理】
  /// - 遇到无效数据会跳过，不会中断整个流程
  /// - 可以通过 [strict] 参数控制是否严格模式（抛出异常）
  List<T> fromJsonList(List<dynamic> jsonList);

  /// 批量转换为 JSON
  ///
  /// [items] 待转换的对象列表
  ///
  /// 返回 JSON 数组
  List<Map<String, dynamic>> toJsonList(List<T> items);
}

// ==================== 验证和清洗接口 ====================

/// JSON 验证接口
///
/// 提供数据验证和清洗能力，确保数据质量
///
/// 【验证策略】
/// 1. 必填字段检查
/// 2. 类型合法性检查
/// 3. 业务规则验证（如价格非负）
/// 4. 引用完整性检查（如外键存在性）
///
/// 【清洗策略】
/// 1. 修复常见格式错误（如大小写）
/// 2. 填充默认值
/// 3. 去除多余空白
/// 4. 类型强制转换
///
/// 【示例】
/// ```dart
/// class ProductGchJsonValidator implements GchJsonValidator {
///   @override
///   bool validate(Map<String, dynamic> json) {
///     if (!json.containsKey('id')) return false;
///     if (json['price'] < 0) return false;
///     return true;
///   }
///
///   @override
///   Map<String, dynamic> sanitize(Map<String, dynamic> json) {
///     final cleaned = Map<String, dynamic>.from(json);
///     cleaned['title'] = (cleaned['title'] as String).trim();
///     cleaned['currency'] = (cleaned['currency'] as String).toUpperCase();
///     return cleaned;
///   }
/// }
/// ```
abstract class GchJsonValidator {
  /// 验证 JSON 数据是否有效
  ///
  /// [json] 待验证的 JSON 数据
  ///
  /// 返回 true 表示数据有效，false 表示无效
  ///
  /// 【验证内容】
  /// - 必填字段存在性
  /// - 字段类型正确性
  /// - 业务规则合法性
  bool validate(Map<String, dynamic> json);

  /// 清洗 JSON 数据（修复常见错误）
  ///
  /// [json] 原始 JSON 数据
  ///
  /// 返回清洗后的 JSON 数据
  ///
  /// 抛出 [GchJsonValidationError] 如果数据无法修复
  ///
  /// 【清洗操作】
  /// - 去除空白字符
  /// - 统一大小写格式
  /// - 填充默认值
  /// - 类型转换（如 "123" → 123）
  Map<String, dynamic> sanitize(Map<String, dynamic> json);
}

// ==================== 高级接口：组合能力 ====================

/// 完整的 JSON 映射器接口
///
/// 组合序列化、批量转换、验证三大能力
///
/// 【推荐】实体的 JSON 映射器应实现此接口
///
/// 【示例】
/// ```dart
/// class ProductGchJsonMapper implements GchJsonMapper<ProductEntriesCompanion> {
///   // 同时实现三个接口的所有方法
/// }
/// ```
abstract class GchJsonMapper<T>
    implements GchJsonSerializable<T>, GchJsonBatchConverter<T>, GchJsonValidator {}

// ==================== 函数式编程接口 ====================

/// 函数式 JSON 转换器
///
/// 使用 fpdart 的 Either 类型处理错误，避免异常抛出
///
/// 【优势】
/// - 显式错误处理
/// - 可组合的转换管道
/// - 类型安全的错误信息
///
/// 【示例】
/// ```dart
/// class ProductFunctionalMapper implements GchJsonEither<ProductEntriesCompanion> {
///   @override
///   Either<GchJsonFailure, ProductEntriesCompanion> fromEither(
///     Map<String, dynamic> json,
///   ) {
///     if (!json.containsKey('id')) {
///       return Left(GchJsonFailure.missingField('id'));
///     }
///
///     try {
///       final companion = ProductEntriesCompanion(
///         id: Value(json['id'] as int),
///       );
///       return Right(companion);
///     } catch (e) {
///       return Left(GchJsonFailure.error(e.toString()));
///     }
///   }
/// }
///
/// // 使用示例
/// final result = mapper.fromEither(json);
/// result.fold(
///   (failure) => print('转换失败: ${failure.message}'),
///   (product) => print('转换成功: $product'),
/// );
/// ```
abstract class GchJsonEither<T> {
  /// Either 方式的 JSON 转换（返回 Either）
  ///
  /// [json] 原始 JSON 数据
  ///
  /// 返回 Either<Failure, T>
  /// - Left: 转换失败，包含错误信息
  /// - Right: 转换成功，包含目标对象
  Either<GchJsonFailure, T> fromEither(Map<String, dynamic> json);

  /// Either 方式的批量转换
  ///
  /// [jsonList] JSON 数组
  ///
  /// 返回 Either<Failure, List<T>>
  /// - Left: 批量转换失败（任意一个失败）
  /// - Right: 所有项转换成功
  Either<GchJsonFailure, List<T>> fromListEither(
    List<dynamic> jsonList,
  ) {
    try {
      final results = <T>[];
      for (final json in jsonList) {
        if (json is! Map<String, dynamic>) {
          return Left(
            GchJsonFailure.invalidFormat('Expected Map, got ${json.runtimeType}'),
          );
        }

        final result = fromEither(json);
        if (result.isLeft()) {
          return Left(result.getLeft().toNullable()!);
        }

        results.add(result.getRight().toNullable()!);
      }

      return Right(results);
    } catch (e) {
      return Left(GchJsonFailure.error(e.toString()));
    }
  }
}

// ==================== 异常定义 ====================

/// JSON 转换异常
///
/// 所有 JSON 转换相关的异常都继承此类
sealed class GchJsonException implements Exception {
  final String message;
  final Map<String, dynamic>? json;
  final StackTrace? stackTrace;

  const GchJsonException(this.message, {this.json, this.stackTrace});

  @override
  String toString() => 'GchJsonException: $message';
}

/// JSON 转换异常
///
/// 在 fromJson 过程中发生的错误
class GchJsonConversionError extends GchJsonException {
  final String field;
  final Object? value;
  final Type expectedType;

  const GchJsonConversionError({
    required String message,
    required this.field,
    this.value,
    required this.expectedType,
    Map<String, dynamic>? json,
    StackTrace? stackTrace,
  }) : super(message, json: json, stackTrace: stackTrace);

  @override
  String toString() =>
      'GchJsonConversionError: Field "$field" - Expected $expectedType, got ${value.runtimeType}. $message';
}

/// JSON 验证异常
///
/// 数据验证失败时抛出
class GchJsonValidationError extends GchJsonException {
  final List<String> violations;

  const GchJsonValidationError({
    required String message,
    required this.violations,
    Map<String, dynamic>? json,
  }) : super(message, json: json);

  @override
  String toString() =>
      'GchJsonValidationError: $message\nViolations:\n${violations.map((v) => '  - $v').join('\n')}';
}

// ==================== 函数式错误类型 ====================

/// JSON 转换失败（函数式编程）
///
/// 用于 Either 的 Left 值，表示转换失败的原因
sealed class GchJsonFailure {
  final String message;

  const GchJsonFailure(this.message);

  /// 缺少必填字段
  factory GchJsonFailure.missingField(String fieldName) =
      GchMissingField;

  /// 字段类型错误
  factory GchJsonFailure.wrongType({
    required String fieldName,
    required Type expectedType,
    required Type actualType,
  }) = GchWrongType;

  /// 数据格式错误
  factory GchJsonFailure.invalidFormat(String reason) =
      GchInvalidFormat;

  /// 验证失败
  factory GchJsonFailure.validation(List<String> violations) =
      GchValidationError;

  /// 转换错误
  factory GchJsonFailure.error(String error) =
      GchConversionError;

  @override
  String toString() => 'GchJsonFailure: $message';
}

/// 缺少必填字段
class GchMissingField extends GchJsonFailure {
  final String fieldName;

  GchMissingField(this.fieldName)
      : super('Missing required field: $fieldName');
}

/// 字段类型错误
class GchWrongType extends GchJsonFailure {
  final String fieldName;
  final Type expectedType;
  final Type actualType;

  GchWrongType({
    required this.fieldName,
    required this.expectedType,
    required this.actualType,
  }) : super(
          'Field "$fieldName" has wrong type. Expected $expectedType, got $actualType',
        );
}

/// 数据格式错误
class GchInvalidFormat extends GchJsonFailure {
  GchInvalidFormat(String reason) : super('Invalid format: $reason');
}

/// 验证失败
class GchValidationError extends GchJsonFailure {
  final List<String> violations;

  GchValidationError(this.violations)
      : super('Validation failed: ${violations.join(', ')}');
}

/// 转换错误
class GchConversionError extends GchJsonFailure {
  GchConversionError(String error) : super('Conversion error: $error');
}

// ==================== 辅助工具类 ====================

/// JSON 解析辅助工具
///
/// 提供常用的类型安全解析方法
///
/// 【使用示例】
/// ```dart
/// class ProductGchJsonMapper {
///   ProductEntriesCompanion fromJson(Map<String, dynamic> json) {
///     return ProductEntriesCompanion(
///       id: Value(GchJsonHelper.parseInt(json, 'id')),
///       price: Value(GchJsonHelper.parseDouble(json, 'price')),
///       title: Value(GchJsonHelper.parseString(json, 'title')),
///     );
///   }
/// }
/// ```
class GchJsonHelper {
  GchJsonHelper._();

  /// 解析整数
  static int parseInt(Map<String, dynamic> json, String key,
      {int? defaultValue}) {
    if (!json.containsKey(key)) {
      if (defaultValue != null) return defaultValue;
      throw GchJsonConversionError(
        message: 'Missing required field',
        field: key,
        expectedType: int,
        json: json,
      );
    }

    final value = json[key];
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        throw GchJsonConversionError(
          message: 'Cannot parse string to int',
          field: key,
          value: value,
          expectedType: int,
          json: json,
        );
      }
    }

    throw GchJsonConversionError(
      message: 'Invalid type',
      field: key,
      value: value,
      expectedType: int,
      json: json,
    );
  }

  /// 解析双精度浮点数
  static double parseDouble(Map<String, dynamic> json, String key,
      {double? defaultValue}) {
    if (!json.containsKey(key)) {
      if (defaultValue != null) return defaultValue;
      throw GchJsonConversionError(
        message: 'Missing required field',
        field: key,
        expectedType: double,
        json: json,
      );
    }

    final value = json[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        throw GchJsonConversionError(
          message: 'Cannot parse string to double',
          field: key,
          value: value,
          expectedType: double,
          json: json,
        );
      }
    }

    throw GchJsonConversionError(
      message: 'Invalid type',
      field: key,
      value: value,
      expectedType: double,
      json: json,
    );
  }

  /// 解析字符串
  static String parseString(Map<String, dynamic> json, String key,
      {String? defaultValue}) {
    if (!json.containsKey(key)) {
      if (defaultValue != null) return defaultValue;
      throw GchJsonConversionError(
        message: 'Missing required field',
        field: key,
        expectedType: String,
        json: json,
      );
    }

    final value = json[key];
    if (value is String) return value;

    throw GchJsonConversionError(
      message: 'Invalid type',
      field: key,
      value: value,
      expectedType: String,
      json: json,
    );
  }

  /// 解析布尔值
  static bool parseBool(Map<String, dynamic> json, String key,
      {bool? defaultValue}) {
    if (!json.containsKey(key)) {
      if (defaultValue != null) return defaultValue;
      throw GchJsonConversionError(
        message: 'Missing required field',
        field: key,
        expectedType: bool,
        json: json,
      );
    }

    final value = json[key];
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }

    throw GchJsonConversionError(
      message: 'Invalid type',
      field: key,
      value: value,
      expectedType: bool,
      json: json,
    );
  }

  /// 解析日期时间
  static DateTime parseDateTime(Map<String, dynamic> json, String key,
      {DateTime? defaultValue}) {
    if (!json.containsKey(key)) {
      if (defaultValue != null) return defaultValue;
      throw GchJsonConversionError(
        message: 'Missing required field',
        field: key,
        expectedType: DateTime,
        json: json,
      );
    }

    final value = json[key];
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        throw GchJsonConversionError(
          message: 'Cannot parse string to DateTime',
          field: key,
          value: value,
          expectedType: DateTime,
          json: json,
        );
      }
    }
    if (value is int) {
      // Unix 时间戳（秒）
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }

    throw GchJsonConversionError(
      message: 'Invalid type',
      field: key,
      value: value,
      expectedType: DateTime,
      json: json,
    );
  }

  /// 解析可选字段
  static T? optional<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>, String) parser,
  ) {
    if (!json.containsKey(key) || json[key] == null) {
      return null;
    }

    return parser(json, key);
  }

  /// 解析列表
  static List<T> parseList<T>(
    Map<String, dynamic> json,
    String key,
    T Function(dynamic) itemParser, {
    List<T>? defaultValue,
  }) {
    if (!json.containsKey(key)) {
      if (defaultValue != null) return defaultValue;
      throw GchJsonConversionError(
        message: 'Missing required field',
        field: key,
        expectedType: List<T>,
        json: json,
      );
    }

    final value = json[key];
    if (value is! List) {
      throw GchJsonConversionError(
        message: 'Invalid type',
        field: key,
        value: value,
        expectedType: List<T>,
        json: json,
      );
    }

    return value.map((item) => itemParser(item)).toList();
  }
}
