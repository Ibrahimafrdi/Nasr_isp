import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/settings/data/models/app_settings_model.dart';

abstract class SettingsRemoteDataSource {
  Future<AppSettingsModel> getSettings();
  Future<void> updateSettings(AppSettingsModel model);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final FirebaseFirestore _firestore;

  SettingsRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference get _configDoc =>
      _firestore.collection('app_settings').doc('config');

  @override
  Future<AppSettingsModel> getSettings() async {
    final doc = await _configDoc.get();

    if (!doc.exists) {
      // First read — create the document with defaults so it exists for
      // future reads. Don't throw.
      final defaults = AppSettingsModel.defaults();
      await _configDoc.set(defaults.toMap());
      // Re-read to get server-generated updatedAt timestamp
      final created = await _configDoc.get();
      return AppSettingsModel.fromFirestore(created);
    }

    return AppSettingsModel.fromFirestore(doc);
  }

  @override
  Future<void> updateSettings(AppSettingsModel model) async {
    await _configDoc.set(model.toMap(), SetOptions(merge: true));
  }
}
