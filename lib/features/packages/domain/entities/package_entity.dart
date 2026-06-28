class PackageEntity {
  final String id;
  final String name;
  final int speed;
  final double price;
  final String description;
  final DateTime? createdAt;

  const PackageEntity({
    required this.id,
    required this.name,
    required this.speed,
    required this.price,
    required this.description,
    this.createdAt,
  });
}
