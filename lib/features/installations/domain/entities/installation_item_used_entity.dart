class InstallationItemUsedEntity {
  final String inventoryItemId;
  final String itemName;
  final int quantity;
  final double costPriceAtTime;

  const InstallationItemUsedEntity({
    required this.inventoryItemId,
    required this.itemName,
    required this.quantity,
    required this.costPriceAtTime,
  });
}
