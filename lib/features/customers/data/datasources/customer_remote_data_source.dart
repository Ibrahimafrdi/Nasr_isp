import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';

abstract class CustomerRemoteDataSource {
  Future<void> addCustomer(CustomerModel customer);
  Future<List<CustomerModel>> getCustomers();
  Future<void> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
  Future<void> updateCustomerWithPayment({
    required CustomerModel customer,
    PaymentModel? payment,
  });
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

  @override
  Future<void> updateCustomerWithPayment({
    required CustomerModel customer,
    PaymentModel? payment,
  }) async {
    final batch = _firestore.batch();

    final customerData = customer.toMap();
    customerData.remove('id');
    customerData.remove('createdAt');
    batch.update(_col.doc(customer.id), customerData);

    if (payment != null) {
      final paymentsCol = _firestore.collection('payments');
      final paymentData = payment.toMap();
      if (payment.dueDate != null) {
        paymentData['dueDate'] = Timestamp.fromDate(payment.dueDate!);
      }
      if (payment.completedDate != null) {
        paymentData['completedDate'] = Timestamp.fromDate(payment.completedDate!);
      }

      if (payment.id.isNotEmpty) {
        paymentData.remove('id');
        paymentData.remove('createdAt');
        batch.update(paymentsCol.doc(payment.id), paymentData);
      } else {
        final docRef = paymentsCol.doc();
        paymentData['id'] = docRef.id;
        paymentData['createdAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, paymentData);
      }
    }

    await batch.commit();
  }
}
