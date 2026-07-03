// registration_type_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:guichao/gch_mod/gch_user/gch_reg/gch_model/gch_registration_state.dart';
import 'package:guichao/gch_gen/gch_text.dart';

/// 注册类型选择器组件
class RegistrationTypeSelector extends ConsumerWidget {
  final RegisterType selectedType;
  final ValueChanged<RegisterType> onTypeChanged;

  const RegistrationTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 44.66.rh,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF3A3A3A),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(22.5.rr),
      ),
      child: Row(
        children: RegisterType.values.map((type) {
          final isSelected = selectedType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTypeChanged(type),
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage('assets/gch_pics/gch_a39c81.webp'),
                          fit: BoxFit.fill,
                        ),
                        borderRadius: BorderRadius.circular(22.5.rr),
                      )
                    : null,
                child: Center(
                  child: Text(
                    _getTypeLabel(type),
                    style: TextStyle(
                      fontSize: 10.rf,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? const Color(0xFF5B3503)
                          : const Color(0xFFB7B7B7),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 获取注册类型的本地化标签
  String _getTypeLabel(RegisterType type) {
    switch (type) {
      case RegisterType.email:
        return GchText.userRegisterEmailRegister;
      case RegisterType.phone:
        return GchText.userRegisterPhoneRegister;
    }
  }
}
