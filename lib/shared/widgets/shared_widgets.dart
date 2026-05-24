import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final CustomerStatus status;
  final String? label;

  const StatusBadge({Key? key, required this.status, this.label})
    : super(key: key);

  Color get backgroundColor {
    switch (status) {
      case CustomerStatus.active:
        return AppTheme.successColor.withOpacity(0.1);
      case CustomerStatus.expiringSoon:
        return AppTheme.warningColor.withOpacity(0.1);
      case CustomerStatus.expired:
        return AppTheme.errorColor.withOpacity(0.1);
      case CustomerStatus.inactive:
        return AppTheme.lightGray.withOpacity(0.5);
    }
  }

  Color get textColor {
    switch (status) {
      case CustomerStatus.active:
        return AppTheme.successColor;
      case CustomerStatus.expiringSoon:
        return AppTheme.warningColor;
      case CustomerStatus.expired:
        return AppTheme.errorColor;
      case CustomerStatus.inactive:
        return AppTheme.mediumGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label ?? status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const PaymentStatusBadge({Key? key, required this.status}) : super(key: key);

  Color get backgroundColor {
    switch (status) {
      case PaymentStatus.completed:
        return AppTheme.successColor.withOpacity(0.1);
      case PaymentStatus.pending:
        return AppTheme.warningColor.withOpacity(0.1);
      case PaymentStatus.failed:
        return AppTheme.errorColor.withOpacity(0.1);
      case PaymentStatus.partial:
        return AppTheme.infoColor.withOpacity(0.1);
    }
  }

  Color get textColor {
    switch (status) {
      case PaymentStatus.completed:
        return AppTheme.successColor;
      case PaymentStatus.pending:
        return AppTheme.warningColor;
      case PaymentStatus.failed:
        return AppTheme.errorColor;
      case PaymentStatus.partial:
        return AppTheme.infoColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const DashboardCard({
    Key? key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor ?? AppTheme.whiteColor,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(value, style: Theme.of(context).textTheme.displaySmall),
            if (subtitle != null) ...[
              const SizedBox(height: AppConstants.paddingSmall),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class DataTableWrapper extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int)? onSort;

  const DataTableWrapper({
    Key? key,
    required this.columns,
    required this.rows,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rows,
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        onSelectAll: null,
        showCheckboxColumn: false,
      ),
    );
  }
}

class AppSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const AppSearchBar({
    Key? key,
    this.hintText = 'Search...',
    required this.onChanged,
    this.onClear,
  }) : super(key: key);

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onClear?.call();
                  widget.onChanged('');
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (value) {
        setState(() {}); // rebuild to show/hide clear button
        widget.onChanged(value);
      },
    );
  }
}

class FilterChips extends StatelessWidget {
  final List<String> labels;
  final List<String> selectedLabels;
  final ValueChanged<List<String>> onChanged;

  const FilterChips({
    Key? key,
    required this.labels,
    required this.selectedLabels,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: labels.map((label) {
        final isSelected = selectedLabels.contains(label);
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            final newSelected = List<String>.from(selectedLabels);
            if (selected) {
              newSelected.add(label);
            } else {
              newSelected.remove(label);
            }
            onChanged(newSelected);
          },
        );
      }).toList(),
    );
  }
}

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 1
              ? () => onPageChanged(currentPage - 1)
              : null,
        ),
        ...List.generate(totalPages, (index) {
          final page = index + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: page == currentPage
                    ? AppTheme.primaryColor
                    : AppTheme.surfaceVariant,
                foregroundColor: page == currentPage
                    ? AppTheme.whiteColor
                    : AppTheme.darkGray,
                minimumSize: const Size(40, 40),
              ),
              onPressed: () => onPageChanged(page),
              child: Text('$page'),
            ),
          );
        }),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
        ),
      ],
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.lightGray),
          const SizedBox(height: AppConstants.paddingLarge),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: AppConstants.paddingLarge),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConstants.paddingMedium),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isDestructive;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
    required this.onCancel,
    this.isDestructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: onCancel, child: Text(cancelLabel)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive
                ? AppTheme.errorColor
                : AppTheme.primaryColor,
          ),
          onPressed: onConfirm,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

// Renamed from FormField → AppFormField to avoid conflict with Flutter's built-in FormField
class AppFormField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final int minLines;
  final bool isRequired;
  final bool isPassword;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;

  const AppFormField({
    Key? key,
    required this.label,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.minLines = 1,
    this.isRequired = false,
    this.isPassword = false,
    this.suffixIcon,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.errorColor),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          maxLines: isPassword ? 1 : maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
          ),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
