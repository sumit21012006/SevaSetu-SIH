import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/enum_ui.dart';
import '../models/application.dart';
import '../models/journey.dart';
import '../theme/app_colors.dart';
import 'common.dart';

class TimelineEntryData {
  const TimelineEntryData({
    required this.icon,
    required this.color,
    required this.state,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final PhaseState state;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
}

/// Reusable vertical timeline used by both the 7-phase journey and the
/// application tracking screens.
class AppTimeline extends StatelessWidget {
  const AppTimeline({super.key, required this.entries});

  final List<TimelineEntryData> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _row(entries[i], isLast: i == entries.length - 1),
      ],
    );
  }

  Widget _row(TimelineEntryData e, {required bool isLast}) {
    final completed = e.state == PhaseState.completed;
    final current = e.state == PhaseState.current;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Node + connector column.
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: current ? 30 : 26,
                  height: current ? 30 : 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed
                        ? e.color
                        : current
                        ? AppColors.surface
                        : AppColors.surfaceMuted,
                    border: Border.all(
                      color: completed
                          ? e.color
                          : current
                          ? e.color
                          : AppColors.hairline,
                      width: current ? 2.4 : 1.6,
                    ),
                    boxShadow: current
                        ? [
                            BoxShadow(
                              color: e.color.withValues(alpha: 0.25),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    completed
                        ? Icons.check_rounded
                        : current
                        ? Icons.circle
                        : e.icon,
                    size: completed
                        ? 15
                        : current
                        ? 12
                        : 14,
                    color: completed
                        ? Colors.white
                        : current
                        ? e.color
                        : AppColors.inkFaint,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: completed ? e.color : AppColors.hairline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Content.
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: e.state == PhaseState.upcoming
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: e.state == PhaseState.upcoming
                                ? AppColors.inkFaint
                                : AppColors.ink,
                          ),
                        ),
                        if (e.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            e.subtitle!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.inkFaint,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (e.trailing != null) ...[
                    const SizedBox(width: 8),
                    e.trailing!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Journey steps (phase id + state) mapped into the shared timeline.
class JourneyTimeline extends StatelessWidget {
  const JourneyTimeline({
    super.key,
    required this.journey,
    this.subtitles = const {},
    this.trailingBuilder,
  });

  final ServiceJourney journey;

  /// Optional custom captions per phase id.
  final Map<PhaseId, String> subtitles;
  final Widget Function(PhaseId phase, PhaseState state)? trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return AppTimeline(
      entries: [
        for (final step in journey.steps)
          TimelineEntryData(
            icon: journeyPhaseUi(step.phase).icon,
            color: phaseColor(step.phase),
            state: step.state,
            title: journeyPhaseUi(step.phase).label,
            subtitle: subtitles[step.phase],
            trailing: trailingBuilder?.call(step.phase, step.state),
          ),
      ],
    );
  }
}

/// Application phases mapped into the shared timeline.
class ApplicationTimeline extends StatelessWidget {
  const ApplicationTimeline({super.key, required this.app, this.onTapPhase});

  final ServiceApplication app;
  final void Function(ApplicationPhase phase)? onTapPhase;

  @override
  Widget build(BuildContext context) {
    return AppTimeline(
      entries: [
        for (final event in app.timeline)
          TimelineEntryData(
            icon: applicationPhaseUi(event.phase).icon,
            color: applicationPhaseUi(event.phase).color,
            state: event.state,
            title: event.phase.label,
            subtitle: _subtitleFor(event),
            trailing: event.isCurrent
                ? const Pill(
                    label: 'In progress',
                    color: AppColors.primary,
                    background: AppColors.infoBg,
                    compact: true,
                  )
                : null,
            onTap: onTapPhase == null ? null : () => onTapPhase!(event.phase),
          ),
      ],
    );
  }

  String? _subtitleFor(TimelineEvent event) {
    switch (event.phase) {
      case ApplicationPhase.serviceSelected:
        return 'Started ${_relative(app.startedOn)}';
      case ApplicationPhase.applicationSubmitted:
        return app.submittedOn == null
            ? null
            : 'Submitted ${_relative(app.submittedOn!)}';
      case ApplicationPhase.underVerification:
        return app.statusDetail;
      case ApplicationPhase.approved:
        return app.applicationNumber == null
            ? 'Benefit released.'
            : 'Reference: ${app.applicationNumber}';
      case ApplicationPhase.rejected:
        return 'Check the reason and re-apply if eligible.';
      default:
        return app.statusDetail;
    }
  }

  String _relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'just now';
  }
}

/// Accent colour per journey phase.
Color phaseColor(PhaseId phase) {
  switch (phase) {
    case PhaseId.discover:
      return AppColors.primary;
    case PhaseId.eligibility:
      return AppColors.info;
    case PhaseId.documents:
      return AppColors.secondary;
    case PhaseId.verification:
      return AppColors.aiPurple;
    case PhaseId.guidance:
      return const Color(0xFFB07A00);
    case PhaseId.apply:
      return const Color(0xFFC2410C);
    case PhaseId.track:
      return AppColors.success;
  }
}
