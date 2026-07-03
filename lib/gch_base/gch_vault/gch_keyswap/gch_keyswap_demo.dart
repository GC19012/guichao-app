// gch_keyswap_demo.dart
// KeySwap服务使用示例

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:guichao/gch_base/gch_vault/gch_keyswap/gch_keyswap_svc.dart';

/// KeySwap使用示例
class GchKeySwapDemo {

  /// 基本使用流程示例
  static Future<void> basicUsageExample() async {
    const userId = 'user123';

    print('=== KeySwap基本使用示例 ===');

    // 1. 为用户生成密钥对
    print('1. 生成用户密钥对...');
    final userKeys = await GchKeySwapSvc.generateUserKeys(userId);
    if (userKeys == null) {
      print('密钥生成失败');
      return;
    }
    print('用户密钥对生成成功');
    print('   公钥: ${base64.encode(userKeys.publicKey)}');

    // 2. 模拟从服务器获取公钥（这里用假数据）
    print('\n2. 模拟服务器公钥交换...');
    final serverPublicKey = _generateMockServerPublicKey();
    print('   服务器公钥: ${base64.encode(serverPublicKey)}');

    // 3. 执行密钥交换
    print('\n3. 执行ECDH密钥交换...');
    final exchangedKeys = await GchKeySwapSvc.performKeyExchange(userId, serverPublicKey);
    if (exchangedKeys == null) {
      print('密钥交换失败');
      return;
    }
    print('密钥交换成功');
    print('   共享密钥已生成并保存');

    // 4. 加密文本
    const plaintext = 'Hello, ECDH Encryption!';
    final encryptedText = await GchKeySwapSvc.encryptText(userId, plaintext);
    if (encryptedText == null) {
      print('加密失败');
      return;
    }
    final decryptedText = await GchKeySwapSvc.decryptText(userId, encryptedText);
    if (decryptedText == null) {
      print('解密失败');
      return;
    }

  }

  /// 多用户示例
  static Future<void> multiUserExample() async {
    print('\n=== 多用户KeySwap示例 ===');

    final users = ['alice', 'bob', 'charlie'];

    // 为每个用户生成密钥
    for (final userId in users) {
      print('\n为用户 $userId 生成密钥...');
      final userKeys = await GchKeySwapSvc.generateUserKeys(userId);
      if (userKeys != null) {
        print('$userId 密钥生成成功');

        // 模拟密钥交换
        final serverKey = _generateMockServerPublicKey();
        final exchangedKeys = await GchKeySwapSvc.performKeyExchange(userId, serverKey);
        if (exchangedKeys != null) {
          print('$userId 密钥交换成功');

          // 测试加解密
          final plaintext = 'Hello from $userId';
          final encrypted = await GchKeySwapSvc.encryptText(userId, plaintext);
          if (encrypted != null) {
            final decrypted = await GchKeySwapSvc.decryptText(userId, encrypted);
            print('   加解密测试: ${decrypted == plaintext ? 'OK' : 'FAIL'}');
          }
        }
      }
    }
  }

  /// 错误处理示例
  static Future<void> errorHandlingExample() async {
    print('\n=== 错误处理示例 ===');

    const invalidUserId = 'nonexistent_user';

    // 1. 尝试加密但没有密钥
    print('1. 测试无密钥加密...');
    final result1 = await GchKeySwapSvc.encryptText(invalidUserId, 'test');
    print('   结果: ${result1 == null ? 'OK 正确返回null' : 'FAIL 应该返回null'}');

    // 2. 尝试解密无效数据
    print('2. 测试无效数据解密...');
    const userId = 'test_user';
    await GchKeySwapSvc.generateUserKeys(userId);
    final serverKey = _generateMockServerPublicKey();
    await GchKeySwapSvc.performKeyExchange(userId, serverKey);

    final result2 = await GchKeySwapSvc.decryptText(userId, 'invalid_base64_data');
    print('   结果: ${result2 == null ? 'OK 正确返回null' : 'FAIL 应该返回null'}');
  }

