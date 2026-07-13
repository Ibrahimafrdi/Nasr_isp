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

  @override
  Future<void> addEmployee(EmployeeModel employee) async {
    final data = employee.toMap();
    data.remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    await _col.doc(employee.id).set(data);
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
    await _col.doc(employee.id).update(data);
  }
}
