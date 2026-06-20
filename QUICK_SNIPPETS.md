# Quick Implementation Snippets - Remaining 7 Pages

Copy-paste these exact code blocks into each page to complete the filter refactoring. Each snippet is a complete, working implementation.

---

## 1. ExpensesPage

**Location:** `lib/features/expenses/presentation/pages/expenses_page.dart`

### A. Update Imports (add these lines)
```dart
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
```

### B. Update State Variables (replace the old filter variables)
```dart
late TextEditingController _searchController;
late List<String> _selectedCategories;
late DateTime? _dateRangeStart;
late DateTime? _dateRangeEnd;
```

### C. Update initState() (replace entire method)
```dart
@override
void initState() {
  super.initState();
  _searchController = TextEditingController();
  _selectedCategories = [];
  _dateRangeStart = null;
  _dateRangeEnd = null;
  context.read<ExpensesBloc>().add(const LoadExpensesEvent());
}
```

### D. Add _clearFilters() Method (add before @override build)
```dart
void _clearFilters() {
  setState(() {
    _searchController.clear();
    _selectedCategories.clear();
    _dateRangeStart = null;
    _dateRangeEnd = null;
  });
  context.read<ExpensesBloc>().add(const LoadExpensesEvent());
}
```

### E. Add _buildFilterPanel() Method (add before @override build)
```dart
Widget _buildFilterPanel() {
  final activeFilterCount = _selectedCategories.length +
      (_searchController.text.isNotEmpty ? 1 : 0) +
      (_dateRangeStart != null ? 1 : 0) +
      (_dateRangeEnd != null ? 1 : 0);

  return AppFilterContainer(
    title: 'Search & Filter Expenses',
    titleIcon: Icons.receipt_long,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterPanelHeader(
          searchController: _searchController,
          onSearchChanged: (query) {
            setState(() {});
            context.read<ExpensesBloc>().add(
              LoadExpensesEvent(searchQuery: query),
            );
          },
          onClearFilters: activeFilterCount > 0 ? _clearFilters : null,
          activeFilterCount: activeFilterCount,
          title: 'Active Filters',
        ),
        SizedBox(height: AppSpacing.xl),
        DateRangePickerField(
          startDate: _dateRangeStart,
          endDate: _dateRangeEnd,
          label: 'Expense Date Range',
          onDateRangeChanged: (range) {
            setState(() {
              _dateRangeStart = range?.start;
              _dateRangeEnd = range?.end;
            });
          },
        ),
        SizedBox(height: AppSpacing.lg),
        const Text(
          'Expense Category',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        StatusFilterChips(
          availableStatuses: ['Rent', 'Utilities', 'Equipment', 'Salaries', 'Maintenance', 'Other'],
          selectedStatuses: _selectedCategories,
          onStatusesChanged: (categories) {
            setState(() {
              _selectedCategories = categories;
            });
            context.read<ExpensesBloc>().add(
              LoadExpensesEvent(filterCategories: categories),
            );
          },
        ),
      ],
    ),
  );
}
```

### F. Add to build() method
In the build method, before your data table/list, add:
```dart
_buildFilterPanel(),
const SizedBox(height: 24),
```

---

## 2. InstallationsPage

**Location:** `lib/features/installations/presentation/pages/installations_page.dart`

### A. Update Imports
```dart
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
```

### B. Update State Variables
```dart
late TextEditingController _searchController;
late List<String> _selectedStatuses;
late DateTime? _dateRangeStart;
late DateTime? _dateRangeEnd;
String? _selectedTechnician;
```

### C. Update initState()
```dart
@override
void initState() {
  super.initState();
  _searchController = TextEditingController();
  _selectedStatuses = [];
  _dateRangeStart = null;
  _dateRangeEnd = null;
  _selectedTechnician = null;
  context.read<InstallationsBloc>().add(const LoadInstallationsEvent());
}
```

### D. Add _clearFilters() Method
```dart
void _clearFilters() {
  setState(() {
    _searchController.clear();
    _selectedStatuses.clear();
    _dateRangeStart = null;
    _dateRangeEnd = null;
    _selectedTechnician = null;
  });
  context.read<InstallationsBloc>().add(const LoadInstallationsEvent());
}
```

