import 'dart:math';

import '../data/mock_store.dart';
import '../models/chat.dart';
import '../models/journey.dart';
import '../models/readiness.dart';
import '../models/service.dart';
import '../utils/format.dart';
import 'application_service.dart';
import 'eligibility_service.dart';
import 'service_discovery_service.dart';

/// Predefined phrases used by the (mock) voice input.
class VoiceSamples {
  VoiceSamples._();

  static const List<String> general = [
    'I want to apply for a scholarship for my daughter',
    'Mujhe college scholarship ke liye apply karna hai',
    'I need help applying for a house under PMAY',
    'Mujhe kisan sahayata chahiye',
    'I want to register for employment assistance',
  ];

  static const List<String> docQuestions = [
    'What documents do I need?',
    'Which documents am I missing?',
    'Is my income certificate still valid?',
    'Can I apply with my current documents?',
  ];
}

/// SevaSetu AI assistant.
///
/// V1 answers are intent-matched against the local store and are always
/// structured — service cards, document lists and actionable buttons —
/// rather than free-form text. Later this becomes an LLM + RAG pipeline
/// (FastAPI + vector store) behind the same [AIService] contract.
abstract class AIService {
  Future<AssistantMessage> reply({
    required String query,
    String? contextServiceId,
  });

  /// Human-friendly pipeline labels used by the processing animation.
  List<String> get processingSteps;
}

class LocalAIService implements AIService {
  LocalAIService(this._store);

  final AppDataStore _store;
  final _rng = Random();
  int _seq = 0;

  late final ServiceDiscoveryService _discovery = LocalServiceDiscoveryService(
    _store,
  );
  late final EligibilityService _eligibility = LocalEligibilityService();
  late final ApplicationService _applications = LocalApplicationService(_store);

  @override
  List<String> get processingSteps => const [
    'Understanding your request',
    'Finding relevant service',
    'Checking eligibility',
    'Identifying required documents',
    'Comparing your documents',
    'Preparing personalized guidance',
  ];

  GovService _serviceById(String id) =>
      _store.services.firstWhere((s) => s.id == id);

  ReadinessSummary _readiness(GovService service) =>
      computeReadiness(service, _store.documents);

