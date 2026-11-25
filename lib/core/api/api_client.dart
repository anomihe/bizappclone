import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Error from the backend or the network, with a message fit to show users.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Laravel validation errors: field → messages.
  final Map<String, List<String>> fieldErrors;

  const ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == null;

  /// First validation message for [field], if any.
  String? errorFor(String field) => fieldErrors[field]?.firstOrNull;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin JSON client for the Bizpaddi Laravel API.
///
/// Every response uses the envelope `{success, message, data, errors?}`;
/// [send] returns `data` (or the whole body when there is no envelope).
class ApiClient {
  final String baseUrl;
  final http.Client _http;

  /// Bearer token from login; null when signed out.
  String? token;

  /// Called when the backend rejects the token (expired / revoked).
  void Function()? onUnauthorized;

  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), ''),
        _http = httpClient ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl/api$p').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => send('GET', path, query: query);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => send('POST', path, body: body);
  Future<dynamic> put(String path, [Map<String, dynamic>? body]) => send('PUT', path, body: body);
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) => send('PATCH', path, body: body);
  Future<dynamic> delete(String path) => send('DELETE', path);

  Future<dynamic> send(String method, String path, {Map<String, dynamic>? query, Map<String, dynamic>? body}) async {
    final request = http.Request(method, _uri(path, query))..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);

    final http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(request).timeout(ApiConfig.timeout));
    } on TimeoutException {
      throw const ApiException('The server took too long to respond. Check your connection and try again.');
    } on SocketException {
      throw const ApiException('No internet connection. Check your network and try again.');
    } on http.ClientException {
      throw const ApiException('Could not reach Bizpaddi. Check your connection and try again.');
    }
    return _decode(res);
  }

  /// Unwraps the `{success, message, data}` envelope or throws [ApiException].
  dynamic _decode(http.Response res) {
    dynamic json;
    if (res.body.isNotEmpty) {
      try {
        json = jsonDecode(res.body);
      } on FormatException {
        json = null;
      }
    }
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    if (res.statusCode == 401) {
      onUnauthorized?.call();
      throw ApiException(map['message'] as String? ?? 'Your session has ended. Please log in again.', statusCode: 401);
    }
    if (res.statusCode >= 400 || map['success'] == false) {
      throw ApiException(_messageFor(res.statusCode, map), statusCode: res.statusCode, fieldErrors: _fieldErrors(map));
    }
    return map.containsKey('data') ? map['data'] : json;
  }

  /// Multipart POST for file uploads (profile picture, chat attachments).
  Future<dynamic> upload(String path, {Map<String, String> fields = const {}, required String fileField, required List<int> bytes, required String filename}) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll({'Accept': 'application/json', if (token != null) 'Authorization': 'Bearer $token'})
      ..fields.addAll(fields)
      ..files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: filename));
    final http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(request).timeout(const Duration(seconds: 60)));
    } on TimeoutException {
      throw const ApiException('The upload took too long. Check your connection and try again.');
    } on SocketException {
      throw const ApiException('No internet connection. Check your network and try again.');
    } on http.ClientException {
      throw const ApiException('Could not reach Bizpaddi. Check your connection and try again.');
    }
    return _decode(res);
  }

  /// Fetches every page of a Laravel paginated list (up to [ApiConfig.maxPages]).
  Future<List<Map<String, dynamic>>> getAllPages(String path, {Map<String, dynamic>? query}) async {
    final out = <Map<String, dynamic>>[];
    for (var page = 1; page <= ApiConfig.maxPages; page++) {
      final data = await get(path, query: {...?query, 'page': page});
      final (items, lastPage) = parsePage(data);
      out.addAll(items);
      if (page >= lastPage) break;
    }
    return out;
  }

  /// Accepts a Laravel paginator (`{data: [...], last_page}`) or a plain list.
  static (List<Map<String, dynamic>>, int) parsePage(dynamic data) {
    if (data is List) return (data.whereType<Map<String, dynamic>>().toList(), 1);
    if (data is Map<String, dynamic>) {
      final items = (data['data'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
      final last = (data['last_page'] as num?)?.toInt() ?? 1;
      return (items, last);
    }
    return (const [], 1);
  }

  static String _messageFor(int code, Map<String, dynamic> map) {
    final msg = map['message'] as String?;
    if (code == 422) {
      return _fieldErrors(map).values.expand((e) => e).firstOrNull ?? msg ?? 'Please check the details and try again.';
    }
    if (msg != null && msg.isNotEmpty && code < 500) return msg;
    return switch (code) {
      403 => 'You don’t have permission to do that.',
      404 => 'That item could not be found.',
      429 => 'Too many attempts. Please wait a moment and try again.',
      >= 500 => 'Bizpaddi is having trouble right now. Please try again shortly.',
      _ => msg ?? 'Something went wrong. Please try again.',
    };
  }

  static Map<String, List<String>> _fieldErrors(Map<String, dynamic> map) {
    final errors = map['errors'];
    if (errors is! Map) return const {};
    return errors.map((k, v) => MapEntry('$k', v is List ? v.map((e) => '$e').toList() : ['$v']));
  }
}
