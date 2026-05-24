import 'package:flutter/material.dart';
// SidebarItem was previously in premium_sidebar.dart; define locally now

class SidebarItem {
  final IconData icon;
  final String label;
  final String routePath;
  final bool requiresAdmin;

  const SidebarItem({
    required this.icon,
    required this.label,
    required this.routePath,
    this.requiresAdmin = false,
  });
}

class NavigationConstants {
  // Admin Sidebar Items
  static final List<SidebarItem> adminSidebarItems = [
    SidebarItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      routePath: '/dashboard',
    ),
    SidebarItem(
      icon: Icons.people,
      label: 'Customers',
      routePath: '/customers',
    ),
    SidebarItem(icon: Icons.payment, label: 'Payments', routePath: '/payments'),
    SidebarItem(
      icon: Icons.receipt,
      label: 'Expenses',
      routePath: '/expenses',
      requiresAdmin: true,
    ),
    SidebarItem(
      icon: Icons.router,
      label: 'Installations',
      routePath: '/installations',
    ),
    SidebarItem(
      icon: Icons.inventory,
      label: 'Inventory',
      routePath: '/inventory',
    ),
    SidebarItem(
      icon: Icons.warning_amber,
      label: 'Network Issues',
      routePath: '/khataa',
    ),
    SidebarItem(
      icon: Icons.person,
      label: 'Employees',
      routePath: '/employees',
      requiresAdmin: true,
    ),
    SidebarItem(
      icon: Icons.file_present,
      label: 'Reports',
      routePath: '/reports',
      requiresAdmin: true,
    ),
    SidebarItem(
      icon: Icons.settings,
      label: 'Settings',
      routePath: '/settings',
    ),
  ];

  // Employee Sidebar Items
  static final List<SidebarItem> employeeSidebarItems = [
    SidebarItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      routePath: '/dashboard',
    ),
    SidebarItem(
      icon: Icons.people,
      label: 'My Customers',
      routePath: '/customers',
    ),
    SidebarItem(
      icon: Icons.router,
      label: 'Network Status',
      routePath: '/installations',
    ),
    SidebarItem(
      icon: Icons.warning_amber,
      label: 'Service Alerts',
      routePath: '/khataa',
    ),
    SidebarItem(
      icon: Icons.settings,
      label: 'Settings',
      routePath: '/settings',
    ),
  ];
}
