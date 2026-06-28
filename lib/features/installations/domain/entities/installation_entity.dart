class InstallationEntity {
  final String id;
  final String customerId;
  final String customerName;
  final String connectionType;
  final String assignedEmployeeId;
  final String assignedEmployeeName;
  final double installationCost;
  final String status;
  final String remarks;
  final DateTime? installationDate;
  final DateTime? createdAt;

  const InstallationEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.connectionType,
    required this.assignedEmployeeId,
    required this.assignedEmployeeName,
    required this.installationCost,
    required this.status,
    required this.remarks,
    this.installationDate,
    this.createdAt,
  });
}
