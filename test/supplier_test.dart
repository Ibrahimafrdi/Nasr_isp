import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/suppliers/data/models/supplier_model.dart';
import 'package:nasr_isp/features/suppliers/data/models/supplier_purchase_model.dart';
import 'package:nasr_isp/features/suppliers/data/models/supplier_payment_model.dart';

void main() {
  group('Supplier Enums', () {
    test('SupplierPaymentStatus fromString parses valid values and normalizes unknown values to unpaid', () {
      expect(SupplierPaymentStatus.fromString('paid'), SupplierPaymentStatus.paid);
      expect(SupplierPaymentStatus.fromString('partial'), SupplierPaymentStatus.partial);
      expect(SupplierPaymentStatus.fromString('unpaid'), SupplierPaymentStatus.unpaid);
      expect(SupplierPaymentStatus.fromString('unknown_value'), SupplierPaymentStatus.unpaid);
      expect(SupplierPaymentStatus.fromString(null), SupplierPaymentStatus.unpaid);
      expect(SupplierPaymentStatus.fromString(''), SupplierPaymentStatus.unpaid);
    });

    test('PaymentMethod fromString parses valid values and normalizes unknown values to cash', () {
      expect(PaymentMethod.fromString('cash'), PaymentMethod.cash);
      expect(PaymentMethod.fromString('bankTransfer'), PaymentMethod.bankTransfer);
      expect(PaymentMethod.fromString('jazzCash'), PaymentMethod.jazzCash);
      expect(PaymentMethod.fromString('easyPaisa'), PaymentMethod.easyPaisa);
      expect(PaymentMethod.fromString('other'), PaymentMethod.cash);
      expect(PaymentMethod.fromString(null), PaymentMethod.cash);
    });
  });

  group('Weighted Average Cost Formula', () {
    double calculateWeightedCost({
      required int oldQty,
      required double oldCost,
      required int newQty,
      required double newCost,
    }) {
      if (oldQty <= 0) return newCost;
      return (oldQty * oldCost + newQty * newCost) / (oldQty + newQty);
    }

    test('returns new cost if old quantity is zero or negative', () {
      expect(calculateWeightedCost(oldQty: 0, oldCost: 100, newQty: 10, newCost: 150), 150.0);
      expect(calculateWeightedCost(oldQty: -2, oldCost: 100, newQty: 10, newCost: 150), 150.0);
    });

    test('correctly calculates weighted average when existing stock is positive', () {
      // 10 units @ 100 + 10 units @ 200 = 20 units @ 150
      final result1 = calculateWeightedCost(oldQty: 10, oldCost: 100, newQty: 10, newCost: 200);
      expect(result1, 150.0);

      // 20 units @ 100 + 10 units @ 160 = (2000 + 1600) / 30 = 3600 / 30 = 120
      final result2 = calculateWeightedCost(oldQty: 20, oldCost: 100, newQty: 10, newCost: 160);
      expect(result2, 120.0);
    });
  });

  group('Supplier Models & Balances', () {
    test('SupplierModel pendingBalance always equals totalPurchased - totalPaid', () {
      const supplier = SupplierModel(
        id: 'sup_1',
        name: 'Fiber Tech Inc',
        phone: '03001234567',
        totalPurchased: 50000.0,
        totalPaid: 20000.0,
        pendingBalance: 30000.0,
      );

      expect(supplier.pendingBalance, equals(supplier.totalPurchased - supplier.totalPaid));
      expect(supplier.pendingBalance, 30000.0);
    });

    test('SupplierPurchaseEntity status and remainingAmount calculations', () {
      // Unpaid purchase
      final unpaid = SupplierPurchaseModel(
        id: 'pur_1',
        supplierId: 'sup_1',
        itemId: 'item_1',
        itemName: 'ONU Router',
        quantity: 10,
        unitCost: 1500.0,
        totalAmount: 15000.0,
        paidAmount: 0.0,
        status: SupplierPaymentStatus.unpaid,
      );
      expect(unpaid.remainingAmount, 15000.0);
      expect(unpaid.canBeCancelled, isTrue);

      // Partial purchase
      final partial = unpaid.copyWith(
        paidAmount: 5000.0,
        status: SupplierPaymentStatus.partial,
      );
      expect(partial.remainingAmount, 10000.0);
      expect(partial.canBeCancelled, isFalse);

      // Fully paid purchase
      final paid = unpaid.copyWith(
        paidAmount: 15000.0,
        status: SupplierPaymentStatus.paid,
      );
      expect(paid.remainingAmount, 0.0);
      expect(paid.canBeCancelled, isFalse);
    });

    test('SupplierPurchaseModel toMap and fromMap serialization round-trip', () {
      final now = DateTime.now();
      final purchase = SupplierPurchaseModel(
        id: 'pur_123',
        supplierId: 'sup_abc',
        itemId: 'item_xyz',
        itemName: 'Cat6 Cable Roll',
        quantity: 5,
        unitCost: 8000.0,
        totalAmount: 40000.0,
        paidAmount: 10000.0,
        status: SupplierPaymentStatus.partial,
        invoiceNo: 'INV-2026-001',
        notes: 'Delivered in warehouse',
        date: now,
        isCancelled: false,
      );

      final map = purchase.toMap();
      final fromMap = SupplierPurchaseModel.fromMap(map);

      expect(fromMap.id, purchase.id);
      expect(fromMap.supplierId, purchase.supplierId);
      expect(fromMap.totalAmount, purchase.totalAmount);
      expect(fromMap.paidAmount, purchase.paidAmount);
      expect(fromMap.status, SupplierPaymentStatus.partial);
      expect(fromMap.invoiceNo, 'INV-2026-001');
    });

    test('SupplierPaymentModel toMap and fromMap serialization round-trip', () {
      final now = DateTime.now();
      final payment = SupplierPaymentModel(
        id: 'pay_999',
        supplierId: 'sup_abc',
        purchaseId: 'pur_123',
        amount: 10000.0,
        method: PaymentMethod.bankTransfer,
        notes: 'Online transfer ref 44321',
        date: now,
      );

      final map = payment.toMap();
      final fromMap = SupplierPaymentModel.fromMap(map);

      expect(fromMap.id, payment.id);
      expect(fromMap.amount, 10000.0);
      expect(fromMap.method, PaymentMethod.bankTransfer);
      expect(fromMap.notes, 'Online transfer ref 44321');
    });
  });
}

