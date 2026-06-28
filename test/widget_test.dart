import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/main.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/features/auth/presentation/pages/login_page.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/auth/data/models/user_model.dart';
import 'package:nasr_isp/features/auth/domain/repositories/auth_repository.dart';
import 'package:nasr_isp/features/customers/domain/repositories/customer_repository.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/customers/domain/usecases/add_customer.dart';
import 'package:nasr_isp/features/customers/domain/usecases/update_customer.dart';
import 'package:nasr_isp/features/customers/domain/usecases/delete_customer.dart';
import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/packages/domain/usecases/add_package.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:nasr_isp/features/employees/presentation/bloc/employees_bloc.dart';
import 'package:nasr_isp/features/expenses/presentation/bloc/expenses_bloc.dart';
import 'package:nasr_isp/features/installations/presentation/bloc/installations_bloc.dart';
import 'package:nasr_isp/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:nasr_isp/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_payments.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/expenses/domain/repositories/expense_repository.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/get_expenses.dart';
import 'package:nasr_isp/shared/models/models.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserModel> login({required String email, required String password}) async {
    return const UserModel(
      id: 'admin_uid',
      email: 'admin@nasr.com',
      role: 'admin',
      name: 'Admin User',
      phone: '1234567890',
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserModel?> getCurrentUser() async => null;
}

class FakeCustomerRepository implements CustomerRepository {
  @override
  Future<void> addCustomer(CustomerEntity customer) async {}
  @override
  Future<List<CustomerEntity>> getCustomers() async => [];
  @override
  Future<void> updateCustomer(CustomerEntity customer) async {}
  @override
  Future<void> deleteCustomer(String id) async {}
}

class FakePackageRepository implements PackageRepository {
  @override
  Future<void> addPackage(PackageEntity package) async {}
  @override
  Future<List<PackageEntity>> getPackages() async => [];
}

class FakePaymentRepository implements PaymentRepository {
  @override
  Future<void> addPayment(PaymentEntity payment) async {}
  @override
  Future<List<PaymentEntity>> getPayments() async => [];
  @override
  Future<List<PaymentEntity>> getPaymentsByCustomer(String customerId) async => [];
  @override
  Future<void> updatePayment(PaymentEntity payment) async {}
  @override
  Future<void> deletePayment(String id) async {}
}

class FakeExpenseRepository implements ExpenseRepository {
  @override
  Future<void> addExpense(ExpenseModel expense) async {}
  @override
  Future<List<ExpenseModel>> getExpenses() async => [];
  @override
  Future<void> updateExpense(ExpenseModel expense) async {}
  @override
  Future<void> deleteExpense(String id) async {}
}

void main() {
  setUp(() {
    getIt.reset();

    final authRepo = FakeAuthRepository();
    final customerRepo = FakeCustomerRepository();
    final packageRepo = FakePackageRepository();
    final paymentRepo = FakePaymentRepository();
    final expenseRepo = FakeExpenseRepository();

    final getCustomers = GetCustomers(customerRepo);
    final addCustomer = AddCustomer(customerRepo);
    final updateCustomer = UpdateCustomer(customerRepo);
    final deleteCustomer = DeleteCustomer(customerRepo);

    final getPackages = GetPackages(packageRepo);
    final addPackage = AddPackage(packageRepo);

    final getPayments = GetPayments(paymentRepo);
    final getExpenses = GetExpenses(expenseRepo);

    getIt.registerSingleton<AuthBloc>(AuthBloc(authRepository: authRepo));
    getIt.registerSingleton<DashboardBloc>(DashboardBloc(
      getCustomers: getCustomers,
      getPayments: getPayments,
      getExpenses: getExpenses,
    ));
    getIt.registerSingleton<CustomersBloc>(CustomersBloc(
      getCustomers: getCustomers,
      addCustomer: addCustomer,
      updateCustomer: updateCustomer,
      deleteCustomer: deleteCustomer,
    ));
    getIt.registerSingleton<PackagesBloc>(PackagesBloc(
      getPackages: getPackages,
      addPackage: addPackage,
    ));
    getIt.registerSingleton<PaymentsBloc>(PaymentsBloc(
      getCustomers: getCustomers,
      updateCustomer: updateCustomer,
    ));
    getIt.registerSingleton<ExpensesBloc>(ExpensesBloc());
    getIt.registerSingleton<ReportsBloc>(ReportsBloc());
    getIt.registerSingleton<EmployeesBloc>(EmployeesBloc());
    getIt.registerSingleton<InstallationsBloc>(InstallationsBloc());
    getIt.registerSingleton<SettingsBloc>(SettingsBloc());
  });

  testWidgets('Initial route renders LoginPage smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Sign in to dashboard'), findsOneWidget);
  });
}
