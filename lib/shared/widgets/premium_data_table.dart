import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';

class PremiumDataColumn {
  final String label;
  final double? width;
  final TextAlign align;

  PremiumDataColumn({
    required this.label,
    this.width,
    this.align = TextAlign.left,
  });
}

class PremiumDataRow {
  final List<String> cells;
  final VoidCallback? onTap;

  PremiumDataRow({required this.cells, this.onTap});
}

class PremiumDataTable extends StatefulWidget {
  final List<PremiumDataColumn> columns;
  final List<PremiumDataRow> rows;
  final bool isLoading;
  final void Function(int)? onRowTap;
  final int currentPage;
  final int rowsPerPage;
  final int? totalRows;
  final Function(int)? onPageChange;

  const PremiumDataTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.onRowTap,
    this.currentPage = 1,
    this.rowsPerPage = 10,
    this.totalRows,
    this.onPageChange,
  }) : super(key: key);

  @override
  State<PremiumDataTable> createState() => _PremiumDataTableState();
}

class _PremiumDataTableState extends State<PremiumDataTable> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.lightGray, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Table Header
          Container(
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLg),
                topRight: Radius.circular(AppSpacing.radiusLg),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.lightGray, width: 1),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            height: AppSpacing.tableHeaderHeight,
            child: Row(
              children: widget.columns
                  .map(
                    (col) => Expanded(
                      flex: col.width != null ? (col.width! * 10).toInt() : 1,
                      child: Text(
                        col.label,
                        textAlign: col.align,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          // Table Body
          if (widget.isLoading)
            Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
            )
          else if (widget.rows.isEmpty)
            Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'No data available',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mediumGray,
                ),
              ),
            )
          else
            // ✅ Column instead of Expanded + ListView — parent scrollview handles scrolling
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.rows.length, (index) {
                final row = widget.rows[index];
                final isLastRow = index == widget.rows.length - 1;

                return GestureDetector(
                  onTap: row.onTap ?? () => widget.onRowTap?.call(index),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      decoration: BoxDecoration(
                        border: isLastRow
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: AppColors.lightGray,
                                  width: 0.5,
                                ),
                              ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap:
                              row.onTap ?? () => widget.onRowTap?.call(index),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            height: AppSpacing.tableRowHeight,
                            child: Row(
                              children: List.generate(
                                widget.columns.length,
                                (cellIndex) => Expanded(
                                  flex: widget.columns[cellIndex].width != null
                                      ? (widget.columns[cellIndex].width! * 10)
                                            .toInt()
                                      : 1,
                                  child: Text(
                                    row.cells[cellIndex],
                                    textAlign: widget.columns[cellIndex].align,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.charcoal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          // Pagination
          if (widget.totalRows != null &&
              widget.totalRows! > widget.rowsPerPage)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.lightGray, width: 1),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppSpacing.radiusLg),
                  bottomRight: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.currentPage > 1)
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: () =>
                          widget.onPageChange?.call(widget.currentPage - 1),
                    ),
                  Text(
                    'Page ${widget.currentPage}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.charcoal,
                    ),
                  ),
                  if ((widget.currentPage + widget.rowsPerPage) <
                      (widget.totalRows ?? 0))
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: () =>
                          widget.onPageChange?.call(widget.currentPage + 1),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
