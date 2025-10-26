import 'package:equatable/equatable.dart';
import 'package:sales_app/features/settings/data/app_settings.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class LoadCurrencies extends SettingsEvent {
  const LoadCurrencies();
}

class SaveSettings extends SettingsEvent {
  final AppSettings settings;

  const SaveSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}
