import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';

class CustomerEntity {
  final String id;
  final String name;
  final String phone;
  final String cnic;
  final String address;
  final String connectionType;
  final String? packageId;
  final double monthlyBill;
  final String status;
  final String notes;
  final DateTime? createdAt;
  final DateTime? joinDate;
  final DateTime? nextDueDate;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.cnic,
    required this.address,
    required this.connectionType,
    this.packageId,
    required this.monthlyBill,
    required this.status,
    required this.notes,
    this.createdAt,
    this.joinDate,
    this.nextDueDate,
  });

  /// The expiry to act on: [nextDueDate], or one month after [createdAt] for
  /// legacy records that never had one written.
  ///
  /// Every surface that shows or tests a due date reads it from here. The
  /// four hand-rolled copies this replaced used the rolling-over
  /// `DateTime(y, m + 1, d)` form, so a month-end customer's row and the
  /// dashboard's expired count could disagree by a couple of days.
  DateTime? get effectiveDueDate => BillingCycle.effectiveDueDate(
        nextDueDate: nextDueDate,
        createdAt: createdAt,
      );

  /// Whether service has lapsed as of [now]. Cancelled customers are never
  /// reported as expired — a stale due date on a closed account is not a
  /// renewal to chase.
  bool isExpiredAt(DateTime now) {
    if (status != 'active') return false;
    final due = effectiveDueDate;
    return due != null && BillingCycle.isExpired(due, now);
  }

  /// Whether the Renew action should be offered: expired, due today, or
  /// inside the [BillingCycle.renewalWindowDays] warning window.
  bool isDueForRenewalAt(DateTime now) {
    if (status != 'active') return false;
    final due = effectiveDueDate;
    return due != null && BillingCycle.isDueForRenewal(due, now);
  }

  /// This customer's monthly subscription position, plus a verdict on whether
  /// the cost side can be trusted.
  ///
  /// Pass the package resolved from [packageId], or null if it could not be
  /// resolved. This distinguishes "no package assigned" from "assigned a
  /// package we couldn't find" — the latter used to be reported silently as a
  /// 100% margin, since a missing package falls back to a zero cost price.
  SubscriberMargin monthlyMargin(PackageEntity? package) {
    final expectsPackage = packageId != null && packageId!.isNotEmpty;
    final SubscriberCostBasis basis;
    if (package != null) {
      // A resolved package with no cost price is treated as unknown rather
      // than free: PackageModel defaults costPrice to 0 for legacy documents,
      // and a zero upstream cost would report the whole bill as profit.
      basis = package.costPrice > 0
          ? SubscriberCostBasis.packageKnown
          : SubscriberCostBasis.packageCostMissing;
    } else if (expectsPackage) {
      basis = SubscriberCostBasis.packageUnresolved;
    } else {
      basis = SubscriberCostBasis.noPackageAssigned;
    }
    return SubscriberMargin(
      money: MoneyLine(
        amountBilled: monthlyBill,
        costIncurred: package?.costPrice ?? 0.0,
      ),
      basis: basis,
    );
  }

  /// Monthly profit for this customer: `monthlyBill - package.costPrice`.
  ///
  /// A convenience shim over [monthlyMargin] for call sites that only need the
  /// number. Prefer [monthlyMargin] anywhere the reliability of the figure
  /// matters — this getter cannot tell you the package was missing.
  double calculateProfit(PackageEntity? package) =>
      monthlyMargin(package).money.profit;

  CustomerEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? cnic,
    String? address,
    String? connectionType,
    String? packageId,
    double? monthlyBill,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? joinDate,
    DateTime? nextDueDate,
  }) => CustomerEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        cnic: cnic ?? this.cnic,
        address: address ?? this.address,
        connectionType: connectionType ?? this.connectionType,
        packageId: packageId ?? this.packageId,
        monthlyBill: monthlyBill ?? this.monthlyBill,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        joinDate: joinDate ?? this.joinDate,
        nextDueDate: nextDueDate ?? this.nextDueDate,
      );
}
