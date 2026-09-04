import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/chat.dart';
import '../models/document.dart';
import '../services/ai_service.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/chat_widgets.dart';
import '../widgets/voice_input.dart';
import '../widgets/zip_widgets.dart';
import 'doc_actions.dart';
import 'readiness_screen.dart';
import 'service_details_screen.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String? _contextServiceId;
  bool _thinking = false;
  int _step = 0;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 220,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _thinking) return;
    final state = AppScope.of(context);
    state.pushChat(
      AssistantMessage(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        fromUser: true,
        text: text,
      ),
    );
    _input.clear();
    _scrollDown();

    setState(() {
      _thinking = true;
      _step = 0;
    });
    _scrollDown();

    final steps = state.aiProcessingSteps;
    for (var i = 0; i < steps.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;
      setState(() => _step = i + 1);
    }

    final reply = await state.askAssistant(
      query: text,
      contextServiceId: _contextServiceId,
    );
    if (!mounted) return;
    if (reply.contextServiceId != null) {
      _contextServiceId = reply.contextServiceId;
    }
    setState(() => _thinking = false);
    state.pushChat(reply);
    _scrollDown();
  }

  Future<void> _voice() async {
    final samples = [...VoiceSamples.general, ...VoiceSamples.docQuestions];
    final text = await showVoiceCapture(context, samples: samples);
    if (text == null || !mounted) return;
    _input.text = text;
    await _send(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final messages = state.chatMessages;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.aiPurple, Color(0xFF8B6DE0)],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SevaSetu AI', style: TextStyle(fontSize: 17)),
                  Text(
                    'Your government-service assistant',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.inkFaint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Start new chat',
            onPressed: () {
              _contextServiceId = null;
              state.clearChat();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (_contextServiceId != null)
            _ContextStrip(
              serviceId: _contextServiceId!,
              onClear: () => setState(() => _contextServiceId = null),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.lg,
              ),
              itemCount: messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= messages.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: AssistantProcessingCard(
                      steps: state.aiProcessingSteps,
                      activeStep: _step - 1,
                    ),
                  );
                }
                final message = messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: AIMessageBubble(
                    message: message,
                    onOpenService: _openService,
                    onServiceEligibility: _openService,
                    onServiceDocuments: (id) => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReadinessScreen(serviceId: id),
                      ),
                    ),
                    onZip: (serviceId, _) async {
                      final service = AppScope.of(
                        context,
                      ).serviceById(serviceId);
                      await prepareServiceZip(context, service);
                    },
                    onDocPrimaryAction: _handleDocLine,
                    onQuickReply: _send,
                  ),
                );
              },
            ),
          ),
          _Composer(
            controller: _input,
            busy: _thinking,
            onSend: () => _send(_input.text),
            onVoice: _voice,
          ),
        ],
      ),
    );
  }

  void _openService(String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceDetailsScreen(serviceId: id),
      ),
    );
  }

  void _handleDocLine(ChatDocLine line) {
    final state = AppScope.of(context);
    if (line.status == DocStatus.missing ||
        line.status == DocStatus.expired ||
        line.status == DocStatus.verificationRequired) {
      openDocumentUpload(context, type: line.type);
      return;
    }
    state.openDocumentsTab();
  }
}

class _ContextStrip extends StatelessWidget {
  const _ContextStrip({required this.serviceId, required this.onClear});
  final String serviceId;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final service = state.serviceById(serviceId);
    return Container(
      width: double.infinity,
      color: AppColors.aiPurpleSoft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      height: 42,
      child: Row(
        children: [
          const Icon(
            Icons.ads_click_rounded,
            size: 15,
            color: AppColors.aiPurple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Helping with: ${service.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.aiPurple,
              ),
            ),
          ),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.aiPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.onSend,
    required this.onVoice,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: const TextStyle(fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: 'Ask in English, हिंदी or मराठी…',
                    hintStyle: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.inkFaint,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Voice input',
                      onPressed: busy ? null : onVoice,
                      icon: const Icon(
                        Icons.mic_rounded,
                        color: AppColors.aiPurple,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: busy ? null : onSend,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
