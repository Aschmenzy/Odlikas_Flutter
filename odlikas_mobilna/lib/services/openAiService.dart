import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final String _baseUrl = 'https://api.openai.com/v1';

  late final String _apiKey;

  // Increased to 10 to accommodate two-model pipeline (2 calls per user message)
  final int _maxRequestsPerMinute = 10;
  final _requestTimestamps = <DateTime>[];

  final Map<String, CachedResponse> _responseCache = {};
  final int _maxCacheSize = 50;
  final Duration _cacheTTL = const Duration(hours: 12);

  static final OpenAIService _instance = OpenAIService._internal();

  factory OpenAIService() => _instance;

  OpenAIService._internal() {
    _apiKey = dotenv.env['OPEN_AI_API_KEY'] ?? '';
    if (_apiKey.isEmpty && kDebugMode) {
      debugPrint('WARNING: OpenAI API key missing. Add OPEN_AI_API_KEY to .env');
    }
  }

  Future<void> _respectRateLimit() async {
    final now = DateTime.now();
    _requestTimestamps
        .removeWhere((t) => now.difference(t).inMinutes >= 1);

    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      final oldest = _requestTimestamps.first;
      final wait = const Duration(minutes: 1) - now.difference(oldest);
      if (!wait.isNegative) {
        await Future.delayed(wait + const Duration(seconds: 1));
      }
      final afterWait = DateTime.now();
      _requestTimestamps
          .removeWhere((t) => afterWait.difference(t).inMinutes >= 1);
    }
    _requestTimestamps.add(now);
  }

  String? _checkCache(String key, double temperature, int maxTokens) {
    final cacheKey = '$key|$temperature|$maxTokens';
    final cached = _responseCache[cacheKey];
    if (cached != null) {
      if (DateTime.now().difference(cached.timestamp) < _cacheTTL) {
        return cached.response;
      }
      _responseCache.remove(cacheKey);
    }
    return null;
  }

  void _addToCache(String key, double temperature, int maxTokens, String response) {
    final cacheKey = '$key|$temperature|$maxTokens';
    if (_responseCache.length >= _maxCacheSize) {
      final oldest = _responseCache.entries
          .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b);
      _responseCache.remove(oldest.key);
    }
    _responseCache[cacheKey] = CachedResponse(response, DateTime.now());
  }

  Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required Map<String, dynamic> body,
    int retries = 3,
  }) async {
    if (_apiKey.isEmpty) {
      throw OpenAIException('Missing OPEN_AI_API_KEY in .env', 401, '');
    }

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
          .timeout(const Duration(seconds: 30),
              onTimeout: () => throw OpenAIException('Request timed out', 408, ''));

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw OpenAIException('Failed to parse response: $e', 200, response.body);
        }
      } else if ((response.statusCode == 429 || response.statusCode >= 500) &&
          retries > 0) {
        final delay = response.statusCode == 429 ? 10 : 5;
        if (kDebugMode) {
          debugPrint('API ${response.statusCode}, retrying in ${delay}s...');
        }
        await Future.delayed(Duration(seconds: delay));
        return _makeRequest(endpoint: endpoint, body: body, retries: retries - 1);
      } else {
        String errorMessage = 'API error: ${response.statusCode}';
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final error = json['error'];
          if (error is String) errorMessage = error;
          if (error is Map && error.containsKey('message')) {
            errorMessage = error['message'] as String;
          }
        } catch (_) {}
        throw OpenAIException(errorMessage, response.statusCode, response.body);
      }
    } catch (e) {
      if (e is OpenAIException) rethrow;
      throw OpenAIException('Failed to connect to OpenAI: $e', 0, '');
    }
  }

  // ──────────────────────────────────────────────
  // MODEL 1 — intent classifier (gpt-4o-mini)
  // ──────────────────────────────────────────────

  /// Reads the user message and returns a compact intent JSON.
  /// Cheap, fast, ~120 output tokens max.
  Future<QueryIntent> classifyIntent(String userMessage) async {
    const systemPrompt =
        'Klasifikator namjere za skolsku aplikaciju. Vrati SAMO JSON:\n'
        '{"intent":"grades|tests|schedule|profile|general",'
        '"needsApi":true|false,'
        '"subject":"naziv predmeta ili null",'
        '"dayOfWeek":"Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday ili null",'
        '"summary":"sto ucenik trazi, max 15 rijeci"}\n'
        'grades=ocjene/prosjek/predmet, tests=testovi/ispiti/kontrolni, '
        'schedule=raspored/satnica/nastava, profile=profil/skola/razred/osobni podaci, '
        'general=sve ostalo. needsApi=true za grades/tests/schedule/profile.';

    try {
      final response = await _makeRequest(
        endpoint: 'chat/completions',
        body: {
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.1,
          'max_tokens': 120,
          'response_format': {'type': 'json_object'},
        },
      );

      final content = response['choices'][0]['message']['content'] as String;
      return QueryIntent.fromJson(jsonDecode(content) as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) debugPrint('Intent classification failed, falling back to general: $e');
      return QueryIntent.general();
    }
  }

  // ──────────────────────────────────────────────
  // MODEL 2 — response generator (gpt-3.5-turbo)
  // ──────────────────────────────────────────────

  /// Receives pre-fetched context data + intent summary and produces
  /// the final natural language response shown to the user.
  Future<String> generateResponse({
    required String userQuery,
    required String intentSummary,
    String contextData = '',
  }) async {
    // Cache based on intent summary + context (same question, same data → same answer)
    final cacheKey = 'gen|$intentSummary|$contextData';
    final cached = _checkCache(cacheKey, 0.7, 400);
    if (cached != null) return cached;

    final system = StringBuffer()
      ..write(
        'Ti si skolski AI asistent za ucenika u hrvatskoj skoli. '
        'Odgovaraj prijateljski i sazetko na HRVATSKOM jeziku. '
        'Nemoj koristiti dijakriticka slova (pisi c,s,z,d umjesto c,s,z,d).',
      );

    if (contextData.isNotEmpty) {
      system.write('\n\nPodaci iz sustava:\n$contextData');
    }

    if (intentSummary.isNotEmpty) {
      system.write('\n\nSto ucenik trazi: $intentSummary');
    }

    try {
      final response = await _makeRequest(
        endpoint: 'chat/completions',
        body: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': system.toString()},
            {'role': 'user', 'content': userQuery},
          ],
          'temperature': 0.7,
          'max_tokens': 400,
        },
      );

      if (response.containsKey('choices') &&
          (response['choices'] as List).isNotEmpty) {
        final result = response['choices'][0]['message']['content'] as String;
        _addToCache(cacheKey, 0.7, 400, result);
        return result;
      }
      throw OpenAIException('Invalid response format', 0, jsonEncode(response));
    } catch (e) {
      if (kDebugMode) debugPrint('Error in generateResponse: $e');
      if (e is OpenAIException && (e.statusCode == 429 || e.statusCode >= 500)) {
        return 'Trenutno ne mogu generirati odgovor. Pokusajte opet malo kasnije.';
      }
      return 'Zao mi je, doslo je do pogreske. Pokusajte opet.';
    }
  }

  // ──────────────────────────────────────────────
  // Legacy method kept for backward compatibility
  // ──────────────────────────────────────────────

  Future<String> generateText({
    required String prompt,
    double temperature = 0.7,
    int maxTokens = 512,
    bool useCache = true,
  }) async {
    if (useCache) {
      final cached = _checkCache(prompt, temperature, maxTokens);
      if (cached != null) return cached;
    }

    try {
      final response = await _makeRequest(
        endpoint: 'chat/completions',
        body: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Ti si skolski AI asistent koji pomaze ucenicima. Odgovaraj tocno, jasno i sazetko na hrvatskom jeziku.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        },
      );

      if (response.containsKey('choices') &&
          response['choices'] is List &&
          response['choices'].isNotEmpty) {
        final result = response['choices'][0]['message']['content'] as String;
        if (useCache) _addToCache(prompt, temperature, maxTokens, result);
        return result;
      }
      throw OpenAIException('Invalid response format', 0, jsonEncode(response));
    } catch (e) {
      if (kDebugMode) debugPrint('Error generating text: $e');
      if (e is OpenAIException && (e.statusCode == 429 || e.statusCode >= 500)) {
        return 'Trenutno ne mogu generirati odgovor zbog preopterecenja sustava. Pokusajte opet.';
      }
      if (e is OpenAIException && e.statusCode == 401) {
        return 'AI asistent trenutno nije dostupan zbog problema s konfiguracijom.';
      }
      return 'Zao mi je, nesto je poslo po krivu. Pokusajte postaviti jednostavnije pitanje.';
    }
  }

  void clearCache() => _responseCache.clear();
}

