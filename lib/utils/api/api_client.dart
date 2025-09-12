import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class ApiClient {
  Map<String, String> _headers({Map<String, String>? extra, bool json = true}) => {
        'accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        ...?extra,
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Constants.baseUrl.endsWith('/')
        ? Constants.baseUrl.substring(0, Constants.baseUrl.length - 1)
        : Constants.baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p').replace(queryParameters: query);
  }

  Future<http.Response> get(String path, {Map<String, String>? query}) {
    return http.get(_uri(path, query), headers: _headers(json: false));
  }

  Future<http.Response> post(String path, {Object? body, bool isForm = false}) {
    final uri = _uri(path);

    if (isForm) {
      // フォーム送信（x-www-form-urlencoded）
      // body は Map<String, String> を想定
      return http.post(
        uri,
        headers: {
          ..._headers(json: false),
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
    }

    // JSON送信（application/json）
    final encoded = (body == null || body is String) ? body : jsonEncode(body);
    return http.post(
      uri,
      headers: _headers(), // Content-Type: application/json
      body: encoded,
    );
  }

  Future<http.Response> put(String path, {Object? body}) {
    final encoded = (body == null || body is String) ? body : jsonEncode(body);
    return http.put(_uri(path), headers: _headers(), body: encoded);
  }

  Future<http.Response> delete(String path, {Map<String, String>? query}) {
    return http.delete(_uri(path, query), headers: _headers(json: false));
  }
}