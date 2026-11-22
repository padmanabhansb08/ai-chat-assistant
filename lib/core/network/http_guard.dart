import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../error/failures.dart';

/// Performs a POST and maps every transport / HTTP-level problem to a [Failure].
Future<http.Response> guardedPost(
  http.Client client,
  Uri uri, {
  required Map<String, String> headers,
  required Object body,
  Duration timeout = const Duration(seconds: 60),
}) async {
  final http.Response response;
  try {
    response = await client
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(timeout);
  } on TimeoutException {
    throw const TimeoutFailure();
  } on SocketException {
    throw const NetworkFailure();
  } on http.ClientException {
    throw const NetworkFailure();
  }

  final code = response.statusCode;
  if (code >= 200 && code < 300) return response;
  if (code == 401 || code == 403) throw const AuthFailure();
  if (code == 429) throw const RateLimitFailure();
  throw ServerFailure(_extractMessage(response.body) ?? 'Server error ($code).');
}

/// Decodes a JSON object body or throws [InvalidResponseFailure].
Map<String, dynamic> decodeJsonObject(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException {
    // fall through
  }
  throw const InvalidResponseFailure();
}

String? _extractMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic> && error['message'] is String) {
        return error['message'] as String;
      }
    }
  } on FormatException {
    // ignore
  }
  return null;
}
