import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../core/app_constants.dart';
import '../models/readiness.dart';
import '../models/service.dart';
import '../services/zip_service.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Prominent "Download Required Documents as ZIP" card.
///
/// Honest by design: it only ever packs documents that are ready. Anything
/// missing/expired is called out and excluded.
class ZipDownloadCard extends StatefulWidget {
  const ZipDownloadCard({
    super.key,
    required this.serviceName,
    required this.summary,
    required this.onDownload,
    this.onViewMissing,
    this.prominent = false,
  });

  final String serviceName;
  final ReadinessSummary summary;
  final Future<ZipPackResult> Function() onDownload;
  final VoidCallback? onViewMissing;
  final bool prominent;

  @override
  State<ZipDownloadCard> createState() => _ZipDownloadCardState();
}

class _ZipDownloadCardState extends State<ZipDownloadCard> {
  bool _busy = false;
  ZipPackResult? _result;
  String? _error;

  Future<void> _start() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.onDownload();
      if (!mounted) return;
      setState(() {
        _result = result;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not prepare the ZIP. Please try again.';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final ready = summary.zipDocuments.length;
    final missing = summary.missingChecks.length;
    final expired = summary.expiredChecks.length;
    final attention = missing + expired;

    return SoftCard(
      padding: EdgeInsets.all(widget.prominent ? AppSpacing.xl : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.archive_rounded,
                  size: 21,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Download Required Documents',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$ready of ${summary.requiredCount} required documents for '
            '${widget.serviceName} are ready.',
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
          if (attention > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$attention document${attention == 1 ? ' is' : 's are'} still '
              'missing or expired — $attention '
              '${attention == 1 ? 'document' : 'documents'} will NOT be included.',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.md),
            _SuccessPanel(result: _result!),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _start,
                child: const Text('Prepare again'),
              ),
            ),
          ] else if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            ErrorState(compact: true, message: _error!, onRetry: _start),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _start,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.archive_outlined, size: 20),
                    label: Text(
                      _busy
                          ? 'Preparing ZIP…'
                          : '📦 Download $ready '
                                'Document${ready == 1 ? '' : 's'} as ZIP',
                    ),
                  ),
                ),
              ],
            ),
            if (widget.onViewMissing != null && attention > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: widget.onViewMissing,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'View documents needing attention',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.result});

  final ZipPackResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ZIP prepared successfully',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.fileName,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${result.sizeLabel} • ${result.includedFiles.length} files saved '
            'to this device',
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// Convenience: builds the ZIP for [service] (with a short progress dialog)
/// and shows the result sheet. Used by quick actions across tabs.
Future<void> prepareServiceZip(
  BuildContext context,
  GovService service, {
  VoidCallback? onViewMissing,
}) async {
  final state = AppScope.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ZipPreparingDialog(),
  );
  try {
    final result = await state.createZip(service);
    if (!context.mounted) return;
    Navigator.of(context).pop(); // close progress
    if (!context.mounted) return;
    showZipResultSheet(context, result, onViewMissing: onViewMissing);
  } catch (_) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not prepare the ZIP right now.')),
    );
  }
}

class _ZipPreparingDialog extends StatelessWidget {
  const _ZipPreparingDialog();

  @override
  Widget build(BuildContext context) {
    return const Dialog(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(width: AppSpacing.lg),
            Text(
              'Packing your documents…',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a full ZIP result sheet after generation.
void showZipResultSheet(
  BuildContext context,
  ZipPackResult result, {
  VoidCallback? onViewMissing,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return Padding(
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
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 30,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your documents are packed',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        result.sizeLabel,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.fileName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final name in result.includedFiles)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            size: 14,
                            color: AppColors.inkFaint,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (result.missingDocuments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Not included (${result.missingDocuments.length} missing or '
                'expired): ${result.missingDocuments.join(', ')}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              'Saved to: ${result.filePath}',
              style: const TextStyle(fontSize: 11, color: AppColors.inkFaint),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      OpenFilex.open(result.filePath);
                    },
                    icon: const Icon(Icons.folder_zip_rounded, size: 18),
                    label: const Text('Open ZIP Archive'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
