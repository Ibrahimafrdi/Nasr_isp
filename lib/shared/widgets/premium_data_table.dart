import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';

class PremiumDataColumn {
  final String label;

  /// Relative share of the available width, where `1.0` is one normal
  /// column. A column with `width: 2.5` is 2.5x as wide as an unset one.
  final double width;

  final TextAlign align;

  PremiumDataColumn({
    required this.label,
    this.width = 1.0,
    this.align = TextAlign.left,
  });

  /// Flex weight for the header/row [Row]. Scaled by 10 so fractional
  /// widths below 1.0 keep useful resolution after truncation.
  int get flex => math.max(1, (width * 10).round());
}

/// Upgraded PremiumDataRow supporting dynamic widgets or strings inside cells
class PremiumDataRow {
  final List<dynamic> cells;
  final VoidCallback? onTap;

  PremiumDataRow({required this.cells, this.onTap});
}

/// PremiumDataTable - Enterprise dashboard data table supporting dynamic cell widgets, row hover highlights, responsive horizontal scrolling, and custom pagination.
class PremiumDataTable extends StatefulWidget {
  final List<PremiumDataColumn> columns;
  final List<PremiumDataRow> rows;
  final bool isLoading;
  final void Function(int)? onRowTap;
  final int currentPage;
  final int rowsPerPage;
  final int? totalRows;
  final Function(int)? onPageChange;

  /// Narrowest a single (`width: 1.0`) column may be rendered. Once the
  /// columns no longer fit the available width the table becomes
  /// horizontally scrollable rather than squeezing text to nothing.
  final double minColumnWidth;

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
    this.minColumnWidth = 130,
  }) : super(key: key);

  @override
  State<PremiumDataTable> createState() => _PremiumDataTableState();
}

/// Horizontal padding applied to the header row and every body row. The
/// minimum table width has to account for it or the last column clips.
const double _kRowHorizontalPadding = 20;

class _PremiumDataTableState extends State<PremiumDataTable> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Width the columns need before text starts getting squeezed.
        final totalFlex = widget.columns.fold<int>(0, (sum, c) => sum + c.flex);
        final minTableWidth =
            (totalFlex / 10) * widget.minColumnWidth +
            _kRowHorizontalPadding * 2;

        // Read the slot we were actually given. The previous implementation
        // used the *window* width minus a hardcoded 320px sidebar, which
        // matched no real layout — the sidebar is 260px and is absent
        // entirely below the desktop breakpoint.
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : minTableWidth;
        final tableWidth = math.max(available, minTableWidth);
        final needsHorizontalScroll = tableWidth > available;

        final table = SizedBox(width: tableWidth, child: _buildHeaderAndBody());

        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.lightGray.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (needsHorizontalScroll)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: table,
                )
              else
                table,

              // Pagination stays outside the horizontal scroller so it
              // remains pinned when the table scrolls sideways.
              _buildPaginationBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderAndBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sticky Header Row
        Container(
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.lightGray.withOpacity(0.8),
                width: 1.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: _kRowHorizontalPadding,
            vertical: 14,
          ),
          height: 52,
          child: Row(
            children: widget.columns
                .map(
                  (col) => Expanded(
                    flex: col.flex,
                    child: Text(
                      col.label,
                      textAlign: col.align,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.charcoal,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        // Body: Loading, Empty, or List rows
        if (widget.isLoading)
          Container(
            height: 180,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading record directory...',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
          )
        else if (widget.rows.isEmpty)
          Container(
            height: 180,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.layers_clear_outlined,
                  size: 40,
                  color: AppColors.mediumGray.withOpacity(0.8),
                ),
                const SizedBox(height: 12),
                Text(
                  'No matching records found',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.darkGray,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try adjusting filters or checking query parameters.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.rows.length, (index) {
              final row = widget.rows[index];
              final isLastRow = index == widget.rows.length - 1;

              return Container(
                decoration: BoxDecoration(
                  border: isLastRow
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: AppColors.lightGray.withOpacity(0.5),
                            width: 0.8,
                          ),
                        ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: row.onTap ?? () => widget.onRowTap?.call(index),
                    hoverColor: AppColors.primaryBlue.withOpacity(0.03),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _kRowHorizontalPadding,
                        vertical: 14,
                      ),
                      // Minimum, not fixed — lets rows grow for
                      // multi-line cell content (e.g. a title +
                      // notes) instead of overflowing.
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Row(
                        children: List.generate(widget.columns.length, (
                          cellIndex,
                        ) {
                          // Tolerate a row with fewer cells than
                          // there are columns rather than
                          // throwing RangeError during layout.
                          final cell = cellIndex < row.cells.length
                              ? row.cells[cellIndex]
                              : '';
                          return Expanded(
                            flex: widget.columns[cellIndex].flex,
                            child: Align(
                              alignment: _getAlignment(
                                widget.columns[cellIndex].align,
                              ),
                              child: cell is Widget
                                  ? cell
                                  : Text(
                                      cell.toString(),
                                      textAlign:
                                          widget.columns[cellIndex].align,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.charcoal,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildPaginationBar() {
    if (widget.totalRows == null || widget.totalRows! <= widget.rowsPerPage) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.lightGray.withOpacity(0.8),
            width: 1.5,
          ),
        ),
        color: AppColors.offWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Showing ${widget.rows.length} of ${widget.totalRows} records',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.darkGray,
                fontSize: 12,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: widget.currentPage > 1
                    ? () => widget.onPageChange?.call(widget.currentPage - 1)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Text(
                  'Page ${widget.currentPage}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed:
                    (widget.currentPage * widget.rowsPerPage) <
                        widget.totalRows!
                    ? () => widget.onPageChange?.call(widget.currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Alignment _getAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.left:
      default:
        return Alignment.centerLeft;
    }
  }
}
