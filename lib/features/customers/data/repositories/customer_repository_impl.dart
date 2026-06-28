import 'package:nasr_isp/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addCustomer(CustomerEntity customer) async {
    final model = CustomerModel(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      cnic: customer.cnic,
      address: customer.address,
      connectionType: customer.connectionType,
      packageId: customer.packageId,
      monthlyBill: customer.monthlyBill,
      status: customer.status,
      notes: customer.notes,
      createdAt: customer.createdAt,
      joinDate: customer.joinDate,
      nextDueDate: customer.nextDueDate,
    );
    await remoteDataSource.addCustomer(model);
  }

  @override
  Future<List<CustomerEntity>> getCustomers() async {
    return await remoteDataSource.getCustomers();
  }

  @override
  Future<void> updateCustomer(CustomerEntity customer) async {
    final model = CustomerModel(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      cnic: customer.cnic,
      address: customer.address,
      connectionType: customer.connectionType,
      packageId: customer.packageId,
      monthlyBill: customer.monthlyBill,
      status: customer.status,
      notes: customer.notes,
      createdAt: customer.createdAt,
      joinDate: customer.joinDate,
      nextDueDate: customer.nextDueDate,
    );
    await remoteDataSource.updateCustomer(model);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await remoteDataSource.deleteCustomer(id);
  }
}
