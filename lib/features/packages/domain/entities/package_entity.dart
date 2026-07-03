import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';

class PackageEntity extends Equatable {
  final String id;
  final String name;
  final int speedMbps;
  final double price;
  final ConnectionType connectionType;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PackageEntity({
    required this.id,
    required this.name,
    required this.speedMbps,
    required this.price,
    required this.connectionType,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        speedMbps,
        price,
        connectionType,
        description,
        isActive,
        createdAt,
        updatedAt,
      ];

  PackageEntity copyWith({
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
      PackageEntity(
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
