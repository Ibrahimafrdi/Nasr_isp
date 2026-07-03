import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';

class AddPayment {
  final PaymentRepository repository;

  AddPayment(this.repository);

  Future<void> call(PaymentEntity payment) => repository.addPayment(payment);
}
