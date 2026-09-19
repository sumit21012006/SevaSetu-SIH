import 'dart:async';
import '../../../models/service.dart';
import '../agents/eligibility_agent.dart';
import '../agents/gr_simplifier_agent.dart';
import '../agents/guidance_agent.dart';
import '../agents/recommendation_agent.dart';
import '../agents/router_agent.dart';
import '../cache/response_cache.dart';
import '../groq_client.dart';
import '../knowledge/knowledge_repository.dart';
import '../models/agent_event.dart';
import '../models/agent_request.dart';
import '../models/agent_result.dart';
import '../models/agent_type.dart';

/// Central multi-agent orchestrator coordinating routers, agents, streaming events, and caches.
class AgentOrchestrator {
  AgentOrchestrator({
    required this.catalog,
    GroqClient? groqClient,
    KnowledgeRepository? knowledgeRepo,
    ResponseCache? responseCache,
  })  : groqClient = groqClient ?? GroqClient(),
        knowledgeRepo = knowledgeRepo ?? KnowledgeRepository(),
        responseCache = responseCache ?? ResponseCache() {
    routerAgent = RouterAgent(
      groqClient: this.groqClient,
      catalog: catalog,
    );
    recommendationAgent = RecommendationAgent(
      groqClient: this.groqClient,
      knowledgeRepo: this.knowledgeRepo,
      catalog: catalog,
    );
    eligibilityAgent = EligibilityAgent(
      groqClient: this.groqClient,
      knowledgeRepo: this.knowledgeRepo,
      catalog: catalog,
    );
    guidanceAgent = GuidanceAgent(
      groqClient: this.groqClient,
      knowledgeRepo: this.knowledgeRepo,
      catalog: catalog,
    );
    grSimplifierAgent = GRSimplifierAgent(
      groqClient: this.groqClient,
      knowledgeRepo: this.knowledgeRepo,
      catalog: catalog,
    );
  }

  final List<GovService> catalog;
  final GroqClient groqClient;
  final KnowledgeRepository knowledgeRepo;
  final ResponseCache responseCache;

  late final RouterAgent routerAgent;
  late final RecommendationAgent recommendationAgent;
  late final EligibilityAgent eligibilityAgent;
  late final GuidanceAgent guidanceAgent;
  late final GRSimplifierAgent grSimplifierAgent;

  bool _initialized = false;

  /// Initializes knowledge repositories and assets.
  Future<void> initialize() async {
    if (_initialized) return;
    await knowledgeRepo.initialize();
    _initialized = true;
  }

  /// Processes request with streaming progress events for the UI.
  Stream<AgentEvent> processStream(AgentRequest request) async* {
    if (!_initialized) {
      await initialize();
    }

    final query = request.query.trim();

    // Check in-memory response cache
    final cacheKey = '${request.language.code}:${request.targetAgent?.name ?? "auto"}:${request.serviceId ?? ""}:$query';
    final cachedResult = responseCache.get(cacheKey);
    if (cachedResult != null) {
      yield AgentSelected(cachedResult.agentType, 'Retrieved from cache');
      yield AgentCompleted(cachedResult);
      return;
    }

    // 1. Determine Agent (either explicitly selected by user or routed via RouterAgent)
    AgentType chosenAgent;
    String? chosenServiceId = request.serviceId;

    if (request.targetAgent != null) {
      chosenAgent = request.targetAgent!;
      yield AgentSelected(chosenAgent, 'User selected ${chosenAgent.displayName}');
    } else {
      yield AgentRoutingStarted(query);
      final decision = await routerAgent.route(
        query: query,
        activeServiceId: request.serviceId,
      );
      chosenAgent = decision.agentType;
      chosenServiceId ??= decision.serviceHint;
      yield AgentSelected(
        chosenAgent,
        decision.isFallback ? 'Routed via intent keywords' : 'Routed via Intent Agent',
      );
    }

    // 2. Prepare tailored request
    final effectiveRequest = request.copyWith(
      targetAgent: chosenAgent,
      serviceId: chosenServiceId,
    );

    // 3. Execute selected agent with progress steps
    try {
      yield AgentStepStarted(chosenAgent, 'Analyzing requirements and sources...');

      final result = await _dispatchAgent(chosenAgent, effectiveRequest);

      // Cache successful responses
      if (result.isSuccess) {
        responseCache.put(cacheKey, result);
      }

      yield AgentCompleted(result);
    } catch (e) {
      yield AgentFailed(chosenAgent, e.toString());
    }
  }

  /// Synchronous future wrapper around processStream.
  Future<AgentResult> process(AgentRequest request) async {
    AgentResult? finalResult;
    String? lastError;
    AgentType currentAgent = request.targetAgent ?? AgentType.recommendation;

    await for (final event in processStream(request)) {
      if (event is AgentSelected) {
        currentAgent = event.agentType;
      } else if (event is AgentCompleted) {
        finalResult = event.result;
      } else if (event is AgentFailed) {
        lastError = event.errorMessage;
      }
    }

    return finalResult ??
        AgentResult.error(
          agentType: currentAgent,
          errorMessage: lastError ?? 'Failed to complete agent execution.',
        );
  }

  Future<AgentResult> _dispatchAgent(AgentType agentType, AgentRequest request) {
    switch (agentType) {
      case AgentType.recommendation:
        return recommendationAgent.execute(request);
      case AgentType.eligibility:
        return eligibilityAgent.execute(request);
      case AgentType.guidance:
        return guidanceAgent.execute(request);
      case AgentType.grSimplifier:
        return grSimplifierAgent.execute(request);
      case AgentType.router:
        return recommendationAgent.execute(request);
    }
  }

  void dispose() {
    groqClient.close();
  }
}
