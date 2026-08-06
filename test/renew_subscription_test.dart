import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/repositories/customer_repository.dart';
import 'package:nasr_isp/features/customers/domain/usecases/renew_subscription.dart';
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
  Future<List<CustomerEntity>> getCustomers() async => throw UnimplementedError();
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
  Future<List<PaymentEntity>> getAllPayments() async => throw UnimplementedError();
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
  Future<void> updatePackage(PackageEntity p) async => throw UnimplementedError();
  @override
  Future<void> deletePackage(String id) async => throw UnimplementedError();
}

/// Package lookups blow up — the renewal must still take the money.
class _ExplodingPackageRepository extends _FakePackageRepository {
  _ExplodingPackageRepository() : super(const []);

  @override
  Future<List<PackageEntity>> getPackages({
    ConnectionType? filterByType,
    bool? activeOnly,
  }) async =>
      throw StateError('firestore unavailable');
}

// ── Builders ─────────────────────────────────────────────────────

CustomerModel _customer({
  String? packageId = 'pkg1',
  double monthlyBill = 3000,
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
      status: 'active',
      notes: '',
      createdAt: DateTime(2026, 1, 5),
      joinDate: DateTime(2026, 1, 5),
      nextDueDate: nextDueDate ?? DateTime(2026, 8, 5),
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

RenewSubscription _useCase({
  required _FakePaymentRepository payments,
  required _FakeCustomerRepository customers,
  _FakePackageRepository? packages,
}) =>
    RenewSubscription(
      paymentRepository: payments,
      customerRepository: customers,
      getPackages: GetPackages(packages ?? _FakePackageRepository([_package()])),
    );

void main() {
  group('a full renewal', () {
    late _FakePaymentRepository payments;
    late _FakeCustomerRepository customers;
    late RenewalOutcome outcome;

    setUp(() async {
      payments = _FakePaymentRepository();
      customers = _FakeCustomerRepository();
      outcome = await _useCase(payments: payments, customers: customers)(
        customer: _customer(),
        amountReceived: 3000,
        renewalDate: DateTime(2026, 8, 10),
        method: 'cash',
      );
    });

    test('sets the new expiry one month from the RENEWAL date', () {
      // Not from the old due date (Aug 5) — a customer paying late gets a full
      // month from the day they paid.
      expect(outcome.renewedUntil, DateTime(2026, 9, 10));
      expect(customers.updated.single.nextDueDate, DateTime(2026, 9, 10));
    });

    test('writes one charge keyed to the renewal month', () {
      expect(payments.added, hasLength(1));
      expect(payments.updated, isEmpty);
      expect(payments.added.single.billingMonth, '2026-08');
    });

    test('records it as a settled subscription charge', () {
      final charge = payments.added.single;
      expect(charge.type, PaymentType.subscription);
      expect(charge.status, 'paid');
      expect(charge.amount, 3000);
      expect(charge.paidAmount, 3000);
      expect(charge.remainingAmount, 0);
      expect(charge.completedDate, DateTime(2026, 8, 10));
      expect(outcome.isPaidInFull, isTrue);
      expect(outcome.outstanding, 0);
    });

    test('dueDate is the expiry being cured, not the next one', () {
      // The old code stored the NEXT due date here, which made the payments
      // table's date column mean the opposite of its label.
      expect(payments.added.single.dueDate, DateTime(2026, 8, 5));
      expect(payments.added.single.periodEnd, DateTime(2026, 9, 10));
    });

    test('snapshots the upstream cost onto the charge', () {
      expect(payments.added.single.packageCostAtBilling, 1000);
    });

    test('realized margin equals bill minus upstream cost', () {
      expect(payments.added.single.collectedMargin().profit, 2000);
    });
  });

  group('a part payment', () {
    late _FakePaymentRepository payments;
    late RenewalOutcome outcome;

    setUp(() async {
      payments = _FakePaymentRepository();
      final customers = _FakeCustomerRepository();
      outcome = await _useCase(payments: payments, customers: customers)(
        customer: _customer(),
        amountReceived: 1200,
        renewalDate: DateTime(2026, 8, 10),
        method: 'cash',
      );
    });

    test('still renews the subscription', () {
      // The operator has granted the month; the shortfall is a receivable, not
      // a reason to leave the customer disconnected.
      expect(outcome.renewedUntil, DateTime(2026, 9, 10));
    });

    test('leaves the balance outstanding and the charge open', () {
      final charge = payments.added.single;
      expect(charge.status, 'partial');
      expect(charge.paidAmount, 1200);
      expect(charge.remainingAmount, 1800);
      expect(charge.completedDate, isNull);
      expect(outcome.isPaidInFull, isFalse);
      expect(outcome.outstanding, 1800);
    });

    test('charges the full upstream cost against the part collection', () {
      // The ISP pays for the bandwidth either way, so an under-collected
      // month reads as a loss rather than a smaller profit.
      expect(payments.added.single.collectedMargin().profit, 200);
    });
  });

  group('an existing charge for the month', () {
    test('is topped up in place rather than duplicated', () async {
      final existing = PaymentEntity(
        id: 'pay1',
        customerId: 'c1',
        customerName: 'Ayesha Khan',
        amount: 3000,
        paidAmount: 1200,
        status: 'partial',
        billingMonth: '2026-08',
        packageCostAtBilling: 1000,
      );
      final payments = _FakePaymentRepository(existing: existing);
      final customers = _FakeCustomerRepository();

      final outcome = await _useCase(payments: payments, customers: customers)(
        customer: _customer(),
        amountReceived: 1800,
        renewalDate: DateTime(2026, 8, 20),
        method: 'cash',
      );

      expect(payments.added, isEmpty);
      expect(payments.updated, hasLength(1));
      expect(payments.updated.single.paidAmount, 3000);
      expect(payments.updated.single.status, 'paid');
      expect(outcome.isPaidInFull, isTrue);
    });

    test('keeps the original cost snapshot when re-priced since', () async {
      final existing = PaymentEntity(
        id: 'pay1',
        customerId: 'c1',
        customerName: 'Ayesha Khan',
        amount: 3000,
        paidAmount: 500,
        status: 'partial',
        billingMonth: '2026-08',
        packageCostAtBilling: 900,
      );
      final payments = _FakePaymentRepository(existing: existing);

      await _useCase(payments: payments, customers: _FakeCustomerRepository())(
        customer: _customer(),
        amountReceived: 500,
        renewalDate: DateTime(2026, 8, 20),
        method: 'cash',
      );

      // History is not rewritten by a later package re-price.
      expect(payments.updated.single.packageCostAtBilling, 900);
    });
  });

  group('cost resolution', () {
    test('is null when no package is assigned', () async {
      final payments = _FakePaymentRepository();
      await _useCase(payments: payments, customers: _FakeCustomerRepository())(
        customer: _customer(packageId: null),
        amountReceived: 3000,
        renewalDate: DateTime(2026, 8, 10),
        method: 'cash',
      );
      // Null, not zero — zero would silently report the whole bill as margin.
      expect(payments.added.single.packageCostAtBilling, isNull);
    });

    test('is null when the package carries no cost price', () async {
      final payments = _FakePaymentRepository();
      await _useCase(
        payments: payments,
        customers: _FakeCustomerRepository(),
        packages: _FakePackageRepository([_package(costPrice: 0)]),
      )(
        customer: _customer(),
        amountReceived: 3000,
        renewalDate: DateTime(2026, 8, 10),
        method: 'cash',
      );
      expect(payments.added.single.packageCostAtBilling, isNull);
    });

    test('a package lookup failure does not block the collection', () async {
      final payments = _FakePaymentRepository();
      final customers = _FakeCustomerRepository();
      await _useCase(
        payments: payments,
        customers: customers,
        packages: _ExplodingPackageRepository(),
      )(
        customer: _customer(),
        amountReceived: 3000,
        renewalDate: DateTime(2026, 8, 10),
        method: 'cash',
      );

      expect(payments.added.single.paidAmount, 3000);
      expect(payments.added.single.packageCostAtBilling, isNull);
      expect(customers.updated.single.nextDueDate, DateTime(2026, 9, 10));
    });
  });

  group('guards', () {
    test('rejects collecting more than the monthly bill', () {
      expect(
        () => _useCase(
          payments: _FakePaymentRepository(),
          customers: _FakeCustomerRepository(),
        )(
          customer: _customer(monthlyBill: 3000),
          amountReceived: 3500,
          renewalDate: DateTime(2026, 8, 10),
          method: 'cash',
        ),
        throwsArgumentError,
      );
    });

    test('rejects a negative amount', () {
      expect(
        () => _useCase(
          payments: _FakePaymentRepository(),
          customers: _FakeCustomerRepository(),
        )(
          customer: _customer(),
          amountReceived: -100,
          renewalDate: DateTime(2026, 8, 10),
          method: 'cash',
        ),
        throwsArgumentError,
      );
    });

    test('rejects a customer with no monthly bill set', () {
      expect(
        () => _useCase(
          payments: _FakePaymentRepository(),
          customers: _FakeCustomerRepository(),
        )(
          customer: _customer(monthlyBill: 0),
          amountReceived: 0,
          renewalDate: DateTime(2026, 8, 10),
          method: 'cash',
        ),
        throwsStateError,
      );
    });
  });

  test('a month-end renewal clamps rather than rolling over', () async {
    final payments = _FakePaymentRepository();
    final customers = _FakeCustomerRepository();
    final outcome = await _useCase(payments: payments, customers: customers)(
      customer: _customer(nextDueDate: DateTime(2026, 1, 31)),
      amountReceived: 3000,
      renewalDate: DateTime(2026, 1, 31),
      method: 'cash',
    );

    expect(outcome.renewedUntil, DateTime(2026, 2, 28));
  });
}
