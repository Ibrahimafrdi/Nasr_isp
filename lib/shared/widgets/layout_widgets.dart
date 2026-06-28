import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_fonts.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'breadcrumbs.dart';

class SidebarSubItem {
  final String label;
  final String route;

  const SidebarSubItem({required this.label, required this.route});
}

class SidebarItem {
  final IconData icon;
  final String label;
  final String route;
  final List<SidebarSubItem> subItems;

  const SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    this.subItems = const [],
  });
}

class DashboardSidebar extends StatefulWidget {
  final UserModel currentUser;
  final String currentRoute;
  final VoidCallback? onLogout;

  /// When true, sidebar is always rendered in icon-only (collapsed) mode.
  /// Used on tablet breakpoint by [AppShell].
  final bool forceCollapsed;

  const DashboardSidebar({
    super.key,
    required this.currentUser,
    required this.currentRoute,
    this.onLogout,
    this.forceCollapsed = false,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  bool _localExpanded = true;

  bool get isExpanded => widget.forceCollapsed ? false : _localExpanded;

  List<SidebarItem> _getMenuItems() {
    final isAdmin = widget.currentUser.isAdmin;

    return [
      SidebarItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        route: RoutePaths.dashboard,
      ),
      SidebarItem(
        icon: Icons.wifi,
        label: 'Packages',
        route: RoutePaths.packages,
      ),
      SidebarItem(
        icon: Icons.alt_route,
        label: 'Operations',
        route: RoutePaths.customers,
        subItems: [
          const SidebarSubItem(label: 'Customers', route: RoutePaths.customers),
          const SidebarSubItem(
            label: 'Installations',
            route: RoutePaths.installations,
          ),
          // Inventory — admin only
          if (isAdmin)
            const SidebarSubItem(
              label: 'Inventory',
              route: RoutePaths.inventory,
            ),
        ],
      ),
      SidebarItem(
        icon: Icons.account_balance_wallet,
        label: 'Financials',
        route: RoutePaths.payments,
        subItems: [
          const SidebarSubItem(label: 'Payments', route: RoutePaths.payments),
          // Khataa — admin only
          if (isAdmin)
            const SidebarSubItem(
              label: 'Khataa Ledger',
              route: RoutePaths.khataa,
            ),
          if (isAdmin)
            const SidebarSubItem(
              label: 'Expenses',
              route: RoutePaths.expenses,
            ),
        ],
      ),
      // Management group — admin only (employees see no items here)
      if (isAdmin)
        SidebarItem(
          icon: Icons.admin_panel_settings,
          label: 'Management',
          route: RoutePaths.settings,
          subItems: [
            const SidebarSubItem(
              label: 'Employees',
              route: RoutePaths.employees,
            ),
            const SidebarSubItem(
              label: 'Settings',
              route: RoutePaths.settings,
            ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _getMenuItems();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isExpanded ? 260 : 80,
      decoration: const BoxDecoration(color: AppColors.navyDark),
      child: Column(
        children: [
          // ── Logo & Branding Header ────────────────────────────────────────
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                if (isExpanded)
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/logo.jpg',
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: 'NASR',
                              style: AppFonts.bodyLarge.copyWith(
                                color: AppColors.white,
                                fontWeight: AppFonts.extraBold,
                              ),
                              children: [
                                TextSpan(
                                  text: ' ISP',
                                  style: AppFonts.bodyLarge.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: AppFonts.extraBold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Connecting Better',
                            style: AppFonts.labelSmall.copyWith(
                              color: AppColors.mediumGray,
                              fontSize: 9,
                              fontWeight: AppFonts.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/logo.jpg',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (isExpanded)
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.mediumGray,
                    ),
                    onPressed: widget.forceCollapsed
                        ? null
                        : () => setState(() => _localExpanded = false),
                  ),
              ],
            ),
          ),

          if (!isExpanded && !widget.forceCollapsed) ...[
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.mediumGray),
              onPressed: () => setState(() => _localExpanded = true),
              tooltip: 'Expand Sidebar',
            ),
          ],

          // ── Navigation Menu ───────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: menuItems.length,
              itemBuilder: (context, i) {
                final item = menuItems[i];
                final hasSubItems = item.subItems.isNotEmpty;

                // Determine active state
                bool isGroupActive = widget.currentRoute.startsWith(item.route);
                int selectedSubIndex = -1;
                for (int s = 0; s < item.subItems.length; s++) {
                  if (widget.currentRoute.startsWith(item.subItems[s].route)) {
                    isGroupActive = true;
                    selectedSubIndex = s;
                  }
                }

                return _SidebarGroupTile(
                  item: item,
                  isExpandedSidebar: isExpanded,
                  isGroupActive: isGroupActive,
                  selectedSubIndex: selectedSubIndex >= 0
                      ? selectedSubIndex
                      : null,
                  onGroupTap: () {
                    // If no sub-items, navigate directly
                    if (!hasSubItems) {
                      final scaffoldState = Scaffold.maybeOf(context);
                      if (scaffoldState != null && scaffoldState.isDrawerOpen) {
                        Navigator.pop(context);
                      }
                      context.go(item.route);
                    }
                    // If collapsed sidebar, expand it
                    if (!isExpanded) {
                      setState(() => _localExpanded = true);
                    }
                  },
                  onSubTap: (subIndex) {
                    final scaffoldState = Scaffold.maybeOf(context);
                    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
                      Navigator.pop(context);
                    }
                    context.go(item.subItems[subIndex].route);
                  },
                );
              },
            ),
          ),

          // ── User Info & Logout Footer ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                if (isExpanded) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                        child: Text(
                          widget.currentUser.name.characters.first
                              .toUpperCase(),
                          style: AppFonts.labelMedium.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: AppFonts.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.currentUser.name,
                              style: AppFonts.labelMedium.copyWith(
                                color: AppColors.white,
                                fontWeight: AppFonts.semiBold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.currentUser.role.toUpperCase(),
                              style: AppFonts.labelSmall.copyWith(
                                color: AppColors.mediumGray,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(
                      Icons.logout,
                      size: 18,
                      color: AppColors.errorRed,
                    ),
                    label: isExpanded
                        ? Text(
                            'Sign Out',
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.errorRed,
                              fontWeight: AppFonts.semiBold,
                            ),
                          )
                        : const SizedBox.shrink(),
                    style: TextButton.styleFrom(
                      alignment: isExpanded
                          ? Alignment.centerLeft
                          : Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
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

// ══════════════════════════════════════════════════════════════════════════════
// _SidebarGroupTile — Always-expanded group tile (no toggle)
// ══════════════════════════════════════════════════════════════════════════════

class _SidebarGroupTile extends StatefulWidget {
  final SidebarItem item;
  final bool isExpandedSidebar;
  final bool isGroupActive;
  final int? selectedSubIndex;
  final VoidCallback onGroupTap;
  final Function(int) onSubTap;

  const _SidebarGroupTile({
    required this.item,
    required this.isExpandedSidebar,
    required this.isGroupActive,
    this.selectedSubIndex,
    required this.onGroupTap,
    required this.onSubTap,
  });

  @override
  State<_SidebarGroupTile> createState() => _SidebarGroupTileState();
}

class _SidebarGroupTileState extends State<_SidebarGroupTile> {
  bool isHovered = false;
  int? hoveredSubIndex;

  @override
  Widget build(BuildContext context) {
    final hasSubItems = widget.item.subItems.isNotEmpty;

    final Color tileBgColor = widget.isGroupActive
        ? Colors.white.withValues(alpha: 0.08)
        : (isHovered ? Colors.white.withValues(alpha: 0.04) : Colors.transparent);

    final Color iconAndTextColor = widget.isGroupActive
        ? AppColors.primaryBlue
        : (isHovered ? AppColors.white : AppColors.mediumGray);

    return Column(
      children: [
        // ── Group header row (no chevron, no toggle) ──────────────────────
        MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onGroupTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: tileBgColor,
              ),
              child: Row(
                mainAxisAlignment: widget.isExpandedSidebar
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(widget.item.icon, color: iconAndTextColor, size: 20),
                  if (widget.isExpandedSidebar) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.item.label,
                        style: AppFonts.bodyMedium.copyWith(
                          color: iconAndTextColor,
                          fontWeight: widget.isGroupActive
                              ? AppFonts.bold
                              : AppFonts.medium,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // ← chevron removed entirely
                  ],
                ],
              ),
            ),
          ),
        ),

        // ── Sub-items — always visible when sidebar is expanded ───────────
        if (hasSubItems && widget.isExpandedSidebar)
          ...widget.item.subItems.asMap().entries.map((entry) {
            final int subIndex = entry.key;
            final SidebarSubItem subItem = entry.value;

            final bool subSelected = widget.selectedSubIndex == subIndex;
            final bool subHovered = hoveredSubIndex == subIndex;

            final Color subBgColor = subSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.12)
                : (subHovered
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.transparent);

            final Color subTextColor = subSelected
                ? AppColors.primaryBlue
                : (subHovered
                      ? AppColors.white
                      : AppColors.mediumGray.withValues(alpha: 0.8));

            return MouseRegion(
              onEnter: (_) => setState(() => hoveredSubIndex = subIndex),
              onExit: (_) => setState(() => hoveredSubIndex = null),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => widget.onSubTap(subIndex),
                child: Container(
                  margin: const EdgeInsets.only(
                    left: 36,
                    right: 16,
                    bottom: 4,
                    top: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: subBgColor,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: subTextColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          subItem.label,
                          style: AppFonts.bodySmall.copyWith(
                            color: subTextColor,
                            fontWeight: subSelected
                                ? AppFonts.bold
                                : AppFonts.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

        // ── Subtle section divider between groups ─────────────────────────
        if (widget.isExpandedSidebar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.05),
              height: 1,
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DashboardTopBar
// ══════════════════════════════════════════════════════════════════════════════

class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onMenuPressed;
  final UserModel? currentUser;

  const DashboardTopBar({
    super.key,
    required this.title,
    this.actions,
    this.onMenuPressed,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      title: Text(
        title,
        style: AppFonts.headlineMedium.copyWith(fontWeight: AppFonts.bold),
      ),
      actions: [
        if (actions != null) ...actions!,
        if (currentUser != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Tooltip(
                message: '${currentUser!.name} (${currentUser!.role})',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                      child: Text(
                        currentUser!.name.characters.first.toUpperCase(),
                        style: AppFonts.labelMedium.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: AppFonts.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser!.name,
                          style: AppFonts.labelMedium.copyWith(
                            fontWeight: AppFonts.semiBold,
                          ),
                        ),
                        Text(
                          currentUser!.role.toUpperCase(),
                          style: AppFonts.labelSmall.copyWith(
                            color: AppColors.mediumGray,
                            fontSize: 9,
                          ),
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

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  BreadcrumbItem({required this.label, this.onTap});
}

class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem>? items;

  const Breadcrumb({super.key, this.items});

  @override
  Widget build(BuildContext context) {
    if (items == null || items!.isEmpty) {
      return const Breadcrumbs();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(items!.length, (index) {
            final item = items![index];
            final isLast = index == items!.length - 1;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.onTap != null)
                  InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        item.label,
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: AppFonts.medium,
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      item.label,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.charcoal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (!isLast)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.mediumGray,
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
