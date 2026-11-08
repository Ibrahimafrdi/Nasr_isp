import 'package:nasr_isp/features/suppliers/domain/entities/supplier_purchase_entity.dart';

/// How much of a single payment lands on one purchase/invoice.
class SupplierPaymentAllocation {
  final String purchaseId;
  final double amount;

  const SupplierPaymentAllocation({
    required this.purchaseId,
    required this.amount,
  });
}

/// Splits one supplier payment across that supplier's unpaid purchases,
/// oldest first. Used by the dialog (live preview) and by the datasource
/// (the real write) so both always agree.
class SupplierPaymentAllocator {
  static const double _eps = 0.0001;

  /// Unpaid, non-cancelled purchases, oldest first.
  static List<SupplierPurchaseEntity> payable(
    List<SupplierPurchaseEntity> purchases,
  ) {
    final list = purchases
        .where((p) => !p.isCancelled && p.remainingAmount > _eps)
        .toList();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    list.sort((a, b) {
      final aDate = a.date ?? a.createdAt ?? epoch;
      final bDate = b.date ?? b.createdAt ?? epoch;
      final byDate = aDate.compareTo(bDate);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    return list;
  }

  static double totalDue(List<SupplierPurchaseEntity> purchases) {
    return payable(purchases).fold(0.0, (sum, p) => sum + p.remainingAmount);
  }

  /// Oldest invoice is cleared first, then the next one, and so on. Any
  /// amount above the total due is simply not allocated (callers validate
  /// that before saving).
  static List<SupplierPaymentAllocation> allocate(
    List<SupplierPurchaseEntity> purchases,
    double amount,
  ) {
    var left = amount;
    final result = <SupplierPaymentAllocation>[];
    for (final p in payable(purchases)) {
      if (left <= _eps) break;
      final take = left < p.remainingAmount ? left : p.remainingAmount;
      result.add(SupplierPaymentAllocation(purchaseId: p.id, amount: take));
      left -= take;
    }
    return result;
  }
}
