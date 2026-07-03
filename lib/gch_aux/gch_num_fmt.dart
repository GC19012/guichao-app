extension ByteFormatter on int {
  String size() {
    final b = toDouble();
    if (b < 1024) return '${b.toStringAsFixed(0)} B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KiB';
    if (b < 1024 * 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(2)} MiB';
    return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GiB';
  }

  String sizeGB() => '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GiB';

  String sizeOf(int total) => '${sizeGB()} / ${total.sizeGB()}';

  String speed() {
    final b = toDouble();
    if (b < 1024) return '${b.toStringAsFixed(0)} B/s';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB/s';
    if (b < 1024 * 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB/s';
  }
}
