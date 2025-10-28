import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/settings/data/app_settings.dart';
import 'package:sales_app/network/auth_http_client.dart';

class SettingsService {
  final String baseUrl;
  final AuthHttpClient _client;

  // ETag per-URL ili kuepuka kuchanganya matokeo ya queries tofauti
  static final Map<String, String> _etagByUrl = {};
  static final Map<String, List<Map<String, dynamic>>> _cacheByUrl = {};

  SettingsService({
    String? baseUrl,
    AuthHttpClient? client,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _client = client ?? AuthHttpClient();

  Map<String, String> get _jsonHeaders => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Exception _err(String prefix, http.Response res) {
    String msg = res.body;
    try {
      final d = jsonDecode(res.body);
      if (d is Map && (d['error'] != null || d['message'] != null)) {
        msg = (d['error'] ?? d['message']).toString();
      }
    } catch (_) {}
    return Exception('$prefix (${res.statusCode}): $msg');
  }

  Future<AppSettings> getSettings() async {
    final uri = Uri.parse('$baseUrl/settings');
    final res = await _client
        .get(uri, headers: _jsonHeaders)
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw _err('Failed to load settings', res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AppSettings.fromJson(data);
  }

  Future<AppSettings> updateSettings(AppSettings s) async {
    final uri = Uri.parse('$baseUrl/settings');
    final res = await _client
        .put(uri, headers: _jsonHeaders, body: jsonEncode(s.toJson()))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw _err('Failed to update settings', res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AppSettings.fromJson(data);
  }

  /// Orodha ya sarafu (catalog) kutoka DB
  Future<List<Map<String, dynamic>>> getCurrencies({
    String? q,
    String? region,
    bool? active,
    int limit = 500,
  }) async {
    final qp = <String, String>{
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (region != null && region.trim().isNotEmpty) 'region': region.trim(),
      if (active != null) 'active': active.toString(),
      'limit': limit.clamp(1, 1000).toString(),
    };

    final uri = Uri.parse('$baseUrl/settings/currencies').replace(
      queryParameters: qp.isEmpty ? null : qp,
    );
    final urlKey = uri.toString();

    final headers = {
      ..._jsonHeaders,
      if (_etagByUrl[urlKey] != null)
        HttpHeaders.ifNoneMatchHeader: _etagByUrl[urlKey]!,
    };

    final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 20));

    if (res.statusCode == 304 && _cacheByUrl[urlKey] != null) {
      return _cacheByUrl[urlKey]!;
    }

    if (res.statusCode != 200) throw _err('Failed to load currencies', res);

    final etag = res.headers[HttpHeaders.etagHeader];
    if (etag != null && etag.isNotEmpty) {
      _etagByUrl[urlKey] = etag;
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('Failed to load currencies (unexpected payload)');
    }

    final list = decoded
        .whereType<Map>()
        .map((e) => _sanitizeCurrencyMap(e))
        .toList()
        .cast<Map<String, dynamic>>();

    _cacheByUrl[urlKey] = list;
    return list;
  }

  Map<String, dynamic> _sanitizeCurrencyMap(Map raw) {
    final code = (raw['code'] ?? '').toString();
    final name = (raw['name'] ?? code).toString();
    final symbol = (raw['symbol'] ?? code).toString();
    final digits = int.tryParse('${raw['fraction_digits'] ?? 2}') ?? 2;

    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'fraction_digits': digits,
      if (raw.containsKey('numeric_code')) 'numeric_code': raw['numeric_code'],
      if (raw.containsKey('countries')) 'countries': raw['countries'],
      if (raw.containsKey('is_active')) 'is_active': raw['is_active'],
    };
  }
}