import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/installations/data/models/installation_item_used_model.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';

class InstallationModel extends InstallationEntity {
  const InstallationModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.connectionType,
    required super.installationDate,
    super.assignedEmployeeId,
    super.assignedEmployeeName,
    required super.installationCost,
    required super.status,
    super.remarks,
    super.itemsUsed,
    required super.createdAt,
    super.completedAt,
    super.equipmentCost,
    super.laborCost,
  });

  factory InstallationModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawItems = map['itemsUsed'] as List<dynamic>?;
    final parsedItems = rawItems != null
        ? rawItems.map((item) => InstallationItemUsedModel.fromMap(Map<String, dynamic>.from(item))).toList()
        : <InstallationItemUsedModel>[];

    return InstallationModel(
      id: docId,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      connectionType: _parseConnectionType(map['connectionType']),
      installationDate: _parseDate(map['installationDate']) ?? DateTime.now(),
      assignedEmployeeId: map['assignedEmployeeId'] as String?,
      assignedEmployeeName: map['assignedEmployeeName'] as String?,
      installationCost: (map['installationCost'] as num?)?.toDouble() ?? 0.0,
      status: _parseInstallationStatus(map['status']),
      remarks: map['remarks'] as String?,
      itemsUsed: parsedItems,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      completedAt: _parseDate(map['completedAt']),
      equipmentCost: (map['equipmentCost'] as num?)?.toDouble(),
      laborCost: (map['laborCost'] as num?)?.toDouble(),
    );
  }

  static ConnectionType _parseConnectionType(dynamic value) {
    if (value == null) return ConnectionType.wireless;
    final valueStr = value.toString();
    if (valueStr == 'fiber') return ConnectionType.opticalFibre;
    return ConnectionType.values.firstWhere(
      (e) => e.name == valueStr || e.label == valueStr,
      orElse: () => ConnectionType.wireless,
    );
  }

  static InstallationStatus _parseInstallationStatus(dynamic value) {
    if (value == null) return InstallationStatus.pending;
    final valueStr = value.toString();
    return InstallationStatus.values.firstWhere(
      (e) => e.name == valueStr || e.label == valueStr,
      orElse: () => InstallationStatus.pending,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'connectionType': connectionType.name,
      'installationDate': Timestamp.fromDate(installationDate),
      'assignedEmployeeId': assignedEmployeeId,
      'assignedEmployeeName': assignedEmployeeName,
      'installationCost': installationCost,
      'status': status.name,
      'remarks': remarks,
      'itemsUsed': itemsUsed?.map((item) {
        if (item is InstallationItemUsedModel) {
          return item.toMap();
        }
        return InstallationItemUsedModel(
          inventoryItemId: item.inventoryItemId,
          itemName: item.itemName,
          quantity: item.quantity,
          costPriceAtTime: item.costPriceAtTime,
          sellPriceAtTime: item.sellPriceAtTime,
        ).toMap();
      }).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'equipmentCost': equipmentCost,
      'laborCost': laborCost,
    };
  }

  factory InstallationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InstallationModel.fromMap(data, doc.id);
  }

  InstallationModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    ConnectionType? connectionType,
    DateTime? installationDate,
    String? assignedEmployeeId,
    String? assignedEmployeeName,
    double? installationCost,
    InstallationStatus? status,
    String? remarks,
    List<InstallationItemUsedModel>? itemsUsed,
    DateTime? createdAt,
    DateTime? completedAt,
    double? equipmentCost,
    double? laborCost,
  }) {
    return InstallationModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      connectionType: connectionType ?? this.connectionType,
      installationDate: installationDate ?? this.installationDate,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      assignedEmployeeName: assignedEmployeeName ?? this.assignedEmployeeName,
      installationCost: installationCost ?? this.installationCost,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      itemsUsed: itemsUsed ?? this.itemsUsed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      equipmentCost: equipmentCost ?? this.equipmentCost,
      laborCost: laborCost ?? this.laborCost,
    );
  }
}
