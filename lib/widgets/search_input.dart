import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../theme/app_colors.dart';
import 'action_widgets.dart';

/// Natural-language ask field with optional trailing mode chips
/// (keyboard / voice / upload).
class AskField extends StatelessWidget {
  const AskField({
    super.key,
    required this.controller,
    required this.hint,
    this.onSubmitted,
    this.onChanged,
    this.onVoice,
    this.onUpload,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    this.primary = false,
    this.textInputAction = TextInputAction.search,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onVoice;
  final VoidCallback? onUpload;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool primary;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final fill = primary ? Colors.white.withValues(alpha: 0.15) : AppColors.surface;
    final borderColor = primary ? Colors.white24 : AppColors.hairline;
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile + 2),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          Icon(
            Icons.search_rounded,
            color: primary ? Colors.white70 : AppColors.inkFaint,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              readOnly: readOnly,
              onTap: onTap,
              autofocus: autofocus,
              textInputAction: textInputAction,
              style: TextStyle(
                fontSize: 15,
                color: primary ? Colors.white : AppColors.ink,
              ),
              cursorColor: primary ? Colors.white : AppColors.primary,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 14.5,
                  color: primary ? Colors.white60 : AppColors.inkFaint,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 2,
                ),
              ),
            ),
          ),
          if (onUpload != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InputModeChip(
                icon: Icons.upload_file_rounded,
                color: primary ? Colors.white : AppColors.secondary,
                onTap: onUpload,
                tooltip: 'Upload',
              ),
            ),
          if (onVoice != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InputModeChip(
                icon: Icons.mic_rounded,
                color: primary ? Colors.white : AppColors.aiPurple,
                onTap: onVoice,
                tooltip: 'Voice',
              ),
            ),
        ],
      ),
    );
  }
}
