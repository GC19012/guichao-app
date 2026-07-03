// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:convert';
import 'dart:math';

// ──────────────────────────────────────────────
// GchJsonValidationResult
// ──────────────────────────────────────────────
class GchJsonValidationResult {
  final bool isValid;
  final List<String> errors;

  const GchJsonValidationResult({required this.isValid, required this.errors});

  @override
  String toString() =>
      isValid ? 'valid' : 'invalid: ${errors.join('; ')}';
}

// ──────────────────────────────────────────────
// GchJsonUtil
// ──────────────────────────────────────────────
class GchJsonUtil {
  GchJsonUtil._();

  static String prettyPrint(dynamic json, {int indent = 2}) {
    final encoder = JsonEncoder.withIndent(' ' * indent);
    return encoder.convert(json);
  }

  static String minify(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    return jsonEncode(decoded);
  }

  static dynamic get(dynamic json, String path) {
    if (path.isEmpty) return json;
    final parts = path.split('.');
    dynamic current = json;
    for (final part in parts) {
      if (current == null) return null;
      if (current is Map) {
        current = current[part];
      } else if (current is List) {
        final idx = int.tryParse(part);
        if (idx == null || idx < 0 || idx >= current.length) return null;
        current = current[idx];
      } else {
        return null;
      }
    }
    return current;
  }

