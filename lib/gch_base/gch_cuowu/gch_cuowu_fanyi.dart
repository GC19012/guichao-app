import 'package:guichao/gch_gen/gch_text.dart';
import 'fuwuqi/gch_fuwuqi_cuowuma.dart';

/// 服务端错误码本地化工具
class GchCuowuFanyi {
  GchCuowuFanyi._();

  /// 根据错误码获取本地化消息
  static String huoquBendiXiaoxi(String code, [dynamic _]) {
    return switch (code) {
      'unknown' => GchText.serverErrorsUnknown,
      'unexpected_failure' => GchText.serverErrorsUnexpectedFailure,
      'network_error' => GchText.serverErrorsNetworkError,
      'request_timeout' => GchText.serverErrorsRequestTimeout,
      'validation_failed' => GchText.serverErrorsValidationFailed,
      'bad_json' => GchText.serverErrorsBadJson,
      'conflict' => GchText.serverErrorsConflict,
      'invalid_credentials' => GchText.serverErrorsInvalidCredentials,
      'user_not_found' => GchText.serverErrorsUserNotFound,
      'weak_password' => GchText.serverErrorsWeakPassword,
      'same_password' => GchText.serverErrorsSamePassword,
      'bad_jwt' => GchText.serverErrorsBadJwt,
      'user_already_exists' => GchText.serverErrorsUserAlreadyExists,
      'email_exists' => GchText.serverErrorsEmailExists,
      'phone_exists' => GchText.serverErrorsPhoneExists,
      'identity_already_exists' => GchText.serverErrorsIdentityAlreadyExists,
      'email_not_confirmed' => GchText.serverErrorsEmailNotConfirmed,
      'phone_not_confirmed' => GchText.serverErrorsPhoneNotConfirmed,
      'provider_email_needs_verification' => GchText.serverErrorsProviderEmailNeedsVerification,
      'email_address_not_authorized' => GchText.serverErrorsEmailAddressNotAuthorized,
      'email_address_invalid' => GchText.serverErrorsEmailAddressInvalid,
      'otp_expired' => GchText.serverErrorsOtpExpired,
      'otp_disabled' => GchText.serverErrorsOtpDisabled,
      'captcha_failed' => GchText.serverErrorsCaptchaFailed,
      'session_expired' => GchText.serverErrorsSessionExpired,
      'session_not_found' => GchText.serverErrorsSessionNotFound,
      'refresh_token_not_found' => GchText.serverErrorsRefreshTokenNotFound,
      'refresh_token_already_used' => GchText.serverErrorsRefreshTokenAlreadyUsed,
      'reauthentication_needed' => GchText.serverErrorsReauthenticationNeeded,
      'signup_disabled' => GchText.serverErrorsSignupDisabled,
      'user_banned' => GchText.serverErrorsUserBanned,
      'over_request_rate_limit' => GchText.serverErrorsOverRequestRateLimit,
      'over_email_send_rate_limit' => GchText.serverErrorsOverEmailSendRateLimit,
      'over_sms_send_rate_limit' => GchText.serverErrorsOverSmsSendRateLimit,
      'sms_send_failed' => GchText.serverErrorsSmsSendFailed,
      'bad_oauth_state' => GchText.serverErrorsBadOauthState,
      'bad_oauth_callback' => GchText.serverErrorsBadOauthCallback,
      'oauth_provider_not_supported' => GchText.serverErrorsOauthProviderNotSupported,
      'provider_disabled' => GchText.serverErrorsProviderDisabled,
      'mfa_challenge_expired' => GchText.serverErrorsMfaChallengeExpired,
      'mfa_verification_failed' => GchText.serverErrorsMfaVerificationFailed,
      'mfa_factor_not_found' => GchText.serverErrorsMfaFactorNotFound,
      'no_authorization' => GchText.serverErrorsNoAuthorization,
      'not_admin' => GchText.serverErrorsNotAdmin,
      'signup_success_email_verify' => GchText.serverErrorsSignupSuccessEmailVerify,
      'signup_success_phone_verify' => GchText.serverErrorsSignupSuccessPhoneVerify,
      'signup_success_verify' => GchText.serverErrorsSignupSuccessVerify,
      'oauth_cancelled' => GchText.serverErrorsOauthCancelled,
      'oauth_config_error' => GchText.serverErrorsOauthConfigError,
      'pkce_expired' => GchText.serverErrorsPkceExpired,
      'auth_timeout' => GchText.serverErrorsAuthTimeout,
      'supabase_not_initialized' => GchText.serverErrorsSupabaseNotInitialized,
      'otp_sent_email' => GchText.serverErrorsOtpSentEmail,
      'otp_sent_phone' => GchText.serverErrorsOtpSentPhone,
      'otp_resent' => GchText.serverErrorsOtpResent,
      'user_exists_otp_resent' => GchText.serverErrorsUserExistsOtpResent,
      'agreement_required' => GchText.serverErrorsAgreementRequired,
      'email_required' => GchText.serverErrorsEmailRequired,
      'phone_required' => GchText.serverErrorsPhoneRequired,
      'phone_invalid' => GchText.serverErrorsPhoneInvalid,
      'password_required' => GchText.serverErrorsPasswordRequired,
      'otp_required' => GchText.serverErrorsOtpRequired,
      'otp_invalid_length' => GchText.serverErrorsOtpInvalidLength,
      'password_reset_success' => GchText.serverErrorsPasswordResetSuccess,
      'otp_countdown_active' => GchText.serverErrorsOtpCountdownActive,
      'captcha_required' => GchText.serverErrorsCaptchaRequired,
      'otp_send_failed' => GchText.serverErrorsOtpSendFailed,
      _ => GchText.serverErrorsUnknown,
    };
  }

  /// 从错误消息中提取错误码并返回本地化消息
  static String bendihua(String? errorMessage, [dynamic _]) {
    if (errorMessage == null || errorMessage.isEmpty) {
      return huoquBendiXiaoxi('unknown');
    }
    final code = tiquCuowuma(errorMessage);
    return huoquBendiXiaoxi(code);
  }

  /// 从错误消息中提取错误码
  static String tiquCuowuma(String message) {
    final lower = message.toLowerCase();
    final errorCodes = GchFuwuqiCuowuma.all;

    for (final code in errorCodes) {
      if (lower.contains(code)) return code;
    }

    return _pipeiJiuMoshi(lower);
  }

  static String _pipeiJiuMoshi(String lower) {
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password')) {
      return 'invalid_credentials';
    }
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'user_already_exists';
    }
    if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return 'over_request_rate_limit';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'network_error';
    }
    if (lower.contains('timeout')) {
      return 'request_timeout';
    }
    return 'unknown';
  }
}
