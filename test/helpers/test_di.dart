import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/auth/domain/repositories/auth_repository.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/repositories/customer_repository.dart';
import 'package:nasr_isp/features/customers/domain/usecases/add_customer.dart';
import 'package:nasr_isp/features/customers/domain/usecases/delete_customer.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/customers/domain/usecases/renew_subscription.dart';
import 'package:nasr_isp/features/customers/domain/usecases/set_customer_status.dart';
import 'package:nasr_isp/features/customers/domain/usecases/update_customer.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';
import 'package:nasr_isp/features/employees/domain/repositories/employee_repository.dart';
import 'package:nasr_isp/features/employees/domain/usecases/add_employee.dart';
import 'package:nasr_isp/features/employees/domain/usecases/get_employees.dart';
import 'package:nasr_isp/features/employees/domain/usecases/update_employee.dart';
import 'package:nasr_isp/features/employees/presentation/bloc/employees_bloc.dart';
import 'package:nasr_isp/features/expenses/domain/entities/expense_entity.dart';
import 'package:nasr_isp/features/expenses/domain/repositories/expense_repository.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/add_expense.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/delete_expense.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/get_expenses.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/update_expense.dart';
import 'package:nasr_isp/features/expenses/presentation/bloc/expenses_bloc.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/repositories/installation_repository.dart';
import 'package:nasr_isp/features/installations/domain/usecases/create_installation.dart';
import 'package:nasr_isp/features/installations/domain/usecases/delete_installation.dart';
import 'package:nasr_isp/features/installations/domain/usecases/get_installations.dart';
import 'package:nasr_isp/features/installations/domain/usecases/get_installations_by_customer.dart';
import 'package:nasr_isp/features/installations/domain/usecases/update_installation.dart';
import 'package:nasr_isp/features/installations/presentation/bloc/installations_bloc.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';
import 'package:nasr_isp/features/packages/domain/usecases/add_package.dart';
import 'package:nasr_isp/features/packages/domain/usecases/delete_package.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/packages/domain/usecases/update_package.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';
import 'package:nasr_isp/features/payments/domain/usecases/add_payment.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_all_payments.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_payment_by_customer_and_month.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_payments.dart';
import 'package:nasr_isp/features/payments/domain/usecases/update_payment.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/features/reports/domain/usecases/get_available_report_months.dart';
import 'package:nasr_isp/features/reports/domain/usecases/get_monthly_financial_summary.dart';
import 'package:nasr_isp/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:nasr_isp/features/settings/domain/entities/app_settings_entity.dart';
import 'package:nasr_isp/features/settings/domain/repositories/settings_repository.dart';
import 'package:nasr_isp/features/settings/domain/repositories/user_management_repository.dart';
import 'package:nasr_isp/features/settings/domain/usecases/create_user.dart';
import 'package:nasr_isp/features/settings/domain/usecases/get_settings.dart';
import 'package:nasr_isp/features/settings/domain/usecases/get_users.dart';
import 'package:nasr_isp/features/settings/domain/usecases/toggle_user_status.dart';
import 'package:nasr_isp/features/settings/domain/usecases/update_settings.dart';
import 'package:nasr_isp/features/settings/domain/usecases/update_user_role.dart';
import 'package:nasr_isp/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nasr_isp/features/settings/presentation/bloc/user_management_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
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
  Future<String> addPackage(PackageEntity package) async => '';
  @override
  Future<List<PackageEntity>> getPackages({
    ConnectionType? filterByType,
    bool? activeOnly,
  }) async => [];
  @override
  Future<PackageEntity> getPackageById(String id) async => PackageModel(
    id: id,
    name: '',
    speedMbps: 0,
    price: 0,
    costPrice: 0,
    connectionType: ConnectionType.wireless,
    isActive: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  @override
  Future<void> updatePackage(PackageEntity package) async {}
  @override
  Future<void> deletePackage(String id) async {}
}

class FakePaymentRepository implements PaymentRepository {
  @override
  Future<void> addPayment(PaymentEntity payment) async {}
  @override
  Future<List<PaymentEntity>> getPayments({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    List<String>? filterStatuses,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
  }) async => [];
  @override
  Future<List<PaymentEntity>> getAllPayments() async => [];
  @override
  Future<void> updatePayment(PaymentEntity payment) async {}
  @override
  Future<void> deletePayment(String id) async {}
  @override
  Future<int> getTotalPaymentsCount() async => 0;
  @override
  Future<PaymentEntity?> getPaymentByCustomerAndMonth(
    String customerId,
    String billingMonth,
  ) async => null;
}

