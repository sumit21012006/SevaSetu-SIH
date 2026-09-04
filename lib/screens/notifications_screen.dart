import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/notification_card.dart';
import 'service_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final notifications = state.notificationsForDisplay;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.any((n) => !n.read))
            TextButton(
              onPressed: state.markAllNotificationsRead,
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              message:
                  'Updates about your documents, journey and applications '
                  'will appear here.',
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.page),
              children: [
                for (final notification in notifications)
                  NotificationCard(
                    notification: notification,
                    onTap: () => _open(context, state, notification),
                  ),
              ],
            ),
    );
  }

  void _open(BuildContext context, state, notification) {
    state.markNotificationRead(notification.id);
    if (notification.serviceId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ServiceDetailsScreen(serviceId: notification.serviceId!),
        ),
      );
    }
  }
}