  static Map<String, dynamic> set(
      Map<String, dynamic> json, String path, dynamic value) {
    final result = deepCopy<Map<String, dynamic>>(json);
    final parts = path.split('.');
    Map<String, dynamic> current = result;
    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (!current.containsKey(part) || current[part] is! Map) {
        current[part] = <String, dynamic>{};
      }
      current = current[part] as Map<String, dynamic>;
    }
    current[parts.last] = value;
    return result;
  }

  static Map<String, dynamic> delete(
      Map<String, dynamic> json, String path) {
    final result = deepCopy<Map<String, dynamic>>(json);
    final parts = path.split('.');
    Map<String, dynamic> current = result;
    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (!current.containsKey(part) || current[part] is! Map) return result;
      current = current[part] as Map<String, dynamic>;
    }
    current.remove(parts.last);
    return result;
  }

  static Map<String, dynamic> flatten(Map<String, dynamic> json,
      {String separator = '.'}) {
    final result = <String, dynamic>{};
    void traverse(dynamic value, String prefix) {
      if (value is Map<String, dynamic>) {
        for (final entry in value.entries) {
          final key = prefix.isEmpty ? entry.key : '$prefix$separator${entry.key}';
          traverse(entry.value, key);
        }
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          final key = prefix.isEmpty ? '$i' : '$prefix$separator$i';
          traverse(value[i], key);
        }
      } else {
        result[prefix] = value;
      }
    }
    traverse(json, '');
    return result;
  }

  static Map<String, dynamic> unflatten(Map<String, dynamic> flat,
      {String separator = '.'}) {
    final result = <String, dynamic>{};
    for (final entry in flat.entries) {
      final parts = entry.key.split(separator);
      Map<String, dynamic> current = result;
      for (int i = 0; i < parts.length - 1; i++) {
        final part = parts[i];
        if (!current.containsKey(part)) {
          current[part] = <String, dynamic>{};
        }
        current = current[part] as Map<String, dynamic>;
      }
      current[parts.last] = entry.value;
    }
    return result;
  }

  static Map<String, dynamic> merge(
      Map<String, dynamic> a, Map<String, dynamic> b) {
    final result = deepCopy<Map<String, dynamic>>(a);
    for (final entry in b.entries) {
      if (result.containsKey(entry.key) &&
          result[entry.key] is Map<String, dynamic> &&
          entry.value is Map<String, dynamic>) {
        result[entry.key] = merge(
            result[entry.key] as Map<String, dynamic>,
            entry.value as Map<String, dynamic>);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  static Map<String, dynamic> diff(dynamic a, dynamic b) {
    final result = <String, dynamic>{};
    if (a is Map<String, dynamic> && b is Map<String, dynamic>) {
      final allKeys = {...a.keys, ...b.keys};
      for (final key in allKeys) {
        if (!a.containsKey(key)) {
          result[key] = {'added': b[key]};
        } else if (!b.containsKey(key)) {
          result[key] = {'removed': a[key]};
        } else if (!isEqual(a[key], b[key])) {
          if (a[key] is Map<String, dynamic> && b[key] is Map<String, dynamic>) {
            result[key] = diff(a[key], b[key]);
          } else {
            result[key] = {'from': a[key], 'to': b[key]};
          }
        }
      }
    } else if (!isEqual(a, b)) {
      result['_'] = {'from': a, 'to': b};
    }
    return result;
  }

  static Map<String, dynamic> pick(
      Map<String, dynamic> json, List<String> keys) {
    final result = <String, dynamic>{};
    for (final key in keys) {
      if (json.containsKey(key)) result[key] = json[key];
    }
    return result;
  }

  static Map<String, dynamic> omit(
      Map<String, dynamic> json, List<String> keys) {
    final keySet = Set<String>.from(keys);
    return Map.fromEntries(
        json.entries.where((e) => !keySet.contains(e.key)));
  }

  static T deepCopy<T>(T value) {
    return jsonDecode(jsonEncode(value)) as T;
  }

  static bool isEqual(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!isEqual(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!isEqual(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  static T safeGet<T>(Map json, String key, T defaultValue) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is T) return value;
    return defaultValue;
  }

  static String toQueryString(Map<String, dynamic> params) {
    final pairs = <String>[];
    void encode(String prefix, dynamic value) {
      if (value is Map<String, dynamic>) {
        for (final e in value.entries) {
          encode(prefix.isEmpty ? e.key : '${prefix}[${e.key}]', e.value);
        }
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          encode('${prefix}[$i]', value[i]);
        }
      } else if (value != null) {
        pairs.add(
            '${Uri.encodeQueryComponent(prefix)}=${Uri.encodeQueryComponent('$value')}');
      }
    }
    encode('', params);
    // fix the first pair which would have = prefix
    return pairs.map((p) {
      final eqIdx = p.indexOf('=');
      final rawKey = Uri.decodeQueryComponent(p.substring(0, eqIdx));
      final rawVal = p.substring(eqIdx + 1);
      if (rawKey.startsWith('[') && rawKey.endsWith(']')) {
        return p;
      }
      return p;
    }).join('&');
  }

  static Map<String, String> fromQueryString(String query) {
    final result = <String, String>{};
    if (query.isEmpty) return result;
    final qs = query.startsWith('?') ? query.substring(1) : query;
    for (final pair in qs.split('&')) {
      final idx = pair.indexOf('=');
      if (idx < 0) {
        result[Uri.decodeQueryComponent(pair)] = '';
      } else {
        result[Uri.decodeQueryComponent(pair.substring(0, idx))] =
            Uri.decodeQueryComponent(pair.substring(idx + 1));
      }
    }
    return result;
  }

  static Map<String, dynamic> camelKeysToSnake(Map<String, dynamic> json) {
    String toSnake(String s) {
      final sb = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        final ch = s[i];
        if (ch.toUpperCase() == ch && ch != ch.toLowerCase() && i > 0) {
          sb.write('_');
        }
        sb.write(ch.toLowerCase());
      }
      return sb.toString();
    }

    Map<String, dynamic> convert(dynamic value) {
      if (value is Map<String, dynamic>) {
        return {
          for (final e in value.entries) toSnake(e.key): convert(e.value)
        };
      } else if (value is List) {
        return {'_': value.map(convert).toList()};
      }
      return {'_': value};
    }

    return {
      for (final e in json.entries) toSnake(e.key): _convertValue(e.value, camelKeysToSnake)
    };
  }

  static Map<String, dynamic> snakeKeysToCamel(Map<String, dynamic> json) {
    String toCamel(String s) {
      final parts = s.split('_');
      if (parts.length == 1) return s;
      return parts[0] +
          parts.sublist(1).map((p) {
            if (p.isEmpty) return p;
            return p[0].toUpperCase() + p.substring(1);
          }).join();
    }

    return {
      for (final e in json.entries)
        toCamel(e.key): _convertValue(e.value, snakeKeysToCamel)
    };
  }

  static dynamic _convertValue(dynamic value, Map<String, dynamic> Function(Map<String, dynamic>) mapConverter) {
    if (value is Map<String, dynamic>) return mapConverter(value);
    if (value is List) return value.map((e) => _convertValue(e, mapConverter)).toList();
    return value;
  }

  static Map<String, dynamic> filterNulls(Map<String, dynamic> json) {
    final result = <String, dynamic>{};
    for (final e in json.entries) {
      if (e.value == null) continue;
      if (e.value is Map<String, dynamic>) {
        result[e.key] = filterNulls(e.value as Map<String, dynamic>);
      } else {
        result[e.key] = e.value;
      }
    }
    return result;
  }

  static Map<String, dynamic> sortKeys(Map<String, dynamic> json) {
    final sorted = Map.fromEntries(
        json.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return sorted.map((key, value) {
      if (value is Map<String, dynamic>) return MapEntry(key, sortKeys(value));
      return MapEntry(key, value);
    });
  }

  static List<T> mapList<T>(
      List list, T Function(Map<String, dynamic>) mapper) {
    return list
        .whereType<Map<String, dynamic>>()
        .map(mapper)
        .toList();
  }

  static Map<String, List<Map<String, dynamic>>> groupBy<T>(
      List<Map<String, dynamic>> list, String key) {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final item in list) {
      final k = '${item[key]}';
      result.putIfAbsent(k, () => []).add(item);
    }
    return result;
  }

  static List sortList(List<Map<String, dynamic>> list, String key,
      {bool descending = false}) {
    final sorted = List<Map<String, dynamic>>.from(list);
    sorted.sort((a, b) {
      final av = a[key];
      final bv = b[key];
      int cmp;
      if (av is num && bv is num) {
        cmp = av.compareTo(bv);
      } else {
        cmp = '$av'.compareTo('$bv');
      }
      return descending ? -cmp : cmp;
    });
    return sorted;
  }

  static List<Map<String, dynamic>> unique(
      List<Map<String, dynamic>> list, String key) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final item in list) {
      final k = '${item[key]}';
      if (seen.add(k)) result.add(item);
    }
    return result;
  }

  static num sum(List<Map<String, dynamic>> list, String key) {
    num total = 0;
    for (final item in list) {
      final v = item[key];
      if (v is num) total += v;
    }
    return total;
  }

  static double avg(List<Map<String, dynamic>> list, String key) {
    if (list.isEmpty) return 0.0;
    return sum(list, key) / list.length;
  }

  static List<Map<String, dynamic>> flatMap(
      List<Map<String, dynamic>> list, String key) {
    final result = <Map<String, dynamic>>[];
    for (final item in list) {
      final v = item[key];
      if (v is List) {
        result.addAll(v.whereType<Map<String, dynamic>>());
      }
    }
    return result;
  }

  static List<Map<String, dynamic>> where(
      List<Map<String, dynamic>> list,
      bool Function(Map<String, dynamic>) predicate) {
    return list.where(predicate).toList();
  }

  static Map<String, dynamic>? findFirst(
      List<Map<String, dynamic>> list,
      bool Function(Map<String, dynamic>) predicate) {
    for (final item in list) {
      if (predicate(item)) return item;
    }
    return null;
  }

  static Map<bool, List<Map<String, dynamic>>> partition(
      List<Map<String, dynamic>> list,
      bool Function(Map<String, dynamic>) predicate) {
    final trueList = <Map<String, dynamic>>[];
    final falseList = <Map<String, dynamic>>[];
    for (final item in list) {
      if (predicate(item)) {
        trueList.add(item);
      } else {
        falseList.add(item);
      }
    }
    return {true: trueList, false: falseList};
  }

  static Map<String, dynamic> fromPairs(List<List<dynamic>> pairs) {
    return {for (final p in pairs) '${p[0]}': p.length > 1 ? p[1] : null};
  }

  static List<List<dynamic>> toPairs(Map<String, dynamic> json) {
    return json.entries.map((e) => [e.key, e.value]).toList();
  }

  static bool hasPath(Map<String, dynamic> json, String path) {
    final parts = path.split('.');
    dynamic current = json;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return false;
      }
    }
    return true;
  }

  static Map<String, dynamic> defaults(
      Map<String, dynamic> json, Map<String, dynamic> defaultValues) {
    final result = deepCopy<Map<String, dynamic>>(defaultValues);
    for (final e in json.entries) {
      if (!result.containsKey(e.key) || result[e.key] == null) {
        result[e.key] = e.value;
      } else {
        result[e.key] = e.value;
      }
    }
    return result;
  }

  static num min_(List<Map<String, dynamic>> list, String key) {
    if (list.isEmpty) return 0;
    num result = double.infinity;
    for (final item in list) {
      final v = item[key];
      if (v is num && v < result) result = v;
    }
    return result;
  }

  static num max_(List<Map<String, dynamic>> list, String key) {
    if (list.isEmpty) return 0;
    num result = double.negativeInfinity;
    for (final item in list) {
      final v = item[key];
      if (v is num && v > result) result = v;
    }
    return result;
  }
}

