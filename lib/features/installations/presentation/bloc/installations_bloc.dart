import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/usecases/create_installation.dart';
import 'package:nasr_isp/features/installations/domain/usecases/delete_installation.dart';
import 'package:nasr_isp/features/installations/domain/usecases/get_installations.dart';
import 'package:nasr_isp/features/installations/domain/usecases/get_installations_by_customer.dart';
import 'package:nasr_isp/features/installations/domain/usecases/update_installation.dart';

// Events
abstract class InstallationEvent extends Equatable {
  const InstallationEvent();

  @override
  List<Object?> get props => [];
}

class LoadInstallationsEvent extends InstallationEvent {
  final String? status;
  final String? connectionType;
  final String? employeeId;
  final String? searchQuery;

  const LoadInstallationsEvent({
    this.status,
    this.connectionType,
    this.employeeId,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [status, connectionType, employeeId, searchQuery];
}

class CreateInstallationEvent extends InstallationEvent {
  final InstallationEntity installation;

  const CreateInstallationEvent(this.installation);

  @override
  List<Object?> get props => [installation];
}

class UpdateInstallationEvent extends InstallationEvent {
  final InstallationEntity installation;

  const UpdateInstallationEvent(this.installation);

  @override
  List<Object?> get props => [installation];
}

class DeleteInstallationEvent extends InstallationEvent {
  final String id;
  final String? status;
  final String? connectionType;
  final String? employeeId;
  final String? searchQuery;

  const DeleteInstallationEvent(
    this.id, {
    this.status,
    this.connectionType,
    this.employeeId,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [id, status, connectionType, employeeId, searchQuery];
}

class LoadCustomerInstallationsEvent extends InstallationEvent {
  final String customerId;

  const LoadCustomerInstallationsEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

// States
abstract class InstallationState extends Equatable {
  const InstallationState();

  @override
  List<Object?> get props => [];
}

class InstallationInitial extends InstallationState {}

class InstallationLoading extends InstallationState {}

class InstallationLoaded extends InstallationState {
  final List<InstallationEntity> installations;

  const InstallationLoaded(this.installations);

  @override
  List<Object?> get props => [installations];
}

class InstallationError extends InstallationState {
  final String message;

  const InstallationError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class InstallationBloc extends Bloc<InstallationEvent, InstallationState> {
  final GetInstallations getInstallations;
  final CreateInstallation createInstallation;
  final UpdateInstallation updateInstallation;
  final DeleteInstallation deleteInstallation;
  final GetInstallationsByCustomer getInstallationsByCustomer;

  InstallationBloc({
    required this.getInstallations,
    required this.createInstallation,
    required this.updateInstallation,
    required this.deleteInstallation,
    required this.getInstallationsByCustomer,
  }) : super(InstallationInitial()) {
    on<LoadInstallationsEvent>(_onLoadInstallations);
    on<CreateInstallationEvent>(_onCreateInstallation);
    on<UpdateInstallationEvent>(_onUpdateInstallation);
    on<DeleteInstallationEvent>(_onDeleteInstallation);
    on<LoadCustomerInstallationsEvent>(_onLoadCustomerInstallations);
  }

  Future<void> _onLoadInstallations(
    LoadInstallationsEvent event,
    Emitter<InstallationState> emit,
  ) async {
    emit(InstallationLoading());
    try {
      final list = await getInstallations(
        status: event.status,
        connectionType: event.connectionType,
        employeeId: event.employeeId,
        searchQuery: event.searchQuery,
      );
      emit(InstallationLoaded(list));
    } catch (e) {
      emit(InstallationError(e.toString()));
    }
  }

  Future<void> _onCreateInstallation(
    CreateInstallationEvent event,
    Emitter<InstallationState> emit,
  ) async {
    emit(InstallationLoading());
    try {
      await createInstallation(event.installation);
      final list = await getInstallations();
      emit(InstallationLoaded(list));
    } catch (e) {
      emit(InstallationError(e.toString()));
    }
  }

  Future<void> _onUpdateInstallation(
    UpdateInstallationEvent event,
    Emitter<InstallationState> emit,
  ) async {
    emit(InstallationLoading());
    try {
      await updateInstallation(event.installation);
      final list = await getInstallations();
      emit(InstallationLoaded(list));
    } catch (e) {
      emit(InstallationError(e.toString()));
    }
  }

  Future<void> _onDeleteInstallation(
    DeleteInstallationEvent event,
    Emitter<InstallationState> emit,
  ) async {
    emit(InstallationLoading());
    try {
      await deleteInstallation(event.id);
      final list = await getInstallations(
        status: event.status,
        connectionType: event.connectionType,
        employeeId: event.employeeId,
        searchQuery: event.searchQuery,
      );
      emit(InstallationLoaded(list));
    } catch (e) {
      emit(InstallationError(e.toString()));
    }
  }

  Future<void> _onLoadCustomerInstallations(
    LoadCustomerInstallationsEvent event,
    Emitter<InstallationState> emit,
  ) async {
    emit(InstallationLoading());
    try {
      final list = await getInstallationsByCustomer(event.customerId);
      emit(InstallationLoaded(list));
    } catch (e) {
      emit(InstallationError(e.toString()));
    }
  }
}
