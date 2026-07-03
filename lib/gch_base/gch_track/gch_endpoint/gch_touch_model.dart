/// 操作系统枚举
enum GchTouchOS {
  ios,
  android,
}

/// 操作系统扩展
extension GchTouchOSExt on GchTouchOS {
  String get value {
    switch (this) {
      case GchTouchOS.ios:
        return 'ios';
      case GchTouchOS.android:
        return 'android';
    }
  }

  static GchTouchOS fromString(String value) {
    switch (value.toLowerCase()) {
      case 'ios':
        return GchTouchOS.ios;
      case 'android':
        return GchTouchOS.android;
      default:
        throw ArgumentError('Unknown OS: $value');
    }
  }
}

/// 触点上传请求
///
/// 用于记录用户行为的原始来源证据，支持匿名设备上传。
/// API Endpoint: POST /api/v1/public/touchpoints
class GchTouchRequest {
  /// 用户ID，可选，未提供则使用匿名ID
  final String? userId;

  /// 设备唯一标识（必填）
  final String deviceId;

  /// 操作类型（必填）：install, open, click 等
  final String action;

  /// 应用标识（必填）：bundleId 或 packageName
  final String app;

  /// 操作系统（必填）
  final GchTouchOS os;

  /// 安装渠道（必填）：appstore, official_website 等
  final String channel;

  /// 来源证据类型（必填）：install_referrer, universal_link, skan 等
  final String source;

  /// 幂等键（必填）：防重复提交
  final String idemKey;

  /// UTM 来源：google, telegram 等
  final String? src;

  /// UTM 媒介：cpc, social, kol 等
  final String? medium;

  /// UTM 活动名称
  final String? campaign;

  /// UTM 广告素材标识
  final String? content;

  /// UTM 搜索关键词
  final String? term;

  /// 点击ID
  final String? click;

  /// 原始 referrer 字符串
  final String? rawRef;

  /// 代理商/渠道商ID
  final String? agentId;

  /// 客户端记录时间
  final DateTime? clientTime;

  /// 扩展元数据
  final Map<String, dynamic>? meta;

  const GchTouchRequest({
    this.userId,
    required this.deviceId,
    required this.action,
    required this.app,
    required this.os,
    required this.channel,
    required this.source,
    required this.idemKey,
    this.src,
    this.medium,
    this.campaign,
    this.content,
    this.term,
    this.click,
    this.rawRef,
    this.agentId,
    this.clientTime,
    this.meta,
  });

  factory GchTouchRequest.fromJson(Map<String, dynamic> json) {
    return GchTouchRequest(
      userId: json['userid'] as String?,
      deviceId: json['device_id'] as String,
      action: json['action'] as String,
      app: json['app'] as String,
      os: GchTouchOSExt.fromString(json['os'] as String),
      channel: json['channel'] as String,
      source: json['source'] as String,
      idemKey: json['idem_key'] as String,
      src: json['src'] as String?,
      medium: json['medium'] as String?,
      campaign: json['campaign'] as String?,
      content: json['content'] as String?,
      term: json['term'] as String?,
      click: json['click'] as String?,
      rawRef: json['raw_ref'] as String?,
      agentId: json['agent_id'] as String?,
      clientTime: json['client_time'] != null
          ? DateTime.tryParse(json['client_time'] as String)
          : null,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'userid': userId,
      'device_id': deviceId,
      'action': action,
      'app': app,
      'os': os.value,
      'channel': channel,
      'source': source,
      'idem_key': idemKey,
      if (src != null) 'src': src,
      if (medium != null) 'medium': medium,
      if (campaign != null) 'campaign': campaign,
      if (content != null) 'content': content,
      if (term != null) 'term': term,
      if (click != null) 'click': click,
      if (rawRef != null) 'raw_ref': rawRef,
      if (agentId != null) 'agent_id': agentId,
      if (clientTime != null) 'client_time': clientTime!.toIso8601String(),
      if (meta != null) 'meta': meta,
    };
  }

  GchTouchRequest copyWith({
    String? userId,
    String? deviceId,
    String? action,
    String? app,
    GchTouchOS? os,
    String? channel,
    String? source,
    String? idemKey,
    String? src,
    String? medium,
    String? campaign,
    String? content,
    String? term,
    String? click,
    String? rawRef,
    String? agentId,
    DateTime? clientTime,
    Map<String, dynamic>? meta,
  }) {
    return GchTouchRequest(
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      action: action ?? this.action,
      app: app ?? this.app,
      os: os ?? this.os,
      channel: channel ?? this.channel,
      source: source ?? this.source,
      idemKey: idemKey ?? this.idemKey,
      src: src ?? this.src,
      medium: medium ?? this.medium,
      campaign: campaign ?? this.campaign,
      content: content ?? this.content,
      term: term ?? this.term,
      click: click ?? this.click,
      rawRef: rawRef ?? this.rawRef,
      agentId: agentId ?? this.agentId,
      clientTime: clientTime ?? this.clientTime,
      meta: meta ?? this.meta,
    );
  }
}

/// 触点上传响应
class GchTouchResponse {
  /// 是否成功
  final bool success;

  /// 响应消息
  final String? message;

  /// 触点ID（服务端生成）
  final String? touchpointId;

  /// 是否为更新操作（幂等键冲突时）
  final bool updated;

  const GchTouchResponse({
    this.success = false,
    this.message,
    this.touchpointId,
    this.updated = false,
  });

  factory GchTouchResponse.fromJson(Map<String, dynamic> json) {
    return GchTouchResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      touchpointId: json['touchpoint_id'] as String?,
      updated: json['updated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (touchpointId != null) 'touchpoint_id': touchpointId,
      'updated': updated,
    };
  }
}
