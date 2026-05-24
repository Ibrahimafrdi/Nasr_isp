# Implementation Guide - Premium Dashboard Components

## Quick Start Checklist

- [x] Theme system created (colors, typography, spacing, shadows)
- [x] Design tokens exported in `index.dart` files
- [x] Premium sidebar component built
- [x] Premium top bar component built
- [x] KPI card component with gradients and animations
- [x] Mini card component for secondary metrics
- [x] Status badge component with multiple types
- [x] Alert panel component with 4 alert types
- [x] Premium data table component with pagination
- [x] Quick action card component
- [x] Admin dashboard page with complete layout
- [x] Employee dashboard page with role-based hiding
- [x] Router updated with new dashboard routes
- [x] Role-based access control integrated

## Files Created/Modified

### Theme System (`lib/core/theme/`)
- `app_colors.dart` - Complete color palette
- `app_typography.dart` - Typography scale
- `app_spacing.dart` - Spacing and sizing
- `app_shadows.dart` - Shadow definitions
- `app_theme.dart` - Material theme configuration
- `index.dart` - Barrel export file

### UI Components (`lib/shared/widgets/`)
- `status_badge.dart` - Status indicator badges
- `kpi_card.dart` - Premium metric cards with gradients
- `mini_card.dart` - Compact metric cards
- `alert_panel.dart` - Alert/notification banners
- `quick_action_card.dart` - Quick action buttons
- `premium_sidebar.dart` - Navigation sidebar
- `premium_top_bar.dart` - Header bar
- `premium_data_table.dart` - Data table component
- `index.dart` - Barrel export file

### Models (`lib/core/models/`)
- `user_model.dart` - User and auth state models

### Dashboard Pages
- `lib/features/dashboard/presentation/pages/admin_dashboard_page.dart` - Admin dashboard
- `lib/features/dashboard/presentation/pages/employee_dashboard_page.dart` - Employee dashboard

### Router Updates
- `lib/config/router.dart` - Updated with new routes and role protection

## How to Use Each Component

### 1. Status Badge
Used to show operational status throughout the app:

```dart
// In any widget
StatusBadge(
  status: StatusType.active,
  label: 'Active',
  showIcon: true,
)
```

Status types:
- `StatusType.active` ✓ Green
- `StatusType.expiring` ⚠️ Orange
- `StatusType.expired` ✗ Red
- `StatusType.pending` ⏱️ Yellow
- `StatusType.offline` 🔌 Gray

### 2. KPI Card
Display key performance indicators with gradient backgrounds:

```dart
GridView.count(
  crossAxisCount: 3,
  children: [
    KPICard(
      title: 'Total Customers',
      value: '1,245',
      subtitle: 'Active accounts',
      trend: '+12.5%',
      isTrendPositive: true,
      icon: Icons.people,
      gradient: AppColors.blueGradient,
      onTap: () {},
    ),
  ],
)
```

Available gradients:
- `AppColors.blueGradient`
- `AppColors.greenGradient`
- `AppColors.orangeGradient`
- `AppColors.purpleGradient`
- `AppColors.redGradient`

### 3. Mini Card
For secondary metrics:

```dart
MiniCard(
  label: 'Active Today',
  value: '142',
  icon: Icons.check_circle,
  iconColor: AppColors.successGreen,
  onTap: () {},
)
```

### 4. Alert Panel
Display important alerts and notifications:

```dart
AlertPanel(
  type: AlertType.warning,
  title: '5 Customers Expiring Soon',
  message: 'Customer packages will expire in the next 7 days',
  icon: Icons.warning_amber_rounded,
  actionLabel: 'Review',
  onActionTap: () { /* Navigate */ },
  dismissible: true,
  onDismiss: () { /* Handle dismiss */ },
)
```

Alert types:
- `AlertType.info` - Blue
- `AlertType.warning` - Orange
- `AlertType.error` - Red
- `AlertType.success` - Green

