import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_movement_entity.dart';

class StockMovementModel extends StockMovementEntity {
  const StockMovementModel({
    required super.id,
    required super.itemId,
    required super.type,
    required super.quantity,
    required super.reason,
    required super.date,
    required super.performedBy,
  });

  factory StockMovementModel.fromMap(Map<String, dynamic> map) {
    return StockMovementModel(
      id: map['id'] as String? ?? '',
      itemId: map['itemId'] as String? ?? '',
      type: _parseType(map['type']),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      reason: map['reason'] as String? ?? '',
      date: _parseDate(map['date']) ?? DateTime.now(),
      performedBy: map['performedBy'] as String? ?? '',
    );
  }

  static StockMovementType _parseType(dynamic value) {
    if (value == null) return StockMovementType.stockIn;
    final valueStr = value.toString();
    return StockMovementType.values.firstWhere(
      (e) => e.name == valueStr || e.label == valueStr,
      orElse: () => StockMovementType.stockIn,
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
      'itemId': itemId,
      'type': type.name,
      'quantity': quantity,
      'reason': reason,
      'date': Timestamp.fromDate(date),
      'performedBy': performedBy,
    };
  }

  factory StockMovementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StockMovementModel.fromMap({...data, 'id': doc.id});
  }

  Map<String, dynamic> toFirestore() {
    final data = toMap();
    data.remove('id');
    return data;
  }

  factory StockMovementModel.fromJson(Map<String, dynamic> json) => StockMovementModel.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  StockMovementModel copyWith({
    String? id,
    String? itemId,
    StockMovementType? type,
    int? quantity,
    String? reason,
    DateTime? date,
    String? performedBy,
  }) {
    return StockMovementModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      date: date ?? this.date,
      performedBy: performedBy ?? this.performedBy,
    );
  }
}
