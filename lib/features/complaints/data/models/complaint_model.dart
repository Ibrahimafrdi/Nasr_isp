import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';

class ComplaintModel extends ComplaintEntity {
  const ComplaintModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.customerPhone,
    required super.type,
    required super.priority,
    required super.status,
    required super.description,
    super.assignedEmployeeId,
    super.assignedEmployeeName,
    super.resolutionNotes,
    required super.createdAt,
    required super.updatedAt,
    super.resolvedAt,
    super.createdById,
    super.createdByName,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String docId) {
    return ComplaintModel(
      id: docId,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      type: _parseComplaintType(map['type']),
      priority: _parseComplaintPriority(map['priority']),
      status: _parseComplaintStatus(map['status']),
      description: map['description'] as String? ?? '',
      assignedEmployeeId: map['assignedEmployeeId'] as String?,
      assignedEmployeeName: map['assignedEmployeeName'] as String?,
      resolutionNotes: map['resolutionNotes'] as String?,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
      resolvedAt: _parseDate(map['resolvedAt']),
      createdById: map['createdById'] as String?,
      createdByName: map['createdByName'] as String?,
    );
  }

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ComplaintModel.fromMap(data, doc.id);
  }

  static ComplaintType _parseComplaintType(dynamic value) {
    if (value == null) return ComplaintType.other;
    final valueStr = value.toString();
    return ComplaintType.values.firstWhere(
      (e) => e.name == valueStr || e.label == valueStr,
      orElse: () => ComplaintType.other,
    );
  }

  static ComplaintPriority _parseComplaintPriority(dynamic value) {
    if (value == null) return ComplaintPriority.medium;
    final valueStr = value.toString();
    return ComplaintPriority.values.firstWhere(
      (e) => e.name == valueStr || e.label == valueStr,
      orElse: () => ComplaintPriority.medium,
    );
  }

  static ComplaintStatus _parseComplaintStatus(dynamic value) {
    if (value == null) return ComplaintStatus.open;
    final valueStr = value.toString();
    return ComplaintStatus.values.firstWhere(
      (e) => e.name == valueStr || e.label == valueStr,
      orElse: () => ComplaintStatus.open,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'description': description,
      'assignedEmployeeId': assignedEmployeeId,
      'assignedEmployeeName': assignedEmployeeName,
      'resolutionNotes': resolutionNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'resolvedAt':
          resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'createdById': createdById,
      'createdByName': createdByName,
    };
  }

  @override
  ComplaintModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    ComplaintType? type,
    ComplaintPriority? priority,
    ComplaintStatus? status,
    String? description,
    String? assignedEmployeeId,
    String? assignedEmployeeName,
    String? resolutionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? createdById,
    String? createdByName,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      description: description ?? this.description,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      assignedEmployeeName: assignedEmployeeName ?? this.assignedEmployeeName,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}

