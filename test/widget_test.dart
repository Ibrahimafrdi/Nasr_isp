import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/features/auth/presentation/pages/login_page.dart';
import 'package:nasr_isp/main.dart';

import 'helpers/responsive_harness.dart';
import 'helpers/test_di.dart';

void main() {
  setUpAll(disableGoogleFontsFetching);

  setUp(registerFakeDependencies);

  testWidgets('Initial route renders LoginPage smoke test', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Sign in to dashboard'), findsOneWidget);
  });

  testWidgets('Tapping forgot password opens the reset password dialog', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final forgotBtn = find.text('Forgot your password?');
    expect(forgotBtn, findsOneWidget);
    await tester.tap(forgotBtn);
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Reset Password'), findsNothing);
  });
}
