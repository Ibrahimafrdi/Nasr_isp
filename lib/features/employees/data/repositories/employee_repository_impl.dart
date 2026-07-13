import 'package:nasr_isp/features/employees/data/datasources/employee_remote_data_source.dart';
import 'package:nasr_isp/features/employees/data/models/employee_model.dart';
import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';
import 'package:nasr_isp/features/employees/domain/repositories/employee_repository.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final EmployeeRemoteDataSource remoteDataSource;

  EmployeeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addEmployee(EmployeeEntity employee) async {
    final model = EmployeeModel(
      id: employee.id,
      name: employee.name,
      phone: employee.phone,
      email: employee.email,
      address: employee.address,
      designation: employee.designation,
      sectorArea: employee.sectorArea,
      status: employee.status,
      salary: employee.salary,
      joinDate: employee.joinDate,
      createdAt: employee.createdAt,
    );
    await remoteDataSource.addEmployee(model);
  }

  @override
  Future<List<EmployeeEntity>> getEmployees() async {
    return await remoteDataSource.getEmployees();
  }

  @override
  Future<void> updateEmployee(EmployeeEntity employee) async {
    final model = EmployeeModel(
      id: employee.id,
      name: employee.name,
      phone: employee.phone,
      email: employee.email,
      address: employee.address,
      designation: employee.designation,
      sectorArea: employee.sectorArea,
      status: employee.status,
      salary: employee.salary,
      joinDate: employee.joinDate,
      createdAt: employee.createdAt,
    );
    await remoteDataSource.updateEmployee(model);
  }
}
