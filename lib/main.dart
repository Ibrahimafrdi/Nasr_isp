import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/firebase_options.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:nasr_isp/config/router.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:nasr_isp/features/employees/presentation/bloc/employees_bloc.dart';
import 'package:nasr_isp/features/expenses/presentation/bloc/expenses_bloc.dart';
import 'package:nasr_isp/features/installations/presentation/bloc/installations_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:nasr_isp/features/settings/presentation/bloc/settings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => getIt<AuthBloc>()),
        BlocProvider<DashboardBloc>(create: (_) => getIt<DashboardBloc>()),
        BlocProvider<CustomersBloc>(create: (_) => getIt<CustomersBloc>()),
        BlocProvider<PackagesBloc>(create: (_) => getIt<PackagesBloc>()),
        BlocProvider<PaymentsBloc>(create: (_) => getIt<PaymentsBloc>()),
        BlocProvider<ExpensesBloc>(create: (_) => getIt<ExpensesBloc>()),
        BlocProvider<ReportsBloc>(create: (_) => getIt<ReportsBloc>()),
        BlocProvider<EmployeeBloc>(create: (_) => getIt<EmployeeBloc>()),
        BlocProvider<InstallationBloc>(
          create: (_) => getIt<InstallationBloc>(),
        ),
        BlocProvider<SettingsBloc>(create: (_) => getIt<SettingsBloc>()),
      ],
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final router = createAppRouter(authBloc);

          return MaterialApp.router(
            title: 'NASR ISP Management',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => ResponsiveBreakpoints.builder(
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 1024, name: TABLET),
                const Breakpoint(start: 1025, end: 1440, name: DESKTOP),
                const Breakpoint(start: 1441, end: double.infinity, name: '4K'),
              ],
              child: MaxWidthBox(maxWidth: 1920, child: child!),
            ),
          );
        },
      ),
    );
  }
}
