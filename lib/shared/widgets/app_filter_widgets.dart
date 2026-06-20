import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';

// ============================================================================
// AppFilterContainer — Premium card wrapper for filter sections
// ============================================================================

class AppFilterContainer extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? titleIcon;

  const AppFilterContainer({
    Key? key,
    required this.child,
    this.title,
    this.titleIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.lightGray.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtle gradient accent line at top
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMd),
                topRight: Radius.circular(AppSpacing.radiusMd),
              ),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue,
                  AppColors.blueAccent.withOpacity(0.5),
                  AppColors.primaryBlue.withOpacity(0.1),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Row(
                    children: [
                      if (titleIcon != null) ...[
                        Icon(titleIcon, size: 18, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AppFilterChip — Premium animated pill-style filter chip
// ============================================================================

class AppFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  const AppFilterChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  }) : super(key: key);

  @override
  State<AppFilterChip> createState() => _AppFilterChipState();
}

class _AppFilterChipState extends State<AppFilterChip>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.selected;

    final Color bgColor = isActive
        ? AppColors.primaryBlue
        : (_isHovered
              ? AppColors.primaryBlue.withOpacity(0.07)
              : AppColors.offWhite);

    final Color textColor = isActive
        ? AppColors.white
        : (_isHovered ? AppColors.primaryBlue : AppColors.charcoal);

    final Color borderColor = isActive
        ? AppColors.primaryBlue
        : (_isHovered
              ? AppColors.primaryBlue.withOpacity(0.35)
              : AppColors.lightGray);

    final List<BoxShadow> shadows = isActive
        ? [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]
        : (_isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : []);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onSelected(!widget.selected),
        child: AnimatedScale(
          scale: _isHovered && !isActive ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: widget.icon != null ? 14 : 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: shadows,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 14, color: textColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isActive || _isHovered
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 12.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// AppStatusChipGroup — Reusable "All + status options" single-select group
//
// USAGE (shared across Customers, Payments, Installations, Inventory, etc.):
//
//   AppStatusChipGroup(
//     options: const ['Active', 'Expiring Soon', 'Expired', 'Inactive'],
//     selected: _selectedStatus,        // null/empty => "All" is active
//     onChanged: (value) {
//       setState(() => _selectedStatus = value); // value is null when "All" tapped
//       // re-trigger bloc load with new filter here
//     },
//   ),
//
// "All" is always the first chip and is shown as active whenever `selected`
// is null. Tapping any other chip switches single-select to that status;
// tapping "All" clears the filter back to null.
// ============================================================================

class AppStatusChipGroup extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final String allLabel;

  const AppStatusChipGroup({
    Key? key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.allLabel = 'All',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        AppFilterChip(
          label: allLabel,
          selected: selected == null,
          onSelected: (_) => onChanged(null),
        ),
        ...options.map(
          (option) => AppFilterChip(
            label: option,
            selected: selected == option,
            onSelected: (_) => onChanged(option),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// AppSearchField — Enhanced search text field with animations
// ============================================================================

class AppSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const AppSearchField({
    Key? key,
    required this.controller,
    this.hintText = 'Search...',
    required this.onChanged,
    this.onClear,
  }) : super(key: key);

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: TextField(
          controller: widget.controller,
          style: const TextStyle(fontSize: 13.5, color: AppColors.charcoal),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontSize: 13,
              color: AppColors.mediumGray.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.search_rounded,
                size: 20,
                color: _isFocused
                    ? AppColors.primaryBlue
                    : AppColors.mediumGray,
              ),
            ),
            suffixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: widget.controller.text.isNotEmpty
                  ? IconButton(
                      key: const ValueKey('clear'),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.mediumGray,
                      splashRadius: 16,
                      onPressed: () {
                        widget.controller.clear();
                        widget.onClear?.call();
                        widget.onChanged('');
                        setState(() {});
                      },
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            filled: true,
            fillColor: _isFocused ? AppColors.white : AppColors.offWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: AppColors.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(
                color: AppColors.lightGray.withOpacity(0.8),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
          ),
          onChanged: (value) {
            setState(() {}); // rebuild to show/hide clear button
            widget.onChanged(value);
          },
        ),
      ),
    );
  }
}

// ============================================================================
// AppFilterBadge — Active filter counter badge
// ============================================================================

class AppFilterBadge extends StatelessWidget {
  final int count;

  const AppFilterBadge({Key? key, required this.count}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: count > 0
          ? Container(
              key: ValueKey('badge_$count'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 13,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Active: $count',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
}

// ============================================================================
// AppClearFilterButton — Animated clear filters action button
// ============================================================================

class AppClearFilterButton extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClear;

  const AppClearFilterButton({
    Key? key,
    required this.isVisible,
    required this.onClear,
  }) : super(key: key);

  @override
  State<AppClearFilterButton> createState() => _AppClearFilterButtonState();
}

class _AppClearFilterButtonState extends State<AppClearFilterButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          ),
        );
      },
      child: widget.isVisible
          ? MouseRegion(
              key: const ValueKey('clear_btn'),
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? AppColors.errorRed.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: widget.onClear,
                  icon: Icon(
                    Icons.clear_all_rounded,
                    size: 17,
                    color: _isHovered
                        ? AppColors.errorRed
                        : AppColors.errorRed.withOpacity(0.7),
                  ),
                  label: Text(
                    'Clear Filters',
                    style: TextStyle(
                      color: _isHovered
                          ? AppColors.errorRed
                          : AppColors.errorRed.withOpacity(0.7),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }
}
