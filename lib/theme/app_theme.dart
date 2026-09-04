import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import 'app_colors.dart';

/// Builds the SevaSetu Material 3 light theme.
///
/// The palette is tuned for a trustworthy Indian civic-tech feel:
/// clean light surfaces, deep blue primary, teal secondary, restrained
/// shadows and generous rounded corners.
ThemeData buildAppTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  );

  final scheme = base.copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primarySoft(opacity: 0.16),
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondarySoft(),
    onSecondaryContainer: AppColors.secondaryDark,
    tertiary: AppColors.aiPurple,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.aiPurpleSoft,
    onTertiaryContainer: AppColors.aiPurple,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkSoft,
    outline: AppColors.hairline,
    outlineVariant: AppColors.hairline,
    surfaceContainerHighest: AppColors.surfaceMuted,
    surfaceContainerHigh: const Color(0xFFF0F3F9),
    surfaceContainer: const Color(0xFFF3F6FB),
    surfaceContainerLow: const Color(0xFFF7F9FC),
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerBg,
    onErrorContainer: AppColors.danger,
  );

  const shadowColor = Color(0x140F2F6E);
  final shadows = <BoxShadow>[
    BoxShadow(color: shadowColor, blurRadius: 18, offset: const Offset(0, 6)),
    BoxShadow(
      color: Color(0x0A0F2F6E),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: InkRipple.splashFactory,
  );

  final textTheme = baseTheme.textTheme.apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );

  return baseTheme.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
      actionsIconTheme: const IconThemeData(color: AppColors.ink),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      shadowColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.4),
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.inkFaint, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primarySoft(opacity: 0.12),
      surfaceTintColor: Colors.transparent,
      height: 68,
      elevation: 0,
      shadowColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primary : AppColors.inkFaint,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.inkFaint,
        );
      }),
    ),
    chipTheme: baseTheme.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceMuted,
      selectedColor: AppColors.primarySoft(opacity: 0.16),
      labelStyle: const TextStyle(
        color: AppColors.inkSoft,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      side: const BorderSide(color: Colors.transparent),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.inkSoft,
      textColor: AppColors.ink,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.surfaceMuted,
      circularTrackColor: AppColors.surfaceMuted,
    ),
    dividerColor: AppColors.hairline,
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.inkFaint,
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[AppCardShadows(shadows)],
  );
}

/// Theme extension carrying the soft card shadow list.
@immutable
class AppCardShadows extends ThemeExtension<AppCardShadows> {
  const AppCardShadows(this.shadows);

  final List<BoxShadow> shadows;

  @override
  AppCardShadows copyWith({List<BoxShadow>? shadows}) =>
      AppCardShadows(shadows ?? this.shadows);

  @override
  AppCardShadows lerp(AppCardShadows? other, double t) => this;
}

/// A decorated container that gives cards their subtle shadow + border.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
    this.color = AppColors.surface,
    this.radius = AppSpacing.radiusCard,
    this.onTap,
    this.borderColor = AppColors.hairline,
    this.borderWidth = 1,
    this.inkHost = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;
  final double radius;
  final VoidCallback? onTap;
  final Color borderColor;
  final double borderWidth;

  /// Hosts an inner [Material] so descendants such as [ListTile] paint
  /// their tile colour and ink on a Material that sits above this card's
  /// decoration (otherwise ListTile assertions fire and ripples are hidden).
  final bool inkHost;

  @override
  Widget build(BuildContext context) {
    final shadow = Theme.of(context).extension<AppCardShadows>()?.shadows.first;
    final boxDecoration = BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: shadow == null ? null : [shadow],
    );

    final childWidget = Padding(padding: padding, child: child);
    final Widget content;
    if (onTap != null) {
      content = _hostMaterial(InkWell(onTap: onTap, child: childWidget));
    } else if (inkHost) {
      content = _hostMaterial(childWidget);
    } else {
      content = childWidget;
    }
    return Container(margin: margin, decoration: boxDecoration, child: content);
  }

  /// A transparent [Material] clipped to the card radius, placed above the
  /// card's decoration so ink and tile colours are visible.
  Widget _hostMaterial(Widget child) {
    return Material(
      type: MaterialType.transparency,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
