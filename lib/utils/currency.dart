import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/features/settings/bloc/settings_bloc.dart';
import 'package:sales_app/features/settings/bloc/settings_state.dart';
import 'package:sales_app/features/settings/data/app_settings.dart';

class CurrencyFmt {
  /// Returns a web-safe formatted money string using the current settings.
  /// We explicitly format the numeric part and prepend the symbol from DB,
  /// because browser Intl may ignore custom symbols for some locales.
  static String format(BuildContext context, num amount, {bool includeCode = false}) {
    final s = _settings(context);
    // Build purely numeric string with fixed fraction digits from settings
    final f = NumberFormat.decimalPattern(s.currencyLocale)
      ..minimumFractionDigits = s.fractionDigits
      ..maximumFractionDigits = s.fractionDigits;
    final numeric = f.format(amount);

    final symbol = (s.currencySymbol.isNotEmpty ? s.currencySymbol : s.currencyCode).trim();
    if (includeCode && s.currencyCode.isNotEmpty && !symbol.toUpperCase().contains(s.currencyCode.toUpperCase())) {
      // Example: "TSh 60,000 (TZS)"
      return '$symbol $numeric (${s.currencyCode})';
    }
    // Default "TSh 60,000"
    return '$symbol $numeric';
  }

  static AppSettings _settings(BuildContext context) {
    final st = context.read<SettingsBloc>().state;
    if (st is SettingsLoaded) return st.settings;
    if (st is SettingsSaved) return st.settings;
    // Fallback before settings load finishes (e.g., initial boot)
    return AppSettings.fallback;
  }
}

/// Drop-in text that automatically reacts to currency settings changes.
/// Use this everywhere you show amounts so the UI updates when settings change.
class MoneyText extends StatelessWidget {
  final num amount;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool includeCode;

  const MoneyText({
    super.key,
    required this.amount,
    this.style,
    this.textAlign,
    this.includeCode = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (p, n) => n is SettingsLoaded || n is SettingsSaved,
      builder: (context, state) {
        final text = CurrencyFmt.format(context, amount, includeCode: includeCode);
        return Text(text, style: style, textAlign: textAlign);
      },
    );
  }
}