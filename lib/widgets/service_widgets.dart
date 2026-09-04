import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/enum_ui.dart';
import '../models/eligibility.dart';
import '../models/readiness.dart';
import '../models/service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'status_widgets.dart';

/// Service card used in discovery lists and recommendations.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.summary,
    this.matchPercent,
    this.onTap,
    this.compact = false,
  });

  final GovService service;
  final ReadinessSummary summary;
  final int? matchPercent;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = serviceCategoryColor(service.category);
    return SoftCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  serviceCategoryIcon(service.category),
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      service.department,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
          if (!compact) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              service.shortDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Pill(
                label: service.category.label,
                color: color,
                background: color.withValues(alpha: 0.10),
                icon: serviceCategoryIcon(service.category),
                compact: true,
              ),
              if (matchPercent != null)
                Pill(
                  label: '$matchPercent% Eligibility Match',
                  color: matchPercent! >= 60
                      ? AppColors.success
                      : AppColors.warning,
                  background: matchPercent! >= 60
                      ? AppColors.successBg
                      : AppColors.warningBg,
                  icon: Icons.how_to_reg_rounded,
                  compact: true,
                ),
              Pill(
                label:
                    '${summary.readyCount}/${summary.requiredCount} Documents Ready',
                color: readinessColor(summary.percent),
                background: readinessColor(
                  summary.percent,
                ).withValues(alpha: 0.10),
                icon: Icons.folder_copy_rounded,
                compact: true,
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'View service',
                  style: TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, size: 18, color: color),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Eligibility block: match ring + pass/fail rule list.
class EligibilityCard extends StatelessWidget {
  const EligibilityCard({super.key, required this.report, this.onFixDocuments});

  final EligibilityReport report;
  final VoidCallback? onFixDocuments;

  @override
  Widget build(BuildContext context) {
    final percent = report.matchPercent;
    final color = percent >= 60 ? AppColors.success : AppColors.warning;
    final failed = report.failed;

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: percent / 100,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      color: color,
                      backgroundColor: AppColors.surfaceMuted,
                    ),
                    Center(
                      child: Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: color,
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
                      'Eligibility Match',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.summary,
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
          for (final result in report.results) ...[
            _ruleRow(result),
            const SizedBox(height: 4),
          ],
          if (failed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      failed
                          .map((f) => f.rule.failHint)
                          .where((t) => t.isNotEmpty)
                          .join(' '),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF8A4B06),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onFixDocuments != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onFixDocuments,
                  icon: const Icon(Icons.folder_open_rounded, size: 17),
                  label: const Text('Fix my documents'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _ruleRow(EligibilityRuleResult result) {
    final ok = result.passed;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 17,
            color: ok ? AppColors.success : AppColors.danger,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            result.rule.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ok ? AppColors.ink : AppColors.inkSoft,
              decoration: ok ? TextDecoration.none : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact service card embedded inside an AI assistant reply.
class AiServiceCard extends StatelessWidget {
  const AiServiceCard({
    super.key,
    required this.service,
    required this.matchPercent,
    required this.summary,
    required this.onOpenService,
    required this.onCheckEligibility,
    required this.onViewDocuments,
  });

  final GovService service;
  final int matchPercent;
  final ReadinessSummary summary;
  final VoidCallback onOpenService;
  final VoidCallback onCheckEligibility;
  final VoidCallback onViewDocuments;

  @override
  Widget build(BuildContext context) {
    final color = serviceCategoryColor(service.category);
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpenService,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    serviceCategoryIcon(service.category),
                    size: 19,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: AppColors.inkFaint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill(
                label: '$matchPercent% match',
                color: matchPercent >= 60
                    ? AppColors.success
                    : AppColors.warning,
                background: matchPercent >= 60
                    ? AppColors.successBg
                    : AppColors.warningBg,
                icon: Icons.how_to_reg_rounded,
                compact: true,
              ),
              Pill(
                label:
                    '${summary.readyCount}/${summary.requiredCount} docs ready',
                color: readinessColor(summary.percent),
                background: readinessColor(
                  summary.percent,
                ).withValues(alpha: 0.10),
                icon: Icons.folder_copy_rounded,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCheckEligibility,
                  icon: const Icon(Icons.how_to_reg_rounded, size: 15),
                  label: const Text(
                    'Check Eligibility',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewDocuments,
                  icon: const Icon(Icons.description_outlined, size: 15),
                  label: const Text(
                    'View Documents',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
