import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration for SevaSetu AI multi-agent service.
class AIConfig {
  static const String groqApiBaseUrl = 'https://api.groq.com/openai/v1';

  static String? _getEnv(String key) {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env[key];
      }
    } catch (_) {}
    return null;
  }

  /// Primary LLM for deep reasoning, guidance, and GR translation.
  static String get primaryModel {
    final val = _getEnv('GROQ_PRIMARY_MODEL')?.trim();
    return val != null && val.isNotEmpty ? val : 'openai/gpt-oss-120b';
  }

  /// Fast LLM for classification, query routing, and simple extraction.
  static String get fastModel {
    final val = _getEnv('GROQ_FAST_MODEL')?.trim();
    return val != null && val.isNotEmpty ? val : 'openai/gpt-oss-20b';
  }

  /// Groq API key from environment (.env).
  static String get apiKey => _getEnv('GROQ_API_KEY')?.trim() ?? '';

  static bool get hasApiKey => apiKey.isNotEmpty;

  static int get maxRetries {
    final val = _getEnv('GROQ_MAX_RETRIES');
    return (val != null ? int.tryParse(val) : null) ?? 2;
  }

  static Duration get timeout {
    final val = _getEnv('GROQ_TIMEOUT_SECONDS');
    final seconds = (val != null ? int.tryParse(val) : null) ?? 30;
    return Duration(seconds: seconds);
  }
}
