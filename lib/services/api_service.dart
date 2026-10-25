import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];

    if (url == null || url.isEmpty) {
      throw Exception('API_BASE_URL is missing from .env');
    }

    return url;
  }

  static Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> body, {
        String? accessToken,
      }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null)
          'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> get(
      String endpoint, {
        String? accessToken,
      }) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null)
          'Authorization': 'Bearer $accessToken',
      },
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
      String endpoint,
      Map<String, dynamic> body, {
        String? accessToken,
      }) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null)
          'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(
      http.Response response,
      ) {
    debugPrint('API URL: ${response.request?.url}');
    debugPrint('API Status: ${response.statusCode}');
    debugPrint('API Response: ${response.body}');

    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return {'data': data};
    }

    final message = data is Map
        ? data.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n')
        : response.body.isNotEmpty
        ? response.body
        : 'Request failed: ${response.statusCode}';

    throw Exception(
      'HTTP ${response.statusCode}: $message',
    );
  }
}