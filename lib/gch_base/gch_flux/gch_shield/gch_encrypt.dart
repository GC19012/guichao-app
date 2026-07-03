import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guichao/gch_base/gch_vault/gch_keyswap/gch_keyswap_svc.dart';
import 'package:guichao/gch_base/gch_biz/gch_api/gch_providers/gch_api_client_providers.dart';

/// ECDH加密拦截器 - 集成KeySwap服务
class ECDHCryptoInterceptor extends Interceptor {
  String _userId;
  final String keyExchangeUrl;
  Uint8List? _serverPublicKey;
  int _retryCount = 0;  // 重试计数器
  static const int _maxRetries = 1;  // 最大重试次数
  bool _enabled = true;
  bool _debug;
  final void Function(String message)? _logger;
  final Map<String, dynamic> _customHeaders = {};

  ECDHCryptoInterceptor({
    required String userId,
    required this.keyExchangeUrl,
    bool enabled = true,
    bool debug = false,
    void Function(String message)? logger,
  }) : _userId = userId, _enabled = enabled, _debug = debug, _logger = logger;

  /// 启用/禁用拦截器
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// 获取启用状态
  bool get isEnabled => _enabled;

  /// 获取当前用户ID
  String get userId => _userId;

  /// 设置新的用户ID（会清理密钥缓存并重新进行密钥交换）
  void setUserId(String newUserId) {
    if (_userId != newUserId) {
      _log('用户ID变更: $_userId -> $newUserId');
      _userId = newUserId;
      _serverPublicKey = null; // 清理旧的服务端公钥
      _retryCount = 0; // 重置重试计数器
      _log('已清理密钥缓存，下次请求将重新进行密钥交换');
    }
  }

  /// 设置自定义请求头
  void setHeader(String key, dynamic value) {
    _customHeaders[key] = value;
    _log('设置自定义请求头: $key = $value');
  }

  /// 批量设置请求头
  void setHeaders(Map<String, dynamic> headers) {
    _customHeaders.addAll(headers);
    _log('批量设置请求头: ${headers.keys.join(', ')}');
  }

  /// 移除指定请求头
  void removeHeader(String key) {
    _customHeaders.remove(key);
    _log('移除请求头: $key');
  }

  /// 清除所有自定义请求头
  void clearHeaders() {
    _customHeaders.clear();
    _log('清除所有自定义请求头');
  }

  /// 获取所有自定义请求头
  Map<String, dynamic> get customHeaders => Map.unmodifiable(_customHeaders);

  /// 清除所有配置
  void clear() {
    _serverPublicKey = null;
    _customHeaders.clear();
    _retryCount = 0;
    _log('清除所有配置和缓存');
  }

  void _log(String message) {
    if (_debug) {
      if (_logger != null) {
        _logger(message);
      } else {
        print('[ECDHCrypto] $message');
      }
    }
  }

  /// 公共的加密处理函数 - 包括密钥获取和数据加密
  Future<bool> _performEncryption(RequestOptions options, {bool forceRefresh = false}) async {
    try {
      // 1. 确保有服务端公钥
      if (forceRefresh || _serverPublicKey == null) {
        if (!await _fetchServerKey(forceRefresh: forceRefresh)) {
          _log('无法获取服务端公钥');
          return false;
        }
      }

      // 2. 准备加密数据
      final plainText = options.data is String ?
        options.data as String : jsonEncode(options.data);

      _log('开始ECDH加密，原文长度: ${plainText.length}');

      // 3. 执行加密 - 异步执行避免长时间阻塞
      String? encrypted;
      await Future.delayed(Duration.zero, () async {
        encrypted = await GchKeySwapSvc.encryptWithServerKey(_userId, plainText, _serverPublicKey!);
      });

      if (encrypted != null) {
        // 加密成功，更新请求数据
        options.data = {'data': encrypted};
        options.headers['Content-Type'] = 'application/json';

        // 应用自定义请求头
        if (_customHeaders.isNotEmpty) {
          options.headers.addAll(_customHeaders);
          _log('已应用 ${_customHeaders.length} 个自定义请求头');
        }

        _log('ECDH加密成功');
        return true;
      } else {
        _log('ECDH加密失败');
        return false;
      }
    } catch (e) {
      _log('加密处理异常: $e');
      return false;
    }
  }

