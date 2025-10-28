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
        } else {
          emit(SettingsLoaded(AppSettings.fallback, _currencies));
        }
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    });

    on<SaveSettings>((event, emit) async {
      final List<Map<String, dynamic>> currentCurrencies = _currencies.isNotEmpty ? _currencies :
        (state is SettingsLoaded) ? (state as SettingsLoaded).currencies : <Map<String, dynamic>>[];

      emit(SettingsSaving(event.settings, currentCurrencies));
      try {
        final Map<String, dynamic> meta = currentCurrencies.firstWhere(
            (c) => c['code'] == event.settings.currencyCode,
            orElse: () => <String, dynamic>{});
        final locale = meta['locale'] ?? event.settings.currencyLocale;
        final settingsWithCorrectLocale = event.settings.copyWith(
          currencyLocale: locale,
        );
        
        final updated = await service.updateSettings(settingsWithCorrectLocale);
        emit(SettingsSaved(updated, _currencies));
        emit(SettingsLoaded(updated, _currencies));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    });
  }
}