// ──────────────────────────────────────────────
// GchJsonSchema
// ──────────────────────────────────────────────
class GchJsonSchema {
  GchJsonSchema._();

  static GchJsonValidationResult validate(
      dynamic data, Map<String, dynamic> schema) {
    final errors = <String>[];
    _validateNode(data, schema, '', errors);
    return GchJsonValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  static void _validateNode(dynamic data, Map<String, dynamic> schema,
      String path, List<String> errors) {
    final label = path.isEmpty ? 'root' : path;

    // type check
    if (schema.containsKey('type')) {
      final expectedType = schema['type'] as String;
      if (!_checkType(data, expectedType)) {
        errors.add('$label: expected type $expectedType but got ${_typeName(data)}');
        return;
      }
    }

    // enum check
    if (schema.containsKey('enum')) {
      final allowed = schema['enum'] as List;
      if (!allowed.contains(data)) {
        errors.add('$label: value "$data" not in enum $allowed');
      }
    }

    // string constraints
    if (data is String) {
      if (schema.containsKey('minLength')) {
        final min = schema['minLength'] as int;
        if (data.length < min) {
          errors.add('$label: string length ${data.length} < minLength $min');
        }
      }
      if (schema.containsKey('maxLength')) {
        final max = schema['maxLength'] as int;
        if (data.length > max) {
          errors.add('$label: string length ${data.length} > maxLength $max');
        }
      }
      if (schema.containsKey('pattern')) {
        final pattern = schema['pattern'] as String;
        if (!RegExp(pattern).hasMatch(data)) {
          errors.add('$label: value "$data" does not match pattern $pattern');
        }
      }
    }

    // numeric constraints
    if (data is num) {
      if (schema.containsKey('min')) {
        final min = schema['min'] as num;
        if (data < min) errors.add('$label: value $data < min $min');
      }
      if (schema.containsKey('max')) {
        final max = schema['max'] as num;
        if (data > max) errors.add('$label: value $data > max $max');
      }
      if (schema.containsKey('multipleOf')) {
        final m = schema['multipleOf'] as num;
        if (m != 0 && data % m != 0) {
          errors.add('$label: $data is not a multiple of $m');
        }
      }
    }

    // object constraints
    if (data is Map<String, dynamic>) {
      if (schema.containsKey('required')) {
        final required = schema['required'] as List;
        for (final key in required) {
          if (!data.containsKey(key)) {
            errors.add('$label: required key "$key" missing');
          }
        }
      }
      if (schema.containsKey('properties')) {
        final props = schema['properties'] as Map<String, dynamic>;
        for (final entry in props.entries) {
          final childPath = path.isEmpty ? entry.key : '$path.${entry.key}';
          if (data.containsKey(entry.key)) {
            _validateNode(
                data[entry.key], entry.value as Map<String, dynamic>, childPath, errors);
          }
        }
      }
      if (schema.containsKey('minProperties')) {
        final min = schema['minProperties'] as int;
        if (data.length < min) {
          errors.add('$label: object has ${data.length} properties < minProperties $min');
        }
      }
      if (schema.containsKey('maxProperties')) {
        final max = schema['maxProperties'] as int;
        if (data.length > max) {
          errors.add('$label: object has ${data.length} properties > maxProperties $max');
        }
      }
    }

    // array constraints
    if (data is List) {
      if (schema.containsKey('minItems')) {
        final min = schema['minItems'] as int;
        if (data.length < min) {
          errors.add('$label: array length ${data.length} < minItems $min');
        }
      }
      if (schema.containsKey('maxItems')) {
        final max = schema['maxItems'] as int;
        if (data.length > max) {
          errors.add('$label: array length ${data.length} > maxItems $max');
        }
      }
      if (schema.containsKey('items')) {
        final itemSchema = schema['items'] as Map<String, dynamic>;
        for (int i = 0; i < data.length; i++) {
          _validateNode(data[i], itemSchema, '$label[$i]', errors);
        }
      }
      if (schema.containsKey('uniqueItems') && schema['uniqueItems'] == true) {
        final seen = <dynamic>[];
        for (final item in data) {
          if (seen.any((s) => GchJsonUtil.isEqual(s, item))) {
            errors.add('$label: array has duplicate items');
            break;
          }
          seen.add(item);
        }
      }
    }
  }

  static bool _checkType(dynamic data, String type) {
    switch (type) {
      case 'string':
        return data is String;
      case 'number':
        return data is num;
      case 'integer':
        return data is int;
      case 'boolean':
        return data is bool;
      case 'array':
        return data is List;
      case 'object':
        return data is Map;
      case 'null':
        return data == null;
      default:
        return true;
    }
  }

  static String _typeName(dynamic data) {
    if (data == null) return 'null';
    if (data is String) return 'string';
    if (data is int) return 'integer';
    if (data is double) return 'number';
    if (data is bool) return 'boolean';
    if (data is List) return 'array';
    if (data is Map) return 'object';
    return data.runtimeType.toString();
  }
}

// ──────────────────────────────────────────────
// GchJsonPath – JSONPath-like query engine
// ──────────────────────────────────────────────
class GchJsonPath {
  GchJsonPath._();

