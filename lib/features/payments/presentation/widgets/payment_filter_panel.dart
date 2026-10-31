import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';

/// One-row modern filter bar for the Payments page.
/// Provides real-time search, status tabs with colored dot indicators,
/// payment method filtering, date-range selection, and clear actions.
class PaymentFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedStatus;
  final String? selectedMethod;
  final int activeFilterCount;
  final bool hasDateRange;
  final String? dateRangeLabel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?>? onMethodChanged;
  final VoidCallback onPickDateRange;
  final VoidCallback? onClearDateRange;
  final VoidCallback? onClearFilters;

  const PaymentFilterPanel({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    this.selectedMethod,
    required this.activeFilterCount,
    required this.hasDateRange,
    this.dateRangeLabel,
    required this.onSearchChanged,
    required this.onStatusChanged,
    this.onMethodChanged,
    required this.onPickDateRange,
    this.onClearDateRange,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search Input Field
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navyDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search customer name, ID, or month...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.mediumGray,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.darkGray,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          color: AppColors.darkGray,
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.lightGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Status Filter Tabs
          _StatusPillTab(
            label: 'All',
            isSelected: selectedStatus == null,
            onTap: () => onStatusChanged(null),
          ),
          _StatusPillTab(
            label: 'Paid',
            dotColor: AppColors.successGreen,
            isSelected: selectedStatus == 'paid',
            onTap: () => onStatusChanged('paid'),
          ),
          _StatusPillTab(
            label: 'Unpaid',
            dotColor: AppColors.errorRed,
            isSelected: selectedStatus == 'unpaid',
            onTap: () => onStatusChanged('unpaid'),
          ),
          _StatusPillTab(
            label: 'Partial',
            dotColor: AppColors.warningOrange,
            isSelected: selectedStatus == 'partial',
            onTap: () => onStatusChanged('partial'),
          ),

          // Divider between status and filters
          Container(width: 1, height: 26, color: AppColors.lightGray),

          // Payment Method Selector Dropdown (Optional / Additional UX)
          if (onMethodChanged != null)
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: selectedMethod != null
                    ? AppColors.primaryBlue.withValues(alpha: 0.08)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selectedMethod != null
                      ? AppColors.primaryBlue
                      : AppColors.lightGray,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: selectedMethod,
                  hint: Text(
                    'All Methods',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.charcoal,
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.darkGray,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('All Methods'),
                    ),
                    DropdownMenuItem(
                      value: 'cash',
                      child: Text('Cash'),
                    ),
                    DropdownMenuItem(
                      value: 'bankTransfer',
                      child: Text('Bank Transfer'),
                    ),
                    DropdownMenuItem(
                      value: 'easypaisa',
                      child: Text('EasyPaisa'),
                    ),
                    DropdownMenuItem(
                      value: 'jazzcash',
                      child: Text('JazzCash'),
                    ),
                  ],
                  onChanged: onMethodChanged,
                ),
              ),
            ),

          // Date Range Picker Button
          OutlinedButton.icon(
            onPressed: onPickDateRange,
            icon: Icon(
              Icons.date_range_rounded,
              size: 16,
              color: hasDateRange ? AppColors.primaryBlue : AppColors.darkGray,
            ),
            label: Text(
              hasDateRange && dateRangeLabel != null
                  ? dateRangeLabel!
                  : 'Filter by Date Range',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: hasDateRange ? FontWeight.w600 : FontWeight.w500,
                color: hasDateRange ? AppColors.primaryBlue : AppColors.charcoal,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: hasDateRange
                  ? AppColors.primaryBlue.withValues(alpha: 0.06)
                  : Colors.white,
              side: BorderSide(
                color: hasDateRange ? AppColors.primaryBlue : AppColors.lightGray,
              ),
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Clear Date Range Icon
          if (hasDateRange && onClearDateRange != null)
            IconButton(
              tooltip: 'Clear date filter',
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.darkGray,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              splashRadius: 18,
              onPressed: onClearDateRange,
            ),

          // Clear All Filters
          if (activeFilterCount > 0 && onClearFilters != null)
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: Text(
                'Reset Filters ($activeFilterCount)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPillTab extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusPillTab({
    required this.label,
    this.dotColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.lightGray,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
