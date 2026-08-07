import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/repositories/customer_repository.dart';
import 'package:nasr_isp/features/customers/domain/usecases/set_customer_status.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';

// ── Fakes ────────────────────────────────────────────────────────
// Hand-written, matching the project's convention (no mocking library).

class _FakeCustomerRepository implements CustomerRepository {
  final List<CustomerEntity> updated = [];

  @override
  Future<void> updateCustomer(CustomerEntity c) async => updated.add(c);

  @override
  Future<List<CustomerEntity>> getCustomers() async =>
      throw UnimplementedError();
  @override
  Future<void> addCustomer(CustomerEntity c) async => throw UnimplementedError();
  @override
  Future<void> deleteCustomer(String id) async => throw UnimplementedError();
}

class _FakePaymentRepository implements PaymentRepository {
  _FakePaymentRepository({this.existing});

  /// The row `getPaymentByCustomerAndMonth` will return, if any.
  final PaymentEntity? existing;

  final List<PaymentEntity> added = [];
  final List<PaymentEntity> updated = [];
  final List<String> lookedUpMonths = [];

  @override
  Future<PaymentEntity?> getPaymentByCustomerAndMonth(
    String customerId,
    String billingMonth,
  ) async {
    lookedUpMonths.add(billingMonth);
    return existing;
  }

  @override
  Future<void> addPayment(PaymentEntity p) async => added.add(p);
  @override
  Future<void> updatePayment(PaymentEntity p) async => updated.add(p);

  @override
  Future<List<PaymentEntity>> getAllPayments() async =>
      throw UnimplementedError();
  @override
  Future<List<PaymentEntity>> getPayments({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    List<String>? filterStatuses,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
  }) async =>
      throw UnimplementedError();
  @override
  Future<void> deletePayment(String id) async => throw UnimplementedError();
  @override
  Future<int> getTotalPaymentsCount() async => throw UnimplementedError();
}

class _FakePackageRepository implements PackageRepository {
  _FakePackageRepository(this.packages);
  final List<PackageEntity> packages;

  @override
  Future<List<PackageEntity>> getPackages({
    ConnectionType? filterByType,
    bool? activeOnly,
  }) async =>
      packages;

  @override
  Future<PackageEntity> getPackageById(String id) async =>
      throw UnimplementedError();
  @override
  Future<String> addPackage(PackageEntity p) async => throw UnimplementedError();
  @override
  Future<void> updatePackage(PackageEntity p) async =>
      throw UnimplementedError();
  @override
  Future<void> deletePackage(String id) async => throw UnimplementedError();
}

// ── Builders ─────────────────────────────────────────────────────

CustomerModel _customer({
  String status = CustomerEntity.statusInactive,
  double monthlyBill = 3000,
  String? packageId = 'pkg1',
  DateTime? nextDueDate,
}) =>
    CustomerModel(
      id: 'c1',
      name: 'Ayesha Khan',
      phone: '03001234567',
      cnic: '1234567890123',
      address: 'Peshawar',
      connectionType: 'fiber',
      packageId: packageId,
      monthlyBill: monthlyBill,
      status: status,
      notes: '',
      createdAt: DateTime(2026, 1, 5),
      joinDate: DateTime(2026, 1, 5),
      nextDueDate: nextDueDate ?? DateTime(2026, 1, 5),
    );

