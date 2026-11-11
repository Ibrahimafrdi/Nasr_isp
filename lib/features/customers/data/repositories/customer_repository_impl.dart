import 'package:nasr_isp/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/repositories/customer_repository.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});
  @override
  Future<void> addCustomer(CustomerEntity customer) async {
    await remoteDataSource.addCustomer(CustomerModel.fromEntity(customer));
  }

  @override
  Future<void> updateCustomer(CustomerEntity customer) async {
    await remoteDataSource.updateCustomer(CustomerModel.fromEntity(customer));
  }

  @override
  Future<void> updateCustomerWithPayment({
    required CustomerEntity customer,
    PaymentEntity? payment,
  }) async {
    await remoteDataSource.updateCustomerWithPayment(
      customer: CustomerModel.fromEntity(customer),
      payment: payment != null ? PaymentModel.from(payment) : null,
    );
  }

  @override
  Future<List<CustomerEntity>> getCustomers() async {
    return await remoteDataSource.getCustomers();
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await remoteDataSource.deleteCustomer(id);
  }
}
