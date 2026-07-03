import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/packages/data/models/package_model.dart';

abstract class PackageRemoteDataSource {
  Future<List<PackageModel>> getPackages({
    ConnectionType? filterByType,
    bool? activeOnly,
  });

  Future<PackageModel> getPackageById(String id);

  /// Returns the Firestore-generated document id.
  Future<String> addPackage(PackageModel package);

  Future<void> updatePackage(PackageModel package);

  Future<void> deletePackage(String id);
}

class PackageRemoteDataSourceImpl implements PackageRemoteDataSource {
  final FirebaseFirestore _firestore;

  PackageRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('packages');

  @override
  Future<List<PackageModel>> getPackages({
    ConnectionType? filterByType,
    bool? activeOnly,
  }) async {
    Query query = _col;

    // NOTE: We deliberately avoid chaining orderBy with where on a different
    // field to sidestep composite-index requirements (same pattern as payments).
    // Instead we filter in-memory and sort by name.
    if (filterByType != null) {
      query = query.where('connectionType', isEqualTo: filterByType.name);
    }
    if (activeOnly == true) {
      query = query.where('isActive', isEqualTo: true);
    }

    final snapshot = await query.get();
    final results = snapshot.docs
        .map((doc) => PackageModel.fromFirestore(doc))
        .toList();

    // In-memory sort by name ascending
    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  @override
  Future<PackageModel> getPackageById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) throw Exception('Package not found: $id');
    return PackageModel.fromFirestore(doc);
  }

  @override
  Future<String> addPackage(PackageModel package) async {
    final data = package.toFirestore(isCreate: true);
    final docRef = await _col.add(data);
    return docRef.id;
  }

  @override
  Future<void> updatePackage(PackageModel package) async {
    final data = package.toFirestore(isCreate: false);
    await _col.doc(package.id).update(data);
  }

  @override
  Future<void> deletePackage(String id) async {
    await _col.doc(id).delete();
  }
}
