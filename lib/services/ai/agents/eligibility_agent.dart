import '../../../models/service.dart';
import '../ai_config.dart';
import '../context/prompt_context_builder.dart';
import '../engine/eligibility_engine.dart';
import '../models/agent_request.dart';
import '../models/agent_result.dart';
import '../models/agent_type.dart';
import '../prompts/agent_prompts.dart';
import '../validation/response_validator.dart';
import 'base_agent.dart';

/// Specialized agent for evaluating scheme eligibility with deterministic grounding.
class EligibilityAgent extends BaseAgent {
  EligibilityAgent({
    required super.groqClient,
    required super.knowledgeRepo,
    required super.catalog,
    this.engine = const EligibilityEngine(),
    this.validator = const ResponseValidator(),
  });

  final EligibilityEngine engine;
  final ResponseValidator validator;

  @override
  AgentType get agentType => AgentType.eligibility;

  @override
  Future<AgentResult> execute(AgentRequest request) async {
    // 1. Identify targeted service
    final service = _findService(request.serviceId, request.query);
    if (service == null) {
      return AgentResult.error(
        agentType: agentType,
        errorMessage: 'Please specify which government scheme or service you would like to evaluate eligibility for.',
      );
    }

    // 2. Compute deterministic eligibility evaluation
    final report = engine.evaluate(
      service: service,
      profile: request.profile,
      vault: request.vault,
      knowledgeRepo: knowledgeRepo,
    );

    // 3. If offline or no API key, return deterministic report directly
    if (!AIConfig.hasApiKey) {
      final points = report.results.map((r) {
        return '${r.rule.title}: ${r.effectiveStatus.label} (${r.reason ?? ""})';
      }).toList();

      return AgentResult(
        agentType: agentType,
        summary: report.summary,
        confidence: 1.0,
        ruleResults: report.results,
        recommendedServiceIds: [service.id],
        steps: points,
        nextActions: ['view_documents:${service.id}', 'view_service:${service.id}'],
        metadata: {
          'matchPercent': report.matchPercent,
          'isEligible': report.isEligible,
          'isDeterministicOnly': true,
        },
      );
    }

    // 4. Ground with LLM reasoning using deterministic check
    final relevantSources = knowledgeRepo.getSourcesForService(service.id);
    final systemPrompt = buildSystemPrompt(AgentPrompts.eligibility);

    final contextBlock = StringBuffer();
    contextBlock.writeln(PromptContextBuilder.buildSystemContext(
      profile: request.profile,
      vault: request.vault,
      services: [service],
      sources: relevantSources,
      language: request.language,
    ));
    contextBlock.writeln(engine.formatReportForPrompt(report));

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

      final parsedResult = await validator.validateAndParse(
        rawInput: rawResponse,
        agentType: agentType,
        catalog: catalog,
        vault: request.vault,
        sources: relevantSources,
        groqClient: groqClient,
      );

      return parsedResult.copyWith(
        ruleResults: report.results,
        metadata: {
          ...parsedResult.metadata,
          'matchPercent': report.matchPercent,
          'isEligible': report.isEligible,
        },
      );
    } catch (e) {
      // Fall back gracefully to deterministic report
      return AgentResult(
        agentType: agentType,
        summary: report.summary,
        confidence: 1.0,
        ruleResults: report.results,
        recommendedServiceIds: [service.id],
        metadata: {
          'matchPercent': report.matchPercent,
          'isEligible': report.isEligible,
          'fallbackReason': e.toString(),
        },
      );
    }
  }

  GovService? _findService(String? serviceId, String query) {
    if (serviceId != null) {
      try {
        return catalog.firstWhere((s) => s.id == serviceId);
      } catch (_) {}
    }
    final lower = query.toLowerCase();
    for (final s in catalog) {
      if (lower.contains(s.id.toLowerCase()) || lower.contains(s.name.toLowerCase())) {
        return s;
      }
      for (final kw in s.keywords) {
        if (lower.contains(kw.toLowerCase())) {
          return s;
        }
      }
    }
    return catalog.isNotEmpty ? catalog.first : null;
  }
}
