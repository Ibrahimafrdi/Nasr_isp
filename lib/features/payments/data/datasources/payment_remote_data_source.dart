import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<void> addPayment(PaymentModel payment);
  Future<List<PaymentModel>> getPayments();
  Future<List<PaymentModel>> getPaymentsByCustomer(String customerId);
  Future<void> updatePayment(PaymentModel payment);
  Future<void> deletePayment(String id);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final FirebaseFirestore _firestore;

  PaymentRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('payments');

  @override
  Future<void> addPayment(PaymentModel payment) async {
    final data = payment.toMap();
    data.remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    await _col.doc(payment.id).set(data);
  }

  @override
  Future<List<PaymentModel>> getPayments() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<PaymentModel>> getPaymentsByCustomer(String customerId) async {
    final snapshot = await _col
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updatePayment(PaymentModel payment) async {
    final data = payment.toMap();
    data.remove('id');
    data.remove('createdAt');
    await _col.doc(payment.id).update(data);
  }

  @override
  Future<void> deletePayment(String id) async {
    await _col.doc(id).delete();
  }
}
