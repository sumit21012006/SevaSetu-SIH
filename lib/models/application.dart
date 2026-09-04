/// Application tracking models used by the Applications screen.
library;

import 'journey.dart';

enum ApplicationPhase {
  serviceSelected('Service Selected'),
  eligibilityChecked('Eligibility Checked'),
  documentsPrepared('Documents Prepared'),
  applicationSubmitted('Application Submitted'),
  underVerification('Under Verification'),
  approved('Approved'),
  rejected('Rejected');

  const ApplicationPhase(this.label);
  final String label;
}

class TimelineEvent {
  const TimelineEvent({required this.phase, required this.state});

  final ApplicationPhase phase;
  final PhaseState state;

  bool get isCompleted => state == PhaseState.completed;
  bool get isCurrent => state == PhaseState.current;
}

class ServiceApplication {
  const ServiceApplication({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.department,
    required this.startedOn,
    required this.currentPhase,
    this.applicationNumber,
    this.submittedOn,
    this.statusDetail = '',
  });

  final String id;
  final String serviceId;
  final String serviceName;
  final String department;
  final DateTime startedOn;
  final ApplicationPhase currentPhase;
  final String? applicationNumber;
  final DateTime? submittedOn;

  /// Extra tracking detail shown under the phase label.
  final String statusDetail;

  List<TimelineEvent> get timeline {
    const ordered = ApplicationPhase.values;
    final current = ordered.indexOf(currentPhase);
    return [
      for (var i = 0; i < ordered.length; i++)
        TimelineEvent(
          phase: ordered[i],
          state: i < current
              ? PhaseState.completed
              : i == current
              ? PhaseState.current
              : PhaseState.upcoming,
        ),
    ];
  }

  bool get isRejected => currentPhase == ApplicationPhase.rejected;
  bool get isApproved => currentPhase == ApplicationPhase.approved;
}
