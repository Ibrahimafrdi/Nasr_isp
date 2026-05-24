import 'package:get_it/get_it.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:nasr_isp/features/employees/presentation/bloc/employees_bloc.dart';
import 'package:nasr_isp/features/expenses/presentation/bloc/expenses_bloc.dart';
import 'package:nasr_isp/features/installations/presentation/bloc/installations_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:nasr_isp/features/settings/presentation/bloc/settings_bloc.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // BLoCs
  getIt.registerSingleton<AuthBloc>(AuthBloc());
  getIt.registerSingleton<DashboardBloc>(DashboardBloc());
  getIt.registerSingleton<CustomersBloc>(CustomersBloc());
  getIt.registerSingleton<PaymentsBloc>(PaymentsBloc());
  getIt.registerSingleton<ExpensesBloc>(ExpensesBloc());
  getIt.registerSingleton<ReportsBloc>(ReportsBloc());
  getIt.registerSingleton<EmployeesBloc>(EmployeesBloc());
  getIt.registerSingleton<InstallationsBloc>(InstallationsBloc());
  getIt.registerSingleton<SettingsBloc>(SettingsBloc());
}
