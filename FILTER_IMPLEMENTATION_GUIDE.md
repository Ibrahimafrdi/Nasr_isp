# Filter Implementation Guide - Complete Reference

## Overview
The filter system has been successfully refactored with reusable components. This guide provides step-by-step instructions to apply the same filtering pattern to all remaining screens.

## Phase 1: Completed ✅
- ✅ Created `FilterModel` class in `shared/models/models.dart`
- ✅ Created reusable filter components in `shared/widgets/reusable_filter_components.dart`:
  - `DateRangePickerField` - Date range selection
  - `StatusFilterChips` - Multi-select status filters
  - `CategoryFilterDropdown` - Category selection
  - `FilterPanelHeader` - Standardized header with search and stats
- ✅ Updated `CustomersPage` with enhanced filter panel
- ✅ Partial update to `PaymentsPage` (import/state setup)

## Phase 2: In Progress - Remaining Pages

### Template Pattern for Each Page

```dart
// 1. IMPORTS (Add these)
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';

// 2. STATE VARIABLES (Replace old filter variables)
late TextEditingController _searchController;
late List<String> _selectedStatuses;  // or List<String> _selectedCategories
late DateTime? _dateRangeStart;
late DateTime? _dateRangeEnd;

// 3. INIT STATE
@override
void initState() {
  super.initState();
  _searchController = TextEditingController();
  _selectedStatuses = [];
  _dateRangeStart = null;
  _dateRangeEnd = null;
  context.read<YourBloc>().add(const LoadYourDataEvent());
}

// 4. CLEAR FILTERS METHOD
void _clearFilters() {
  setState(() {
    _searchController.clear();
    _selectedStatuses.clear();
    _dateRangeStart = null;
    _dateRangeEnd = null;
  });
  context.read<YourBloc>().add(const LoadYourDataEvent());
}

// 5. BUILD FILTER PANEL METHOD
Widget _buildFilterPanel() {
  final activeFilterCount = _selectedStatuses.length +
      (_searchController.text.isNotEmpty ? 1 : 0) +
      (_dateRangeStart != null ? 1 : 0) +
      (_dateRangeEnd != null ? 1 : 0);

  return AppFilterContainer(
    title: 'Search & Filter [Page Name]',
    titleIcon: Icons.filter_list,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with search
        FilterPanelHeader(
          searchController: _searchController,
          onSearchChanged: (query) {
            setState(() {});
            context.read<YourBloc>().add(
              YourLoadEvent(
                searchQuery: query,
                // Add other filter parameters
              ),
            );
          },
          onClearFilters: activeFilterCount > 0 ? _clearFilters : null,
          activeFilterCount: activeFilterCount,
          title: 'Active Filters',
        ),
        SizedBox(height: AppSpacing.xl),

        // Date Range (if applicable)
        DateRangePickerField(
          startDate: _dateRangeStart,
          endDate: _dateRangeEnd,
          label: '[Label e.g., "Created Date Range"]',
          onDateRangeChanged: (range) {
            setState(() {
              _dateRangeStart = range?.start;
              _dateRangeEnd = range?.end;
            });
            // Trigger filter event
          },
        ),
        SizedBox(height: AppSpacing.lg),

        // Status/Category Filters
        const Text(
          '[Filter Category Name]',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        StatusFilterChips(
          availableStatuses: ['Option 1', 'Option 2', 'Option 3'],
          selectedStatuses: _selectedStatuses,
          onStatusesChanged: (statuses) {
            setState(() {
              _selectedStatuses = statuses;
            });
            // Trigger filter event
          },
        ),
      ],
    ),
  );
}

// 6. IN BUILD METHOD
// Replace old filter card with:
const SizedBox(height: 16),
_buildFilterPanel(),
const SizedBox(height: 24),
```

## Screens to Update

### 1. **PaymentsPage** (Partially Started)
**Filters:** Search, Status (Completed/Pending/Failed/Partial), Date Range (Due Date), Payment Method

**Status Options:**
```dart
['Completed', 'Pending', 'Failed', 'Partial']
```

**Additional Logic:**
- Add date range for due dates and completion dates
- Add dropdown for payment methods if needed

---

### 2. **ExpensesPage**
**Filters:** Search, Category, Date Range, Amount Range

