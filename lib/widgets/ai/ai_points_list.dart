import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../theme/app_colors.dart';

/// Renders structured key takeaway points with semantic icon indicators.
class AIPointsList extends StatelessWidget {
  const AIPointsList({
    super.key,
    required this.points,
  });

  final List<String> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points.asMap().entries.map((entry) {
        final index = entry.key;
        final text = entry.value;
        final styleConfig = _classifyPoint(text, index);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: styleConfig.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  styleConfig.icon,
                  size: 14,
                  color: styleConfig.iconColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  _PointStyle _classifyPoint(String text, int index) {
    final lower = text.toLowerCase();
    if (lower.contains('ready') ||
        lower.contains('verified') ||
        lower.contains('pass') ||
        lower.contains('eligible') ||
        lower.contains('उपलब्ध') ||
        lower.contains('पात्र')) {
      return const _PointStyle(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        bgColor: AppColors.successBg,
      );
    }
    if (lower.contains('missing') ||
        lower.contains('expired') ||
        lower.contains('fail') ||
        lower.contains('problem') ||
        lower.contains('नाही') ||
        lower.contains('अपात्र')) {
      return const _PointStyle(
        icon: Icons.cancel_rounded,
        iconColor: AppColors.danger,
        bgColor: AppColors.dangerBg,
      );
    }
    if (lower.contains('warning') ||
        lower.contains('expiring') ||
        lower.contains('caution') ||
        lower.contains('लवकरच संपेल')) {
      return const _PointStyle(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.warning,
        bgColor: AppColors.warningBg,
      );
    }
    if (lower.contains('step') || lower.contains('action') || RegExp(r'^\d+\.').hasMatch(text)) {
      return const _PointStyle(
        icon: Icons.play_arrow_rounded,
        iconColor: AppColors.aiPurple,
        bgColor: AppColors.aiPurpleSoft,
      );
    }
    return const _PointStyle(
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.info,
      bgColor: AppColors.infoBg,
    );
  }
}

class _PointStyle {
  const _PointStyle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
}
