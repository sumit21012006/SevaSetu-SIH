/// Document-centric models: types, categories, statuses and the citizen's
/// vault documents.
library;

import '../core/app_constants.dart';

enum DocumentCategory {
  identity('Identity'),
  address('Address'),
  income('Income'),
  education('Education'),
  financial('Financial'),
  photo('Photo'),
  land('Land & Property');

  const DocumentCategory(this.label);
  final String label;
}

enum DocumentType {
  aadhaar('Aadhaar Card', DocumentCategory.identity, 'UIDAI', '•••• •••• 4521'),
  domicile(
    'Domicile Certificate',
    DocumentCategory.address,
    'Collector Office',
    'DOM/MH/PN/..218',
  ),
  income(
    'Income Certificate',
    DocumentCategory.income,
    'Tehsildar Office',
    'INC/MH/..884',
  ),
  caste(
    'Caste Certificate',
    DocumentCategory.identity,
    'Sub-Divisional Magistrate',
    'CST/MH/..033',
  ),
  marksheet(
    'Previous Marksheet',
    DocumentCategory.education,
    'Board / University',
    'HSC/2023/..551',
  ),
  bankPassbook(
    'Bank Passbook',
    DocumentCategory.financial,
    'Bank Branch',
    'SBI ..7741',
  ),
  photograph('Passport-size Photograph', DocumentCategory.photo, 'Self', '—'),
  addressProof(
    'Address Proof',
    DocumentCategory.address,
    'Issuing Authority',
    'ADDR/MH/..206',
  ),
  landRecord(
    'Land Records (7/12)',
    DocumentCategory.land,
    'Land Records Office',
    '7-12/..492',
  );

  const DocumentType(this.title, this.category, this.issuer, this.sampleNumber);

  final String title;
  final DocumentCategory category;
  final String issuer;
  final String sampleNumber;
}

/// Citizen-facing status of a document. Always rendered with icon + label.
enum DocStatus {
  verified,
  available,
  verificationRequired,
  expiringSoon,
  expired,
  invalid,
  missing,
}

/// One document inside the citizen's Document Vault.
class CitizenDocument {
  const CitizenDocument({
    required this.id,
    required this.type,
    required this.uploadedAt,
    this.issuedAt,
    this.expiresAt,
    this.verified = true,
    this.awaitingVerification = false,
    this.docNumber,
    this.issuer,
    this.note,
    this.filePath,
    this.verificationBadge,
  });

  final String id;
  final DocumentType type;
  final DateTime uploadedAt;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  /// True once the document has passed a validity/verification check.
  final bool verified;

  /// Fresh uploads await verification against the issuing authority.
  final bool awaitingVerification;

  final String? docNumber;
  final String? issuer;
  final String? note;
  final String? filePath;
  final String? verificationBadge;

  String get title => type.title;

  /// Effective status derived from expiry + verification state so that
  /// readiness always reflects reality.
  DocStatus get status {
    final now = DateTime.now();
    final exp = expiresAt;
    if (exp != null && !exp.isAfter(now)) {
      return DocStatus.expired;
    }
    if (awaitingVerification && !verified) {
      return DocStatus.verificationRequired;
    }
    if (exp != null) {
      final daysLeft = exp.difference(now).inDays;
      if (daysLeft >= 0 && daysLeft <= expiringSoonDays) {
        return DocStatus.expiringSoon;
      }
    }
    if (verified) {
      return DocStatus.verified;
    }
    return DocStatus.available;
  }

  bool get isExpired => status == DocStatus.expired;
  bool get isExpiringSoon => status == DocStatus.expiringSoon;
  bool get isValidNow =>
      status == DocStatus.verified ||
      status == DocStatus.available ||
      status == DocStatus.verificationRequired;

  CitizenDocument copyWith({
    bool? verified,
    bool? awaitingVerification,
    String? docNumber,
    String? issuer,
    DateTime? expiresAt,
    DateTime? issuedAt,
    DateTime? uploadedAt,
    String? note,
    String? filePath,
    String? verificationBadge,
  }) {
    return CitizenDocument(
      id: id,
      type: type,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      verified: verified ?? this.verified,
      awaitingVerification: awaitingVerification ?? this.awaitingVerification,
      docNumber: docNumber ?? this.docNumber,
      issuer: issuer ?? this.issuer,
      note: note ?? this.note,
      filePath: filePath ?? this.filePath,
      verificationBadge: verificationBadge ?? this.verificationBadge,
    );
  }
}
