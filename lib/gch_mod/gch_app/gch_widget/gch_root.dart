import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_schema/gch_const.dart';
import 'package:guichao/gch_base/gch_prefs/gch_general_pref.dart';
import 'package:guichao/gch_base/gch_nav/gch_nav.dart';
import 'package:guichao/gch_base/gch_look/gch_look_engine.dart';
import 'package:guichao/gch_base/gch_look/gch_skin/gch_skin_pref.dart';
import 'package:guichao/gch_base/gch_look/gch_look_pref.dart';
import 'package:guichao/gch_mod/gch_app/gch_widget/gch_consent_page.dart';
import 'package:guichao/gch_aux/gch_common.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sizer/sizer.dart';

class GchRoot extends HookConsumerWidget with GchPresLogger {
  const GchRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyAgreed = ref.watch(GchPrefs.privacyAgreed).valueOrNull ?? false;
    final router = ref.watch(gchNavProvider);
    final themeMode = ref.watch(gchLookPrefProvider);
    final skinPref = ref.watch(gchSkinPrefProvider);
    final theme = GchLookEngine(
      themeMode,
      "",
      skin: skinPref.skin,
      tone: skinPref.tone,
    );

    return DynamicColorBuilder(
              builder: (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
                return Sizer(
                  builder: (context, orientation, deviceType) {
                    return MaterialApp.router(
                        routerConfig: router,
                        locale: const Locale('zh', 'CN'),
                        supportedLocales: const [Locale('zh', 'CN')],
                        localizationsDelegates: GlobalMaterialLocalizations.delegates,
                        debugShowCheckedModeBanner: false,
                        themeMode: themeMode.flutterMode,
                        theme: theme.dayTheme(lightColorScheme),
                        darkTheme: theme.nightTheme(darkColorScheme),
                        title: GchConst.brandName,
                        builder: (context, child) {
                          child = child ?? const SizedBox();
                          // AnnotatedRegion 强制所有页面状态栏图标为深色，
                          // 子页面 AppBar 的 systemOverlayStyle 也会被它覆盖
                          final wrapped = AnnotatedRegion<SystemUiOverlayStyle>(
                            value: const SystemUiOverlayStyle(
                              statusBarColor: Colors.transparent,
                              statusBarBrightness: Brightness.light,
                              statusBarIconBrightness: Brightness.dark,
                              systemNavigationBarColor: Colors.transparent,
                              systemNavigationBarIconBrightness: Brightness.dark,
                            ),
                            child: child,
                          );
                          // 用 Stack 将隐私页叠在主内容之上，
                          // 主内容始终渲染，同意后隐私页移除，无黑屏过渡
                          if (!privacyAgreed) {
                            return Stack(
                              children: [
                                wrapped,
                                Positioned.fill(
                                  child: GchConsentPage(
                                    title: GchText.userPrivacyTitle,
                                    agreeText: GchText.userPrivacyAgree,
                                    declineText: GchText.userPrivacyDecline,
                                    onAgreed: () {
                                      ref.read(GchPrefs.privacyAgreed.notifier).updateValue(true);
                                    },
                                    onDeclined: () {
                                      SystemNavigator.pop();
                                      if (Platform.isIOS) {
                                        exit(0);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                          return wrapped;
                        },
                    );
                  },
                );
              },
    );
  }
}
