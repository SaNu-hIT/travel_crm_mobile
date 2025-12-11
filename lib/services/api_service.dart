import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/api_response.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService = StorageService();

  // Get headers with authorization token
  Future<Map<String, String>> getHeaders() async {
    final token = await _storageService.getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint')
          .replace(queryParameters: queryParams);
      
      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(Duration(seconds: AppConfig.apiTimeout));

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        error: 'No internet connection',
      );
    } on HttpException {
      return ApiResponse<T>(
        success: false,
        error: 'Server error',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'An error occurred: ${e.toString()}',
      );
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
      
      final response = await http
          .post(
            uri,
            headers: await getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: AppConfig.apiTimeout));

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        error: 'No internet connection',
      );
    } on HttpException {
      return ApiResponse<T>(
        success: false,
        error: 'Server error',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'An error occurred: ${e.toString()}',
      );
    }
  }

  // Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
      
      final response = await http
          .put(
            uri,
            headers: await getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: AppConfig.apiTimeout));

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        error: 'No internet connection',
      );
    } on HttpException {
      return ApiResponse<T>(
        success: false,
        error: 'Server error',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'An error occurred: ${e.toString()}',
      );
    }
  }

  // Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
      
      final response = await http
          .delete(uri, headers: await getHeaders())
          .timeout(Duration(seconds: AppConfig.apiTimeout));

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        error: 'No internet connection',
      );
    } on HttpException {
      return ApiResponse<T>(
        success: false,
        error: 'Server error',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'An error occurred: ${e.toString()}',
      );
    }
  }

  // Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      final decoded = jsonDecode(response.body);
      
      // Check if response is a Map (expected format)
      if (decoded is! Map<String, dynamic>) {
        return ApiResponse<T>(
          success: false,
          error: 'Invalid response format from server',
        );
      }
      
      final responseBody = decoded as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>.fromJson(responseBody, fromJson);
      } else if (response.statusCode == 401) {
        return ApiResponse<T>(
          success: false,
          error: 'Unauthorized. Please login again.',
        );
      } else if (response.statusCode == 403) {
        return ApiResponse<T>(
          success: false,
          error: responseBody['error'] as String? ?? 'Access denied',
        );
      } else if (response.statusCode == 404) {
        return ApiResponse<T>(
          success: false,
          error: responseBody['error'] as String? ?? 'Not found',
        );
      } else {
        return ApiResponse<T>(
          success: false,
          error: responseBody['error'] as String? ?? 'An error occurred',
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'Failed to parse response: ${e.toString()}',
      );
    }
  }
}
