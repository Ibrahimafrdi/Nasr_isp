import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/shared/models/models.dart';

class DashboardSidebar extends StatefulWidget {
  final UserModel currentUser;
  final String currentRoute;
  final VoidCallback? onLogout;

  const DashboardSidebar({
    Key? key,
    required this.currentUser,
    required this.currentRoute,
    this.onLogout,
  }) : super(key: key);

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  bool isExpanded = true;

  List<SidebarItem> _getMenuItems() {
    final items = <SidebarItem>[
      SidebarItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        route: RoutePaths.dashboard,
      ),
      SidebarItem(
        icon: Icons.people,
        label: 'Customers',
        route: RoutePaths.customers,
      ),
      SidebarItem(
        icon: Icons.payments,
        label: 'Payments',
        route: RoutePaths.payments,
      ),
      SidebarItem(
        icon: Icons.account_balance_wallet,
        label: 'Khataa Ledger',
        route: RoutePaths.khataa,
      ),
      SidebarItem(
        icon: Icons.inventory_2,
        label: 'Inventory',
        route: RoutePaths.inventory,
      ),
    ];

    // Admin only items
    if (widget.currentUser.role.isAdmin) {
      items.addAll([
        SidebarItem(
          icon: Icons.receipt,
          label: 'Expenses',
          route: RoutePaths.expenses,
        ),
        SidebarItem(
          icon: Icons.assessment,
          label: 'Reports',
          route: RoutePaths.reports,
        ),
        SidebarItem(
          icon: Icons.groups,
          label: 'Employees',
          route: RoutePaths.employees,
        ),
        SidebarItem(
          icon: Icons.build,
          label: 'Installations',
          route: RoutePaths.installations,
        ),
      ]);
    }

    items.add(
      SidebarItem(
        icon: Icons.settings,
        label: 'Settings',
        route: RoutePaths.settings,
      ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _getMenuItems();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isExpanded
          ? AppConstants.sidebarWidthExpanded
          : AppConstants.sidebarWidthCollapsed,
      color: AppTheme.whiteColor,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.lightGray)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isExpanded)
                      Expanded(
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                'assets/logo.jpg',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'NASR ISP',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryDark,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text(
                                    'Connecting Better',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.mediumGray,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            'assets/logo.jpg',
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.chevron_left : Icons.chevron_right,
                      ),
                      onPressed: () {
                        setState(() => isExpanded = !isExpanded);
                      },
                      tooltip: isExpanded ? 'Collapse' : 'Expand',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Menu items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isActive = widget.currentRoute.startsWith(item.route);
                return _SidebarMenuItem(
                  item: item,
                  isActive: isActive,
                  isExpanded: isExpanded,
                  onTap: () {
                    context.go(item.route);
                  },
                );
              },
            ),
          ),
          // Footer - User info
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.lightGray)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isExpanded)
                  Text(
                    widget.currentUser.name,
                    style: Theme.of(context).textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (isExpanded) const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: widget.onLogout,
                        icon: const Icon(Icons.logout, size: 18),
                        label: isExpanded
                            ? const Text('Logout')
                            : const SizedBox.shrink(),
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
}

class _SidebarMenuItem extends StatefulWidget {
  final SidebarItem item;
  final bool isActive;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    Key? key,
    required this.item,
    required this.isActive,
    required this.isExpanded,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isActive;
    
    Color getBgColor() {
      if (active) return AppTheme.primaryColor.withOpacity(0.1);
      if (_isHovered) return AppTheme.primaryColor.withOpacity(0.04);
      return Colors.transparent;
    }

    Color getTextColor() {
      if (active) return AppTheme.primaryColor;
      if (_isHovered) return AppTheme.primaryColor.withOpacity(0.8);
      return AppTheme.mediumGray;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: getBgColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            dense: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.isExpanded ? 16 : 12,
              vertical: 4,
            ),
            leading: AnimatedSlide(
              offset: (_isHovered && !active && widget.isExpanded) 
                  ? const Offset(0.08, 0) 
                  : Offset.zero,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                widget.item.icon,
                color: getTextColor(),
                size: 20,
              ),
            ),
            title: widget.isExpanded
                ? AnimatedPadding(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.only(
                      left: (_isHovered && !active) ? 4.0 : 0.0,
                    ),
                    child: Text(
                      widget.item.label,
                      style: TextStyle(
                        color: active ? AppTheme.primaryColor : AppTheme.darkGray,
                        fontWeight: active ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  )
                : null,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String label;
  final String route;

  SidebarItem({required this.icon, required this.label, required this.route});
}

class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onMenuPressed;
  final UserModel? currentUser;

  const DashboardTopBar({
    Key? key,
    required this.title,
    this.actions,
    this.onMenuPressed,
    this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppTheme.whiteColor,
      foregroundColor: AppTheme.darkGray,
      title: Text(title),
      actions: [
        if (actions != null) ...actions!,
        if (currentUser != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Tooltip(
                message: '${currentUser!.name} (${currentUser!.role.name})',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      child: Text(
                        currentUser!.name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser!.name,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          currentUser!.role.name.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.mediumGray),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const Breadcrumb({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isLast = index == items.length - 1;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.onTap != null)
                  TextButton(
                    onPressed: item.onTap,
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                else
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.darkGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppTheme.lightGray,
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  BreadcrumbItem({required this.label, this.onTap});
}
