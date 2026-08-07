import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';

/// The upstream cost to snapshot onto a charge, or null when it cannot be
/// established.
///
/// Null rather than zero on purpose: zero would report the customer's whole
/// bill as margin, which is exactly the overstatement the dashboard warns
/// about via `unpricedCustomerCount`. A package lookup failure must not block
/// the operator from billing, so it degrades to null.
///
/// Shared by every path that writes a subscription charge — renewals and
/// reactivations alike — so the two can't drift on what an unknown cost means.
Future<double?> resolvePackageCost(
  GetPackages getPackages,
  String? packageId,
) async {
  if (packageId == null || packageId.isEmpty) return null;
  try {
    final packages = await getPackages();
    for (final package in packages) {
      if (package.id == packageId) {
        return package.costPrice > 0 ? package.costPrice : null;
      }
    }
  } catch (_) {
    // Fall through — an unresolvable cost is recorded as unknown.
  }
  return null;
}