class FakeExpenseRepository implements ExpenseRepository {
  @override
  Future<void> addExpense(ExpenseEntity expense) async {}
  @override
  Future<List<ExpenseEntity>> getExpenses() async => [];
  @override
  Future<void> updateExpense(ExpenseEntity expense) async {}
  @override
  Future<void> deleteExpense(String id) async {}
}

class FakeInstallationRepository implements InstallationRepository {
  @override
  Future<void> createInstallation(InstallationEntity installation) async {}
  @override
  Future<List<InstallationEntity>> getInstallations({
    String? status,
    String? connectionType,
    String? employeeId,
    String? searchQuery,
  }) async => [];
  @override
  Future<List<InstallationEntity>> getInstallationsByCustomer(
    String customerId,
  ) async => [];
  @override
  Future<void> updateInstallation(InstallationEntity installation) async {}
  @override
  Future<void> deleteInstallation(String id) async {}
}

class FakeSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettingsEntity> getSettings() async => const AppSettingsEntity();
  @override
  Future<void> updateSettings(AppSettingsEntity settings) async {}
}

class FakeUserManagementRepository implements UserManagementRepository {
  @override
  Future<List<UserModel>> getUsers() async => [];
  @override
  Future<void> createUser(
    String email,
    String password,
    String name,
    String role,
  ) async {}
  @override
  Future<void> updateUserRole(String uid, String role) async {}
  @override
  Future<void> toggleUserStatus(String uid, bool isActive) async {}
}

class FakeEmployeeRepository implements EmployeeRepository {
  @override
  Future<void> addEmployee(EmployeeEntity employee) async {}
  @override
  Future<List<EmployeeEntity>> getEmployees() async => [];
  @override
  Future<void> updateEmployee(EmployeeEntity employee) async {}
}

