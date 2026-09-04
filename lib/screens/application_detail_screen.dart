import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/enum_ui.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/status_widgets.dart';
import '../widgets/timeline_widgets.dart';
import '../widgets/zip_widgets.dart';
import 'service_details_screen.dart';

class ApplicationDetailScreen extends StatelessWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final apps = state.applications.where((a) => a.id == applicationId);
    if (apps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Application')),
        body: const EmptyState(
          icon: Icons.feed_outlined,
          title: 'Application not found',
          message: 'This application is no longer tracked.',
        ),
      );
    }
    final app = apps.first;
    final service = state.serviceById(app.serviceId);
    final style = applicationPhaseUi(app.currentPhase);
    final summary = state.readinessFor(service);
    final terminal = app.isApproved || app.isRejected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Application Tracking')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xs,
          AppSpacing.page,
          AppSpacing.xxl + 32,
        ),
        children: [
          // ---- Header ----
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  style.color.withValues(alpha: 0.16),
                  AppColors.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard + 4),
              border: Border.all(color: style.color.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: style.color,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(style.icon, size: 23, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.serviceName,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            app.department,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.inkFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Status',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.inkFaint,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            app.currentPhase.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: style.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            app.statusDetail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.inkSoft,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (app.applicationNumber != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          size: 15,
                          color: AppColors.inkSoft,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          app.applicationNumber!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: terminal
                            ? null
                            : () => state.advanceApplication(app.id),
                        icon: const Icon(Icons.fast_forward_rounded, size: 18),
                        label: const Text('Simulate next update'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ServiceDetailsScreen(serviceId: service.id),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('View Service'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.xl),

          // ---- Status line ----
          if (app.isApproved) ...[
            _banner(
              Icons.celebration_rounded,
              AppColors.success,
              'Approved! The benefit will be released to your account. '
              'Keep an eye on notifications.',
            ),
            const Gap(AppSpacing.xl),
          ] else if (app.isRejected) ...[
            _banner(
              Icons.info_outline_rounded,
              AppColors.danger,
              'This application was rejected. Check the department notice '
              'and re-apply if you qualify.',
            ),
            const Gap(AppSpacing.xl),
          ],

          // ---- Readiness of this service ----
          if (!app.isApproved &&
              !app.isRejected &&
              summary.requiredCount > 0) ...[
            const SectionHeader(title: 'Document Readiness'),
            SoftCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 66,
                        height: 66,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: summary.percent / 100,
                              strokeWidth: 6,
                              strokeCap: StrokeCap.round,
                              color: readinessColor(summary.percent),
                              backgroundColor: AppColors.surfaceMuted,
                            ),
                            Center(
                              child: Text(
                                '${summary.percent}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: readinessColor(summary.percent),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${summary.readyCount} of ${summary.requiredCount} '
                              'documents ready',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary.message,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.inkFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (summary.zipDocuments.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: () => prepareServiceZip(context, service),
                      icon: const Icon(Icons.archive_outlined, size: 18),
                      label: Text(
                        'Download ${summary.zipDocuments.length} Ready '
                        'Documents',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(AppSpacing.xl),
          ],

          // ---- Timeline ----
          const SectionHeader(title: 'Timeline'),
          SoftCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ApplicationTimeline(app: app),
          ),
        ],
      ),
    );
  }

  Widget _banner(IconData icon, Color color, String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
