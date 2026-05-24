# NASR ISP Management System - Frontend Architecture

A professional, enterprise-grade ISP (Internet Service Provider) Management & Financial Intelligence System built with Flutter Web. This frontend is designed for desktop-first operations management with a clean, productive UI optimized for business operations.

## 🎯 Project Overview

This is a **frontend-only foundation** for a comprehensive ISP management system that handles:

- **Customer Management**: Track ISP subscribers, packages, and expiry dates
- **Billing & Payments**: Payment tracking, collection status, and financial monitoring
- **Financial Intelligence**: Revenue, expense tracking, profit analysis
- **Operational Dashboards**: Real-time metrics, customer status monitoring
- **Employee Management**: Staff assignments, roles, and access control
- **Installation Tracking**: Profitability analysis for new installations

## 🏗️ Architecture Overview

### Clean Architecture with Feature-First Organization

```
lib/
├── main.dart                          # App entry point
├── config/
│   ├── router.dart                    # go_router navigation setup
│   └── service_locator.dart           # get_it dependency injection
├── core/
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 theming
│   ├── constants/
│   │   └── app_constants.dart         # App-wide constants
│   └── utils/
│       └── utils.dart                 # Utility functions
├── shared/
│   ├── models/
│   │   └── models.dart                # Shared data models
│   └── widgets/
│       ├── shared_widgets.dart        # Reusable UI components
│       └── layout_widgets.dart        # Layout shells (Sidebar, TopBar)
└── features/
    ├── auth/
    │   └── presentation/
    │       ├── pages/
    │       │   └── login_page.dart
    │       ├── widgets/
    │       └── bloc/
    │           └── auth_bloc.dart
    ├── dashboard/
    │   └── presentation/
    ├── customers/
    │   └── presentation/
    ├── payments/
    │   └── presentation/
    ├── expenses/
    │   └── presentation/
    ├── reports/
    │   └── presentation/
    ├── employees/
    │   └── presentation/
    ├── installations/
    │   └── presentation/
    └── settings/
        └── presentation/
```

### Key Architectural Principles

1. **Feature-First Organization**: Each feature is self-contained with its own presentation layer
2. **BLoC Pattern**: State management via `flutter_bloc` for scalability
3. **Separation of Concerns**: Clear separation between UI, business logic, and data
4. **Reusability**: Common components in `shared/widgets/` and `shared/models/`
5. **Responsive Design**: Primary desktop focus with secondary mobile support via `responsive_framework`
6. **Type Safety**: Equatable models for proper equality checks

## 🔐 Authentication

### Demo Credentials

The app comes with mock authentication for testing:

```
Admin Account:
  Email: admin@nasr.com
  Password: admin123

Employee Account:
  Email: employee@nasr.com
  Password: emp123
```

### Role-Based Access Control

- **Admin**: Full access to all features including financial reports, employee management
- **Employee**: Limited access to customer data and assigned operational tasks only

## 📊 Features Overview

### 1. Dashboard
- Key metrics cards (Total Customers, Active, Expiring, Expired)
- Financial overview (Revenue, Expenses, Profit, Pending Payments)
- Recent transactions table
- Expiring customers list

### 2. Customer Management
- Full customer listing with pagination
- Search by name, phone, or package
- Filter by status (Active, Expiring Soon, Expired, Inactive)
- Customer details view
- Add/Edit customer functionality
- Balance tracking

### 3. Payment Management
- Payment history with detailed tracking
- Collection summary cards
- Partial payment indicators
- Status badges (Pending, Completed, Failed, Partial)
- Payment method tracking

### 4. Expense Tracking
- Expense categorization (Rent, Electricity, Fuel, Upstream Internet, Salaries, Repairs, Equipment)
- Monthly expense summaries
- Total expense analytics
- Expense records with dates and notes

### 5. Reports (Placeholder)
- Revenue overview
- Expense breakdown
- Customer statistics
- Financial analytics

### 6. Employee Management (Placeholder)
- Team listings
- Staff assignments
- Role-based access

### 7. Installation Tracking (Placeholder)
- Device and installation costs
- Profitability analysis
- Cost breakdown (Cable, Router, Labor, Other)

### 8. Settings (Placeholder)
- System configuration
- User preferences
- App settings

## 🎨 UI/UX Design System

### Theme Features
- **Material 3 Design**: Modern, clean design language
- **Professional Palette**: 
  - Primary: #1565C0 (Blue)
  - Secondary: #00897B (Teal)
  - Success: #4CAF50 (Green)
  - Warning: #FFC107 (Yellow)
  - Error: #E53935 (Red)

### Reusable Components
- `StatusBadge`: Customer and payment status indicators
- `DashboardCard`: Metric display cards
- `DataTableWrapper`: Responsive data tables
- `SearchBar`: Integrated search functionality
- `FilterChips`: Status and category filtering
- `PaginationBar`: Page navigation
- `EmptyStateWidget`: Empty state displays
- `LoadingWidget`: Loading indicators
- `ConfirmationDialog`: Confirmation dialogs
- `FormField`: Form input fields

### Layout Components
- `DashboardSidebar`: Collapsible navigation sidebar
- `DashboardTopBar`: Application header with user info
- `Breadcrumb`: Navigation breadcrumbs

## 🚀 Tech Stack

| Technology | Purpose |
|-----------|---------|
| **Flutter Web** | Cross-platform web application |
| **Material 3** | Modern UI design system |
| **flutter_bloc** | State management |
| **go_router** | Navigation and routing |
| **get_it** | Dependency injection |
| **responsive_framework** | Responsive design |
| **Google Fonts** | Typography |
| **intl** | Internationalization & formatting |
| **equatable** | Value equality and hashing |
| **uuid** | Unique identifier generation |

