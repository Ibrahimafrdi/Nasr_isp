import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_fonts.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'breadcrumbs.dart';

// Sidebar palette. Private to this file; the teal matches every redesigned
// page so the chrome and the content finally agree.
const Color _kInk = Color(0xFF14213D);
const Color _kMuted = Color(0xFF5B6472);
const Color _kFaint = Color(0xFF8A93A1);
const Color _kBorder = Color(0xFFE3E6EB);

// Dark sidebar palette (flat navy, teal accent).
const Color _kSbBg = Color(0xFF101827);
const Color _kSbLine = Color(0xFF1C2A40);
const Color _kSbHover = Color(0xFF162236);
const Color _kSbText = Color(0xFFB7C0CE);
const Color _kSbIcon = Color(0xFF8793A6);
const Color _kSbLabel = Color(0xFF6B7A90);
const Color _kSbAccent = Color(0xFF2DD4BF);

class SidebarItem {
  final IconData icon;
  final String label;
  final String route;

  const SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class SidebarSection {
  final String label;
  final List<SidebarItem> items;

  const SidebarSection({required this.label, required this.items});
}

/// Flat, always-visible navigation: every page is one click away, grouped
/// under small section labels. No collapsible groups to open first.
class DashboardSidebar extends StatefulWidget {
  final UserModel currentUser;
  final String currentRoute;
  final VoidCallback? onLogout;

  /// When true, sidebar is always rendered in icon-only (collapsed) mode.
  final bool forceCollapsed;

  /// Hide the collapse / expand control (used inside the mobile drawer).
  final bool showCollapseToggle;

