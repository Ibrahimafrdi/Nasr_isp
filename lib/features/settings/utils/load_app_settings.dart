import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/features/settings/domain/entities/app_settings_entity.dart';
import 'package:nasr_isp/features/settings/presentation/bloc/settings_bloc.dart';

/// Loads the latest company settings through the app-wide [SettingsBloc].
///
/// The root bloc is never loaded at startup and the Settings page uses its own
/// bloc, so callers that need company details (receipts, reminders) ask for a
/// fresh load here. Falls back to defaults if loading fails or times out.
Future<AppSettingsEntity> loadAppSettings(BuildContext context) async {
  final bloc = context.read<SettingsBloc>();
  final result = bloc.stream
      .firstWhere((s) => s is SettingsLoaded || s is SettingsError)
      .timeout(const Duration(seconds: 6));
  bloc.add(const LoadSettingsEvent());
  try {
    final state = await result;
    if (state is SettingsLoaded) return state.settings;
  } catch (_) {
    // fall through to defaults
  }
  return AppSettingsEntity.defaults();
}