  static List<dynamic> query(dynamic json, String path) {
    final results = <dynamic>[];
    _query(json, _tokenize(path), 0, results);
    return results;
  }

  static List<String> _tokenize(String path) {
    if (path.startsWith('\$.')) {
      path = path.substring(2);
    } else if (path.startsWith('\$')) {
      path = path.substring(1);
    }
    final tokens = <String>[];
    var current = '';
    for (int i = 0; i < path.length; i++) {
      final ch = path[i];
      if (ch == '.') {
        if (current.isNotEmpty) tokens.add(current);
        current = '';
      } else if (ch == '[') {
        if (current.isNotEmpty) tokens.add(current);
        current = '';
        i++;
        final sb = StringBuffer();
        while (i < path.length && path[i] != ']') {
          sb.write(path[i]);
          i++;
        }
        tokens.add('[${sb}]');
      } else {
        current += ch;
      }
    }
    if (current.isNotEmpty) tokens.add(current);
    return tokens;
  }

  static void _query(dynamic node, List<String> tokens, int idx, List<dynamic> results) {
    if (idx >= tokens.length) {
      results.add(node);
      return;
    }
    final token = tokens[idx];
    if (token == '*') {
      if (node is Map<String, dynamic>) {
        for (final v in node.values) _query(v, tokens, idx + 1, results);
      } else if (node is List) {
        for (final v in node) _query(v, tokens, idx + 1, results);
      }
    } else if (token.startsWith('[') && token.endsWith(']')) {
      final inner = token.substring(1, token.length - 1);
      if (node is List) {
        final i = int.tryParse(inner);
        if (i != null && i >= 0 && i < node.length) {
          _query(node[i], tokens, idx + 1, results);
        }
      }
    } else if (token == '..') {
      results.addAll(query(node, tokens.sublist(idx + 1).join('.')));
      if (node is Map<String, dynamic>) {
        for (final v in node.values) {
          results.addAll(query(v, '\$.' + tokens.sublist(idx).join('.')));
        }
      } else if (node is List) {
        for (final v in node) {
          results.addAll(query(v, '\$.' + tokens.sublist(idx).join('.')));
        }
      }
    } else {
      if (node is Map && node.containsKey(token)) {
        _query(node[token], tokens, idx + 1, results);
      }
    }
  }

