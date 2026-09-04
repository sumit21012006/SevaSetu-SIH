import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/enum_ui.dart';
import '../models/document.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/status_widgets.dart';
import 'doc_actions.dart';
import 'service_details_screen.dart';

class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final doc = state.documentById(documentId);
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document')),
        body: const EmptyState(
          icon: Icons.folder_off_outlined,
          title: 'Document not found',
          message: 'This document is no longer in your vault.',
        ),
      );
    }

    final color = categoryColor(doc.type.category);
    final usedBy = [
      for (final service in state.services)
        if (service.requiredDocuments.any((r) => r.type == doc.type)) service,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(doc.title)),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.xxl + 32,
        ),
        children: [
          // ---- Document preview placeholder ----
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.16), AppColors.surface],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        documentTypeIcon(doc.type),
                        size: 54,
                        color: color.withValues(alpha: 0.75),
                      ),
                      const SizedBox(height: AppSpacing.sm + 2),
                      Text(
                        doc.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Document preview',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: StatusPill(status: doc.status, compact: true),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.lg),

          // ---- Metadata ----
          SoftCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                _metaRow(
                  Icons.verified_user_rounded,
                  'Verification',
                  _verificationLabel(doc),
                ),
                const Gap(AppSpacing.md),
                _metaRow(
                  Icons.calendar_today_rounded,
                  'Uploaded',
                  Formatters.date(doc.uploadedAt),
                ),
                if (doc.issuedAt != null) ...[
                  const Gap(AppSpacing.md),
                  _metaRow(
                    Icons.event_note_rounded,
                    'Issued',
                    Formatters.date(doc.issuedAt!),
                  ),
                ],
                _metaRow(
                  Icons.hourglass_bottom_rounded,
                  'Validity',
                  _validityLabel(doc),
                ),
                const Gap(AppSpacing.md),
                _metaRow(
                  Icons.tag_rounded,
                  'Document number',
                  Formatters.maskedDocNumber(
                    doc.docNumber ?? doc.type.sampleNumber,
                  ),
                ),
                const Gap(AppSpacing.md),
                _metaRow(
                  Icons.account_balance_rounded,
                  'Issued by',
                  doc.issuer ?? doc.type.issuer,
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.xl),

          // ---- Used for ----
          const SectionHeader(title: 'Used for'),
          if (usedBy.isEmpty)
            const EmptyState(
              compact: true,
              icon: Icons.link_off_rounded,
              title: 'Not required by current services',
              message:
                  'This document is not needed by any service you are '
                  'tracking right now.',
            )
          else
            SoftCard(
              padding: EdgeInsets.zero,
              inkHost: true,
              child: Column(
                children: [
                  for (final service in usedBy)
                    ListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ServiceDetailsScreen(serviceId: service.id),
                        ),
                      ),
                      leading: DocIcon(type: doc.type, size: 38),
                      title: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: const Text('Tap to view service details'),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.inkFaint,
                      ),
                    ),
                ],
              ),
            ),
          const Gap(AppSpacing.xl),

          // ---- Actions ----
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewPreview(context, doc),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View Document'),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openDocumentReplace(context, doc),
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text('Replace Document'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => runCheckValidity(context, doc),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Check Validity'),
                ),
              ),
            ],
          ),
          if (doc.status == DocStatus.expired) ...[
            const Gap(AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This ${doc.title} has expired. Upload a renewed '
                      'certificate before applying.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _verificationLabel(CitizenDocument doc) {
    switch (doc.status) {
      case DocStatus.verified:
        return 'Verified';
      case DocStatus.verificationRequired:
        return 'Verification pending';
      case DocStatus.expired:
      case DocStatus.invalid:
        return 'Not valid';
      default:
        return 'Available';
    }
  }

  String _validityLabel(CitizenDocument doc) {
    final exp = doc.expiresAt;
    if (exp == null) return 'No expiry (lifetime)';
    return '${Formatters.date(exp)} • ${Formatters.daysUntil(exp) >= 0 ? Formatters.expiryPhrase(exp) : 'Expired'}';
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  void _viewPreview(BuildContext context, CitizenDocument doc) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DocIcon(type: doc.type),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        doc.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    StatusPill(status: doc.status, compact: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  AppBrand.demoNote,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkFaint,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
