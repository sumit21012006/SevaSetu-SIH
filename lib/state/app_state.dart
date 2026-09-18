import 'package:flutter/foundation.dart';

import '../data/mock_store.dart';
import '../models/application.dart';
import '../models/chat.dart';
import '../models/document.dart';
import '../models/eligibility.dart';
import '../models/journey.dart';
import '../models/notification_item.dart';
import '../models/profile.dart';
import '../models/readiness.dart';
import '../models/service.dart';
import '../services/ai_service.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import '../services/eligibility_service.dart';
import '../services/notification_service.dart';
import '../services/service_discovery_service.dart';
import '../services/zip_service.dart';
import '../utils/l10n.dart';

/// Bottom-navigation tab indices used across the app.
abstract final class AppTabs {
  static const int home = 0;
  static const int services = 1;
  static const int journey = 2;
  static const int documents = 3;
  static const int applications = 4;
}

/// Application-wide state.
///
/// A single [ChangeNotifier] over the local [AppDataStore] with the mock
/// services wired in. Every mutation calls [notifyListeners] so readiness,
/// vault and journey widgets refresh together. Later the store is replaced
/// by API-backed repositories behind the same service interfaces.
class AppState extends ChangeNotifier {
  AppState({
    AppDataStore? store,
    AuthService? authService,
    DocumentService? documentService,
    EligibilityService? eligibilityService,
    ServiceDiscoveryService? discoveryService,
    ApplicationService? applicationService,
    NotificationService? notificationService,
    AIService? aiService,
    ZipService? zipService,
  }) : _store = store ?? AppDataStore() {
    _auth = authService ?? LocalAuthService(_store);
    _documents = documentService ?? LocalDocumentService(_store);
    _eligibility = eligibilityService ?? LocalEligibilityService();
    _discovery = discoveryService ?? LocalServiceDiscoveryService(_store);
    _applications = applicationService ?? LocalApplicationService(_store);
    _notifications = notificationService ?? LocalNotificationService(_store);
    _ai = aiService ?? LocalAIService(_store);
    _zip = zipService ?? LocalZipService();
    _seedChat();
  }

  final AppDataStore _store;

  late final AuthService _auth;
  late final DocumentService _documents;
  late final EligibilityService _eligibility;
  late final ServiceDiscoveryService _discovery;
  late final ApplicationService _applications;
  late final NotificationService _notifications;
  late final AIService _ai;
  late final ZipService _zip;

  AppLanguage _language = AppLanguage.english;
  bool _seenOnboarding = false;
  List<AssistantMessage> _chat = [];
  int _activeTabIndex = AppTabs.home;
  DocumentType? _pendingDocFocus;
  String? _pendingServiceQuery;

  // ---- Accessors ----

  AppLanguage get language => _language;
  bool get hasSeenOnboarding => _seenOnboarding;
  List<AssistantMessage> get chatMessages => List.unmodifiable(_chat);
  int get activeTabIndex => _activeTabIndex;

  void goToTab(int index) {
    if (_activeTabIndex == index) return;
    _activeTabIndex = index;
    if (index != AppTabs.services) _pendingServiceQuery = null;
    notifyListeners();
  }

  /// Switches to the Services tab with a query to prefill (used by the Home
  /// "Find My Service" CTA).
  void openServicesTab([String query = '']) {
    _pendingServiceQuery = query.isEmpty ? null : query;
    _activeTabIndex = AppTabs.services;
    notifyListeners();
  }

  /// Consumed once by the Services tab when it becomes visible.
  String? consumePendingServiceQuery() {
    final q = _pendingServiceQuery;
    _pendingServiceQuery = null;
    return q;
  }

  /// Switches to the Documents tab, optionally auto-opening the upload flow
  /// for [uploadType] (used by "Upload/Renew" CTAs on other tabs).
  void openDocumentsTab({DocumentType? uploadType}) {
    _pendingDocFocus = uploadType;
    _activeTabIndex = AppTabs.documents;
    notifyListeners();
  }

  /// Consumed once by the Documents tab when it becomes visible.
  DocumentType? consumePendingDocUpload() {
    final t = _pendingDocFocus;
    _pendingDocFocus = null;
    return t;
  }

  CitizenDocument? documentById(String id) {
    for (final d in _store.documents) {
      if (d.id == id) return d;
    }
    return null;
  }

