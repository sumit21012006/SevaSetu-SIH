import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../theme/app_colors.dart';

/// Horizontal list of suggested follow-up questions citizen can tap to ask immediately.
class FollowUpChips extends StatelessWidget {
  const FollowUpChips({
    super.key,
    required this.questions,
    required this.onSelect,
  });

  final List<String> questions;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Row(
          children: questions.map((q) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ActionChip(
                avatar: const Icon(Icons.help_outline, size: 13, color: AppColors.aiPurple),
                label: Text(q),
                backgroundColor: AppColors.surface,
                side: BorderSide(color: AppColors.aiPurple.withValues(alpha: 0.3)),
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                onPressed: () => onSelect(q),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
