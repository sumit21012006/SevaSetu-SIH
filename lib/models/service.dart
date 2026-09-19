/// Government service models: categories, required documents and the
/// service catalogue entry shown across discovery surfaces.
library;

import 'document.dart';
import 'profile.dart';

/// One eligibility criterion evaluated against the profile + vault.
class EligibilityRule {
  const EligibilityRule({
    required this.title,
    required this.weight,
    required this.check,
    this.failHint = '',
  });

  /// What the citizen needs to satisfy.
  final String title;

  /// Contribution towards the 100-point match (higher = more important).
  final double weight;

  /// Evaluated with the profile and the current vault documents.
  final bool Function(UserProfile profile, List<CitizenDocument> vault) check;

  /// Shown when the rule does not pass.
  final String failHint;
}

enum ServiceCategory {
  education('Education', 'Post-Matric Scholarship', 'scholarships.gov.in'),
  women('Women & Child', 'Ladki Bahin Yojana', 'ladakibahin.maharashtra.gov.in'),
  identity('Identity & Travel', 'Passport Seva', 'passportindia.gov.in'),
  agriculture('Agriculture', 'PM-KISAN & Namo Shetkari', 'pmkisan.gov.in'),
  financial('Banking & Finance', 'Jan Dhan Bank Account', 'pmjdy.gov.in'),
  housing('Housing', 'PMAY', 'pmay-urban.gov.in'),
  employment('Employment', 'Employment Assistance', 'rojgar.mahaswayam.gov.in'),
  other('Other Services', '', '');

  const ServiceCategory(this.label, this.example, this.portal);
  final String label;
  final String example;
  final String portal;
}

/// A document a given service needs from the citizen.
class DocumentRequirement {
  const DocumentRequirement({
    required this.type,
    required this.why,
    this.mandatory = true,
  });

  final DocumentType type;

  /// Human-readable reason this document is required.
  final String why;

  final bool mandatory;
}

class ServiceStep {
  const ServiceStep(this.title, this.detail);
  final String title;
  final String detail;
}

class ImportantDate {
  const ImportantDate(this.title, this.range);
  final String title;
  final String range;
}

class GovService {
  const GovService({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.category,
    required this.department,
    required this.keywords,
    required this.requiredDocuments,
    required this.eligibility,
    required this.process,
    required this.importantDates,
    this.scope = 'All India',
    this.applicationMode = 'Online',
    this.applyPortal = '',
    this.helpline = '',
    this.officialUrl = '',
    this.lastDateNote = '',
  });

  final String id;
  final String name;
  final String shortDescription;
  final String description;
  final ServiceCategory category;
  final String department;
  final String scope;

  /// Natural-language search tokens (English + transliterated Hindi/Marathi).
  final List<String> keywords;

  /// Documents this service requires from the citizen.
  final List<DocumentRequirement> requiredDocuments;

  /// Personalised eligibility criteria evaluated by the eligibility engine.
  final List<EligibilityRule> eligibility;

  final List<ServiceStep> process;
  final List<ImportantDate> importantDates;

  final String applicationMode; // e.g. 'Online', 'Offline', 'Both'
  final String applyPortal; // web portal / office
  final String helpline;
  final String officialUrl;
  final String lastDateNote;
}
