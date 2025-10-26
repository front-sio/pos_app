import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/settings/bloc/settings_event.dart';
import 'package:sales_app/features/settings/bloc/settings_state.dart';
import 'package:sales_app/features/settings/data/app_settings.dart';
import 'package:sales_app/features/settings/services/settings_service.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService service;

  List<Map<String, dynamic>> _currencies = [];

  SettingsBloc(this.service) : super(SettingsInitial()) {
    on<LoadSettings>((event, emit) async {
      emit(SettingsLoading());
      try {
        final settings = await service.getSettings();
        // Load currencies if we haven't yet
        if (_currencies.isEmpty) {
          _currencies = await service.getCurrencies();
        }
        emit(SettingsLoaded(settings, _currencies));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    });

    on<LoadCurrencies>((event, emit) async {
      try {
        _currencies = await service.getCurrencies();
        if (state is SettingsLoaded) {
          final s = (state as SettingsLoaded).settings;
          emit(SettingsLoaded(s, _currencies));
        }
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    });

    on<SaveSettings>((event, emit) async {
      if (state is SettingsLoaded) {
        final currentCurrencies = (state as SettingsLoaded).currencies;
        emit(SettingsSaving(event.settings, currentCurrencies));
      }
      try {
        final updated = await service.updateSettings(event.settings);
        emit(SettingsSaved(updated, _currencies));
        // Immediately back to loaded
        emit(SettingsLoaded(updated, _currencies));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    });
  }
}
