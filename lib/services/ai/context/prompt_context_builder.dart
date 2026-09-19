import 'dart:convert';
import '../../../models/document.dart';
import '../../../models/profile.dart';
import '../../../models/service.dart';
import '../../../utils/l10n.dart';
import '../models/ai_source.dart';

/// Builder that generates strictly anonymized, privacy-safe prompts for LLMs.
///
/// Under NO circumstance may personal identifiers (citizen full name, phone number,
/// Aadhaar/document numbers, or local file system paths) be included in the output.
class PromptContextBuilder {
  static const Set<String> forbiddenKeys = {
    'name',
    'phone',
    'id',
    'filepath',
    'file_path',
    'docnumber',
    'doc_number',
    'aadhaarnumber',
  };

  /// Builds a strictly whitelisted representation of the user profile.
  static Map<String, dynamic> buildSafeProfileMap(UserProfile? profile) {
    if (profile == null) return const {};

    return {
      'age': profile.age,
      'state': profile.state,
      'district': profile.district,
      'occupation': profile.occupation.label,
      'education': profile.education.label,
      'annualIncomeLakhs': profile.annualIncomeLakhs,
      'casteCategory': profile.casteCategory.label,
      'familySize': profile.familySize,
    };
  }

  /// Builds a strictly whitelisted list of document metadata from the vault.
  static List<Map<String, dynamic>> buildSafeVaultList(List<CitizenDocument> vault) {
    return vault.map((doc) {
      return {
        'documentType': doc.type.name,
        'title': doc.type.title,
        'status': doc.status.label,
        'isValidNow': doc.isValidNow,
        'isVerified': doc.verified,
      };
    }).toList();
  }

  /// Builds a summary string of available government schemes in catalogue.
  static String buildServicesCatalog(List<GovService> services) {
    final buffer = StringBuffer();
    for (final s in services) {
      buffer.writeln('- Scheme ID: ${s.id}');
      buffer.writeln('  Name: ${s.name}');
      buffer.writeln('  Category: ${s.category.label}');
      buffer.writeln('  Department: ${s.department}');
      buffer.writeln('  Description: ${s.shortDescription}');
      buffer.writeln('  Required Docs: ${s.requiredDocuments.map((d) => d.type.title).join(", ")}');
      buffer.writeln('  Apply Portal: ${s.applyPortal}');
      buffer.writeln('');
    }
    return buffer.toString().trim();
  }

  /// Builds a summary string of official resolutions / sources.
  static String buildSourcesCatalog(List<AISource> sources) {
    final buffer = StringBuffer();
    for (final src in sources) {
      buffer.writeln('- [${src.id}] ${src.title}');
      if (src.documentNumber != null) buffer.writeln('  GR/Ref: ${src.documentNumber}');
      buffer.writeln('  Authority: ${src.authority}');
      if (src.issueDate != null) buffer.writeln('  Date: ${src.issueDate}');
      if (src.summary != null) buffer.writeln('  Summary: ${src.summary}');
      buffer.writeln('');
    }
    return buffer.toString().trim();
  }

  /// Formats language prompt instruction.
  static String languageDirective(AppLanguage language) {
    switch (language) {
      case AppLanguage.hindi:
        return 'IMPORTANT: You must respond in natural, polite Hindi (Devanagari script), keeping technical scheme terms clear.';
      case AppLanguage.marathi:
        return 'IMPORTANT: You must respond in natural, polite Marathi (Devanagari script), appropriate for Maharashtra citizens.';
      case AppLanguage.english:
        return 'Respond in clear, accessible Indian English.';
    }
  }

  /// Generates the complete system context block for an agent prompt.
  static String buildSystemContext({
    UserProfile? profile,
    List<CitizenDocument> vault = const [],
    List<GovService> services = const [],
    List<AISource> sources = const [],
    AppLanguage language = AppLanguage.english,
  }) {
    final safeProfile = buildSafeProfileMap(profile);
    final safeVault = buildSafeVaultList(vault);

    final buffer = StringBuffer();
    buffer.writeln('### CITIZEN ANONYMIZED PROFILE (Read-only context):');
    if (safeProfile.isEmpty) {
      buffer.writeln('No profile provided.');
    } else {
      buffer.writeln(jsonEncode(safeProfile));
    }
    buffer.writeln();

    buffer.writeln('### CITIZEN DOCUMENT VAULT STATUS (Metadata only):');
    if (safeVault.isEmpty) {
      buffer.writeln('No documents in vault.');
    } else {
      buffer.writeln(jsonEncode(safeVault));
    }
    buffer.writeln();

    if (services.isNotEmpty) {
      buffer.writeln('### OFFICIAL SERVICES CATALOGUE:');
      buffer.writeln(buildServicesCatalog(services));
      buffer.writeln();
    }

    if (sources.isNotEmpty) {
      buffer.writeln('### OFFICIAL GROUNDING RESOLUTIONS & SOURCES:');
      buffer.writeln(buildSourcesCatalog(sources));
      buffer.writeln();
    }

    buffer.writeln('### LANGUAGE REQUIREMENT:');
    buffer.writeln(languageDirective(language));

    return buffer.toString();
  }

  /// Validates that a serialized payload contains none of the strictly forbidden privacy keys.
  static bool assertPrivacySafety(Map<String, dynamic> payload) {
    final jsonStr = jsonEncode(payload).toLowerCase();
    for (final key in forbiddenKeys) {
      if (jsonStr.contains('"$key":')) {
        return false;
      }
    }
    return true;
  }
}
