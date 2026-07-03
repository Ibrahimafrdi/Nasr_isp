import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<void> addPayment(PaymentEntity payment);
  Future<List<PaymentEntity>> getPayments({
    int limit,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    List<String>? filterStatuses,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
  });
  Future<void> updatePayment(PaymentEntity payment);
  Future<void> deletePayment(String id);
  Future<int> getTotalPaymentsCount();
  Future<PaymentEntity?> getPaymentByCustomerAndMonth(
    String customerId,
    String billingMonth,
  );
}
