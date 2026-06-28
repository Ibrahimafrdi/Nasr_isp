import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';

class PackageModel extends PackageEntity {
  const PackageModel({
    required super.id,
    required super.name,
    required super.speed,
    required super.price,
    required super.description,
    super.createdAt,
  });

  factory PackageModel.fromMap(Map<String, dynamic> map) {
    return PackageModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      speed: (map['speed'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'speed': speed,
      'price': price,
      'description': description,
      'createdAt': createdAt,
    };
  }

  factory PackageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PackageModel.fromMap({
      ...data,
      'id': doc.id,
    });
  }

  PackageModel copyWith({
    String? id,
    String? name,
    int? speed,
    double? price,
    String? description,
    DateTime? createdAt,
  }) {
    return PackageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      speed: speed ?? this.speed,
      price: price ?? this.price,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
