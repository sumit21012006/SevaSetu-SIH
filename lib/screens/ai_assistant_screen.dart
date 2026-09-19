import 'dart:async';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../core/app_constants.dart';
import '../models/document.dart';
import '../models/service.dart';
import '../services/ai/ai_config.dart';
import '../services/ai/models/agent_event.dart';
import '../services/ai/models/agent_request.dart';
import '../services/ai/models/agent_result.dart';
import '../services/ai/models/agent_type.dart';
import '../services/ai/models/chat_turn.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../utils/l10n.dart';
import '../widgets/ai/active_context_chip.dart';
import '../widgets/ai/agent_progress_inline.dart';
import '../widgets/ai/agent_selector_bar.dart';
import '../widgets/ai/agent_tag.dart';
import '../widgets/ai/ai_points_list.dart';
import '../widgets/ai/follow_up_chips.dart';
import '../widgets/ai/gr_input_sheet.dart';
import '../widgets/ai/gr_summary_card.dart';
import '../widgets/ai/how_answered_panel.dart';
import '../widgets/ai/source_chips.dart';
import 'doc_actions.dart';
import 'service_details_screen.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    this.text,
    this.result,
    this.timestamp,
  });

  final bool isUser;
  final String? text;
  final AgentResult? result;
  final DateTime? timestamp;
}

