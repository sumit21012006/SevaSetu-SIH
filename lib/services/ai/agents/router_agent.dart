import '../../../models/service.dart';
import '../ai_config.dart';
import '../groq_client.dart';
import '../models/agent_type.dart';
import '../prompts/router_prompt.dart';

/// Decision result returned by the Router / Intent Agent.
class RouterDecision {
  const RouterDecision({
    required this.agentType,
    this.serviceHint,
    this.confidence = 1.0,
    this.isFallback = false,
  });

  final AgentType agentType;
  final String? serviceHint;
  final double confidence;
  final bool isFallback;
}

/// The Router / Intent Agent that directs user queries to the appropriate agent.
class RouterAgent {
  RouterAgent({
    required this.groqClient,
    required this.catalog,
  });

  final GroqClient groqClient;
  final List<GovService> catalog;

  /// Routes the citizen query using Groq Fast Model, with deterministic keyword fallback.
  Future<RouterDecision> route({
    required String query,
    String? activeServiceId,
    List<Map<String, String>> history = const [],
  }) async {
    // 1. Try LLM Router if API key is available
    if (AIConfig.hasApiKey) {
      try {
        final serviceListText = catalog
            .map((s) => '- ${s.id}: ${s.name} (${s.category.label})')
            .join('\n');

        final prompt = '''
${RouterPrompt.text}

ACTIVE SERVICE CONTEXT: ${activeServiceId ?? 'None'}

SERVICE LIST:
$serviceListText

CITIZEN QUERY: $query
'''.trim();

        final response = await groqClient.chatCompletion(
          messages: [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': query},
          ],
          model: AIConfig.fastModel,
          temperature: 0.0,
          jsonMode: true,
        );

        final agentStr = response['agent']?.toString().toLowerCase() ?? '';
        final hint = response['service_hint']?.toString();
        final conf = (response['confidence'] as num?)?.toDouble() ?? 0.9;

        AgentType agentType;
        if (agentStr.contains('scheme') || agentStr.contains('recommendation')) {
          agentType = AgentType.recommendation;
        } else if (agentStr.contains('eligibility')) {
          agentType = AgentType.eligibility;
        } else if (agentStr.contains('guidance')) {
          agentType = AgentType.guidance;
        } else if (agentStr.contains('gr')) {
          agentType = AgentType.grSimplifier;
        } else {
          agentType = AgentType.recommendation;
        }

        // Validate service hint against catalog
        String? validHint = hint;
        if (validHint != null && !catalog.any((s) => s.id == validHint)) {
          validHint = null;
        }

        return RouterDecision(
          agentType: agentType,
          serviceHint: validHint ?? activeServiceId,
          confidence: conf,
        );
      } catch (_) {
        // Fall through to deterministic keyword router on any error
      }
    }

    // 2. Deterministic keyword router fallback (Devanagari + Roman script)
    return fallbackKeywordRoute(query, activeServiceId: activeServiceId);
  }

  /// Deterministic keyword router.
  RouterDecision fallbackKeywordRoute(String query, {String? activeServiceId}) {
    final lower = query.toLowerCase().trim();

    // Out of scope / greetings
    if (RegExp(r'^(hi|hello|hey|namaste|namaskar|good morning|kem cho|kasa kay)\b').hasMatch(lower)) {
      if (lower.split(' ').length <= 4) {
        return RouterDecision(
          agentType: AgentType.recommendation,
          serviceHint: activeServiceId,
          confidence: 0.7,
          isFallback: true,
        );
      }
    }

    // GR simplification keywords
    if (lower.contains('gr') ||
        lower.contains('shasan nirnay') ||
        lower.contains('शासन निर्णय') ||
        lower.contains('जीआर') ||
        lower.contains('circular') ||
        lower.contains('notification') ||
        lower.contains('परिपत्रक') ||
        lower.contains('simplify')) {
      return RouterDecision(
        agentType: AgentType.grSimplifier,
        serviceHint: activeServiceId ?? _matchServiceFromQuery(lower),
        confidence: 0.85,
        isFallback: true,
      );
    }

    // Eligibility keywords
    if (lower.contains('eligible') ||
        lower.contains('eligibility') ||
        lower.contains('qualify') ||
        lower.contains('patra') ||
        lower.contains('patrata') ||
        lower.contains('पात्रता') ||
        lower.contains('पात्र') ||
        lower.contains('अपात्र') ||
        lower.contains('लायक') ||
        lower.contains('can i get') ||
        lower.contains('milu shakel')) {
      return RouterDecision(
        agentType: AgentType.eligibility,
        serviceHint: activeServiceId ?? _matchServiceFromQuery(lower),
        confidence: 0.85,
        isFallback: true,
      );
    }

    // Guidance & document keywords
    if (lower.contains('document') ||
        lower.contains('documents') ||
        lower.contains('proof') ||
        lower.contains('kagadpatre') ||
        lower.contains('dastavej') ||
        lower.contains('कागदपत्रे') ||
        lower.contains('दस्तावेज') ||
        lower.contains('how to apply') ||
        lower.contains('where to apply') ||
        lower.contains('apply now') ||
        lower.contains('portal') ||
        lower.contains('deadline') ||
        lower.contains('last date') ||
        lower.contains('tarikh') ||
        lower.contains('तारीख') ||
        lower.contains('कसे अर्ज करावे') ||
        lower.contains('अर्ज कसा करावा') ||
        lower.contains('download') ||
        lower.contains('zip')) {
      return RouterDecision(
        agentType: AgentType.guidance,
        serviceHint: activeServiceId ?? _matchServiceFromQuery(lower),
        confidence: 0.85,
        isFallback: true,
      );
    }

    // Default to Scheme Recommendation
    return RouterDecision(
      agentType: AgentType.recommendation,
      serviceHint: activeServiceId ?? _matchServiceFromQuery(lower),
      confidence: 0.75,
      isFallback: true,
    );
  }

  String? _matchServiceFromQuery(String text) {
    for (final s in catalog) {
      if (text.contains(s.id.toLowerCase()) || text.contains(s.name.toLowerCase())) {
        return s.id;
      }
      for (final kw in s.keywords) {
        if (text.contains(kw.toLowerCase())) {
          return s.id;
        }
      }
    }
    return null;
  }
}
