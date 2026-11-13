import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';
import 'package:nasr_isp/features/complaints/domain/usecases/create_complaint.dart';
import 'package:nasr_isp/features/complaints/domain/usecases/delete_complaint.dart';
import 'package:nasr_isp/features/complaints/domain/usecases/get_complaints.dart';
import 'package:nasr_isp/features/complaints/domain/usecases/get_complaints_by_customer.dart';
import 'package:nasr_isp/features/complaints/domain/usecases/update_complaint.dart';

// Events
abstract class ComplaintEvent extends Equatable {
  const ComplaintEvent();

  @override
  List<Object?> get props => [];
}

class LoadComplaintsEvent extends ComplaintEvent {
  final String? status;
  final String? priority;
  final String? type;
  final String? employeeId;
  final String? currentUserId;
  final bool isAdmin;
  final bool mineOnly;
  final String? searchQuery;

  const LoadComplaintsEvent({
    this.status,
    this.priority,
    this.type,
    this.employeeId,
    this.currentUserId,
    this.isAdmin = true,
    this.mineOnly = false,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
        status,
        priority,
        type,
        employeeId,
        currentUserId,
        isAdmin,
        mineOnly,
        searchQuery,
      ];
}

class CreateComplaintEvent extends ComplaintEvent {
  final ComplaintEntity complaint;
  final String? status;
  final String? priority;
  final String? type;
  final String? employeeId;
  final String? currentUserId;
  final bool isAdmin;
  final bool mineOnly;
  final String? searchQuery;

  const CreateComplaintEvent(
    this.complaint, {
    this.status,
    this.priority,
    this.type,
    this.employeeId,
    this.currentUserId,
    this.isAdmin = true,
    this.mineOnly = false,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
        complaint,
        status,
        priority,
        type,
        employeeId,
        currentUserId,
        isAdmin,
        mineOnly,
        searchQuery,
      ];
}

class UpdateComplaintEvent extends ComplaintEvent {
  final ComplaintEntity complaint;
  final String? status;
  final String? priority;
  final String? type;
  final String? employeeId;
  final String? currentUserId;
  final bool isAdmin;
  final bool mineOnly;
  final String? searchQuery;

  const UpdateComplaintEvent(
    this.complaint, {
    this.status,
    this.priority,
    this.type,
    this.employeeId,
    this.currentUserId,
    this.isAdmin = true,
    this.mineOnly = false,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
        complaint,
        status,
        priority,
        type,
        employeeId,
        currentUserId,
        isAdmin,
        mineOnly,
        searchQuery,
      ];
}

class DeleteComplaintEvent extends ComplaintEvent {
  final String id;
  final String? status;
  final String? priority;
  final String? type;
  final String? employeeId;
  final String? currentUserId;
  final bool isAdmin;
  final bool mineOnly;
  final String? searchQuery;

  const DeleteComplaintEvent(
    this.id, {
    this.status,
    this.priority,
    this.type,
    this.employeeId,
    this.currentUserId,
    this.isAdmin = true,
    this.mineOnly = false,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
        id,
        status,
        priority,
        type,
        employeeId,
        currentUserId,
        isAdmin,
        mineOnly,
        searchQuery,
      ];
}

class LoadCustomerComplaintsEvent extends ComplaintEvent {
  final String customerId;

  const LoadCustomerComplaintsEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

// States
abstract class ComplaintState extends Equatable {
  const ComplaintState();

  @override
  List<Object?> get props => [];
}

class ComplaintInitial extends ComplaintState {}

class ComplaintLoading extends ComplaintState {}

class ComplaintLoaded extends ComplaintState {
  final List<ComplaintEntity> complaints;

  const ComplaintLoaded(this.complaints);

  @override
  List<Object?> get props => [complaints];
}

class ComplaintError extends ComplaintState {
  final String message;

  const ComplaintError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ComplaintBloc extends Bloc<ComplaintEvent, ComplaintState> {
  final GetComplaints getComplaints;
  final CreateComplaint createComplaint;
  final UpdateComplaint updateComplaint;
  final DeleteComplaint deleteComplaint;
  final GetComplaintsByCustomer getComplaintsByCustomer;

  ComplaintBloc({
    required this.getComplaints,
    required this.createComplaint,
    required this.updateComplaint,
    required this.deleteComplaint,
    required this.getComplaintsByCustomer,
  }) : super(ComplaintInitial()) {
    on<LoadComplaintsEvent>(_onLoadComplaints);
    on<CreateComplaintEvent>(_onCreateComplaint);
    on<UpdateComplaintEvent>(_onUpdateComplaint);
    on<DeleteComplaintEvent>(_onDeleteComplaint);
    on<LoadCustomerComplaintsEvent>(_onLoadCustomerComplaints);
  }

  Future<void> _onLoadComplaints(
    LoadComplaintsEvent event,
    Emitter<ComplaintState> emit,
  ) async {
    emit(ComplaintLoading());
    try {
      final list = await getComplaints(
        status: event.status,
        priority: event.priority,
        type: event.type,
        employeeId: event.employeeId,
        currentUserId: event.currentUserId,
        isAdmin: event.isAdmin,
        mineOnly: event.mineOnly,
        searchQuery: event.searchQuery,
      );
      emit(ComplaintLoaded(list));
    } catch (e) {
      emit(ComplaintError(e.toString()));
    }
  }

  Future<void> _onCreateComplaint(
    CreateComplaintEvent event,
    Emitter<ComplaintState> emit,
  ) async {
    emit(ComplaintLoading());
    try {
      await createComplaint(event.complaint);
      final list = await getComplaints(
        status: event.status,
        priority: event.priority,
        type: event.type,
        employeeId: event.employeeId,
        currentUserId: event.currentUserId,
        isAdmin: event.isAdmin,
        mineOnly: event.mineOnly,
        searchQuery: event.searchQuery,
      );
      emit(ComplaintLoaded(list));
    } catch (e) {
      emit(ComplaintError(e.toString()));
    }
  }

  Future<void> _onUpdateComplaint(
    UpdateComplaintEvent event,
    Emitter<ComplaintState> emit,
  ) async {
    emit(ComplaintLoading());
    try {
      await updateComplaint(event.complaint);
      final list = await getComplaints(
        status: event.status,
        priority: event.priority,
        type: event.type,
        employeeId: event.employeeId,
        currentUserId: event.currentUserId,
        isAdmin: event.isAdmin,
        mineOnly: event.mineOnly,
        searchQuery: event.searchQuery,
      );
      emit(ComplaintLoaded(list));
    } catch (e) {
      emit(ComplaintError(e.toString()));
    }
  }

  Future<void> _onDeleteComplaint(
    DeleteComplaintEvent event,
    Emitter<ComplaintState> emit,
  ) async {
    emit(ComplaintLoading());
    try {
      await deleteComplaint(event.id);
      final list = await getComplaints(
        status: event.status,
        priority: event.priority,
        type: event.type,
        employeeId: event.employeeId,
        currentUserId: event.currentUserId,
        isAdmin: event.isAdmin,
        mineOnly: event.mineOnly,
        searchQuery: event.searchQuery,
      );
      emit(ComplaintLoaded(list));
    } catch (e) {
      emit(ComplaintError(e.toString()));
    }
  }

  Future<void> _onLoadCustomerComplaints(
    LoadCustomerComplaintsEvent event,
    Emitter<ComplaintState> emit,
  ) async {
    emit(ComplaintLoading());
    try {
      final list = await getComplaintsByCustomer(event.customerId);
      emit(ComplaintLoaded(list));
    } catch (e) {
      emit(ComplaintError(e.toString()));
    }
  }
}

