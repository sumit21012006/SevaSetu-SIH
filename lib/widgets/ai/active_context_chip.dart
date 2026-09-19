import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../models/service.dart';
import '../../theme/app_colors.dart';

/// Pill showing active government scheme context scoped to current conversation.
class ActiveContextChip extends StatelessWidget {
  const ActiveContextChip({
    super.key,
    required this.service,
    required this.onClear,
  });

  final GovService service;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft(opacity: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark_outline_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Context: ${service.name}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(Icons.close, size: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