  static dynamic queryFirst(dynamic json, String path) {
    final results = query(json, path);
    return results.isEmpty ? null : results.first;
  }
}

// ──────────────────────────────────────────────
// GchJsonTransformer – pipeline-style transforms
// ──────────────────────────────────────────────
class GchJsonTransformer {
  final List<dynamic Function(dynamic)> _transforms = [];

  GchJsonTransformer filter(bool Function(dynamic) predicate) {
    _transforms.add((value) {
      if (value is List) return value.where(predicate).toList();
      return value;
    });
    return this;
  }

  GchJsonTransformer mapValues(dynamic Function(dynamic) mapper) {
    _transforms.add((value) {
      if (value is List) return value.map(mapper).toList();
      if (value is Map<String, dynamic>) {
        return value.map((k, v) => MapEntry(k, mapper(v)));
      }
      return mapper(value);
    });
    return this;
  }

  GchJsonTransformer pickKeys(List<String> keys) {
    _transforms.add((value) {
      if (value is Map<String, dynamic>) return GchJsonUtil.pick(value, keys);
      if (value is List) {
        return value.map((item) {
          if (item is Map<String, dynamic>) return GchJsonUtil.pick(item, keys);
          return item;
        }).toList();
      }
      return value;
    });
    return this;
  }