/// Upgraded SevaSetu AI assistant screen backed by Groq multi-agent architecture.
class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({
    super.key,
    this.initialContextServiceId,
    this.initialQuery,
    this.initialAgent,
  });

  final String? initialContextServiceId;
  final String? initialQuery;
  final AgentType? initialAgent;

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<_ChatMessage> _messages = [];
  final List<ChatTurn> _history = [];

  String? _contextServiceId;
  AgentType? _selectedAgent;
  bool _isThinking = false;
  AgentEvent? _activeStreamingEvent;
  List<String> _suggestedFollowUps = [
    'What schemes can I apply for?',
    'Can I apply with my current documents?',
    'What are the Post-Matric Scholarship rules?',
  ];

  @override
  void initState() {
    super.initState();
    _contextServiceId = widget.initialContextServiceId;
    _selectedAgent = widget.initialAgent;

    _seedWelcome();

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendQuery(widget.initialQuery!);
      });
    }
  }

  void _seedWelcome() {
    _messages.add(
      _ChatMessage(
        isUser: false,
        result: AgentResult(
          agentType: AgentType.recommendation,
          summary:
              'Namaste! I am SevaSetu AI, your personal guide for Indian government services, eligibility checks, document preparation, and Government Resolutions (GRs). How can I assist you today?',
          steps: const [
            'Discover matching schemes based on your profile',
            'Check 100% deterministic eligibility with official citations',
            'Track missing or expiring documents in your vault',
            'Translate and simplify complex Government Resolutions (GRs)',
          ],
          confidence: 1.0,
        ),
      ),
    );
  }

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
        _scroll.position.maxScrollExtent + 260,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _sendQuery(
    String raw, {
    AgentType? agentOverride,
    String? serviceIdOverride,
    String? documentText,
  }) async {
    final query = raw.trim();
    if (query.isEmpty || _isThinking) return;

    final state = AppScope.of(context);
    final orchestrator = state.orchestrator;

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: query, timestamp: DateTime.now()));
      _history.add(ChatTurn.user(query));
      _isThinking = true;
      _activeStreamingEvent = null;
    });
    _input.clear();
    _scrollDown();

    final request = AgentRequest(
      query: query,
      targetAgent: agentOverride ?? _selectedAgent,
      serviceId: serviceIdOverride ?? _contextServiceId,
      profile: state.profile,
      vault: state.vault,
      history: _history,
      language: state.language,
      documentText: documentText,
    );

    AgentResult? finalResult;

    try {
      await for (final event in orchestrator.processStream(request)) {
        if (!mounted) return;
        setState(() {
          _activeStreamingEvent = event;
        });

        if (event is AgentCompleted) {
          finalResult = event.result;
        }
      }
    } catch (e) {
      finalResult = AgentResult.error(
        agentType: _selectedAgent ?? AgentType.recommendation,
        errorMessage: 'An error occurred while processing: $e',
      );
    }

    if (!mounted) return;

    final nonNullResult = finalResult ??
        AgentResult.error(
          agentType: _selectedAgent ?? AgentType.recommendation,
          errorMessage: 'No response received from assistant.',
        );

    setState(() {
      _isThinking = false;
      _activeStreamingEvent = null;
      _messages.add(_ChatMessage(isUser: false, result: nonNullResult, timestamp: DateTime.now()));
      _history.add(ChatTurn.assistant(nonNullResult.summary));

      // Update follow-up questions
      final dynamic followUps = nonNullResult.metadata['followUpQuestions'];
      if (followUps is List && followUps.isNotEmpty) {
        _suggestedFollowUps = followUps.map((e) => e.toString()).toList();
      }
    });

    _scrollDown();
  }

  void _handleAction(String action) async {
    final state = AppScope.of(context);
    final parts = action.split(':');
    final prefix = parts[0].trim();
    final targetId = parts.length > 1 ? parts[1].trim() : '';

    if (prefix == 'view_service' && targetId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ServiceDetailsScreen(serviceId: targetId),
        ),
      );
    } else if (prefix == 'check_eligibility' && targetId.isNotEmpty) {
      final svc = state.serviceById(targetId);
      setState(() => _contextServiceId = targetId);
      _sendQuery('Check my eligibility for ${svc.name}', agentOverride: AgentType.eligibility);
    } else if (prefix == 'view_documents' && targetId.isNotEmpty) {
      final svc = state.serviceById(targetId);
      setState(() => _contextServiceId = targetId);
      _sendQuery('What documents do I need for ${svc.name}?', agentOverride: AgentType.guidance);
    } else if (prefix == 'download_zip' && targetId.isNotEmpty) {
      final svc = state.serviceById(targetId);
      try {
        final pack = await state.createZip(svc);
        if (pack.filePath.isNotEmpty) {
          await OpenFilex.open(pack.filePath);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create ZIP: $e')),
        );
      }
    } else if (prefix == 'upload_document' && targetId.isNotEmpty) {
      final match = DocumentType.values.where((t) => t.name == targetId).toList();
      if (match.isNotEmpty) {
        await openDocumentUpload(context, type: match.first);
        if (mounted) {
          setState(() {}); // Refresh vault state
        }
      } else {
        state.openDocumentsTab();
        Navigator.of(context).pop();
      }
    } else if (prefix == 'open_gr_guide') {
      _showGRSheet();
    }
  }

  void _showGRSheet() {
    final state = AppScope.of(context);
    GRInputSheet.show(
      context,
      knowledgeRepo: state.orchestrator.knowledgeRepo,
      onSelect: (text, serviceId) {
        setState(() {
          if (serviceId != null) _contextServiceId = serviceId;
          _selectedAgent = AgentType.grSimplifier;
        });
        _sendQuery(
          'Simplify this Government Resolution for me',
          agentOverride: AgentType.grSimplifier,
          serviceIdOverride: serviceId,
          documentText: text,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final contextService = _contextServiceId != null ? state.serviceById(_contextServiceId!) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.aiPurpleSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, size: 18, color: AppColors.aiPurple),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SevaSetu AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
                Text(
                  'Multi-Agent Civic Assistant',
                  style: TextStyle(fontSize: 10, color: AppColors.inkFaint),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Simplify GR',
            icon: const Icon(Icons.description_outlined, color: AppColors.aiPurple),
            onPressed: _showGRSheet,
          ),
          PopupMenuButton<AppLanguage>(
            tooltip: 'Language',
            icon: const Icon(Icons.translate_rounded, color: AppColors.inkSoft),
            onSelected: (lang) => state.setLanguage(lang),
            itemBuilder: (_) => [
              const PopupMenuItem(value: AppLanguage.english, child: Text('English')),
              const PopupMenuItem(value: AppLanguage.hindi, child: Text('हिंदी (Hindi)')),
              const PopupMenuItem(value: AppLanguage.marathi, child: Text('मराठी (Marathi)')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(contextService != null ? 80 : 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AgentSelectorBar(
                selectedAgent: _selectedAgent,
                onSelect: (agent) => setState(() => _selectedAgent = agent),
              ),
              if (contextService != null)
                ActiveContextChip(
                  service: contextService,
                  onClear: () => setState(() => _contextServiceId = null),
                ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (!AIConfig.hasApiKey)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 6),
              color: AppColors.infoBg,
              child: Row(
                children: const [
                  Icon(Icons.offline_bolt_outlined, size: 14, color: AppColors.info),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Deterministic Mode: GROQ_API_KEY not set in .env. Vault readiness and rule evaluations are working offline.',
                      style: TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(AppSpacing.page),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isThinking) {
                  return _buildStreamingIndicator();
                }
                final msg = _messages[index];
                return msg.isUser ? _buildUserBubble(msg.text ?? '') : _buildAssistantCard(msg.result!);
              },
            ),
          ),
          if (_suggestedFollowUps.isNotEmpty && !_isThinking)
            FollowUpChips(
              questions: _suggestedFollowUps,
              onSelect: (q) => _sendQuery(q),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildStreamingIndicator() {
    String stepDesc = 'Thinking and processing request...';
    AgentType type = _selectedAgent ?? AgentType.recommendation;

    if (_activeStreamingEvent is AgentRoutingStarted) {
      stepDesc = 'Routing your query to the best specialized agent...';
      type = AgentType.router;
    } else if (_activeStreamingEvent is AgentSelected) {
      final ev = _activeStreamingEvent as AgentSelected;
      stepDesc = ev.reason;
      type = ev.agentType;
    } else if (_activeStreamingEvent is AgentStepStarted) {
      final ev = _activeStreamingEvent as AgentStepStarted;
      stepDesc = ev.stepDescription;
      type = ev.agentType;
    }

    return AgentProgressInline(
      agentType: type,
      stepDescription: stepDesc,
    );
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusTile),
            topRight: Radius.circular(AppSpacing.radiusTile),
            bottomLeft: Radius.circular(AppSpacing.radiusTile),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAssistantCard(AgentResult result) {
    final headline = result.metadata['headline']?.toString();
    final grSummary = result.metadata['gr_summary'] as Map<String, dynamic>?;
    final state = AppScope.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg, right: 16),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top metadata row
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AgentTag(agentType: result.agentType, compact: true),
              if (result.sources.isNotEmpty) SourceChips(sources: result.sources),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Headline
          if (headline != null && headline.isNotEmpty) ...[
            Text(
              headline,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          // Main answer narrative
          Text(
            result.summary,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Points breakdown
          if (result.steps.isNotEmpty) ...[
            AIPointsList(points: result.steps),
            const SizedBox(height: AppSpacing.sm),
          ],

          // GR Summary Card
          if (grSummary != null) ...[
            GRSummaryCard(grSummary: grSummary),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Recommended Services Cards
          if (result.recommendedServiceIds.isNotEmpty) ...[
            const Text(
              'Recommended Schemes:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.inkSoft),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...result.recommendedServiceIds.map((svcId) {
              GovService? s;
              try {
                s = state.serviceById(svcId);
              } catch (_) {}
              if (s == null) return const SizedBox.shrink();

              return Card(
                elevation: 0,
                color: AppColors.background,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
                  side: const BorderSide(color: AppColors.hairline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                      Text(
                        '${s.category.label} • ${s.department}',
                        style: const TextStyle(fontSize: 11, color: AppColors.inkFaint),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        s.shortDescription,
                        style: const TextStyle(fontSize: 12, height: 1.3, color: AppColors.inkSoft),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              ),
                            ),
                            onPressed: () => _handleAction('view_service:${s!.id}'),
                            child: const Text('View Scheme', style: TextStyle(fontSize: 11)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              ),
                            ),
                            onPressed: () => _handleAction('check_eligibility:${s!.id}'),
                            child: const Text('Check Eligibility', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          // Quick Action buttons
          if (result.nextActions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: result.nextActions.map((action) {
                return _buildActionButton(action);
              }).toList(),
            ),
          ],

          // Transparency panel
          HowAnsweredPanel(result: result),
        ],
      ),
    );
  }

  Widget _buildActionButton(String action) {
    final parts = action.split(':');
    final prefix = parts[0];
    final label = _actionLabel(action);
    final isPrimary = prefix == 'download_zip' || prefix == 'upload_document';

    return ActionChip(
      avatar: Icon(
        _actionIcon(prefix),
        size: 13,
        color: isPrimary ? Colors.white : AppColors.primary,
      ),
      label: Text(label),
      backgroundColor: isPrimary ? AppColors.primary : AppColors.surface,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isPrimary ? Colors.white : AppColors.primary,
      ),
      side: BorderSide(color: AppColors.primary.withValues(alpha: isPrimary ? 1.0 : 0.3)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      onPressed: () => _handleAction(action),
    );
  }

  IconData _actionIcon(String prefix) {
    switch (prefix) {
      case 'download_zip':
        return Icons.folder_zip_outlined;
      case 'upload_document':
        return Icons.upload_file_outlined;
      case 'check_eligibility':
        return Icons.verified_user_outlined;
      case 'view_service':
        return Icons.open_in_new_rounded;
      case 'open_gr_guide':
        return Icons.description_outlined;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  String _actionLabel(String action) {
    final parts = action.split(':');
    final prefix = parts[0];
    final target = parts.length > 1 ? parts[1] : '';

    switch (prefix) {
      case 'download_zip':
        return 'Download Ready Documents (ZIP)';
      case 'upload_document':
        return 'Upload $target';
      case 'check_eligibility':
        return 'Check Eligibility';
      case 'view_service':
        return 'View Scheme Details';
      case 'view_documents':
        return 'Check Document List';
      case 'open_gr_guide':
        return 'Simplify Another GR';
      default:
        return action;
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              tooltip: 'Simplify GR',
              icon: const Icon(Icons.description_outlined, color: AppColors.aiPurple),
              onPressed: _showGRSheet,
            ),
            Expanded(
              child: TextField(
                controller: _input,
                textInputAction: TextInputAction.send,
                onSubmitted: (val) => _sendQuery(val),
                decoration: InputDecoration(
                  hintText: 'Ask about any scheme, documents, or eligibility...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.inkFaint),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    borderSide: const BorderSide(color: AppColors.hairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    borderSide: const BorderSide(color: AppColors.hairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    borderSide: const BorderSide(color: AppColors.aiPurple, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.aiPurple,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              onPressed: () => _sendQuery(_input.text),
            ),
          ],
        ),
      ),
    );
  }
}
