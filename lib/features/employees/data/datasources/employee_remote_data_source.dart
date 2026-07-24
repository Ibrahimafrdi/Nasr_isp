import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/employees/data/models/employee_model.dart';

abstract class EmployeeRemoteDataSource {
  Future<void> addEmployee(EmployeeModel employee);
  Future<List<EmployeeModel>> getEmployees();
  Future<void> updateEmployee(EmployeeModel employee);
}

class EmployeeRemoteDataSourceImpl implements EmployeeRemoteDataSource {
  final FirebaseFirestore _firestore;

  EmployeeRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('employees');

  // Public mirror of non-sensitive fields (no salary/phone/email/address),
  // readable by any signed-in user — e.g. the installations technician
  // dropdown — while the `employees` collection itself stays admin-only.
  CollectionReference get _directoryCol =>
      _firestore.collection('employee_directory');

  @override
  Future<void> addEmployee(EmployeeModel employee) async {
    final data = employee.toMap();
    data.remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    batch.set(_col.doc(employee.id), data);
    batch.set(_directoryCol.doc(employee.id), _directoryData(employee));
    await batch.commit();
  }

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => EmployeeModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updateEmployee(EmployeeModel employee) async {
    final data = employee.toMap();
    data.remove('id');
    data.remove('createdAt');
    final batch = _firestore.batch();
    batch.update(_col.doc(employee.id), data);
    batch.set(_directoryCol.doc(employee.id), _directoryData(employee));
    await batch.commit();
  }

  Map<String, dynamic> _directoryData(EmployeeModel employee) {
    return {
      'name': employee.name,
      'status': employee.status.name,
    };
  }
}
