import '../../../models/service.dart';
import '../groq_client.dart';
import '../knowledge/knowledge_repository.dart';
import '../models/agent_request.dart';
import '../models/agent_result.dart';
import '../models/agent_type.dart';
import '../prompts/core_prompt.dart';
import '../prompts/output_contract.dart';

/// Base class for all SevaSetu AI specialized agents.
abstract class BaseAgent {
  const BaseAgent({
    required this.groqClient,
    required this.knowledgeRepo,
    required this.catalog,
  });

  final GroqClient groqClient;
  final KnowledgeRepository knowledgeRepo;
  final List<GovService> catalog;

  AgentType get agentType;

  /// Executes the agent's reasoning task.
  Future<AgentResult> execute(AgentRequest request);

  /// Assembles the complete system prompt = CorePrompt + AgentPrompt + OutputContract.
  String buildSystemPrompt(String specificPrompt) {
    return '''
${CorePrompt.text}

$specificPrompt

${OutputContract.text}
'''.trim();
  }

  /// Builds conversational message list for Groq Chat Completions.
  List<Map<String, dynamic>> buildMessages({
    required String systemPrompt,
    required String contextBlock,
    required AgentRequest request,
  }) {
    final List<Map<String, dynamic>> messages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    // Append up to last 6 chat history turns (assistant messages plain text only)
    final history = request.history.length > 6
        ? request.history.sublist(request.history.length - 6)
        : request.history;

    for (final turn in history) {
      messages.add(turn.toGroqMessage());
    }

    // Final user message containing context blocks + language + untrusted user text
    final finalUserContent = '''
$contextBlock

APP_LANGUAGE: ${request.language.code}
CITIZEN MESSAGE (untrusted user text): ${request.query}
'''.trim();

    messages.add({'role': 'user', 'content': finalUserContent});
    return messages;
  }
}