  GchJsonTransformer sortByKey(String key, {bool descending = false}) {
    _transforms.add((value) {
      if (value is List<Map<String, dynamic>>) {
        return GchJsonUtil.sortList(value, key, descending: descending);
      }
      return value;
    });
    return this;
  }

  GchJsonTransformer groupByKey(String key) {
    _transforms.add((value) {
      if (value is List<Map<String, dynamic>>) {
        return GchJsonUtil.groupBy(value, key);
      }
      return value;
    });
    return this;
  }

  dynamic apply(dynamic input) {
    dynamic result = input;
    for (final transform in _transforms) {
      result = transform(result);
    }
    return result;
  }
}

// ──────────────────────────────────────────────
// Test data constants and examples
// ──────────────────────────────────────────────
class GchJsonExamples {
  GchJsonExamples._();

  static final Map<String, dynamic> sampleUser = {
    'id': 1,
    'name': 'Alice',
    'email': 'alice@example.com',
    'age': 30,
    'address': {
      'street': '123 Main St',
      'city': 'Springfield',
      'country': 'US',
      'zip': '12345',
    },
    'tags': ['developer', 'admin'],
    'scores': [95, 87, 92, 78],
    'active': true,
  };

  static final Map<String, dynamic> userSchema = {
    'type': 'object',
    'required': ['id', 'name', 'email'],
    'properties': {
      'id': {'type': 'integer', 'min': 1},
      'name': {'type': 'string', 'minLength': 1, 'maxLength': 100},
      'email': {
        'type': 'string',
        'pattern': r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$'
      },
      'age': {'type': 'integer', 'min': 0, 'max': 150},
    },
  };

