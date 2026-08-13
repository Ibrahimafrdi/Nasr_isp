import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.cnic,
    required super.address,
    required super.connectionType,
    super.packageId,
    required super.monthlyBill,
    required super.status,
    required super.notes,
    super.userId,
    super.createdAt,
    super.joinDate,
    super.nextDueDate,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      cnic: map['cnic'] as String? ?? '',
      address: map['address'] as String? ?? '',
      connectionType: map['connectionType'] as String? ?? '',
      packageId: map['packageId'] as String?,
      monthlyBill: (map['monthlyBill'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      userId: map['userId'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] != null
                ? DateTime.tryParse(map['createdAt'].toString())
                : null),
      joinDate: _parseDate(map['joinDate']),
      nextDueDate: _parseDate(map['nextDueDate']),
    );
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
      'cnic': cnic,
      'address': address,
      'connectionType': connectionType,
      'packageId': packageId,
      'monthlyBill': monthlyBill,
      'status': status,
      'notes': notes,
      'userId': userId,
      'createdAt': createdAt,
      'joinDate': joinDate != null ? Timestamp.fromDate(joinDate!) : null,
      'nextDueDate': nextDueDate != null
          ? Timestamp.fromDate(nextDueDate!)
          : null,
    };
  }

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CustomerModel.fromMap({...data, 'id': doc.id});
  }

  @override
  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? cnic,
    String? address,
    String? connectionType,
    String? packageId,
    double? monthlyBill,
    String? status,
    String? notes,
    String? userId,
    DateTime? createdAt,
    DateTime? joinDate,
    DateTime? nextDueDate,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      cnic: cnic ?? this.cnic,
      address: address ?? this.address,
      connectionType: connectionType ?? this.connectionType,
      packageId: packageId ?? this.packageId,
      monthlyBill: monthlyBill ?? this.monthlyBill,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      joinDate: joinDate ?? this.joinDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
    );
  }

}
