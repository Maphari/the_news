import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:the_news/config/env_config.dart';
import 'package:the_news/service/auth_service.dart';

/// Centralized API Client for all HTTP requests
/// This is the SINGLE source of truth for API communication
///
/// Usage:
/// ```dart
/// final response = await ApiClient.instance.get('/articles');
/// final response = await ApiClient.instance.post('/comments', body: {...});
/// ```
class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  final _env = EnvConfig();
  final _authService = AuthService();

  /// Get the backend base URL
  String get baseUrl {
    final url = _env.get('API_BASE_URL');
    if (url == null || url.isEmpty) {
      log('⚠️ WARNING: API_BASE_URL not configured in .env file');
      throw Exception('API_BASE_URL not configured');
    }
    return url;
  }

  /// Build full API URL
  String buildUrl(String endpoint) {
    // Remove leading slash if present to avoid double slashes
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$baseUrl/$cleanEndpoint';
  }

  /// Get common headers (without auth)
  Map<String, String> get _commonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Get authenticated headers
  Future<Map<String, String>> get _authenticatedHeaders async {
    final token = await _authService.getToken();
    return {
      ..._commonHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET request
  Future<http.Response> get(
    String endpoint, {
    bool requiresAuth = false,
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final uri = Uri.parse(buildUrl(endpoint)).replace(queryParameters: queryParams);
      final headers = requiresAuth ? await _authenticatedHeaders : _commonHeaders;

      log('🌐 GET: $uri');
      final response = await http.get(uri, headers: headers).timeout(timeout);
      _logResponse(response);
      return response;
    } catch (e) {
      log('❌ GET Error: $endpoint - $e');
      rethrow;
    }
  }

  /// POST request
  Future<http.Response> post(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = false,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final uri = Uri.parse(buildUrl(endpoint));
      final headers = requiresAuth ? await _authenticatedHeaders : _commonHeaders;

      log('🌐 POST: $uri');
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
      _logResponse(response);
      return response;
    } catch (e) {
      log('❌ POST Error: $endpoint - $e');
      rethrow;
    }
  }

  /// PUT request
  Future<http.Response> put(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = false,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final uri = Uri.parse(buildUrl(endpoint));
      final headers = requiresAuth ? await _authenticatedHeaders : _commonHeaders;

      log('🌐 PUT: $uri');
      final response = await http
          .put(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
      _logResponse(response);
      return response;
    } catch (e) {
      log('❌ PUT Error: $endpoint - $e');
      rethrow;
    }
  }

  /// DELETE request
  Future<http.Response> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final uri = Uri.parse(buildUrl(endpoint));
      final headers = requiresAuth ? await _authenticatedHeaders : _commonHeaders;

      log('🌐 DELETE: $uri');
      final response = await http
          .delete(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);
      _logResponse(response);
      return response;
    } catch (e) {
      log('❌ DELETE Error: $endpoint - $e');
      rethrow;
    }
  }

  /// PATCH request
  Future<http.Response> patch(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = false,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final uri = Uri.parse(buildUrl(endpoint));
      final headers = requiresAuth ? await _authenticatedHeaders : _commonHeaders;

      log('🌐 PATCH: $uri');
      final response = await http
          .patch(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
      _logResponse(response);
      return response;
    } catch (e) {
      log('❌ PATCH Error: $endpoint - $e');
      rethrow;
    }
  }

  /// Log response details
  void _logResponse(http.Response response) {
    final statusIcon = response.statusCode >= 200 && response.statusCode < 300 ? '✅' : '❌';
    log('$statusIcon Response: ${response.statusCode} - ${response.body.length} bytes');
  }

  /// Parse JSON response with error handling
  Map<String, dynamic> parseJson(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      log('❌ JSON Parse Error: $e');
      throw Exception('Failed to parse response: ${response.body}');
    }
  }

  /// Check if response is successful
  bool isSuccess(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Handle common API errors
  String getErrorMessage(http.Response response) {
    if (isSuccess(response)) return '';

    try {
      final data = parseJson(response);
      return data['message'] ?? data['error'] ?? 'Request failed';
    } catch (e) {
      return 'Request failed with status ${response.statusCode}';
    }
  }
}
