import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';

/// Entry point for "Add Customer" — lets the admin choose between
/// registering a pre-existing subscriber record (unchanged form) or
/// onboarding a brand-new subscriber together with their installation.
class AddCustomerChoicePage extends StatelessWidget {
  const AddCustomerChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Breadcrumb(
              items: [
                BreadcrumbItem(
                  label: 'Home',
                  onTap: () => context.go(RoutePaths.dashboard),
                ),
                BreadcrumbItem(
                  label: 'Customers',
                  onTap: () => context.go(RoutePaths.customers),
                ),
                BreadcrumbItem(label: 'Add Customer'),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'How would you like to add this customer?',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose "Existing Customer" for a plain subscriber record, or '
              '"New Customer" to also register their installation and its costs.',
              style: TextStyle(color: AppTheme.mediumGray),
            ),
            const SizedBox(height: 28),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 640;
                    final cards = [
                      _ChoiceCard(
                        icon: Icons.person_outline,
                        title: 'Existing Customer',
                        description:
                            'Add a subscriber record using the standard form '
                            '— name, contact, package and billing details.',
                        color: AppColors.primaryBlue,
                        onTap: () => context.go('${RoutePaths.addCustomer}/existing'),
                      ),
                      _ChoiceCard(
                        icon: Icons.add_business_outlined,
                        title: 'New Customer',
                        description:
                            'Onboard a brand-new subscriber and log their '
                            'installation — cost, labor and profit — in one step.',
                        color: AppTheme.successColor,
                        onTap: () => context.go('${RoutePaths.addCustomer}/new'),
                      ),
                    ];

                    if (isNarrow) {
                      return Column(
                        children: [
                          cards[0],
                          const SizedBox(height: 16),
                          cards[1],
                        ],
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[1]),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightGray.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: AppTheme.mediumGray),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