  static final List<Map<String, dynamic>> sampleList = [
    {'id': 1, 'name': 'Alice', 'score': 95, 'team': 'alpha'},
    {'id': 2, 'name': 'Bob', 'score': 82, 'team': 'beta'},
    {'id': 3, 'name': 'Charlie', 'score': 91, 'team': 'alpha'},
    {'id': 4, 'name': 'Diana', 'score': 87, 'team': 'gamma'},
    {'id': 5, 'name': 'Eve', 'score': 79, 'team': 'beta'},
  ];

  static void runAll() {
    _testJsonUtil();
    _testJsonSchema();
    _testJsonPath();
    _testTransformer();
  }

  static void _testJsonUtil() {
    print('=== GchJsonUtil ===');
    final pretty = GchJsonUtil.prettyPrint(sampleUser);
    print('Pretty:\n$pretty');

    final flat = GchJsonUtil.flatten(sampleUser);
    print('Flatten: $flat');

    final unflat = GchJsonUtil.unflatten(flat);
    print('Unflatten equals original: ${GchJsonUtil.isEqual(unflat, sampleUser)}');

    final cityVal = GchJsonUtil.get(sampleUser, 'address.city');
    print('Get address.city: $cityVal');

    final updated = GchJsonUtil.set(sampleUser, 'address.city', 'NewCity');
    print('Set city: ${GchJsonUtil.get(updated, 'address.city')}');

    final deleted = GchJsonUtil.delete(sampleUser, 'address.zip');
    print('Delete zip: ${deleted['address']}');

    final a = {'x': 1, 'y': {'a': 1, 'b': 2}};
    final b = {'y': {'b': 3, 'c': 4}, 'z': 5};
    print('Merge: ${GchJsonUtil.merge(a, b)}');
    print('Diff: ${GchJsonUtil.diff(a, b)}');

    print('Sum scores: ${GchJsonUtil.sum(sampleList, 'score')}');
    print('Avg scores: ${GchJsonUtil.avg(sampleList, 'score')}');
    print('Group by team: ${GchJsonUtil.groupBy(sampleList, 'team').keys}');
    print('Sort by score desc: ${GchJsonUtil.sortList(sampleList, 'score', descending: true).map((e) => e['name'])}');
    print('Unique by team: ${GchJsonUtil.unique(sampleList, 'team').length}');

    final qs = GchJsonUtil.toQueryString({'name': 'Alice', 'age': 30, 'active': true});
    print('Query string: $qs');
    print('From query string: ${GchJsonUtil.fromQueryString(qs)}');

    final snake = {'firstName': 'John', 'lastName': 'Doe', 'homeAddress': {'streetName': 'Main'}};
    print('Camel to snake: ${GchJsonUtil.camelKeysToSnake(snake)}');
  }

  static void _testJsonSchema() {
    print('\n=== GchJsonSchema ===');
    final valid = GchJsonSchema.validate(sampleUser, userSchema);
    print('Valid user: $valid');

    final invalid = GchJsonSchema.validate({'id': -1, 'name': '', 'email': 'bad'}, userSchema);
    print('Invalid user: $invalid');
  }

  static void _testJsonPath() {
    print('\n=== GchJsonPath ===');
    final cityResult = GchJsonPath.query(sampleUser, '\$.address.city');
    print('JsonPath \$.address.city: $cityResult');

    final nested = {
      'users': sampleList,
    };
    print('JsonPath \$.users[0]: ${GchJsonPath.query(nested, '\$.users[0]')}');
  }

  static void _testTransformer() {
    print('\n=== GchJsonTransformer ===');
    final result = GchJsonTransformer()
        .filter((item) => item is Map && (item['score'] as num) >= 85)
        .pickKeys(['name', 'score'])
        .sortByKey('score', descending: true)
        .apply(sampleList);
    print('Transformed: $result');
  }
}

// ignore: unused_element
final _usedMath = max(0, 0);
