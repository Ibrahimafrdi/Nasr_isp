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
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';

import 'package:nasr_isp/features/packages/data/datasources/package_remote_data_source.dart';
import 'package:nasr_isp/features/packages/data/repositories/package_repository_impl.dart';
import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';
import 'package:nasr_isp/features/packages/domain/usecases/add_package.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_event.dart';

import 'package:nasr_isp/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:nasr_isp/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_payments.dart';

import 'package:nasr_isp/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:nasr_isp/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:nasr_isp/features/expenses/domain/repositories/expense_repository.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/get_expenses.dart';

import 'package:nasr_isp/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:nasr_isp/features/employees/presentation/bloc/employees_bloc.dart';
import 'package:nasr_isp/features/expenses/presentation/bloc/expenses_bloc.dart';
import 'package:nasr_isp/features/installations/presentation/bloc/installations_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:nasr_isp/features/settings/presentation/bloc/settings_bloc.dart';

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

  // Use Cases - Packages
  getIt.registerLazySingleton(() => GetPackages(getIt()));
  getIt.registerLazySingleton(() => AddPackage(getIt()));

  // Use Cases - Payments & Expenses
  getIt.registerLazySingleton(() => GetPayments(getIt()));
  getIt.registerLazySingleton(() => GetExpenses(getIt()));

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

  getIt.registerSingleton<DashboardBloc>(
    DashboardBloc(
      getCustomers: getIt<GetCustomers>(),
      getPayments: getIt<GetPayments>(),
      getExpenses: getIt<GetExpenses>(),
    ),
  );

  getIt.registerSingleton<CustomersBloc>(
    CustomersBloc(
      getCustomers: getIt(),
      addCustomer: getIt(),
      updateCustomer: getIt(),
      deleteCustomer: getIt(),
    ),
  );

  getIt.registerSingleton<PackagesBloc>(
    PackagesBloc(getPackages: getIt(), addPackage: getIt())
      ..add(const LoadPackagesEvent()),
  );

  getIt.registerSingleton<PaymentsBloc>(
    PaymentsBloc(
      getCustomers: getIt(),
      updateCustomer: getIt(),
    ),
  );
  getIt.registerSingleton<ExpensesBloc>(ExpensesBloc());
  getIt.registerSingleton<ReportsBloc>(ReportsBloc());
  getIt.registerSingleton<EmployeesBloc>(EmployeesBloc());
  getIt.registerSingleton<InstallationsBloc>(InstallationsBloc());
  getIt.registerSingleton<SettingsBloc>(SettingsBloc());
}