// ──────────────────────────────────────────────
// Supporting types
// ──────────────────────────────────────────────

/// Structured output from Model 1 (intent classifier).
class QueryIntent {
  final String intent; // grades | tests | schedule | profile | general
  final bool needsApi;
  final String? subject;
  final String? dayOfWeek; // English day name (Monday–Sunday) or null
  final String summary;

  QueryIntent({
    required this.intent,
    required this.needsApi,
    this.subject,
    this.dayOfWeek,
    required this.summary,
  });

  factory QueryIntent.fromJson(Map<String, dynamic> json) => QueryIntent(
        intent: (json['intent'] as String? ?? 'general').toLowerCase(),
        needsApi: json['needsApi'] as bool? ?? false,
        subject: _nullOrString(json['subject']),
        dayOfWeek: _nullOrString(json['dayOfWeek']),
        summary: json['summary'] as String? ?? '',
      );

  factory QueryIntent.general() =>
      QueryIntent(intent: 'general', needsApi: false, summary: '');

  static String? _nullOrString(dynamic value) {
    if (value == null || value == 'null' || (value as String).isEmpty) {
      return null;
    }
    return value;
  }
}

class CachedResponse {
  final String response;
  final DateTime timestamp;

  CachedResponse(this.response, this.timestamp);
}

class OpenAIException implements Exception {
  final String message;
  final int statusCode;
  final String responseBody;

  OpenAIException(this.message, this.statusCode, this.responseBody);

  @override
  String toString() => 'OpenAIException: $message (Status: $statusCode)';
}
