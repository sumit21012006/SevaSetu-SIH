import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../services/ai/models/agent_type.dart';
import '../../theme/app_colors.dart';

/// Horizontal chip selector allowing the user to select an agent or Auto mode.
class AgentSelectorBar extends StatelessWidget {
  const AgentSelectorBar({
    super.key,
    required this.selectedAgent,
    required this.onSelect,
  });

  final AgentType? selectedAgent;
  final ValueChanged<AgentType?> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <(AgentType?, String, IconData)>[
      (null, 'Auto Router', Icons.alt_route_rounded),
      (AgentType.recommendation, 'Find Schemes', Icons.auto_awesome),
      (AgentType.eligibility, 'Eligibility', Icons.verified_user_outlined),
      (AgentType.guidance, 'Guidance', Icons.checklist_rtl_rounded),
      (AgentType.grSimplifier, 'Simplify GR', Icons.description_outlined),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.xs),
      child: Row(
        children: items.map((item) {
          final isSelected = selectedAgent == item.$1;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              avatar: Icon(
                item.$3,
                size: 14,
                color: isSelected ? Colors.white : AppColors.inkSoft,
              ),
              label: Text(item.$2),
              selected: isSelected,
              showCheckmark: false,
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.aiPurple,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.aiPurple : AppColors.hairline,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              onSelected: (_) => onSelect(item.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}
