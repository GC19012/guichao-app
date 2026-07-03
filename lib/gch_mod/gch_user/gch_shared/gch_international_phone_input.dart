// international_phone_input.dart
// 统一的国际手机号输入组件，基于 phone_form_field 库
// 遵循项目深蓝科技主题风格

import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:guichao/gch_mod/gch_user/gch_shared/gch_user_theme_colors.dart';

/// 兼容层：保持与旧 intl_phone_number_input PhoneNumber 相同的对外接口
/// 业务层通过此类获取 dialCode / phoneNumber / isoCode，无需感知底层库切换
class PhoneNumberData {
  final String? phoneNumber;
  final String? dialCode;
  final String? isoCode;

  const PhoneNumberData({
    this.phoneNumber,
    this.dialCode,
    this.isoCode,
  });
}

/// 统一的国际手机号输入组件
/// 使用 phone_form_field 库实现完整的国际区号支持
class InternationalPhoneInput extends StatefulWidget {
  /// 手机号变化回调，返回兼容的 PhoneNumberData 对象
  final ValueChanged<PhoneNumberData>? onInputChanged;

  /// 手机号验证回调
  final ValueChanged<bool>? onInputValidated;

  /// 初始国家代码（ISO 2字母代码，如 'CN', 'US'）
  final String initialCountryCode;

  /// 提示文字
  final String? hintText;

  /// 错误信息
  final String? errorMessage;

  /// 是否启用
  final bool isEnabled;

  /// 自动验证模式
  final AutovalidateMode autoValidateMode;

  /// 文本控制器（用于读取纯手机号文本）
  final TextEditingController? textController;

  /// 焦点节点
  final FocusNode? focusNode;

  /// 是否显示错误状态
  final bool hasError;

  /// 输入框高度
  final double height;

  /// 边框圆角
  final double borderRadius;

  /// 背景色（默认使用主题 secondaryBackground）
  final Color? backgroundColor;

  /// 文字颜色
  final Color? textColor;

  /// 提示文字颜色
  final Color? hintColor;

  const InternationalPhoneInput({
    super.key,
    this.onInputChanged,
    this.onInputValidated,
    this.initialCountryCode = 'CN',
    this.hintText,
    this.errorMessage,
    this.isEnabled = true,
    this.autoValidateMode = AutovalidateMode.disabled,
    this.textController,
    this.focusNode,
    this.hasError = false,
    this.height = 50,
    this.borderRadius = 30,
    this.backgroundColor,
    this.textColor,
    this.hintColor,
  });

  @override
  State<InternationalPhoneInput> createState() => _InternationalPhoneInputState();
}

class _InternationalPhoneInputState extends State<InternationalPhoneInput> {
  late PhoneController _phoneController;
  PhoneNumber? _lastNotifiedValue;

  @override
  void initState() {
    super.initState();
    final isoCode = _parseIsoCode(widget.initialCountryCode);
    _phoneController = PhoneController(
      initialValue: PhoneNumber(isoCode: isoCode, nsn: ''),
    );
    _phoneController.addListener(_onPhoneControllerChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneControllerChanged);
    _phoneController.dispose();
    super.dispose();
  }

  IsoCode _parseIsoCode(String code) {
    try {
      return IsoCode.values.firstWhere(
        (iso) => iso.name == code.toUpperCase(),
      );
    } catch (_) {
      return IsoCode.CN;
    }
  }

