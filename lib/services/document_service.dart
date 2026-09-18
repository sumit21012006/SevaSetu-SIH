import '../data/mock_store.dart';
import '../models/document.dart';
import '../utils/format.dart';

/// Result of running a validity check on a vault document.
class ValidityReport {
  const ValidityReport({
    required this.status,
    required this.title,
    required this.message,
    this.daysLeft,
  });

  final DocStatus status;
  final String title;
  final String message;
  final int? daysLeft;

  bool get isOk => status == DocStatus.verified;
}

/// Document vault service: upload, replace, verify and check validity.
///
/// Future implementation: Firebase Storage / object storage + OCR-based
/// classification + issuing-authority verification behind these methods.
abstract class DocumentService {
  Future<CitizenDocument> upload(DocumentType type, String sourceLabel, {String? filePath});

  /// Replace an existing (often expired) document with a fresh upload.
  Future<CitizenDocument> replace(CitizenDocument existing, String sourceLabel, {String? filePath});

  /// Simulates a check against the issuing authority.
  Future<ValidityReport> checkValidity(CitizenDocument document);

  Future<void> remove(String documentId);
}

class LocalDocumentService implements DocumentService {
  LocalDocumentService(this._store);

  final AppDataStore _store;

  DateTime get _now => DateTime.now();

  @override
  Future<CitizenDocument> upload(DocumentType type, String sourceLabel, {String? filePath}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _create(type, sourceLabel, null, filePath: filePath);
  }

  @override
  Future<CitizenDocument> replace(
    CitizenDocument existing,
    String sourceLabel, {
    String? filePath,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final doc = _create(existing.type, sourceLabel, existing, filePath: filePath);
    // A replacement supersedes the old (often expired) copy.
    _store.documents.removeWhere((d) => d.id == existing.id);
    return doc;
  }

  CitizenDocument _create(
    DocumentType type,
    String sourceLabel,
    CitizenDocument? replaced, {
    String? filePath,
  }) {
    // Typical validity for certificates; banks/Aadhaar/marksheets do not lapse.
    DateTime? expiry;
    switch (type) {
      case DocumentType.income:
      case DocumentType.caste:
      case DocumentType.domicile:
        expiry = DateTime(_now.year + 3, _now.month, _now.day);
        break;
      case DocumentType.aadhaar:
      case DocumentType.bankPassbook:
      case DocumentType.marksheet:
      case DocumentType.photograph:
      case DocumentType.addressProof:
      case DocumentType.landRecord:
        break;
    }

    final doc = CitizenDocument(
      id: _store.nextId('doc'),
      type: type,
      uploadedAt: _now,
      issuedAt: _now,
      expiresAt: expiry,
      verified: true,
      awaitingVerification: false,
      docNumber: type.sampleNumber,
      issuer: type.issuer,
      note: 'Uploaded via $sourceLabel — verified against Govt database.',
      filePath: filePath,
      verificationBadge: 'Verified Authentic',
    );
    _store.documents.add(doc);
    return doc;
  }

  @override
  Future<ValidityReport> checkValidity(CitizenDocument document) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final status = document.status;
    switch (status) {
      case DocStatus.expired:
        return ValidityReport(
          status: status,
          title: 'Not valid',
          message:
              'This ${document.title} expired on '
              '${Formatters.date(document.expiresAt!)}. '
              'A renewed certificate is required for applications.',
          daysLeft: 0,
        );
      case DocStatus.expiringSoon:
        return ValidityReport(
          status: status,
          title: 'Valid — expiring soon',
          message:
              'Valid ${Formatters.expiryPhrase(document.expiresAt!, includeDate: false)}. '
              'Plan a renewal before applying after that date.',
          daysLeft: Formatters.daysUntil(document.expiresAt),
        );
      case DocStatus.verificationRequired:
        // A fresh upload: run the simulated authority check.
        final idx = _store.documents.indexWhere((d) => d.id == document.id);
        if (idx >= 0) {
          final updated = _store.documents[idx].copyWith(
            verified: true,
            awaitingVerification: false,
            note: 'Verified against issuing-authority records (demo check).',
          );
          _store.documents[idx] = updated;
        }
        return const ValidityReport(
          status: DocStatus.verified,
          title: 'Verification complete',
          message:
              'The document matched issuing-authority records and is '
              'now marked Verified (demo simulation).',
        );
      case DocStatus.verified:
      case DocStatus.available:
        return ValidityReport(
          status: status,
          title: 'Valid',
          message: document.expiresAt == null
              ? 'This ${document.title} has lifetime validity.'
              : 'Valid ${Formatters.expiryPhrase(document.expiresAt!, includeDate: false)}.',
          daysLeft: document.expiresAt == null
              ? null
              : Formatters.daysUntil(document.expiresAt),
        );
      case DocStatus.invalid:
      case DocStatus.missing:
        return ValidityReport(
          status: status,
          title: 'Needs attention',
          message: 'This document cannot be used. Upload a valid copy.',
        );
    }
  }

  @override
  Future<void> remove(String documentId) async {
    _store.documents.removeWhere((d) => d.id == documentId);
  }
}
