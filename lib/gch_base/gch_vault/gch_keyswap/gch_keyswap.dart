// gch_keyswap.dart
// KeySwap模块导出文件

/// ECDH椭圆曲线密钥交换实现
///
/// 基于P-256曲线实现ECDH密钥交换和AES-256-GCM加解密
///
/// 主要功能：
/// - 生成P-256密钥对
/// - ECDH密钥交换
/// - AES-256-GCM加解密
/// - 安全密钥存储
/// - 多用户密钥管理
///
/// 使用示例：
/// ```dart
/// // 1. 生成用户密钥
/// final userKeys = await GchKeySwapSvc.generateUserKeys('user123');
///
/// // 2. 密钥交换（获取服务器公钥后）
/// final exchangedKeys = await GchKeySwapSvc.performKeyExchange('user123', serverPublicKey);
///
/// // 3. 加密文本
/// final encrypted = await GchKeySwapSvc.encryptText('user123', 'Hello World');
///
/// // 4. 解密文本
/// final decrypted = await GchKeySwapSvc.decryptText('user123', encrypted);
/// ```

export 'gch_keyswap_svc.dart';
export 'gch_keyswap_demo.dart';
export 'gch_key_vault.dart';
export 'gch_keyswap_model.dart';
