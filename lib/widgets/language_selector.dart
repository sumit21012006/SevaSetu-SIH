import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../utils/l10n.dart';

/// Chip that opens the language picker sheet.
class LanguageBadge extends StatelessWidget {
  const LanguageBadge({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final lang = AppScope.of(context).language;
    return Material(
      color: light ? Colors.white24 : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: InkWell(
        onTap: () => openLanguageSelector(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.translate_rounded,
                size: 17,
                color: light ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                lang.nativeName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: light ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: light ? Colors.white : AppColors.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet language picker. Adding a language = new [AppLanguage] entry
/// + translations in [L10n]; this UI stays unchanged.
Future<void> openLanguageSelector(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final state = AppScope.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'App language for menus and status messages.',
                style: TextStyle(fontSize: 13, color: AppColors.inkFaint),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final lang in AppLanguage.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    onTap: () {
                      state.setLanguage(lang);
                      Navigator.of(sheetContext).pop();
                    },
                    tileColor: lang == state.language
                        ? AppColors.primarySoft(opacity: 0.10)
                        : AppColors.surfaceMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusTile,
                      ),
                    ),
                    leading: const Icon(Icons.translate_rounded, size: 22),
                    title: Text(
                      lang.nativeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      lang == AppLanguage.english ? 'English' : lang.nativeName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: lang == state.language
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
