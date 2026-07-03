import 'package:nasr_isp/features/settings/domain/entities/app_settings_entity.dart';
import 'package:nasr_isp/features/settings/domain/repositories/settings_repository.dart';

class GetSettings {
  final SettingsRepository repository;

  GetSettings(this.repository);

  Future<AppSettingsEntity> call() async {
    return repository.getSettings();
  }
}