  void _onPhoneControllerChanged() {
    final phone = _phoneController.value;

    // 避免重复通知相同值
    if (_lastNotifiedValue != null &&
        _lastNotifiedValue!.isoCode == phone.isoCode &&
        _lastNotifiedValue!.nsn == phone.nsn) {
      return;
    }
    _lastNotifiedValue = phone;

    // 同步纯手机号到外部 TextEditingController
    if (widget.textController != null) {
      final nsn = phone.nsn;
      if (widget.textController!.text != nsn) {
        widget.textController!.text = nsn;
      }
    }

    // 回调 onInputChanged
    widget.onInputChanged?.call(PhoneNumberData(
      phoneNumber: phone.international,
      dialCode: '+${phone.countryCode}',
      isoCode: phone.isoCode.name,
    ));

    // 回调 onInputValidated
    widget.onInputValidated?.call(phone.isValid());
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? UserThemeColors.secondaryBackground.withOpacity(0.8);
    final txtColor = widget.textColor ?? UserThemeColors.primaryText;
    final hntColor = widget.hintColor ?? UserThemeColors.primaryText.withOpacity(0.5);

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black87,
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: hntColor),
        ),
      ),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.hasError
                ? UserThemeColors.error.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: widget.hasError
              ? [
                  BoxShadow(
                    color: UserThemeColors.error.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: PhoneFormField(
            controller: _phoneController,
            focusNode: widget.focusNode,
            enabled: widget.isEnabled,
            isCountrySelectionEnabled: true,
            isCountryButtonPersistent: true,
            countryButtonStyle: CountryButtonStyle(
              showDialCode: true,
              showIsoCode: false,
              showFlag: false,
              flagSize: 18,
              textStyle: TextStyle(
                color: txtColor,
                fontSize: 15.rf,
              ),
            ),
            countrySelectorNavigator: CountrySelectorNavigator.draggableBottomSheet(
              favorites: [IsoCode.CN, IsoCode.US, IsoCode.HK, IsoCode.TW, IsoCode.JP],
              backgroundColor: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              initialChildSize: 0.75,
              maxChildSize: 0.92,
              showDialCode: true,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              subtitleStyle: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 12,
              ),
              searchBoxDecoration: InputDecoration(
                hintText: '搜索国家或区号',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3B82F6), size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                ),
              ),
              searchBoxTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
              searchBoxIconColor: const Color(0xFF3B82F6),
              countries: [
                IsoCode.CN, IsoCode.HK, IsoCode.TW, IsoCode.MO,
                IsoCode.US, IsoCode.CA,
                IsoCode.AU, IsoCode.NZ,
                IsoCode.GB, IsoCode.IE,
                IsoCode.DE, IsoCode.FR, IsoCode.NL, IsoCode.SE, IsoCode.NO,
                IsoCode.DK, IsoCode.FI, IsoCode.IT, IsoCode.ES, IsoCode.CH,
                IsoCode.AT, IsoCode.BE, IsoCode.PT, IsoCode.PL,
                IsoCode.JP, IsoCode.KR, IsoCode.SG, IsoCode.MY, IsoCode.TH,
                IsoCode.PH, IsoCode.VN, IsoCode.IN, IsoCode.ID,
                IsoCode.RU, IsoCode.TR,
                IsoCode.AE, IsoCode.SA, IsoCode.QA, IsoCode.KW,
                IsoCode.MX, IsoCode.BR, IsoCode.ZA,
              ],
            ),
            style: TextStyle(
              color: txtColor,
              fontSize: 15.rf,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 15.rw, vertical: 12.18.rh),
              hintText: widget.hintText ?? '请输入手机号',
              hintStyle: TextStyle(
                color: hntColor,
                fontSize: 15.rf,
              ),
              counterText: '',
              isDense: true,
            ),
            // 不显示内置验证错误，由业务层控制
            validator: (PhoneNumber? _) => null,
            autovalidateMode: widget.autoValidateMode,
          ),
        ),
      ),
    );
  }
}

/// 手机号输入工具类
class PhoneInputUtils {
  /// 从 PhoneNumberData 对象获取完整的国际格式手机号
  /// 例如：+8613812345678
  static String getFullPhoneNumber(PhoneNumberData phoneNumber) {
    final fullNumber = phoneNumber.phoneNumber ?? '';
    if (fullNumber.startsWith('+')) {
      return fullNumber;
    }
    final dialCode = phoneNumber.dialCode ?? '';
    return '$dialCode$fullNumber';
  }

  /// 从 PhoneNumberData 对象获取纯手机号（不含区号）
  static String getPhoneNumberOnly(PhoneNumberData phoneNumber) {
    final fullNumber = phoneNumber.phoneNumber ?? '';
    final dialCode = phoneNumber.dialCode ?? '';

    if (fullNumber.startsWith(dialCode)) {
      return fullNumber.substring(dialCode.length);
    }

    return fullNumber.replaceFirst('+', '').replaceFirst(dialCode.replaceFirst('+', ''), '');
  }

  /// 从 PhoneNumberData 对象获取区号
  static String getDialCode(PhoneNumberData phoneNumber) {
    return phoneNumber.dialCode ?? '+86';
  }

  /// 从 PhoneNumberData 对象获取国家ISO代码
  static String getIsoCode(PhoneNumberData phoneNumber) {
    return phoneNumber.isoCode ?? 'CN';
  }
}
