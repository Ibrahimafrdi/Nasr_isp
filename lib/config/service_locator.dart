import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/auth/data/datasources/firebase_auth_service.dart';
import 'package:nasr_isp/features/auth/data/repositories/auth_repository_impl.dart';

import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:nasr_isp/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:nasr_isp/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:nasr_isp/features/customers/domain/repositories/customer_repository.dart';
import 'package:nasr_isp/features/customers/domain/usecases/add_customer.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/customers/domain/usecases/update_customer.dart';
import 'package:nasr_isp/features/customers/domain/usecases/delete_customer.dart';
import 'package:nasr_isp/features/customers/domain/usecases/renew_subscription.dart';
import 'package:nasr_isp/features/customers/domain/usecases/set_customer_status.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/inventory/data/datasources/inventory_remote_data_source.dart';
import 'package:nasr_isp/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/add_inventory_item.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/addstock_inventory_item.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/delete_inventory_item.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/get_inventory_items.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/getstock_inventory.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/update_inventory_item.dart';
import 'package:nasr_isp/features/inventory/presentation/bloc/inventory_bloc.dart';

import 'package:nasr_isp/features/packages/data/datasources/package_remote_data_source.dart';
import 'package:nasr_isp/features/packages/data/repositories/package_repository_impl.dart';
import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';
import 'package:nasr_isp/features/packages/domain/usecases/add_package.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/packages/domain/usecases/update_package.dart';
import 'package:nasr_isp/features/packages/domain/usecases/delete_package.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_event.dart';

import 'package:nasr_isp/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:nasr_isp/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';
import 'package:nasr_isp/features/payments/domain/usecases/add_payment.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_payments.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_all_payments.dart';
import 'package:nasr_isp/features/payments/domain/usecases/update_payment.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_payment_by_customer_and_month.dart';

import 'package:nasr_isp/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:nasr_isp/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:nasr_isp/features/expenses/domain/repositories/expense_repository.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/get_expenses.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/add_expense.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/update_expense.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/delete_expense.dart';