  @override
  Future<AssistantMessage> reply({
    required String query,
    String? contextServiceId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final q = query.trim().toLowerCase();

    GovService? context;
    if (contextServiceId != null) {
      try {
        context = _serviceById(contextServiceId);
      } catch (_) {
        context = null;
      }
    }

    // --- Service-intent detection (find a government service) ---
    final resolved = _resolveService(q) ?? context;
    context ??= resolved;

    // --- Branch on the intent of the question ---
    if (_any(q, const [
      'thank',
      'dhanyavad',
      'धन्यवाद',
      'shukriya',
      'thanks',
    ])) {
      return _text(
        "You're welcome! Is there anything else I can help you prepare for?",
        quickReplies: const [
          'What documents do I need?',
          'Can I apply with my current documents?',
        ],
        contextServiceId: context?.id,
      );
    }

    if (_any(q, const ['download', 'zip', 'pack', 'डाउनलोड', 'ek saath'])) {
      return _zipReply(context ?? _serviceById('svc-pms'));
    }

    if (_any(q, const [
      'expir',
      'expiry',
      'valid till',
      'validity',
      'expire',
    ])) {
      if (context != null) {
        final r = _readiness(context);
        return _validityReply(context, r, includeExpired: true);
      }
      return _vaultValidityReply();
    }

    if (_any(q, const ['missing', 'renew', 'not have', 'need attention'])) {
      final target = context ?? _serviceById('svc-pms');
      return _missingReply(target);
    }

    if (_any(q, const [
      'reuse',
      'reused',
      'another service',
      'which document',
    ])) {
      return _reuseReply();
    }

    if (_any(q, const [
      'can i apply',
      'am i ready',
      'ready to apply',
      'apply with',
      'able to apply',
    ])) {
      final target = context ?? _serviceById('svc-pms');
      return _readyReply(target);
    }

    if (_any(q, const [
      'eligible',
      'eligibility',
      'patra',
      'पात्र',
      'pata hai kya',
    ])) {
      if (context == null) {
        return _text(
          'Tell me which service you are interested in and I will check your '
          'eligibility against your profile.',
          serviceIds: [for (final s in _store.services.take(3)) s.id],
          quickReplies: const [
            'Am I eligible for the Post-Matric Scholarship?',
            'Am I eligible for PMAY?',
          ],
        );
      }
      final report = _eligibility.evaluate(
        service: context,
        profile: _store.profile,
        vault: _store.documents,
      );
      return _text(
        '${report.summary} I found a ${report.matchPercent}% eligibility '
        'match for ${context.name}.',
        serviceIds: [context.id],
        quickReplies: const ['What documents do I need?', 'How do I apply?'],
        contextServiceId: context.id,
      );
    }

    if (_any(q, const ['journey', 'progress', 'track', 'status', 'step'])) {
      final app = _store.applications.isNotEmpty
          ? _store.applications.first
          : null;
      if (app == null) {
        return _text(
          'You have not started a journey yet. Pick a service and I will '
          'lay out your path.',
          serviceIds: [for (final s in _store.services.take(2)) s.id],
        );
      }
      final journey = _applications.journeyFor(app);
      final current = journey.steps[journey.currentIndex];
      return _text(
        'Your ${app.serviceName} journey is at the "${_phaseName(current.phase)}" '
        'stage. ${current.isCompleted ? 'This stage is complete.' : 'This is your current stage.'}',
        serviceIds: [app.serviceId],
        quickReplies: const [
          'What should I do next?',
          'Which documents are missing?',
        ],
        contextServiceId: app.serviceId,
      );
    }

    if (_any(q, const [
      'document',
      'docs',
      'kagaj',
      'कागद',
      'कागजात',
      'dastaavej',
      'दस्तावेज़',
      'files',
    ])) {
      final target = context ?? _serviceById('svc-pms');
      final r = _readiness(target);
      final lines = <ChatDocLine>[
        for (final c in r.readyChecks)
          ChatDocLine(
            type: c.requirement.type,
            status: c.status,
            detail: 'In your vault and usable.',
          ),
        for (final c in r.expiringChecks)
          ChatDocLine(
            type: c.requirement.type,
            status: c.status,
            detail: c.document?.expiresAt == null
                ? 'Renewal suggested.'
                : Formatters.expiryPhrase(c.document!.expiresAt!),
          ),
        for (final c in r.missingChecks)
          ChatDocLine(
            type: c.requirement.type,
            status: c.status,
            detail: c.requirement.why,
          ),
        for (final c in r.expiredChecks)
          ChatDocLine(
            type: c.requirement.type,
            status: c.status,
            detail: 'Renew to use this document.',
          ),
      ];
      return AssistantMessage(
        id: _id(),
        fromUser: false,
        text:
            'For ${target.name} you need ${r.requiredCount} documents. '
            '${r.readyCount} are ready in your vault'
            '${r.attentionCount > 0 ? ' and ${r.attentionCount} need attention' : ''}.',
        docLines: lines,
        zip: ChatZipAction(serviceId: target.id, count: r.zipDocuments.length),
        quickReplies: const [
          'Which documents am I missing?',
          '📦 Download my documents',
        ],
        contextServiceId: target.id,
      );
    }

    if (_any(q, const [
      'hello',
      'hi',
      'namaste',
      'नमस्ते',
      'नमस्कार',
      'hey',
      'start',
    ])) {
      return _text(
        'Namaste! 👋 I am SevaSetu, your government-service assistant. Tell me '
        'what you need — a scholarship, housing help, farming support or a job '
        '— or ask about your documents.',
        serviceIds: [for (final s in _store.services.take(4)) s.id],
        quickReplies: const [
          'I want to apply for a scholarship',
          'What documents do I need?',
        ],
      );
    }

    // --- General service discovery branch ---
    final hits = _discovery
        .search(ServiceFilter(query: query))
        .take(3)
        .toList();
    if (hits.isNotEmpty) {
      final best = hits.first;
      final r = _readiness(best);
      return AssistantMessage(
        id: _id(),
        fromUser: false,
        text:
            'I found ${hits.length == 1 ? 'a relevant service' : '${hits.length} relevant services'} '
            'for you.${hits.length > 1 ? ' Here is the closest match' : ''} '
            '— ${best.name}. Your profile shows ${_eligibility.evaluate(service: best, profile: _store.profile, vault: _store.documents).matchPercent}% eligibility '
            'and ${r.readyCount}/${r.requiredCount} documents ready.',
        serviceIds: [for (final h in hits) h.id],
        quickReplies: const [
          'What documents do I need?',
          'Check my eligibility',
        ],
        contextServiceId: best.id,
      );
    }

    // --- Fallback ---
    final random = _rng.nextInt(_store.services.length);
    final s = _store.services[random];
    return AssistantMessage(
      id: _id(),
      fromUser: false,
      text:
          'I could not match that to a specific request yet. You can describe '
          'a need in your own words — for example "scholarship", "housing", '
          '"farming" or "job". Here are services you can explore:',
      serviceIds: [for (final svc in _store.services) svc.id],
      quickReplies: const [
        'I want to apply for a scholarship',
        'What documents do I need?',
      ],
      contextServiceId: s.id,
    );
  }

  // ---- Intent helpers ----

  GovService? _resolveService(String q) {
    final tokens = q.split(RegExp(r'\s+'));
    GovService? best;
    var bestScore = 0;
    for (final s in _store.services) {
      final text = '${s.name} ${s.shortDescription} ${s.keywords.join(' ')}'
          .toLowerCase();
      var score = 0;
      for (final token in tokens) {
        if (token.length < 3) continue;
        if (text.contains(token)) score += 2;
      }
      for (final kw in s.keywords) {
        if (q.contains(kw.toLowerCase())) score += 3;
      }
      if (score > bestScore) {
        bestScore = score;
        best = s;
      }
    }
    return bestScore >= 3 ? best : null;
  }

  /// Whole-word (or phrase) matching so intents never fire on accidental
  /// substrings — e.g. "hi" must not match inside "scholarship".
  bool _any(String q, List<String> terms) {
    final lq = q.toLowerCase();
    for (final raw in terms) {
      final term = raw.trim().toLowerCase();
      if (term.isEmpty) continue;
      final words = term
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();
      final asciiWords = words.every(RegExp(r'^[a-z]+$').hasMatch);
      if (asciiWords && words.length == 1) {
        if (RegExp('\b${RegExp.escape(term)}\b').hasMatch(lq)) {
          return true;
        }
      } else if (lq.contains(term)) {
        return true;
      }
    }
    return false;
  }

  AssistantMessage _text(
    String text, {
    List<String> serviceIds = const [],
    List<String> quickReplies = const [],
    String? contextServiceId,
  }) {
    return AssistantMessage(
      id: _id(),
      fromUser: false,
      text: text,
      serviceIds: serviceIds,
      quickReplies: quickReplies,
      contextServiceId: contextServiceId,
    );
  }

  AssistantMessage _zipReply(GovService service) {
    final r = _readiness(service);
    return AssistantMessage(
      id: _id(),
      fromUser: false,
      text:
          '${r.readyCount} of ${r.requiredCount} required documents for '
          '${service.name} are ready. I can pack the ${r.zipDocuments.length} '
          'available documents into one ZIP file.',
      zip: ChatZipAction(serviceId: service.id, count: r.zipDocuments.length),
      quickReplies: const ['Which documents are still missing?'],
      contextServiceId: service.id,
    );
  }

  AssistantMessage _validityReply(
    GovService service,
    ReadinessSummary r, {
    bool includeExpired = true,
  }) {
    final lines = <ChatDocLine>[
      for (final c in r.expiringChecks)
        ChatDocLine(
          type: c.requirement.type,
          status: c.status,
          detail: c.document?.expiresAt == null
              ? 'Renewal suggested soon.'
              : Formatters.expiryPhrase(c.document!.expiresAt!),
        ),
      if (includeExpired)
        for (final c in r.expiredChecks)
          ChatDocLine(
            type: c.requirement.type,
            status: c.status,
            detail: c.document?.expiresAt == null
                ? 'Expired.'
                : 'Expired on ${Formatters.date(c.document!.expiresAt!)}.',
          ),
    ];
    if (lines.isEmpty) {
      return _text(
        'Good news — every document for ${service.name} is valid. '
        'No renewals are needed right now.',
        contextServiceId: service.id,
      );
    }
    final n = lines.length;
    return AssistantMessage(
      id: _id(),
      fromUser: false,
      text:
          'I found $n document${n == 1 ? '' : 's'} for ${service.name} that '
          'need${n == 1 ? 's' : ''} your attention for validity:',
      docLines: lines,
      quickReplies: const [
        'How do I renew a certificate?',
        'What documents do I need?',
      ],
      contextServiceId: service.id,
    );
  }

  AssistantMessage _vaultValidityReply() {
    final lines = <ChatDocLine>[];
    for (final d in _store.documents) {
      if (d.isExpiringSoon || d.isExpired) {
        lines.add(
          ChatDocLine(
            type: d.type,
            status: d.status,
            detail: d.isExpired
                ? 'Expired on ${Formatters.date(d.expiresAt!)}.'
                : Formatters.expiryPhrase(d.expiresAt!),
          ),
        );
      }
    }
    if (lines.isEmpty) {
      return _text(
        'All documents in your vault are valid. Aadhaar has lifetime '
        'validity and nothing is close to expiring.',
      );
    }
    return AssistantMessage(
      id: _id(),
      fromUser: false,
      text:
          'Looking across your vault, ${lines.length} document'
          '${lines.length == 1 ? '' : 's'} need attention:',
      docLines: lines,
      quickReplies: const [
        'Which service needs these documents?',
        'What documents do I need?',
      ],
    );
  }

  AssistantMessage _missingReply(GovService service) {
    final r = _readiness(service);
    final lines = <ChatDocLine>[
      for (final c in r.missingChecks)
        ChatDocLine(
          type: c.requirement.type,
          status: c.status,
          detail: c.requirement.why,
        ),
      for (final c in r.expiredChecks)
        ChatDocLine(
          type: c.requirement.type,
          status: c.status,
          detail: 'Expired — upload a renewed copy.',
        ),
    ];
    if (lines.isEmpty) {
      return _text(
        "You are not missing any documents for ${service.name}. "
        'Everything required is in your vault.',
        contextServiceId: service.id,
      );
    }
    return AssistantMessage(
      id: _id(),
      fromUser: false,
      text:
          'You are missing ${lines.length} document'
          '${lines.length == 1 ? '' : 's'} for ${service.name}. '
          'Upload or renew them from your Documents tab.',
      docLines: lines,
      quickReplies: const [
        'Why is this document required?',
        '📦 Download my documents',
      ],
      contextServiceId: service.id,
    );
  }

  AssistantMessage _readyReply(GovService service) {
    final r = _readiness(service);
    if (r.isFullyReady) {
      return AssistantMessage(
        id: _id(),
        fromUser: false,
        text:
            'Yes — you are fully ready to apply for ${service.name}. '
            'All ${r.requiredCount} documents are in place.',
        zip: ChatZipAction(serviceId: service.id, count: r.zipDocuments.length),
        quickReplies: const ['How do I apply?', 'Show my journey'],
        contextServiceId: service.id,
      );
    }
    return AssistantMessage(
      id: _id(),
      fromUser: false,
      text:
          'Not yet. You are ${r.readyCount} of ${r.requiredCount} documents '
          'ready for ${service.name}. '
          '${r.message} Focus on the ${r.attentionCount} documents below.',
      docLines: [
        for (final c in r.missingChecks)
          ChatDocLine(
            type: c.requirement.type,
            status: c.status,
            detail: c.requirement.why,
          ),
        for (final c in r.expiringChecks)
          ChatDocLine(
            type: c.requirement.type,
            status: c.status,
            detail: 'Expiring — use soon or renew.',
          ),
        for (final c in r.expiredChecks)
          ChatDocLine(
            type: c.requirement.type,
            status: c.status,
            detail: 'Expired — renew to proceed.',
          ),
      ],
      zip: ChatZipAction(serviceId: service.id, count: r.zipDocuments.length),
      quickReplies: const ['Which documents are missing?', 'How do I renew?'],
      contextServiceId: service.id,
    );
  }

  AssistantMessage _reuseReply() {
    final lines = <ChatDocLine>[];
    for (final d in _store.documents) {
      final usedBy = _store.services
          .where((s) => s.requiredDocuments.any((req) => req.type == d.type))
          .toList();
      if (usedBy.length >= 2) {
        lines.add(
          ChatDocLine(
            type: d.type,
            status: d.status,
            detail:
                'Used for ${usedBy.map((s) => s.name).take(2).join(' & ')}'
                '${usedBy.length > 2 ? ' +${usedBy.length - 2} more' : ''}.',
          ),
        );
      }
    }
    return AssistantMessage(
      id: _id(),
      fromUser: false,
      text:
          'Documents in your vault that are required by more than one '
          'service — keep these renewed to stay ready:',
      docLines: lines.isEmpty ? const [] : lines.take(6).toList(),
      quickReplies: const ['What documents do I need?', 'Check my readiness'],
    );
  }

  String _phaseName(PhaseId id) {
    switch (id) {
      case PhaseId.discover:
        return 'Discover';
      case PhaseId.eligibility:
        return 'Eligibility';
      case PhaseId.documents:
        return 'Documents';
      case PhaseId.verification:
        return 'Verification';
      case PhaseId.guidance:
        return 'Guidance';
      case PhaseId.apply:
        return 'Apply';
      case PhaseId.track:
        return 'Track';
    }
  }

  String _id() => 'msg-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
}
