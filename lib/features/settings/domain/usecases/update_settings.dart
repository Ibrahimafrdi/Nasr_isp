import 'package:nasr_isp/features/settings/domain/entities/app_settings_entity.dart';
import 'package:nasr_isp/features/settings/domain/repositories/settings_repository.dart';

class UpdateSettings {
  final SettingsRepository repository;

  UpdateSettings(this.repository);

  Future<void> call(AppSettingsEntity settings) async {
    return repository.updateSettings(settings);
  }
}
