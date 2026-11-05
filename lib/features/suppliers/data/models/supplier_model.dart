import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_entity.dart';

class SupplierModel extends SupplierEntity {
  const SupplierModel({
    required super.id,
    required super.name,
    required super.phone,
    super.address,
    super.notes,
    super.isActive = true,
    super.totalPurchased = 0.0,
    super.totalPaid = 0.0,
    super.pendingBalance = 0.0,
    super.createdAt,
  });

  factory SupplierModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final purchased = (map['totalPurchased'] as num?)?.toDouble() ?? 0.0;
    final paid = (map['totalPaid'] as num?)?.toDouble() ?? 0.0;
    final pending = (map['pendingBalance'] as num?)?.toDouble() ?? (purchased - paid);

    return SupplierModel(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      totalPurchased: purchased,
      totalPaid: paid,
      pendingBalance: pending,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  factory SupplierModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SupplierModel.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'isActive': isActive,
      'totalPurchased': totalPurchased,
      'totalPaid': totalPaid,
      'pendingBalance': pendingBalance,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  Map<String, dynamic> toFirestore() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  SupplierEntity toEntity() => this;

  SupplierModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
    bool? isActive,
    double? totalPurchased,
    double? totalPaid,
    double? pendingBalance,
    DateTime? createdAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      totalPurchased: totalPurchased ?? this.totalPurchased,
      totalPaid: totalPaid ?? this.totalPaid,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

