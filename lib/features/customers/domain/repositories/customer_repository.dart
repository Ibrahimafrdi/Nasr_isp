import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<void> addCustomer(CustomerEntity customer);
  Future<List<CustomerEntity>> getCustomers();
  Future<void> updateCustomer(CustomerEntity customer);
  Future<void> deleteCustomer(String id);
}
