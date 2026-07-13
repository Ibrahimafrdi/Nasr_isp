import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/info_chip.dart';
import 'package:nasr_isp/shared/widgets/status_badge.dart';

/// Mobile card list for the Customers page.
///
/// Pure UI — callbacks are provided by the parent page.
class CustomerCardList extends StatelessWidget {
  final List<CustomerModel> customers;
  final UserModel currentUser;

  /// Resolves a package ID to its display name.
  final String Function(String? packageId) getPackageName;

  /// Called when the user taps "Delete" on a card.
  final void Function(CustomerModel customer) onDelete;

  const CustomerCardList({
    super.key,
    required this.customers,
    required this.currentUser,
    required this.getPackageName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: customers.map((customer) => _CustomerCard(
        customer: customer,
        currentUser: currentUser,
        getPackageName: getPackageName,
        onDelete: onDelete,
      )).toList(),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final UserModel currentUser;
  final String Function(String? packageId) getPackageName;
  final void Function(CustomerModel customer) onDelete;

  const _CustomerCard({
    required this.customer,
    required this.currentUser,
    required this.getPackageName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      customer.id.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: customer.status),
            ],
          ),
          const SizedBox(height: 10),

          // Info chips
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              InfoChip(Icons.speed, getPackageName(customer.packageId)),
              InfoChip(
                Icons.settings_input_antenna,
                customer.connectionType == 'fiber' ? 'Fiber' : 'Wireless',
                color: customer.connectionType == 'fiber'
                    ? Colors.purple
                    : Colors.blue[800],
              ),
              if (currentUser.isAdmin)
                InfoChip(
                  Icons.monetization_on,
                  DateTimeUtils.formatCurrency(customer.monthlyBill),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  context.go('${RoutePaths.customers}/${customer.id}');
                },
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                onPressed: () {
                  context.go('${RoutePaths.customers}/${customer.id}/edit');
                },
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                onPressed: () => onDelete(customer),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
