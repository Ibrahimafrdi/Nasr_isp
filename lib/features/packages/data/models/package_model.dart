import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';

class PackageModel extends PackageEntity {
  const PackageModel({
    required super.id,
    required super.name,
    required super.speedMbps,
    required super.price,
    required super.connectionType,
    super.description,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  // ── Parsing helpers ────────────────────────────────────────────────────────

  static ConnectionType _parseConnectionType(dynamic value) {
    if (value == null) return ConnectionType.wireless;
    final s = value.toString();
    return ConnectionType.values.firstWhere(
      (e) => e.name == s || e.label == s,
      orElse: () => ConnectionType.wireless,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  // ── Factories ──────────────────────────────────────────────────────────────

  factory PackageModel.fromMap(Map<String, dynamic> map) {
    return PackageModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      speedMbps: (map['speedMbps'] as num?)?.toInt() ??
          (map['speed'] as num?)?.toInt() ??
          0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      connectionType: _parseConnectionType(map['connectionType']),
      description: map['description'] as String?,
      // Default to true for legacy docs that don't have this field
      isActive: map.containsKey('isActive') ? (map['isActive'] as bool? ?? true) : true,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt'] ?? map['createdAt']),
    );
  }

  factory PackageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PackageModel.fromMap({...data, 'id': doc.id});
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  /// Used when writing to Firestore.
  /// Pass [isCreate] = true on first write to also set createdAt via
  /// FieldValue.serverTimestamp().
  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'name': name,
      'speedMbps': speedMbps,
      'price': price,
      'connectionType': connectionType.name,
      'description': description,
      'isActive': isActive,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  @override
  PackageModel copyWith({
    String? id,
    String? name,
    int? speedMbps,
    double? price,
    ConnectionType? connectionType,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PackageModel(
        id: id ?? this.id,
        name: name ?? this.name,
        speedMbps: speedMbps ?? this.speedMbps,
        price: price ?? this.price,
        connectionType: connectionType ?? this.connectionType,
        description: description ?? this.description,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
