import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../services/ai/models/ai_source.dart';
import '../../theme/app_colors.dart';
import 'source_sheet.dart';

/// Tap-able chip indicating how many official sources grounded this AI response.
class SourceChips extends StatelessWidget {
  const SourceChips({
    super.key,
    required this.sources,
  });

  final List<AISource> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: () => SourceSheet.show(context, sources),
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primarySoft(opacity: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 12, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Grounded in ${sources.length} ${sources.length == 1 ? "source" : "sources"}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
