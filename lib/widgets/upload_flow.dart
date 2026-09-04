import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/document.dart';
import '../theme/app_colors.dart';

class _SourceOption {
  const _SourceOption(this.icon, this.label, this.subtitle, this.sourceLabel);
  final IconData icon;
  final String label;
  final String subtitle;
  final String sourceLabel;
}

const _options = [
  _SourceOption(
    Icons.photo_camera_rounded,
    'Take a photo',
    'Capture the original document clearly',
    'Camera',
  ),
  _SourceOption(
    Icons.folder_open_rounded,
    'Choose from files',
    'Pick an existing photo or PDF',
    'Device files',
  ),
  _SourceOption(
    Icons.document_scanner_rounded,
    'Scan document',
    'Auto-crop and sharpen the page',
    'Scanner',
  ),
];

/// Runs the simulated upload flow:
/// pick a source → animated upload progress → document added to vault.
///
/// Returns the new document, or null if the citizen cancelled.
Future<CitizenDocument?> showUploadFlow(
  BuildContext context, {
  required String documentTitle,
  required Future<CitizenDocument> Function(String sourceLabel) onUpload,
}) async {
  final source = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) {
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
              Text(
                'Add $documentTitle',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'How would you like to add it to your vault?',
                style: TextStyle(fontSize: 13, color: AppColors.inkFaint),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final option in _options)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    onTap: () =>
                        Navigator.of(sheetContext).pop(option.sourceLabel),
                    tileColor: AppColors.surfaceMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusTile,
                      ),
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        option.icon,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      option.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    subtitle: Text(
                      option.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkFaint,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  AppBrand.demoNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (source == null || !context.mounted) return null;

  final doc = await showDialog<CitizenDocument>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UploadProgressDialog(
      title: documentTitle,
      source: source,
      onUpload: onUpload,
    ),
  );
  return doc;
}

class _UploadProgressDialog extends StatefulWidget {
  const _UploadProgressDialog({
    required this.title,
    required this.source,
    required this.onUpload,
  });

  final String title;
  final String source;
  final Future<CitizenDocument> Function(String sourceLabel) onUpload;

  @override
  State<_UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<_UploadProgressDialog> {
  static const _steps = [
    'Uploading your copy',
    'Checking quality & clarity',
    'Adding to your document vault',
  ];

  int _step = -1;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (var i = 0; i < _steps.length; i++) {
      setState(() => _step = i);
      await Future<void>.delayed(const Duration(milliseconds: 480));
      if (!mounted) return;
    }
    try {
      final doc = await widget.onUpload(widget.source);
      if (!mounted) return;
      setState(() {
        _done = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      Navigator.of(context).pop(doc);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Upload failed. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.title;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Could not upload $doc',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _step = -1;
                            });
                            _run();
                          },
                          child: const Text('Try Again'),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_done)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 34,
                          color: AppColors.success,
                        )
                      else
                        const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _done ? '$doc added' : 'Uploading $doc',
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _done
                                  ? 'Added from ${widget.source}'
                                  : 'From ${widget.source}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.inkFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (var i = 0; i < _steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            i < _step || _done
                                ? Icons.check_circle_rounded
                                : i == _step
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            size: 17,
                            color: i < _step || _done
                                ? AppColors.success
                                : i == _step
                                ? AppColors.primary
                                : AppColors.hairline,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _steps[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: i == _step
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: i == _step
                                  ? AppColors.ink
                                  : AppColors.inkFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
