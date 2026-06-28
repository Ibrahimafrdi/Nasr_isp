import 'package:nasr_isp/features/customers/domain/repositories/customer_repository.dart';

class DeleteCustomer {
  final CustomerRepository repository;

  DeleteCustomer(this.repository);

  Future<void> call(String id) async {
    return repository.deleteCustomer(id);
  }
}
