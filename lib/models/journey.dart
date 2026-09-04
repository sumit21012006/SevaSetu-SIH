/// The personalised service journey — a citizen walks through seven phases
/// from discovery to tracking.
library;

enum PhaseId {
  discover,
  eligibility,
  documents,
  verification,
  guidance,
  apply,
  track,
}

enum PhaseState { completed, current, upcoming }

class JourneyStep {
  const JourneyStep({required this.phase, required this.state});

  final PhaseId phase;
  final PhaseState state;

  bool get isCompleted => state == PhaseState.completed;
  bool get isCurrent => state == PhaseState.current;
}

class ServiceJourney {
  const ServiceJourney({
    required this.serviceId,
    required this.serviceName,
    required this.steps,
  });

  final String serviceId;
  final String serviceName;
  final List<JourneyStep> steps;

  /// Zero-based index of the current (in-progress) step.
  int get currentIndex {
    final i = steps.indexWhere((s) => s.isCurrent);
    return i < 0 ? steps.length - 1 : i;
  }
}

/// Builds a journey whose current phase is [currentPhaseId]. Every phase
/// before it is completed; every phase after it is upcoming.
ServiceJourney buildJourney({
  required String serviceId,
  required String serviceName,
  required PhaseId currentPhaseId,
}) {
  final all = PhaseId.values;
  final current = all.indexOf(currentPhaseId);
  final steps = <JourneyStep>[
    for (var i = 0; i < all.length; i++)
      JourneyStep(
        phase: all[i],
        state: i < current
            ? PhaseState.completed
            : i == current
            ? PhaseState.current
            : PhaseState.upcoming,
      ),
  ];
  return ServiceJourney(
    serviceId: serviceId,
    serviceName: serviceName,
    steps: steps,
  );
}
