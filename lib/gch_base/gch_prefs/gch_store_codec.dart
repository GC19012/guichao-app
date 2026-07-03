// lib/core/gch_prefs/gch_store_codec.dart

import 'dart:convert';

/// 存储序列化器 - 处理对象和JSON之间的转换
class GchStoreCodec {
  
  /// JSON编码对象
  static String encodeJson(dynamic value) {
    try {
      return json.encode(value);
    } catch (e) {
      throw GchStoreCodecException('JSON编码失败: $e', value);
    }
  }
  
  /// JSON解码对象
  static T decodeJson<T>(String jsonString, T Function(Map<String, dynamic>) fromJson) {
    try {
      final decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return fromJson(decoded);
      } else {
        throw GchStoreCodecException('JSON解码结果不是Map类型', decoded);
      }
    } catch (e) {
      throw GchStoreCodecException('JSON解码失败: $e', jsonString);
    }
  }
  
  /// 编码对象为Map
  static Map<String, dynamic> encodeObject<T>(T value, Map<String, dynamic> Function(T)? toJson) {
    if (toJson != null) {
      try {
        return toJson(value);
      } catch (e) {
        throw GchStoreCodecException('对象序列化失败: $e', value);
      }
    }
    
    // 尝试自动转换
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is Map) {
      return value.cast<String, dynamic>();
    } else {
      // 尝试使用反射或toString作为最后手段
      throw GchStoreCodecException('无法序列化对象，请提供toJson方法', value);
    }
  }
  
  /// 编码List对象
  static List<Map<String, dynamic>> encodeList<T>(List<T> value, Map<String, dynamic> Function(T)? toJson) {
    return value.map((item) => encodeObject(item, toJson)).toList();
  }
  
  /// 解码List对象
  static List<T> decodeList<T>(List<dynamic> value, T Function(Map<String, dynamic>) fromJson) {
    return value.map((item) {
      if (item is Map<String, dynamic>) {
        return fromJson(item);
      } else if (item is Map) {
        return fromJson(item.cast<String, dynamic>());
      } else {
        throw GchStoreCodecException('List项目不是Map类型', item);
      }
    }).toList();
  }
  
  /// 验证是否为有效的JSON字符串
  static bool isValidJson(String value) {
    try {
      json.decode(value);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 安全的类型转换
  static T? safeCast<T>(dynamic value) {
    try {
      return value as T?;
    } catch (e) {
      return null;
    }
  }
  
  /// 深度复制对象（通过JSON序列化）
  static T deepCopy<T>(T value, T Function(Map<String, dynamic>) fromJson, Map<String, dynamic> Function(T) toJson) {
    try {
      final json = encodeObject(value, toJson);
      return fromJson(json);
    } catch (e) {
      throw GchStoreCodecException('深度复制失败: $e', value);
    }
  }
}

/// 存储序列化异常
class GchStoreCodecException implements Exception {
  final String message;
  final dynamic value;
  
  const GchStoreCodecException(this.message, this.value);
  
  @override
  String toString() => 'GchStoreCodecException: $message (value: $value)';
}

/// 序列化器接口 - 用于自定义序列化逻辑
abstract interface class Serializer<T> {
  /// 序列化对象为Map
  Map<String, dynamic> serialize(T value);
  
  /// 反序列化Map为对象
  T deserialize(Map<String, dynamic> data);
  
  /// 类型标识符
  String get typeId;
}

/// 内置的基础类型序列化器
class PrimitiveSerializers {
  
  /// String序列化器
  static final stringSerializer = _StringSerializer();
  
  /// int序列化器  
  static final intSerializer = _IntSerializer();
  
  /// bool序列化器
  static final boolSerializer = _BoolSerializer();
  
  /// double序列化器
  static final doubleSerializer = _DoubleSerializer();
  
  /// List<String>序列化器
  static final stringListSerializer = _StringListSerializer();
  
  /// 获取所有内置序列化器
  static List<Serializer> get all => [
    stringSerializer,
    intSerializer, 
    boolSerializer,
    doubleSerializer,
    stringListSerializer,
  ];
}

class _StringSerializer implements Serializer<String> {
  @override
  String get typeId => 'string';
  
  @override
  Map<String, dynamic> serialize(String value) => {'value': value};
  
  @override
  String deserialize(Map<String, dynamic> data) => data['value'] as String;
}

class _IntSerializer implements Serializer<int> {
  @override
  String get typeId => 'int';
  
  @override
  Map<String, dynamic> serialize(int value) => {'value': value};
  
  @override
  int deserialize(Map<String, dynamic> data) => data['value'] as int;
}

class _BoolSerializer implements Serializer<bool> {
  @override
  String get typeId => 'bool';
  
  @override
  Map<String, dynamic> serialize(bool value) => {'value': value};
  
  @override
  bool deserialize(Map<String, dynamic> data) => data['value'] as bool;
}

class _DoubleSerializer implements Serializer<double> {
  @override
  String get typeId => 'double';
  
  @override
  Map<String, dynamic> serialize(double value) => {'value': value};
  
  @override
  double deserialize(Map<String, dynamic> data) => data['value'] as double;
}

class _StringListSerializer implements Serializer<List<String>> {
  @override
  String get typeId => 'stringList';
  
  @override
  Map<String, dynamic> serialize(List<String> value) => {'value': value};
  
  @override
  List<String> deserialize(Map<String, dynamic> data) => 
      (data['value'] as List).cast<String>();
}