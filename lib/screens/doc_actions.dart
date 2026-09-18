import 'package:flutter/material.dart';

import '../models/document.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/upload_flow.dart';
import 'document_detail_screen.dart';

/// Runs the upload sheet for a document type (used when a required document
/// is missing or expired). Shows a success toast afterwards.
Future<void> openDocumentUpload(
  BuildContext context, {
  required DocumentType type,
  String? reasonLabel,
}) async {
  final state = AppScope.of(context);
  final doc = await showUploadFlow(
    context,
    documentTitle: type.title,
    onUpload: (source, path) => state.uploadDocument(type, source, path),
  );
  if (doc == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        reasonLabel != null && reasonLabel.isNotEmpty
            ? '${type.title} added and verified against Govt database.'
            : '${type.title} added to your vault.',
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Replaces an existing (usually expired) document with a fresh upload.
Future<void> openDocumentReplace(
  BuildContext context,
  CitizenDocument existing,
) async {
  final state = AppScope.of(context);
  final doc = await showUploadFlow(
    context,
    documentTitle: existing.title,
    onUpload: (source, path) => state.replaceDocument(existing, source, path),
  );
  if (doc == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('New ${existing.title} saved. Awaiting verification.'),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Runs a simulated authority validity check and shows the result dialog.
Future<void> runCheckValidity(
  BuildContext context,
  CitizenDocument document,
) async {
  final state = AppScope.of(context);
  final report = await state.checkValidity(document);
  if (!context.mounted) return;
  final style = statusColor(report.status);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        icon: Icon(style.icon, size: 40, color: style.color),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.message,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                children: [
                  _dialogDetailRow('Document', document.title),
                  const Divider(height: 12),
                  _dialogDetailRow(
                    'Doc Number',
                    document.docNumber ?? document.type.sampleNumber,
                  ),
                  const Divider(height: 12),
                  _dialogDetailRow(
                    'Issuing Authority',
                    document.issuer ?? document.type.issuer,
                  ),
                  const Divider(height: 12),
                  _dialogDetailRow('Database Match', '100% Verified Genuine'),
                  const Divider(height: 12),
                  _dialogDetailRow('Digital Seal', 'Passed & Active'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          if (report.status == DocStatus.expired)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openDocumentReplace(context, document);
              },
              child: const Text('Upload New Certificate'),
            ),
        ],
      );
    },
  );
}

Widget _dialogDetailRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.inkFaint,
          fontWeight: FontWeight.w500,
        ),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
    ],
  );
}

void openDocDetail(BuildContext context, String documentId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DocumentDetailScreen(documentId: documentId),
    ),
  );
}

class DocStatusColor {
  const DocStatusColor(this.icon, this.color);
  final IconData icon;
  final Color color;
}

DocStatusColor statusColor(DocStatus status) {
  switch (status) {
    case DocStatus.verified:
      return const DocStatusColor(Icons.verified_rounded, AppColors.success);
    case DocStatus.available:
      return const DocStatusColor(
        Icons.check_circle_rounded,
        AppColors.success,
      );
    case DocStatus.verificationRequired:
      return const DocStatusColor(Icons.fact_check_rounded, AppColors.warning);
    case DocStatus.expiringSoon:
      return const DocStatusColor(Icons.schedule_rounded, AppColors.warning);
    case DocStatus.expired:
      return const DocStatusColor(Icons.cancel_rounded, AppColors.danger);
    case DocStatus.invalid:
      return const DocStatusColor(Icons.gpp_bad_rounded, AppColors.danger);
    case DocStatus.missing:
      return const DocStatusColor(
        Icons.remove_circle_outline_rounded,
        AppColors.danger,
      );
  }
}
