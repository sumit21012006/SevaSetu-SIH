import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/document.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/status_widgets.dart';
import '../widgets/zip_widgets.dart';
import 'doc_actions.dart';
import 'service_details_screen.dart';
import 'tab_top.dart';

class DocumentsTab extends StatefulWidget {
  const DocumentsTab({super.key});

  @override
  State<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<DocumentsTab> {
  DocumentCategory? _category;
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    _consumePendingUpload();
  }

  void _consumePendingUpload() {
    final state = AppScope.of(context);
    if (state.activeTabIndex != AppTabs.documents) return;
    final type = state.consumePendingDocUpload();
    if (type == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      openDocumentUpload(context, type: type);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final docs = state.vaultDocuments.toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    final categories = <DocumentCategory>[];
    for (final d in docs) {
      if (!categories.contains(d.type.category)) {
        categories.add(d.type.category);
      }
    }

    final visible = _category == null
        ? docs
        : docs.where((d) => d.type.category == _category).toList();

    return TabPage(
      children: [
        TabHeader(
          title: state.tr('nav.documents'),
          subtitle: 'Your documents, organized and ready when you need them.',
        ),
        const Gap(AppSpacing.lg),
        _SecurityBanner(),
        const Gap(AppSpacing.lg),
        if (docs.isNotEmpty)
          _CategoryChips(
            categories: categories,
            selected: _category,
            onSelect: (c) => setState(() => _category = c),
          ),
        const Gap(AppSpacing.md),
        if (visible.isEmpty)
          EmptyState(
            icon: Icons.folder_off_outlined,
            title: 'No documents here yet',
            message:
                'Documents you add for government services will appear in '
                'this vault.',
            actionLabel: 'Add a document',
            onAction: () => _pickDocumentToAdd(context),
          )
        else ...[
          for (final doc in visible)
            VaultDocumentCard(
              document: doc,
              usageServices: _usedFor(state, doc.type),
              onServiceTap: (name) {
                final service = state.services
                    .where((s) => s.name == name)
                    .toList();
                if (service.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ServiceDetailsScreen(serviceId: service.first.id),
                    ),
                  );
                }
              },
              onOpen: () => openDocDetail(context, doc.id),
              onReplace: () => openDocumentReplace(context, doc),
              onCheckValidity: () => runCheckValidity(context, doc),
            ),
          const Gap(AppSpacing.sm),
          _AddBar(onAdd: () => _pickDocumentToAdd(context)),
          const Gap(AppSpacing.lg),
        ],
        // ---- Pack documents for a service ----
        if (docs.isNotEmpty) ...[
          const SectionHeader(title: 'Pack documents for a service'),
          _ServicePackRow(state: state),
        ],
      ],
    );
  }

  List<String> _usedFor(AppState state, DocumentType type) {
    return [
      for (final service in state.services)
        if (service.requiredDocuments.any((r) => r.type == type)) service.name,
    ];
  }

  Future<void> _pickDocumentToAdd(BuildContext context) async {
    final state = AppScope.of(context);
    // Types that would meaningfully advance readiness.
    final candidates = <DocumentType>[];
    for (final service in state.services) {
      for (final req in service.requiredDocuments) {
        if (!candidates.contains(req.type)) candidates.add(req.type);
      }
    }
    final type = await showModalBottomSheet<DocumentType>(
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
                const Text(
                  'What are you adding?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose the document you want to upload or renew.',
                  style: TextStyle(fontSize: 13, color: AppColors.inkFaint),
                ),
                const SizedBox(height: AppSpacing.lg),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final type in candidates)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: DocIcon(type: type, size: 40),
                          title: Text(
                            type.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                          subtitle: Text(
                            type.category.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.inkFaint,
                            ),
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(type),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (type == null || !context.mounted) return;
    await openDocumentUpload(context, type: type);
  }
}

class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppColors.success),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your documents are securely managed. Only you can view or share them.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF14603B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<DocumentCategory> categories;
  final DocumentCategory? selected;
  final ValueChanged<DocumentCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = i == 0 ? null : categories[i - 1];
          final active = cat == selected;
          return ChoiceChip(
            label: Text(cat == null ? 'All' : cat.label),
            selected: active,
            showCheckmark: false,
            onSelected: (_) => onSelect(cat),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: active ? Colors.white : AppColors.inkSoft,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.hairline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _AddBar extends StatelessWidget {
  const _AddBar({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
        label: const Text('Upload a new document'),
      ),
    );
  }
}

class _ServicePackRow extends StatelessWidget {
  const _ServicePackRow({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final packable = [
      for (final service in state.services)
        if (state.readinessFor(service).zipDocuments.isNotEmpty) service,
    ];
    if (packable.isEmpty) {
      return const EmptyState(
        compact: true,
        icon: Icons.archive_outlined,
        title: 'Nothing to pack yet',
        message: 'Upload a document first — you can then download it as ZIP.',
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final service in packable)
          ActionChip(
            avatar: const Icon(
              Icons.archive_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            label: Text(
              '${service.name} · '
              '${state.readinessFor(service).zipDocuments.length}',
            ),
            onPressed: () => prepareServiceZip(context, service),
            backgroundColor: AppColors.primarySoft(opacity: 0.06),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
      ],
    );
  }
}
