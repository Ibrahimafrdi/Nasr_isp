import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/finance/money_line.dart';

/// Why a subscriber margin's cost side is — or isn't — trustworthy.
enum SubscriberCostBasis {
  /// The customer's package was resolved, so the cost side is real.
  packageKnown,

  /// The customer has no package assigned at all: an ad-hoc or manual bill.
  /// Upstream cost is treated as zero, which is a defensible default here.
  noPackageAssigned,

  /// The customer references a package id that could not be resolved — the
  /// package was deleted, or the package list simply hadn't loaded yet.
  /// Upstream cost is treated as zero, so the margin is an UPPER BOUND rather
  /// than a fact. Call sites should flag this rather than present it as truth.
  packageUnresolved,

  /// The package resolved, but carries no cost price. PackageModel defaults
  /// costPrice to 0 for documents written before buy/sell pricing existed, so
  /// this is indistinguishable from a genuinely free package — and an ISP
  /// reselling bandwidth has no free package. Treated as unknown, not free,
  /// so a full-bill margin can never masquerade as a real one.
  packageCostMissing,
}

/// A customer's monthly subscription position, plus a verdict on how much the
/// cost side can be trusted.
class SubscriberMargin extends Equatable {
  final MoneyLine money;
  final SubscriberCostBasis basis;

  const SubscriberMargin({required this.money, required this.basis});

  /// True only when the margin is backed by a resolved package.
  bool get isReliable => basis == SubscriberCostBasis.packageKnown;

  /// True when a package was expected but its cost couldn't be established —
  /// either the id didn't resolve or the package carries no cost price. These
  /// are the cases that used to be reported silently as a 100% margin.
  bool get isPackageMissing =>
      basis == SubscriberCostBasis.packageUnresolved ||
      basis == SubscriberCostBasis.packageCostMissing;

  @override
  List<Object?> get props => [money, basis];

  @override
  String toString() => 'SubscriberMargin($money, basis: ${basis.name})';
}
