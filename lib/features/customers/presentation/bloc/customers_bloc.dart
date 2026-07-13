import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/features/customers/domain/usecases/add_customer.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/customers/domain/usecases/update_customer.dart';
import 'package:nasr_isp/features/customers/domain/usecases/delete_customer.dart';

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
  final String? filterConnectionType; // 'wireless', 'fiber', or null for all

  const LoadCustomersEvent({
    this.page = 1,
    this.searchQuery,
    this.filterStatus,
    this.filterConnectionType,
  });

  @override
  List<Object?> get props => [
    page,
    searchQuery,
    filterStatus,
    filterConnectionType,
  ];
}

class CreateCustomerEvent extends CustomersEvent {
  final CustomerModel customer;

  const CreateCustomerEvent(this.customer);

  @override
  List<Object?> get props => [customer];
}

class UpdateCustomerEvent extends CustomersEvent {
  final CustomerModel customer;

  const UpdateCustomerEvent(this.customer);

  @override
  List<Object?> get props => [customer];
}

class DeleteCustomerEvent extends CustomersEvent {
  final String customerId;

  const DeleteCustomerEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
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
  final String? filterConnectionType;

  const CustomersLoaded({
    required this.customers,
    required this.currentPage,
    required this.totalPages,
    this.searchQuery,
    this.filterStatus,
    this.filterConnectionType,
  });

  @override
  List<Object?> get props => [
    customers,
    currentPage,
    totalPages,
    searchQuery,
    filterStatus,
    filterConnectionType,
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
  final GetCustomers getCustomers;
  final AddCustomer addCustomer;
  final UpdateCustomer updateCustomer;
  final DeleteCustomer deleteCustomer;

  CustomersBloc({
    required this.getCustomers,
    required this.addCustomer,
    required this.updateCustomer,
    required this.deleteCustomer,
  }) : super(const CustomersInitial()) {
    on<LoadCustomersEvent>(_onLoadCustomers);
    on<CreateCustomerEvent>(_onCreateCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
  }

  Future<void> _onCreateCustomer(
    CreateCustomerEvent event,
    Emitter<CustomersState> emit,
  ) async {
    try {
      await addCustomer(event.customer);
      await _onLoadCustomers(const LoadCustomersEvent(), emit);
    } catch (e) {
      emit(CustomersError(message: 'Failed to create customer: $e'));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    try {
      await updateCustomer(event.customer);
      // Give Firestore time to propagate before re-fetching
      await Future.delayed(const Duration(milliseconds: 500));
      await _onLoadCustomers(const LoadCustomersEvent(), emit);
    } catch (e) {
      emit(CustomersError(message: 'Failed to update customer: $e'));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomerEvent event,
    Emitter<CustomersState> emit,
  ) async {
    try {
      await deleteCustomer(event.customerId);
      await _onLoadCustomers(const LoadCustomersEvent(), emit);
    } catch (e) {
      emit(CustomersError(message: 'Failed to delete customer: $e'));
    }
  }

  Future<void> _onLoadCustomers(
    LoadCustomersEvent event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final allCustomersList = await getCustomers();
      final List<CustomerModel> allModels = allCustomersList.map((e) {
        if (e is CustomerModel) return e;
        return CustomerModel(
          id: e.id,
          name: e.name,
          phone: e.phone,
          cnic: e.cnic,
          address: e.address,
          connectionType: e.connectionType,
          packageId: e.packageId,
          monthlyBill: e.monthlyBill,
          status: e.status,
          notes: e.notes,
          createdAt: e.createdAt,
          joinDate: e.joinDate,
          nextDueDate: e.nextDueDate,
        );
      }).toList();

      final filtered = _filterCustomers(
        allModels,
        event.searchQuery,
        event.filterStatus,
        event.filterConnectionType,
      );

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
          filterConnectionType: event.filterConnectionType,
        ),
      );
    } catch (e) {
      emit(CustomersError(message: 'Failed to load customers: $e'));
    }
  }

  List<CustomerModel> _filterCustomers(
    List<CustomerModel> customers,
    String? searchQuery,
    CustomerStatus? status,
    String? connectionType,
  ) {
    var result = List<CustomerModel>.from(customers);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      result = result.where((c) {
        return c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            c.phone.contains(searchQuery) ||
            c.cnic.contains(searchQuery) ||
            c.address.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (status != null) {
      final now = DateTime.now();
      result = result.where((c) {
        switch (status) {
          case CustomerStatus.active:
            return c.status == 'active' &&
                (c.nextDueDate == null ||
                    c.nextDueDate!.isAfter(now.add(const Duration(days: 7))));
          case CustomerStatus.expiringSoon:
            if (c.nextDueDate == null) return false;
            final diff = c.nextDueDate!.difference(now).inDays;
            return diff >= 0 && diff <= 7;
          case CustomerStatus.expired:
            if (c.status != 'active' || c.nextDueDate == null) return false;
            return c.nextDueDate!.isBefore(now);
          case CustomerStatus.inactive:
            return c.status == 'inactive';
        }
      }).toList();
    }

    if (connectionType != null) {
      result = result.where((c) => c.connectionType == connectionType).toList();
    }

    return result;
  }
}
