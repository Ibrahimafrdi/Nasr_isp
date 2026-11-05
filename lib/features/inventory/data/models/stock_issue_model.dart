import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_issue_entity.dart';

class StockIssueModel extends StockIssueEntity {
  const StockIssueModel({
    required super.id,
    required super.itemId,
    required super.itemName,
    required super.quantity,
    required super.unitCost,
    required super.purpose,
    super.towerName,
    super.notes,
    required super.date,
    required super.issuedBy,
    super.createdAt,
  });

  factory StockIssueModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return StockIssueModel(
      id: id,
      itemId: data['itemId'] as String? ?? '',
      itemName: data['itemName'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      unitCost: (data['unitCost'] as num?)?.toDouble() ?? 0,
      purpose: _parsePurpose(data['purpose']),
      towerName: data['towerName'] as String?,
      notes: data['notes'] as String?,
      date: _parseDate(data['date']) ?? DateTime.now(),
      issuedBy: data['issuedBy'] as String? ?? '',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  factory StockIssueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StockIssueModel.fromMap(data, id: doc.id);
  }

  static StockIssuePurpose _parsePurpose(dynamic value) {
    final name = value?.toString();
    return StockIssuePurpose.values.firstWhere(
      (purpose) => purpose.name == name,
      orElse: () => StockIssuePurpose.other,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toFirestore() => {
    'itemId': itemId,
    'itemName': itemName,
    'quantity': quantity,
    'unitCost': unitCost,
    'purpose': purpose.name,
    'towerName': towerName,
    'notes': notes,
    'date': Timestamp.fromDate(date),
    'issuedBy': issuedBy,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
  };

  StockIssueEntity toEntity() => StockIssueEntity(
    id: id,
    itemId: itemId,
    itemName: itemName,
    quantity: quantity,
    unitCost: unitCost,
    purpose: purpose,
    towerName: towerName,
    notes: notes,
    date: date,
    issuedBy: issuedBy,
    createdAt: createdAt,
  );

  StockIssueModel copyWith({String? itemName, double? unitCost}) =>
      StockIssueModel(
        id: id,
        itemId: itemId,
        itemName: itemName ?? this.itemName,
        quantity: quantity,
        unitCost: unitCost ?? this.unitCost,
        purpose: purpose,
        towerName: towerName,
        notes: notes,
        date: date,
        issuedBy: issuedBy,
        createdAt: createdAt,
      );
}
