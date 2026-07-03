import 'package:nasr_isp/features/settings/data/datasources/settings_remote_data_source.dart';
import 'package:nasr_isp/features/settings/data/models/app_settings_model.dart';
import 'package:nasr_isp/features/settings/domain/entities/app_settings_entity.dart';
import 'package:nasr_isp/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  SettingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AppSettingsEntity> getSettings() async {
    return await remoteDataSource.getSettings();
  }

  @override
  Future<void> updateSettings(AppSettingsEntity settings) async {
    final model = AppSettingsModel.fromEntity(settings);
    await remoteDataSource.updateSettings(model);
  }
}
