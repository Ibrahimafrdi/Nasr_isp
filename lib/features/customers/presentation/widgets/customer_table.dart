import 'package:flutter/material.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';

// Colours for the Customers screen. Private to this file so the app theme
// does not have to change.
const Color _kInk = Color(0xFF14213D);
const Color _kMuted = Color(0xFF5B6472);
const Color _kFaint = Color(0xFF8A93A1);
const Color _kBorder = Color(0xFFE3E6EB);
const Color _kTeal = Color(0xFF0F766E);
const Color _kTealSoft = Color(0xFFE6F4F1);
const Color _kDanger = Color(0xFFB42318);
const Color _kRowHover = Color(0xFFF8FAFB);
const Color _kHeaderBg = Color(0xFFF8F9FB);

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
/// Pure UI - every action is a callback from the page. One row = one
/// customer: who they are, what plan, what they pay, where they stand, and a
/// single obvious action (Renew when due), with the rest tucked in a menu.
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
  static const double _minWidth = 960;

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
              color: _kHeaderBg,
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

// Column layout shared by the header and every row.
const int _flexCustomer = 26;
const int _flexPlan = 20;
const int _flexBill = 12;
const int _flexStatus = 24;
const double _actionsWidth = 200;

class _HeaderRow extends StatelessWidget {
  final bool isAdmin;
  const _HeaderRow({required this.isAdmin});

  Widget _h(String text, int flex) => Expanded(
    flex: flex,
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: _kMuted,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: _kHeaderBg,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          _h('Customer', _flexCustomer),
          _h('Plan', _flexPlan),
          if (isAdmin) _h('Monthly bill', _flexBill),
          _h('Status', _flexStatus),
          SizedBox(width: 150),
          Text("Actions"),
        ],
      ),
    );
  }
}

enum _Tone { ok, warn, bad, off }

class _StatusInfo {
  final String label;
  final String detail;
  final _Tone tone;
  const _StatusInfo(this.label, this.detail, this.tone);
}

_StatusInfo _statusFor(CustomerModel c, DateTime now) {
  if (!c.isActive) {
    return const _StatusInfo('Inactive', 'Not billing', _Tone.off);
  }
  final due = c.billingDueDate;
  if (due == null) {
    return const _StatusInfo('Active', 'No due date', _Tone.ok);
  }
  final date = DateTimeUtils.formatDate(due);
  final est = c.nextDueDate == null ? ' (est.)' : '';
  final diff = BillingCycle.dayUntilDue(due, now);

  if (c.isExpiredAt(now)) {
    final sameDay = BillingCycle.dateOnly(
      due,
    ).isAtSameMomentAs(BillingCycle.dateOnly(now));
    final when = sameDay ? 'Expired today' : 'Overdue ${_days(-diff)}';
    return _StatusInfo('Expired', '$when · $date$est', _Tone.bad);
  }
  if (diff == 0) {
    return _StatusInfo('Due today', 'Due today · $date$est', _Tone.warn);
  }
  if (diff <= BillingCycle.renewalWindowDays) {
    return _StatusInfo(
      'Expiring soon',
      'In ${_days(diff)} · $date$est',
      _Tone.warn,
    );
  }
  return _StatusInfo('Active', 'Renews $date$est', _Tone.ok);
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
    final status = _statusFor(c, now);
    final isFiber = c.connectionType == 'fiber';
    final name = c.name.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return InkWell(
      onTap: () => onView(c),
      hoverColor: _kRowHover,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Row(
          children: [
            // Customer: avatar, name, phone
            Expanded(
              flex: _flexCustomer,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _kTealSoft,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kTeal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Unnamed customer' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.phone.isEmpty ? 'No phone' : c.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: _kMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Plan: package, connection type underneath
            Expanded(
              flex: _flexPlan,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    packageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kInk,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFiber ? Icons.cable : Icons.wifi,
                        size: 14,
                        color: _kFaint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFiber ? 'Fiber' : 'Wireless',
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Monthly bill (admin only, same as the mobile cards)
            if (isAdmin)
              Expanded(
                flex: _flexBill,
                child: Text(
                  formatRs(c.monthlyBill),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                ),
              ),
            // Status pill + due detail
            Expanded(
              flex: _flexStatus,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusPill(label: status.label, tone: status.tone),
                  const SizedBox(height: 4),
                  Text(
                    status.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: status.tone == _Tone.bad ? _kDanger : _kMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Actions: one primary, one icon, one menu
            SizedBox(
              width: _actionsWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isDue)
                    Tooltip(
                      message: isExpired
                          ? 'Expired - collect payment and renew'
                          : 'Renew early',
                      child: ElevatedButton(
                        onPressed: () => onRenew(c),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(84, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => onEdit(c),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: _kMuted,
                    ),
                  ),
                  _moreMenu(c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moreMenu(CustomerModel c) {
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_horiz, size: 22, color: _kMuted),
      onSelected: (value) {
        switch (value) {
          case 'view':
            onView(c);
            break;
          case 'edit':
            onEdit(c);
            break;
          case 'toggle':
            onToggleStatus(c);
            break;
          case 'delete':
            onDelete(c);
            break;
        }
      },
      itemBuilder: (context) => [
        _menuItem('view', Icons.visibility_outlined, 'View details'),
        _menuItem('edit', Icons.edit_outlined, 'Edit'),
        _menuItem(
          'toggle',
          c.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
          c.isActive ? 'Deactivate' : 'Reactivate',
        ),
        const PopupMenuDivider(),
        _menuItem('delete', Icons.delete_outline, 'Delete', danger: true),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    final color = danger ? _kDanger : _kInk;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final _Tone tone;
  const _StatusPill({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    switch (tone) {
      case _Tone.ok:
        fg = const Color(0xFF067647);
        bg = const Color(0xFFE7F6EC);
        break;
      case _Tone.warn:
        fg = const Color(0xFF7A3E00);
        bg = const Color(0xFFFFF4E5);
        break;
      case _Tone.bad:
        fg = _kDanger;
        bg = const Color(0xFFFDECEA);
        break;
      case _Tone.off:
        fg = _kMuted;
        bg = const Color(0xFFEEF0F3);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