  const DashboardSidebar({
    super.key,
    required this.currentUser,
    required this.currentRoute,
    this.onLogout,
    this.forceCollapsed = false,
    this.showCollapseToggle = true,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  bool _localExpanded = true;

  bool get _expanded => widget.forceCollapsed ? false : _localExpanded;

  List<SidebarSection> _sections() {
    final isAdmin = widget.currentUser.isAdmin;
    return [
      const SidebarSection(
        label: 'Overview',
        items: [
          SidebarItem(
            icon: Icons.space_dashboard_outlined,
            label: 'Dashboard',
            route: RoutePaths.dashboard,
          ),
        ],
      ),
      SidebarSection(
        label: 'Operations',
        items: [
          const SidebarItem(
            icon: Icons.people_alt_outlined,
            label: 'Customers',
            route: RoutePaths.customers,
          ),
          const SidebarItem(
            icon: Icons.construction_outlined,
            label: 'Installations',
            route: RoutePaths.installations,
          ),
          const SidebarItem(
            icon: Icons.support_agent_rounded,
            label: 'Complaints',
            route: RoutePaths.complaints,
          ),
          const SidebarItem(
            icon: Icons.speed_outlined,
            label: 'Packages',
            route: RoutePaths.packages,
          ),
          if (isAdmin)
            const SidebarItem(
              icon: Icons.inventory_2_outlined,
              label: 'Inventory',
              route: RoutePaths.inventory,
            ),
          if (isAdmin)
            const SidebarItem(
              icon: Icons.local_shipping_outlined,
              label: 'Suppliers',
              route: RoutePaths.suppliers,
            ),
        ],
      ),
      SidebarSection(
        label: 'Finance',
        items: [
          const SidebarItem(
            icon: Icons.payments_outlined,
            label: 'Payments',
            route: RoutePaths.payments,
          ),
          if (isAdmin)
            const SidebarItem(
              icon: Icons.receipt_long_outlined,
              label: 'Expenses',
              route: RoutePaths.expenses,
            ),
          if (isAdmin)
            const SidebarItem(
              icon: Icons.insights_outlined,
              label: 'Reports',
              route: RoutePaths.reports,
            ),
        ],
      ),
      if (isAdmin)
        const SidebarSection(
          label: 'Admin',
          items: [
            SidebarItem(
              icon: Icons.badge_outlined,
              label: 'Employees',
              route: RoutePaths.employees,
            ),
            SidebarItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              route: RoutePaths.settings,
            ),
          ],
        ),
    ];
  }

  bool _isActive(SidebarItem item) {
    final r = widget.currentRoute;
    return r == item.route || r.startsWith('${item.route}/');
  }

  void _go(String route) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.pop(context);
    }
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: _expanded ? 248 : 76,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: _kSbBg),
      // `wide` follows the animated width, so labels never overflow
      // mid-animation.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 180;
          return Column(
            children: [
              _buildHeader(wide),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  children: [
                    for (var s = 0; s < sections.length; s++) ...[
                      _SectionLabel(
                        label: sections[s].label,
                        wide: wide,
                        first: s == 0,
                      ),
                      for (final item in sections[s].items)
                        _NavTile(
                          item: item,
                          active: _isActive(item),
                          wide: wide,
                          onTap: () => _go(item.route),
                        ),
                    ],
                  ],
                ),
              ),
              _buildFooter(wide),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool wide) {
    final canToggle = widget.showCollapseToggle && !widget.forceCollapsed;

    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/logo.jpg',
        width: 36,
        height: 36,
        fit: BoxFit.cover,
      ),
    );

    return Container(
      height: 68,
      padding: EdgeInsets.symmetric(horizontal: wide ? 16 : 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kSbLine)),
      ),
      child: wide
          ? Row(
              children: [
                logo,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        const TextSpan(
                          text: 'NASR',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                          children: [
                            TextSpan(
                              text: ' ISP',
                              style: TextStyle(color: _kSbAccent),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Connecting Better',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: _kSbLabel),
                      ),
                    ],
                  ),
                ),
                if (canToggle)
                  IconButton(
                    tooltip: 'Collapse sidebar',
                    icon: const Icon(
                      Icons.keyboard_double_arrow_left,
                      size: 20,
                      color: _kSbIcon,
                    ),
                    onPressed: () => setState(() => _localExpanded = false),
                  ),
              ],
            )
          : Center(
              child: canToggle
                  ? Tooltip(
                      message: 'Expand sidebar',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => _localExpanded = true),
                        child: logo,
                      ),
                    )
                  : logo,
            ),
    );
  }

  Widget _buildFooter(bool wide) {
    final user = widget.currentUser;
    final name = user.name.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final roleLabel = user.isAdmin ? 'Administrator' : 'Employee';

    final avatar = CircleAvatar(
      radius: 17,
      backgroundColor: _kSbLine,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _kSbAccent,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kSbLine)),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Account',
        onSelected: (value) {
          if (value == 'logout') widget.onLogout?.call();
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Account' : name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 18, color: Color(0xFFB42318)),
                SizedBox(width: 10),
                Text('Sign out', style: TextStyle(color: Color(0xFFB42318))),
              ],
            ),
          ),
        ],
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: wide ? 8 : 0, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _kSbHover,
          ),
          child: wide
              ? Row(
                  children: [
                    avatar,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Account' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            roleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kSbLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.unfold_more, size: 18, color: _kSbLabel),
                  ],
                )
              : Center(child: avatar),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool wide;
  final bool first;

  const _SectionLabel({
    required this.label,
    required this.wide,
    required this.first,
  });

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      // Icon-only rail: a thin divider stands in for the label.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: first
            ? const SizedBox(height: 4)
            : const Divider(height: 1, color: _kSbLine),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(12, first ? 12 : 20, 12, 6),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: _kSbLabel,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final SidebarItem item;
  final bool active;
  final bool wide;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.active,
    required this.wide,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: active ? _kSbLine : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            hoverColor: active ? Colors.transparent : _kSbHover,
            onTap: onTap,
            child: Container(
              height: 42,
              padding: EdgeInsets.symmetric(horizontal: wide ? 12 : 0),
              child: Row(
                mainAxisAlignment: wide
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: active ? _kSbAccent : _kSbIcon,
                  ),
                  if (wide) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: active ? Colors.white : _kSbText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (active)
          Positioned(
            left: -12,
            top: 9,
            bottom: 9,
            width: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _kSbAccent,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(3),
                ),
              ),
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: wide ? tile : Tooltip(message: item.label, child: tile),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DashboardTopBar — slim context bar: "Section / Page"
// ══════════════════════════════════════════════════════════════════════════════

class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// Group the page belongs to, shown before the title ("Operations / ...").
  final String? section;
  final List<Widget>? actions;
  final VoidCallback? onMenuPressed;
  final UserModel? currentUser;

  const DashboardTopBar({
    super.key,
    required this.title,
    this.section,
    this.actions,
    this.onMenuPressed,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 56,
      backgroundColor: Colors.white,
      foregroundColor: _kInk,
      shape: const Border(bottom: BorderSide(color: _kBorder)),
      titleSpacing: isMobile ? null : 24,
      title: Text.rich(
        TextSpan(
          children: [
            if (section != null && !isMobile)
              TextSpan(
                text: '$section  /  ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _kFaint,
                ),
              ),
            TextSpan(
              text: title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [if (actions != null) ...actions!, const SizedBox(width: 8)],
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
