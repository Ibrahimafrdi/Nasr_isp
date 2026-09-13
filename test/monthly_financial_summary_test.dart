import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/repositories/customer_repository.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
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
import 'package:nasr_isp/features/reports/domain/usecases/get_available_report_months.dart';
import 'package:nasr_isp/features/reports/domain/usecases/get_monthly_financial_summary.dart';

// Fake repos
class _FakeCustomerRepository implements CustomerRepository {
  final List<CustomerModel> customers;
  _FakeCustomerRepository(this.customers);
  @override
  Future<List<CustomerEntity>> getCustomers() async => customers;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentRepository implements PaymentRepository {
  final List<PaymentModel> payments;
  _FakePaymentRepository(this.payments);
  @override
  Future<List<PaymentEntity>> getAllPayments() async => payments;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeExpenseRepository implements ExpenseRepository {
  final List<ExpenseModel> expenses;
  _FakeExpenseRepository(this.expenses);
  @override
  Future<List<ExpenseEntity>> getExpenses() async => expenses;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInstallationRepository implements InstallationRepository {
  final List<InstallationEntity> installations;
  _FakeInstallationRepository(this.installations);
  @override
  Future<List<InstallationEntity>> getInstallations({
    String? status,
    String? connectionType,
    String? employeeId,
    String? searchQuery,
  }) async =>
      installations;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePackageRepository implements PackageRepository {
  final List<PackageEntity> packages;
  _FakePackageRepository(this.packages);
  @override
  Future<List<PackageEntity>> getPackages({
    ConnectionType? filterByType,
    bool? activeOnly,
  }) async =>
      packages;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('GetMonthlyFinancialSummary', () {
    test('calculates billed, collected, installation profit, expenses, and net profit correctly', () async {
      final customers = <CustomerModel>[
        CustomerModel(
          id: 'c1',
          name: 'Alice',
          phone: '03001234567',
          cnic: '1234567890123',
          address: 'Peshawar',
          connectionType: 'fiber',
          packageId: 'pkg1',
          monthlyBill: 3000,
          status: 'active',
          notes: '',
          joinDate: DateTime(2026, 8, 1),
          createdAt: DateTime(2026, 8, 1),
        ),
      ];

      final packages = <PackageEntity>[
        PackageEntity(
          id: 'pkg1',
          name: 'Pro 50M',
          price: 3000,
          costPrice: 1500,
          speedMbps: 50,
          connectionType: ConnectionType.opticalFibre,
          isActive: true,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      final payments = <PaymentModel>[
        // Subscription payment for 2026-09
        PaymentModel(
          id: 'p1',
          customerId: 'c1',
          customerName: 'Alice',
          amount: 3000,
          paidAmount: 3000,
          billingMonth: '2026-09',
          status: 'paid',
          createdAt: DateTime(2026, 9, 2),
        ),
        // Installation payment (should be excluded from subscription figures)
        PaymentModel(
          id: 'p2',
          customerId: 'c1',
          customerName: 'Alice',
          amount: 5000,
          paidAmount: 5000,
          status: 'paid',
          createdAt: DateTime(2026, 9, 3),
        ),
      ];

      final installations = <InstallationEntity>[
        InstallationEntity(
          id: 'inst1',
          customerId: 'c1',
          customerName: 'Alice',
          connectionType: ConnectionType.opticalFibre,
          installationDate: DateTime(2026, 9, 5),
          installationCost: 5000, // setup revenue billed to customer
          laborCost: 1000,
          equipmentCost: 1000,
          status: InstallationStatus.completed,
          completedAt: DateTime(2026, 9, 5),
          createdAt: DateTime(2026, 9, 1),
        ),
      ];

      final expenses = <ExpenseModel>[
        ExpenseModel(
          id: 'e1',
          title: 'Electric Bill',
          amount: 1200,
          category: ExpenseCategory.electricity,
          paidBy: 'Admin',
          date: DateTime(2026, 9, 10),
        ),
      ];

      final usecase = GetMonthlyFinancialSummary(
        getCustomers: GetCustomers(_FakeCustomerRepository(customers)),
        getAllPayments: GetAllPayments(_FakePaymentRepository(payments)),
        getExpenses: GetExpenses(_FakeExpenseRepository(expenses)),
        getInstallations: GetInstallations(_FakeInstallationRepository(installations)),
        getPackages: GetPackages(_FakePackageRepository(packages)),
      );

      final summary = await usecase(DateTime(2026, 9, 15));

      expect(summary.monthKey, '2026-09');
      expect(summary.subscriptionBilled, 3000.0);
      expect(summary.subscriptionCollected, 3000.0);
      expect(summary.installationRevenue, 5000.0);
      expect(summary.installationCost, 2000.0);    // 1000 labour + 1000 equipment
      expect(summary.installationProfit, 3000.0);  // 5000 - 2000
      expect(summary.totalExpenses, 1200.0);
      // Net Profit = subscriptionCollected (3000) + installationProfit (3000) - totalExpenses (1200) = 4800
      expect(summary.netProfit, 4800.0);
      expect(summary.expensesByCategory[ExpenseCategory.electricity], 1200.0);
      expect(summary.unpricedCustomerCount, 0);
    });
  });

  group('GetAvailableReportMonths', () {
    test('returns chronological list of months from earliest record to now', () async {
      final customers = <CustomerModel>[
        CustomerModel(
          id: 'c1',
          name: 'Old Customer',
          phone: '03001234567',
          cnic: '1234567890123',
          address: 'Peshawar',
          connectionType: 'fiber',
          monthlyBill: 3000,
          status: 'active',
          notes: '',
          joinDate: DateTime(2026, 7, 10),
          createdAt: DateTime(2026, 7, 10),
        ),
      ];

      final usecase = GetAvailableReportMonths(
        getCustomers: GetCustomers(_FakeCustomerRepository(customers)),
        getAllPayments: GetAllPayments(_FakePaymentRepository([])),
        getExpenses: GetExpenses(_FakeExpenseRepository([])),
      );

      final months = await usecase();
      expect(months, contains('2026-07'));
      expect(months, contains('2026-08'));
      expect(months, contains('2026-09'));
      expect(months.first, '2026-07');
    });
  });
}
