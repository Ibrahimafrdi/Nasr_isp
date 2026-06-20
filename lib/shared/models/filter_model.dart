import 'package:equatable/equatable.dart';

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
