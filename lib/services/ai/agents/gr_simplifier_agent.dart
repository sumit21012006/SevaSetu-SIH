import '../ai_config.dart';
import '../cache/gr_summary_cache.dart';
import '../context/prompt_context_builder.dart';
import '../knowledge/knowledge_repository.dart';
import '../models/agent_request.dart';
import '../models/agent_result.dart';
import '../models/agent_type.dart';
import '../prompts/agent_prompts.dart';
import '../validation/response_validator.dart';
import 'base_agent.dart';

/// Specialized agent for simplifying complex Government Resolutions and circulars.
class GRSimplifierAgent extends BaseAgent {
  GRSimplifierAgent({
    required super.groqClient,
    required super.knowledgeRepo,
    required super.catalog,
    GRSummaryCache? cache,
    this.validator = const ResponseValidator(),
  }) : cache = cache ?? GRSummaryCache();

  final GRSummaryCache cache;
  final ResponseValidator validator;

  @override
  AgentType get agentType => AgentType.grSimplifier;

  @override
  Future<AgentResult> execute(AgentRequest request) async {
    // 1. Resolve GR document text
    String grText = request.documentText?.trim() ?? '';
    String? resolvedServiceId = request.serviceId;

    if (grText.isEmpty) {
      final grEntry = _findGREntry(request.serviceId, request.query);
      if (grEntry != null) {
        resolvedServiceId = grEntry.serviceId;
        grText = await knowledgeRepo.loadGRText(grEntry.filename);
      }
    }

    if (grText.isEmpty) {
      return AgentResult.error(
        agentType: agentType,
        errorMessage: 'Please provide or paste the Government Resolution (GR) text to simplify.',
      );
    }

    // 2. Check persistent cache
    final cacheKey = cache.computeKey(grText, request.language.code);
    final cachedResult = await cache.get(cacheKey);
    if (cachedResult != null) {
      return cachedResult;
    }

    // 3. Offline / Missing API key fallback
    if (!AIConfig.hasApiKey) {
      return _buildOfflineSummary(grText, resolvedServiceId, request.language.code);
    }

    // 4. Grounded LLM reasoning
    final systemPrompt = buildSystemPrompt(AgentPrompts.grSimplifier);
    final sources = resolvedServiceId != null
        ? knowledgeRepo.getSourcesForService(resolvedServiceId)
        : knowledgeRepo.allSources;

    final contextBlock = StringBuffer();
    contextBlock.writeln(PromptContextBuilder.buildSystemContext(
      profile: request.profile,
      vault: request.vault,
      sources: sources,
      language: request.language,
    ));

    contextBlock.writeln('TARGET_LANGUAGE: ${request.language.code}');
    contextBlock.writeln('<gr_text>');
    contextBlock.writeln(grText);
    contextBlock.writeln('</gr_text>');

    final messages = buildMessages(
      systemPrompt: systemPrompt,
      contextBlock: contextBlock.toString(),
      request: request,
    );

    try {
      final rawResponse = await groqClient.chatCompletion(
        messages: messages,
        model: AIConfig.primaryModel,
        temperature: 0.1,
        jsonMode: true,
      );

      final result = await validator.validateAndParse(
        rawInput: rawResponse,
        agentType: agentType,
        catalog: catalog,
        vault: request.vault,
        sources: sources,
        groqClient: groqClient,
      );

      // Persist to cache
      if (result.isSuccess) {
        await cache.put(cacheKey, result);
      }

      return result;
    } catch (e) {
      return _buildOfflineSummary(
        grText,
        resolvedServiceId,
        request.language.code,
        fallbackReason: e.toString(),
      );
    }
  }

  GRManifestEntry? _findGREntry(String? serviceId, String query) {
    if (serviceId != null) {
      final entry = knowledgeRepo.getGRForService(serviceId);
      if (entry != null) return entry;
    }

    final lower = query.toLowerCase();
    for (final entry in knowledgeRepo.grEntries) {
      if (lower.contains(entry.id.toLowerCase()) ||
          lower.contains(entry.title.toLowerCase()) ||
          lower.contains(entry.grNumber.toLowerCase())) {
        return entry;
      }
    }

    return knowledgeRepo.grEntries.isNotEmpty ? knowledgeRepo.grEntries.first : null;
  }

  AgentResult _buildOfflineSummary(
    String grText,
    String? serviceId,
    String lang, {
    String? fallbackReason,
  }) {
    // Extract first 4 lines for preview
    final lines = grText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final header = lines.take(3).join(' • ');

    final summary = 'Offline summary for Government Resolution: $header. To see deep reasoning and clause translation, configure GROQ_API_KEY in .env.';

    return AgentResult(
      agentType: agentType,
      summary: summary,
      confidence: 0.9,
      recommendedServiceIds: serviceId != null ? [serviceId] : const [],
      steps: [
        'Read key clauses from official resolution',
        'Verify applicable dates and criteria with issuing department',
      ],
      nextActions: serviceId != null ? ['view_service:$serviceId'] : const ['open_gr_guide'],
      metadata: {
        'isOfflineFallback': true,
        if (fallbackReason != null) 'fallbackReason': fallbackReason,
      },
    );
  }
}
