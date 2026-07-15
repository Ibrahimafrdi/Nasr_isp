class InstallationItemUsedEntity {
  final String inventoryItemId;
  final String itemName;
  final int quantity;
  final double costPriceAtTime;
  // Snapshot of the inventory item's sellPrice at the moment it was added to
  // this BOM — lets material profit (sellPrice - costPrice) be reconstructed
  // later even if the inventory item's price has since changed.
  final double sellPriceAtTime;

  const InstallationItemUsedEntity({
    required this.inventoryItemId,
    required this.itemName,
    required this.quantity,
    required this.costPriceAtTime,
    required this.sellPriceAtTime,
  });
}
