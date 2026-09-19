import '../../../models/document.dart';
import '../../../models/eligibility.dart';
import '../../../models/profile.dart';
import '../../../models/service.dart';
import '../knowledge/knowledge_repository.dart';

/// Deterministic engine that evaluates eligibility rules against profile and vault.
///
/// Ensures 100% mathematical certainty for numerical limits (income, age),
/// document availability, and residency criteria before LLM reasoning.
class EligibilityEngine {
  const EligibilityEngine();

  /// Evaluates all rules for a given service against the user profile and document vault.
  EligibilityReport evaluate({
    required GovService service,
    required UserProfile? profile,
    required List<CitizenDocument> vault,
    KnowledgeRepository? knowledgeRepo,
  }) {
    final List<EligibilityRuleResult> results = [];
    final List<String> notes = [];

    // Check if we have external declarative rules from knowledge repo
    final declarativeRules = knowledgeRepo?.getRulesForService(service.id) ?? const [];

    if (declarativeRules.isNotEmpty) {
      for (final ruleJson in declarativeRules) {
        final res = _evaluateDeclarativeRule(ruleJson, profile, vault);
        results.add(res);
      }
    } else {
      // Fall back to GovService embedded rules
      for (final rule in service.eligibility) {
        if (profile == null) {
          results.add(
            EligibilityRuleResult(
              rule,
              false,
              status: EligibilityStatus.unknown,
              reason: 'Profile details not provided',
            ),
          );
          continue;
        }

        final passed = rule.check(profile, vault);
        results.add(
          EligibilityRuleResult(
            rule,
            passed,
            status: passed ? EligibilityStatus.met : EligibilityStatus.notMet,
            reason: passed ? 'Criterion verified' : 'Criterion not met based on current profile',
          ),
        );
      }
    }

    if (profile == null) {
      notes.add('Complete your citizen profile to get accurate eligibility results.');
    }

    return EligibilityReport(
      service: service,
      results: results,
      notes: notes,
    );
  }

  EligibilityRuleResult _evaluateDeclarativeRule(
    Map<String, dynamic> json,
    UserProfile? profile,
    List<CitizenDocument> vault,
  ) {
    final description = json['description'] as String? ?? 'Rule';
    final weight = (json['weight'] as num?)?.toDouble() ?? 20.0;
    final citation = json['citation'] as String? ?? '';
    final field = json['field'] as String? ?? '';
    final op = json['operator'] as String? ?? 'equals';

    final dummyRule = EligibilityRule(
      title: description,
      weight: weight,
      failHint: citation.isNotEmpty ? 'According to $citation' : description,
      check: (_, __) => false,
    );

    if (field.startsWith('hasDocument:')) {
      final docTypeName = field.split(':')[1];
      final matching = vault.where((d) => d.type.name == docTypeName && d.isValidNow).toList();
      final passed = matching.isNotEmpty;
      return EligibilityRuleResult(
        dummyRule,
        passed,
        status: passed ? EligibilityStatus.met : EligibilityStatus.notMet,
        reason: passed
            ? 'Valid $docTypeName found in vault'
            : 'Missing or expired $docTypeName in vault',
        citation: citation,
      );
    }

    if (field.startsWith('hasAnyDocument:')) {
      final docTypes = field.split(':')[1].split(',');
      final matching = vault.where((d) => docTypes.contains(d.type.name) && d.isValidNow).toList();
      final passed = matching.isNotEmpty;
      return EligibilityRuleResult(
        dummyRule,
        passed,
        status: passed ? EligibilityStatus.met : EligibilityStatus.notMet,
        reason: passed
            ? 'Valid qualifying document present in vault'
            : 'None of the qualifying documents (${docTypes.join(", ")}) found in vault',
        citation: citation,
      );
    }

    if (profile == null) {
      return EligibilityRuleResult(
        dummyRule,
        false,
        status: EligibilityStatus.unknown,
        reason: 'Profile data missing for evaluating $field',
        citation: citation,
      );
    }

    // Evaluate profile fields
    dynamic actualValue;
    switch (field) {
      case 'age':
        actualValue = profile.age;
        break;
      case 'annualIncomeLakhs':
        actualValue = profile.annualIncomeLakhs;
        break;
      case 'occupation':
        actualValue = profile.occupation.name;
        break;
      case 'education':
        actualValue = profile.education.name;
        break;
      case 'casteCategory':
        actualValue = profile.casteCategory.name;
        break;
      case 'state':
        actualValue = profile.state;
        break;
      default:
        actualValue = null;
    }

    bool passed = false;
    String reason = '';

    if (op == 'range') {
      final min = (json['min'] as num?)?.toDouble() ?? 0;
      final max = (json['max'] as num?)?.toDouble() ?? 100;
      if (actualValue is num) {
        passed = actualValue >= min && actualValue <= max;
        reason = passed
            ? 'Value $actualValue is within eligible range ($min–$max)'
            : 'Value $actualValue is outside required range ($min–$max)';
      }
    } else if (op == 'lte') {
      final target = (json['value'] as num?)?.toDouble() ?? 0;
      if (actualValue is num) {
        passed = actualValue <= target;
        reason = passed
            ? 'Value ₹${actualValue}L is within ceiling limit of ₹${target}L'
            : 'Value ₹${actualValue}L exceeds maximum ceiling of ₹${target}L';
      }
    } else if (op == 'gte') {
      final target = (json['value'] as num?)?.toDouble() ?? 0;
      if (actualValue is num) {
        passed = actualValue >= target;
        reason = passed
            ? 'Value $actualValue meets minimum requirement of $target'
            : 'Value $actualValue is below required minimum of $target';
      }
    } else if (op == 'equals') {
      final target = json['value']?.toString();
      passed = actualValue.toString().toLowerCase() == target?.toLowerCase();
      reason = passed ? 'Matches required condition ($target)' : 'Current: $actualValue, Required: $target';
    } else if (op == 'not_equals') {
      final target = json['value']?.toString();
      passed = actualValue.toString().toLowerCase() != target?.toLowerCase();
      reason = passed ? 'Complies with non-eligibility restriction ($target)' : 'Falls under restricted category ($target)';
    }

    return EligibilityRuleResult(
      dummyRule,
      passed,
      status: passed ? EligibilityStatus.met : EligibilityStatus.notMet,
      reason: reason,
      citation: citation,
    );
  }

  /// Formats deterministic evaluation results into an LLM-grounding string block.
  String formatReportForPrompt(EligibilityReport report) {
    final buffer = StringBuffer();
    buffer.writeln('### DETERMINISTIC ENGINE EVALUATION RESULTS:');
    buffer.writeln('Scheme: ${report.service.name} (ID: ${report.service.id})');
    buffer.writeln('Overall Match: ${report.matchPercent}%');
    buffer.writeln('Is Eligible: ${report.isEligible}');
    buffer.writeln('Criteria Breakdown:');
    for (final r in report.results) {
      final mark = r.effectiveStatus == EligibilityStatus.met ? '[PASS]' : '[FAIL]';
      buffer.writeln('  - $mark ${r.rule.title} (Weight: ${r.rule.weight.round()}%)');
      if (r.reason != null) buffer.writeln('    Reason: ${r.reason}');
      if (r.citation != null) buffer.writeln('    Citation: ${r.citation}');
    }
    return buffer.toString();
  }
}
