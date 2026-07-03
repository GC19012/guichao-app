import 'package:guichao/gch_gen/gch_text.dart';

enum GchZone {
  ir,
  cn,
  ru,
  af,
  id,
  tr,
  br,
  other;

  String present() => switch (this) {
        ir => GchText.settingsGeneralRegionsIr,
        cn => GchText.settingsGeneralRegionsCn,
        ru => GchText.settingsGeneralRegionsRu,
        tr => GchText.settingsGeneralRegionsTr,
        af => GchText.settingsGeneralRegionsAf,
        id => GchText.settingsGeneralRegionsId,
        br => GchText.settingsGeneralRegionsBr,
        other => GchText.settingsGeneralRegionsOther,
      };
}
