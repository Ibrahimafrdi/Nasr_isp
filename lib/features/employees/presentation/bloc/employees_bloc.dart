import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class EmployeesEvent extends Equatable {
  const EmployeesEvent();

  @override
  List<Object?> get props => [];
}

class LoadEmployeesEvent extends EmployeesEvent {
  const LoadEmployeesEvent();
}

abstract class EmployeesState extends Equatable {
  const EmployeesState();

  @override
  List<Object?> get props => [];
}

class EmployeesInitial extends EmployeesState {
  const EmployeesInitial();
}

class EmployeesLoading extends EmployeesState {
  const EmployeesLoading();
}

class EmployeesLoaded extends EmployeesState {
  const EmployeesLoaded();

  @override
  List<Object?> get props => [];
}

class EmployeesBloc extends Bloc<EmployeesEvent, EmployeesState> {
  EmployeesBloc() : super(const EmployeesInitial()) {
    on<LoadEmployeesEvent>(_onLoadEmployees);
  }

  Future<void> _onLoadEmployees(
    LoadEmployeesEvent event,
    Emitter<EmployeesState> emit,
  ) async {
    emit(const EmployeesLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    emit(const EmployeesLoaded());
  }
}
