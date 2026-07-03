import 'package:guichao/gch_gen/gch_text.dart';

enum GchCloseAction {
  ask,
  hide,
  exit;

  String present() => switch (this) {
        ask => GchText.settingsGeneralActionsAtClosingAskEachTime,
        hide => GchText.settingsGeneralActionsAtClosingHide,
        exit => GchText.settingsGeneralActionsAtClosingExit,
      };
}