PackageEntity _package({double costPrice = 1000}) => PackageEntity(
      id: 'pkg1',
      name: 'Fiber 20',
      speedMbps: 20,
      price: 3000,
      costPrice: costPrice,
      connectionType: ConnectionType.opticalFibre,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  late _FakeCustomerRepository customers;

  SetCustomerStatus build({
    PaymentEntity? existingCharge,
    List<PackageEntity> packages = const [],
    _FakePaymentRepository? payments,
  }) {
    return SetCustomerStatus(
      customerRepository: customers,
      paymentRepository:
          payments ?? _FakePaymentRepository(existing: existingCharge),
      getPackages: GetPackages(_FakePackageRepository(packages)),
    );
  }

  setUp(() {
    customers = _FakeCustomerRepository();
  });

  group('deactivating', () {
    test('writes the inactive status and raises no charge', () async {
      final payments = _FakePaymentRepository();
      final outcome = await build(payments: payments)(
        customer: _customer(status: CustomerEntity.statusActive),
        active: false,
      );

      expect(outcome.customer.status, CustomerEntity.statusInactive);
      expect(outcome.customer.isActive, isFalse);
      expect(outcome.billed, isFalse);
      expect(payments.added, isEmpty);
      expect(customers.updated.single.status, CustomerEntity.statusInactive);
    });

    test('preserves nextDueDate so reactivation can resume it', () async {
      final due = DateTime(2026, 8, 5);
      final outcome = await build()(
        customer: _customer(
          status: CustomerEntity.statusActive,
          nextDueDate: due,
        ),
        active: false,
      );

      expect(outcome.customer.nextDueDate, due);
    });

    test('stops reporting the customer as expired or due for renewal', () {
      // Long lapsed, but off service — nothing to chase.
      final inactive = _customer(nextDueDate: DateTime(2026, 1, 5));
      final now = DateTime(2026, 8, 7);

      expect(inactive.isExpiredAt(now), isFalse);
      expect(inactive.isDueForRenewalAt(now), isFalse);
    });

    test('hides the due date from display but keeps it on the record', () {
      final due = DateTime(2026, 8, 5);
      final inactive = _customer(nextDueDate: due);

      expect(inactive.billingDueDate, isNull);
      expect(inactive.effectiveDueDate, due);
      expect(inactive.nextDueDate, due);
    });
  });

  group('reactivating — resume existing', () {
    test('leaves the stale expiry in place and raises no charge', () async {
      final payments = _FakePaymentRepository();
      final due = DateTime(2026, 1, 5);
      final outcome = await build(payments: payments)(
        customer: _customer(nextDueDate: due),
        active: true,
        cycle: ReactivationCycle.resumeExisting,
        asOf: DateTime(2026, 8, 7),
      );

      expect(outcome.customer.isActive, isTrue);
      expect(outcome.customer.nextDueDate, due);
      // Whatever they owed for the interrupted period is already on the
      // ledger — billing again here would double-charge it.
      expect(outcome.billed, isFalse);
      expect(payments.added, isEmpty);
      expect(outcome.customer.isExpiredAt(DateTime(2026, 8, 7)), isTrue);
    });

    test('is the default, so a month is never silently granted', () async {
      final due = DateTime(2026, 1, 5);
      final outcome = await build()(
        customer: _customer(nextDueDate: due),
        active: true,
      );

      expect(outcome.customer.nextDueDate, due);
      expect(outcome.billed, isFalse);
    });
  });

  group('reactivating — start fresh', () {
    test('moves the expiry one month past the reactivation date', () async {
      final outcome = await build()(
        customer: _customer(),
        active: true,
        cycle: ReactivationCycle.startFresh,
        asOf: DateTime(2026, 8, 7, 14, 30),
      );

      expect(outcome.customer.nextDueDate, DateTime(2026, 9, 7));
      expect(outcome.customer.isExpiredAt(DateTime(2026, 8, 7)), isFalse);
    });

    test('bills the resumed month as unpaid', () async {
      final payments = _FakePaymentRepository();
      final outcome = await build(
        payments: payments,
        packages: [_package(costPrice: 1000)],
      )(
        customer: _customer(monthlyBill: 3000),
        active: true,
        cycle: ReactivationCycle.startFresh,
        asOf: DateTime(2026, 8, 7),
      );

      expect(outcome.billed, isTrue);
      expect(outcome.unbilledReason, isNull);

      final charge = payments.added.single;
      expect(charge.amount, 3000);
      expect(charge.paidAmount, 0);
      // 'unpaid', not 'partial' — partial means some cash arrived.
      expect(charge.status, 'unpaid');
      expect(charge.remainingAmount, 3000);
      expect(charge.isSettled, isFalse);
      expect(charge.completedDate, isNull);
      expect(charge.paymentDate, isNull);
    });

    test('shapes the charge to reconcile with every other month', () async {
      final payments = _FakePaymentRepository();
      final outcome = await build(
        payments: payments,
        packages: [_package(costPrice: 1000)],
      )(
        customer: _customer(),
        active: true,
        cycle: ReactivationCycle.startFresh,
        asOf: DateTime(2026, 8, 7),
      );

      final charge = payments.added.single;
      expect(charge.customerId, 'c1');
      expect(charge.billingMonth, '2026-08');
      expect(charge.type, PaymentType.subscription);
      // The day service resumed, not the expiry it buys.
      expect(charge.dueDate, DateTime(2026, 8, 7));
      // The period the charge covers must be the period the customer was
      // actually granted, or the ledger and the expiry tell different stories.
      expect(charge.periodEnd, DateTime(2026, 9, 7));
      expect(charge.periodEnd, outcome.customer.nextDueDate);
      expect(charge.packageCostAtBilling, 1000);
    });

    test('records an unknown upstream cost as null, never zero', () async {
      final payments = _FakePaymentRepository();
      await build(payments: payments, packages: const [])(
        customer: _customer(),
        active: true,
        cycle: ReactivationCycle.startFresh,
        asOf: DateTime(2026, 8, 7),
      );

      // Zero would report the whole bill as margin.
      expect(payments.added.single.packageCostAtBilling, isNull);
    });

    test('clamps a month-end reactivation instead of rolling over', () async {
      // 31 Jan + 1 month must land on 28 Feb, not 3 Mar.
      final outcome = await build()(
        customer: _customer(),
        active: true,
        cycle: ReactivationCycle.startFresh,
        asOf: DateTime(2026, 1, 31),
      );

      expect(outcome.customer.nextDueDate, DateTime(2026, 2, 28));
    });

    test('normalises away the time component', () async {
      final outcome = await build()(
        customer: _customer(),
        active: true,
        cycle: ReactivationCycle.startFresh,
        asOf: DateTime(2026, 8, 7, 23, 59, 59),
      );

      expect(outcome.customer.nextDueDate, DateTime(2026, 9, 7));
    });

    test('reactivates without billing when no monthly bill is set', () async {
      final payments = _FakePaymentRepository();
      final outcome = await build(payments: payments)(
        customer: _customer(monthlyBill: 0),
        active: true,
        cycle: ReactivationCycle.startFresh,
        asOf: DateTime(2026, 8, 7),
      );

      // Service is restored — refusing over a missing rate would be worse
      // than an unbilled month the operator is told about.
      expect(outcome.customer.isActive, isTrue);
      expect(outcome.customer.nextDueDate, DateTime(2026, 9, 7));
      expect(outcome.billed, isFalse);
      expect(outcome.unbilledReason, UnbilledReason.noMonthlyBill);
      expect(payments.added, isEmpty);
    });

    test('does not double-bill a month that already has a charge', () async {
      final existing = PaymentEntity(
        id: 'p1',
        customerId: 'c1',
        customerName: 'Ayesha Khan',
        amount: 3000,
        paidAmount: 3000,
        status: 'paid',
        billingMonth: '2026-08',
      );
      final payments = _FakePaymentRepository(existing: existing);

      final outcome = await build(payments: payments)(
        customer: _customer(),
        active: true,
        cycle: ReactivationCycle.startFresh,
        asOf: DateTime(2026, 8, 7),
      );

      expect(outcome.customer.isActive, isTrue);
      expect(outcome.billed, isFalse);
      expect(outcome.unbilledReason, UnbilledReason.monthAlreadyBilled);
      // A second row would break the (customerId, billingMonth) key.
      expect(payments.added, isEmpty);
      // And the settled row is left exactly as it was.
      expect(payments.updated, isEmpty);
      expect(payments.lookedUpMonths, ['2026-08']);
    });
  });

  group('isActive', () {
    test('is true only for the exact active literal', () {
      expect(_customer(status: 'active').isActive, isTrue);
      expect(_customer(status: 'inactive').isActive, isFalse);
      // A malformed status fails closed: no due date shown, no renewal
      // chased. CustomerModel.fromMap defaults a missing field to ''.
      expect(_customer(status: '').isActive, isFalse);
      expect(_customer(status: 'Active').isActive, isFalse);
    });
  });
}