**Categories:**
```dart
['Rent', 'Utilities', 'Equipment', 'Salaries', 'Maintenance', 'Other']
```

**Changes Needed:**
- Use CategoryFilterDropdown instead of StatusFilterChips
- Add date range for expense dates
- Consider adding min/max amount range filter

---

### 3. **InstallationsPage**
**Filters:** Search, Status, Technician, Date Range, Cost Range

**Status Options:**
```dart
['Scheduled', 'In Progress', 'Completed', 'Cancelled']
```

**Additional Fields:**
- Add dropdown for Technician selection
- Add date range for installation dates

---

### 4. **InventoryPage**
**Filters:** Search, Category, Stock Status (Low/Adequate/Excess)

**Categories:**
```dart
['ONU Devices', 'Routers', 'Switches', 'Cables', 'Connectors', 'Other']
```

**Special Handling:**
- Consider stock level indicators
- Low stock alert threshold

---

### 5. **EmployeesPage**
**Filters:** Search, Role, Area, Efficiency Range

**Role Options:**
```dart
['Senior Line Technician', 'Fiber Optic Specialist', 'Customer Support Tech', 
 'Network Operations Assistant']
```

**Area Options:**
```dart
['DHA & Clifton', 'Gulshan & Johar', 'Nazimabad & F.B Area', 'Saddar & Tariq Road']
```

---

### 6. **KhataaPage** (Complaints/Ledger)
**Filters:** Search, Status, Date Range, Amount Range

**Status Options:**
```dart
['Paid', 'Partial', 'Overdue', 'Pending']
```

**Features:**
- Date range for payment dates
- Outstanding amount range filter

---

### 7. **ReportsPage**
**Filters:** Report Type, Period, Format, Date Range

**Report Types:**
```dart
['Collections Ledger', 'Expense Audit', 'Contracts Status', 'Revenue Report']
```

**Periods:**
```dart
['This Month', 'Last Month', 'Last Quarter', 'Last Year', 'Custom Range']
```

---

## BLoC Update Pattern

For each BLoC, add support for comprehensive filtering:

```dart
// Add to Event classes
class LoadYourDataEvent extends YourEvent {
  final int page;
  final String? searchQuery;
  final List<String>? filterStatuses;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;

  const LoadYourDataEvent({
    this.page = 1,
    this.searchQuery,
    this.filterStatuses,
    this.dateRangeStart,
    this.dateRangeEnd,
  });

  @override
  List<Object?> get props => [
    page,
    searchQuery,
    filterStatuses,
    dateRangeStart,
    dateRangeEnd,
  ];
}

// In BLoC handler
Future<void> _onLoadData(
  LoadYourDataEvent event,
  Emitter<YourState> emit,
) async {
  emit(const YourLoading());
  await Future.delayed(const Duration(milliseconds: 500));

  try {
    var filtered = _filterData(
      event.searchQuery,
      event.filterStatuses,
      event.dateRangeStart,
      event.dateRangeEnd,
    );

    final totalPages = (filtered.length / 20).ceil();
    final start = (event.page - 1) * 20;
    final end = (start + 20).clamp(0, filtered.length).toInt();
    final paginated = filtered.sublist(start, end);

    emit(YourLoaded(
      items: paginated,
      currentPage: event.page,
      totalPages: totalPages,
    ));
  } catch (e) {
    emit(YourError(message: 'Failed to load data: $e'));
  }
}

// Filtering helper method
List<YourModel> _filterData(
  String? searchQuery,
  List<String>? statuses,
  DateTime? dateStart,
  DateTime? dateEnd,
) {
  var result = List<YourModel>.from(_allItems);

  if (searchQuery != null && searchQuery.isNotEmpty) {
    result = result.where((item) {
      return item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.id.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  if (statuses != null && statuses.isNotEmpty) {
    result = result.where((item) {
      // Adapt based on your model's status field
      return statuses.contains(item.status.label);
    }).toList();
  }

  if (dateStart != null && dateEnd != null) {
    result = result.where((item) {
      // Adapt based on your model's date field
      return item.createdAt.isAfter(dateStart) && 
             item.createdAt.isBefore(dateEnd);
    }).toList();
  }

  return result;
}
```

## UI Consistency Checklist