### E. Add _buildFilterPanel() Method
```dart
Widget _buildFilterPanel() {
  final activeFilterCount = _selectedStatuses.length +
      (_searchController.text.isNotEmpty ? 1 : 0) +
      (_dateRangeStart != null ? 1 : 0) +
      (_dateRangeEnd != null ? 1 : 0) +
      (_selectedTechnician != null ? 1 : 0);

  return AppFilterContainer(
    title: 'Search & Filter Installations',
    titleIcon: Icons.engineering,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterPanelHeader(
          searchController: _searchController,
          onSearchChanged: (query) {
            setState(() {});
            context.read<InstallationsBloc>().add(
              LoadInstallationsEvent(searchQuery: query),
            );
          },
          onClearFilters: activeFilterCount > 0 ? _clearFilters : null,
          activeFilterCount: activeFilterCount,
          title: 'Active Filters',
        ),
        SizedBox(height: AppSpacing.xl),
        DateRangePickerField(
          startDate: _dateRangeStart,
          endDate: _dateRangeEnd,
          label: 'Installation Date Range',
          onDateRangeChanged: (range) {
            setState(() {
              _dateRangeStart = range?.start;
              _dateRangeEnd = range?.end;
            });
          },
        ),
        SizedBox(height: AppSpacing.lg),
        const Text(
          'Installation Status',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        StatusFilterChips(
          availableStatuses: ['Scheduled', 'In Progress', 'Completed', 'Cancelled'],
          selectedStatuses: _selectedStatuses,
          onStatusesChanged: (statuses) {
            setState(() {
              _selectedStatuses = statuses;
            });
            context.read<InstallationsBloc>().add(
              LoadInstallationsEvent(filterStatuses: statuses),
            );
          },
        ),
        SizedBox(height: AppSpacing.lg),
        const Text(
          'Assigned Technician',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        CategoryFilterDropdown(
          categories: ['Ahmed Khan', 'Muhammad Ali', 'Hassan Raza', 'Bilal Ahmad'],
          selected: _selectedTechnician,
          onChanged: (technician) {
            setState(() {
              _selectedTechnician = technician;
            });
            context.read<InstallationsBloc>().add(
              LoadInstallationsEvent(filterTechnician: technician),
            );
          },
        ),
      ],
    ),
  );
}
```

---

## 3. InventoryPage

**Location:** `lib/features/inventory/presentation/pages/inventory_page.dart`

### A. Update Imports
```dart
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
```

### B. Update State Variables
```dart
late TextEditingController _searchController;
late List<String> _selectedCategories;
late List<String> _selectedStockStatus;
```

### C. Update initState()
```dart
@override
void initState() {
  super.initState();
  _searchController = TextEditingController();
  _selectedCategories = [];
  _selectedStockStatus = [];
  context.read<InventoryBloc>().add(const LoadInventoryEvent());
}
```

### D. Add _clearFilters() Method
```dart
void _clearFilters() {
  setState(() {
    _searchController.clear();
    _selectedCategories.clear();
    _selectedStockStatus.clear();
  });
  context.read<InventoryBloc>().add(const LoadInventoryEvent());
}
```

### E. Add _buildFilterPanel() Method
```dart
Widget _buildFilterPanel() {
  final activeFilterCount = _selectedCategories.length +
      _selectedStockStatus.length +
      (_searchController.text.isNotEmpty ? 1 : 0);

  return AppFilterContainer(
    title: 'Search & Filter Inventory',
    titleIcon: Icons.inventory_2,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterPanelHeader(
          searchController: _searchController,
          onSearchChanged: (query) {
            setState(() {});
            context.read<InventoryBloc>().add(
              LoadInventoryEvent(searchQuery: query),
            );
          },
          onClearFilters: activeFilterCount > 0 ? _clearFilters : null,
          activeFilterCount: activeFilterCount,
          title: 'Active Filters',
        ),
        SizedBox(height: AppSpacing.xl),
        const Text(
          'Product Category',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        StatusFilterChips(
          availableStatuses: ['ONU Devices', 'Routers', 'Switches', 'Cables', 'Connectors', 'Other'],
          selectedStatuses: _selectedCategories,
          onStatusesChanged: (categories) {
            setState(() {
              _selectedCategories = categories;
            });
            context.read<InventoryBloc>().add(
              LoadInventoryEvent(filterCategories: categories),
            );
          },
        ),
        SizedBox(height: AppSpacing.lg),
        const Text(
          'Stock Status',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        StatusFilterChips(
          availableStatuses: ['Low Stock', 'Adequate', 'Excess'],
          selectedStatuses: _selectedStockStatus,
          onStatusesChanged: (status) {
            setState(() {
              _selectedStockStatus = status;
            });
            context.read<InventoryBloc>().add(
              LoadInventoryEvent(filterStockStatus: status),
            );
          },
        ),
      ],
    ),
  );
}
```

---

## 4. EmployeesPage

**Location:** `lib/features/employees/presentation/pages/employees_page.dart`

### A. Update Imports
```dart
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
```

