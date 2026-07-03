import 'package:nasr_isp/features/installations/domain/entities/installation_item_used_entity.dart';

class InstallationItemUsedModel extends InstallationItemUsedEntity {
  const InstallationItemUsedModel({
    required super.inventoryItemId,
    required super.itemName,
    required super.quantity,
    required super.costPriceAtTime,
  });

  factory InstallationItemUsedModel.fromMap(Map<String, dynamic> map) {
    return InstallationItemUsedModel(
      inventoryItemId: map['inventoryItemId'] as String? ?? '',
      itemName: map['itemName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      costPriceAtTime: (map['costPriceAtTime'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inventoryItemId': inventoryItemId,
      'itemName': itemName,
      'quantity': quantity,
      'costPriceAtTime': costPriceAtTime,
    };
  }
}
