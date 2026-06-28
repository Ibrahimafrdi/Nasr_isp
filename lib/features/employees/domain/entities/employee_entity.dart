class EmployeeEntity {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String designation;
  final String status;
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
    required this.status,
    required this.salary,
    this.joinDate,
    this.createdAt,
  });
}