import 'package:nasr_isp/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:nasr_isp/features/employees/data/datasources/employee_remote_data_source.dart';
import 'package:nasr_isp/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:nasr_isp/features/employees/domain/repositories/employee_repository.dart';
import 'package:nasr_isp/features/employees/domain/usecases/add_employee.dart';
import 'package:nasr_isp/features/employees/domain/usecases/get_employees.dart';
import 'package:nasr_isp/features/employees/domain/usecases/update_employee.dart';
import 'package:nasr_isp/features/employees/presentation/bloc/employees_bloc.dart';
import 'package:nasr_isp/features/expenses/presentation/bloc/expenses_bloc.dart';
import 'package:nasr_isp/features/installations/data/datasources/installation_remote_data_source.dart';
import 'package:nasr_isp/features/installations/data/repositories/installation_repository_impl.dart';
import 'package:nasr_isp/features/installations/domain/repositories/installation_repository.dart';
import 'package:nasr_isp/features/installations/domain/usecases/create_installation.dart';
import 'package:nasr_isp/features/installations/domain/usecases/delete_installation.dart';
import 'package:nasr_isp/features/installations/domain/usecases/get_installations.dart';
import 'package:nasr_isp/features/installations/domain/usecases/get_installations_by_customer.dart';
import 'package:nasr_isp/features/installations/domain/usecases/update_installation.dart';
import 'package:nasr_isp/features/installations/presentation/bloc/installations_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:nasr_isp/features/settings/data/datasources/settings_remote_data_source.dart';
import 'package:nasr_isp/features/settings/data/datasources/user_management_remote_data_source.dart';
import 'package:nasr_isp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:nasr_isp/features/settings/data/repositories/user_management_repository_impl.dart';
import 'package:nasr_isp/features/settings/domain/repositories/settings_repository.dart';
import 'package:nasr_isp/features/settings/domain/repositories/user_management_repository.dart';
import 'package:nasr_isp/features/settings/domain/usecases/get_settings.dart';
import 'package:nasr_isp/features/settings/domain/usecases/update_settings.dart';
import 'package:nasr_isp/features/settings/domain/usecases/get_users.dart';
import 'package:nasr_isp/features/settings/domain/usecases/create_user.dart';
import 'package:nasr_isp/features/settings/domain/usecases/update_user_role.dart';
import 'package:nasr_isp/features/settings/domain/usecases/toggle_user_status.dart';
import 'package:nasr_isp/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nasr_isp/features/settings/presentation/bloc/user_management_bloc.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Firebase
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // Data Sources
  getIt.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(firestore: getIt()),
  );
  getIt.registerLazySingleton<PackageRemoteDataSource>(
    () => PackageRemoteDataSourceImpl(),
  );
  getIt.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(firestore: getIt()),
  );
  getIt.registerLazySingleton<ExpenseRemoteDataSource>(
    () => ExpenseRemoteDataSourceImpl(firestore: getIt()),
  );

  // Repositories
  getIt.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton<PackageRepository>(
    () => PackageRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(remoteDataSource: getIt()),
  );

  // Use Cases - Customers
  getIt.registerLazySingleton(() => GetCustomers(getIt()));
  getIt.registerLazySingleton(() => AddCustomer(getIt()));
  getIt.registerLazySingleton(() => UpdateCustomer(getIt()));
  getIt.registerLazySingleton(() => DeleteCustomer(getIt()));
  // Spans customers + payments + packages: a fresh-cycle reactivation moves
  // the expiry and raises the unpaid charge for the month it grants.
  getIt.registerLazySingleton(
    () => SetCustomerStatus(
      customerRepository: getIt(),
      paymentRepository: getIt(),
      getPackages: getIt(),
    ),
  );
  // Spans customers + payments + packages: renewing writes the charge, snapshots
  // the upstream cost onto it, and advances the expiry as one operation.
  getIt.registerLazySingleton(
    () => RenewSubscription(
      paymentRepository: getIt(),
      customerRepository: getIt(),
      getPackages: getIt(),
    ),
  );

  // Use Cases - Packages
  getIt.registerLazySingleton(() => GetPackages(getIt()));
  getIt.registerLazySingleton(() => AddPackage(getIt()));
  getIt.registerLazySingleton(() => UpdatePackage(getIt()));
  getIt.registerLazySingleton(() => DeletePackage(getIt()));

  // Use Cases - Payments
  getIt.registerLazySingleton(() => GetPayments(getIt()));
  getIt.registerLazySingleton(() => GetAllPayments(getIt()));
  getIt.registerLazySingleton(() => AddPayment(getIt()));
  getIt.registerLazySingleton(() => UpdatePayment(getIt()));
  getIt.registerLazySingleton(() => GetPaymentByCustomerAndMonth(getIt()));

  // Use Cases - Expenses
  getIt.registerLazySingleton(() => GetExpenses(getIt()));
  getIt.registerLazySingleton(() => AddExpense(getIt()));
  getIt.registerLazySingleton(() => UpdateExpense(getIt()));
  getIt.registerLazySingleton(() => DeleteExpense(getIt()));

  // BLoCs
  getIt.registerSingleton<AuthBloc>(
    AuthBloc(
      authRepository: AuthRepositoryImpl(
        authService: FirebaseAuthService(
          firebaseAuth: getIt(),
          firestore: getIt(),
        ),
      ),
    )..add(const AuthCheckEvent()),
  );

  getIt.registerSingleton<CustomersBloc>(
    CustomersBloc(
      getCustomers: getIt(),
      addCustomer: getIt(),
      updateCustomer: getIt(),
      deleteCustomer: getIt(),
      renewSubscription: getIt(),
      setCustomerStatus: getIt(),
    ),
  );

  getIt.registerSingleton<PackagesBloc>(
    PackagesBloc(
      getPackages: getIt(),
      addPackage: getIt(),
      updatePackage: getIt(),
      deletePackage: getIt(),
    )..add(const LoadPackagesEvent()),
  );

  getIt.registerSingleton<PaymentsBloc>(
    PaymentsBloc(
      getPayments: getIt(),
      addPayment: getIt(),
      updatePayment: getIt(),
      getPaymentByCustomerAndMonth: getIt(),
    ),
  );
  getIt.registerSingleton<ExpensesBloc>(
    ExpensesBloc(
      getExpenses: getIt(),
      addExpense: getIt(),
      updateExpense: getIt(),
      deleteExpense: getIt(),
    ),
  );
  getIt.registerSingleton<ReportsBloc>(ReportsBloc());
  
  // Employees Clean Architecture stack
  getIt.registerLazySingleton<EmployeeRemoteDataSource>(
    () => EmployeeRemoteDataSourceImpl(firestore: getIt()),
  );
  getIt.registerLazySingleton<EmployeeRepository>(
    () => EmployeeRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton(() => GetEmployees(getIt()));
  getIt.registerLazySingleton(() => AddEmployee(getIt()));
  getIt.registerLazySingleton(() => UpdateEmployee(getIt()));
  getIt.registerFactory<EmployeeBloc>(
    () => EmployeeBloc(
      getEmployees: getIt(),
      addEmployee: getIt(),
      updateEmployee: getIt(),
      getInstallations: getIt(),
    ),
  );
  
  // Installations clean architecture stack
  getIt.registerLazySingleton<InstallationRemoteDataSource>(
    () => InstallationRemoteDataSourceImpl(firestore: getIt()),
  );
  getIt.registerLazySingleton<InstallationRepository>(
    () => InstallationRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton(() => CreateInstallation(getIt()));
  getIt.registerLazySingleton(() => UpdateInstallation(getIt()));
  getIt.registerLazySingleton(() => GetInstallations(getIt()));
  getIt.registerLazySingleton(() => GetInstallationsByCustomer(getIt()));
  getIt.registerLazySingleton(() => DeleteInstallation(getIt()));

  getIt.registerFactory<InstallationBloc>(
    () => InstallationBloc(
      getInstallations: getIt(),
      createInstallation: getIt(),
      updateInstallation: getIt(),
      deleteInstallation: getIt(),
      getInstallationsByCustomer: getIt(),
    ),
  );

  // Dashboard (depends on Payments + Installations + Packages use cases registered above)
  getIt.registerSingleton<DashboardBloc>(
    DashboardBloc(
      getCustomers: getIt<GetCustomers>(),
      getAllPayments: getIt<GetAllPayments>(),
      getExpenses: getIt<GetExpenses>(),
      getInstallations: getIt<GetInstallations>(),
      getPackages: getIt<GetPackages>(),
    ),
  );

  // Settings & User Management Clean Architecture stack
  getIt.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(firestore: getIt()),
  );
  getIt.registerLazySingleton<UserManagementRemoteDataSource>(
    () => UserManagementRemoteDataSourceImpl(firestore: getIt(), firebaseAuth: getIt()),
  );

  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton<UserManagementRepository>(
    () => UserManagementRepositoryImpl(remoteDataSource: getIt()),
  );

  getIt.registerLazySingleton(() => GetSettings(getIt()));
  getIt.registerLazySingleton(() => UpdateSettings(getIt()));
  getIt.registerLazySingleton(() => GetUsers(getIt()));
  getIt.registerLazySingleton(() => CreateUser(getIt()));
  getIt.registerLazySingleton(() => UpdateUserRole(getIt()));
  getIt.registerLazySingleton(() => ToggleUserStatus(getIt()));

  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(getSettings: getIt(), updateSettings: getIt()),
  );
  getIt.registerFactory<UserManagementBloc>(
    () => UserManagementBloc(
      getUsers: getIt(),
      createUser: getIt(),
      updateUserRole: getIt(),
      toggleUserStatus: getIt(),
    ),
  );

  getIt.registerLazySingleton<InventoryRemoteDataSource>(
    () => InventoryRemoteDataSourceImpl(),
  );
  getIt.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton(() => GetInventoryItems(getIt()));
  getIt.registerLazySingleton(() => AddInventoryItem(getIt()));
  getIt.registerLazySingleton(() => UpdateInventoryItem(getIt()));
  getIt.registerLazySingleton(() => DeleteInventoryItem(getIt()));
  getIt.registerLazySingleton(() => AddStockMovement(getIt()));
  getIt.registerLazySingleton(() => GetStockMovements(getIt()));
  getIt.registerFactory(
    () => InventoryBloc(
      getInventoryItems: getIt(),
      addInventoryItem: getIt(),
      updateInventoryItem: getIt(),
      deleteInventoryItem: getIt(),
      addStockMovement: getIt(),
      getStockMovements: getIt(),
    ),
  );
}