/// Resets [getIt] and registers every bloc the app's `MultiBlocProvider`
/// expects, backed by the in-memory `Fake*Repository` implementations above.
///
/// Call from `setUp` in any test that pumps a widget reaching into the
/// service locator (i.e. anything under `MyApp` or an `AppShell` route).
/// Widgets that take their data through constructor callbacks — the
/// `*CardList` family, `PremiumDataTable`, the adaptive dialog widgets —
/// don't need this.
Future<void> registerFakeDependencies() async {
  await getIt.reset();

  final authRepo = FakeAuthRepository();
  final customerRepo = FakeCustomerRepository();
  final packageRepo = FakePackageRepository();
  final paymentRepo = FakePaymentRepository();
  final expenseRepo = FakeExpenseRepository();
  final installationRepo = FakeInstallationRepository();
  final settingsRepo = FakeSettingsRepository();
  final userManagementRepo = FakeUserManagementRepository();
  final employeeRepo = FakeEmployeeRepository();

  final getCustomers = GetCustomers(customerRepo);
  final addCustomer = AddCustomer(customerRepo);
  final updateCustomer = UpdateCustomer(customerRepo);
  final deleteCustomer = DeleteCustomer(customerRepo);

  final getPackages = GetPackages(packageRepo);
  final addPackage = AddPackage(packageRepo);
  final updatePackage = UpdatePackage(packageRepo);
  final deletePackage = DeletePackage(packageRepo);

  final getPayments = GetPayments(paymentRepo);
  final getAllPayments = GetAllPayments(paymentRepo);
  final addPayment = AddPayment(paymentRepo);
  final updatePayment = UpdatePayment(paymentRepo);
  final getPaymentByCustomerAndMonth = GetPaymentByCustomerAndMonth(paymentRepo);

  final getExpenses = GetExpenses(expenseRepo);
  final addExpense = AddExpense(expenseRepo);
  final updateExpense = UpdateExpense(expenseRepo);
  final deleteExpense = DeleteExpense(expenseRepo);

  final getInstallations = GetInstallations(installationRepo);
  final createInstallation = CreateInstallation(installationRepo);
  final updateInstallation = UpdateInstallation(installationRepo);
  final deleteInstallation = DeleteInstallation(installationRepo);
  final getInstallationsByCustomer = GetInstallationsByCustomer(
    installationRepo,
  );

  final getSettings = GetSettings(settingsRepo);
  final updateSettings = UpdateSettings(settingsRepo);

  final getUsers = GetUsers(userManagementRepo);
  final createUser = CreateUser(userManagementRepo);
  final updateUserRole = UpdateUserRole(userManagementRepo);
  final toggleUserStatus = ToggleUserStatus(userManagementRepo);

  final getEmployees = GetEmployees(employeeRepo);
  final addEmployee = AddEmployee(employeeRepo);
  final updateEmployee = UpdateEmployee(employeeRepo);

  final getMonthlyFinancialSummary = GetMonthlyFinancialSummary(
    getCustomers: getCustomers,
    getAllPayments: getAllPayments,
    getExpenses: getExpenses,
    getInstallations: getInstallations,
    getPackages: getPackages,
  );
  final getAvailableReportMonths = GetAvailableReportMonths(
    getCustomers: getCustomers,
    getAllPayments: getAllPayments,
    getExpenses: getExpenses,
  );
  getIt.registerLazySingleton<GetMonthlyFinancialSummary>(() => getMonthlyFinancialSummary);
  getIt.registerLazySingleton<GetAvailableReportMonths>(() => getAvailableReportMonths);

  getIt.registerSingleton<AuthBloc>(AuthBloc(authRepository: authRepo));
  getIt.registerSingleton<DashboardBloc>(
    DashboardBloc(
      getCustomers: getCustomers,
      getAllPayments: getAllPayments,
      getExpenses: getExpenses,
      getInstallations: getInstallations,
      getPackages: getPackages,
      getMonthlyFinancialSummary: getMonthlyFinancialSummary,
    ),
  );
  getIt.registerSingleton<CustomersBloc>(
    CustomersBloc(
      getCustomers: getCustomers,
      addCustomer: addCustomer,
      updateCustomer: updateCustomer,
      deleteCustomer: deleteCustomer,
      renewSubscription: RenewSubscription(
        paymentRepository: paymentRepo,
        customerRepository: customerRepo,
        getPackages: getPackages,
      ),
      setCustomerStatus: SetCustomerStatus(
        customerRepository: customerRepo,
        paymentRepository: paymentRepo,
        getPackages: getPackages,
      ),
    ),
  );
  getIt.registerSingleton<PackagesBloc>(
    PackagesBloc(
      getPackages: getPackages,
      addPackage: addPackage,
      updatePackage: updatePackage,
      deletePackage: deletePackage,
    ),
  );
  getIt.registerSingleton<PaymentsBloc>(
    PaymentsBloc(
      getPayments: getPayments,
      addPayment: addPayment,
      updatePayment: updatePayment,
      getPaymentByCustomerAndMonth: getPaymentByCustomerAndMonth,
    ),
  );
  getIt.registerSingleton<ExpensesBloc>(
    ExpensesBloc(
      getExpenses: getExpenses,
      addExpense: addExpense,
      updateExpense: updateExpense,
      deleteExpense: deleteExpense,
    ),
  );
  getIt.registerSingleton<ReportsBloc>(
    ReportsBloc(
      getMonthlyFinancialSummary: getMonthlyFinancialSummary,
      getAvailableReportMonths: getAvailableReportMonths,
    ),
  );
  getIt.registerSingleton<EmployeeBloc>(
    EmployeeBloc(
      getEmployees: getEmployees,
      addEmployee: addEmployee,
      updateEmployee: updateEmployee,
      getInstallations: getInstallations,
    ),
  );
  getIt.registerSingleton<InstallationBloc>(
    InstallationBloc(
      getInstallations: getInstallations,
      createInstallation: createInstallation,
      updateInstallation: updateInstallation,
      deleteInstallation: deleteInstallation,
      getInstallationsByCustomer: getInstallationsByCustomer,
    ),
  );
  getIt.registerSingleton<SettingsBloc>(
    SettingsBloc(getSettings: getSettings, updateSettings: updateSettings),
  );
  getIt.registerSingleton<UserManagementBloc>(
    UserManagementBloc(
      getUsers: getUsers,
      createUser: createUser,
      updateUserRole: updateUserRole,
      toggleUserStatus: toggleUserStatus,
    ),
  );
}
