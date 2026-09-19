import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../services/ai/models/agent_type.dart';
import '../../theme/app_colors.dart';

/// Small badge or tag showing which specialized AI agent produced the response.
class AgentTag extends StatelessWidget {
  const AgentTag({
    super.key,
    required this.agentType,
    this.compact = false,
  });

  final AgentType agentType;
  final bool compact;

  IconData get _icon {
    switch (agentType) {
      case AgentType.recommendation:
        return Icons.auto_awesome;
      case AgentType.eligibility:
        return Icons.verified_user_outlined;
      case AgentType.guidance:
        return Icons.checklist_rtl_rounded;
      case AgentType.grSimplifier:
        return Icons.description_outlined;
      case AgentType.router:
        return Icons.alt_route_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.aiPurpleSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 12 : 14, color: AppColors.aiPurple),
          const SizedBox(width: AppSpacing.xs),
          Text(
            compact ? agentType.name : agentType.displayName,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: AppColors.aiPurple,
            ),
          ),
        ],
      ),
    );
  }
}