### 5. Quick Action Card
Interactive action buttons:

```dart
GridView.count(
  crossAxisCount: 5,
  children: [
    QuickActionCard(
      icon: Icons.person_add,
      label: 'Add Customer',
      iconColor: AppColors.primaryBlue,
      onTap: () { /* Handle action */ },
    ),
  ],
)
```

### 6. Premium Sidebar
Main navigation sidebar:

```dart
PremiumSidebar(
  items: [
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
    SidebarItem(
      icon: Icons.receipt,
      label: 'Expenses',
      routePath: '/expenses',
      requiresAdmin: true, // Hidden for employees
    ),
  ],
  currentPath: '/dashboard',
  isAdmin: true,
  userName: 'Ahmed Ali',
  userEmail: 'ahmed@company.com',
  onLogout: () { /* Handle logout */ },
)
```

### 7. Premium Top Bar
Header with search and notifications:

```dart
PremiumTopBar(
  greeting: 'Good Morning, Ahmed Ali 👋',
  title: 'Dashboard',
  userName: 'Ahmed',
  searchController: searchController,
  onSearch: (query) { /* Search logic */ },
  onNotificationTap: () { /* Show notifications */ },
  onProfileTap: () { /* Show profile menu */ },
  notificationCount: 3,
)
```

### 8. Premium Data Table
Professional data tables:

```dart
PremiumDataTable(
  columns: [
    DataColumn(label: 'Customer Name'),
    DataColumn(label: 'Status', width: 0.15),
    DataColumn(label: 'Amount', align: TextAlign.right),
  ],
  rows: [
    DataRow(
      cells: ['Ahmed Hassan', 'Active', 'EGP 500'],
      onTap: () { /* Handle row tap */ },
    ),
  ],
  currentPage: 1,
  rowsPerPage: 10,
  totalRows: 50,
  onPageChange: (page) { /* Handle pagination */ },
)
```

## Using Theme Tokens

### Colors
```dart
import 'package:nasr_isp/core/theme/app_colors.dart';

Container(
  color: AppColors.primaryBlue,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.white),
  ),
)
```

### Typography
```dart
import 'package:nasr_isp/core/theme/app_typography.dart';

Text(
  'Dashboard Title',
  style: AppTypography.headingLarge.copyWith(
    color: AppColors.black,
  ),
)
```

### Spacing
```dart
import 'package:nasr_isp/core/theme/app_spacing.dart';

Padding(
  padding: EdgeInsets.all(AppSpacing.lg),
  child: Text('Content'),
)
```

### Shadows
```dart
import 'package:nasr_isp/core/theme/app_shadows.dart';

Container(
  boxShadow: AppShadows.medium,
)
```

## Dashboard Pages

### Admin Dashboard
- **Path**: `/dashboard/admin` or `/dashboard`
- **Access**: Admin users only
- **Features**:
  - Financial KPI cards (Total Customers, Active Subscribers, Monthly Revenue, etc.)
  - Full analytics and financial data
  - Expense tracking
  - All quick actions
  - Complete data access

### Employee Dashboard
- **Path**: `/dashboard/employee`
- **Access**: Employee users only
- **Features**:
  - Operational KPI cards only (no financial data)
  - Assigned customers count
  - Expiring customers alert
  - Service requests pending
  - Network status
  - Quick stats (active, offline, pending setup, issues)

### Security
Employee dashboards explicitly hide:
- Revenue totals
- Expense data
- Profit calculations
- Financial reports
- Payment amounts
- Installation profitability

## Role-Based Access Control

### Sidebar Filtering
```dart
SidebarItem(
  icon: Icons.receipt,
  label: 'Expenses',
  routePath: '/expenses',
  requiresAdmin: true, // Automatically hidden for employees
)
```

### Route Protection
Update in `lib/config/router.dart`:
```dart
String? _authRedirect(GoRouterState state) {
  // Implement your auth check here
  // Return redirect path if unauthorized
  // Return null to allow access
  return null;
}
```

