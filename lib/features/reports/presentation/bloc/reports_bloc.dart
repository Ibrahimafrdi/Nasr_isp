import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportsEvent extends ReportsEvent {
  const LoadReportsEvent();
}

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsLoaded extends ReportsState {
  const ReportsLoaded();

  @override
  List<Object?> get props => [];
}

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc() : super(const ReportsInitial()) {
    on<LoadReportsEvent>(_onLoadReports);
  }

  Future<void> _onLoadReports(
    LoadReportsEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    emit(const ReportsLoaded());
  }
}
