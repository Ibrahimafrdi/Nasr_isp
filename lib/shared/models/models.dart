import 'package:equatable/equatable.dart';

export 'package:nasr_isp/features/customers/data/models/customer_model.dart';
export 'package:nasr_isp/features/packages/data/models/package_model.dart';
export 'package:nasr_isp/features/auth/data/models/user_model.dart';
export 'package:nasr_isp/features/payments/data/models/payment_model.dart';
export 'package:nasr_isp/features/employees/data/models/employee_model.dart';
export 'package:nasr_isp/features/installations/data/models/installation_model.dart';
export 'package:nasr_isp/features/expenses/data/models/expense_model.dart';
export 'package:nasr_isp/features/dashboard/data/models/dashboard_stats_model.dart';
export 'package:nasr_isp/features/settings/data/models/app_settings_model.dart';
export 'package:nasr_isp/features/inventory/data/models/inventory_item_model.dart';
export 'package:nasr_isp/features/inventory/data/models/stock_movement_model.dart';
export 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
export 'package:nasr_isp/features/inventory/domain/entities/stock_movement_entity.dart';


/// Generic filter model to hold common filter state
class FilterModel extends Equatable {
  final String? searchQuery;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final List<String> selectedStatuses;
  final List<String> selectedCategories;
  final String? selectedArea;
  final String? selectedRole;
  final int? page;
  final int pageSize;

  const FilterModel({
    this.searchQuery,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.selectedStatuses = const [],
    this.selectedCategories = const [],
    this.selectedArea,
    this.selectedRole,
    this.page = 1,
    this.pageSize = 20,
  });

  /// Check if any filters are active
  bool get hasActiveFilters =>
      searchQuery != null ||
      dateRangeStart != null ||
      dateRangeEnd != null ||
      selectedStatuses.isNotEmpty ||
      selectedCategories.isNotEmpty ||
      selectedArea != null ||
      selectedRole != null;

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (dateRangeStart != null) count++;
    if (dateRangeEnd != null) count++;
    count += selectedStatuses.length;
    count += selectedCategories.length;
    if (selectedArea != null) count++;
    if (selectedRole != null) count++;
    return count;
  }

  /// Create a copy with updated fields
  FilterModel copyWith({
    String? searchQuery,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    List<String>? selectedStatuses,
    List<String>? selectedCategories,
    String? selectedArea,
    String? selectedRole,
    int? page,
    int? pageSize,
  }) {
    return FilterModel(
      searchQuery: searchQuery ?? this.searchQuery,
      dateRangeStart: dateRangeStart ?? this.dateRangeStart,
      dateRangeEnd: dateRangeEnd ?? this.dateRangeEnd,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedArea: selectedArea ?? this.selectedArea,
      selectedRole: selectedRole ?? this.selectedRole,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Reset all filters
  FilterModel reset() {
    return const FilterModel(page: 1, pageSize: 20);
  }

  @override
  List<Object?> get props => [
    searchQuery,
    dateRangeStart,
    dateRangeEnd,
    selectedStatuses,
    selectedCategories,
    selectedArea,
    selectedRole,
    page,
    pageSize,
  ];
}
