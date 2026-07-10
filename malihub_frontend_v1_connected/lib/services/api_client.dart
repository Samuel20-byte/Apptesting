import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_exception.dart';

/// Thin wrapper around package:http that:
/// - prefixes every call with ApiConfig.baseUrl
/// - attaches "Authorization: Bearer <token>" once a user is logged in
/// - decodes JSON responses and throws ApiException with the backend's
///   own message on non-2xx responses, so screens can show something
///   useful in a SnackBar instead of a raw stack trace.
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  static const _tokenKey = 'malihub_auth_token';

  String? _cachedToken;

  Future<String?> get token async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _headers() async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final full = '${ApiConfig.baseUrl}/$cleanPath';
    final uri = Uri.parse(full);
    if (query == null || query.isEmpty) return uri;
    final stringQuery = query.map((k, v) => MapEntry(k, v.toString()));
    return uri.replace(queryParameters: stringQuery);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  void _throwIfError(http.Response response, dynamic decoded) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String message = 'Something went wrong (${response.statusCode})';
    if (decoded is Map<String, dynamic> && decoded['message'] != null) {
      message = decoded['message'].toString();
    }
    throw ApiException(response.statusCode, message);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await http
        .get(_uri(path, query), headers: await _headers())
        .timeout(ApiConfig.timeout);
    final decoded = _decode(response);
    _throwIfError(response, decoded);
    return decoded;
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http
        .post(_uri(path), headers: await _headers(), body: jsonEncode(body ?? {}))
        .timeout(ApiConfig.timeout);
    final decoded = _decode(response);
    _throwIfError(response, decoded);
    return decoded;
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await http
        .put(_uri(path), headers: await _headers(), body: jsonEncode(body ?? {}))
        .timeout(ApiConfig.timeout);
    final decoded = _decode(response);
    _throwIfError(response, decoded);
    return decoded;
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http
        .patch(_uri(path), headers: await _headers(), body: jsonEncode(body ?? {}))
        .timeout(ApiConfig.timeout);
    final decoded = _decode(response);
    _throwIfError(response, decoded);
    return decoded;
  }

  Future<void> delete(String path) async {
    final response =
        await http.delete(_uri(path), headers: await _headers()).timeout(ApiConfig.timeout);
    final decoded = _decode(response);
    _throwIfError(response, decoded);
  }
}
