import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../theme/app_colors.dart';

/// SevaSetu brand mark: gradient tile + bridge/hub glyph + optional wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 40,
    this.showWordmark = false,
    this.wordmarkSize = 20,
  });

  final double size;
  final bool showWordmark;
  final double wordmarkSize;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(size * 0.30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: size * 0.5,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Icon(Icons.hub_rounded, color: Colors.white, size: size * 0.58),
    );

    if (!showWordmark) return tile;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        tile,
        const SizedBox(width: AppSpacing.sm + 2),
        Text(
          AppBrand.name,
          style: TextStyle(
            fontSize: wordmarkSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.ink,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// Coloured pill with optional leading icon (chip-like, always icon+text).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 13 : 15, color: color),
            SizedBox(width: compact ? 3 : 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading with optional "View all" affordance.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.ink,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standard scaffold used by pushed (non-tab) screens.
class SevaPage extends StatelessWidget {
  const SevaPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.body,
    this.children,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.page,
      AppSpacing.sm,
      AppSpacing.page,
      AppSpacing.xxl,
    ),
    this.background,
    this.floatingActionButton,
  }) : assert(body == null || children == null);

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? body;
  final List<Widget>? children;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final content = children != null
        ? ListView(
            physics: const BouncingScrollPhysics(),
            padding: padding,
            children: children!,
          )
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: padding,
            child: body ?? const SizedBox(),
          );
    return Scaffold(
      backgroundColor: background ?? AppColors.background,
      appBar: AppBar(
        leading: leading,
        titleSpacing: subtitle == null ? 0 : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkFaint,
                ),
              ),
          ],
        ),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: content),
    );
  }
}

/// Vertical rhythm gap helper.
class Gap extends StatelessWidget {
  const Gap(this.height, {super.key});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 52 : 68,
          height: compact ? 52 : 68,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: compact ? 26 : 34, color: AppColors.inkFaint),
        ),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: AppColors.inkFaint),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
    if (compact) return content;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl * 1.4),
      child: Center(child: content),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label, this.compact = false});
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        if (label != null) ...[
          const SizedBox(width: AppSpacing.md),
          Text(
            label!,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
          ),
        ],
      ],
    );
    if (compact) return row;
    return Center(
      child: Padding(padding: const EdgeInsets.all(AppSpacing.xxl), child: row),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      compact: compact,
      icon: Icons.cloud_off_rounded,
      title: 'Something went wrong',
      message: message,
      actionLabel: onRetry == null ? null : 'Try Again',
      onAction: onRetry,
    );
  }
}
