import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../services/ai/ai_config.dart';
import '../../services/ai/models/agent_result.dart';
import '../../theme/app_colors.dart';

/// Transparency panel showing model used, privacy assurances, and grounding mechanics.
class HowAnsweredPanel extends StatefulWidget {
  const HowAnsweredPanel({
    super.key,
    required this.result,
  });

  final AgentResult result;

  @override
  State<HowAnsweredPanel> createState() => _HowAnsweredPanelState();
}

class _HowAnsweredPanelState extends State<HowAnsweredPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.inkFaint),
                  const SizedBox(width: AppSpacing.xs),
                  const Text(
                    'How was this answered?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const Spacer(),
                  if (widget.result.fromCache)
                    Container(
                      margin: const EdgeInsets.only(right: AppSpacing.xs),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySoft(opacity: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CACHED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                    ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.inkFaint,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.hairline),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Agent Engine', widget.result.agentType.displayName),
                  _row(
                    'Model Used',
                    AIConfig.hasApiKey ? AIConfig.primaryModel : 'Deterministic Engine (Offline)',
                  ),
                  _row('Grounding Sources', '${widget.result.sources.length} cited Government Resolutions'),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.lock_outline, size: 12, color: AppColors.success),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Privacy Guarantee: Your name, phone number, document numbers, and uploaded files were completely excluded from the AI prompt.',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.35,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.inkFaint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
