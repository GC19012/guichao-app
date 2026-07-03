
/// KV 存储框架异常基类
class GchKvEx implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const GchKvEx(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => 'GchKvEx: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// 初始化异常
class GchKvInitEx extends GchKvEx {
  const GchKvInitEx(super.message, {super.cause, super.stackTrace});
}

/// 盒子操作异常
class GchKvBoxEx extends GchKvEx {
  const GchKvBoxEx(super.message, {super.cause, super.stackTrace});
}

/// 加密异常
class GchKvEncEx extends GchKvEx {
  const GchKvEncEx(super.message, {super.cause, super.stackTrace});
}

/// 类型不匹配异常
class GchKvTypeEx extends GchKvEx {
  const GchKvTypeEx(super.message, {super.cause, super.stackTrace});
}

/// 数据损坏异常
class GchKvCorruptEx extends GchKvEx {
  const GchKvCorruptEx(super.message, {super.cause, super.stackTrace});
}

/// 存储异常
class GchKvStorageEx extends GchKvEx {
  const GchKvStorageEx(super.message, {super.cause, super.stackTrace});
}

/// 并发异常
class GchKvConcEx extends GchKvEx {
  const GchKvConcEx(super.message, {super.cause, super.stackTrace});
}