## 🔄 State Management with BLoC

Each feature has a dedicated BLoC for state management:

```dart
// Example: CustomerBloc
class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  CustomersBloc() : super(const CustomersInitial()) {
    on<LoadCustomersEvent>(_onLoadCustomers);
    on<SearchCustomersEvent>(_onSearchCustomers);
    on<FilterCustomersEvent>(_onFilterCustomers);
  }
}
```

**BLoCs Implemented:**
- `AuthBloc`: Authentication and user session
- `DashboardBloc`: Dashboard metrics and data
- `CustomersBloc`: Customer management
- `PaymentsBloc`: Payment tracking
- `ExpensesBloc`: Expense management
- `ReportsBloc`: Financial reports
- `EmployeesBloc`: Employee management
- `InstallationsBloc`: Installation tracking
- `SettingsBloc`: App settings

## 🗂️ Data Models

Mock data models are included for all features:

- `UserModel`: User and employee data
- `CustomerModel`: Customer information with subscription status
- `PaymentModel`: Payment records and status
- `ExpenseModel`: Expense tracking
- `EmployeeModel`: Employee profiles
- `InstallationModel`: Installation records with costs
- `PackageModel`: ISP subscription packages
- `DashboardStatsModel`: Dashboard metrics

### Mock Data Generation
All BLoCs include mock data generation functions that create realistic test data:

```dart
List<CustomerModel> _generateAllMockCustomers()
List<PaymentModel> _generateMockPayments()
List<ExpenseModel> _generateMockExpenses()
```

## 📱 Navigation Structure

Using **go_router** for type-safe, declarative routing:

```
/login                          # Login page
/dashboard                      # Main dashboard
/customers                      # Customers list
/customers/add                  # Add new customer
/customers/:id                  # Customer details
/customers/:id/edit            # Edit customer
/payments                       # Payments page
/expenses                       # Expenses page
/reports                        # Reports page
/employees                      # Employees page
/installations                  # Installations page
/settings                       # Settings page
```

## 🎯 Responsive Design

- **Mobile (0-450px)**: Optimized mobile layout
- **Tablet (451-1024px)**: Tablet optimization
- **Desktop (1025-1440px)**: Full desktop experience
- **4K (1441px+)**: Ultra-wide display support

**Primary Focus**: Desktop and Laptop layouts with responsive secondary support.

## 🔧 Dependencies

```yaml
dependencies:
  flutter: ^3.11.3
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2
  go_router: ^13.1.0
  get_it: ^7.6.0
  responsive_framework: ^0.9.0
  equatable: ^2.0.5
  intl: ^0.19.0
  uuid: ^4.0.0
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.0
  fl_chart: ^0.68.0
```

## 🚀 Getting Started

### Prerequisites
- Flutter 3.11+ with Web support
- Dart 3.1+

### Installation

1. **Clone the repository**
```bash
cd nasr_isp
```

2. **Get dependencies**
```bash
flutter pub get
```

3. **Run the application**
```bash
flutter run -d chrome
```

Or for a specific build:
```bash
flutter run -d web-server
```

### Building for Production

```bash
flutter build web --release
```

## 📈 Frontend Development Roadmap

### Phase 1: ✅ Foundation (Completed)
- ✅ Responsive admin UI layout
- ✅ Material 3 theme system
- ✅ BLoC state management structure
- ✅ Navigation routing
- ✅ Reusable component system
- ✅ Mock data models
- ✅ Basic pages for all features

### Phase 2: In Progress
- Dashboard charts and analytics visualization
- Form validations and submissions
- Advanced table features (sorting, column selection)
- Customer detail views with transaction history
- Payment form with partial payment support

### Phase 3: Planned
- Real-time data updates
- Export to PDF/Excel
- Advanced filtering and search
- Custom report generation
- User preferences and customization
- Dark mode support

## 🔌 Backend Integration Points

This frontend is designed to integrate with a backend API. The BLoCs currently use mock data but are structured to easily accept real data:

```dart
// Example integration point in BLoC:
// Replace _generateMockPayments() with API call
final payments = await paymentRepository.getPayments();
```

**Recommended Backend Structure:**
- REST API with proper authentication
- Role-based access control (RBAC)
- WebSocket support for real-time updates
- Secure token-based authentication

## 📝 Code Conventions

### Naming
- Files: `snake_case` (e.g., `login_page.dart`)
- Classes: `PascalCase` (e.g., `LoginPage`)
- Variables/Functions: `camelCase` (e.g., `getUser()`)

### File Organization
- One main class per file
- Related widgets in dedicated files
- Constants in `constants.dart`
- Utilities in `utils.dart`

### BLoC Pattern
- Events: `*Event` suffix
- States: `*State` suffix
- BLoC: `*Bloc` suffix

## 🛠️ Development Tips

### Adding a New Feature

1. Create feature folder: `lib/features/feature_name/`
2. Create BLoC: `lib/features/feature_name/presentation/bloc/feature_bloc.dart`
3. Create pages: `lib/features/feature_name/presentation/pages/feature_page.dart`
4. Register BLoC in `service_locator.dart`
5. Add route in `router.dart`

### Debugging
- Enable debug mode: `flutter run -d chrome`
- Use Flutter DevTools: `flutter pub global run devtools`
- Check BLoC states with BLoC Observer

## 📞 Support

For questions or issues:
1. Check the Flutter documentation: https://flutter.dev
2. Review BLoC patterns: https://bloclibrary.dev
3. Check go_router docs: https://pub.dev/packages/go_router

## 📄 License

This project is proprietary software for NASR ISP business operations.

---

**Status**: Frontend Foundation Complete ✨

This is a professional, production-quality frontend framework ready for backend integration and feature expansion.
