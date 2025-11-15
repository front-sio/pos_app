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

  void _syncFromState(SettingsState state) {
    if (state is SettingsLoaded) {
      _lastCurrencies = state.currencies;
      _selectedCode = state.settings.currencyCode.toUpperCase();
      final meta = _metaFor(state.currencies, _selectedCode);
      final dbSymbol = (meta?['symbol'] ?? state.settings.currencySymbol).toString();
      if (_symbolCtrl.text != dbSymbol) _symbolCtrl.text = dbSymbol;
      _editing = state.settings;
    } else if (state is SettingsSaving) {
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
              const SnackBar(content: Text('Settings saved successfully')),
            );
          }
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Unable to save settings. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          _syncFromState(state);
        },
        buildWhen: (_, s) => s is SettingsLoading || s is SettingsLoaded || s is SettingsSaving,
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Map<String, dynamic>> currencies;
          final AppSettings current;

          if (state is SettingsLoaded) {
            currencies = state.currencies;
            current = state.settings;
          } else if (state is SettingsSaving) {
            currencies = _lastCurrencies;
            current = state.settings;
          } else {
            currencies = _lastCurrencies;
            current = _editing;
          }

          _editing = current;
          _selectedCode = _selectedCode.toUpperCase();

          final meta = _metaFor(currencies, _selectedCode);
          final dbSymbol = (meta?['symbol'] ?? _editing.currencySymbol).toString();
          final dbDigits =
              int.tryParse('${meta?['fraction_digits'] ?? _editing.fractionDigits}') ??
                  _editing.fractionDigits;
          final dbLocale = (meta?['locale'] ?? _editing.currencyLocale).toString();

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
                    final newLocale = (m?['locale'] ?? _editing.currencyLocale).toString();
                    setState(() {
                      _selectedCode = val.toUpperCase();
                      _editing = _editing.copyWith(
                        currencyCode: _selectedCode,
                        currencySymbol: newSymbol,
                        currencyLocale: newLocale,
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
                TextFormField(
                  key: ValueKey('digits_${_selectedCode}_$dbDigits'),
                  initialValue: '$dbDigits',
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Fraction digits (from DB)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey('locale_${_selectedCode}_$dbLocale'),
                  initialValue: dbLocale,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Locale (from DB)'),
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
