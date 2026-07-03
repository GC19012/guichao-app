import 'package:flutter/material.dart';
import 'package:guichao/gch_mod/gch_user/gch_center/gch_profile/gch_widget/gch_user_info_card.dart';
import 'package:guichao/gch_mod/gch_user/gch_shared/gch_user_theme_colors.dart';
import 'package:guichao/gch_aux/gch_common.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfilePage extends HookConsumerWidget with GchPresLogger {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void goBack() => context.safePop();

    const userInfoCard = UserInfoCard();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('个人中心', style: TextStyle(color: UserThemeColors.primaryText)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: UserThemeColors.primaryText),
          onPressed: goBack,
        ),
      ),
      body: const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: userInfoCard),
        ],
      ),
    );
  }
}
