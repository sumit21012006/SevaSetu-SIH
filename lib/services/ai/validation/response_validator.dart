import 'dart:convert';
import '../../../models/document.dart';
import '../../../models/service.dart';
import '../ai_config.dart';
import '../groq_client.dart';
import '../models/agent_result.dart';
import '../models/agent_type.dart';
import '../models/ai_source.dart';
import '../prompts/output_contract.dart';

/// Validates, repairs, and sanitizes raw JSON responses from AI agents.
class ResponseValidator {
  const ResponseValidator();

  static const Set<String> allowedActionPrefixes = {
    'view_service',
    'check_eligibility',
    'view_documents',
    'download_zip',
    'upload_document',
    'open_document',
    'open_gr_guide',
  };

  /// Validates and parses raw response string into an AgentResult.
  /// If repair is needed and groqClient is supplied, executes one repair attempt.
  Future<AgentResult> validateAndParse({
    required dynamic rawInput,
    required AgentType agentType,
    required List<GovService> catalog,
    required List<CitizenDocument> vault,
    required List<AISource> sources,
    GroqClient? groqClient,
  }) async {
    Map<String, dynamic>? parsedJson;
    String rawString = '';

    if (rawInput is Map<String, dynamic>) {
      parsedJson = rawInput;
      rawString = rawInput['rawContent']?.toString() ?? jsonEncode(rawInput);
    } else if (rawInput is String) {
      rawString = rawInput;
      parsedJson = _extractJson(rawInput);
    }

    // If parsing failed, attempt one repair call with Fast Model if client is available
    if (parsedJson == null && groqClient != null && AIConfig.hasApiKey) {
      try {
        final repairResponse = await groqClient.chatCompletion(
          messages: [
            {
              'role': 'system',
              'content':
                  'Return ONLY valid JSON matching this contract. No markdown, no conversation.\n${OutputContract.text}',
            },
            {
              'role': 'user',
              'content': 'Fix this output to be valid JSON:\n$rawString',
            },
          ],
          model: AIConfig.fastModel,
          temperature: 0.0,
          jsonMode: true,
        );
        parsedJson = repairResponse;
      } catch (_) {
        // Repair call failed, degrade gracefully to raw text
      }
    }

    // Graceful degradation to plain text bubble if still invalid JSON
    if (parsedJson == null) {
      return AgentResult(
        agentType: agentType,
        summary: rawString.isNotEmpty
            ? rawString
            : 'Received an unformatted response from the assistant.',
        confidence: 0.5,
        rawResponse: rawString,
      );
    }

    // Sanitize and enforce constraints
    return _sanitize(
      parsedJson,
      fallbackAgent: agentType,
      catalog: catalog,
      vault: vault,
      sources: sources,
      rawResponse: rawString,
    );
  }

  /// Extracts the first JSON object from a string, stripping any code blocks or surrounding text.
  static Map<String, dynamic>? _extractJson(String input) {
    String clean = input.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    clean = clean.trim();

    try {
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      // Look for first '{' and last '}'
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        try {
          final sub = clean.substring(start, end + 1);
          return jsonDecode(sub) as Map<String, dynamic>;
        } catch (_) {}
      }
      return null;
    }
  }

  /// Sanitizes parsed fields against whitelist rules and length limits.
  AgentResult _sanitize(
    Map<String, dynamic> json, {
    required AgentType fallbackAgent,
    required List<GovService> catalog,
    required List<CitizenDocument> vault,
    required List<AISource> sources,
    required String rawResponse,
  }) {
    final validServiceIds = catalog.map((s) => s.id).toSet();
    final validDocIds = vault.map((d) => d.type.name).toSet();
    final validSourceIds = sources.map((s) => s.id).toSet();

    // 1. Service IDs & Document IDs
    final rawServiceIds = (json['service_ids'] as List<dynamic>? ??
            json['serviceIds'] as List<dynamic>? ??
            const [])
        .map((s) => s.toString())
        .where(validServiceIds.contains)
        .toList();

    final rawDocIds = (json['document_ids'] as List<dynamic>? ?? const [])
        .map((d) => d.toString())
        .where(validDocIds.contains)
        .toList();

    // 2. Recommendations (max 3, must be valid service IDs)
    final rawRecs = (json['recommendations'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((r) => validServiceIds.contains(r['service_id']?.toString()))
        .take(3)
        .map((r) => r['service_id']!.toString())
        .toList();

    final recommendedServiceIds = rawRecs.isNotEmpty ? rawRecs : rawServiceIds;

    // 3. Actions (must match allowed prefixes and valid IDs)
    final rawActions = (json['actions'] as List<dynamic>? ?? const []).map((a) => a.toString());
    final List<String> validActions = [];
    for (final action in rawActions) {
      final parts = action.split(':');
      final prefix = parts[0].trim();
      if (!allowedActionPrefixes.contains(prefix)) continue;

      if (parts.length > 1) {
        final targetId = parts[1].trim();
        if (prefix.contains('service') || prefix == 'download_zip' || prefix == 'check_eligibility') {
          if (!validServiceIds.contains(targetId)) continue;
        }
      }
      validActions.add(action);
    }

    // 4. Sources: drop any source ID not in available sources
    final rawSourceIds = (json['sources'] as List<dynamic>? ?? const []).map((s) => s.toString());
    final List<AISource> matchedSources = [];
    for (final sId in rawSourceIds) {
      if (validSourceIds.contains(sId)) {
        final src = sources.firstWhere((s) => s.id == sId);
        matchedSources.add(src);
      }
    }

    // 5. Points (max 6)
    final rawPoints = (json['points'] as List<dynamic>? ?? const [])
        .take(6)
        .map((p) => p is Map<String, dynamic> ? p['text']?.toString() ?? '' : p.toString())
        .where((t) => t.isNotEmpty)
        .toList();

    // 6. Follow up questions (max 3)
    final rawFollowUps = (json['follow_up_questions'] as List<dynamic>? ??
            json['followUpQuestions'] as List<dynamic>? ??
            const [])
        .take(3)
        .map((q) => q.toString())
        .toList();

    // 7. Headline & Answer
    final headline = json['headline']?.toString() ?? '';
    final answer = json['answer']?.toString() ??
        json['summary']?.toString() ??
        json['message']?.toString() ??
        '';

    final result = AgentResult.fromJson(
      {
        ...json,
        'summary': answer.isNotEmpty ? answer : (headline.isNotEmpty ? headline : 'Completed.'),
        'recommendedServiceIds': recommendedServiceIds,
        'steps': rawPoints,
        'nextActions': validActions,
        'rawResponse': rawResponse,
      },
      fallbackAgent: fallbackAgent,
    );

    return result.copyWith(
      sources: matchedSources,
      steps: rawPoints,
      nextActions: validActions,
      recommendedServiceIds: recommendedServiceIds,
      metadata: {
        ...result.metadata,
        'headline': headline,
        'groundedSourceCount': matchedSources.length,
        'documentIds': rawDocIds,
        'followUpQuestions': rawFollowUps,
        if (json['gr_summary'] != null) 'gr_summary': json['gr_summary'],
      },
    );
  }
}
