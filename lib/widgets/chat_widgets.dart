import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/enum_ui.dart';
import '../models/chat.dart';
import '../models/document.dart';
import '../models/service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'service_widgets.dart';

/// One assistant (or user) message bubble with structured, actionable
/// content — never a plain chatbot line.
class AIMessageBubble extends StatelessWidget {
  const AIMessageBubble({
    super.key,
    required this.message,
    required this.onOpenService,
    required this.onServiceEligibility,
    required this.onServiceDocuments,
    required this.onZip,
    required this.onDocPrimaryAction,
    required this.onQuickReply,
  });

  final AssistantMessage message;
  final ValueChanged<String> onOpenService;
  final ValueChanged<String> onServiceEligibility;
  final ValueChanged<String> onServiceDocuments;
  final void Function(String serviceId, int count) onZip;
  final ValueChanged<ChatDocLine> onDocPrimaryAction;
  final ValueChanged<String> onQuickReply;

  @override
  Widget build(BuildContext context) {
    if (message.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.84,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 1,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    final state = AppScope.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.aiPurple, Color(0xFF8B6DE0)],
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 15,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md + 1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    ),
                    if (message.serviceIds.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      for (final id in message.serviceIds)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _serviceCard(context, state, id),
                        ),
                    ],
                    if (message.docLines.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      for (final line in message.docLines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _docLine(line),
                        ),
                    ],
                    if (message.zip != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _zipAction(message.zip!),
                    ],
                  ],
                ),
              ),
              if (message.quickReplies.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final q in message.quickReplies)
                      InkWell(
                        onTap: () => onQuickReply(q),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.aiPurpleSoft,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill,
                            ),
                          ),
                          child: Text(
                            q,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.aiPurple,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _serviceCard(BuildContext context, AppState state, String id) {
    GovService? service;
    for (final s in state.services) {
      if (s.id == id) service = s;
    }
    if (service == null) return const SizedBox.shrink();
    final summary = state.readinessFor(service);
    final match = state.eligibilityFor(service).matchPercent;
    return AiServiceCard(
      service: service,
      matchPercent: match,
      summary: summary,
      onOpenService: () => onOpenService(service!.id),
      onCheckEligibility: () => onServiceEligibility(service!.id),
      onViewDocuments: () => onServiceDocuments(service!.id),
    );
  }

  Widget _docLine(ChatDocLine line) {
    final style = statusStyle(line.status);
    final tappable =
        line.status == DocStatus.missing ||
        line.status == DocStatus.expired ||
        line.status == DocStatus.verificationRequired;
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => onDocPrimaryAction(line),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(style.icon, size: 17, color: style.color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.type.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (line.detail.isNotEmpty)
                      Text(
                        line.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkFaint,
                        ),
                      ),
                  ],
                ),
              ),
              if (tappable)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.north_east_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _zipAction(ChatZipAction zip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft(opacity: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.archive_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Download all ${zip.count} available documents as one ZIP file.',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => onZip(zip.serviceId, zip.count),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('📦 ZIP'),
          ),
        ],
      ),
    );
  }
}

/// Checklist card shown while the assistant "analyzes" a request
/// (represents the agent pipeline without technical jargon).
class AssistantProcessingCard extends StatelessWidget {
  const AssistantProcessingCard({
    super.key,
    required this.steps,
    required this.activeStep,
  });

  final List<String> steps;
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.aiPurple, Color(0xFF8B6DE0)],
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 15,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'SevaSetu is analyzing your request',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.5),
                    child: Row(
                      children: [
                        Icon(
                          i <= activeStep
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_off_rounded,
                          size: 16,
                          color: i <= activeStep
                              ? AppColors.success
                              : AppColors.hairline,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          steps[i],
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: i == activeStep
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: i <= activeStep
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
        ),
      ],
    );
  }
}
