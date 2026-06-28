import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';

class InstallationModel extends InstallationEntity {
  const InstallationModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.connectionType,
    required super.assignedEmployeeId,
    required super.assignedEmployeeName,
    required super.installationCost,
    required super.status,
    required super.remarks,
    super.installationDate,
    super.createdAt,
  });

  factory InstallationModel.fromMap(Map<String, dynamic> map) {
    return InstallationModel(
      id: map['id'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      connectionType: map['connectionType'] as String? ?? '',
      assignedEmployeeId: map['assignedEmployeeId'] as String? ?? '',
      assignedEmployeeName: map['assignedEmployeeName'] as String? ?? '',
      installationCost: (map['installationCost'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? '',
      remarks: map['remarks'] as String? ?? '',
      installationDate: map['installationDate'] is Timestamp
          ? (map['installationDate'] as Timestamp).toDate()
          : (map['installationDate'] != null ? DateTime.tryParse(map['installationDate'].toString()) : null),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'connectionType': connectionType,
      'assignedEmployeeId': assignedEmployeeId,
      'assignedEmployeeName': assignedEmployeeName,
      'installationCost': installationCost,
      'status': status,
      'remarks': remarks,
      'installationDate': installationDate,
      'createdAt': createdAt,
    };
  }

  factory InstallationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InstallationModel.fromMap({
      ...data,
      'id': doc.id,
    });
  }

  InstallationModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? connectionType,
    String? assignedEmployeeId,
    String? assignedEmployeeName,
    double? installationCost,
    String? status,
    String? remarks,
    DateTime? installationDate,
    DateTime? createdAt,
  }) {
    return InstallationModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      connectionType: connectionType ?? this.connectionType,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      assignedEmployeeName: assignedEmployeeName ?? this.assignedEmployeeName,
      installationCost: installationCost ?? this.installationCost,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      installationDate: installationDate ?? this.installationDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
