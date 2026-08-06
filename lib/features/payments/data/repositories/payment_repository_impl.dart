import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  PaymentModel _toModel(PaymentEntity e) => PaymentModel.from(e);

  @override
  Future<void> addPayment(PaymentEntity payment) async {
    await remoteDataSource.addPayment(_toModel(payment));
  }

  @override
  Future<List<PaymentEntity>> getPayments({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    List<String>? filterStatuses,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
  }) async {
    return await remoteDataSource.getPayments(
      limit: limit,
      lastDocument: lastDocument,
      searchQuery: searchQuery,
      filterStatuses: filterStatuses,
      dateRangeStart: dateRangeStart,
      dateRangeEnd: dateRangeEnd,
    );
  }

  @override
  Future<List<PaymentEntity>> getAllPayments() =>
      remoteDataSource.getAllPayments();

  @override
  Future<int> getTotalPaymentsCount() =>
      remoteDataSource.getTotalPaymentsCount();

  @override
  Future<void> updatePayment(PaymentEntity payment) async {
    await remoteDataSource.updatePayment(_toModel(payment));
  }

  @override
  Future<void> deletePayment(String id) async {
    await remoteDataSource.deletePayment(id);
  }

  @override
  Future<PaymentEntity?> getPaymentByCustomerAndMonth(
    String customerId,
    String billingMonth,
  ) async {
    return await remoteDataSource.getPaymentByCustomerAndMonth(
      customerId,
      billingMonth,
    );
  }
}
