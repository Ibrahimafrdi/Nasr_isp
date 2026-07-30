import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';

/// Viewport widths every responsive widget is swept across.
///
/// Chosen to straddle the canonical breakpoints (600 / 1024) and to cover the
/// real devices this app ships to: small Android, iPhone 14, large phone,
/// the exact mobile/tablet boundary, iPad portrait, the exact tablet/desktop
/// boundary, laptop, and the 1920 max-width cap.
const kTestWidths = <double>[
  360.0,
  390.0,
  414.0,
  600.0,
  768.0,
  1024.0,
  1280.0,
  1920.0,
];

/// Stops `google_fonts` from attempting an HTTP fetch during tests, which
/// otherwise makes any widget touching `AppTypography`/`AppFonts` flake.
///
/// Call once from `setUpAll` in every responsive test file.
void disableGoogleFontsFetching() {
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// Pumps [child] at an exact logical viewport width.
///
/// Sets `devicePixelRatio` to 1.0 so `width` is logical pixels, and registers
/// teardown so the surface size doesn't leak into the next test.
///
/// Deliberately does NOT install a `FlutterError.onError` filter — overflow
/// errors must surface so callers can assert `tester.takeException()` is null.
Future<void> pumpAtWidth(
  WidgetTester tester,
  Widget child,
  double width, {
  double height = 800,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

/// Fails the test if the last pump produced a layout error.
///
/// `RenderFlex overflowed` is reported through `takeException()`, so this is
/// the single assertion that catches the entire class of bug this suite
/// exists to prevent.
void expectNoOverflow(WidgetTester tester, {String? reason}) {
  expect(tester.takeException(), isNull, reason: reason);
}
