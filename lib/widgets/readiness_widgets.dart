import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/readiness.dart';
import '../theme/app_colors.dart';
import 'status_widgets.dart';

/// Large circular document-readiness progress ring with center label.
class ReadinessRing extends StatelessWidget {
  const ReadinessRing({
    super.key,
    required this.percent,
    this.size = 150,
    this.stroke = 12,
    this.centerTitle,
    this.centerSubtitle,
  });

  final int percent;
  final double size;
  final double stroke;
  final String? centerTitle;
  final String? centerSubtitle;

  @override
  Widget build(BuildContext context) {
    final color = readinessColor(percent);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _RingPainter(
              value: percent / 100,
              color: color,
              stroke: stroke,
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerTitle ?? '$percent%',
                  style: TextStyle(
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: color,
                    height: 1,
                  ),
                ),
                if (centerSubtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    centerSubtitle!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkFaint,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.stroke,
    required this.backgroundColor,
  });

  final double value;
  final Color color;
  final double stroke;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = backgroundColor;
    canvas.drawCircle(center, radius, track);

    if (value <= 0) return;
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value.clamp(0.0, 1.0),
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.stroke != stroke ||
      old.backgroundColor != backgroundColor;
}

/// Legend row used inside readiness summaries (✓ Ready / ⚠ Expiring / ✕ Missing).
class ReadinessLegendRow extends StatelessWidget {
  const ReadinessLegendRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, color: AppColors.inkSoft),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

/// Line of text derived from the readiness state, e.g.
/// "4 of 6 documents ready • 2 need attention".
class ReadinessCaption extends StatelessWidget {
  const ReadinessCaption({
    super.key,
    required this.summary,
    this.fontSize = 13,
  });

  final ReadinessSummary summary;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = readinessColor(summary.percent);
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.inkSoft,
        ),
        children: [
          TextSpan(
            text:
                '${summary.readyCount} of ${summary.requiredCount} documents ready',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          if (summary.attentionCount > 0)
            TextSpan(
              text:
                  ' • ${summary.attentionCount} need${summary.attentionCount == 1 ? 's' : ''} attention',
            ),
        ],
      ),
    );
  }
}
