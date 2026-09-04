import '../data/mock_store.dart';
import '../models/notification_item.dart';

/// In-app notification feed.
///
/// Future implementation: FCM push + a notifications table; the unread
/// badge contract stays the same.
abstract class NotificationService {
  List<AppNotification> list();
  int get unreadCount;
  void markRead(String id);
  void markAllRead();
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService(this._store);

  final AppDataStore _store;

  @override
  List<AppNotification> list() {
    final copy = [..._store.notifications];
    copy.sort((a, b) => b.at.compareTo(a.at));
    return copy;
  }

  @override
  int get unreadCount => _store.notifications.where((n) => !n.read).length;

  @override
  void markRead(String id) {
    final i = _store.notifications.indexWhere((n) => n.id == id);
    if (i >= 0) {
      final n = _store.notifications[i];
      if (!n.read) {
        _store.notifications[i] = AppNotification(
          id: n.id,
          kind: n.kind,
          title: n.title,
          body: n.body,
          at: n.at,
          read: true,
          serviceId: n.serviceId,
          actionLabel: n.actionLabel,
        );
      }
    }
  }

  @override
  void markAllRead() {
    _store.notifications = [
      for (final n in _store.notifications)
        n.read
            ? n
            : AppNotification(
                id: n.id,
                kind: n.kind,
                title: n.title,
                body: n.body,
                at: n.at,
                read: true,
                serviceId: n.serviceId,
                actionLabel: n.actionLabel,
              ),
    ];
  }
}
