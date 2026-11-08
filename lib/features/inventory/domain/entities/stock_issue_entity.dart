import 'package:nasr_isp/core/constants/app_constants.dart';

class StockIssueEntity {
  final String id;
  final String itemId;
  final String itemName;
  final int quantity;
  final double unitCost;
  final StockIssuePurpose purpose;
  final String? towerName;
  final String? notes;
  final DateTime date;
  final String issuedBy;
  final DateTime? createdAt;
  final double? salePrice;
  final String? buyerName;
  final String? customerId;
  final PaymentMethod? paymentMethod;

  const StockIssueEntity({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitCost,
    required this.purpose,
    this.towerName,
    this.notes,
    required this.date,
    required this.issuedBy,
    this.createdAt,
    this.salePrice,
    this.buyerName,
    this.customerId,
    this.paymentMethod,
  });

  void validate() {
    if (quantity <= 0) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Must be greater than zero.',
      );
    }
    if (purpose == StockIssuePurpose.tower &&
        (towerName == null || towerName!.trim().isEmpty)) {
      throw ArgumentError(
        'Tower name is required when issuing stock to a tower.',
      );
    }
    if (purpose == StockIssuePurpose.sale) {
      if (salePrice == null || salePrice! < 0) {
        throw ArgumentError('Sale price is required for a sale.');
      }
      final hasBuyer =
          (buyerName != null && buyerName!.trim().isNotEmpty) ||
          (customerId != null && customerId!.isNotEmpty);
      if (!hasBuyer) {
        throw ArgumentError('Buyer name is required for a sale.');
      }
    }
  }
}
