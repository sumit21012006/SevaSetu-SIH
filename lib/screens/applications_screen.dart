import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/enum_ui.dart';
import '../models/application.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'application_detail_screen.dart';
import 'tab_top.dart';

class ApplicationsTab extends StatelessWidget {
  const ApplicationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final apps = state.applications.toList()
      ..sort((a, b) => b.startedOn.compareTo(a.startedOn));

    return TabPage(
      children: [
        TabHeader(
          title: state.tr('nav.applications'),
          subtitle: 'Track every application you have started.',
        ),
        const Gap(AppSpacing.lg),
        if (apps.isEmpty)
          EmptyState(
            icon: Icons.feed_outlined,
            title: 'No applications yet',
            message:
                'Start a journey from any service and it will appear here '
                'for tracking.',
            actionLabel: 'Browse services',
            onAction: () => state.goToTab(AppTabs.services),
          )
        else
          for (final app in apps) _AppCard(app: app),
      ],
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.app});
  final ServiceApplication app;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final service = state.serviceById(app.serviceId);
    final phaseStyle = applicationPhaseUi(app.currentPhase);
    final ordered = ApplicationPhase.values;
    final progress = (ordered.indexOf(app.currentPhase) + 1) / ordered.length;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ApplicationDetailScreen(applicationId: app.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: phaseStyle.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(phaseStyle.icon, size: 21, color: phaseStyle.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.serviceName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.department,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkFaint,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.circle, size: 9, color: phaseStyle.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  app.currentPhase.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: phaseStyle.color,
                  ),
                ),
              ),
              Text(
                '${state.readinessFor(service).percent}% docs ready',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.inkFaint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: phaseStyle.color,
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
