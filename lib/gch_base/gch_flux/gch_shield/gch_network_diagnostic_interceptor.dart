import 'dart:io';

import 'package:dio/dio.dart';
import 'package:guichao/gch_aux/gch_log_mix.dart';

/// 网络诊断拦截器
/// 在请求失败时自动诊断 DNS 解析、TCP 连接、TLS 握手，帮助定位问题
class NetworkDiagnosticInterceptor extends Interceptor with GchInfraLogger {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 只对网络层错误做诊断（HandshakeException、SocketException 等）
    if (_isNetworkError(err)) {
      final uri = err.requestOptions.uri;
      loggy.error('═══ 网络诊断开始 ═══ ${uri.toString()}');
      loggy.error('错误类型: ${err.type}, 原始异常: ${err.error.runtimeType}: ${err.error}');

      await _diagnoseDns(uri.host);
      await _diagnoseTcp(uri.host, uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80));
      if (uri.scheme == 'https') {
        await _diagnoseTls(uri.host, uri.hasPort ? uri.port : 443);
      }
      await _diagnoseAlternateDns(uri.host);

      loggy.error('═══ 网络诊断结束 ═══');
    }

    handler.next(err);
  }

  bool _isNetworkError(DioException err) {
    final error = err.error;
    if (error is HandshakeException) return true;
    if (error is SocketException) return true;
    if (error is TlsException) return true;
    if (err.type == DioExceptionType.connectionError) return true;
    if (err.type == DioExceptionType.connectionTimeout) return true;
    // unknown 类型中也可能包含 HandshakeException
    if (err.type == DioExceptionType.unknown && error != null) {
      final msg = error.toString().toLowerCase();
      if (msg.contains('handshake') || msg.contains('socket') || msg.contains('tls')) {
        return true;
      }
    }
    return false;
  }

  /// 步骤1: 系统 DNS 解析
  Future<void> _diagnoseDns(String host) async {
    final sw = Stopwatch()..start();
    try {
      final addresses = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 5));
      sw.stop();
      final ips = addresses.map((a) => '${a.address} (${a.type.name})').join(', ');
      loggy.error('[DNS] ✅ $host -> [$ips] (${sw.elapsedMilliseconds}ms)');
    } on SocketException catch (e) {
      sw.stop();
      loggy.error('[DNS] ❌ 解析失败 $host: $e (${sw.elapsedMilliseconds}ms)');
    } catch (e) {
      sw.stop();
      loggy.error('[DNS] ❌ 解析异常 $host: ${e.runtimeType}: $e (${sw.elapsedMilliseconds}ms)');
    }
  }

  /// 步骤2: TCP 连接测试
  Future<void> _diagnoseTcp(String host, int port) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port,
          timeout: const Duration(seconds: 5));
      sw.stop();
      loggy.error('[TCP] ✅ $host:$port 连接成功 '
          '(本地=${socket.address.address}:${socket.port}, '
          '远端=${socket.remoteAddress.address}:${socket.remotePort}, '
          '${sw.elapsedMilliseconds}ms)');
      await socket.close();
    } on SocketException catch (e) {
      sw.stop();
      loggy.error('[TCP] ❌ $host:$port 连接失败: $e (${sw.elapsedMilliseconds}ms)');
    } catch (e) {
      sw.stop();
      loggy.error('[TCP] ❌ $host:$port 异常: ${e.runtimeType}: $e (${sw.elapsedMilliseconds}ms)');
    }
  }

  /// 步骤3: TLS 握手测试
  Future<void> _diagnoseTls(String host, int port) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await SecureSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
        onBadCertificate: (cert) {
          loggy.error('[TLS] ⚠️ 证书问题: '
              'subject=${cert.subject}, '
              'issuer=${cert.issuer}, '
              'validFrom=${cert.startValidity}, '
              'validTo=${cert.endValidity}');
          return false; // 不信任坏证书，只记录
        },
      );
      sw.stop();
      final cert = socket.peerCertificate;
      if (cert != null) {
        loggy.error('[TLS] ✅ $host:$port 握手成功 (${sw.elapsedMilliseconds}ms) '
            'subject=${cert.subject}, '
            'issuer=${cert.issuer}, '
            'validTo=${cert.endValidity}');
      } else {
        loggy.error('[TLS] ✅ $host:$port 握手成功 (${sw.elapsedMilliseconds}ms) 无证书信息');
      }
      await socket.close();
    } on HandshakeException catch (e) {
      sw.stop();
      loggy.error('[TLS] ❌ $host:$port 握手失败: $e (${sw.elapsedMilliseconds}ms)');
      loggy.error('[TLS] 提示: HandshakeException 常见原因: '
          '1) 中间人拦截(公共WiFi/运营商) '
          '2) DNS 被污染指向错误IP '
          '3) 服务器证书过期或配置错误 '
          '4) 客户端系统时间不正确 '
          '5) 代理/VPN 干扰');
    } on TlsException catch (e) {
      sw.stop();
      loggy.error('[TLS] ❌ $host:$port TLS异常: $e (${sw.elapsedMilliseconds}ms)');
    } catch (e) {
      sw.stop();
      loggy.error('[TLS] ❌ $host:$port 异常: ${e.runtimeType}: $e (${sw.elapsedMilliseconds}ms)');
    }
  }

  /// 步骤4: 用公共 DNS 做对比解析，判断是否 DNS 污染
  Future<void> _diagnoseAlternateDns(String host) async {
    // 尝试通过直连知名 IP 来判断基本网络连通性
    const targets = [
      ('8.8.8.8', 53, 'Google DNS'),
      ('1.1.1.1', 53, 'Cloudflare DNS'),
      ('223.5.5.5', 53, '阿里 DNS'),
    ];

    final results = <String>[];
    for (final (ip, port, name) in targets) {
      try {
        final socket = await Socket.connect(ip, port,
            timeout: const Duration(seconds: 3));
        await socket.close();
        results.add('$name($ip):✅');
      } catch (_) {
        results.add('$name($ip):❌');
      }
    }
    loggy.error('[网络连通性] ${results.join(', ')}');
  }
}
