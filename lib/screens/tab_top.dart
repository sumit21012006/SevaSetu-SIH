import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../theme/app_colors.dart';
import '../widgets/action_widgets.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Standard top chrome for the five bottom-tab screens.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.light = false,
    this.extra,
  });

  final String title;
  final String? subtitle;
  final bool light;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final onSurface = light ? Colors.white : AppColors.ink;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: onSurface,
                  height: 1.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: light ? Colors.white70 : AppColors.inkFaint,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?extra,
        HeaderActions(
          light: light,
          onNotifications: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NotificationsScreen(),
            ),
          ),
          onProfile: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          ),
        ),
      ],
    );
  }
}

/// Scrollable container for a tab body with safe-area padding.
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.page,
      AppSpacing.lg,
      AppSpacing.page,
      AppSpacing.xxl + 40, // room for the assistant FAB
    ),
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: padding,
        children: children,
      ),
    );
  }
}
