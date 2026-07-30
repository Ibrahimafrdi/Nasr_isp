import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';

import '../helpers/responsive_harness.dart';

void main() {
  group('Responsive.deviceTypeForWidth', () {
    test('classifies the canonical bands', () {
      expect(Responsive.deviceTypeForWidth(0), DeviceType.mobile);
      expect(Responsive.deviceTypeForWidth(360), DeviceType.mobile);
      expect(Responsive.deviceTypeForWidth(599), DeviceType.mobile);
      expect(Responsive.deviceTypeForWidth(600), DeviceType.tablet);
      expect(Responsive.deviceTypeForWidth(768), DeviceType.tablet);
      expect(Responsive.deviceTypeForWidth(1023), DeviceType.tablet);
      expect(Responsive.deviceTypeForWidth(1024), DeviceType.desktop);
      expect(Responsive.deviceTypeForWidth(1920), DeviceType.desktop);
    });

    test('1024 is desktop, not tablet', () {
      // Regression guard: the original used `width <= tabletBreakpoint`,
      // which made exactly 1024 a tablet while AppShell already rendered the
      // desktop sidebar at that width.
      expect(Responsive.deviceTypeForWidth(1024), DeviceType.desktop);
      expect(Responsive.deviceTypeForWidth(1023.99), DeviceType.tablet);
    });
  });

  group('padding helpers', () {
    test('phones get a tighter page gutter than tablet/desktop', () {
      expect(
        Responsive.pagePaddingFor(DeviceType.mobile),
        const EdgeInsets.all(AppSpacing.lg),
      );
      expect(
        Responsive.pagePaddingFor(DeviceType.desktop),
        const EdgeInsets.all(AppSpacing.xl),
      );
    });

    test('card padding never stacks 32dp on top of the page gutter', () {
      final mobilePage = Responsive.pagePaddingFor(DeviceType.mobile);
      final mobileCard = Responsive.cardPaddingFor(DeviceType.mobile);
      // 360dp phone: both gutters applied on both sides must leave a usable
      // content width. The old 24 + 32 combination left only 248dp.
      final remaining =
          360 - mobilePage.horizontal - mobileCard.horizontal;
      expect(remaining, greaterThanOrEqualTo(290));
    });
  });

  group('ResponsiveSwitcher', () {
    Widget switcher() => const ResponsiveSwitcher(
      mobile: Text('mobile'),
      desktop: Text('desktop'),
    );

    testWidgets('tablet falls back to mobile, not desktop', (tester) async {
      // This is the rule that makes Inventory/Expenses show cards rather
      // than a 9-column table on a 768dp tablet.
      await pumpAtWidth(tester, switcher(), 768);
      expect(find.text('mobile'), findsOneWidget);
      expect(find.text('desktop'), findsNothing);
    });

    testWidgets('desktop uses the desktop child', (tester) async {
      await pumpAtWidth(tester, switcher(), 1280);
      expect(find.text('desktop'), findsOneWidget);
    });

    testWidgets('an explicit tablet child wins when supplied', (tester) async {
      await pumpAtWidth(
        tester,
        const ResponsiveSwitcher(
          mobile: Text('mobile'),
          tablet: Text('tablet'),
          desktop: Text('desktop'),
        ),
        768,
      );
      expect(find.text('tablet'), findsOneWidget);
    });
  });
}
