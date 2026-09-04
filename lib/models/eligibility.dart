/// Eligibility reports produced when [service.EligibilityRule]s are evaluated
/// against the citizen's profile and vault.
library;

import 'service.dart';

class EligibilityRuleResult {
  const EligibilityRuleResult(this.rule, this.passed);

  final EligibilityRule rule;
  final bool passed;
}

class EligibilityReport {
  const EligibilityReport({
    required this.service,
    required this.results,
    required this.notes,
  });

  final GovService service;
  final List<EligibilityRuleResult> results;

  /// Extra guidance computed alongside the score.
  final List<String> notes;

  double get _passedWeight =>
      results.where((r) => r.passed).fold(0.0, (sum, r) => sum + r.rule.weight);

  double get _totalWeight => results.fold(0.0, (sum, r) => sum + r.rule.weight);

  int get matchPercent =>
      _totalWeight == 0 ? 0 : (_passedWeight / _totalWeight * 100).round();

  bool get isEligible => matchPercent >= 60;

  List<EligibilityRuleResult> get failed =>
      results.where((r) => !r.passed).toList();

  String get summary {
    if (results.isEmpty) return 'Eligibility could not be checked.';
    if (isEligible) {
      return 'Based on your profile you appear eligible for ${service.name}.';
    }
    return 'Some eligibility criteria are not met for ${service.name}.';
  }
}
