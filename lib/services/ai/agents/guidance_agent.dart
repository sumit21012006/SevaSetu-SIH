import '../../../models/document.dart';
import '../../../models/readiness.dart';
import '../../../models/service.dart';
import '../ai_config.dart';
import '../context/prompt_context_builder.dart';
import '../models/agent_request.dart';
import '../models/agent_result.dart';
import '../models/agent_type.dart';
import '../prompts/agent_prompts.dart';
import '../validation/response_validator.dart';
import 'base_agent.dart';

/// Specialized agent for document preparation, readiness analysis, and application guidance.
class GuidanceAgent extends BaseAgent {
  GuidanceAgent({
    required super.groqClient,
    required super.knowledgeRepo,
    required super.catalog,
    this.validator = const ResponseValidator(),
  });

  final ResponseValidator validator;

  @override
  AgentType get agentType => AgentType.guidance;

  @override
  Future<AgentResult> execute(AgentRequest request) async {
    final service = _findService(request.serviceId, request.query);
    if (service == null) {
      return AgentResult.error(
        agentType: agentType,
        errorMessage: 'Please specify which service or scheme you need document guidance for.',
      );
    }

    // 1. Compute exact app readiness using single source of truth
    final readiness = computeReadiness(service, request.vault);

    // 2. Compute document reuse map across catalog
    final docReuseMap = _buildDocReuseMap(request.vault, service);

    // 3. If offline or no API key, build deterministic guidance
    if (!AIConfig.hasApiKey) {
      return _buildDeterministicResult(service, readiness);
    }

    // 4. Build prompt context blocks
    final relevantSources = knowledgeRepo.getSourcesForService(service.id);
    final systemPrompt = buildSystemPrompt(AgentPrompts.guidance);

    final contextBlock = StringBuffer();
    contextBlock.writeln(PromptContextBuilder.buildSystemContext(
      profile: request.profile,
      vault: request.vault,
      services: [service],
      sources: relevantSources,
      language: request.language,
    ));

    contextBlock.writeln('### [READINESS] (App-calculated numbers — DO NOT RECALCULATE):');
    contextBlock.writeln('service_id: ${service.id}');
    contextBlock.writeln('ready_count: ${readiness.readyCount}');
    contextBlock.writeln('total_mandatory: ${readiness.requiredCount}');
    contextBlock.writeln('percent: ${readiness.percent}%');
    contextBlock.writeln('expiring_count: ${readiness.expiringChecks.length}');
    contextBlock.writeln('expired_count: ${readiness.expiredChecks.length}');
    contextBlock.writeln('missing_count: ${readiness.missingChecks.length}');
    contextBlock.writeln('invalid_count: ${readiness.invalidChecks.length}');
    contextBlock.writeln('zip_count: ${readiness.zipDocuments.length}');
    contextBlock.writeln();

    contextBlock.writeln('### [DOC_REUSE_MAP]:');
    contextBlock.writeln(docReuseMap);
    contextBlock.writeln();

    contextBlock.writeln('### [SERVICE_KNOWLEDGE]:');
    contextBlock.writeln('Apply Portal: ${service.applyPortal}');
    contextBlock.writeln('Helpline: ${service.helpline}');
    contextBlock.writeln('Process Steps:');
    for (int i = 0; i < service.process.length; i++) {
      final step = service.process[i];
      contextBlock.writeln('  ${i + 1}. ${step.title}: ${step.detail}');
    }
    if (service.importantDates.isNotEmpty) {
      contextBlock.writeln('Important Dates:');
      for (final d in service.importantDates) {
        contextBlock.writeln('  - ${d.title}: ${d.range}');
      }
    }

    final messages = buildMessages(
      systemPrompt: systemPrompt,
      contextBlock: contextBlock.toString(),
      request: request,
    );

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
    } catch (e) {
      return _buildDeterministicResult(service, readiness, fallbackReason: e.toString());
    }
  }

  AgentResult _buildDeterministicResult(
    GovService service,
    ReadinessSummary readiness, {
    String? fallbackReason,
  }) {
    final isReady = readiness.isFullyReady;
    final List<String> points = [];
    final List<String> actions = [];

    if (isReady) {
      points.add('All ${readiness.requiredCount} required documents are verified and ready.');
      actions.add('download_zip:${service.id}');
      actions.add('view_service:${service.id}');
    } else {
      for (final exp in readiness.expiredChecks) {
        points.add('${exp.requirement.type.title} is expired. Please renew it at the issuing office.');
        actions.add('upload_document:${exp.requirement.type.name}');
      }
      for (final miss in readiness.missingChecks) {
        points.add('${miss.requirement.type.title} is missing from your vault.');
        if (!actions.any((a) => a.contains(miss.requirement.type.name))) {
          actions.add('upload_document:${miss.requirement.type.name}');
        }
      }
      if (readiness.zipDocuments.isNotEmpty) {
        actions.add('download_zip:${service.id}');
      }
      actions.add('view_documents:${service.id}');
    }

    final summary = isReady
        ? 'You are 100% ready to apply for ${service.name}. All required documents are verified in your vault.'
        : 'Not yet. ${readiness.readyCount} of ${readiness.requiredCount} required documents are ready; the ZIP contains only those ${readiness.readyCount}. Please address the missing or expired documents.';

    return AgentResult(
      agentType: agentType,
      summary: summary,
      confidence: 1.0,
      recommendedServiceIds: [service.id],
      steps: points,
      nextActions: actions,
      metadata: {
        'readyCount': readiness.readyCount,
        'totalCount': readiness.requiredCount,
        'percent': readiness.percent,
        if (fallbackReason != null) 'fallbackReason': fallbackReason,
      },
    );
  }

  String _buildDocReuseMap(List<CitizenDocument> vault, GovService currentService) {
    final buffer = StringBuffer();
    for (final doc in vault) {
      final reusableIn = catalog
          .where((s) => s.id != currentService.id && s.requiredDocuments.any((req) => req.type == doc.type))
          .map((s) => s.name)
          .toList();

      if (reusableIn.isNotEmpty) {
        buffer.writeln('- ${doc.type.title} can also be reused for: ${reusableIn.join(", ")}');
      }
    }
    return buffer.isEmpty ? 'No cross-scheme reuse detected.' : buffer.toString();
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
