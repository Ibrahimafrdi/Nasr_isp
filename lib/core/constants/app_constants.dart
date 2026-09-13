/// App constants
class AppConstants {
  // App info
  static const String appName = 'NASR ISP Management';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int itemsPerPage = 10;
  static const int maxCachedPages = 5;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Spacing
  static const double paddingXSmall = 4;
  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;
  static const double paddingXLarge = 32;

  // Border radius
  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 16;

  // Icon sizes
  static const double iconSizeSmall = 16;
  static const double iconSizeMedium = 24;
  static const double iconSizeLarge = 32;
  static const double iconSizeXLarge = 48;

  // Breakpoints intentionally live in `shared/utils/responsive.dart` — the
  // single source of truth. Do not re-declare them here.
}

/// Route paths
class RoutePaths {
  static const String root = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String customers = '/customers';
  static const String customerDetails = '/customers/:id';
  static const String addCustomer = '/customers/add';
  static const String editCustomer = '/customers/:id/edit';
  static const String packages = '/packages';
  static const String payments = '/payments';
  static const String expenses = '/expenses';
  static const String employees = '/employees';
  static const String installations = '/installations';
  static const String settings = '/settings';
  static const String inventory = '/inventory';
  static const String khataa = '/khataa';
  static const String reports = '/reports';
}

/// User roles
enum UserRole {
  admin,
  employee;

  bool get isAdmin => this == UserRole.admin;
  bool get isEmployee => this == UserRole.employee;
}

/// Customer status
enum CustomerStatus {
  active,
  expiringSoon,
  expired,
  inactive;

  String get label {
    switch (this) {
      case CustomerStatus.active:
        return 'Active';
      case CustomerStatus.expiringSoon:
        return 'Expiring Soon';
      case CustomerStatus.expired:
        return 'Expired';
      case CustomerStatus.inactive:
        return 'Inactive';
    }
  }

  String get displayName => label;
}

/// Payment status
enum PaymentStatus {
  pending,
  completed,
  failed,
  partial;

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.partial:
        return 'Partial';
    }
  }
}

/// Expense category
enum ExpenseCategory {
  fuel,
  equipment,
  salary,
  maintenance,
  rent,
  internet,
  electricity,
  other;

  String get label {
    switch (this) {
      case ExpenseCategory.fuel:
        return 'Fuel';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.salary:
        return 'Salary';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.internet:
        return 'Internet';
      case ExpenseCategory.electricity:
        return 'Electricity';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

/// Connection type
enum ConnectionType {
  wireless,
  opticalFibre;

  String get label {
    switch (this) {
      case ConnectionType.wireless:
        return 'Wireless';
      case ConnectionType.opticalFibre:
        return 'Optical Fibre';
    }
  }

  String get displayName => label;
}

/// Inventory category
enum InventoryCategory {
  equipment,
  consumable;

  String get label {
    switch (this) {
      case InventoryCategory.equipment:
        return 'Equipment';
      case InventoryCategory.consumable:
        return 'Consumable';
    }
  }
}

/// Which job type an inventory item's stock is applicable to. Drives the
/// required "Applicable To" field on inventory items, used to filter stock
/// and to auto-select an installation's BOM for its connection type.
/// `both` covers shared consumables (e.g. cable ties).
enum InventoryConnectionType {
  wireless,
  opticalFibre,
  both;

  String get label {
    switch (this) {
      case InventoryConnectionType.wireless:
        return 'Wireless';
      case InventoryConnectionType.opticalFibre:
        return 'Optical Fibre';
      case InventoryConnectionType.both:
        return 'Both';
    }
  }
}

/// Stock movement type
enum StockMovementType {
  stockIn,
  stockOut;

  String get label {
    switch (this) {
      case StockMovementType.stockIn:
        return 'Stock In';
      case StockMovementType.stockOut:
        return 'Stock Out';
    }
  }
}

/// Installation status
enum InstallationStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case InstallationStatus.pending:
        return 'Pending';
      case InstallationStatus.inProgress:
        return 'In Progress';
      case InstallationStatus.completed:
        return 'Completed';
      case InstallationStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get displayName => label;
}

/// Employee status
enum EmployeeStatus {
  active,
  inactive;

  String get label {
    switch (this) {
      case EmployeeStatus.active:
        return 'Active';
      case EmployeeStatus.inactive:
        return 'Inactive';
    }
  }

  String get displayName => label;
}



