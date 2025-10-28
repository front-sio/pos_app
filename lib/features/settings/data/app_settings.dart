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

  // Global default: KMF / CF / fr-KM / 0
  static const fallback = AppSettings(
    currencyCode: 'KMF',
    currencySymbol: 'CF',
    currencyLocale: 'fr-KM',
    fractionDigits: 0,
  );

  AppSettings copyWith({
    String? currencyCode,
    String? currencySymbol,
    String? currencyLocale,
    int? fractionDigits,
  }) {
    return AppSettings(
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyLocale: currencyLocale ?? this.currencyLocale,
      fractionDigits: fractionDigits ?? this.fractionDigits,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final digitsRaw = json['fraction_digits'];
    final digits = digitsRaw is int ? digitsRaw : int.tryParse('${digitsRaw ?? 0}') ?? 0;

    return AppSettings(
      currencyCode: (json['currency_code'] ?? 'KMF').toString(),
      currencySymbol: (json['currency_symbol'] ?? 'CF').toString(),
      currencyLocale: (json['currency_locale'] ?? 'fr-KM').toString(),
      fractionDigits: digits,
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
