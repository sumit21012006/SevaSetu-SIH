/// Chat models for the SevaSetu AI assistant. Assistant replies are
/// structured: text plus actionable service / document cards, so the
/// assistant never behaves like a plain chatbot.
library;

import 'document.dart';

/// A structured line about one document shown inside an assistant reply.
class ChatDocLine {
  const ChatDocLine({
    required this.type,
    required this.status,
    required this.detail,
  });

  final DocumentType type;
  final DocStatus status;

  /// Supporting text (validity / why it is required).
  final String detail;
}

class ChatZipAction {
  const ChatZipAction({required this.serviceId, required this.count});
  final String serviceId;
  final int count;
}

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.fromUser,
    required this.text,
    this.serviceIds = const [],
    this.docLines = const [],
    this.zip,
    this.quickReplies = const [],
    this.contextServiceId,
  });

  final String id;
  final bool fromUser;

  /// Rendered as the bubble text.
  final String text;

  /// Services worth showing as action cards under this reply.
  final List<String> serviceIds;

  /// Document status lines (missing / expiring / available).
  final List<ChatDocLine> docLines;

  /// When non-null, the reply offers the ZIP download action.
  final ChatZipAction? zip;

  /// Suggested next questions the citizen can tap.
  final List<String> quickReplies;

  /// Service this reply refers to (used to route follow-up actions).
  final String? contextServiceId;
}
