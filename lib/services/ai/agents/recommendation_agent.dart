import '../../../models/service.dart';
import '../ai_config.dart';
import '../context/prompt_context_builder.dart';
import '../groq_client.dart';
import '../models/agent_request.dart';
import '../models/agent_result.dart';
import '../models/agent_type.dart';
import '../prompts/agent_prompts.dart';
import '../validation/response_validator.dart';
import 'base_agent.dart';

/// Specialized agent for finding and recommending government schemes.
class RecommendationAgent extends BaseAgent {
  RecommendationAgent({
    required super.groqClient,
    required super.knowledgeRepo,
    required super.catalog,
    this.validator = const ResponseValidator(),
  });

  final ResponseValidator validator;

  @override
  AgentType get agentType => AgentType.recommendation;

  @override
  Future<AgentResult> execute(AgentRequest request) async {
    if (!AIConfig.hasApiKey) {
      return AgentResult.error(
        agentType: agentType,
        errorMessage: 'Groq API Key is not configured. Please add GROQ_API_KEY to your .env file to enable AI scheme discovery.',
      );
    }

    // 1. Filter top <= 8 candidates by query keyword/category match to save tokens
    final filteredServices = _filterCandidateServices(request.query, request.serviceId);

    // 2. Fetch relevant grounding sources
    final relevantSources = knowledgeRepo.allSources
        .where((s) => filteredServices.any((svc) => svc.id == s.serviceId))
        .toList();

    // 3. Assemble prompt
    final systemPrompt = buildSystemPrompt(AgentPrompts.schemeRecommendation);
    final contextBlock = PromptContextBuilder.buildSystemContext(
      profile: request.profile,
      vault: request.vault,
      services: filteredServices,
      sources: relevantSources,
      language: request.language,
    );

    final messages = buildMessages(
      systemPrompt: systemPrompt,
      contextBlock: contextBlock,
      request: request,
    );

    // 4. Invoke Groq
    try {
      final rawResponse = await groqClient.chatCompletion(
        messages: messages,
        model: AIConfig.primaryModel,
        temperature: 0.2,
        jsonMode: true,
      );

      return await validator.validateAndParse(
        rawInput: rawResponse,
        agentType: agentType,
        catalog: catalog,
        vault: request.vault,
        sources: relevantSources,
        groqClient: groqClient,
      );
    } on GroqException catch (e) {
      return AgentResult.error(
        agentType: agentType,
        errorMessage: e.message,
      );
    } catch (e) {
      return AgentResult.error(
        agentType: agentType,
        errorMessage: 'Failed to process scheme recommendations: $e',
      );
    }
  }

  List<GovService> _filterCandidateServices(String query, String? explicitServiceId) {
    if (explicitServiceId != null) {
      final explicit = catalog.where((s) => s.id == explicitServiceId).toList();
      if (explicit.isNotEmpty) return explicit;
    }

    final lower = query.toLowerCase();
    final scored = catalog.map((s) {
      int score = 0;
      if (lower.contains(s.name.toLowerCase())) score += 10;
      if (lower.contains(s.category.label.toLowerCase())) score += 5;
      for (final kw in s.keywords) {
        if (lower.contains(kw.toLowerCase())) score += 3;
      }
      return MapEntry(s, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    final top = scored.where((e) => e.value > 0).map((e) => e.key).take(8).toList();

    // If fewer than 3 match, return whole catalog to let LLM reason broadly
    if (top.length < 3) {
      return catalog;
    }
    return top;
  }
}
