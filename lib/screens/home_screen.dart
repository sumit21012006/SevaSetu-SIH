import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/readiness.dart';
import '../models/service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import '../widgets/action_widgets.dart';
import '../widgets/common.dart';
import '../widgets/language_selector.dart';
import '../widgets/readiness_widgets.dart';
import '../widgets/search_input.dart';
import '../theme/app_theme.dart';
import '../widgets/service_widgets.dart';
import '../widgets/voice_input.dart';
import '../widgets/zip_widgets.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'readiness_screen.dart';
import 'service_details_screen.dart';
import 'tab_top.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final summary = state.readinessFor(state.primaryService);

    return TabPage(
      children: [
        // ---- Top: brand + language + bell/profile ----
        // The wordmark is scale-down fitted so this row can never overflow,
        // even on very narrow screens or large system font sizes.
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const BrandMark(showWordmark: true, wordmarkSize: 21),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            const LanguageBadge(),
            const SizedBox(width: AppSpacing.sm),
            HeaderActions(
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
        ),
        const Gap(AppSpacing.xl),

        // ---- Greeting ----
        Text(
          '${state.tr('greet.${Formatters.greetingKey()}')} 👋',
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: AppColors.ink,
          ),
        ),
        const Gap(4),
        Text(
          state.tr('home.subtitle'),
          style: const TextStyle(fontSize: 14.5, color: AppColors.inkSoft),
        ),
        const Gap(AppSpacing.xl),

        // ---- Find-a-service hero ----
        _AskHero(
          controller: _search,
          onVoice: _onVoice,
          onUpload: () => state.openDocumentsTab(uploadType: null),
          onSubmit: _submitQuery,
        ),
        const Gap(AppSpacing.xl),

        // ---- Document readiness hero (primary feature) ----
        SectionHeader(title: state.tr('home.readinessTitle')),
        _ReadinessHero(
          service: state.primaryService,
          summary: summary,
          onOpenReadiness: () => _openReadiness(state.primaryService),
          onDownload: () => prepareServiceZip(
            context,
            state.primaryService,
            onViewMissing: () => state.openDocumentsTab(),
          ),
        ),
        const Gap(AppSpacing.sm),
        const _TrustNote(),
        const Gap(AppSpacing.xl),

        // ---- Quick actions ----
        SectionHeader(title: state.tr('home.quickActions')),
        _QuickActions(state: state),
        const Gap(AppSpacing.xl),

        // ---- Recommended services (secondary to documents) ----
        SectionHeader(
          title: state.tr('home.recommended'),
          actionLabel: state.tr('action.viewAll'),
          onAction: () => state.goToTab(AppTabs.services),
        ),
        for (final service in state.services)
          _RecommendedCard(state: state, service: service),
      ],
    );
  }

  void _openReadiness(GovService service) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReadinessScreen(serviceId: service.id),
      ),
    );
  }

  void _submitQuery(String query) {
    final state = AppScope.of(context);
    final trimmed = query.trim();
    state.openServicesTab(trimmed);
  }

  Future<void> _onVoice() async {
    final text = await showVoiceCapture(context, samples: VoiceSamples.general);
    if (text == null || !mounted) return;
    _search.text = text;
    _submitQuery(text);
  }
}

class _AskHero extends StatelessWidget {
  const _AskHero({
    required this.controller,
    required this.onVoice,
    required this.onUpload,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onVoice;
  final VoidCallback onUpload;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123A85), Color(0xFF1D5CB0)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What government service are you looking for?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const Gap(AppSpacing.md),
          AskField(
            controller: controller,
            hint: 'Try: “I want to apply for a scholarship for my daughter”',
            primary: true,
            onSubmitted: onSubmit,
            onVoice: onVoice,
            onUpload: onUpload,
          ),
          const Gap(AppSpacing.sm + 2),
          const Text(
            'Describe it in your own words — even in Hindi or Marathi.',
            style: TextStyle(fontSize: 11.5, color: Colors.white60),
          ),
          const Gap(AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final text = controller.text.trim();
                onSubmit(text);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 52),
              ),
              icon: const Icon(Icons.travel_explore_rounded, size: 20),
              label: Text(state.tr('home.findService')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessHero extends StatelessWidget {
  const _ReadinessHero({
    required this.service,
    required this.summary,
    required this.onOpenReadiness,
    required this.onDownload,
  });

  final GovService service;
  final ReadinessSummary summary;
  final VoidCallback onOpenReadiness;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Application Readiness',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onOpenReadiness,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft(opacity: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Full report',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          Row(
            children: [
              ReadinessRing(percent: summary.percent, size: 132, stroke: 11),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendRow(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                      label: '${summary.readyCount} Ready',
                    ),
                    const SizedBox(height: 10),
                    _legendRow(
                      icon: Icons.schedule_rounded,
                      color: AppColors.warning,
                      label: '${summary.expiringChecks.length} Expiring Soon',
                    ),
                    const SizedBox(height: 10),
                    _legendRow(
                      icon: Icons.cancel_rounded,
                      color: AppColors.danger,
                      label:
                          '${summary.missingChecks.length + summary.expiredChecks.length} Missing / Expired',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      summary.message,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenReadiness,
                  icon: const Icon(Icons.fact_check_outlined, size: 19),
                  label: const Text('Check My Documents'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.archive_outlined, size: 19),
                  label: const Text('📦 Download ZIP'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_outlined, size: 14, color: AppColors.inkFaint),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            AppBrand.trustNote,
            style: const TextStyle(fontSize: 11.5, color: AppColors.inkFaint),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final actions = [
      QuickActionData(
        label: 'Find a Service',
        subtitle: 'Browse 1000+ schemes',
        icon: Icons.travel_explore_rounded,
        color: AppColors.primary,
        onTap: () => state.goToTab(AppTabs.services),
      ),
      QuickActionData(
        label: 'My Documents',
        subtitle: 'Your secure vault',
        icon: Icons.folder_copy_rounded,
        color: AppColors.secondary,
        onTap: () => state.goToTab(AppTabs.documents),
      ),
      QuickActionData(
        label: 'Check Eligibility',
        subtitle: 'Personal match',
        icon: Icons.how_to_reg_rounded,
        color: AppColors.warning,
        onTap: () => state.goToTab(AppTabs.services),
      ),
      QuickActionData(
        label: 'My Journey',
        subtitle: 'Next step guidance',
        icon: Icons.route_rounded,
        color: AppColors.aiPurple,
        onTap: () => state.goToTab(AppTabs.journey),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final action in actions)
              SizedBox(
                width: tileWidth,
                child: QuickActionTile(action: action),
              ),
          ],
        );
      },
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.state, required this.service});

  final AppState state;
  final GovService service;

  @override
  Widget build(BuildContext context) {
    final summary = state.readinessFor(service);
    final match = state.eligibilityFor(service).matchPercent;
    return ServiceCard(
      service: service,
      summary: summary,
      matchPercent: match,
      compact: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ServiceDetailsScreen(serviceId: service.id),
        ),
      ),
    );
  }
}
