import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/main.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/features/auth/presentation/pages/login_page.dart';

void main() {
  setUp(() {
    getIt.reset();
    setupServiceLocator();
  });

  testWidgets('Initial route renders LoginPage smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the login page widgets are present.
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });
}
