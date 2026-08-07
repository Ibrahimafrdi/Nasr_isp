import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';

void main() {
  group('PaymentEntity.statusFor', () {
    test('nothing collected is unpaid, not partial', () {
      // The blind spot the hand-rolled `isPaidInFull ? paid : partial`
      // copies all shared: a charge raised with zero against it is unpaid.
      expect(
        PaymentEntity.statusFor(amount: 3000, paidAmount: 0),
        'unpaid',
      );
    });

    test('some cash collected is partial', () {
      expect(
        PaymentEntity.statusFor(amount: 3000, paidAmount: 1200),
        'partial',
      );
    });

    test('collected in full is paid', () {
      expect(
        PaymentEntity.statusFor(amount: 3000, paidAmount: 3000),
        'paid',
      );
    });

    test('overpayment is still paid', () {
      expect(
        PaymentEntity.statusFor(amount: 3000, paidAmount: 3500),
        'paid',
      );
    });

    test('a zero-amount charge is settled by definition', () {
      // The full-payment test runs first precisely so this doesn't fall
      // through to 'unpaid' — there is nothing left to collect.
      expect(PaymentEntity.statusFor(amount: 0, paidAmount: 0), 'paid');
    });

    test('a negative collection is treated as nothing collected', () {
      expect(
        PaymentEntity.statusFor(amount: 3000, paidAmount: -50),
        'unpaid',
      );
    });

    test('agrees with isSettled and remainingAmount', () {
      const partial = PaymentEntity(
        id: 'p1',
        customerId: 'c1',
        customerName: 'Ayesha Khan',
        amount: 3000,
        paidAmount: 0,
        status: 'unpaid',
      );

      expect(
        partial.status,
        PaymentEntity.statusFor(amount: 3000, paidAmount: 0),
      );
      expect(partial.isSettled, isFalse);
      expect(partial.remainingAmount, 3000);
    });
  });
}
