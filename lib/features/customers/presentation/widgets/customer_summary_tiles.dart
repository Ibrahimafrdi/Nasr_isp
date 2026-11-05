import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_table.dart'
    show formatRs;

const Color _kInk = Color(0xFF14213D);
const Color _kMuted = Color(0xFF5B6472);
const Color _kBorder = Color(0xFFE3E6EB);
const Color _kTeal = Color(0xFF0F766E);
const Color _kAmber = Color(0xFFB45309);
const Color _kRed = Color(0xFFB42318);
const Color _kGrey = Color(0xFF8A93A1);

/// The five customer counts, as tiles. Tapping a tile filters the list by
/// that status; tapping the selected tile clears it. This replaces both the
/// orange "Needs your attention" bar and the status chips, which said the
/// same thing twice.
class CustomerSummaryTiles extends StatelessWidget {
  final CustomersSummary summary;

  /// `null` = all customers.
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  const CustomerSummaryTiles({
    super.key,
    required this.summary,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <_TileData>[
      _TileData(
        label: 'All customers',
        count: summary.total,
        status: null,
        accent: _kInk,
      ),
      _TileData(
        label: 'Active',
        count: summary.active,
        status: CustomerStatus.active.label,
        accent: _kTeal,
      ),
      _TileData(
        label: 'Expiring soon',
        count: summary.expiringSoon,
        status: CustomerStatus.expiringSoon.label,
        accent: _kAmber,
        note: 'Next ${BillingCycle.renewalWindowDays} days',
      ),
      _TileData(
        label: 'Expired',
        count: summary.expired,
        status: CustomerStatus.expired.label,
        accent: _kRed,
        note: summary.expired > 0
            ? '${formatRs(summary.expiredAmount)} to collect'
            : null,
      ),
      _TileData(
        label: 'Inactive',
        count: summary.inactive,
        status: CustomerStatus.inactive.label,
        accent: _kGrey,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = constraints.maxWidth;
        // 5 across on desktop, 3 on tablet, 2 on phones.
        final perRow = width >= 980 ? 5 : (width >= 640 ? 3 : 2);
        final tileWidth = (width - gap * (perRow - 1)) / perRow;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tiles)
              SizedBox(
                width: tileWidth,
                child: _Tile(
                  data: t,
                  selected: selectedStatus == t.status,
                  onTap: () {
                    final isSelected = selectedStatus == t.status;
                    // Tapping the selected tile goes back to "all".
                    onStatusChanged(isSelected ? null : t.status);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TileData {
  final String label;
  final int count;
  final String? status;
  final Color accent;
  final String? note;

  const _TileData({
    required this.label,
    required this.count,
    required this.status,
    required this.accent,
    this.note,
  });
}

class _Tile extends StatelessWidget {
  final _TileData data;
  final bool selected;
  final VoidCallback onTap;

  const _Tile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = data.accent;
    return Material(
      color: selected ? accent.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : _kBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${data.count}',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: data.count > 0 && data.status != null
                      ? accent
                      : _kInk,
                ),
              ),
              if (data.note != null) ...[
                const SizedBox(height: 4),
                Text(
                  data.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