For each page, ensure:

- ✅ AppFilterContainer used as wrapper
- ✅ FilterPanelHeader for search + badge + clear button
- ✅ All filter options use AppFilterChip or appropriate widget
- ✅ Date ranges use DateRangePickerField
- ✅ Filter badge shows active filter count
- ✅ Clear Filters button appears when filters are active
- ✅ All actions trigger appropriate BLoC events
- ✅ Responsive layout maintained (mobile/tablet/desktop)
- ✅ Consistent spacing using AppSpacing constants
- ✅ Consistent colors using AppColors
- ✅ Animations preserved (fade/slide on clear)

## Testing Checklist

For each screen:

1. **Search Functionality**
   - [ ] Search filters results in real-time
   - [ ] Clear button appears when text entered
   - [ ] Search clears when button clicked

2. **Status/Category Filters**
   - [ ] Chips highlight when selected
   - [ ] Multiple selections work
   - [ ] Deselect by clicking again

3. **Date Range Filters**
   - [ ] Calendar picker opens on click
   - [ ] Date range displays correctly
   - [ ] Clear button appears when selected
   - [ ] Date range clears when button clicked

4. **Combined Filters**
   - [ ] Multiple filters work together
   - [ ] Filter badge counts correctly
   - [ ] Clear all filters works

5. **Data Updates**
   - [ ] Data updates when filters change
   - [ ] Loading state shows
   - [ ] Error handling works

6. **Responsiveness**
   - [ ] Mobile layout (< 600px)
   - [ ] Tablet layout (600-1200px)
   - [ ] Desktop layout (> 1200px)

## Icons Reference

For titleIcon in AppFilterContainer:
- `Icons.filter_list` - Generic filters
- `Icons.people` - Customers/Employees
- `Icons.payment` - Payments
- `Icons.receipt_long` - Expenses/Reports
- `Icons.engineering` - Installations
- `Icons.inventory_2` - Inventory
- `Icons.comment` - Comments/Khataa

## Styling Reference

All components use these standard values:

```dart
// From app_spacing.dart
AppSpacing.radiusSm = 8
AppSpacing.radiusMd = 12
AppSpacing.md = 12
AppSpacing.lg = 16
AppSpacing.xl = 24
AppSpacing.xxl = 32

// From app_colors.dart
AppColors.primaryBlue = #2563EB
AppColors.errorRed = #DC2626
AppColors.offWhite = #F5F5F5
AppColors.lightGray = #E5E7EB
```

## Migration Order (Recommended)

1. ✅ Customers (Done)
2. ⏳ Payments (In Progress)
3. → Expenses (Next - Simple list)
4. → Installations (Moderate complexity)
5. → Inventory (Similar to Customers)
6. → Employees (Similar to Customers)
7. → Khataa (Similar to Payments)
8. → Reports (Complex - custom logic)

## Quick Copy-Paste Section

### Complete _buildFilterPanel for Payments
```dart
Widget _buildFilterPanel() {
  final activeFilterCount = _selectedStatuses.length +
      (_searchController.text.isNotEmpty ? 1 : 0) +
      (_dateRangeStart != null ? 1 : 0) +
      (_dateRangeEnd != null ? 1 : 0);

  return AppFilterContainer(
    title: 'Search & Filter Payments',
    titleIcon: Icons.payment,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterPanelHeader(
          searchController: _searchController,
          onSearchChanged: (query) {
            setState(() {});
            context.read<PaymentsBloc>().add(
              LoadPaymentsEvent(searchQuery: query),
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
          label: 'Payment Date Range',
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
          availableStatuses: ['Completed', 'Pending', 'Failed', 'Partial'],
          selectedStatuses: _selectedStatuses,
          onStatusesChanged: (statuses) {
            setState(() {
              _selectedStatuses = statuses;
            });
            context.read<PaymentsBloc>().add(
              LoadPaymentsEvent(filterStatuses: statuses),
            );
          },
        ),
      ],
    ),
  );
}
```

---

## Summary

- Total Reusable Components: 5
- Total Pages to Update: 8
- Estimated Implementation Time: 2-3 hours for all pages
- Key Benefit: Consistent UX across entire application

All components follow Material Design 3 principles and maintain responsive design across all device sizes.
