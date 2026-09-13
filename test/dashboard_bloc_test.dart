import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/repositories/customer_repository.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:nasr_isp/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:nasr_isp/features/expenses/data/models/expense_model.dart';
import 'package:nasr_isp/features/expenses/domain/entities/expense_entity.dart';
import 'package:nasr_isp/features/expenses/domain/repositories/expense_repository.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/get_expenses.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_item_used_entity.dart';
import 'package:nasr_isp/features/installations/domain/repositories/installation_repository.dart';
import 'package:nasr_isp/features/installations/domain/usecases/get_installations.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_all_payments.dart';
import 'package:nasr_isp/features/reports/domain/usecases/get_monthly_financial_summary.dart';

// ── Fakes ────────────────────────────────────────────────────────
// Hand-written, matching the project's convention (no mocking library).
// We fake the repositories — they are real abstract interfaces — and wrap
// them in the real use cases, which are concrete classes with no interface.

class _FakeCustomerRepository implements CustomerRepository {
  _FakeCustomerRepository(this.customers);
  final List<CustomerModel> customers;

  @override
  Future<List<CustomerEntity>> getCustomers() async => customers;

  @override
  Future<void> addCustomer(CustomerEntity c) async => throw UnimplementedError();
  @override
  Future<void> updateCustomer(CustomerEntity c) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteCustomer(String id) async => throw UnimplementedError();
}

class _FakePaymentRepository implements PaymentRepository {
  _FakePaymentRepository(this.payments);
  final List<PaymentModel> payments;

  @override
  Future<List<PaymentEntity>> getAllPayments() async => payments;

  @override
  Future<void> addPayment(PaymentEntity p) async => throw UnimplementedError();
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
  Future<void> updatePayment(PaymentEntity p) async =>
      throw UnimplementedError();
  @override
  Future<void> deletePayment(String id) async => throw UnimplementedError();
  @override
  Future<int> getTotalPaymentsCount() async => throw UnimplementedError();
  @override
  Future<PaymentEntity?> getPaymentByCustomerAndMonth(
    String customerId,
    String billingMonth,
  ) async =>
      throw UnimplementedError();
}

class _FakeExpenseRepository implements ExpenseRepository {
  _FakeExpenseRepository(this.expenses);
  final List<ExpenseModel> expenses;

  @override
  Future<List<ExpenseEntity>> getExpenses() async => expenses;

  @override
  Future<void> addExpense(ExpenseEntity e) async => throw UnimplementedError();
  @override
  Future<void> updateExpense(ExpenseEntity e) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteExpense(String id) async => throw UnimplementedError();
}

class _FakeInstallationRepository implements InstallationRepository {
  _FakeInstallationRepository(this.installations);
  final List<InstallationEntity> installations;

  @override
  Future<List<InstallationEntity>> getInstallations({
    String? status,
    String? connectionType,
    String? employeeId,
    String? searchQuery,
  }) async =>
      installations;

