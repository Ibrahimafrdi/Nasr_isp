import 'package:equatable/equatable.dart';

/// Cost and billed value of the materials (the BOM) consumed by one job.
///
/// Two front doors over one summation loop:
///  * [MaterialTotals.of] for typed, saved BOM lines — the caller supplies
///    three field selectors, which is what keeps feature imports out of
///    `core/`; and
///  * [MaterialTotals.fromRows] for the in-progress, untyped
///    `Map<String, dynamic>` rows the installation forms hold in local state
///    (see `installation_item_autofill.dart`'s `InstallationItemRow`).
///
/// Because both paths run the same arithmetic, a live form preview and the
/// record it eventually saves cannot disagree.
class MaterialTotals extends Equatable {
  /// Sum of qty x cost-price snapshot: what the ISP paid for the materials.
  final double cost;

  /// Sum of qty x sell-price snapshot: what the customer is billed for the
  /// materials, ON TOP of the installation setup fee.
  final double revenue;

  /// False only when no material information exists at all — no BOM rows and
  /// no lump-sum equipment cost. Distinguishes "nothing recorded" (render
  /// 'N/A') from "recorded, and it happened to be zero".
  final bool isRecorded;

  const MaterialTotals({
    required this.cost,
    required this.revenue,
    required this.isRecorded,
  });

  /// No BOM and no lump-sum cost recorded.
  static const MaterialTotals none =
      MaterialTotals(cost: 0.0, revenue: 0.0, isRecorded: false);

  /// A single lump-sum material/equipment cost with no per-item sell price —
  /// the legacy `equipmentCost` field. [revenue] is zero because there is
  /// nothing to bill the materials at. Returns [none] when [equipmentCost] is
  /// null; an explicit 0.0 counts as recorded.
  factory MaterialTotals.lumpSum(double? equipmentCost) => equipmentCost == null
      ? none
      : MaterialTotals(cost: equipmentCost, revenue: 0.0, isRecorded: true);

  /// Totals over any typed BOM line collection. An empty [lines] yields
  /// [none], not a recorded zero.
  static MaterialTotals of<T>(
    Iterable<T> lines, {
    required int Function(T line) quantity,
    required double Function(T line) unitCost,
    required double Function(T line) sellPrice,
  }) {
    var cost = 0.0;
    var revenue = 0.0;
    var any = false;
    for (final line in lines) {
      final qty = quantity(line);
      cost += qty * unitCost(line);
      revenue += qty * sellPrice(line);
      any = true;
    }
    return any
        ? MaterialTotals(cost: cost, revenue: revenue, isRecorded: true)
        : none;
  }

  /// Totals over in-progress form rows keyed 'qty', 'unitCost' and
  /// 'sellPrice'. Missing or non-numeric values read as zero rather than
  /// throwing, so a half-built row can never crash a live preview.
  factory MaterialTotals.fromRows(Iterable<Map<String, dynamic>> rows) =>
      MaterialTotals.of<Map<String, dynamic>>(
        rows,
        quantity: (r) => (r['qty'] as num?)?.toInt() ?? 0,
        unitCost: (r) => (r['unitCost'] as num?)?.toDouble() ?? 0.0,
        sellPrice: (r) => (r['sellPrice'] as num?)?.toDouble() ?? 0.0,
      );

  /// What the ISP makes on the materials alone. Rendered as "Estimated
  /// Material Margin" in both installation forms.
  double get markup => revenue - cost;

  @override
  List<Object?> get props => [cost, revenue, isRecorded];

  @override
  String toString() =>
      'MaterialTotals(cost: $cost, revenue: $revenue, recorded: $isRecorded)';
}
