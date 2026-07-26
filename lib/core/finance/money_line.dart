import 'package:equatable/equatable.dart';

/// One financial position: what was billed to the customer, and what it cost
/// the ISP to deliver.
///
/// Only [amountBilled] and [costIncurred] are stored — [profit] and
/// [marginPct] are derived. A caller therefore cannot report a profit that
/// disagrees with `billed - cost`, because that inconsistency is not
/// representable. Every revenue/cost/profit figure in the app, per-row and
/// aggregate alike, should be produced as a MoneyLine rather than as three
/// loose doubles.
///
/// Deliberately entity-agnostic: it knows nothing about installations,
/// customers or packages, which is what keeps it in `core/`.
class MoneyLine extends Equatable {
  /// Total charged to the customer for this line. For an installation this is
  /// the setup fee PLUS the sell-price value of the materials consumed —
  /// materials are billed on top of the setup fee, not absorbed by it.
  final double amountBilled;

  /// Total the ISP paid out for this line: materials at cost, labour,
  /// upstream bandwidth, and so on.
  final double costIncurred;

  const MoneyLine({required this.amountBilled, required this.costIncurred});

  /// Additive identity — the correct seed for [sum] and for empty collections.
  static const MoneyLine zero = MoneyLine(amountBilled: 0.0, costIncurred: 0.0);

  /// Always defined. Negative means the line lost money.
  double get profit => amountBilled - costIncurred;

  /// Profit as a percentage of [amountBilled], or null when the margin is
  /// undefined because nothing was billed.
  ///
  /// Null rather than zero on purpose: a zero-revenue line with real costs has
  /// no meaningful margin, and rendering "0.0% margin" would read as
  /// break-even when it is in fact a pure loss. Call sites decide what to show
  /// instead — the existing copy is 'No revenue records'.
  double? get marginPct =>
      amountBilled <= 0.0 ? null : (profit / amountBilled) * 100.0;

  /// True when this line carries no billing and no cost signal at all. Useful
  /// for telling "genuinely zero" apart from "nothing recorded yet".
  bool get isZero => amountBilled == 0.0 && costIncurred == 0.0;

  MoneyLine operator +(MoneyLine other) => MoneyLine(
        amountBilled: amountBilled + other.amountBilled,
        costIncurred: costIncurred + other.costIncurred,
      );

  /// Folds [lines] into a single position, returning [zero] for an empty
  /// iterable. This is the only sanctioned way to build an aggregate KPI — a
  /// summary card built this way can never disagree with the rows beneath it.
  static MoneyLine sum(Iterable<MoneyLine> lines) =>
      lines.fold(zero, (acc, line) => acc + line);

  @override
  List<Object?> get props => [amountBilled, costIncurred];

  @override
  String toString() =>
      'MoneyLine(billed: $amountBilled, cost: $costIncurred, profit: $profit)';
}
