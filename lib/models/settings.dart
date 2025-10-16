class AppSettings {
  String? brandLogoUrl;       // for admin uploaded logo
  String? appIconUrl;         // for custom app icon
  int? primaryColorValue;     // store as int from Color.value
  String? appName;

  AppSettings({
    this.brandLogoUrl,
    this.appIconUrl,
    this.primaryColorValue,
    this.appName,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        brandLogoUrl: json['brandLogoUrl'],
        appIconUrl: json['appIconUrl'],
        primaryColorValue: json['primaryColorValue'],
        appName: json['appName'],
      );

  Map<String, dynamic> toJson() => {
        'brandLogoUrl': brandLogoUrl,
        'appIconUrl': appIconUrl,
        'primaryColorValue': primaryColorValue,
        'appName': appName,
      };
}