  @override
  Future<void> createInstallation(InstallationEntity i) async =>
      throw UnimplementedError();
  @override
  Future<void> updateInstallation(InstallationEntity i) async =>
      throw UnimplementedError();
  @override
  Future<List<InstallationEntity>> getInstallationsByCustomer(String id) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteInstallation(String id) async => throw UnimplementedError();
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

final _fixedNow = DateTime(2026, 7, 15);

DashboardBloc _bloc({
  List<CustomerModel> customers = const [],
  List<PaymentModel> payments = const [],
  List<ExpenseModel> expenses = const [],
  List<InstallationEntity> installations = const [],
  List<PackageEntity> packages = const [],
}) {
  final getCustomers = GetCustomers(_FakeCustomerRepository(customers));
  final getAllPayments = GetAllPayments(_FakePaymentRepository(payments));
  final getExpenses = GetExpenses(_FakeExpenseRepository(expenses));
  final getInstallations = GetInstallations(_FakeInstallationRepository(installations));
  final getPackages = GetPackages(_FakePackageRepository(packages));

  return DashboardBloc(
    getCustomers: getCustomers,
    getAllPayments: getAllPayments,
    getExpenses: getExpenses,
    getInstallations: getInstallations,
    getPackages: getPackages,
    getMonthlyFinancialSummary: GetMonthlyFinancialSummary(
      getCustomers: getCustomers,
      getAllPayments: getAllPayments,
      getExpenses: getExpenses,
      getInstallations: getInstallations,
      getPackages: getPackages,
    ),
    // Fixed clock: month bucketing would otherwise be flaky on the first and
    // last days of a real month.
    clock: () => _fixedNow,
  );
}

Future<DashboardStatsModel> _statsFrom(DashboardBloc bloc) async {
  bloc.add(const LoadDashboardEvent());
  final loaded = await bloc.stream.firstWhere((s) => s is DashboardLoaded);
  return (loaded as DashboardLoaded).stats;
}

CustomerModel _customer({
  String id = 'c1',
  String? packageId,
  double monthlyBill = 3000,
  String status = 'active',
  DateTime? nextDueDate,
}) =>
    CustomerModel(
      id: id,
      name: 'Customer $id',
      phone: '03001234567',
      cnic: '1234567890123',
      address: 'Peshawar',
      connectionType: 'fiber',
      packageId: packageId,
      monthlyBill: monthlyBill,
      status: status,
      notes: '',
      createdAt: DateTime(2026, 1, 1),
      // Comfortably after _fixedNow, so a customer is neither expired nor
      // expiring unless a test says otherwise.
      nextDueDate: nextDueDate ?? DateTime(2026, 8, 1),
    );

PackageEntity _package({String id = 'pkg1', double costPrice = 1000}) =>
    PackageEntity(
      id: id,
      name: 'Fiber 20',
      speedMbps: 20,
      price: 3000,
      costPrice: costPrice,
      connectionType: ConnectionType.opticalFibre,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

PaymentModel _payment({
  String id = 'p1',
  String customerId = 'c1',
  double amount = 3000,
  double paidAmount = 3000,
  String status = 'paid',
  DateTime? completedDate,
  String? billingMonth,
  double? packageCostAtBilling,
}) =>
    PaymentModel(
      id: id,
      customerId: customerId,
      customerName: 'Customer $customerId',
      amount: amount,
      paidAmount: paidAmount,
      status: status,
      completedDate: completedDate ?? DateTime(2026, 7, 5),
      createdAt: DateTime(2026, 7, 5),
      billingMonth: billingMonth,
      packageCostAtBilling: packageCostAtBilling,
    );

/// A charge in the shape RenewSubscription produces for the fixed clock's
/// month, so the reconciliation assertions exercise the real code path.
PaymentModel _renewal({
  String id = 'r1',
  String customerId = 'c1',
  double amount = 3000,
  double? paidAmount,
  double? packageCostAtBilling = 1000,
}) {
  final paid = paidAmount ?? amount;
  return PaymentModel(
    id: id,
    customerId: customerId,
    customerName: 'Customer $customerId',
    amount: amount,
    paidAmount: paid,
    status: paid >= amount ? 'paid' : 'partial',
    billingMonth: '2026-07', // matches _fixedNow
    periodEnd: DateTime(2026, 8, 5),
    completedDate: paid >= amount ? DateTime(2026, 7, 5) : null,
    createdAt: DateTime(2026, 7, 5),
    packageCostAtBilling: packageCostAtBilling,
  );
}

ExpenseModel _expense({double amount = 1000, DateTime? date}) => ExpenseModel(
      id: 'e1',
      title: 'Fuel',
      category: ExpenseCategory.fuel,
      amount: amount,
      date: date ?? DateTime(2026, 7, 3),
      paidBy: 'Admin',
    );

InstallationEntity _installation({
  String id = 'i1',
  double installationCost = 3000,
  double? laborCost,
  double? equipmentCost,
  List<InstallationItemUsedEntity>? itemsUsed,
  InstallationStatus status = InstallationStatus.completed,
  DateTime? createdAt,
  DateTime? completedAt,
}) =>
    InstallationEntity(
      id: id,
      customerId: 'c1',
      customerName: 'Customer c1',
      connectionType: ConnectionType.wireless,
      installationDate: DateTime(2026, 7, 2),
      installationCost: installationCost,
      status: status,
      itemsUsed: itemsUsed,
      createdAt: createdAt ?? DateTime(2026, 7, 2),
      completedAt: completedAt ?? DateTime(2026, 7, 2),
      equipmentCost: equipmentCost,
      laborCost: laborCost,
    );

InstallationItemUsedEntity _item({
  required double cost,
  required double sell,
  int qty = 1,
}) =>
    InstallationItemUsedEntity(
      inventoryItemId: 'inv1',
      itemName: 'Router',
      quantity: qty,
      costPriceAtTime: cost,
      sellPriceAtTime: sell,
    );

void main() {
  group('netProfit reconciliation (accrual)', () {
    test('equals recurring margin + installation profit - expenses', () {
      final bloc = _bloc(
        customers: [_customer(packageId: 'pkg1')],
        packages: [_package()],
        installations: [
          _installation(
            installationCost: 3000,
            laborCost: 500,
            itemsUsed: [_item(cost: 100, sell: 150, qty: 2)],
          ),
        ],
        expenses: [_expense(amount: 1000)],
      );

      return _statsFrom(bloc).then((stats) {
        // Assert each term individually so a failure localises.
        expect(stats.subscriberRunRateMargin, 2000.0); // 3000 - 1000
        expect(stats.monthlyInstallationProfit, 2600.0); // 3300 - 700
        expect(stats.monthlyExpenses, 1000.0);
        expect(stats.netProfit, 3600.0); // 2000 + 2600 - 1000
        expect(
          stats.netProfit,
          stats.subscriberRunRateMargin +
              stats.monthlyInstallationProfit -
              stats.monthlyExpenses,
        );
      });
    });

    test('recurring margin does not depend on who has paid', () async {
      // The regression guard for the original mixed-basis bug: the accrual
      // term must be identical whether or not payments exist.
      final unpaid = await _statsFrom(_bloc(
        customers: [_customer(packageId: 'pkg1')],
        packages: [_package()],
      ));
      final paid = await _statsFrom(_bloc(
        customers: [_customer(packageId: 'pkg1')],
        packages: [_package()],
        payments: [_payment()],
      ));

      expect(unpaid.subscriberRunRateMargin, paid.subscriberRunRateMargin);
      expect(unpaid.netProfit, paid.netProfit);
      expect(unpaid.cashCollectedThisMonth, 0.0);
      expect(paid.cashCollectedThisMonth, 3000.0);
    });

    test('cash collected is not a term of netProfit', () async {
      final stats = await _statsFrom(_bloc(
        customers: [_customer(packageId: 'pkg1')],
        packages: [_package()],
        payments: [_payment(paidAmount: 3000), _payment(id: 'p2', paidAmount: 3000)],
      ));

      expect(stats.cashCollectedThisMonth, 6000.0);
      expect(stats.netProfit, 2000.0); // unchanged by the cash above
    });

    test('cash counts only paid rows, partials feed pending instead', () async {
      final stats = await _statsFrom(_bloc(
        payments: [
          _payment(status: 'partial', amount: 1500, paidAmount: 500),
        ],
      ));

      expect(stats.cashCollectedThisMonth, 0.0);
      expect(stats.pendingPayments, 1000.0);
    });
  });

  group('current-month collection reconciles against the run rate', () {
    // The property the whole renewal redesign turns on: once every active
    // subscriber has been renewed and paid in full, the margin realized in
    // cash equals the accrual run rate exactly.
    test('collected margin equals the run rate when everyone has paid',
        () async {
      final stats = await _statsFrom(_bloc(
        customers: [
          _customer(id: 'c1', packageId: 'pkg1'),
          _customer(id: 'c2', packageId: 'pkg1'),
          _customer(id: 'c3', packageId: 'pkg1'),
        ],
        packages: [_package(costPrice: 1000)],
        payments: [
          _renewal(id: 'r1', customerId: 'c1'),
          _renewal(id: 'r2', customerId: 'c2'),
          _renewal(id: 'r3', customerId: 'c3'),
        ],
      ));

      expect(stats.subscriberRunRateMargin, 6000.0); // 3 * (3000 - 1000)
      expect(stats.currentMonthMarginCollected, 6000.0);
      expect(stats.currentMonthMarginCollected, stats.subscriberRunRateMargin);
      expect(stats.marginNotYetCollected, 0.0);
      expect(stats.marginCollectionRate, 1.0);
      expect(stats.pendingThisMonth, 0.0);
    });

    test('the shortfall is exactly the margin of who has not renewed',
        () async {
      final stats = await _statsFrom(_bloc(
        customers: [
          _customer(id: 'c1', packageId: 'pkg1'),
          _customer(id: 'c2', packageId: 'pkg1'),
        ],
        packages: [_package(costPrice: 1000)],
        payments: [_renewal(id: 'r1', customerId: 'c1')],
      ));

      expect(stats.subscriberRunRateMargin, 4000.0);
      expect(stats.currentMonthMarginCollected, 2000.0);
      expect(stats.marginNotYetCollected, 2000.0);
      expect(stats.marginCollectionRate, 0.5);
    });

    test('a part-paid renewal absorbs the full upstream cost', () async {
      // Collected 1200 of a 3000 bill on a 1000-cost package: realized margin
      // is 200, not 1200 * (2000/3000).
      final stats = await _statsFrom(_bloc(
        customers: [_customer(packageId: 'pkg1')],
        packages: [_package(costPrice: 1000)],
        payments: [_renewal(paidAmount: 1200)],
      ));

      expect(stats.currentMonthCollected, 1200.0);
      expect(stats.currentMonthMarginCollected, 200.0);
      expect(stats.currentMonthOutstanding, 1800.0);
      expect(stats.pendingThisMonth, 1800.0);
    });

    test('an under-collected month can read as a loss', () async {
      final stats = await _statsFrom(_bloc(
        customers: [_customer(packageId: 'pkg1')],
        packages: [_package(costPrice: 1000)],
        payments: [_renewal(paidAmount: 400)],
      ));

      expect(stats.currentMonthMarginCollected, -600.0);
    });

    test('a legacy charge falls back to the live package cost', () async {
      // Without the fallback this would report 3000 of margin on a 1000-cost
      // package and break the reconciliation for every pre-existing row.
      final stats = await _statsFrom(_bloc(
        customers: [_customer(packageId: 'pkg1')],
        packages: [_package(costPrice: 1000)],
        payments: [_renewal(packageCostAtBilling: null)],
      ));

      expect(stats.currentMonthMarginCollected, 2000.0);
      expect(stats.currentMonthMarginCollected, stats.subscriberRunRateMargin);
    });

    test('a charge for another month does not count toward this one', () async {
      final stats = await _statsFrom(_bloc(
        customers: [_customer(packageId: 'pkg1')],
        packages: [_package(costPrice: 1000)],
        payments: [_payment(billingMonth: '2026-06')],
      ));

      expect(stats.currentMonthCollected, 0.0);
      expect(stats.currentMonthMarginCollected, 0.0);
      // Cash basis still sees it — that is the difference between the two.
      expect(stats.cashCollectedThisMonth, 3000.0);
    });
  });

  group('pending this month', () {
    test('counts lapsed customers who have no charge for the month', () async {
      final stats = await _statsFrom(_bloc(
        customers: [
          _customer(id: 'c1', packageId: 'pkg1', nextDueDate: DateTime(2026, 7, 1)),
          _customer(id: 'c2', packageId: 'pkg1', nextDueDate: DateTime(2026, 7, 3)),
        ],
        packages: [_package()],
      ));

      expect(stats.expiredCustomers, 2);
      expect(stats.expiredCustomersDueCount, 2);
      expect(stats.expiredCustomersDue, 6000.0);
      expect(stats.pendingThisMonth, 6000.0);
    });

    test('a lapsed customer already renewed this month is not double counted',
        () async {
      // c1 lapsed on Jul 1 and was renewed on Jul 5 — their money is tracked
      // by the charge, so counting their bill again would inflate pending.
      final stats = await _statsFrom(_bloc(
        customers: [
          _customer(id: 'c1', packageId: 'pkg1', nextDueDate: DateTime(2026, 7, 1)),
        ],
        packages: [_package()],
        payments: [_renewal(customerId: 'c1', paidAmount: 1000)],
      ));

      expect(stats.expiredCustomersDueCount, 0);
      expect(stats.expiredCustomersDue, 0.0);
      expect(stats.currentMonthOutstanding, 2000.0);
      expect(stats.pendingThisMonth, 2000.0);
    });

    test('a cancelled customer is never chased for a renewal', () async {
      final stats = await _statsFrom(_bloc(
        customers: [
          _customer(
            id: 'c1',
            packageId: 'pkg1',
            status: 'cancelled',
            nextDueDate: DateTime(2026, 1, 1),
          ),
        ],
        packages: [_package()],
      ));

      expect(stats.expiredCustomers, 0);
      expect(stats.expiredCustomersDue, 0.0);
    });

    test('the due date itself is not yet expired', () async {
      final stats = await _statsFrom(_bloc(
        customers: [
          _customer(id: 'c1', packageId: 'pkg1', nextDueDate: _fixedNow),
        ],
        packages: [_package()],
      ));

      expect(stats.expiredCustomers, 0);
      expect(stats.expiringsoon, 1);
    });
  });

  group('installation aggregates', () {
    test('revenue includes material sell price, not just the setup fee', () async {
      // Pre-fix this reported 3000 and made profit exceed revenue.
      final stats = await _statsFrom(_bloc(
        installations: [
          _installation(
            installationCost: 3000,
            laborCost: 500,
            itemsUsed: [_item(cost: 100, sell: 150, qty: 2)],
          ),
        ],
      ));

      expect(stats.monthlyInstallationRevenue, 3300.0); // 3000 + 2*150
      expect(stats.monthlyInstallationCost, 700.0); // 2*100 + 500
      expect(stats.monthlyInstallationProfit, 2600.0);
    });

    test('revenue - cost == profit across a mixed set of jobs', () async {
      final stats = await _statsFrom(_bloc(
        installations: [
          _installation(
            id: 'bom',
            installationCost: 3000,
            laborCost: 500,
            itemsUsed: [_item(cost: 100, sell: 150, qty: 2)],
          ),
          _installation(id: 'legacy', installationCost: 1000, equipmentCost: 300),
          _installation(id: 'feeOnly', installationCost: 2500),
          _installation(id: 'noLabor', installationCost: 800, laborCost: null),
        ],
      ));

      expect(
        stats.monthlyInstallationRevenue - stats.monthlyInstallationCost,
        stats.monthlyInstallationProfit,
      );
    });

    test('a legacy equipmentCost job bills only its fee', () async {
      final stats = await _statsFrom(_bloc(
        installations: [
          _installation(installationCost: 1000, equipmentCost: 300),
        ],
      ));

      expect(stats.monthlyInstallationRevenue, 1000.0);
      expect(stats.monthlyInstallationCost, 300.0);
      expect(stats.monthlyInstallationProfit, 700.0);
    });
  });

  group('installation scoping', () {
    test('a cancelled job contributes no revenue, cost or profit', () async {
      final stats = await _statsFrom(_bloc(
        installations: [
          _installation(
            id: 'cancelled',
            installationCost: 9999,
            laborCost: 500,
            status: InstallationStatus.cancelled,
            itemsUsed: [_item(cost: 100, sell: 150, qty: 5)],
          ),
        ],
      ));

      expect(stats.monthlyInstallationRevenue, 0.0);
      expect(stats.monthlyInstallationCost, 0.0);
      expect(stats.monthlyInstallationProfit, 0.0);
    });

    test('pending and in-progress jobs count in the pipeline, not in money',
        () async {
      final stats = await _statsFrom(_bloc(
        installations: [
          _installation(id: 'p', status: InstallationStatus.pending),
          _installation(id: 'ip', status: InstallationStatus.inProgress),
        ],
      ));

      expect(stats.pendingInstallations, 2);
      expect(stats.monthlyInstallationRevenue, 0.0);
      expect(stats.monthlyInstallationProfit, 0.0);
    });

    test('a job completed last month is excluded from the monthly figures',
        () async {
      final stats = await _statsFrom(_bloc(
        installations: [
          _installation(
            createdAt: DateTime(2026, 6, 1),
            completedAt: DateTime(2026, 6, 10),
          ),
        ],
      ));

      expect(stats.monthlyInstallationRevenue, 0.0);
      // completedInstallations is all-time by design, unlike the money above.
      expect(stats.completedInstallations, 1);
    });

    test('buckets by completedAt, not createdAt, when both exist', () async {
      final stats = await _statsFrom(_bloc(
        installations: [
          _installation(
            installationCost: 1500,
            createdAt: DateTime(2026, 5, 2),
            completedAt: DateTime(2026, 7, 3),
          ),
        ],
      ));

      expect(stats.monthlyInstallationRevenue, 1500.0);
    });
  });

  group('subscriber run rate', () {
    test('excludes non-active customers regardless of their bill', () async {
      final stats = await _statsFrom(_bloc(
        customers: [
          _customer(id: 'c1', packageId: 'pkg1'),
          _customer(id: 'c2', packageId: 'pkg1', status: 'cancelled'),
        ],
        packages: [_package()],
      ));

      expect(stats.subscriberRunRateMargin, 2000.0);
      expect(stats.activeCustomers, 1);
    });

    test('subtracts the package cost, not just the monthly bill', () async {
      // monthlyBill is the negotiated rate and is independent of the package
      // price; the package supplies only the cost side.
      final stats = await _statsFrom(_bloc(
        customers: [_customer(packageId: 'pkg1', monthlyBill: 3000)],
        packages: [_package(costPrice: 1000)],
      ));

      expect(stats.subscriberRunRateMargin, 2000.0);
      expect(stats.unpricedCustomerCount, 0);
    });

    test('a customer with no usable package cost is counted as unpriced',
        () async {
      final stats = await _statsFrom(_bloc(
        customers: [
          _customer(id: 'c1', packageId: 'deleted_pkg'), // set but unresolvable
          _customer(id: 'c2', packageId: null), // never assigned
          _customer(id: 'c3', packageId: ''), // empty string, as the seeder wrote
          _customer(id: 'c4', packageId: 'pkg1'), // properly linked
        ],
        packages: [_package(costPrice: 1000)],
      ));

      // The three unpriced customers contribute their whole bill as margin —
      // the symptom of "monthly bill is entirely considered profit".
      expect(stats.subscriberRunRateMargin, 11000.0); // 3*3000 + (3000-1000)
      expect(stats.unpricedCustomerCount, 3);
    });
  });
}
