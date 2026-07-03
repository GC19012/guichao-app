import 'package:dio/dio.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_client/gch_api_client.dart';

/// 传输层响应类型 - 避免使用 dynamic
///
/// 使用 Object? 替代 dynamic，强制调用方进行类型检查
sealed class TransportResponse {
  const TransportResponse();
}

/// JSON Map 响应
class MapResponse extends TransportResponse {
  final Map<String, Object?> data;
  const MapResponse(this.data);
}

/// 字符串响应
class StringResponse extends TransportResponse {
  final String data;
  const StringResponse(this.data);
}

/// List 响应
class ListResponse extends TransportResponse {
  final List<Object?> data;
  const ListResponse(this.data);
}

/// 空响应
class EmptyResponse extends TransportResponse {
  const EmptyResponse();
}

/// 传输层接口 - 抽象网络协议
///
/// 支持 HTTP / gRPC / WebSocket 等实现
abstract interface class ConfigTransport {
  /// POST 请求
  ///
  /// 返回类型安全的 [TransportResponse]，调用方需通过模式匹配处理
  Future<TransportResponse> post(String url, Map<String, dynamic> data, {CancelToken? cancelToken});

  /// 下载文件
  ///
  /// [skipInterceptors] 跳过拦截器，用于外部URL（如S3）避免自定义header导致400错误
  Future<void> download(String url, String savePath, {CancelToken? cancelToken, bool skipInterceptors = false});
}

/// HTTP 传输实现（使用 DataApiClient，保留 middleware）
class HttpTransport implements ConfigTransport {
  HttpTransport({required this.client});

  final DataApiClient client;

  @override
  Future<TransportResponse> post(String url, Map<String, dynamic> data, {CancelToken? cancelToken}) async {
    final response = await client.post<Object?>(url, data: data, cancelToken: cancelToken);
    return _wrapResponse(response.data);
  }

  /// 将原始响应包装为类型安全的 TransportResponse
  TransportResponse _wrapResponse(Object? data) {
    if (data == null) {
      return const EmptyResponse();
    }
    if (data is String) {
      return StringResponse(data);
    }
    if (data is Map<String, Object?>) {
      return MapResponse(data);
    }
    // 处理 Map<String, dynamic> 的情况（Dio 常返回此类型）
    if (data is Map) {
      final safeMap = <String, Object?>{};
      for (final entry in data.entries) {
        if (entry.key is String) {
          safeMap[entry.key as String] = entry.value;
        }
      }
      return MapResponse(safeMap);
    }
    if (data is List) {
      return ListResponse(List<Object?>.from(data));
    }
    // 未知类型，转为字符串
    return StringResponse(data.toString());
  }

  @override
  Future<void> download(String url, String savePath, {CancelToken? cancelToken, bool skipInterceptors = false}) async {
    await client.httpClient.download(url, savePath, cancelToken: cancelToken, skipInterceptors: skipInterceptors);
  }
}
