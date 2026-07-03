import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';

abstract class EmployeeRepository {
  Future<void> addEmployee(EmployeeEntity employee);
  Future<List<EmployeeEntity>> getEmployees();
  Future<void> updateEmployee(EmployeeEntity employee);
  Future<void> deleteEmployee(String id);
}
