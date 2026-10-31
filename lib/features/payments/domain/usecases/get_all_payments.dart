import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';

class GetAllPayments {
  final PaymentRepository repository;

  GetAllPayments(this.repository);

  Future<List<PaymentEntity>> call({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      repository.getAllPayments(
        startDate: startDate,
        endDate: endDate,
      );
}
