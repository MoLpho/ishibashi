import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class ApiClient {
  Map<String, String> _headers({Map<String, String>? extra, bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        ...?extra,
      };

  Future<http.Response> get(String path, {Map<String, String>? query}) {
    final uri = Uri.parse('${Constants.baseUrl}$path')
        .replace(queryParameters: query);
    return http.get(uri, headers: _headers(json: false));
  }

  Future<http.Response> post(String path, {Object? body, bool isForm = false}) {
    final headers = _headers(
      json: !isForm,
      extra: isForm
          ? {'Content-Type': 'application/x-www-form-urlencoded'}
          : null,
    );
    final uri = Uri.parse('${Constants.baseUrl}$path');
    return http.post(uri, headers: headers, body: body);
  }

  Future<http.Response> put(String path, {Object? body}) {
    final uri = Uri.parse('${Constants.baseUrl}$path');
    return http.put(uri, headers: _headers(), body: jsonEncode(body));
  }

  Future<http.Response> delete(String path) {
    final uri = Uri.parse('${Constants.baseUrl}$path');
    return http.delete(uri, headers: _headers(json: false));
  }
}