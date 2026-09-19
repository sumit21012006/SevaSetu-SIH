import 'agent_result.dart';
import 'agent_type.dart';

/// Event emitted during agent orchestration to communicate real-time progress.
sealed class AgentEvent {
  const AgentEvent();
}

class AgentRoutingStarted extends AgentEvent {
  const AgentRoutingStarted(this.query);
  final String query;
}

class AgentSelected extends AgentEvent {
  const AgentSelected(this.agentType, this.reason);
  final AgentType agentType;
  final String reason;
}

class AgentStepStarted extends AgentEvent {
  const AgentStepStarted(this.agentType, this.stepDescription);
  final AgentType agentType;
  final String stepDescription;
}

class AgentStepProgress extends AgentEvent {
  const AgentStepProgress(this.agentType, this.details);
  final AgentType agentType;
  final String details;
}

class AgentCompleted extends AgentEvent {
  const AgentCompleted(this.result);
  final AgentResult result;
}

class AgentFailed extends AgentEvent {
  const AgentFailed(this.agentType, this.errorMessage, {this.details});
  final AgentType agentType;
  final String errorMessage;
  final String? details;
}
