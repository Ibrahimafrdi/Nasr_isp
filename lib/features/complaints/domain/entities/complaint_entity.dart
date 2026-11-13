import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';

class ComplaintEntity extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final ComplaintType type;
  final ComplaintPriority priority;
  final ComplaintStatus status;
  final String description;
  final String? assignedEmployeeId;
  final String? assignedEmployeeName;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? createdById;
  final String? createdByName;

  const ComplaintEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.type,
    required this.priority,
    required this.status,
    required this.description,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.createdById,
    this.createdByName,
  });

  bool get isResolvedOrClosed =>
      status == ComplaintStatus.resolved || status == ComplaintStatus.closed;

  int get ageInDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  ComplaintEntity copyWith({
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
    return ComplaintEntity(
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

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        customerPhone,
        type,
        priority,
        status,
        description,
        assignedEmployeeId,
        assignedEmployeeName,
        resolutionNotes,
        createdAt,
        updatedAt,
        resolvedAt,
        createdById,
        createdByName,
      ];
}

