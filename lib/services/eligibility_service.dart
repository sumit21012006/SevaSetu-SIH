import '../models/document.dart';
import '../models/eligibility.dart';
import '../models/profile.dart';
import '../models/service.dart';

/// Eligibility engine: evaluates a service's rules against the citizen's
/// profile and current vault to produce a personalised match score.
///
/// Future implementation: a rule engine backed by PostgreSQL + an
/// eligibility micro-service; the scoring contract stays identical.
abstract class EligibilityService {
  EligibilityReport evaluate({
    required GovService service,
    required UserProfile profile,
    required List<CitizenDocument> vault,
  });
}

class LocalEligibilityService implements EligibilityService {
  LocalEligibilityService();

  @override
  EligibilityReport evaluate({
    required GovService service,
    required UserProfile profile,
    required List<CitizenDocument> vault,
  }) {
    final results = <EligibilityRuleResult>[
      for (final rule in service.eligibility)
        EligibilityRuleResult(rule, rule.check(profile, vault)),
    ];

    final notes = <String>[
      for (final r in results)
        if (!r.passed && r.rule.failHint.isNotEmpty) r.rule.failHint,
    ];

    return EligibilityReport(service: service, results: results, notes: notes);
  }
}
