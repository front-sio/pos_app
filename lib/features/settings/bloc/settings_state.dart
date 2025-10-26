import 'package:equatable/equatable.dart';
import 'package:sales_app/features/settings/data/app_settings.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  final List<Map<String, dynamic>> currencies;

  const SettingsLoaded(this.settings, this.currencies);

  @override
  List<Object?> get props => [settings, currencies];
}

class SettingsSaving extends SettingsState {
  final AppSettings settings;
  final List<Map<String, dynamic>> currencies;

  const SettingsSaving(this.settings, this.currencies);

  @override
  List<Object?> get props => [settings, currencies];
}

class SettingsSaved extends SettingsState {
  final AppSettings settings;
  final List<Map<String, dynamic>> currencies;

  const SettingsSaved(this.settings, this.currencies);

  @override
  List<Object?> get props => [settings, currencies];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
