import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.email,
    required super.address,
    required super.designation,
    required super.sectorArea,
    required super.status,
    required super.salary,
    super.joinDate,
    super.createdAt,
  });

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      sectorArea: map['sectorArea'] as String? ?? '',
      status: _parseStatus(map['status']),
      salary: (map['salary'] as num?)?.toDouble() ?? 0.0,
      joinDate: _parseDate(map['joinDate']),
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static EmployeeStatus _parseStatus(dynamic value) {
    if (value == null) return EmployeeStatus.active;
    final valStr = value.toString().toLowerCase();
    if (valStr == 'inactive') return EmployeeStatus.inactive;
    return EmployeeStatus.active;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'designation': designation,
      'sectorArea': sectorArea,
      'status': status.name,
      'salary': salary,
      'joinDate': joinDate != null ? Timestamp.fromDate(joinDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  factory EmployeeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EmployeeModel.fromMap({
      ...data,
      'id': doc.id,
    });
  }

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? designation,
    String? sectorArea,
    EmployeeStatus? status,
    double? salary,
    DateTime? joinDate,
    DateTime? createdAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      designation: designation ?? this.designation,
      sectorArea: sectorArea ?? this.sectorArea,
      status: status ?? this.status,
      salary: salary ?? this.salary,
      joinDate: joinDate ?? this.joinDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