  /// 带重试机制的加密处理
  Future<bool> _performEncryptionWithRetry(RequestOptions options) async {
    // 第一次尝试
    if (await _performEncryption(options)) {
      return true;
    }

    // 加密失败，尝试重新获取密钥
    _log('ECDH加密失败，尝试重新交换密钥...');
    _serverPublicKey = null;

    // 第二次尝试（强制刷新）
    if (await _performEncryption(options, forceRefresh: true)) {
      _log('密钥重新交换成功，加密成功');
      return true;
    }

    _log('ECDH加密最终失败');
    return false;
  }

  /// 统一的密钥获取函数
  Future<bool> _fetchServerKey({bool forceRefresh = false}) async {
    try {
      // 如果不是强制刷新，先尝试从本地获取
      if (!forceRefresh) {
        var userKeys = await GchKeySwapSvc.getUserKeys(_userId);
        if (userKeys != null && userKeys.serverPublicKey != null) {
          _serverPublicKey = userKeys.serverPublicKey;
          _log('使用本地缓存的服务端公钥');
          return true;
        }
      }

      return await _fetchServerKeyFromNetwork(forceRefresh);
    } catch (e) {
      _log('密钥获取异常: $e');
      return false;
    }
  }

  /// 从网络获取服务端公钥 - 使用专用的keyExchangeApiClient
  Future<bool> _fetchServerKeyFromNetwork(bool forceRefresh) async {
    try {
      _log('开始从网络获取服务端公钥...');

      if (forceRefresh) {
        await GchKeySwapSvc.removeUserKeys(_userId);
        _log('已清除旧密钥');
      }

      var userKeys = await GchKeySwapSvc.generateUserKeys(_userId);
      if (userKeys == null) {
        _log('客户端密钥生成失败');
        return false;
      }

      // 使用现有的apiClient，但临时禁用ECDH验证
      final container = ProviderContainer();
      final apiClient = container.read(apiClientProvider);

      // 临时禁用ECDH加密
      apiClient.setECDHEnabled(false);

      try {
        final response = await apiClient.post(
          keyExchangeUrl,
          data: {
            'userid': _userId,
            'client_public_key': base64.encode(userKeys.publicKey),
            'key_type': 'permanent',
            'expiration_hours': 0,
          },
        );

        if (response.statusCode == 200 &&
            response.data != null &&
            response.data['success'] == true &&
            response.data['data'] != null &&
            response.data['data']['server_public_key_base64'] != null) {
          final serverPublicKeyStr = response.data['data']['server_public_key_base64'] as String;
          _serverPublicKey = base64.decode(serverPublicKeyStr);
          _log('服务端公钥获取成功，长度: ${_serverPublicKey!.length}');
          return true;
        }

        _log('服务端公钥获取失败: ${response.statusCode}');
        return false;
      } finally {
        // 恢复ECDH状态 - 重新启用加密
        apiClient.setECDHEnabled(true);
        container.dispose();
      }
    } catch (e) {
      _log('网络获取密钥异常: $e');
      return false;
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _handleRequestAsync(options, handler);
  }

  Future<void> _handleRequestAsync(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_enabled) {
      // 即使拦截器禁用，也应用自定义请求头
      if (_customHeaders.isNotEmpty) {
        options.headers.addAll(_customHeaders);
        _log('已应用 ${_customHeaders.length} 个自定义请求头（拦截器禁用）');
      }
      handler.next(options);
      return;
    }

    try {
      // 只处理有body的请求
      if (options.data != null && ['POST', 'PUT', 'PATCH'].contains(options.method.toUpperCase())) {
        // 使用公共的加密处理函数（带重试机制）
        if (!await _performEncryptionWithRetry(options)) {
          _log('加密失败，使用原始数据');
          // 即使加密失败也应用自定义请求头
          if (_customHeaders.isNotEmpty) {
            options.headers.addAll(_customHeaders);
            _log('已应用 ${_customHeaders.length} 个自定义请求头（加密失败）');
          }
        }
      } else {
        // 不需要加密的请求也应用自定义请求头
        if (_customHeaders.isNotEmpty) {
          options.headers.addAll(_customHeaders);
          _log('已应用 ${_customHeaders.length} 个自定义请求头（无需加密）');
        }
      }
    } catch (e) {
      _log('请求加密异常: $e');
      // 异常情况下也应用自定义请求头
      if (_customHeaders.isNotEmpty) {
        options.headers.addAll(_customHeaders);
        _log('已应用 ${_customHeaders.length} 个自定义请求头（异常情况）');
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _handleResponseAsync(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _handleErrorAsync(err, handler);
  }

  Future<void> _handleErrorAsync(DioException err, ErrorInterceptorHandler handler) async {
    // 检测ECDH认证失败（400错误）且未超过重试次数
    if (_enabled && err.response?.statusCode == 400 && _retryCount < _maxRetries) {
      _log('检测到400错误，可能是ECDH认证失败，尝试重试 (${_retryCount + 1}/$_maxRetries)');

      _retryCount++; // 增加重试计数

      // 清理密钥缓存
      _serverPublicKey = null;
      await GchKeySwapSvc.removeUserKeys(_userId);

      try {
        final originalRequest = err.requestOptions;

        // 对有body的请求重新加密
        if (originalRequest.data != null && ['POST', 'PUT', 'PATCH'].contains(originalRequest.method.toUpperCase())) {
          // 使用带重试机制的加密处理函数
          if (await _performEncryption(originalRequest, forceRefresh: true))  {
            _log('密钥重新获取成功，重试请求');

            // 使用 ProviderContainer 需要确保在所有路径都释放
            ProviderContainer? container;
            try {
              // 使用Provider获取配置好的API客户端
              container = ProviderContainer();
              final apiClient = container.read(apiClientProvider);

              // 根据请求方法类型重新发起请求
              late final Response response;
              final method = originalRequest.method.toUpperCase();

              switch (method) {
                case 'POST':
                  response = await apiClient.post(
                    originalRequest.uri.toString(),
                    data: originalRequest.data,
                    queryParameters: originalRequest.queryParameters,
                  );
                  break;
                case 'PUT':
                  response = await apiClient.put(
                    originalRequest.uri.toString(),
                    data: originalRequest.data,
                    queryParameters: originalRequest.queryParameters,
                  );
                  break;
                case 'DELETE':
                  response = await apiClient.delete(
                    originalRequest.uri.toString(),
                    data: originalRequest.data,
                    queryParameters: originalRequest.queryParameters,
                  );
                  break;
                case 'GET':
                  response = await apiClient.get(
                    originalRequest.uri.toString(),
                    queryParameters: originalRequest.queryParameters,
                  );
                  break;
                default:
                  throw UnsupportedError('不支持的HTTP方法: $method');
              }

              _retryCount = 0; // 重置计数器
              handler.resolve(response); // 返回成功响应
              return;
            } catch (httpError) {
              _log('使用API客户端重试失败: $httpError');
            } finally {
              // 确保在所有路径都释放 container
              container?.dispose();
              _log('ProviderContainer 已释放');
            }
          }
        }
      } catch (retryError) {
        _log('重试失败: $retryError');
      }
    }

    // 超过重试次数或其他错误，重置计数器
    if (err.response?.statusCode == 400) {
      _retryCount = 0;
    }

    handler.next(err);
  }

  Future<void> _handleResponseAsync(Response response, ResponseInterceptorHandler handler) async {
    if (!_enabled) {
      handler.next(response);
      return;
    }

    try {
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;

        if (responseMap['data'] is String) {
          final encryptedData = responseMap['data'] as String;
          _log('开始ECDH解密，密文长度: ${encryptedData.length}');

          // 异步执行但不阻塞UI
          String? decrypted;
          await Future.delayed(Duration.zero, () async {
            decrypted = await GchKeySwapSvc.decryptWithUserKey(_userId, encryptedData);
          });

          if (decrypted != null) {
            // 大数据JSON解析优化：异步处理避免阻塞
            if (decrypted!.length > 10000) {
              await Future.delayed(Duration.zero, () {
                try {
                  responseMap['data'] = jsonDecode(decrypted!);
                  _log('ECDH大数据解密成功，解析为JSON');
                } catch (_) {
                  responseMap['data'] = decrypted!;
                  _log('ECDH大数据解密成功，保持字符串');
                }
              });
            } else {
              try {
                responseMap['data'] = jsonDecode(decrypted!);
                _log('ECDH解密成功，解析为JSON');
              } catch (_) {
                responseMap['data'] = decrypted!;
                _log('ECDH解密成功，保持字符串');
              }
            }
            response.data = responseMap;
          } else {
            _log('ECDH解密失败');
          }
        }
      }
    } catch (e) {
      _log('响应解密异常: $e');
    }

    handler.next(response);
  }
}
