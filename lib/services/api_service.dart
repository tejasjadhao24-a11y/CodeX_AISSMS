import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';


class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static String get baseUrl => AppConfig.serverUrl;


  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      'bypass-tunnel-reminder': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };

  }

  Future<dynamic> get(String endpoint, {int retries = 2}) async {
    for (int i = 0; i <= retries; i++) {
      try {
        final response = await http
            .get(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders())
            .timeout(const Duration(seconds: 10));
        return _processResponse(response);
      } on ApiException {
        rethrow;
      } catch (e) {
        if (i == retries) {
          throw ApiException('Connection failed. Please check your internet or if server is running.');
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body, {int retries = 2}) async {
    for (int i = 0; i <= retries; i++) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl$endpoint'),
              headers: await _getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 10));
        return _processResponse(response);
      } on ApiException {
        rethrow;
      } catch (e) {
        if (i == retries) {
          throw ApiException('Connection failed. Please check your internet or if server is running.');
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body, {int retries = 2}) async {
    for (int i = 0; i <= retries; i++) {
      try {
        final response = await http
            .patch(
              Uri.parse('$baseUrl$endpoint'),
              headers: await _getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 10));
        return _processResponse(response);
      } on ApiException {
        rethrow;
      } catch (e) {
        if (i == retries) {
          throw ApiException('Connection failed. Please check your internet or if server is running.');
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<dynamic> delete(String endpoint, {int retries = 2}) async {
    for (int i = 0; i <= retries; i++) {
      try {
        final response = await http
            .delete(
              Uri.parse('$baseUrl$endpoint'),
              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));
        return _processResponse(response);
      } on ApiException {
        rethrow;
      } catch (e) {
        if (i == retries) {
          throw ApiException('Connection failed. Please check your internet or if server is running.');
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  dynamic _processResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is Map && body.containsKey('data')) {
          return body['data'];
        }
        return body;
      } else if (response.statusCode == 401) {
        // DON'T clear token here - just throw error
        throw ApiException(body['error'] ?? body['msg'] ?? 'Unauthorized');
      } else if (response.statusCode == 404) {
        throw ApiException(body['error'] ?? 'Not found');
      } else if (response.statusCode >= 500) {
        throw ApiException('Server error. Please try again.');
      } else {
        throw ApiException(
          body['error'] ?? body['message'] ?? 'Something went wrong',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Response error: ${e.toString()}');
    }
  }
}

