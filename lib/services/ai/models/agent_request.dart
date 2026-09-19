import '../../../models/document.dart';
import '../../../models/profile.dart';
import '../../../utils/l10n.dart';
import 'agent_type.dart';
import 'chat_turn.dart';

/// Request parameters supplied to the AgentOrchestrator or individual agents.
class AgentRequest {
  const AgentRequest({
    required this.query,
    this.targetAgent,
    this.serviceId,
    this.profile,
    this.vault = const [],
    this.history = const [],
    this.language = AppLanguage.english,
    this.documentText,
    this.extraParams = const {},
  });

  final String query;
  final AgentType? targetAgent;
  final String? serviceId;
  final UserProfile? profile;
  final List<CitizenDocument> vault;
  final List<ChatTurn> history;
  final AppLanguage language;
  final String? documentText;
  final Map<String, dynamic> extraParams;

  AgentRequest copyWith({
    String? query,
    AgentType? targetAgent,
    String? serviceId,
    UserProfile? profile,
    List<CitizenDocument>? vault,
    List<ChatTurn>? history,
    AppLanguage? language,
    String? documentText,
    Map<String, dynamic>? extraParams,
  }) {
    return AgentRequest(
      query: query ?? this.query,
      targetAgent: targetAgent ?? this.targetAgent,
      serviceId: serviceId ?? this.serviceId,
      profile: profile ?? this.profile,
      vault: vault ?? this.vault,
      history: history ?? this.history,
      language: language ?? this.language,
      documentText: documentText ?? this.documentText,
      extraParams: extraParams ?? this.extraParams,
    );
  }
}
