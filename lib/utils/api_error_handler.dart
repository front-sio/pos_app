import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Muda umeisha! Server inachukua muda mrefu kujibu. Tafadhali jaribu tena.';
    }
    
    if (error is SocketException) {
      return 'Imeshindwa kuunganisha na server. Angalia muunganisho wako wa mtandao.';
    }
    
    if (error is http.ClientException) {
      return 'Tatizo la muunganisho. Tafadhali hakikisha una mtandao mzuri.';
    }
    
    if (error is FormatException) {
      return 'Tatizo la kusoma data kutoka server. Tafadhali jaribu tena.';
    }
    
    return 'Tatizo limetokea. Tafadhali jaribu tena baadaye.';
  }

  static String getHttpErrorMessage(int statusCode, {String? defaultMessage}) {
    switch (statusCode) {
      case 400:
        return 'Taarifa ulizotuma si sahihi. Tafadhali angalia na jaribu tena.';
      case 401:
        return 'Huna ruhusa. Tafadhali ingia tena.';
      case 403:
        return 'Hauruhusiwi kufanya tendo hili.';
      case 404:
        return 'Huduma hii haipatikani kwa sasa. Tafadhali jaribu tena.';
      case 408:
        return 'Ombi limechukua muda mrefu. Tafadhali jaribu tena.';
      case 422:
        return 'Taarifa ulizotuma hazikukubaliwa. Angalia na jaribu tena.';
      case 429:
        return 'Umetuma maombi mengi. Tafadhali subiri kidogo kabla ya kujaribu tena.';
      case 500:
        return 'Tatizo la server. Tafadhali jaribu tena baadaye.';
      case 502:
        return 'Huduma haipatikani kwa sasa. Tafadhali jaribu tena baadaye.';
      case 503:
        return 'Huduma iko chini kwa matengenezo. Tafadhali jaribu tena baadaye.';
      case 504:
        return 'Server inachukua muda mrefu kujibu. Tafadhali jaribu tena.';
      default:
        return defaultMessage ?? 'Tatizo limetokea ($statusCode). Tafadhali jaribu tena.';
    }
  }

  static Future<T> handleApiCall<T>({
    required Future<T> Function() apiCall,
    required String operationName,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await apiCall().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Ombi la $operationName limechukua muda mrefu',
            timeout,
          );
        },
      );
    } on TimeoutException {
      throw ApiException(
        'Muda umeisha! $operationName inachukua muda mrefu. Tafadhali jaribu tena.',
        type: ApiErrorType.timeout,
      );
    } on SocketException {
      throw ApiException(
        'Imeshindwa kuunganisha na server wakati wa $operationName. Angalia muunganisho wako.',
        type: ApiErrorType.network,
      );
    } on http.ClientException {
      throw ApiException(
        'Tatizo la muunganisho wakati wa $operationName. Tafadhali jaribu tena.',
        type: ApiErrorType.network,
      );
    } on FormatException {
      throw ApiException(
        'Tatizo la kusoma data ya $operationName. Tafadhali jaribu tena.',
        type: ApiErrorType.parsing,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Tatizo limetokea wakati wa $operationName. Tafadhali jaribu tena.',
        type: ApiErrorType.unknown,
        originalError: e,
      );
    }
  }

  static Future<http.Response> handleHttpRequest({
    required Future<http.Response> Function() request,
    required String operationName,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final response = await request().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Ombi la $operationName limechukua muda mrefu',
            timeout,
          );
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      throw ApiException(
        getHttpErrorMessage(response.statusCode),
        type: ApiErrorType.http,
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw ApiException(
        'Muda umeisha! $operationName inachukua muda mrefu. Tafadhali jaribu tena.',
        type: ApiErrorType.timeout,
      );
    } on SocketException {
      throw ApiException(
        'Huduma haipatikani. Tafadhali angalia kama server inafanya kazi.',
        type: ApiErrorType.network,
      );
    } on http.ClientException {
      throw ApiException(
        'Imeshindwa kuunganisha na server. Angalia muunganisho wako.',
        type: ApiErrorType.network,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Tatizo limetokea wakati wa $operationName. Tafadhali jaribu tena.',
        type: ApiErrorType.unknown,
        originalError: e,
      );
    }
  }
}

enum ApiErrorType {
  network,
  timeout,
  http,
  parsing,
  validation,
  unknown,
}

class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;
  final dynamic originalError;

  ApiException(
    this.message, {
    required this.type,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;

  bool get isNetworkError => type == ApiErrorType.network;
  bool get isTimeoutError => type == ApiErrorType.timeout;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;
}
