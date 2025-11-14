import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/purchases/data/purchase_model.dart';
import 'package:sales_app/network/auth_http_client.dart';
import 'package:sales_app/utils/api_error_handler.dart';

class PurchaseService {
  final String baseUrl;
  final http.Client _client;

  PurchaseService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _client = client ?? AuthHttpClient();

  Future<List<Purchase>> getAllPurchases() async {
    try {
      final url = Uri.parse('$baseUrl/products/purchases');
      final res = await _client.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Ombi limechukua muda mrefu');
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded.map((e) => Purchase.fromJson(e as Map<String, dynamic>)).toList();
        }
        debugPrint('[PurchaseService][getAllPurchases] Expected list, got ${decoded.runtimeType}');
        return [];
      } else {
        throw ApiException(
          ApiErrorHandler.getHttpErrorMessage(res.statusCode),
          type: ApiErrorType.http,
          statusCode: res.statusCode,
        );
      }
    } on SocketException {
      throw ApiException(
        'Huduma haipatikani. Tafadhali angalia kama server inafanya kazi na muunganisho wa mtandao.',
        type: ApiErrorType.network,
      );
    } on TimeoutException {
      throw ApiException(
        'Muda umeisha! Server inachukua muda mrefu. Tafadhali jaribu tena.',
        type: ApiErrorType.timeout,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Imeshindwa kuunganisha na server. Angalia muunganisho wako.\nEndpoint: /products/purchases',
        type: ApiErrorType.network,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Tatizo limetokea wakati wa kupakua manunuzi. Tafadhali jaribu tena.',
        type: ApiErrorType.unknown,
        originalError: e,
      );
    }
  }

  // Multi-item purchase creation
  Future<void> createPurchase({
    int? supplierId,
    String status = 'unpaid',
    double? paidAmount,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/products/purchases');

      final payload = <String, dynamic>{
        if (supplierId != null) 'supplier_id': supplierId,
        'status': status,
        if (paidAmount != null) 'paid_amount': paidAmount.toStringAsFixed(2),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'items': items.map((it) {
          return {
            'product_id': it['product_id'],
            'quantity': it['quantity'],
            'price_per_unit': (it['price_per_unit'] as num).toStringAsFixed(2),
          };
        }).toList(),
      };

      final body = jsonEncode(payload);
      debugPrint('[PurchaseService][createPurchase] POST $url');
      debugPrint('[PurchaseService][createPurchase] payload: $body');

      final res = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Ombi limechukua muda mrefu');
        },
      );

      debugPrint('[PurchaseService][createPurchase] status: ${res.statusCode}, response: ${res.body}');

      if (res.statusCode != 201 && res.statusCode != 200) {
        String message = res.body;
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map && decoded['error'] != null) {
            message = decoded['error'].toString();
          } else if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}
        throw ApiException(
          'Imeshindwa kuunda manunuzi: $message',
          type: ApiErrorType.http,
          statusCode: res.statusCode,
        );
      }
    } on SocketException {
      throw ApiException(
        'Huduma haipatikani. Tafadhali angalia muunganisho wa mtandao.',
        type: ApiErrorType.network,
      );
    } on TimeoutException {
      throw ApiException(
        'Muda umeisha wakati wa kuunda manunuzi. Tafadhali jaribu tena.',
        type: ApiErrorType.timeout,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Imeshindwa kuunganisha na server wakati wa kuunda manunuzi.',
        type: ApiErrorType.network,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Tatizo limetokea wakati wa kuunda manunuzi. Tafadhali jaribu tena.',
        type: ApiErrorType.unknown,
        originalError: e,
      );
    }
  }

  // Update payment/settlement
  Future<void> updatePurchasePayment({
    required int purchaseId,
    required double paidAmount,
    String? status, // 'paid' | 'unpaid' | 'credited'
  }) async {
    try {
      final url = Uri.parse('$baseUrl/products/purchases/$purchaseId/payment');
      final payload = {
        'paid_amount': paidAmount.toStringAsFixed(2),
        if (status != null) 'status': status,
      };
      final res = await _client.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Ombi limechukua muda mrefu');
        },
      );
      if (res.statusCode != 200) {
        throw ApiException(
          ApiErrorHandler.getHttpErrorMessage(res.statusCode),
          type: ApiErrorType.http,
          statusCode: res.statusCode,
        );
      }
    } on SocketException {
      throw ApiException(
        'Huduma haipatikani. Angalia muunganisho wa mtandao.',
        type: ApiErrorType.network,
      );
    } on TimeoutException {
      throw ApiException(
        'Muda umeisha wakati wa kusasisha malipo. Tafadhali jaribu tena.',
        type: ApiErrorType.timeout,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Imeshindwa kuunganisha na server.',
        type: ApiErrorType.network,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Tatizo limetokea wakati wa kusasisha malipo. Tafadhali jaribu tena.',
        type: ApiErrorType.unknown,
        originalError: e,
      );
    }
  }
}