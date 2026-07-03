import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/features/settings/domain/entities/app_settings_entity.dart';
import 'package:nasr_isp/features/settings/domain/usecases/get_settings.dart';
import 'package:nasr_isp/features/settings/domain/usecases/update_settings.dart';

// Settings Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class SaveSettingsEvent extends SettingsEvent {
  final AppSettingsEntity settings;

  const SaveSettingsEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

// Settings States
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final AppSettingsEntity settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingsSaving extends SettingsState {
  const SettingsSaving();
}

class SettingsSaved extends SettingsState {
  final AppSettingsEntity settings;

  const SettingsSaved(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Settings BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final UpdateSettings updateSettings;

  SettingsBloc({
    required this.getSettings,
    required this.updateSettings,
  }) : super(const SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<SaveSettingsEvent>(_onSaveSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final settings = await getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(message: 'Failed to load settings: $e'));
    }
  }

  Future<void> _onSaveSettings(
    SaveSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsSaving());
    try {
      await updateSettings(event.settings);
      // Give Firestore a small delay to propagate or just load the updated data
      final updated = await getSettings();
      emit(SettingsSaved(updated));
      emit(SettingsLoaded(updated));
    } catch (e) {
      emit(SettingsError(message: 'Failed to save settings: $e'));
    }
  }
}
