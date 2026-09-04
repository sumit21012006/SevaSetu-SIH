import '../models/document.dart';

/// Builds the demo citizen's document vault.
///
/// Dates are computed relative to `now` so the demo always looks alive:
/// the Income Certificate has just lapsed, the Caste Certificate expires
/// soon, and the Bank Passbook awaits verification.
List<CitizenDocument> buildSeedDocuments({DateTime? now}) {
  final t = now ?? DateTime.now();
  final y = DateTime(t.year, t.month, t.day);

  DateTime years(int n) => DateTime(y.year - n, y.month, y.day);
  DateTime plusDays(int n) => y.add(Duration(days: n));

  return [
    CitizenDocument(
      id: 'doc-aadhaar',
      type: DocumentType.aadhaar,
      uploadedAt: years(4),
      issuedAt: years(5),
      verified: true,
      docNumber: '1234 5678 4521',
      issuer: 'UIDAI',
      note: 'Verified against the UIDAI database.',
    ),
    CitizenDocument(
      id: 'doc-domicile',
      type: DocumentType.domicile,
      uploadedAt: years(2),
      issuedAt: years(2),
      expiresAt: DateTime(y.year + 8, y.month, y.day),
      verified: true,
      docNumber: 'DOM/MH/PUNE/2024/00218',
      issuer: 'Collector Office, Pune',
      note: 'Domicile certificate of Maharashtra, Pune district.',
    ),
    CitizenDocument(
      id: 'doc-marksheet',
      type: DocumentType.marksheet,
      uploadedAt: years(1),
      issuedAt: years(3),
      verified: true,
      docNumber: 'HSC/MH/2023/14551',
      issuer: 'Maharashtra State Board',
      note: 'Class XII (HSC) marksheet — 72.4%.',
    ),
    CitizenDocument(
      id: 'doc-caste',
      type: DocumentType.caste,
      uploadedAt: years(4),
      issuedAt: years(5).subtract(const Duration(days: 200)),
      expiresAt: plusDays(150),
      verified: true,
      docNumber: 'CST/MH/OBC/2021/00333',
      issuer: 'Sub-Divisional Magistrate, Pune',
      note: 'OBC caste certificate (validity period).',
    ),
    CitizenDocument(
      id: 'doc-bank',
      type: DocumentType.bankPassbook,
      uploadedAt: plusDays(-40),
      verified: false,
      awaitingVerification: true,
      docNumber: 'SBI Pune Main 36721-7741',
      issuer: 'State Bank of India',
      note: 'Latest passbook pages uploaded — verification pending.',
    ),
    CitizenDocument(
      id: 'doc-income',
      type: DocumentType.income,
      uploadedAt: years(3),
      issuedAt: years(3).subtract(const Duration(days: 60)),
      expiresAt: plusDays(-35),
      verified: true,
      docNumber: 'INC/MH/PUNE/2023/00884',
      issuer: 'Tehsildar Office, Haveli',
      note: 'Family income certificate — validity has lapsed.',
    ),
    CitizenDocument(
      id: 'doc-photo',
      type: DocumentType.photograph,
      uploadedAt: plusDays(-180),
      issuedAt: plusDays(-180),
      verified: true,
      docNumber: '',
      issuer: 'Studio photo',
      note: 'Passport-size photograph on white background.',
    ),
  ];
}
