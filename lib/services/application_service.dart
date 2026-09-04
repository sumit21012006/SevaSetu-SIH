import '../data/mock_store.dart';
import '../models/application.dart';
import '../models/journey.dart';
import '../models/service.dart';

/// Tracks the citizen's applications and derives their service journey.
///
/// Future implementation: application records in PostgreSQL + status
/// webhooks from government portals.
abstract class ApplicationService {
  List<ServiceApplication> list();
  ServiceApplication? forService(String serviceId);
  ServiceApplication startForService(GovService service);

  /// Moves an application to its next phase (demo progression).
  ServiceApplication advance(ServiceApplication app);

  /// Maps application progress onto the 7-phase journey.
  ServiceJourney journeyFor(ServiceApplication app);
}

class LocalApplicationService implements ApplicationService {
  LocalApplicationService(this._store);

  final AppDataStore _store;

  @override
  List<ServiceApplication> list() => List.unmodifiable(_store.applications);

  @override
  ServiceApplication? forService(String serviceId) {
    final matches = _store.applications
        .where((a) => a.serviceId == serviceId)
        .toList();
    return matches.isEmpty ? null : matches.first;
  }

  @override
  ServiceApplication startForService(GovService service) {
    final existing = forService(service.id);
    if (existing != null) return existing;
    final app = ServiceApplication(
      id: _store.nextId('app'),
      serviceId: service.id,
      serviceName: service.name,
      department: service.department,
      startedOn: DateTime.now(),
      currentPhase: ApplicationPhase.serviceSelected,
    );
    _store.applications.add(app);
    return app;
  }

  @override
  ServiceApplication advance(ServiceApplication app) {
    const ordered = ApplicationPhase.values;
    final current = ordered.indexOf(app.currentPhase);
    if (current >= ordered.length - 1) return app;
    final next = ordered[current + 1];
    final advanced = ServiceApplication(
      id: app.id,
      serviceId: app.serviceId,
      serviceName: app.serviceName,
      department: app.department,
      startedOn: app.startedOn,
      currentPhase: next,
      applicationNumber: app.applicationNumber,
      submittedOn: next == ApplicationPhase.applicationSubmitted
          ? DateTime.now()
          : app.submittedOn,
      statusDetail: _detailFor(next),
    );
    final index = _store.applications.indexWhere((a) => a.id == app.id);
    if (index >= 0) _store.applications[index] = advanced;
    return advanced;
  }

  String _detailFor(ApplicationPhase phase) {
    switch (phase) {
      case ApplicationPhase.serviceSelected:
        return 'Service selected. Next: confirm eligibility.';
      case ApplicationPhase.eligibilityChecked:
        return 'Eligibility confirmed. Next: prepare documents.';
      case ApplicationPhase.documentsPrepared:
        return 'Documents prepared. Next: submit the application.';
      case ApplicationPhase.applicationSubmitted:
        return 'Submitted — awaiting departmental verification.';
      case ApplicationPhase.underVerification:
        return 'Verification by the department in progress.';
      case ApplicationPhase.approved:
        return 'Approved — benefit will be disbursed.';
      case ApplicationPhase.rejected:
        return 'Rejected — check reason and re-apply if eligible.';
    }
  }

  @override
  ServiceJourney journeyFor(ServiceApplication app) {
    return buildJourney(
      serviceId: app.serviceId,
      serviceName: app.serviceName,
      currentPhaseId: journeyPhaseFor(app.currentPhase),
    );
  }

  PhaseId journeyPhaseFor(ApplicationPhase phase) {
    switch (phase) {
      case ApplicationPhase.serviceSelected:
        return PhaseId.discover;
      case ApplicationPhase.eligibilityChecked:
        return PhaseId.eligibility;
      case ApplicationPhase.documentsPrepared:
        return PhaseId.documents;
      case ApplicationPhase.applicationSubmitted:
        return PhaseId.apply;
      case ApplicationPhase.underVerification:
      case ApplicationPhase.approved:
      case ApplicationPhase.rejected:
        return PhaseId.track;
    }
  }
}
