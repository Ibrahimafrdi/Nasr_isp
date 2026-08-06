import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';
import 'package:nasr_isp/shared/widgets/status_badge.dart';

/// Desktop side-sheet panel that displays detailed info for a selected customer.
///
/// Pure UI — callbacks are provided by the parent page.
class CustomerDetailsSideSheet extends StatelessWidget {
  final CustomerModel customer;
  final bool isAdmin;

  /// Resolves a package ID to its display name.
  final String Function(String? packageId) getPackageName;

  /// Called when the user taps the close (×) button.
  final VoidCallback onClose;

  /// Called when the user taps the "Delete" action button.
  final void Function(CustomerModel customer) onDelete;

  /// Called when the user taps "Renew Subscription".
  final void Function(CustomerModel customer) onRenew;

  const CustomerDetailsSideSheet({
    super.key,
    required this.customer,
    required this.isAdmin,
    required this.getPackageName,
    required this.onClose,
    required this.onDelete,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final due = customer.effectiveDueDate;
    final isDueForRenewal = customer.isDueForRenewalAt(now);
    final isExpired = customer.isExpiredAt(now);

    return Container(
      width: 460,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppTheme.lightGray, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.veryLightGray,
              border: Border(
                bottom: BorderSide(color: AppTheme.lightGray, width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.darkGray,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        customer.id.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.mediumGray,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StatusBadge(status: customer.status),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppTheme.mediumGray),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subscriber Info
                _sectionTitle('Subscriber Info'),
                const SizedBox(height: 10),
                _detailRow('Phone', customer.phone, Icons.phone),
                _detailRow('CNIC', customer.cnic, Icons.badge),
                _detailRow(
                  'Address',
                  customer.address.isEmpty ? 'Not provided' : customer.address,
                  Icons.location_on,
                ),
                if (customer.notes.isNotEmpty)
                  _detailRow('Notes', customer.notes, Icons.notes),

                const Divider(height: 28),

                // Connection & Plan
                _sectionTitle('Connection & Plan'),
                const SizedBox(height: 10),
                _detailRow(
                  'Type',
                  customer.connectionType == 'fiber' ? 'Fiber' : 'Wireless',
                  Icons.settings_input_antenna,
                ),
                _detailRow(
                  'Package',
                  getPackageName(customer.packageId),
                  Icons.speed,
                ),
                if (isAdmin)
                  _detailRow(
                    'Monthly Bill',
                    DateTimeUtils.formatCurrency(customer.monthlyBill),
                    Icons.receipt_long,
                  ),

                const Divider(height: 28),

                // Billing Dates
                _sectionTitle('Billing'),
                const SizedBox(height: 10),
                _detailRow(
                  'Join Date',
                  customer.joinDate != null
                      ? DateTimeUtils.formatDate(customer.joinDate!)
                      : 'N/A',
                  Icons.calendar_today,
                ),
                _detailRow(
                  'Next Due Date',
                  due != null
                      ? '${DateTimeUtils.formatDate(due)}'
                          '${isExpired ? ' · expired' : (isDueForRenewal ? ' · due soon' : '')}'
                      : 'N/A',
                  Icons.event,
                  valueColor: isExpired
                      ? AppTheme.errorColor
                      : (isDueForRenewal ? Colors.orange : null),
                  isEstimated: customer.nextDueDate == null && due != null,
                ),

                const SizedBox(height: 16),

                // Renewal is the reason this panel is open on a lapsed
                // account, so it gets its own full-width primary button above
                // the edit/delete pair rather than competing with them.
                if (isDueForRenewal) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.autorenew, size: 16),
                      label: Text(
                        isExpired
                            ? 'Collect & Renew Subscription'
                            : 'Renew Subscription Early',
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: () => onRenew(customer),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: isExpired
                            ? AppTheme.errorColor
                            : Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Edit', style: TextStyle(fontSize: 13)),
                        onPressed: () {
                          context.go(
                            '${RoutePaths.customers}/${customer.id}/edit',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 15),
                        label: const Text('Delete', style: TextStyle(fontSize: 13)),
                        onPressed: () => onDelete(customer),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryBlue,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool isEstimated = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.mediumGray),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: AppTheme.mediumGray),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isEstimated)
                  Tooltip(
                    message: 'Estimated — no payment recorded yet',
                    child: const Icon(
                      Icons.info_outline,
                      size: 12,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                if (isEstimated) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? AppTheme.darkGray,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
