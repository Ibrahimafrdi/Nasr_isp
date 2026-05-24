import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/shared/models/models.dart';

// Customers Events
abstract class CustomersEvent extends Equatable {
  const CustomersEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomersEvent extends CustomersEvent {
  final int page;
  final String? searchQuery;
  final CustomerStatus? filterStatus;

  const LoadCustomersEvent({
    this.page = 1,
    this.searchQuery,
    this.filterStatus,
  });

  @override
  List<Object?> get props => [page, searchQuery, filterStatus];
}

class SearchCustomersEvent extends CustomersEvent {
  final String query;

  const SearchCustomersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterCustomersEvent extends CustomersEvent {
  final CustomerStatus? status;

  const FilterCustomersEvent({this.status});

  @override
  List<Object?> get props => [status];
}

// Customers States
abstract class CustomersState extends Equatable {
  const CustomersState();

  @override
  List<Object?> get props => [];
}

class CustomersInitial extends CustomersState {
  const CustomersInitial();
}

class CustomersLoading extends CustomersState {
  const CustomersLoading();
}

class CustomersLoaded extends CustomersState {
  final List<CustomerModel> customers;
  final int currentPage;
  final int totalPages;
  final String? searchQuery;
  final CustomerStatus? filterStatus;

  const CustomersLoaded({
    required this.customers,
    required this.currentPage,
    required this.totalPages,
    this.searchQuery,
    this.filterStatus,
  });

  @override
  List<Object?> get props => [
    customers,
    currentPage,
    totalPages,
    searchQuery,
    filterStatus,
  ];
}

class CustomersError extends CustomersState {
  final String message;

  const CustomersError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Customers BLoC
class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  final List<CustomerModel> _allCustomers = _generateAllMockCustomers();

  CustomersBloc() : super(const CustomersInitial()) {
    on<LoadCustomersEvent>(_onLoadCustomers);
    on<SearchCustomersEvent>(_onSearchCustomers);
    on<FilterCustomersEvent>(_onFilterCustomers);
  }

  Future<void> _onLoadCustomers(
    LoadCustomersEvent event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      var filtered = _filterCustomers(event.searchQuery, event.filterStatus);

      final totalPages = (filtered.length / AppConstants.itemsPerPage).ceil();
      final start = (event.page - 1) * AppConstants.itemsPerPage;
      final end = (start + AppConstants.itemsPerPage)
          .clamp(0, filtered.length)
          .toInt();
      final paginated = filtered.sublist(start, end);

      emit(
        CustomersLoaded(
          customers: paginated,
          currentPage: event.page,
          totalPages: totalPages,
          searchQuery: event.searchQuery,
          filterStatus: event.filterStatus,
        ),
      );
    } catch (e) {
      emit(CustomersError(message: 'Failed to load customers: $e'));
    }
  }

  Future<void> _onSearchCustomers(
    SearchCustomersEvent event,
    Emitter<CustomersState> emit,
  ) async {
    await _onLoadCustomers(LoadCustomersEvent(searchQuery: event.query), emit);
  }

  Future<void> _onFilterCustomers(
    FilterCustomersEvent event,
    Emitter<CustomersState> emit,
  ) async {
    await _onLoadCustomers(
      LoadCustomersEvent(filterStatus: event.status),
      emit,
    );
  }

  List<CustomerModel> _filterCustomers(
    String? searchQuery,
    CustomerStatus? status,
  ) {
    var result = List<CustomerModel>.from(_allCustomers);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      result = result.where((c) {
        return c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            c.phone.contains(searchQuery) ||
            c.packageName.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (status != null) {
      result = result.where((c) => c.status == status).toList();
    }

    return result;
  }

  static List<CustomerModel> _generateAllMockCustomers() {
    final baseDate = DateTime.now();
    return List.generate(150, (i) {
      final daysUntilExpiry = 7 + (i % 60);
      final expiryDate = baseDate.add(Duration(days: daysUntilExpiry));

      CustomerStatus status;
      if (daysUntilExpiry <= 0) {
        status = CustomerStatus.expired;
      } else if (daysUntilExpiry <= 7) {
        status = CustomerStatus.expiringSoon;
      } else {
        status = CustomerStatus.active;
      }

      return CustomerModel(
        id: 'cust_$i',
        name: 'Customer ${i + 1}',
        phone: '+923001234${500 + i}',
        address: 'Address $i, Karachi',
        email: 'customer$i@email.com',
        packageName: ['10 Mbps', '25 Mbps', '50 Mbps'][i % 3],
        monthlyRate: [999, 1499, 2499][i % 3].toDouble(),
        expiryDate: expiryDate,
        status: status,
        assignedEmployeeId: 'emp_${i % 5}',
        createdAt: baseDate.subtract(Duration(days: 90 + i)),
        balance: (i % 2 == 0) ? 0 : (500 + (i * 100)).toDouble(),
      );
    });
  }
}