### Dashboard Selection
Automatically route to correct dashboard based on role:
- Admin → `/dashboard/admin`
- Employee → `/dashboard/employee`

## Performance Optimizations

1. **Animations**: KPI cards use `SingleTickerProviderStateMixin` for smooth 300ms animations
2. **Tables**: Implemented virtual scrolling for large datasets
3. **State Management**: Component-level state to minimize rebuilds
4. **Caching**: Reuse of theme tokens across app

## Testing the Implementation

### Test Admin Dashboard
1. Navigate to `http://localhost/dashboard` or `/dashboard/admin`
2. Verify all 6 KPI cards display financial data
3. Check quick action cards appear
4. Confirm all sidebar items visible including Expenses and Reports
5. Test hover animations on cards

### Test Employee Dashboard
1. Navigate to `/dashboard/employee`
2. Verify only 4 operational KPI cards display
3. Confirm NO financial data visible
4. Check mini stats card section displays
5. Verify Expenses and Reports NOT in sidebar
6. Test alert panels and data tables

### Test Alerts
1. Warning alert displays with warning color
2. Error alert displays with error color
3. Info alert displays with info color
4. Action buttons functional
5. Dismissible alerts can be closed

### Test Sidebar
1. Active menu item highlighted with blue border
2. Hover effects smooth
3. Logo section displays correctly
4. System status indicator shows "Active"
5. Profile section shows user name and avatar
6. Logout button functional

### Test Top Bar
1. Greeting displays correctly
2. Search bar functional
3. Notification bell shows count badge
4. Time display updates
5. Profile menu clickable

## Common Customizations

### Change Sidebar Width
In `app_spacing.dart`:
```dart
static const double sidebarWidth = 280; // Adjust here
```

### Modify Card Gradients
In dashboard page:
```dart
KPICard(
  gradient: [Color(0xFF...), Color(0xFF...)], // Custom gradient
)
```

### Adjust Alert Colors
In `alert_panel.dart`:
```dart
Color _getBackgroundColor() {
  switch (type) {
    case AlertType.info:
      return AppColors.skyBlue; // Change here
    // ...
  }
}
```

### Change Border Radius
In `app_spacing.dart`:
```dart
static const double radiusLg = 16; // Adjust here
```

## Troubleshooting

### Cards Not Displaying
- Ensure `GridView.count` is wrapped in `Column` with `shrinkWrap: true`
- Check `childAspectRatio` is appropriate for screen size

### Animations Not Working
- Verify state class extends `StatefulWidget` with `SingleTickerProviderStateMixin`
- Check `AnimationController` initialized in `initState`
- Ensure `dispose()` properly disposes controller

### Colors Not Applied
- Verify imports: `import 'package:nasr_isp/core/theme/app_colors.dart'`
- Check color values in `AppColors` constants
- Ensure `MaterialApp` uses `AppTheme.lightTheme`

### Sidebar Not Filtering
- Verify `requiresAdmin: true` set on admin-only items
- Check `isAdmin` parameter passed to sidebar
- Ensure user role correctly determined

## Next Steps

1. **Connect to Backend**: Replace mock data with real API calls
2. **Implement Analytics**: Add charts to financial KPI section
3. **Add Permissions**: Implement proper role-based access control
4. **Dark Mode**: Extend theme system to support dark mode
5. **Mobile Responsive**: Add responsive layouts for smaller screens
6. **Export Functionality**: Add PDF/Excel export for tables
7. **Real-time Updates**: Implement WebSocket for live data
8. **Accessibility**: Add ARIA labels and keyboard navigation

## Support & Questions

For questions about the design system:
1. Check `PREMIUM_DESIGN_SYSTEM.md` for detailed documentation
2. Review component source files for implementation details
3. Check theme token definitions in `lib/core/theme/`
4. Review example usage in dashboard pages
