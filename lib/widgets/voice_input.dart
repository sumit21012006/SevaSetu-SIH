import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../theme/app_colors.dart';

/// Simulated voice capture. Real STT (Hindi/Marathi/English) lands later via
/// a multilingual speech service — the UI contract stays: user speaks, a
/// recognised utterance string is returned.
Future<String?> showVoiceCapture(
  BuildContext context, {
  List<String> samples = const [],
}) async {
  if (samples.isEmpty) return null;
  final index = Random().nextInt(samples.length);
  final text = samples[index];
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _VoiceCaptureSheet(recognisedText: text),
  );
}

class _VoiceCaptureSheet extends StatefulWidget {
  const _VoiceCaptureSheet({required this.recognisedText});
  final String recognisedText;

  @override
  State<_VoiceCaptureSheet> createState() => _VoiceCaptureSheetState();
}

class _VoiceCaptureSheetState extends State<_VoiceCaptureSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  String _status = 'Listening…';
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(AppDurations.fakeVoice, () {
      if (!mounted) return;
      setState(() {
        _status = 'Processing…';
        _done = true;
      });
      _pulse.stop();
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        Navigator.of(context).pop(widget.recognisedText);
      });
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _done ? AppColors.success : AppColors.aiPurple;
    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 40, right: 40),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final scale = _done ? 1.0 : 1.0 + _pulse.value * 0.14;
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _done ? Icons.check_rounded : Icons.mic_rounded,
                size: 32,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _status,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (_done) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '“${widget.recognisedText}”',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSoft,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
