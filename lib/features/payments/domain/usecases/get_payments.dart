import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';

class GetPayments {
  final PaymentRepository repository;

  GetPayments(this.repository);

  Future<List<PaymentEntity>> call() async {
    return repository.getPayments();
  }
}
