/// A single conversational turn in an AI chat session.
class ChatTurn {
  const ChatTurn({
    required this.role,
    required this.content,
    this.timestamp,
  });

  factory ChatTurn.user(String content) => ChatTurn(
        role: 'user',
        content: content,
        timestamp: DateTime.now(),
      );

  factory ChatTurn.assistant(String content) => ChatTurn(
        role: 'assistant',
        content: content,
        timestamp: DateTime.now(),
      );

  factory ChatTurn.system(String content) => ChatTurn(
        role: 'system',
        content: content,
        timestamp: DateTime.now(),
      );

  final String role;
  final String content;
  final DateTime? timestamp;

  Map<String, dynamic> toGroqMessage() => {
        'role': role,
        'content': content,
      };
}
