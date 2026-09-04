import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/application.dart';
import '../models/journey.dart';
import '../models/readiness.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/readiness_widgets.dart';
import '../widgets/status_widgets.dart';
import '../widgets/timeline_widgets.dart';
import '../widgets/zip_widgets.dart';
import 'application_detail_screen.dart';
import 'tab_top.dart';

class JourneyTab extends StatefulWidget {
  const JourneyTab({super.key});

  @override
  State<JourneyTab> createState() => _JourneyTabState();
}

class _JourneyTabState extends State<JourneyTab> {
  String? _selectedApplicationId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    var apps = state.applications.toList()
      ..sort((a, b) => b.startedOn.compareTo(a.startedOn));
    // Keep in-progress journeys first.
    apps.sort((a, b) => _activeRank(a).compareTo(_activeRank(b)));

    if (apps.isEmpty) {
      return TabPage(
        children: [
          TabHeader(title: state.tr('nav.journey')),
          const Gap(AppSpacing.xl * 2),
          EmptyState(
            icon: Icons.route_rounded,
            title: 'Your journey starts here',
            message:
                'Open any service and tap “Start Journey”. SevaSetu will walk '
                'you from discovery all the way to tracking your application.',
            actionLabel: 'Browse services',
            onAction: () => state.goToTab(AppTabs.services),
          ),
        ],
      );
    }

    final active = _selectedApplicationId == null
        ? apps.first
        : apps.firstWhere(
            (a) => a.id == _selectedApplicationId,
            orElse: () => apps.first,
          );
    final service = state.serviceById(active.serviceId);
    final journey = state.journeyFor(active);
    final summary = state.readinessFor(service);

    return TabPage(
      children: [
        TabHeader(
          title: state.tr('nav.journey'),
          subtitle: 'Your guided path to ${service.name}',
        ),
        const Gap(AppSpacing.lg),
        if (apps.length > 1) ...[
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: apps.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final app = apps[i];
                final selected = app.id == active.id;
                return ChoiceChip(
                  label: Text(app.serviceName),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) =>
                      setState(() => _selectedApplicationId = app.id),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.inkSoft,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          const Gap(AppSpacing.lg),
        ],

        _CurrentPhaseCard(
          journey: journey,
          summary: summary,
          serviceId: service.id,
        ),
        const Gap(AppSpacing.xl),

        if (journey.currentIndex < journey.steps.length &&
            journey.steps[journey.currentIndex].phase == PhaseId.documents) ...[
          const SectionHeader(title: 'Documents being prepared'),
          SoftCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReadinessCaption(summary: summary, fontSize: 14.5),
                const SizedBox(height: 6),
                Text(
                  '${summary.attentionCount} document'
                  '${summary.attentionCount == 1 ? '' : 's'} still need '
                  'attention.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkFaint,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ReadinessBar(percent: summary.percent, height: 8),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => prepareServiceZip(context, service),
                        icon: const Icon(Icons.archive_outlined, size: 18),
                        label: Text(
                          'Download ${summary.zipDocuments.length} Ready',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => state.openDocumentsTab(),
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: const Text('Resolve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.xl),
        ],

        const SectionHeader(title: 'Your path'),
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: JourneyTimeline(
            journey: journey,
            subtitles: _phaseSubtitles(active, journey, summary),
          ),
        ),
        const Gap(AppSpacing.xl),

        const SectionHeader(title: 'Next step guidance'),
        _GuidanceCard(
          phase: journey.steps[journey.currentIndex].phase,
          app: active,
          serviceId: service.id,
        ),
      ],
    );
  }

  Map<PhaseId, String> _phaseSubtitles(
    ServiceApplication app,
    ServiceJourney journey,
    ReadinessSummary summary,
  ) {
    return {
      PhaseId.discover: 'Started ${_daysAgo(app.startedOn)}',
      PhaseId.documents:
          '${summary.readyCount}/${summary.requiredCount} documents ready',
    };
  }

  int _daysAgo(DateTime d) => DateTime.now().difference(d).inDays;

  int _activeRank(ServiceApplication app) {
    if (app.isApproved || app.isRejected) return 1;
    return 0;
  }
}

class _CurrentPhaseCard extends StatelessWidget {
  const _CurrentPhaseCard({
    required this.journey,
    required this.summary,
    required this.serviceId,
  });

