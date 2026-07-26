import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';

/// Whether a job contributes to financial aggregates.
///
/// Completed jobs only, on every screen. A cancelled job never deducted stock
/// (the completed -> cancelled transition is blocked precisely because it
/// would) and never billed anyone, so counting its setup fee as revenue is
/// fiction and counting its BOM as cost double-counts stock that was never
/// issued. Pending and in-progress jobs are pipeline: they show up in counts,
/// never in money.
bool isFinanciallyCountable(InstallationStatus status) =>
    status == InstallationStatus.completed;

/// The combined billed/cost/profit position of [installations].
///
/// This is the single sanctioned aggregate for installation KPIs. Because it
/// sums each job's own [InstallationEntity.money], a summary card built from
/// it is arithmetically guaranteed to equal the sum of the rows on screen.
///
/// Callers are responsible for scoping the input — this function has no
/// opinion on status or date. Use [isFinanciallyCountable] and
/// [completedInMonth] for that.
MoneyLine installationsMoney(Iterable<InstallationEntity> installations) =>
    MoneyLine.sum(installations.map((i) => i.money));

/// Completed jobs whose completion date falls in the calendar month
/// containing [month].
///
/// Falls back to `createdAt` for records written before `completedAt` existed;
/// new records always carry a server-stamped `completedAt`.
List<InstallationEntity> completedInMonth(
  Iterable<InstallationEntity> installations,
  DateTime month,
) =>
    installations.where((i) {
      if (!isFinanciallyCountable(i.status)) return false;
      final date = i.completedAt ?? i.createdAt;
      return date.year == month.year && date.month == month.month;
    }).toList();
