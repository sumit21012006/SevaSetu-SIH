import '../../../models/eligibility.dart';
import 'agent_type.dart';
import 'ai_source.dart';

/// Structured result returned by an AI agent or the AgentOrchestrator.
class AgentResult {
  const AgentResult({
    required this.agentType,
    required this.summary,
    this.confidence = 1.0,
    this.sources = const [],
    this.ruleResults = const [],
    this.recommendedServiceIds = const [],
    this.steps = const [],
    this.warnings = const [],
    this.nextActions = const [],
    this.metadata = const {},
    this.rawResponse,
    this.isSuccess = true,
    this.errorMessage,
    this.fromCache = false,
  });

  factory AgentResult.error({
    required AgentType agentType,
    required String errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return AgentResult(
      agentType: agentType,
      summary: errorMessage,
      confidence: 0.0,
      isSuccess: false,
      errorMessage: errorMessage,
      metadata: metadata ?? const {},
    );
  }

  factory AgentResult.fromJson(Map<String, dynamic> json, {AgentType? fallbackAgent}) {
    final agentStr = json['agent'] as String? ?? json['agentType'] as String?;
    final type = agentStr != null ? AgentType.fromString(agentStr) : (fallbackAgent ?? AgentType.recommendation);

    final rawSources = json['sources'] as List<dynamic>? ?? const [];
    final sources = rawSources
        .whereType<Map<String, dynamic>>()
        .map(AISource.fromJson)
        .toList();

    final rawSteps = json['steps'] as List<dynamic>? ??
        json['processSteps'] as List<dynamic>? ??
        const [];
    final steps = rawSteps.map((s) => s.toString()).toList();

    final rawWarnings = json['warnings'] as List<dynamic>? ?? const [];
    final warnings = rawWarnings.map((w) => w.toString()).toList();

    final rawNextActions = json['nextActions'] as List<dynamic>? ??
        json['next_actions'] as List<dynamic>? ??
        const [];
    final nextActions = rawNextActions.map((a) => a.toString()).toList();

    final rawRecServices = json['recommendedServiceIds'] as List<dynamic>? ??
        json['recommended_services'] as List<dynamic>? ??
        json['serviceIds'] as List<dynamic>? ??
        const [];
    final recommendedServiceIds = rawRecServices.map((s) => s.toString()).toList();

    final rawConfidence = json['confidence'];
    double confidence = 1.0;
    if (rawConfidence is num) {
      confidence = rawConfidence.toDouble();
    } else if (rawConfidence is String) {
      confidence = double.tryParse(rawConfidence) ?? 1.0;
    }

    final summary = json['summary'] as String? ??
        json['answer'] as String? ??
        json['response'] as String? ??
        json['message'] as String? ??
        '';

    return AgentResult(
      agentType: type,
      summary: summary,
      confidence: confidence,
      sources: sources,
      recommendedServiceIds: recommendedServiceIds,
      steps: steps,
      warnings: warnings,
      nextActions: nextActions,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      rawResponse: json['rawResponse'] as String?,
      isSuccess: json['isSuccess'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  final AgentType agentType;
  final String summary;
  final double confidence;
  final List<AISource> sources;
  final List<EligibilityRuleResult> ruleResults;
  final List<String> recommendedServiceIds;
  final List<String> steps;
  final List<String> warnings;
  final List<String> nextActions;
  final Map<String, dynamic> metadata;
  final String? rawResponse;
  final bool isSuccess;
  final String? errorMessage;
  final bool fromCache;

  AgentResult copyWith({
    AgentType? agentType,
    String? summary,
    double? confidence,
    List<AISource>? sources,
    List<EligibilityRuleResult>? ruleResults,
    List<String>? recommendedServiceIds,
    List<String>? steps,
    List<String>? warnings,
    List<String>? nextActions,
    Map<String, dynamic>? metadata,
    String? rawResponse,
    bool? isSuccess,
    String? errorMessage,
    bool? fromCache,
  }) {
    return AgentResult(
      agentType: agentType ?? this.agentType,
      summary: summary ?? this.summary,
      confidence: confidence ?? this.confidence,
      sources: sources ?? this.sources,
      ruleResults: ruleResults ?? this.ruleResults,
      recommendedServiceIds: recommendedServiceIds ?? this.recommendedServiceIds,
      steps: steps ?? this.steps,
      warnings: warnings ?? this.warnings,
      nextActions: nextActions ?? this.nextActions,
      metadata: metadata ?? this.metadata,
      rawResponse: rawResponse ?? this.rawResponse,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
        'agent': agentType.name,
        'summary': summary,
        'confidence': confidence,
        'sources': sources.map((s) => s.toJson()).toList(),
        'recommendedServiceIds': recommendedServiceIds,
        'steps': steps,
        'warnings': warnings,
        'nextActions': nextActions,
        'metadata': metadata,
        'isSuccess': isSuccess,
        if (errorMessage != null) 'errorMessage': errorMessage,
        'fromCache': fromCache,
      };
}
