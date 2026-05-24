import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class InstallationsEvent extends Equatable {
  const InstallationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadInstallationsEvent extends InstallationsEvent {
  const LoadInstallationsEvent();
}

abstract class InstallationsState extends Equatable {
  const InstallationsState();

  @override
  List<Object?> get props => [];
}

class InstallationsInitial extends InstallationsState {
  const InstallationsInitial();
}

class InstallationsLoading extends InstallationsState {
  const InstallationsLoading();
}

class InstallationsLoaded extends InstallationsState {
  const InstallationsLoaded();

  @override
  List<Object?> get props => [];
}

class InstallationsBloc extends Bloc<InstallationsEvent, InstallationsState> {
  InstallationsBloc() : super(const InstallationsInitial()) {
    on<LoadInstallationsEvent>(_onLoadInstallations);
  }

  Future<void> _onLoadInstallations(
    LoadInstallationsEvent event,
    Emitter<InstallationsState> emit,
  ) async {
    emit(const InstallationsLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    emit(const InstallationsLoaded());
  }
}
