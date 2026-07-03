import 'package:nasr_isp/core/constants/app_constants.dart';

class StockMovementEntity {
  final String id;
  final String itemId;
  final StockMovementType type;
  final int quantity;
  final String reason;
  final DateTime date;
  final String performedBy;

  const StockMovementEntity({
    required this.id,
    required this.itemId,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.date,
    required this.performedBy,
  });
}
