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

  // Cache for recent queries to minimize API calls
  final Map<String, CachedResponse> _responseCache = {};
  final int _maxCacheSize = 50;
  final Duration _cacheTTL = const Duration(hours: 12);

  // Create a singleton instance
  static final OpenAIService _instance = OpenAIService._internal();

  factory OpenAIService() {
    return _instance;
  }

  OpenAIService._internal() {
    _apiKey = dotenv.env['OPEN_AI_API_KEY'] ?? '';
    _checkApiKey();
  }

  // Check if API key is available
  void _checkApiKey() {
    if (_apiKey.isEmpty) {
      if (kDebugMode) {
        print(
            'WARNING: OpenAI API key is missing. Please add OPEN_AI_API_KEY to your .env file.');
      }
    }
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

  /// Check cache for a response
  String? _checkCache(String prompt, double temperature, int maxTokens) {
    final cacheKey = _generateCacheKey(prompt, temperature, maxTokens);
    final cached = _responseCache[cacheKey];
    final now = DateTime.now();

    if (cached != null) {
      // Check if cache entry is still valid
      if (now.difference(cached.timestamp) < _cacheTTL) {
        return cached.response;
      } else {
        // Remove expired cache entry
        _responseCache.remove(cacheKey);
      }
    }

    return null;
  }

  /// Add response to cache
  void _addToCache(
      String prompt, double temperature, int maxTokens, String response) {
    final cacheKey = _generateCacheKey(prompt, temperature, maxTokens);

    // Evict oldest entries if cache is full
    if (_responseCache.length >= _maxCacheSize) {
      final oldest = _responseCache.entries.reduce(
          (a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b);
      _responseCache.remove(oldest.key);
    }

    _responseCache[cacheKey] = CachedResponse(response, DateTime.now());
  }

  /// Generate a cache key
  String _generateCacheKey(String prompt, double temperature, int maxTokens) {
    return '$prompt|$temperature|$maxTokens';
  }

  /// Makes an API request to OpenAI with rate limiting and improved error handling
  Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required Map<String, dynamic> body,
    int retries = 3,
  }) async {
    if (_apiKey.isEmpty) {
      throw OpenAIException(
        'Missing OpenAI API key. Please add OPEN_AI_API_KEY to your .env file.',
        401,
        '',
      );
    }

    // Respect rate limit before making request
    await _respectRateLimit();

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw OpenAIException('Request timed out', 408, ''),
          );

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw OpenAIException(
            'Failed to parse response: $e',
            200,
            response.body,
          );
        }
      } else if ((response.statusCode == 429 || response.statusCode >= 500) &&
          retries > 0) {
        // Too many requests or server error - back off and retry
        final delay = response.statusCode == 429
            ? 10
            : 5; // Wait longer for rate limit errors

        if (kDebugMode) {
          print(
              'API request failed with status ${response.statusCode}. Retrying in $delay seconds...');
        }

        await Future.delayed(Duration(seconds: delay));
        return _makeRequest(
          endpoint: endpoint,
          body: body,
          retries: retries - 1,
        );
      } else {
        // Try to parse error message from JSON
        String errorMessage =
            'API request failed with status code: ${response.statusCode}';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'];
          if (error != null) {
            if (error is String) {
              errorMessage = error;
            } else if (error is Map && error.containsKey('message')) {
              errorMessage = error['message'] as String;
            }
          }
        } catch (_) {
          // If parsing fails, use the status code message
        }

        throw OpenAIException(
          errorMessage,
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      if (e is OpenAIException) rethrow;
      throw OpenAIException('Failed to connect to OpenAI API: $e', 0, '');
    }
  }

  /// Generate text using GPT-3.5 Turbo model with improved caching and error handling
  Future<String> generateText({
    required String prompt,
    double temperature = 0.7,
    int maxTokens = 512,
    bool useCache = true,
  }) async {
    try {
      // Check cache first if enabled
      if (useCache) {
        final cachedResponse = _checkCache(prompt, temperature, maxTokens);
        if (cachedResponse != null) {
          return cachedResponse;
        }
      }

      final response = await _makeRequest(
        endpoint: 'chat/completions',
        body: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Ti si školski AI asistent koji pomaže učenicima. Odgovaraj točno, jasno i sažeto na hrvatskom jeziku.',
            },
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
        final result = response['choices'][0]['message']['content'];

        // Cache the result if caching is enabled
        if (useCache) {
          _addToCache(prompt, temperature, maxTokens, result);
        }

        return result;
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

      // Provide a graceful fallback response
      if (e is OpenAIException &&
          (e.statusCode == 429 || e.statusCode >= 500)) {
        return "Trenutno ne mogu generirati odgovor zbog preopterećenja sustava. Molim pokušajte ponovno kasnije ili postavite specifično pitanje o vašim ocjenama, testovima ili rasporedu.";
      }

      // If API key is missing
      if (e is OpenAIException && e.statusCode == 401) {
        return "AI asistent trenutno nije dostupan zbog problema s konfiguracijom. Molimo kontaktirajte administratora aplikacije.";
      }

      return "Žao mi je, nešto je pošlo po krivu prilikom generiranja odgovora. Molimo pokušajte postaviti jednostavnije pitanje ili pitajte me o vašim ocjenama, testovima ili rasporedu.";
    }
  }

  /// Clear the response cache (useful for testing)
  void clearCache() {
    _responseCache.clear();
  }
}

/// Cache storage for responses
class CachedResponse {
  final String response;
  final DateTime timestamp;

  CachedResponse(this.response, this.timestamp);
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
