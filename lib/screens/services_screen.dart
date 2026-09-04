import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/search_input.dart';
import '../widgets/service_widgets.dart';
import '../services/ai_service.dart';
import '../services/service_discovery_service.dart';
import '../widgets/voice_input.dart';
import 'service_details_screen.dart';
import 'tab_top.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  final TextEditingController _controller = TextEditingController();
  ServiceCategory? _category;
  String _query = '';
  bool _hydrated = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    final state = AppScope.of(context);
    if (state.activeTabIndex != AppTabs.services) return;
    final pending = state.consumePendingServiceQuery();
    if (pending != null) _applyQuery(pending);
  }

  void _applyQuery(String q) {
    _controller.text = q;
    setState(() => _query = q);
  }

  void _search(String value) => setState(() => _query = value.trim());

  Future<void> _voice() async {
    final text = await showVoiceCapture(context, samples: VoiceSamples.general);
    if (text == null || !mounted) return;
    _applyQuery(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final results = state.searchServices(
      ServiceFilter(query: _query, category: _category),
    );

    return TabPage(
      children: [
        TabHeader(
          title: state.tr('nav.services'),
          subtitle: 'Find a Government Service',
        ),
        const Gap(AppSpacing.lg),
        AskField(
          controller: _controller,
          hint: 'Search or describe what you need…',
          onSubmitted: _search,
          onChanged: _search,
          onVoice: _voice,
        ),
        const Gap(AppSpacing.md),
        _CategoryChips(
          selected: _category,
          onSelect: (c) => setState(() => _category = c),
        ),
        const Gap(AppSpacing.lg),
        if (_query.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              '${results.length} service${results.length == 1 ? '' : 's'} '
              'found for “$_query”',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkFaint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (results.isEmpty)
          EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No services found',
            message:
                'Try different words — for example “scholarship”, “housing”, '
                '“kisan” or “job”. You can also ask the SevaSetu AI assistant.',
            actionLabel: 'Clear filters',
            onAction: () {
              _controller.clear();
              setState(() {
                _query = '';
                _category = null;
              });
            },
          )
        else
          for (final service in results)
            _ServiceResult(state: state, service: service),
      ],
    );
  }
}

class _ServiceResult extends StatelessWidget {
  const _ServiceResult({required this.state, required this.service});

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
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ServiceDetailsScreen(serviceId: service.id),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelect});

  final ServiceCategory? selected;
  final ValueChanged<ServiceCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <(ServiceCategory?, String)>[
      (null, 'All'),
      for (final c in ServiceCategory.values)
        if (c != ServiceCategory.other) (c, c.label),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (cat, label) = items[i];
          final active = cat == selected;
          return ChoiceChip(
            label: Text(label),
            selected: active,
            showCheckmark: false,
            onSelected: (_) => onSelect(cat),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: active ? Colors.white : AppColors.inkSoft,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.hairline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}
