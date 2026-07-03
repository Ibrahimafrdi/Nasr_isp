import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';

class InventoryItemModel extends InventoryItemEntity {
  const InventoryItemModel({
    required super.id,
    required super.name,
    required super.category,
    required super.unit,
    required super.quantityInStock,
    required super.reorderLevel,
    required super.unitCost,
    super.supplier,
    super.notes,
    super.createdAt,
    super.updatedAt,
  });

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) {
    return InventoryItemModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: _parseCategory(map['category']),
      unit: map['unit'] as String? ?? '',
      quantityInStock: (map['quantityInStock'] as num?)?.toInt() ?? 0,
      reorderLevel: (map['reorderLevel'] as num?)?.toInt() ?? 0,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
      supplier: map['supplier'] as String?,
      notes: map['notes'] as String?,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static InventoryCategory _parseCategory(dynamic value) {
    if (value == null) return InventoryCategory.equipment;
    final valueStr = value.toString();
    return InventoryCategory.values.firstWhere(
      (e) => e.name == valueStr || e.label == valueStr,
      orElse: () => InventoryCategory.equipment,
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
      'category': category.name,
      'unit': unit,
      'quantityInStock': quantityInStock,
      'reorderLevel': reorderLevel,
      'unitCost': unitCost,
      'supplier': supplier,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory InventoryItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InventoryItemModel.fromMap({...data, 'id': doc.id});
  }

  Map<String, dynamic> toFirestore() {
    final data = toMap();
    data.remove('id');
    return data;
  }

  // Adding json methods to match the requirement prompt: "fromJson/toJson and fromFirestore/toFirestore"
  factory InventoryItemModel.fromJson(Map<String, dynamic> json) => InventoryItemModel.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  InventoryItemModel copyWith({
    String? id,
    String? name,
    InventoryCategory? category,
    String? unit,
    int? quantityInStock,
    int? reorderLevel,
    double? unitCost,
    String? supplier,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantityInStock: quantityInStock ?? this.quantityInStock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      unitCost: unitCost ?? this.unitCost,
      supplier: supplier ?? this.supplier,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
