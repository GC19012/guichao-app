import 'package:guichao/gch_mod/gch_settings/gch_repo/gch_settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_settings_data_providers.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  return SettingsRepositoryImpl();
}
