import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/installations/data/models/installation_model.dart';

abstract class InstallationRemoteDataSource {
  Future<void> addInstallation(InstallationModel installation);
  Future<List<InstallationModel>> getInstallations();
  Future<List<InstallationModel>> getInstallationsByCustomer(String customerId);
  Future<void> updateInstallation(InstallationModel installation);
  Future<void> deleteInstallation(String id);
}

class InstallationRemoteDataSourceImpl implements InstallationRemoteDataSource {
  final FirebaseFirestore _firestore;

  InstallationRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('installations');

  @override
  Future<void> addInstallation(InstallationModel installation) async {
    final data = installation.toMap();
    data.remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    await _col.doc(installation.id).set(data);
  }

  @override
  Future<List<InstallationModel>> getInstallations() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => InstallationModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<InstallationModel>> getInstallationsByCustomer(String customerId) async {
    final snapshot = await _col
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => InstallationModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updateInstallation(InstallationModel installation) async {
    final data = installation.toMap();
    data.remove('id');
    data.remove('createdAt');
    await _col.doc(installation.id).update(data);
  }

  @override
  Future<void> deleteInstallation(String id) async {
    await _col.doc(id).delete();
  }
}
