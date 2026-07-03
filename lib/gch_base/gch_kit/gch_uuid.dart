DateTime uuidV7ToDateTime(String uuidV7) {
  // 1. 移除 UUID 中的连字符 '-'
  final strippedUuid = uuidV7.replaceAll('-', '');

  // 2. 提取前 48 位 (12 个十六进制字符)
  if (strippedUuid.length < 12) {
    throw ArgumentError('UUID v7 格式不正确，至少需要 12 个十六进制字符。');
  }
  final timestampHex = strippedUuid.substring(0, 12);

  // 3. 将 48 位的十六进制数转换为十进制的毫秒数
  BigInt timestampBigInt;
  try {
    timestampBigInt = BigInt.parse(timestampHex, radix: 16);
  } catch (e) {
    throw FormatException('无法解析时间戳十六进制部分: $timestampHex');
  }

  // 4. 转换为 int 毫秒数 (用于 DateTime.fromMillisecondsSinceEpoch)
  final timestampMilliseconds = timestampBigInt.toInt();

  // 5. 转换为 UTC DateTime 对象
  return DateTime.fromMillisecondsSinceEpoch(
    timestampMilliseconds,
    isUtc: true,
  );
}

String uuidV7ToDateTimeString(String uuidV7, {bool useLocalTime = false}) {
  final dateTime = uuidV7ToDateTime(uuidV7);
  final dt = useLocalTime ? dateTime.toLocal() : dateTime;

  return '${dt.year}'
      '${dt.month.toString().padLeft(2, '0')}'
      '${dt.day.toString().padLeft(2, '0')}'
      '${dt.hour.toString().padLeft(2, '0')}'
      '${dt.minute.toString().padLeft(2, '0')}'
      '${dt.second.toString().padLeft(2, '0')}';
}
