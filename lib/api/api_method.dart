import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as https;

import '../utility/app_messages.dart';

/// Result of every API call. Screens never deal with raw http responses,
/// status codes or exceptions — only [isSuccess], [data] and [message].
class ApiResponse {
  ApiResponse({required this.statusCode, this.data, this.message});

  final int statusCode;
  final dynamic data;
  final String? message;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// A message that is always safe to show to the user.
  String get errorMessage => message ?? AppMessages.unknownError;
}

const _timeout = Duration(seconds: 30);

Map<String, String> get _headers => {
  HttpHeaders.contentTypeHeader: 'application/json',
  HttpHeaders.acceptHeader: 'application/json',
};

Future<ApiResponse> callGetApi({required String endURl}) =>
    _send("GET", endURl, () => https.get(Uri.parse(endURl), headers: _headers));

Future<ApiResponse> callPostApi({required String endURl, required Object body}) =>
    _send("POST", endURl, () => https.post(Uri.parse(endURl), headers: _headers, body: _encode(body)), body);

Future<ApiResponse> callPutApi({required String endURl, required Object body}) =>
    _send("PUT", endURl, () => https.put(Uri.parse(endURl), headers: _headers, body: _encode(body)), body);

Future<ApiResponse> callPatchApi({required String endURl, required Object body}) =>
    _send("PATCH", endURl, () => https.patch(Uri.parse(endURl), headers: _headers, body: _encode(body)), body);

Future<ApiResponse> callDeleteApi({required String endURl}) =>
    _send("DELETE", endURl, () => https.delete(Uri.parse(endURl), headers: _headers));

String _encode(Object body) => body is String ? body : jsonEncode(body);

Future<ApiResponse> _send(String method, String url, Future<https.Response> Function() request, [Object? body]) async {
  kLog(title: "API $method", content: url);
  if (body != null) kLog(title: "REQUEST BODY", content: _encode(body));
  try {
    final response = await request().timeout(_timeout);
    kLog(title: "STATUS CODE", content: "${response.statusCode}");
    kLog(title: "RESPONSE", content: response.body);

    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok && decoded == null && response.body.isNotEmpty) {
      return ApiResponse(statusCode: 422, message: AppMessages.badResponse);
    }

    String? serverMessage;
    if (decoded is Map && decoded['message'] is String && (decoded['message'] as String).isNotEmpty) {
      serverMessage = decoded['message'];
    }

    return ApiResponse(
      statusCode: response.statusCode,
      data: decoded,
      message: ok
          ? serverMessage
          : (response.statusCode >= 500 ? AppMessages.serverError : serverMessage ?? AppMessages.unknownError),
    );
  } on SocketException catch (e) {
    kLog(title: "API ERROR", content: e);
    return ApiResponse(statusCode: -1, message: AppMessages.noInternet);
  } on https.ClientException catch (e) {
    kLog(title: "API ERROR", content: e);
    return ApiResponse(statusCode: -1, message: AppMessages.noInternet);
  } on TimeoutException catch (e) {
    kLog(title: "API ERROR", content: e);
    return ApiResponse(statusCode: -2, message: AppMessages.timeout);
  } catch (e) {
    kLog(title: "API ERROR", content: e);
    return ApiResponse(statusCode: -3, message: AppMessages.unknownError);
  }
}

void kLog({String? title, required Object? content}) {
  if (kDebugMode) {
    log(content.toString(), name: title ?? "");
  }
}
