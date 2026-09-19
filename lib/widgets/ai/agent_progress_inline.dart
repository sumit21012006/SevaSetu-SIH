import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../services/ai/models/agent_type.dart';
import '../../theme/app_colors.dart';
import 'agent_tag.dart';

/// Inline card showing active agent reasoning step and progress.
class AgentProgressInline extends StatelessWidget {
  const AgentProgressInline({
    super.key,
    required this.agentType,
    required this.stepDescription,
  });

  final AgentType agentType;
  final String stepDescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.aiPurpleSoft.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
        border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.aiPurple),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AgentTag(agentType: agentType, compact: true),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  stepDescription,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
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
