import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/shared/widgets/premium_data_table.dart';

/// A wrapper widget that adaptively chooses between a full tabular format on desktop (>=768px)
/// and a vertical stack of custom items (mobileItemBuilder) on mobile screens.
class ResponsiveTable extends StatelessWidget {
  final List<PremiumDataColumn> columns;
  final List<PremiumDataRow> rows;
  final bool isLoading;
  final void Function(int)? onRowTap;
  final int currentPage;
  final int rowsPerPage;
  final int? totalRows;
  final Function(int)? onPageChange;
  final Widget Function(BuildContext, int) mobileItemBuilder;

  const ResponsiveTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.onRowTap,
    this.currentPage = 1,
    this.rowsPerPage = 10,
    this.totalRows,
    this.onPageChange,
    required this.mobileItemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          if (isLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              ),
            );
          }
          if (rows.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'No records found',
                  style: TextStyle(
                    color: AppColors.mediumGray,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  return mobileItemBuilder(context, index);
                },
              ),
              if (totalRows != null && totalRows! > rowsPerPage) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: currentPage > 1 ? () => onPageChange?.call(currentPage - 1) : null,
                    ),
                    Text(
                      'Page $currentPage',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: (currentPage * rowsPerPage) < totalRows! ? () => onPageChange?.call(currentPage + 1) : null,
                    ),
                  ],
                ),
              ],
            ],
          );
        } else {
          return PremiumDataTable(
            columns: columns,
            rows: rows,
            isLoading: isLoading,
            onRowTap: onRowTap,
            currentPage: currentPage,
            rowsPerPage: rowsPerPage,
            totalRows: totalRows,
            onPageChange: onPageChange,
          );
        }
      },
    );
  }
}
