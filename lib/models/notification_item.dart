/// In-app notification shown on the Notifications screen.
library;

enum NotificationKind { document, journey, application, tip }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.read = false,
    this.serviceId,
    this.actionLabel,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime at;
  final bool read;
  final String? serviceId;
  final String? actionLabel;
}
