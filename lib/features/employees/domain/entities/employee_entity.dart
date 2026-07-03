import 'package:nasr_isp/core/constants/app_constants.dart';

class EmployeeEntity {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String designation;
  final String sectorArea;
  final EmployeeStatus status;
  final double salary;
  final DateTime? joinDate;
  final DateTime? createdAt;

  const EmployeeEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.designation,
    required this.sectorArea,
    required this.status,
    required this.salary,
    this.joinDate,
    this.createdAt,
  });
}

