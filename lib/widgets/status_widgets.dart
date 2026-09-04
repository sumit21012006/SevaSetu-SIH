import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/enum_ui.dart';
import '../models/document.dart';
import '../models/readiness.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

String docStatusLabel(BuildContext context, DocStatus status) {
  final style = statusStyle(status);
  final localized = AppScope.of(context).tr(style.l10nKey);
  const fallback = {
    DocStatus.verified: 'Verified',
    DocStatus.available: 'Available',
    DocStatus.verificationRequired: 'Verification Required',
    DocStatus.expiringSoon: 'Expiring Soon',
    DocStatus.expired: 'Expired',
    DocStatus.invalid: 'Invalid',
    DocStatus.missing: 'Missing',
  };
  return localized == style.l10nKey ? fallback[status]! : localized;
}

/// Status chip — always icon + label, never colour alone.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
    this.compact = false,
    this.customLabel,
  });

  final DocStatus status;
  final bool compact;
  final String? customLabel;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);
    return Pill(
      label: customLabel ?? docStatusLabel(context, status),
      color: style.color,
      background: style.background,
      icon: style.icon,
      compact: compact,
    );
  }
}

/// Tinted square with a document icon.
class DocIcon extends StatelessWidget {
  const DocIcon({super.key, required this.type, this.size = 44, this.iconSize});

  final DocumentType type;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(type.category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        documentTypeIcon(type),
        size: iconSize ?? size * 0.5,
        color: color,
      ),
    );
  }
}

/// Full-width vault document card (Documents tab).
class VaultDocumentCard extends StatelessWidget {
  const VaultDocumentCard({
    super.key,
    required this.document,
    required this.onOpen,
    this.onReplace,
    this.onCheckValidity,
    this.usageServices = const [],
    this.onServiceTap,
    this.dense = false,
  });

  final CitizenDocument document;
  final VoidCallback onOpen;
  final VoidCallback? onReplace;
  final VoidCallback? onCheckValidity;

  /// Service names this document is used for.
  final List<String> usageServices;
  final ValueChanged<String>? onServiceTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final status = document.status;
    final color = categoryColor(document.type.category);
    return SoftCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DocIcon(type: document.type),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${document.type.category.label} • Uploaded '
                      '${Formatters.date(document.uploadedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(status: status, compact: true),
            ],
          ),
          if (!dense) ...[
            const SizedBox(height: AppSpacing.md),
            _validityRow(status, color),
          ],
          if (usageServices.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              'Used for',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [
                for (final name in usageServices)
                  InkWell(
                    onTap: onServiceTap == null
                        ? null
                        : () => onServiceTap!(name),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (!dense) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Row(
              children: [
                _actionChip(Icons.remove_red_eye_outlined, 'View', onOpen),
                if (onReplace != null)
                  _actionChip(
                    Icons.file_upload_outlined,
                    'Replace',
                    onReplace!,
                  ),
                if (onCheckValidity != null)
                  _actionChip(
                    Icons.fact_check_outlined,
                    'Check Validity',
                    onCheckValidity!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _validityRow(DocStatus status, Color color) {
    switch (status) {
      case DocStatus.expired:
        final exp = document.expiresAt;
        return Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: AppColors.danger,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                exp == null
                    ? 'Validity has lapsed'
                    : 'Expired on ${Formatters.date(exp)} — renew to use this document.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.danger),
              ),
            ),
          ],
        );
      case DocStatus.expiringSoon:
        final exp = document.expiresAt;
        return Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 16,
              color: AppColors.warning,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                exp == null
                    ? 'Validity ending soon'
                    : Formatters.expiryPhrase(exp),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        );
      case DocStatus.verificationRequired:
        return const Row(
          children: [
            Icon(Icons.fact_check_rounded, size: 16, color: AppColors.warning),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Available — run a validity check to verify this document.',
                style: TextStyle(fontSize: 12.5, color: AppColors.warning),
              ),
            ),
          ],
        );
      case DocStatus.verified:
      case DocStatus.available:
        return Row(
          children: [
            Icon(Icons.verified_rounded, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                document.expiresAt == null
                    ? 'Verified • No expiry'
                    : 'Verified • Valid until ${Formatters.date(document.expiresAt!)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ],
        );
      case DocStatus.invalid:
      case DocStatus.missing:
        return const Row(
          children: [
            Icon(Icons.gpp_bad_rounded, size: 16, color: AppColors.danger),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'This document cannot currently be used.',
                style: TextStyle(fontSize: 12.5, color: AppColors.danger),
              ),
            ),
          ],
        );
    }
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A required document within a service — status, reason, validity and an
/// action (Upload / Renew / View / Verify). This is the heart of the
/// personalized document recommendation UI.
class RequirementDocTile extends StatelessWidget {
  const RequirementDocTile({
    super.key,
    required this.check,
    required this.onUpload,
    this.onViewDocument,
    this.onVerify,
    this.onRenew,
  });

  final RequirementCheck check;
  final VoidCallback onUpload;
  final VoidCallback? onViewDocument;
  final VoidCallback? onVerify;
  final VoidCallback? onRenew;

  @override
  Widget build(BuildContext context) {
    final status = check.status;
    final type = check.requirement.type;
    final doc = check.document;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocIcon(type: type, size: 42),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            type.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusPill(status: status, compact: true),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      check.requirement.why,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                        height: 1.35,
                      ),
                    ),
                    if (doc != null && status == DocStatus.expiringSoon)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          'Valid until ${Formatters.date(doc.expiresAt!)}.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    if (doc != null && status == DocStatus.expired)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          'Expired on ${Formatters.date(doc.expiresAt!)} — '
                          'renew to proceed.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              Expanded(
                child: _tileAction(
                  icon: status == DocStatus.missing
                      ? Icons.add_photo_alternate_outlined
                      : status == DocStatus.expired
                      ? Icons.refresh_rounded
                      : Icons.file_upload_outlined,
                  label: status == DocStatus.missing
                      ? 'Upload'
                      : status == DocStatus.expired
                      ? 'Renew'
                      : 'Upload New',
                  onTap: onUpload,
                  primary:
                      status == DocStatus.missing ||
                      status == DocStatus.expired,
                ),
              ),
              if (doc != null &&
                  onVerify != null &&
                  status == DocStatus.verificationRequired) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _tileAction(
                    icon: Icons.fact_check_outlined,
                    label: 'Verify',
                    onTap: onVerify!,
                  ),
                ),
              ],
              if (doc != null && onViewDocument != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _tileAction(
                    icon: Icons.visibility_outlined,
                    label: 'View',
                    onTap: onViewDocument!,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _tileAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        foregroundColor: primary ? Colors.white : AppColors.primary,
        backgroundColor: primary ? AppColors.primary : Colors.transparent,
        side: BorderSide(
          color: primary ? AppColors.primary : AppColors.hairline,
        ),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
        ),
      ),
    );
  }
}

/// Small bar showing readiness percent inside compact cards.
class ReadinessBar extends StatelessWidget {
  const ReadinessBar({super.key, required this.percent, this.height = 6});

  final int percent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = readinessColor(percent);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: percent / 100,
          color: color,
          backgroundColor: AppColors.surfaceMuted,
        ),
      ),
    );
  }
}

Color readinessColor(int percent) {
  if (percent >= 100) return AppColors.success;
  if (percent >= 60) return AppColors.secondary;
  if (percent >= 40) return AppColors.warning;
  return AppColors.danger;
}
