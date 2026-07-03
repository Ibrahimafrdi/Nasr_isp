import 'package:nasr_isp/features/employees/domain/repositories/employee_repository.dart';

class DeleteEmployee {
  final EmployeeRepository repository;

  DeleteEmployee(this.repository);

  Future<void> call(String id) => repository.deleteEmployee(id);
}