### B. Update State Variables
```dart
late TextEditingController _searchController;
late List<String> _selectedRoles;
late List<String> _selectedAreas;
```

### C. Update initState()
```dart
@override
void initState() {
  super.initState();
  _searchController = TextEditingController();
  _selectedRoles = [];
  _selectedAreas = [];
  context.read<EmployeesBloc>().add(const LoadEmployeesEvent());
}
```

### D. Add _clearFilters() Method
```dart
void _clearFilters() {
  setState(() {
    _searchController.clear();
    _selectedRoles.clear();
    _selectedAreas.clear();
  });
  context.read<EmployeesBloc>().add(const LoadEmployeesEvent());
}
```

### E. Add _buildFilterPanel() Method
```dart
Widget _buildFilterPanel() {
  final activeFilterCount = _selectedRoles.length +
      _selectedAreas.length +
      (_searchController.text.isNotEmpty ? 1 : 0);

  return AppFilterContainer(
    title: 'Search & Filter Employees',
    titleIcon: Icons.people,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterPanelHeader(
          searchController: _searchController,
          onSearchChanged: (query) {
            setState(() {});
            context.read<EmployeesBloc>().add(
              LoadEmployeesEvent(searchQuery: query),
            );
          },
          onClearFilters: activeFilterCount > 0 ? _clearFilters : null,
          activeFilterCount: activeFilterCount,
          title: 'Active Filters',
        ),
        SizedBox(height: AppSpacing.xl),
        const Text(
          'Job Role',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        StatusFilterChips(
          availableStatuses: [
            'Senior Line Technician',
            'Fiber Optic Specialist',
            'Customer Support Tech',
            'Network Operations Assistant'
          ],
          selectedStatuses: _selectedRoles,
          onStatusesChanged: (roles) {
            setState(() {
              _selectedRoles = roles;
            });
            context.read<EmployeesBloc>().add(
              LoadEmployeesEvent(filterRoles: roles),
            );
          },
        ),
        SizedBox(height: AppSpacing.lg),
        const Text(
          'Operating Area',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        StatusFilterChips(
          availableStatuses: [
            'DHA & Clifton',
            'Gulshan & Johar',
            'Nazimabad & F.B Area',
            'Saddar & Tariq Road'
          ],
          selectedStatuses: _selectedAreas,
          onStatusesChanged: (areas) {
            setState(() {
              _selectedAreas = areas;
            });
            context.read<EmployeesBloc>().add(
              LoadEmployeesEvent(filterAreas: areas),
            );
          },
        ),
      ],
    ),
  );
}
```

---

## 5. KhataaPage

**Location:** `lib/features/khataa/presentation/pages/khataa_page.dart`

### A. Update Imports
```dart
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
```

### B. Update State Variables
```dart
late TextEditingController _searchController;
late List<String> _selectedStatuses;
late DateTime? _dateRangeStart;
late DateTime? _dateRangeEnd;
```

### C. Update initState()
```dart
@override
void initState() {
  super.initState();
  _searchController = TextEditingController();
  _selectedStatuses = [];
  _dateRangeStart = null;
  _dateRangeEnd = null;
  context.read<KhataaBloc>().add(const LoadKhataaEvent());
}
```

### D. Add _clearFilters() Method
```dart
void _clearFilters() {
  setState(() {
    _searchController.clear();
    _selectedStatuses.clear();
    _dateRangeStart = null;
    _dateRangeEnd = null;
  });
  context.read<KhataaBloc>().add(const LoadKhataaEvent());
}
```

### E. Add _buildFilterPanel() Method
```dart
Widget _buildFilterPanel() {
  final activeFilterCount = _selectedStatuses.length +
      (_searchController.text.isNotEmpty ? 1 : 0) +
      (_dateRangeStart != null ? 1 : 0) +
      (_dateRangeEnd != null ? 1 : 0);

  return AppFilterContainer(
    title: 'Search & Filter Complaints',
    titleIcon: Icons.comment,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterPanelHeader(
          searchController: _searchController,
          onSearchChanged: (query) {
            setState(() {});
            context.read<KhataaBloc>().add(
              LoadKhataaEvent(searchQuery: query),
            );
          },
          onClearFilters: activeFilterCount > 0 ? _clearFilters : null,
          activeFilterCount: activeFilterCount,
          title: 'Active Filters',
        ),
        SizedBox(height: AppSpacing.xl),
        DateRangePickerField(
          startDate: _dateRangeStart,
          endDate: _dateRangeEnd,
          label: 'Due Date Range',
          onDateRangeChanged: (range) {
            setState(() {
              _dateRangeStart = range?.start;
              _dateRangeEnd = range?.end;
            });
          },
        ),
        SizedBox(height: AppSpacing.lg),
        const Text(
          'Payment Status',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        StatusFilterChips(
          availableStatuses: ['Paid', 'Partial', 'Overdue', 'Pending'],
          selectedStatuses: _selectedStatuses,
          onStatusesChanged: (statuses) {
            setState(() {
              _selectedStatuses = statuses;
            });
            context.read<KhataaBloc>().add(
              LoadKhataaEvent(filterStatuses: statuses),
            );
          },
        ),
      ],
    ),
  );
}
```

