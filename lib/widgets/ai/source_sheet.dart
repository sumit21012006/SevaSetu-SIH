import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../services/ai/models/ai_source.dart';
import '../../theme/app_colors.dart';

/// Modal bottom sheet displaying detailed government sources and resolutions.
class SourceSheet extends StatelessWidget {
  const SourceSheet({
    super.key,
    required this.sources,
  });

  final List<AISource> sources;

  static Future<void> show(BuildContext context, List<AISource> sources) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SourceSheet(sources: sources),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusCard)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Official Sources & Grounding (${sources.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.inkSoft),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.hairline),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.page),
              itemCount: sources.length,
              separatorBuilder: (_, __) => const Divider(height: 24, color: AppColors.hairline),
              itemBuilder: (context, index) {
                final src = sources[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            src.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.infoBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            src.id,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (src.documentNumber != null)
                      Text(
                        'Ref / GR No.: ${src.documentNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    Text(
                      'Authority: ${src.authority}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkFaint,
                      ),
                    ),
                    if (src.issueDate != null)
                      Text(
                        'Issued: ${src.issueDate}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    if (src.summary != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        src.summary!,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                    if (src.url != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Official Portal: ${src.url}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
