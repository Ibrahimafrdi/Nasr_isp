import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<void> addCustomer(CustomerModel customer);
  Future<List<CustomerModel>> getCustomers();
  Future<void> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final FirebaseFirestore _firestore;

  CustomerRemoteDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('customers');

  @override
  Future<void> addCustomer(CustomerModel customer) async {
    final data = customer.toMap();
    data.remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    await _col.doc(customer.id).set(data);
  }

  @override
  Future<List<CustomerModel>> getCustomers() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => CustomerModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> updateCustomer(CustomerModel customer) async {
    final data = customer.toMap();
    data.remove('id');
    data.remove('createdAt');
    await _col.doc(customer.id).update(data);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _col.doc(id).delete();
  }
}