  /// 密钥管理示例
  static Future<void> keyManagementExample() async {
    print('\n=== 密钥管理示例 ===');

    const userId = 'management_test';

    // 1. 生成密钥
    print('1. 生成密钥...');
    await GchKeySwapSvc.generateUserKeys(userId);

    // 2. 检查密钥是否存在
    print('2. 检查密钥存在性...');
    final keys = await GchKeySwapSvc.getUserKeys(userId);
    print('   密钥存在: ${keys != null ? 'OK' : 'FAIL'}');

    // 3. 删除密钥
    print('3. 删除密钥...');
    final deleted = await GchKeySwapSvc.removeUserKeys(userId);
    print('   删除结果: ${deleted ? 'OK' : 'FAIL'}');

    // 4. 再次检查
    print('4. 再次检查密钥...');
    final keysAfterDelete = await GchKeySwapSvc.getUserKeys(userId);
    print('   密钥存在: ${keysAfterDelete == null ? 'OK 已删除' : 'FAIL 应该为null'}');

    // 5. 清理过期密钥
    print('5. 清理过期密钥...');
    final cleanedCount = await GchKeySwapSvc.cleanExpiredKeys();
    print('   清理数量: $cleanedCount');
  }

  /// 性能测试示例
  static Future<void> performanceExample() async {
    print('\n=== 性能测试示例 ===');

    const userId = 'perf_test';
    const testCount = 100;

    // 生成密钥
    await GchKeySwapSvc.generateUserKeys(userId);
    final serverKey = _generateMockServerPublicKey();
    await GchKeySwapSvc.performKeyExchange(userId, serverKey);

    // 加密性能测试
    print('测试 $testCount 次加密操作...');
    final encryptStart = DateTime.now();
    final encrypted = <String>[];

    for (int i = 0; i < testCount; i++) {
      final result = await GchKeySwapSvc.encryptText(userId, 'test message $i');
      if (result != null) encrypted.add(result);
    }

    final encryptTime = DateTime.now().difference(encryptStart);
    print('加密完成: ${encrypted.length}/$testCount 成功');
    print('   平均时间: ${encryptTime.inMicroseconds / testCount / 1000}ms per operation');

    // 解密性能测试
    print('\n测试 ${encrypted.length} 次解密操作...');
    final decryptStart = DateTime.now();
    int decryptSuccess = 0;

    for (final ciphertext in encrypted) {
      final result = await GchKeySwapSvc.decryptText(userId, ciphertext);
      if (result != null) decryptSuccess++;
    }

    final decryptTime = DateTime.now().difference(decryptStart);
    print('解密完成: $decryptSuccess/${encrypted.length} 成功');
    print('   平均时间: ${decryptTime.inMicroseconds / encrypted.length / 1000}ms per operation');
  }

  /// 生成模拟的服务器公钥（仅用于示例）
  /// 注意：生产环境中应该从服务器获取真实的ECDH公钥
  static Uint8List _generateMockServerPublicKey() {
    // 模拟P-256未压缩公钥格式 (65字节)
    final key = Uint8List(65);
    key[0] = 0x04; // 未压缩格式标识

    // 填充伪随机数据（仅用于演示，实际应使用真实服务器公钥）
    final random = Random.secure();
    for (int i = 1; i < 65; i++) {
      key[i] = random.nextInt(256);
    }
    return key;
  }
}

/// 运行所有示例
Future<void> runAllExamples() async {
  try {
    await GchKeySwapDemo.basicUsageExample();
    await GchKeySwapDemo.multiUserExample();
    await GchKeySwapDemo.errorHandlingExample();
    await GchKeySwapDemo.keyManagementExample();
    await GchKeySwapDemo.performanceExample();

    print('\n所有示例运行完成！');
  } catch (e) {
    print('示例运行出错: $e');
  }
}