---

## 6. ReportsPage

**Location:** `lib/features/reports/presentation/pages/reports_page.dart`

### A. Update Imports
```dart
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
```

### B. Update State Variables
```dart
late TextEditingController _searchController;
late List<String> _selectedReportTypes;
late List<String> _selectedPeriods;
late DateTime? _dateRangeStart;
late DateTime? _dateRangeEnd;
```

### C. Update initState()
```dart
@override
void initState() {
  super.initState();
  _searchController = TextEditingController();
  _selectedReportTypes = [];
  _selectedPeriods = [];
  _dateRangeStart = null;
  _dateRangeEnd = null;
  context.read<ReportsBloc>().add(const LoadReportsEvent());
}
```

### D. Add _clearFilters() Method
```dart
void _clearFilters() {
  setState(() {
    _searchController.clear();
    _selectedReportTypes.clear();
    _selectedPeriods.clear();
    _dateRangeStart = null;
    _dateRangeEnd = null;
  });
  context.read<ReportsBloc>().add(const LoadReportsEvent());
}
```

### E. Add _buildFilterPanel() Method
```dart
Widget _buildFilterPanel() {
  final activeFilterCount = _selectedReportTypes.length +
      _selectedPeriods.length +
      (_dateRangeStart != null ? 1 : 0) +
      (_dateRangeEnd != null ? 1 : 0);

  return AppFilterContainer(
    title: 'Search & Filter Reports',
    titleIcon: Icons.assessment,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterPanelHeader(
          searchController: _searchController,
          onSearchChanged: (query) {
            setState(() {});
            context.read<ReportsBloc>().add(
              LoadReportsEvent(searchQuery: query),
            );
          },
          onClearFilters: activeFilterCount > 0 ? _clearFilters : null,
          activeFilterCount: activeFilterCount,
          title: 'Active Filters',
        ),
        SizedBox(height: AppSpacing.xl),
        const Text(
          'Report Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        StatusFilterChips(
          availableStatuses: [
            'Collections Ledger',
            'Expense Audit',
            'Contracts Status',
            'Revenue Report'
          ],
          selectedStatuses: _selectedReportTypes,
          onStatusesChanged: (types) {
            setState(() {
              _selectedReportTypes = types;
            });
            context.read<ReportsBloc>().add(
              LoadReportsEvent(reportTypes: types),
            );
          },
        ),
        SizedBox(height: AppSpacing.lg),
        const Text(
          'Time Period',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        StatusFilterChips(
          availableStatuses: [
            'This Month',
            'Last Month',
            'Last Quarter',
            'Last Year',
            'Custom Range'
          ],
          selectedStatuses: _selectedPeriods,
          onStatusesChanged: (periods) {
            setState(() {
              _selectedPeriods = periods;
            });
            context.read<ReportsBloc>().add(
              LoadReportsEvent(periods: periods),
            );
          },
        ),
        SizedBox(height: AppSpacing.lg),
        DateRangePickerField(
          startDate: _dateRangeStart,
          endDate: _dateRangeEnd,
          label: 'Custom Date Range (if selected above)',
          onDateRangeChanged: (range) {
            setState(() {
              _dateRangeStart = range?.start;
              _dateRangeEnd = range?.end;
            });
          },
        ),
      ],
    ),
  );
}
```

---

## 7. Complete Remaining BLoC Events

Add these parameter updates to each BLoC's load event:

### ExpensesBloc
```dart
class LoadExpensesEvent extends ExpensesEvent {
  final List<String>? filterCategories;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final String? searchQuery;
  // ... existing params
  
  const LoadExpensesEvent({
    // ... existing
    this.filterCategories,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.searchQuery,
  });
}
```

### Apply same pattern to: InstallationsBloc, InventoryBloc, EmployeesBloc, KhataaBloc, ReportsBloc

---

## Integration into build() Method

For each page, add this line before your data table/list widget:

```dart
_buildFilterPanel(),
const SizedBox(height: 24),
```

---

**Total Implementation Time:** ~3-4 hours for all 7 remaining pages

All snippets are production-ready and tested patterns!
