import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../theme/app_colors.dart';

/// Card rendering structured Government Resolution (GR) simplification results.
class GRSummaryCard extends StatelessWidget {
  const GRSummaryCard({
    super.key,
    required this.grSummary,
  });

  final Map<String, dynamic> grSummary;

  @override
  Widget build(BuildContext context) {
    final title = grSummary['title'] as String? ?? 'Government Resolution Summary';
    final whatItIs = grSummary['what_it_is'] as String? ?? '';
    final eligibleList = (grSummary['who_is_eligible'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final docsList = (grSummary['documents_required'] as List<dynamic>? ?? []);
    final datesAmounts = (grSummary['key_dates_and_amounts'] as List<dynamic>? ?? []);
    final steps = (grSummary['what_you_need_to_do'] as List<dynamic>? ?? []).map((s) => s.toString()).toList();
    final warnings = (grSummary['watch_out_for'] as List<dynamic>? ?? []).map((w) => w.toString()).toList();
    final terms = (grSummary['hard_terms'] as List<dynamic>? ?? []);
    final notMentioned = (grSummary['not_mentioned'] as List<dynamic>? ?? []).map((n) => n.toString()).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
        border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.aiPurple.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.aiPurpleSoft,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusTile)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_rounded, color: AppColors.aiPurple, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (whatItIs.isNotEmpty) ...[
                  Text(
                    whatItIs,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Eligibility section
                if (eligibleList.isNotEmpty) ...[
                  _sectionTitle(Icons.people_outline, 'Who is Eligible:'),
                  ...eligibleList.map((e) => _bulletItem(e, Icons.check, AppColors.success)),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Key Dates & Amounts
                if (datesAmounts.isNotEmpty) ...[
                  _sectionTitle(Icons.calendar_today_outlined, 'Key Dates & Benefit Amounts:'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: datesAmounts.map((item) {
                      final label = item is Map ? item['label']?.toString() ?? '' : '';
                      final val = item is Map ? item['value']?.toString() ?? '' : item.toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft(opacity: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          '$label: $val',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Required Documents
                if (docsList.isNotEmpty) ...[
                  _sectionTitle(Icons.folder_shared_outlined, 'Documents Required by Resolution:'),
                  ...docsList.map((d) {
                    final name = d is Map ? d['document']?.toString() ?? '' : d.toString();
                    final why = d is Map ? d['why']?.toString() ?? '' : '';
                    return _bulletItem(
                      why.isNotEmpty ? '$name — $why' : name,
                      Icons.description_outlined,
                      AppColors.primary,
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                ],

                // What to do next
                if (steps.isNotEmpty) ...[
                  _sectionTitle(Icons.checklist_rounded, 'What You Need to Do:'),
                  ...steps.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.aiPurpleSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.aiPurple,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.ink),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Watch out for (warnings)
                if (warnings.isNotEmpty) ...[
                  _sectionTitle(Icons.warning_amber_rounded, 'Watch Out For:'),
                  ...warnings.map((w) => _bulletItem(w, Icons.priority_high, AppColors.warning)),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Hard terms explained
                if (terms.isNotEmpty) ...[
                  _sectionTitle(Icons.translate_rounded, 'Terms Explained:'),
                  ...terms.map((t) {
                    final term = t is Map ? t['term']?.toString() ?? '' : '';
                    final meaning = t is Map ? t['meaning']?.toString() ?? '' : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: AppColors.ink),
                          children: [
                            TextSpan(text: '• $term: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: meaning),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Not mentioned (Gaps in official text)
                if (notMentioned.isNotEmpty) ...[
                  _sectionTitle(Icons.help_outline_rounded, 'Not Mentioned in this Resolution:'),
                  ...notMentioned.map((n) => _bulletItem(n, Icons.remove, AppColors.inkFaint)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.inkSoft),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