  final ServiceJourney journey;
  final ReadinessSummary summary;
  final String serviceId;

  @override
  Widget build(BuildContext context) {
    final step = journey.steps[journey.currentIndex];
    final phase = step.phase;
    final color = phaseColor(phase);
    final complete = step.isCompleted;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.16), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard + 4),
        border: Border.all(color: color.withValues(alpha: 0.32)),
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
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  complete ? Icons.check_rounded : _currentIcon(step),
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete ? 'Stage completed' : 'You are here',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _phaseTitle(step),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (summary.requiredCount > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${summary.percent}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: readinessColor(summary.percent),
                      ),
                    ),
                    Text(
                      'ready',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkFaint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _phaseDetail(phase),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.inkSoft,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  IconData _currentIcon(JourneyStep step) {
    switch (step.phase) {
      case PhaseId.discover:
        return Icons.travel_explore_rounded;
      case PhaseId.eligibility:
        return Icons.rule_rounded;
      case PhaseId.documents:
        return Icons.folder_open_rounded;
      case PhaseId.verification:
        return Icons.verified_user_rounded;
      case PhaseId.guidance:
        return Icons.lightbulb_rounded;
      case PhaseId.apply:
        return Icons.send_rounded;
      case PhaseId.track:
        return Icons.manage_search_rounded;
    }
  }

  String _phaseTitle(JourneyStep step) {
    switch (step.phase) {
      case PhaseId.discover:
        return 'Discover';
      case PhaseId.eligibility:
        return 'Eligibility';
      case PhaseId.documents:
        return 'Documents';
      case PhaseId.verification:
        return 'Verification';
      case PhaseId.guidance:
        return 'Guidance';
      case PhaseId.apply:
        return 'Apply';
      case PhaseId.track:
        return 'Track';
    }
  }

  String _phaseDetail(PhaseId phase) {
    switch (phase) {
      case PhaseId.discover:
        return 'Service identified for your need. Explore requirements and '
            'check if this is the right scheme for you.';
      case PhaseId.eligibility:
        return 'Your profile is matched against the service rules. Review '
            'criteria you may not meet yet.';
      case PhaseId.documents:
        return 'Prepare the exact documents required. SevaSetu tracks what is '
            'ready, expiring or missing — and packs the ready ones for you.';
      case PhaseId.verification:
        return 'Uploaded documents are checked. Run validity checks and '
            'replace anything expired.';
      case PhaseId.guidance:
        return 'Personalised instructions for filling the form are ready.';
      case PhaseId.apply:
        return 'Everything is prepared — complete the application on the '
            'official portal and keep the reference number here.';
      case PhaseId.track:
        return 'SevaSetu keeps your application status updated here.';
    }
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({
    required this.phase,
    required this.app,
    required this.serviceId,
  });

  final PhaseId phase;
  final ServiceApplication app;
  final String serviceId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final service = state.serviceById(serviceId);

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'For the ${_phaseName(phase)} stage:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          _bullet('Check eligibility and rules on the official page.'),
          _bullet('Application mode: ${service.applicationMode}.'),
          _bullet('Apply at: ${service.applyPortal}.'),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    state.goToTab(AppTabs.applications);
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: Text(
                    app.isApproved
                        ? 'View Application'
                        : 'Track in Applications',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ApplicationDetailScreen(applicationId: app.id),
                    ),
                  ),
                  child: const Text('Application timeline'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _phaseName(PhaseId id) {
    switch (id) {
      case PhaseId.discover:
        return 'Discover';
      case PhaseId.eligibility:
        return 'Eligibility';
      case PhaseId.documents:
        return 'Documents';
      case PhaseId.verification:
        return 'Verification';
      case PhaseId.guidance:
        return 'Guidance';
      case PhaseId.apply:
        return 'Apply';
      case PhaseId.track:
        return 'Track';
    }
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 7, color: AppColors.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
