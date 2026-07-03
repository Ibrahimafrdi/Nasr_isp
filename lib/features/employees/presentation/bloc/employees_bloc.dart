import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';
import 'package:nasr_isp/features/employees/domain/usecases/add_employee.dart';
import 'package:nasr_isp/features/employees/domain/usecases/get_employees.dart';
import 'package:nasr_isp/features/employees/domain/usecases/update_employee.dart';
import 'package:nasr_isp/features/employees/domain/usecases/delete_employee.dart';
import 'package:nasr_isp/features/installations/domain/usecases/get_installations.dart';

// ─── EVENTS ─────────────────────────────────────────────────────────────────
abstract class EmployeeEvent extends Equatable {
  const EmployeeEvent();

  @override
  List<Object?> get props => [];
}

class LoadEmployeesEvent extends EmployeeEvent {
  const LoadEmployeesEvent();
}

class AddEmployeeEvent extends EmployeeEvent {
  final EmployeeEntity employee;

  const AddEmployeeEvent(this.employee);

  @override
  List<Object?> get props => [employee];
}

class UpdateEmployeeEvent extends EmployeeEvent {
  final EmployeeEntity employee;

  const UpdateEmployeeEvent(this.employee);

  @override
  List<Object?> get props => [employee];
}

class DeleteEmployeeEvent extends EmployeeEvent {
  final String employeeId;

  const DeleteEmployeeEvent(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}

class SearchEmployeesEvent extends EmployeeEvent {
  final String query;

  const SearchEmployeesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

// ─── STATES ─────────────────────────────────────────────────────────────────
abstract class EmployeeState extends Equatable {
  const EmployeeState();

  @override
  List<Object?> get props => [];
}

class EmployeeInitial extends EmployeeState {
  const EmployeeInitial();
}

class EmployeeLoading extends EmployeeState {
  const EmployeeLoading();
}

class EmployeeLoaded extends EmployeeState {
  final List<EmployeeEntity> employees;
  final Map<String, int> installationCounts;
  final String? searchQuery;

  const EmployeeLoaded(
    this.employees, {
    this.installationCounts = const {},
    this.searchQuery,
  });

  @override
  List<Object?> get props => [employees, installationCounts, searchQuery];
}

class EmployeeError extends EmployeeState {
  final String message;

  const EmployeeError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLOC ───────────────────────────────────────────────────────────────────
class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final GetEmployees getEmployees;
  final AddEmployee addEmployee;
  final UpdateEmployee updateEmployee;
  final DeleteEmployee deleteEmployee;
  final GetInstallations getInstallations;

  List<EmployeeEntity> _allEmployees = [];
  Map<String, int> _installationCounts = {};

  EmployeeBloc({
    required this.getEmployees,
    required this.addEmployee,
    required this.updateEmployee,
    required this.deleteEmployee,
    required this.getInstallations,
  }) : super(const EmployeeInitial()) {
    on<LoadEmployeesEvent>(_onLoadEmployees);
    on<AddEmployeeEvent>(_onAddEmployee);
    on<UpdateEmployeeEvent>(_onUpdateEmployee);
    on<DeleteEmployeeEvent>(_onDeleteEmployee);
    on<SearchEmployeesEvent>(_onSearchEmployees);
  }

  Future<void> _onLoadEmployees(
    LoadEmployeesEvent event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(const EmployeeLoading());
    try {
      final employeesList = await getEmployees();
      final installationsList = await getInstallations();

      // Compute installation counts per employee
      final counts = <String, int>{};
      for (final inst in installationsList) {
        final empId = inst.assignedEmployeeId;
        if (empId != null && empId.isNotEmpty) {
          counts[empId] = (counts[empId] ?? 0) + 1;
        }
      }

      _allEmployees = List.from(employeesList);
      _installationCounts = counts;

      emit(EmployeeLoaded(_allEmployees, installationCounts: _installationCounts));
    } catch (e) {
      emit(EmployeeError('Failed to load employees: $e'));
    }
  }

  Future<void> _onAddEmployee(
    AddEmployeeEvent event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(const EmployeeLoading());
    try {
      await addEmployee(event.employee);
      // Give firestore brief time to complete write operations
      await Future.delayed(const Duration(milliseconds: 300));
      add(const LoadEmployeesEvent());
    } catch (e) {
      emit(EmployeeError('Failed to add employee: $e'));
    }
  }

  Future<void> _onUpdateEmployee(
    UpdateEmployeeEvent event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(const EmployeeLoading());
    try {
      await updateEmployee(event.employee);
      await Future.delayed(const Duration(milliseconds: 300));
      add(const LoadEmployeesEvent());
    } catch (e) {
      emit(EmployeeError('Failed to update employee: $e'));
    }
  }

  Future<void> _onDeleteEmployee(
    DeleteEmployeeEvent event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(const EmployeeLoading());
    try {
      await deleteEmployee(event.employeeId);
      await Future.delayed(const Duration(milliseconds: 300));
      add(const LoadEmployeesEvent());
    } catch (e) {
      emit(EmployeeError('Failed to delete employee: $e'));
    }
  }

  void _onSearchEmployees(
    SearchEmployeesEvent event,
    Emitter<EmployeeState> emit,
  ) {
    if (state is EmployeeLoaded) {
      final query = event.query.toLowerCase().trim();
      if (query.isEmpty) {
        emit(EmployeeLoaded(_allEmployees, installationCounts: _installationCounts));
      } else {
        final filtered = _allEmployees.where((emp) {
          return emp.name.toLowerCase().contains(query) ||
              emp.phone.contains(query) ||
              emp.designation.toLowerCase().contains(query) ||
              emp.sectorArea.toLowerCase().contains(query);
        }).toList();
        emit(EmployeeLoaded(
          filtered,
          installationCounts: _installationCounts,
          searchQuery: event.query,
        ));
      }
    }
  }
}
