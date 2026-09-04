import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/readiness.dart';
import '../models/service.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/readiness_widgets.dart';
import '../widgets/status_widgets.dart';
import '../widgets/zip_widgets.dart';
import 'doc_actions.dart';

/// Dedicated full-screen Document Readiness Checker for one service.
class ReadinessScreen extends StatelessWidget {
  const ReadinessScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final service = state.serviceById(serviceId);
    final summary = state.readinessFor(service);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Application Readiness')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xs,
          AppSpacing.page,
          AppSpacing.xxl + 32,
        ),
        children: [
          _ScoreHero(service: service, summary: summary),
          const Gap(AppSpacing.lg),
          const SectionHeader(title: 'Your Documents'),
          for (final check in summary.checks)
            RequirementDocTile(
              check: check,
              onUpload: () => openDocumentUpload(
                context,
                type: check.requirement.type,
                reasonLabel: check.requirement.why,
              ),
              onViewDocument: check.document == null
                  ? null
                  : () => openDocDetail(context, check.document!.id),
              onVerify: check.document == null
                  ? null
                  : () => runCheckValidity(context, check.document!),
              onRenew: () => openDocumentUpload(
                context,
                type: check.requirement.type,
                reasonLabel: check.requirement.why,
              ),
            ),
          const Gap(AppSpacing.xs),
          _BottomActions(service: service, summary: summary),
        ],
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.service, required this.summary});
  final GovService service;
  final ReadinessSummary summary;

  @override
  Widget build(BuildContext context) {
    final color = readinessColor(summary.percent);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.12), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard + 4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.name,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              ReadinessRing(percent: summary.percent, size: 148, stroke: 12),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.percent}%',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 1,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                Icons.check_circle_rounded,
                AppColors.success,
                '${summary.readyCount} Ready',
              ),
              if (summary.expiringChecks.isNotEmpty)
                _chip(
                  Icons.schedule_rounded,
                  AppColors.warning,
                  '${summary.expiringChecks.length} Expiring Soon',
                ),
              if (summary.missingChecks.isNotEmpty)
                _chip(
                  Icons.remove_circle_outline_rounded,
                  AppColors.danger,
                  '${summary.missingChecks.length} Missing',
                ),
              if (summary.expiredChecks.isNotEmpty)
                _chip(
                  Icons.cancel_rounded,
                  AppColors.danger,
                  '${summary.expiredChecks.length} Expired',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, Color color, String label) {
    return Pill(
      label: label,
      icon: icon,
      color: color,
      background: color.withValues(alpha: 0.1),
      compact: true,
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.service, required this.summary});
  final GovService service;
  final ReadinessSummary summary;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.isFullyReady
                ? 'Everything is ready — you can apply. 🎉'
                : summary.attentionCount == 1
                ? "You're almost ready to apply."
                : 'Resolve the remaining documents to reach 100%.',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (!summary.isFullyReady) ...[
            const SizedBox(height: 6),
            Text(
              '${summary.attentionCount} document'
              '${summary.attentionCount == 1 ? '' : 's'} still need '
              'attention before you apply.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkFaint),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => prepareServiceZip(context, service),
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  label: Text(
                    'Download ${summary.zipDocuments.length} Ready '
                    'Document${summary.zipDocuments.length == 1 ? '' : 's'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (summary.attentionCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => state.openDocumentsTab(),
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Resolve Missing Documents'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
