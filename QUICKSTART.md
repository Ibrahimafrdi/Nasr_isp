# NASR ISP Management System - Quick Start Guide

## 🚀 Getting Started in 5 Minutes

### Step 1: Get Dependencies
```bash
flutter pub get
```

### Step 2: Run the Application
```bash
flutter run -d chrome
```

Or specify a different device:
```bash
flutter run -d web-server
flutter run -d windows
flutter run -d linux
```

### Step 3: Login
Use demo credentials:
- **Admin**: admin@nasr.com / admin123
- **Employee**: employee@nasr.com / emp123

### Step 4: Explore Features
- Go to Dashboard to see metrics
- Check Customers for full management
- View Payments and Expenses
- Explore all menu items in the sidebar

## 📍 Main Pages & Routes

### Authentication
- `/login` - Login page with demo credentials

### Dashboard
- `/dashboard` - Main dashboard with metrics and tables

### Customer Management
- `/customers` - Customer list with search/filter
- `/customers/add` - Add new customer
- `/customers/:id` - Customer details
- `/customers/:id/edit` - Edit customer

### Financial
- `/payments` - Payment tracking
- `/expenses` - Expense management
- `/reports` - Financial reports

### Operations
- `/employees` - Employee management
- `/installations` - Installation tracking

### Configuration
- `/settings` - System settings

## 🎯 Key Features to Try

### 1. Search Customers
- Go to Customers page
- Search by name, phone, or package

### 2. Filter by Status
- Active, Expiring Soon, Expired statuses
- Click filter chips to toggle

### 3. Pagination
- See "Page 1 of 15" at bottom
- Navigate between pages

### 4. View Metrics
- Dashboard shows real-time stats
- Click cards to navigate to details

### 5. Responsive Design
- Resize browser window
- See sidebar collapse on small screens
- Tables scroll horizontally

## 🛠️ Development

### Add New Page
1. Create in `lib/features/feature_name/presentation/pages/`
2. Add BLoC to feature bloc folder
3. Add route in `config/router.dart`
4. Register BLoC in `config/service_locator.dart`

### Modify Theme
- Edit `lib/core/theme/app_theme.dart`
- Change colors in `AppTheme` class
- Update spacing constants in `app_constants.dart`

### Add Menu Item
- Edit `DashboardSidebar` widget
- Update `_getMenuItems()` method with new route

### Work with BLoCs
- Events trigger state changes
- States are immutable
- Equatable handles equality
- Emit new state for UI updates

## 📊 Mock Data

All BLoCs have realistic mock data:
- 150 customers across 3 statuses
- 80 payment records with various statuses
- 100 expenses across 7 categories
- Dashboard metrics reflecting real data

### Accessing Mock Data in BLoC
```dart
List<CustomerModel> _generateAllMockCustomers() {
  // Generation logic
  return List.generate(...);
}
```

## 🔍 Debugging

### View BLoC States
```dart
// Add BLoC Observer to main.dart
Bloc.observer = SimpleBlocObserver();
```

### Check Console
- Open DevTools: F12
- Check console tab for errors
- Network tab for API calls (when integrated)

### Hot Reload
- Press 'R' to hot reload
- Press 'R' again for full rebuild
- State may reset on rebuild

## 📱 Responsive Behavior

### Desktop (1025px+)
- Full sidebar visible
- All features accessible
- Tables display fully

### Tablet (451-1024px)
- Sidebar may collapse
- Tables scroll horizontally
- Buttons stack on small widths

### Mobile (0-450px)
- Sidebar hidden by default
- Menu button to show sidebar
- Tables in horizontal scroll

## 🎨 Customization Quick Tips

### Change Primary Color
```dart
// app_theme.dart
static const Color primaryColor = Color(0xFF1565C0); // Change this
```

### Modify Spacing
```dart
// app_constants.dart
static const double paddingLarge = 24; // Change this
```

### Add New Role
```dart
// app_constants.dart
enum UserRole {
  admin,
  employee,
  technician, // Add new role
}
```

### Change Sidebar Width
```dart
// app_constants.dart
static const double sidebarWidthExpanded = 280;
static const double sidebarWidthCollapsed = 80;
```

## 🔗 Navigation Examples

### Navigate to Dashboard
```dart
context.go(RoutePaths.dashboard);
```

### Navigate with Parameters
```dart
context.go('/customers/${customer.id}');
```

### Navigate with Replacement
```dart
context.replace(RoutePaths.login);
```

## 💾 Data Flow

```
Page → BLoC → State → rebuild → UI
  ↑                                ↓
  ←←← Event triggered by user ←←←←
```

## 📚 Important Files

| File | Purpose |
|------|---------|
| main.dart | App entry point & providers |
| config/router.dart | Navigation routes |
| config/service_locator.dart | Dependency injection |
| core/theme/app_theme.dart | Design theme |
| core/constants/app_constants.dart | App-wide constants |
| shared/widgets/shared_widgets.dart | Reusable components |
| shared/models/models.dart | Data models |

## 🚨 Common Issues

### "Package not found"
```bash
flutter pub get
flutter pub upgrade
```

### Hot reload not working
- Press Shift+R for full rebuild
- Close and reopen app

### Sidebar not collapsing
- The sidebar is hidden below 1024px wide; `AppShell` swaps it for an `AppBar` + `Drawer`
- Check `Responsive.deviceTypeForWidth` in `lib/shared/utils/responsive.dart`

### Navigation issues
- Check route path spelling
- Verify route registered in router.dart
- Check BLoC provider in material.dart

## 📖 Resources

- Flutter Docs: https://flutter.dev/docs
- BLoC Library: https://bloclibrary.dev
- go_router: https://github.com/google/app-frameworks/tree/main/packages/go_router_builder
- Material 3: https://m3.material.io

## ✅ Functionality Checklist

- [x] Authentication system
- [x] Dashboard with metrics
- [x] Customer management
- [x] Payment tracking
- [x] Expense tracking
- [x] Search functionality
- [x] Filtering system
- [x] Pagination
- [x] Role-based UI
- [x] Responsive design
- [x] Status indicators
- [x] Empty states
- [x] Loading states
- [x] Form fields
- [x] Navigation system

## 🎉 You're Ready!

The application is fully functional as a frontend foundation. Time to:
1. Connect to backend API
2. Implement real authentication
3. Add charts and analytics
4. Integrate payment processing
5. Setup real-time updates

Happy coding! 🚀
