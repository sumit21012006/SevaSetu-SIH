import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../services/ai/knowledge/knowledge_repository.dart';
import '../../theme/app_colors.dart';

/// Bottom sheet allowing citizens to choose a sample GR or paste custom resolution text.
class GRInputSheet extends StatefulWidget {
  const GRInputSheet({
    super.key,
    required this.knowledgeRepo,
    required this.onSelect,
  });

  final KnowledgeRepository knowledgeRepo;
  final void Function(String text, String? serviceId) onSelect;

  static Future<void> show(
    BuildContext context, {
    required KnowledgeRepository knowledgeRepo,
    required void Function(String text, String? serviceId) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GRInputSheet(
        knowledgeRepo: knowledgeRepo,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<GRInputSheet> createState() => _GRInputSheetState();
}

class _GRInputSheetState extends State<GRInputSheet> {
  final _textController = TextEditingController();
  bool _isPastingCustom = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusCard)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.description_outlined, color: AppColors.aiPurple),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Simplify Government Resolution (GR)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Select a known scheme GR to simplify, or paste text from any official circular.',
                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Segmented selection
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: !_isPastingCustom ? AppColors.aiPurpleSoft : Colors.transparent,
                        side: BorderSide(
                          color: !_isPastingCustom ? AppColors.aiPurple : AppColors.hairline,
                        ),
                      ),
                      onPressed: () => setState(() => _isPastingCustom = false),
                      child: Text(
                        'Choose Preset GR',
                        style: TextStyle(
                          color: !_isPastingCustom ? AppColors.aiPurple : AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _isPastingCustom ? AppColors.aiPurpleSoft : Colors.transparent,
                        side: BorderSide(
                          color: _isPastingCustom ? AppColors.aiPurple : AppColors.hairline,
                        ),
                      ),
                      onPressed: () => setState(() => _isPastingCustom = true),
                      child: Text(
                        'Paste Custom Text',
                        style: TextStyle(
                          color: _isPastingCustom ? AppColors.aiPurple : AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              if (!_isPastingCustom) ...[
                const Text(
                  'Preset Official Resolutions:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...widget.knowledgeRepo.grEntries.map((entry) {
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
                      side: const BorderSide(color: AppColors.hairline),
                    ),
                    child: ListTile(
                      title: Text(
                        entry.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                      ),
                      subtitle: Text(
                        'GR No. ${entry.grNumber} • ${entry.department}',
                        style: const TextStyle(fontSize: 11, color: AppColors.inkFaint),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.aiPurple),
                      onTap: () async {
                        final text = await widget.knowledgeRepo.loadGRText(entry.filename);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          widget.onSelect(text, entry.serviceId);
                        }
                      },
                    ),
                  );
                }),
              ] else ...[
                TextField(
                  controller: _textController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Paste official GR text, government order, or eligibility clauses here...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.inkFaint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
                      borderSide: const BorderSide(color: AppColors.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
                      borderSide: const BorderSide(color: AppColors.aiPurple, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Simplify Pasted Resolution'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.aiPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.of(context).pop();
                        widget.onSelect(text, null);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
