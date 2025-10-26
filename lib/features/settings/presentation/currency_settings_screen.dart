import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/settings/bloc/settings_bloc.dart';
import 'package:sales_app/features/settings/bloc/settings_event.dart';
import 'package:sales_app/features/settings/bloc/settings_state.dart';
import 'package:sales_app/features/settings/data/app_settings.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  AppSettings _editing = AppSettings.fallback;
  String _selectedCode = AppSettings.fallback.currencyCode;
  final _symbolCtrl = TextEditingController();

  // Hifadhi currencies za mwisho ili zitumike wakati wa SettingsSaving
  List<Map<String, dynamic>> _lastCurrencies = const [];

  @override
  void initState() {
    super.initState();
    final st = context.read<SettingsBloc>().state;
    if (st is SettingsLoaded) {
      _editing = st.settings;
      _selectedCode = st.settings.currencyCode;
      _symbolCtrl.text = st.settings.currencySymbol;
      _lastCurrencies = st.currencies;
    } else {
      context.read<SettingsBloc>().add(const LoadSettings());
    }
    context.read<SettingsBloc>().add(const LoadCurrencies());
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _metaFor(List<Map<String, dynamic>> currencies, String code) {
    if (code.isEmpty) return null;
    final up = code.toUpperCase();
    try {
      return currencies.firstWhere(
        (c) => (c['code']?.toString().toUpperCase() ?? '') == up,
      );
    } catch (_) {
      return null;
    }
  }

  // Sync symbol tu pale ambapo code ya Bloc inalingana na selection ya sasa
  void _syncFromState(SettingsState state) {
    if (state is SettingsLoaded) {
      _lastCurrencies = state.currencies;
      // endapo Loaded baada ya Save, songa local selection ili iakisi persisted value
      _selectedCode = state.settings.currencyCode.toUpperCase();
      final meta = _metaFor(state.currencies, _selectedCode);
      final dbSymbol = (meta?['symbol'] ?? state.settings.currencySymbol).toString();
      if (_symbolCtrl.text != dbSymbol) _symbolCtrl.text = dbSymbol;
      // pia weka kwenye _editing ili Save inayofuata iwe na data ya sasa
      _editing = state.settings;
    } else if (state is SettingsSaving) {
      // wakati Saving, huenda symbol ibadilike; weka tu symbol kutoka settings ya sasa
      if (_symbolCtrl.text != state.settings.currencySymbol) {
        _symbolCtrl.text = state.settings.currencySymbol;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Currency Settings')),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listenWhen: (_, s) =>
            s is SettingsLoaded || s is SettingsSaving || s is SettingsSaved || s is SettingsError,
        listener: (context, state) {
          if (state is SettingsSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Currency saved')),
            );
          }
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
          _syncFromState(state);
        },
        buildWhen: (_, s) => s is SettingsLoading || s is SettingsLoaded || s is SettingsSaving,
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Chukua currencies na settings za sasa kwa usahihi
          final List<Map<String, dynamic>> currencies;
          final AppSettings current;

          if (state is SettingsLoaded) {
            currencies = state.currencies;
            current = state.settings;
          } else if (state is SettingsSaving) {
            // wakati Saving: tumia currencies za mwisho zilizohifadhiwa
            currencies = _lastCurrencies;
            current = state.settings;
          } else {
            // fallback isiyowezekana kutokana na buildWhen, lakini salama
            currencies = _lastCurrencies;
            current = _editing;
          }

          _editing = current; // endelea na editing kulingana na state
          // Hakikisha _selectedCode ipo uppercase
          _selectedCode = _selectedCode.toUpperCase();

          final meta = _metaFor(currencies, _selectedCode);
          final dbSymbol = (meta?['symbol'] ?? _editing.currencySymbol).toString();
          final dbDigits =
              int.tryParse('${meta?['fraction_digits'] ?? _editing.fractionDigits}') ??
                  _editing.fractionDigits;

          // value ya dropdown lazima ilingane kabisa na item value (case sensitive)
          final availableCodes = currencies
              .map((c) => (c['code']?.toString().toUpperCase() ?? ''))
              .toSet();
          final dropdownValue = availableCodes.contains(_selectedCode) ? _selectedCode : null;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const Text('Choose your default currency.'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: dropdownValue,
                  items: currencies.map((c) {
                    final code = (c['code']?.toString() ?? '').toUpperCase();
                    final name = c['name']?.toString() ?? '';
                    final symbol = c['symbol']?.toString() ?? code;
                    return DropdownMenuItem(
                      value: code,
                      child: Text('$code • $name ($symbol)', maxLines: 1, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final m = _metaFor(currencies, val);
                    final newSymbol = (m?['symbol'] ?? _editing.currencySymbol).toString();
                    final newDigits =
                        int.tryParse('${m?['fraction_digits'] ?? _editing.fractionDigits}') ??
                            _editing.fractionDigits;
                    setState(() {
                      _selectedCode = val.toUpperCase();
                      _editing = _editing.copyWith(
                        currencyCode: _selectedCode,
                        currencySymbol: newSymbol, // symbol auto kutoka DB
                        fractionDigits: newDigits,
                      );
                      _symbolCtrl.text = newSymbol;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Currency'),
                  menuMaxHeight: 420,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _symbolCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Symbol (auto)'),
                ),
                const SizedBox(height: 12),
                // Onyesha digits zilizotokana na DB ili mtumiaji aione (read-only hapa)
                TextFormField(
                  key: ValueKey('digits_${_selectedCode}_$dbDigits'),
                  initialValue: '$dbDigits',
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Fraction digits (from DB)'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: state is SettingsSaving
                      ? null
                      : () => context.read<SettingsBloc>().add(SaveSettings(_editing)),
                  child: Text(state is SettingsSaving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}