class AppSettings {
  final String currencyCode;
  final String currencySymbol;
  final String currencyLocale;
  final int fractionDigits;

  const AppSettings({
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyLocale,
    required this.fractionDigits,
  });

  static const fallback = AppSettings(
    currencyCode: 'TZS',
    currencySymbol: 'TSh',
    currencyLocale: 'sw_TZ',
    fractionDigits: 0,
  );

  AppSettings copyWith({
    String? currencyCode,
    String? currencySymbol,
    String? currencyLocale,
    int? fractionDigits,
  }) =>
      AppSettings(
        currencyCode: currencyCode ?? this.currencyCode,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        currencyLocale: currencyLocale ?? this.currencyLocale,
        fractionDigits: fractionDigits ?? this.fractionDigits,
      );

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      currencyCode: json['currency_code'] ?? 'TZS',
      currencySymbol: json['currency_symbol'] ?? 'TSh',
      currencyLocale: json['currency_locale'] ?? 'sw_TZ',
      fractionDigits: json['fraction_digits'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'currency_locale': currencyLocale,
      'fraction_digits': fractionDigits,
    };
  }
}
