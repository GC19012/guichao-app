// gch_keyswap_model.dart
// KeySwap简化模型 - 本地存储userid对应的密钥信息

import 'dart:convert';
import 'dart:typed_data';

// =============================================================================
// 核心模型
// =============================================================================

/// 用户ECDH密钥信息 - 本地存储模型
class GchUserKeys {
  final String userId;
  final Uint8List privateKey;        // 用户的ECDH私钥
  final Uint8List publicKey;         // 用户的ECDH公钥
  final Uint8List? serverPublicKey;  // 服务端的ECDH公钥
  final Uint8List? sharedKey;        // 通过ECDH计算得到的共享密钥
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? lastUsedAt;

  const GchUserKeys({
    required this.userId,
    required this.privateKey,
    required this.publicKey,
    this.serverPublicKey,
    this.sharedKey,
    required this.createdAt,
    this.expiresAt,
    this.lastUsedAt,
  });

  /// 检查密钥是否有效
  bool get isValid {
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return false;
    }
    return privateKey.isNotEmpty && publicKey.isNotEmpty;
  }

  /// 检查是否有服务端公钥
  bool get hasServerPublicKey => serverPublicKey != null && serverPublicKey!.isNotEmpty;

  /// 检查是否有共享密钥
  bool get hasSharedKey => sharedKey != null && sharedKey!.isNotEmpty;

  /// 检查是否可以进行密钥交换（有服务端公钥但没有共享密钥）
  bool get canComputeSharedKey => hasServerPublicKey && !hasSharedKey;

  /// 获取密钥年龄
  Duration get age => DateTime.now().difference(createdAt);

  /// 获取剩余有效时间
  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 更新服务端公钥
  GchUserKeys withServerPublicKey(Uint8List newServerPublicKey) {
    return GchUserKeys(
      userId: userId,
      privateKey: privateKey,
      publicKey: publicKey,
      serverPublicKey: newServerPublicKey,
      sharedKey: sharedKey, // 保持现有共享密钥
      createdAt: createdAt,
      expiresAt: expiresAt,
      lastUsedAt: DateTime.now(),
    );
  }

  /// 更新共享密钥
  GchUserKeys withSharedKey(Uint8List newSharedKey) {
    return GchUserKeys(
      userId: userId,
      privateKey: privateKey,
      publicKey: publicKey,
      serverPublicKey: serverPublicKey,
      sharedKey: newSharedKey,
      createdAt: createdAt,
      expiresAt: expiresAt,
      lastUsedAt: DateTime.now(),
    );
  }

  /// 同时更新服务端公钥和共享密钥
  GchUserKeys withServerKeyAndSharedKey(Uint8List newServerPublicKey, Uint8List newSharedKey) {
    return GchUserKeys(
      userId: userId,
      privateKey: privateKey,
      publicKey: publicKey,
      serverPublicKey: newServerPublicKey,
      sharedKey: newSharedKey,
      createdAt: createdAt,
      expiresAt: expiresAt,
      lastUsedAt: DateTime.now(),
    );
  }

  /// 更新最后使用时间
  GchUserKeys updateLastUsed() {
    return GchUserKeys(
      userId: userId,
      privateKey: privateKey,
      publicKey: publicKey,
      serverPublicKey: serverPublicKey,
      sharedKey: sharedKey,
      createdAt: createdAt,
      expiresAt: expiresAt,
      lastUsedAt: DateTime.now(),
    );
  }

  /// 序列化为JSON（用于安全存储）
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'privateKey': base64.encode(privateKey),
      'publicKey': base64.encode(publicKey),
      'serverPublicKey': serverPublicKey != null ? base64.encode(serverPublicKey!) : null,
      'sharedKey': sharedKey != null ? base64.encode(sharedKey!) : null,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  /// 从JSON反序列化
  factory GchUserKeys.fromJson(Map<String, dynamic> json) {
    return GchUserKeys(
      userId: json['userId'] as String,
      privateKey: base64.decode(json['privateKey'] as String),
      publicKey: base64.decode(json['publicKey'] as String),
      serverPublicKey: json['serverPublicKey'] != null
          ? base64.decode(json['serverPublicKey'] as String)
          : null,
      sharedKey: json['sharedKey'] != null
          ? base64.decode(json['sharedKey'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'GchUserKeys(userId: $userId, age: ${age.inHours}h, '
           'hasServerKey: $hasServerPublicKey, hasSharedKey: $hasSharedKey, isValid: $isValid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GchUserKeys && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

/// 密钥交换请求
class GchKeySwapRequest {
  final String userId;
  final Uint8List clientPublicKey;
  final Duration? expirationTime;

  const GchKeySwapRequest({
    required this.userId,
    required this.clientPublicKey,
    this.expirationTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'clientPublicKey': base64.encode(clientPublicKey),
      'expirationTime': expirationTime?.inMilliseconds,
    };
  }

  factory GchKeySwapRequest.fromJson(Map<String, dynamic> json) {
    return GchKeySwapRequest(
      userId: json['userId'] as String,
      clientPublicKey: base64.decode(json['clientPublicKey'] as String),
      expirationTime: json['expirationTime'] != null
          ? Duration(milliseconds: json['expirationTime'] as int)
          : null,
    );
  }
}

/// 密钥交换响应
class GchKeySwapResponse {
  final String userId;
  final Uint8List serverPublicKey;
  final DateTime expiresAt;

  const GchKeySwapResponse({
    required this.userId,
    required this.serverPublicKey,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'serverPublicKey': base64.encode(serverPublicKey),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory GchKeySwapResponse.fromJson(Map<String, dynamic> json) {
    return GchKeySwapResponse(
      userId: json['userId'] as String,
      serverPublicKey: base64.decode(json['serverPublicKey'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

// =============================================================================
// 配置和异常
// =============================================================================

/// KeySwap服务配置
class GchKeySwapConfig {
  final Duration defaultKeyTTL;
  final Duration maxKeyAge;
  final bool enableKeyCache;
  final int maxCachedKeys;
  final bool autoCleanExpiredKeys;

  const GchKeySwapConfig({
    this.defaultKeyTTL = const Duration(hours: 24),
    this.maxKeyAge = const Duration(days: 7),
    this.enableKeyCache = true,
    this.maxCachedKeys = 100,
    this.autoCleanExpiredKeys = true,
  });

  /// 高安全性配置
  static const highSecurity = GchKeySwapConfig(
    defaultKeyTTL: Duration(hours: 6),
    maxKeyAge: Duration(days: 1),
    maxCachedKeys: 50,
  );

  /// 高性能配置
  static const highPerformance = GchKeySwapConfig(
    defaultKeyTTL: Duration(days: 2),
    maxKeyAge: Duration(days: 30),
    maxCachedKeys: 200,
    autoCleanExpiredKeys: false,
  );
}

/// KeySwap异常
class GchKeySwapException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  const GchKeySwapException(this.message, this.code, {this.originalError});

  @override
  String toString() => 'GchKeySwapException[$code]: $message';

  // 常见异常类型
  static const keyGenerationFailed = GchKeySwapException(
    '密钥生成失败',
    'KEY_GENERATION_FAILED'
  );

  static const keyNotFound = GchKeySwapException(
    '未找到用户密钥',
    'KEY_NOT_FOUND'
  );

  static const keyExpired = GchKeySwapException(
    '密钥已过期',
    'KEY_EXPIRED'
  );

  static const serverKeyMissing = GchKeySwapException(
    '缺少服务端公钥',
    'SERVER_KEY_MISSING'
  );

  static const sharedSecretFailed = GchKeySwapException(
    '共享密钥计算失败',
    'SHARED_SECRET_FAILED'
  );

  static const encryptionFailed = GchKeySwapException(
    '加密操作失败',
    'ENCRYPTION_FAILED'
  );

  static const decryptionFailed = GchKeySwapException(
    '解密操作失败',
    'DECRYPTION_FAILED'
  );
}

// =============================================================================
// 统计和状态
// =============================================================================

/// KeySwap服务统计信息
class GchKeySwapStats {
  final int totalUsers;
  final int activeKeys;
  final int expiredKeys;
  final int keysWithServerPublicKey;
  final int keysWithSharedKey;
  final int totalKeyExchanges;
  final int totalEncryptions;
  final int totalDecryptions;
  final int cacheHits;
  final int cacheMisses;
  final DateTime? lastKeyGeneration;
  final DateTime? lastKeyCleanup;

  const GchKeySwapStats({
    required this.totalUsers,
    required this.activeKeys,
    required this.expiredKeys,
    required this.keysWithServerPublicKey,
    required this.keysWithSharedKey,
    required this.totalKeyExchanges,
    required this.totalEncryptions,
    required this.totalDecryptions,
    required this.cacheHits,
    required this.cacheMisses,
    this.lastKeyGeneration,
    this.lastKeyCleanup,
  });

  double get cacheHitRate {
    final total = cacheHits + cacheMisses;
    return total > 0 ? cacheHits / total : 0.0;
  }

  double get serverKeyRate {
    return totalUsers > 0 ? keysWithServerPublicKey / totalUsers : 0.0;
  }

  double get sharedKeyRate {
    return totalUsers > 0 ? keysWithSharedKey / totalUsers : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'activeKeys': activeKeys,
      'expiredKeys': expiredKeys,
      'keysWithServerPublicKey': keysWithServerPublicKey,
      'keysWithSharedKey': keysWithSharedKey,
      'totalKeyExchanges': totalKeyExchanges,
      'totalEncryptions': totalEncryptions,
      'totalDecryptions': totalDecryptions,
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'cacheHitRate': cacheHitRate,
      'serverKeyRate': serverKeyRate,
      'sharedKeyRate': sharedKeyRate,
      'lastKeyGeneration': lastKeyGeneration?.toIso8601String(),
      'lastKeyCleanup': lastKeyCleanup?.toIso8601String(),
    };
  }
}
