import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<void> addPayment(PaymentModel payment);
  Future<List<PaymentModel>> getPayments({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    List<String>? filterStatuses,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
  });
  Future<void> updatePayment(PaymentModel payment);
  Future<void> deletePayment(String id);
  Future<int> getTotalPaymentsCount();
  Future<PaymentModel?> getPaymentByCustomerAndMonth(
    String customerId,
    String billingMonth,
  );
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
    if (payment.dueDate != null) {
      data['dueDate'] = Timestamp.fromDate(payment.dueDate!);
    }
    if (payment.completedDate != null) {
      data['completedDate'] = Timestamp.fromDate(payment.completedDate!);
    }
    await _col.doc(payment.id).set(data);
  }

  @override
  @override
  Future<List<PaymentModel>> getPayments({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    List<String>? filterStatuses,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
  }) async {
    // Treat empty list same as null
    final statuses = (filterStatuses != null && filterStatuses.isEmpty)
        ? null
        : filterStatuses;

    Query query = _col.orderBy('createdAt', descending: true);

    if (statuses != null && statuses.length == 1) {
      final status = statuses.first;
      List<String> matchValues;
      if (status == 'paid') {
        matchValues = ['paid', 'completed'];
      } else if (status == 'unpaid') {
        matchValues = ['unpaid', 'pending', 'failed'];
      } else {
        matchValues = [status]; // 'partial'
      }

      // whereIn + orderBy requires a composite index in Firestore.
      // To avoid index errors, fetch without orderBy when filtering by status.
      query = _col.where('status', whereIn: matchValues);
    }

    if (dateRangeStart != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(dateRangeStart),
      );
    }
    if (dateRangeEnd != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(
          dateRangeEnd.add(const Duration(days: 1)),
        ),
      );
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    final results = snapshot.docs
        .map((doc) => _normalizeStatus(PaymentModel.fromFirestore(doc)))
        .toList();

    // Sort in-memory when filtering by status (no orderBy applied above)
    if (statuses != null) {
      results.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    }

    return results;
  }

  PaymentModel _normalizeStatus(PaymentModel p) {
    String status = p.status.toLowerCase();
    if (status == 'completed') status = 'paid';
    if (status == 'pending') status = 'unpaid';
    if (status == 'failed') status = 'unpaid';
    return p.copyWith(status: status);
  }

  @override
  Future<int> getTotalPaymentsCount() async {
    final snapshot = await _col.count().get();
    return snapshot.count ?? 0;
  }

  @override
  Future<void> updatePayment(PaymentModel payment) async {
    final data = payment.toMap();
    data.remove('id');
    data.remove('createdAt');
    if (payment.dueDate != null) {
      data['dueDate'] = Timestamp.fromDate(payment.dueDate!);
    }
    if (payment.completedDate != null) {
      data['completedDate'] = Timestamp.fromDate(payment.completedDate!);
    }
    await _col.doc(payment.id).update(data);
  }

  @override
  Future<void> deletePayment(String id) async {
    await _col.doc(id).delete();
  }

  @override
  Future<PaymentModel?> getPaymentByCustomerAndMonth(
    String customerId,
    String billingMonth,
  ) async {
    final snapshot = await _col
        .where('customerId', isEqualTo: customerId)
        .where('billingMonth', isEqualTo: billingMonth)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return _normalizeStatus(PaymentModel.fromFirestore(snapshot.docs.first));
  }
}
