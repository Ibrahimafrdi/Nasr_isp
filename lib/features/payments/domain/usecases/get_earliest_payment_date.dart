import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';

/// Returns the `createdAt` of the oldest payment, or `null` when there are no
/// payments. Resolves with a single Firestore read regardless of collection
/// size — use this instead of [GetAllPayments] whenever only the earliest date
/// is needed (e.g. building the available-months picker).
class GetEarliestPaymentDate {
  final PaymentRepository repository;

  GetEarliestPaymentDate(this.repository);

  Future<DateTime?> call() => repository.getEarliestPaymentDate();
}
