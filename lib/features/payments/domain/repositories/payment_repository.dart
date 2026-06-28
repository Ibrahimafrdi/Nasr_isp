import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<void> addPayment(PaymentEntity payment);
  Future<List<PaymentEntity>> getPayments();
  Future<List<PaymentEntity>> getPaymentsByCustomer(String customerId);
  Future<void> updatePayment(PaymentEntity payment);
  Future<void> deletePayment(String id);
}
