import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';

class GetPaymentByCustomerAndMonth {
  final PaymentRepository repository;

  GetPaymentByCustomerAndMonth(this.repository);

  Future<PaymentEntity?> call(
    String customerId,
    String billingMonth,
  ) =>
      repository.getPaymentByCustomerAndMonth(customerId, billingMonth);
}
