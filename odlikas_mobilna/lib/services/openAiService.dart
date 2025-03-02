import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  // Base URL for OpenAI API
  final String _baseUrl = 'https://api.openai.com/v1';

  // API Key from .env file
  late final String _apiKey;

  // Rate limiting - maximum 3 requests per minute
  final int _maxRequestsPerMinute = 3;
  final _requestTimestamps = <DateTime>[];

  // Create a singleton instance
  static final OpenAIService _instance = OpenAIService._internal();

  factory OpenAIService() {
    return _instance;
  }

  OpenAIService._internal() {
    _apiKey = dotenv.env['OPEN_AI_API_KEY']!;
  }

  /// Ensures the rate limit is respected
  Future<void> _respectRateLimit() async {
    final now = DateTime.now();

    // Remove timestamps older than 1 minute
    _requestTimestamps
        .removeWhere((timestamp) => now.difference(timestamp).inMinutes >= 1);

    // If we've reached the limit, delay the next request
    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      final oldestRequest = _requestTimestamps.first;
      final timeToWait = Duration(minutes: 1) - now.difference(oldestRequest);

      if (timeToWait.isNegative) {
        // Just to be safe, wait a small amount if calculation is off
        await Future.delayed(const Duration(seconds: 2));
      } else {
        // Wait until we can make the next request
        await Future.delayed(timeToWait + const Duration(seconds: 1));
      }

      // After waiting, remove old timestamps again
      final afterWait = DateTime.now();
      _requestTimestamps.removeWhere(
          (timestamp) => afterWait.difference(timestamp).inMinutes >= 1);
    }

    // Add current request timestamp
    _requestTimestamps.add(now);
  }

  /// Makes an API request to OpenAI with rate limiting
  Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required Map<String, dynamic> body,
    int retries = 3,
  }) async {
    // Respect rate limit before making request
    await _respectRateLimit();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 429 && retries > 0) {
        // Too many requests - back off and retry
        await Future.delayed(const Duration(seconds: 5));
        return _makeRequest(
          endpoint: endpoint,
          body: body,
          retries: retries - 1,
        );
      } else {
        throw OpenAIException(
          'API request failed with status code: ${response.statusCode}',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      if (e is OpenAIException) rethrow;
      throw OpenAIException('Failed to connect to OpenAI API: $e', 0, '');
    }
  }

  /// Generate text using the slower GPT-3.5 Turbo model
  Future<String> generateText({
    required String prompt,
    double temperature = 0.7,
    int maxTokens = 512,
  }) async {
    try {
      final response = await _makeRequest(
        endpoint: 'chat/completions',
        body: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        },
      );

      if (response.containsKey('choices') &&
          response['choices'] is List &&
          response['choices'].isNotEmpty) {
        return response['choices'][0]['message']['content'];
      } else {
        throw OpenAIException(
          'Invalid response format from OpenAI API',
          0,
          jsonEncode(response),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating text: $e');
      }
      rethrow;
    }
  }
}

/// Custom exception for OpenAI API errors
class OpenAIException implements Exception {
  final String message;
  final int statusCode;
  final String responseBody;

  OpenAIException(this.message, this.statusCode, this.responseBody);

  @override
  String toString() {
    return 'OpenAIException: $message (Status Code: $statusCode)';
  }
}
