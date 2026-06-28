import 'package:nasr_isp/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addPayment(PaymentEntity payment) async {
    final model = PaymentModel(
      id: payment.id,
      customerId: payment.customerId,
      customerName: payment.customerName,
      amount: payment.amount,
      paidAmount: payment.paidAmount,
      status: payment.status,
      dueDate: payment.dueDate,
      completedDate: payment.completedDate,
      method: payment.method,
      notes: payment.notes,
      billingMonth: payment.billingMonth,
      createdAt: payment.createdAt,
    );
    await remoteDataSource.addPayment(model);
  }

  @override
  Future<List<PaymentEntity>> getPayments() async {
    return await remoteDataSource.getPayments();
  }

  @override
  Future<List<PaymentEntity>> getPaymentsByCustomer(String customerId) async {
    return await remoteDataSource.getPaymentsByCustomer(customerId);
  }

  @override
  Future<void> updatePayment(PaymentEntity payment) async {
    final model = PaymentModel(
      id: payment.id,
      customerId: payment.customerId,
      customerName: payment.customerName,
      amount: payment.amount,
      paidAmount: payment.paidAmount,
      status: payment.status,
      dueDate: payment.dueDate,
      completedDate: payment.completedDate,
      method: payment.method,
      notes: payment.notes,
      billingMonth: payment.billingMonth,
      createdAt: payment.createdAt,
    );
    await remoteDataSource.updatePayment(model);
  }

  @override
  Future<void> deletePayment(String id) async {
    await remoteDataSource.deletePayment(id);
  }
}
