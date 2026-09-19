import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'ai_config.dart';

/// Base exception for all Groq-related errors.
abstract class GroqException implements Exception {
  const GroqException(this.message, {this.statusCode, this.body});
  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => message;
}

class GroqMissingKeyException extends GroqException {
  const GroqMissingKeyException()
      : super('Groq API Key is not configured. Add GROQ_API_KEY to your .env file.');
}

class GroqAuthException extends GroqException {
  const GroqAuthException([String? body])
      : super('Groq authentication failed. Please check your GROQ_API_KEY.', statusCode: 401, body: body);
}

class GroqRateLimitException extends GroqException {
  const GroqRateLimitException([String? body])
      : super('Groq rate limit exceeded. Please try again shortly.', statusCode: 429, body: body);
}

class GroqTimeoutException extends GroqException {
  GroqTimeoutException(Duration duration)
      : super('Groq request timed out after ${duration.inSeconds} seconds.');
}

class GroqServerException extends GroqException {
  GroqServerException(int status, String body)
      : super('Groq server error (HTTP $status). Please retry later.', statusCode: status, body: body);
}

class GroqParseException extends GroqException {
  GroqParseException(String details, String raw)
      : super('Failed to parse Groq response: $details', body: raw);
}

/// Robust client wrapper for the Groq OpenAI-compatible Chat Completions API.
class GroqClient {
  GroqClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Sends a chat completion request to Groq with automatic retry on transient errors.
  Future<Map<String, dynamic>> chatCompletion({
    required List<Map<String, dynamic>> messages,
    String? model,
    double temperature = 0.2,
    bool jsonMode = true,
    int? maxTokens,
    String? overrideApiKey,
  }) async {
    final apiKey = overrideApiKey ?? AIConfig.apiKey;
    if (apiKey.isEmpty) {
      throw const GroqMissingKeyException();
    }

    final selectedModel = model ?? AIConfig.primaryModel;
    final maxRetries = AIConfig.maxRetries;
    final timeout = AIConfig.timeout;

    final url = Uri.parse('${AIConfig.groqApiBaseUrl}/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final payload = {
      'model': selectedModel,
      'messages': messages,
      'temperature': temperature,
      if (jsonMode) 'response_format': {'type': 'json_object'},
      if (maxTokens != null) 'max_tokens': maxTokens,
    };

    int attempts = 0;
    while (true) {
      attempts++;
      try {
        final response = await _client
            .post(url, headers: headers, body: jsonEncode(payload))
            .timeout(timeout);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          final choices = decoded['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) {
            throw GroqParseException('Empty choices array returned by Groq', response.body);
          }
          final messageObj = choices.first['message'] as Map<String, dynamic>?;
          final content = messageObj?['content'] as String? ?? '';

          if (jsonMode) {
            try {
              // Strip code fences if present
              String clean = content.trim();
              if (clean.startsWith('```json')) {
                clean = clean.substring(7);
              } else if (clean.startsWith('```')) {
                clean = clean.substring(3);
              }
              if (clean.endsWith('```')) {
                clean = clean.substring(0, clean.length - 3);
              }
              final parsed = jsonDecode(clean.trim()) as Map<String, dynamic>;
              parsed['rawContent'] = content;
              return parsed;
            } catch (e) {
              throw GroqParseException('Content was not valid JSON: $e', content);
            }
          }

          return {'content': content, 'raw': decoded};
        }

        if (response.statusCode == 401) {
          throw GroqAuthException(response.body);
        }

        if (response.statusCode == 429) {
          if (attempts <= maxRetries) {
            await Future.delayed(Duration(milliseconds: 1000 * attempts));
            continue;
          }
          throw GroqRateLimitException(response.body);
        }

        if (response.statusCode >= 500) {
          if (attempts <= maxRetries) {
            await Future.delayed(Duration(milliseconds: 1000 * attempts));
            continue;
          }
          throw GroqServerException(response.statusCode, response.body);
        }

        throw GroqServerException(response.statusCode, response.body);
      } on SocketException catch (e) {
        if (attempts <= maxRetries) {
          await Future.delayed(Duration(milliseconds: 1000 * attempts));
          continue;
        }
        throw GroqServerException(0, 'Network connection failed: ${e.message}');
      } on TimeoutException {
        if (attempts <= maxRetries) {
          await Future.delayed(Duration(milliseconds: 1000 * attempts));
          continue;
        }
        throw GroqTimeoutException(timeout);
      }
    }
  }

  void close() {
    _client.close();
  }
}
