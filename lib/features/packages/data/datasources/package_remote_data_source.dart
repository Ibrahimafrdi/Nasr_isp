import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/packages/data/models/package_model.dart';

abstract class PackageRemoteDataSource {
  Future<void> addPackage(PackageModel package);
  Future<List<PackageModel>> getPackages();
  Future<void> updatePackage(PackageModel package);
  Future<void> deletePackage(String id);
}

class PackageRemoteDataSourceImpl implements PackageRemoteDataSource {
  final FirebaseFirestore _firestore;

  PackageRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('packages');

  @override
  Future<void> addPackage(PackageModel package) async {
    final data = package.toMap();
    data.remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    await _col.doc(package.id).set(data);
  }

  @override
  Future<List<PackageModel>> getPackages() async {
    final snapshot = await _col.orderBy('speed').get();
    return snapshot.docs.map((doc) => PackageModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updatePackage(PackageModel package) async {
    final data = package.toMap();
    data.remove('id');
    data.remove('createdAt');
    await _col.doc(package.id).update(data);
  }

  @override
  Future<void> deletePackage(String id) async {
    await _col.doc(id).delete();
  }
}
