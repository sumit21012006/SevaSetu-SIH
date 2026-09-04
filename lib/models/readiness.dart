/// Readiness computation: for a chosen service, compare the documents the
/// vault holds against the documents the service requires, and produce the
/// score, missing/expiring lists and ZIP-ready set.
library;

import 'document.dart';
import 'service.dart';

class RequirementCheck {
  const RequirementCheck({
    required this.requirement,
    required this.status,
    this.document,
  });

  final DocumentRequirement requirement;

  /// [DocStatus.missing] when no matching vault document exists.
  final DocStatus status;

  /// The vault document satisfying the requirement, if any.
  final CitizenDocument? document;

  bool get isSatisfied =>
      status == DocStatus.verified ||
      status == DocStatus.available ||
      status == DocStatus.verificationRequired;
}

class ReadinessSummary {
  ReadinessSummary({required this.service, required this.checks})
    : assert(checks.length == service.requiredDocuments.length);

  final GovService service;
  final List<RequirementCheck> checks;

  int get requiredCount => checks.length;

  List<RequirementCheck> get readyChecks =>
      checks.where((c) => c.isSatisfied).toList();
  List<RequirementCheck> get expiringChecks =>
      checks.where((c) => c.status == DocStatus.expiringSoon).toList();
  List<RequirementCheck> get expiredChecks =>
      checks.where((c) => c.status == DocStatus.expired).toList();
  List<RequirementCheck> get missingChecks =>
      checks.where((c) => c.status == DocStatus.missing).toList();
  List<RequirementCheck> get invalidChecks =>
      checks.where((c) => c.status == DocStatus.invalid).toList();
  List<RequirementCheck> get verifyChecks =>
      checks.where((c) => c.status == DocStatus.verificationRequired).toList();

  int get readyCount => readyChecks.length;
  int get attentionCount => requiredCount - readyCount;

  /// 4 of 6 => 67 (rounded).
  int get percent =>
      requiredCount == 0 ? 0 : (readyCount / requiredCount * 100).round();

  /// Documents that can be packed into the download ZIP right now.
  List<CitizenDocument> get zipDocuments =>
      readyChecks.map((c) => c.document).whereType<CitizenDocument>().toList();

  bool get isFullyReady => readyCount == requiredCount && requiredCount > 0;

  /// A one-line human summary ("You're almost ready to apply.").
  String get message {
    if (requiredCount == 0) return 'No documents required for this service.';
    if (isFullyReady) return "You're fully ready to apply. 🎉";
    if (readyCount >= requiredCount - 1) {
      return "You're almost ready to apply.";
    }
    if (readyCount == 0) return 'Documents are yet to be prepared.';
    return 'Some documents still need your attention.';
  }
}

/// Pure helper: map a vault to a [ReadinessSummary] for one service.
/// The most recently uploaded document of a type satisfies the requirement.
ReadinessSummary computeReadiness(
  GovService service,
  List<CitizenDocument> vault,
) {
  final checks = <RequirementCheck>[];
  for (final requirement in service.requiredDocuments) {
    final matches = vault.where((d) => d.type == requirement.type).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    if (matches.isEmpty) {
      checks.add(
        RequirementCheck(requirement: requirement, status: DocStatus.missing),
      );
      continue;
    }
    final doc = matches.first;
    checks.add(
      RequirementCheck(
        requirement: requirement,
        status: doc.status,
        document: doc,
      ),
    );
  }
  return ReadinessSummary(service: service, checks: checks);
}
