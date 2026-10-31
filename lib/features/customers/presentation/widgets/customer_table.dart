import 'package:flutter/material.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';

// Colours for the redesigned Customers screen. Kept private to this file so
// the app theme does not have to change.
const Color _kInk = Color(0xFF14213D);
const Color _kMuted = Color(0xFF5B6472);
const Color _kBorder = Color(0xFFE3E6EB);
const Color _kTeal = Color(0xFF0F766E);
const Color _kDanger = Color(0xFFB42318);
const Color _kWarnText = Color(0xFF7A3E00);
const Color _kSoft = Color(0xFFF6F7F9);

/// Formats a PKR amount in full with commas, like `Rs 420,686`.
String formatRs(num value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}Rs $buffer';
}

String _days(int n) => n == 1 ? '1 day' : '$n days';

/// Full-width customers table for desktop.
///
/// Pure UI - every action is a callback from the page.
class CustomerTable extends StatelessWidget {
  final List<CustomerModel> customers;
  final bool isAdmin;
  final String Function(String? packageId) getPackageName;
  final String? footerText;
  final void Function(CustomerModel customer) onView;
  final void Function(CustomerModel customer) onRenew;
  final void Function(CustomerModel customer) onEdit;
  final void Function(CustomerModel customer) onToggleStatus;
  final void Function(CustomerModel customer) onDelete;

  const CustomerTable({
    super.key,
    required this.customers,
    required this.isAdmin,
    required this.getPackageName,
    required this.onView,
    required this.onRenew,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    this.footerText,
  });

  /// Below this width the table scrolls sideways inside its card instead of
  /// squeezing its columns.
  static const double _minWidth = 1000;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final table = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderRow(isAdmin: isAdmin),
        ...customers.map(
          (c) => _CustomerRow(
            customer: c,
            now: now,
            isAdmin: isAdmin,
            packageName: getPackageName(c.packageId),
            onView: onView,
            onRenew: onRenew,
            onEdit: onEdit,
            onToggleStatus: onToggleStatus,
            onDelete: onDelete,
          ),
        ),
        if (footerText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kBorder)),
            ),
            child: Text(
              footerText!,
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final Widget body = constraints.maxWidth >= _minWidth
            ? table
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: _minWidth, child: table),
              );
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: body,
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final bool isAdmin;
  const _HeaderRow({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: _kInk,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFEEF2F6),
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 16,
            child: Text(
              'Customer',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
          ),
          const Expanded(
            flex: 10,
            child: Text(
              'Connection',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
          ),
          const Expanded(
            flex: 14,
            child: Text(
              'Package',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
          ),
          if (isAdmin)
            const Expanded(
              flex: 12,
              child: Text(
                'Monthly bill',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
            ),
          const Expanded(
            flex: 14,
            child: Text(
              'Due date',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
          ),
          const SizedBox(width: 280, child: Text('Actions', style: style)),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final CustomerModel customer;
  final DateTime now;
  final bool isAdmin;
  final String packageName;
  final void Function(CustomerModel customer) onView;
  final void Function(CustomerModel customer) onRenew;
  final void Function(CustomerModel customer) onEdit;
  final void Function(CustomerModel customer) onToggleStatus;
  final void Function(CustomerModel customer) onDelete;

  const _CustomerRow({
    required this.customer,
    required this.now,
    required this.isAdmin,
    required this.packageName,
    required this.onView,
    required this.onRenew,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final isDue = c.isDueForRenewalAt(now);
    final isExpired = c.isExpiredAt(now);
    final subline = c.phone.isEmpty
        ? c.id.toUpperCase()
        : '${c.id.toUpperCase()} · ${c.phone}';

    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          // Customer
          Expanded(
            flex: 16,
            child: InkWell(
              onTap: () => onView(c),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ],
              ),
            ),
          ),
          // Connection
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _kSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Text(
                  c.connectionType == 'fiber' ? 'Fiber' : 'Wireless',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                ),
              ),
            ),
          ),
          // Package
          Expanded(
            flex: 14,
            child: Text(
              packageName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: _kInk),
            ),
          ),
          // Monthly bill (admin only, same as the mobile cards)
          if (isAdmin)
            Expanded(
              flex: 10,
              child: Text(
                formatRs(c.monthlyBill),
                style: const TextStyle(fontSize: 14, color: _kInk),
              ),
            ),
          // Due date
          Expanded(flex: 14, child: _dueCell(c)),
          // Actions
          SizedBox(
            width: 300,
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: isDue
                      ? Tooltip(
                          message: isExpired
                              ? 'Expired - collect payment and renew'
                              : 'Renew early',
                          child: ElevatedButton(
                            onPressed: () => onRenew(c),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kTeal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(0, 44),
                              padding: EdgeInsets.zero,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Renew'),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                _outlined('View', () => onView(c)),
                const SizedBox(width: 8),
                _outlined('Edit', () => onEdit(c)),
                const SizedBox(width: 8),
                _moreMenu(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlined(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kInk,
        side: const BorderSide(color: _kBorder),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }

  Widget _moreMenu(CustomerModel c) {
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      onSelected: (value) {
        if (value == 'toggle') {
          onToggleStatus(c);
        } else if (value == 'delete') {
          onDelete(c);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                c.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                size: 18,
                color: _kInk,
              ),
              const SizedBox(width: 10),
              Text(
                c.isActive ? 'Deactivate' : 'Reactivate',
                style: const TextStyle(color: _kInk),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: _kDanger),
              SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: _kDanger)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: const Icon(Icons.more_horiz, size: 20, color: _kInk),
      ),
    );
  }

  /// Date on the first line, state in colour on the second. This replaces the
  /// old Status column, which said "Active" even on an overdue account.
  Widget _dueCell(CustomerModel c) {
    final due = c.billingDueDate;
    if (due == null) {
      if (c.isActive) {
        return const Text('-', style: TextStyle(color: _kMuted));
      }
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Inactive',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kMuted,
            ),
          ),
          SizedBox(height: 2),
          Text('Not billing', style: TextStyle(fontSize: 12, color: _kMuted)),
        ],
      );
    }

    final diff = BillingCycle.daysUntilDue(due, now);
    Color color = _kInk;
    String label = '';
    if (diff < 0) {
      color = _kDanger;
      label = 'Overdue by ${_days(-diff)}';
    } else if (diff == 0) {
      color = _kDanger;
      label = 'Due today';
    } else if (diff <= BillingCycle.renewalWindowDays) {
      color = _kWarnText;
      label = 'Due in ${_days(diff)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateTimeUtils.formatDate(due),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(label, style: TextStyle(fontSize: 12, color: color)),
          ),
        if (c.nextDueDate == null)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'estimated',
              style: TextStyle(fontSize: 11, color: _kMuted),
            ),
          ),
      ],
    );
  }
}
