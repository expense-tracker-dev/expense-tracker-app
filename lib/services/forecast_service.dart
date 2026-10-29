import 'dart:convert';

import 'package:http/http.dart' as http;

class ForecastService {
  static const String _baseUrl = 'https://ml-reposit.onrender.com';

  final http.Client _client;

  ForecastService({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getDailyPrediction() {
    return _getPrediction('/predict/daily');
  }

  Future<Map<String, dynamic>> getMonthlyPrediction() {
    return _getPrediction('/predict/monthly');
  }

  Future<Map<String, dynamic>> _getPrediction(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    try {
      final response = await _client
          .get(
        uri,
        headers: {'Accept': 'application/json'},
      )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception(
          'API error ${response.statusCode}: ${response.body}',
        );
      }

      final dynamic data = jsonDecode(response.body);

      if (data is! Map) {
        throw Exception('Invalid forecast response format.');
      }

      return Map<String, dynamic>.from(data);
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on FormatException {
      throw Exception('The API returned invalid JSON.');
    } on Exception {
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}