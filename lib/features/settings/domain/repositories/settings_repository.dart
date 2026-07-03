import 'package:nasr_isp/features/settings/domain/entities/app_settings_entity.dart';

abstract class SettingsRepository {
  Future<AppSettingsEntity> getSettings();
  Future<void> updateSettings(AppSettingsEntity settings);
}