  UserProfile get profile => _auth.profile;
  List<CitizenDocument> get vaultDocuments =>
      List.unmodifiable(_store.documents);
  List<GovService> get services => List.unmodifiable(_store.services);
  List<ServiceApplication> get applications => _applications.list();

  String tr(String key, [String fallback = '']) =>
      L10n.tr(_language, key, fallback);

  GovService serviceById(String id) =>
      _store.services.firstWhere((s) => s.id == id);

  /// Service powering the Home readiness hero: the most recently started
  /// active application (falls back to the first service).
  GovService get primaryService {
    final active =
        _store.applications
            .where((a) => !a.isApproved && !a.isRejected)
            .toList()
          ..sort((a, b) => b.startedOn.compareTo(a.startedOn));
    if (active.isNotEmpty) return serviceById(active.first.serviceId);
    return _store.services.first;
  }

  ServiceApplication? applicationFor(String serviceId) =>
      _applications.forService(serviceId);

  int get unreadNotificationCount => _notifications.unreadCount;

  List<AppNotification> get notificationsForDisplay => _notifications.list();

  // ---- Mutations ----

  void setLanguage(AppLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }

  void completeOnboarding() {
    _seenOnboarding = true;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile updated) async {
    await _auth.updateProfile(updated);
    notifyListeners();
  }

  Future<CitizenDocument> uploadDocument(
    DocumentType type,
    String sourceLabel, [
    String? filePath,
  ]) async {
    final doc = await _documents.upload(type, sourceLabel, filePath: filePath);
    notifyListeners();
    return doc;
  }

  Future<CitizenDocument> replaceDocument(
    CitizenDocument existing,
    String sourceLabel, [
    String? filePath,
  ]) async {
    final doc = await _documents.replace(existing, sourceLabel, filePath: filePath);
    notifyListeners();
    return doc;
  }

  Future<ValidityReport> checkValidity(CitizenDocument document) async {
    final report = await _documents.checkValidity(document);
    notifyListeners();
    return report;
  }

  Future<void> removeDocument(String documentId) async {
    await _documents.remove(documentId);
    notifyListeners();
  }

  void markNotificationRead(String id) {
    _notifications.markRead(id);
    notifyListeners();
  }

  void markAllNotificationsRead() {
    _notifications.markAllRead();
    notifyListeners();
  }

  void pushChat(AssistantMessage message) {
    _chat = [..._chat, message];
    notifyListeners();
  }

  void clearChat() {
    _chat = [];
    _seedChat();
    notifyListeners();
  }

  void _seedChat() {
    _chat = [
      AssistantMessage(
        id: 'msg-welcome',
        fromUser: false,
        text:
            'Namaste, ${profile.name.split(' ').first}! 👋 I can find a '
            'government service for you, tell you exactly which documents you '
            'need, and check how ready you are to apply. Try one of these:',
        serviceIds: [for (final s in _store.services.take(4)) s.id],
        quickReplies: const [
          'I want to apply for a scholarship',
          'What documents do I need?',
          'Can I apply with my current documents?',
          'Which documents are expiring?',
        ],
      ),
    ];
  }

  // ---- Derived queries (pure, computed on demand) ----

  ReadinessSummary readinessFor(GovService service) =>
      computeReadiness(service, _store.documents);

  ReadinessSummary readinessForId(String serviceId) =>
      readinessFor(serviceById(serviceId));

  EligibilityReport eligibilityFor(GovService service) => _eligibility.evaluate(
    service: service,
    profile: _auth.profile,
    vault: _store.documents,
  );

  List<GovService> searchServices(ServiceFilter filter) =>
      _discovery.search(filter);

  ServiceJourney journeyFor(ServiceApplication app) =>
      _applications.journeyFor(app);

  ServiceApplication startJourney(GovService service) {
    final app = _applications.startForService(service);
    notifyListeners();
    return app;
  }

  /// Demo progression: move the application to its next phase.
  ServiceApplication advanceApplication(String applicationId) {
    final app = _store.applications.firstWhere(
      (a) => a.id == applicationId,
      orElse: () => _store.applications.first,
    );
    final advanced = _applications.advance(app);
    notifyListeners();
    return advanced;
  }

  Future<AssistantMessage> askAssistant({
    required String query,
    String? contextServiceId,
  }) => _ai.reply(query: query, contextServiceId: contextServiceId);

  List<String> get aiProcessingSteps => _ai.processingSteps;

  Future<ZipPackResult> createZip(GovService service) async {
    return _zip.buildServicePack(
      service: service,
      summary: readinessFor(service),
    );
  }
}
