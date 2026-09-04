import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/enum_ui.dart';
import '../models/readiness.dart';
import '../models/service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/readiness_widgets.dart';
import '../widgets/service_widgets.dart';
import '../widgets/status_widgets.dart';
import '../widgets/zip_widgets.dart';
import 'doc_actions.dart';

class ServiceDetailsScreen extends StatelessWidget {
  const ServiceDetailsScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final service = state.serviceById(serviceId);
    final summary = state.readinessFor(service);
    final report = state.eligibilityFor(service);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(service.name)),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl + 40),
        children: [
          _HeroCard(service: service),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Service overview ----
                const SectionHeader(title: 'Service Overview'),
                Text(
                  service.description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.inkSoft,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ---- Eligibility (personal match) ----
                const SectionHeader(title: 'Your Eligibility'),
                EligibilityCard(
                  report: report,
                  onFixDocuments: summary.attentionCount > 0
                      ? () => state.openDocumentsTab()
                      : null,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- Documents You Need (prominent) ----
                _DocumentsSection(service: service, summary: summary),
                const SizedBox(height: AppSpacing.xl),

                // ---- Journey CTA ----
                _JourneyCta(service: service, summary: summary),
                const SizedBox(height: AppSpacing.xl),

                // ---- Application process ----
                const SectionHeader(title: 'Application Process'),
                _ProcessSteps(steps: service.process),
                const SizedBox(height: AppSpacing.xl),

                // ---- Important dates ----
                const SectionHeader(title: 'Important Dates'),
                _DateCard(dates: service.importantDates),
                const SizedBox(height: AppSpacing.xl),

                // ---- Where to apply / official info ----
                const SectionHeader(title: 'Where to Apply'),
                _ApplyInfo(service: service),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient header with category identity.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.service});
  final GovService service;

  @override
  Widget build(BuildContext context) {
    final color = serviceCategoryColor(service.category);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xl,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.white, 0.22)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  serviceCategoryIcon(service.category),
                  size: 28,
                  color: Colors.white,
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
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      service.department,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
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
              _glassPill(Icons.category_rounded, service.category.label),
              _glassPill(Icons.public_rounded, service.scope),
              _glassPill(Icons.language_rounded, service.applicationMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Prominent personalized document section: count chips, doc list with
/// status + actions, readiness caption and the ZIP download card.
class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({required this.service, required this.summary});

  final GovService service;
  final ReadinessSummary summary;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard + 4),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_copy_rounded,
                  size: 21,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Documents You Need',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Based on your profile and this service, you need '
                      '${summary.requiredCount} documents.',
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
          const SizedBox(height: AppSpacing.md),
          _countChips(summary),
          const SizedBox(height: AppSpacing.xs),
          ReadinessCaption(summary: summary),
          const SizedBox(height: AppSpacing.lg),
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
          ZipDownloadCard(
            serviceName: service.name,
            summary: summary,
            onDownload: () => state.createZip(service),
            onViewMissing: () => state.openDocumentsTab(),
            prominent: true,
          ),
        ],
      ),
    );
  }

  Widget _countChips(ReadinessSummary summary) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Pill(
          label: '${summary.readyCount} Ready',
          color: AppColors.success,
          background: AppColors.successBg,
          icon: Icons.check_circle_rounded,
        ),
        if (summary.expiringChecks.isNotEmpty)
          Pill(
            label: '${summary.expiringChecks.length} Expiring Soon',
            color: AppColors.warning,
            background: AppColors.warningBg,
            icon: Icons.schedule_rounded,
          ),
        if (summary.missingChecks.isNotEmpty)
          Pill(
            label: '${summary.missingChecks.length} Missing',
            color: AppColors.danger,
            background: AppColors.dangerBg,
            icon: Icons.remove_circle_outline_rounded,
          ),
        if (summary.expiredChecks.isNotEmpty)
          Pill(
            label: '${summary.expiredChecks.length} Expired',
            color: AppColors.danger,
            background: AppColors.dangerBg,
            icon: Icons.cancel_rounded,
          ),
      ],
    );
  }
}

/// Start / continue the personalised journey for this service.
class _JourneyCta extends StatelessWidget {
  const _JourneyCta({required this.service, required this.summary});

  final GovService service;
  final ReadinessSummary summary;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final app = state.applicationFor(service.id);
    final started = app != null;
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  size: 21,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Service Journey',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      started
                          ? '${app.currentPhase.label} • '
                                '${summary.readyCount}/${summary.requiredCount} '
                                'documents ready'
                          : 'Follow a guided path from discovery to tracking.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ReadinessBar(percent: summary.percent),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    state.startJourney(service);
                    state.goToTab(AppTabs.journey);
                  },
                  icon: Icon(
                    started ? Icons.play_arrow_rounded : Icons.add_rounded,
                  ),
                  label: Text(started ? 'Continue Journey' : 'Start Journey'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => state.openDocumentsTab(),
                  icon: const Icon(Icons.folder_open_rounded),
                  label: Text(
                    summary.readyCount > 0 ? 'My Documents' : 'Documents',
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

/// Numbered application process steps.
class _ProcessSteps extends StatelessWidget {
  const _ProcessSteps({required this.steps});
  final List<ServiceStep> steps;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                i == 0 ? 0 : AppSpacing.md,
                AppSpacing.lg,
                i == steps.length - 1 ? 0 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[i].detail,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkSoft,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Key application dates.
class _DateCard extends StatelessWidget {
  const _DateCard({required this.dates});
  final List<ImportantDate> dates;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          for (final date in dates)
            ListTile(
              leading: const Icon(
                Icons.event_rounded,
                color: AppColors.warning,
              ),
              title: Text(
                date.title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                date.range,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkFaint,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Where and how to apply + official links.
class _ApplyInfo extends StatelessWidget {
  const _ApplyInfo({required this.service});
  final GovService service;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.laptop_mac_rounded, 'Mode', service.applicationMode),
          const SizedBox(height: AppSpacing.md),
          _infoRow(Icons.web_rounded, 'Apply at', service.applyPortal),
          if (service.helpline.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _infoRow(Icons.support_agent_rounded, 'Helpline', service.helpline),
          ],
          if (service.officialUrl.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _infoRow(
              Icons.link_rounded,
              'Official information',
              service.officialUrl,
            ),
          ],
          if (service.lastDateNote.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.alarm_on_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      service.lastDateNote,
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
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkFaint,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
