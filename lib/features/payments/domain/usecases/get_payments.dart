import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';

class GetPayments {
  final PaymentRepository repository;

  GetPayments(this.repository);

  Future<List<PaymentEntity>> call({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    List<String>? filterStatuses,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
  }) =>
      repository.getPayments(
        limit: limit,
        lastDocument: lastDocument,
        searchQuery: searchQuery,
        filterStatuses: filterStatuses,
        dateRangeStart: dateRangeStart,
        dateRangeEnd: dateRangeEnd,
      );
}
