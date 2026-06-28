import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.email,
    required super.address,
    required super.designation,
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
      status: map['status'] as String? ?? '',
      salary: (map['salary'] as num?)?.toDouble() ?? 0.0,
      joinDate: map['joinDate'] is Timestamp
          ? (map['joinDate'] as Timestamp).toDate()
          : (map['joinDate'] != null ? DateTime.tryParse(map['joinDate'].toString()) : null),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'designation': designation,
      'status': status,
      'salary': salary,
      'joinDate': joinDate,
      'createdAt': createdAt,
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
    String? status,
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
      status: status ?? this.status,
      salary: salary ?? this.salary,
      joinDate: joinDate ?? this.joinDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
