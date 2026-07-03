/// Supabase 服务端错误码分类
///
/// 基于 Supabase GoTrue 服务端错误码定义
/// https://github.com/supabase/gotrue
class GchFuwuqiCuowuma {
  GchFuwuqiCuowuma._();

  /// 认证凭证类
  static const credential = [
    'invalid_credentials',
    'user_not_found',
    'weak_password',
    'same_password',
    'bad_jwt',
    'decrypt_jwt',
  ];

  /// 账号存在性类
  static const existence = [
    'user_already_exists',
    'email_exists',
    'phone_exists',
    'identity_already_exists',
  ];

  /// 验证状态类
  static const verification = [
    'email_not_confirmed',
    'phone_not_confirmed',
    'provider_email_needs_verification',
    'email_address_not_authorized',
    'email_address_invalid',
  ];

  /// OTP/验证码类
  static const otp = [
    'otp_expired',
    'otp_disabled',
    'captcha_failed',
    'bad_code_verifier',
  ];

  /// 会话类
  static const session = [
    'session_expired',
    'session_not_found',
    'refresh_token_not_found',
    'refresh_token_already_used',
    'flow_state_not_found',
    'flow_state_expired',
    'reauthentication_needed',
    'reauthentication_not_valid',
  ];

  /// 账号状态类
  static const accountStatus = [
    'signup_disabled',
    'user_banned',
    'user_sso_managed',
  ];

  /// 频率限制类
  static const rateLimit = [
    'over_request_rate_limit',
    'over_email_send_rate_limit',
    'over_sms_send_rate_limit',
  ];

  /// 发送失败类
  static const sendFailed = [
    'sms_send_failed',
  ];

  /// OAuth类
  static const oauth = [
    'bad_oauth_state',
    'bad_oauth_callback',
    'oauth_provider_not_supported',
    'provider_disabled',
    'email_provider_disabled',
    'phone_provider_disabled',
    'anonymous_provider_disabled',
  ];

  /// MFA类
  static const mfa = [
    'mfa_challenge_expired',
    'mfa_verification_failed',
    'mfa_verification_rejected',
    'mfa_factor_not_found',
    'mfa_factor_name_conflict',
    'mfa_ip_address_mismatch',
    'too_many_enrolled_mfa_factors',
    'insufficient_aal',
    'mfa_phone_enroll_not_enabled',
    'mfa_phone_verify_not_enabled',
    'mfa_totp_enroll_not_enabled',
    'mfa_totp_verify_not_enabled',
    'mfa_webauthn_enroll_not_enabled',
    'mfa_webauthn_verify_not_enabled',
    'mfa_verified_factor_exists',
  ];

  /// SSO/SAML类
  static const sso = [
    'sso_provider_not_found',
    'sso_domain_already_exists',
    'saml_provider_disabled',
    'saml_relay_state_not_found',
    'saml_relay_state_expired',
    'saml_idp_not_found',
    'saml_idp_already_exists',
    'saml_assertion_no_user_id',
    'saml_assertion_no_email',
    'saml_metadata_fetch_failed',
    'saml_entity_id_mismatch',
  ];

  /// 系统/通用类
  static const system = [
    'unknown',
    'unexpected_failure',
    'validation_failed',
    'bad_json',
    'no_authorization',
    'not_admin',
    'request_timeout',
    'conflict',
    'hook_timeout',
    'hook_timeout_after_retry',
    'hook_payload_over_size_limit',
    'hook_payload_invalid_content_type',
    'network_error',
    'supabase_not_initialized',
  ];

  /// 注册成功提示类（特殊：用于显示成功消息）
  static const signupSuccess = [
    'signup_success_email_verify',
    'signup_success_phone_verify',
    'signup_success_verify',
  ];

  /// OAuth 自定义错误类
  static const oauthCustom = [
    'oauth_cancelled',
    'oauth_config_error',
    'pkce_expired',
    'auth_timeout',
  ];

  /// 注册流程消息类
  static const registration = [
    'otp_sent_email',
    'otp_sent_phone',
    'otp_resent',
    'user_exists_otp_resent',
    'agreement_required',
    'email_required',
    'phone_required',
    'phone_invalid',
    'password_required',
  ];

  /// 密码重置流程消息类
  static const passwordReset = [
    'otp_required',
    'otp_invalid_length',
    'password_reset_success',
  ];

  /// OTP 发送相关消息类
  static const otpSend = [
    'otp_countdown_active',
    'captcha_required',
    'otp_send_failed',
  ];


  /// 身份管理类
  static const identity = [
    'identity_not_found',
    'single_identity_not_deletable',
    'email_conflict_identity_not_deletable',
    'manual_linking_disabled',
    'invite_not_found',
    'unexpected_audience',
  ];

  /// 所有错误码（扁平列表）
  static List<String> get all => [
    ...credential,
    ...existence,
    ...verification,
    ...otp,
    ...session,
    ...accountStatus,
    ...rateLimit,
    ...sendFailed,
    ...oauth,
    ...mfa,
    ...sso,
    ...system,
    ...identity,
    ...signupSuccess,
    ...oauthCustom,
    ...registration,
    ...passwordReset,
    ...otpSend,
  ];
}
