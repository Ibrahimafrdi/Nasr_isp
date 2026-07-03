import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';

class UpdatePayment {
  final PaymentRepository repository;

  UpdatePayment(this.repository);

  Future<void> call(PaymentEntity payment) => repository.updatePayment(payment);
}
