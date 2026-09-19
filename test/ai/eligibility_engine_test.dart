import 'package:flutter_test/flutter_test.dart';
import 'package:sevasetu/data/seed_services.dart';
import 'package:sevasetu/models/document.dart';
import 'package:sevasetu/models/profile.dart';
import 'package:sevasetu/services/ai/engine/eligibility_engine.dart';

void main() {
  group('EligibilityEngine Unit Tests', () {
    const engine = EligibilityEngine();
    final services = buildSeedServices();
    final pmsService = services.firstWhere((s) => s.id == 'svc-pms');
    final ladkiBahinService = services.firstWhere((s) => s.id == 'svc-ladki-bahin');
    final farmerService = services.firstWhere((s) => s.id == 'svc-farmer');

    test('Student profile passes PMS occupation and income criteria', () {
      final studentProfile = const UserProfile(
        id: 'p1',
        name: 'Arjun',
        age: 20,
        state: 'Maharashtra',
        district: 'Pune',
        occupation: Occupation.student,
        education: EducationLevel.undergrad,
        annualIncomeLakhs: 3.4,
        casteCategory: CasteCategory.obc,
      );

      final report = engine.evaluate(
        service: pmsService,
        profile: studentProfile,
        vault: [],
      );

      expect(report.matchPercent, greaterThanOrEqualTo(50));
      expect(report.results.any((r) => r.rule.title.contains('student') && r.passed), isTrue);
      expect(report.results.any((r) => r.rule.title.contains('income') && r.passed), isTrue);
    });

    test('Over-income non-resident fails Ladki Bahin criteria', () {
      final ineligibleProfile = const UserProfile(
        id: 'p2',
        name: 'Anita',
        age: 70, // Over age ceiling of 65
        state: 'Gujarat',
        district: 'Surat',
        occupation: Occupation.privateEmployee,
        education: EducationLevel.postgrad,
        annualIncomeLakhs: 9.5, // Exceeds 2.5L
        casteCategory: CasteCategory.general,
      );

      final report = engine.evaluate(
        service: ladkiBahinService,
        profile: ineligibleProfile,
        vault: [],
      );

      expect(report.isEligible, isFalse);
      expect(report.matchPercent, lessThan(40));
    });

    test('Farmer profile with 7/12 land record in vault passes PM-KISAN rules', () {
      final farmerProfile = const UserProfile(
        id: 'p3',
        name: 'Ramesh',
        age: 45,
        state: 'Maharashtra',
        district: 'Kolhapur',
        occupation: Occupation.farmer,
        education: EducationLevel.secondary,
        annualIncomeLakhs: 1.8,
        casteCategory: CasteCategory.general,
      );

      final vaultWithLandRecord = [
        CitizenDocument(
          id: 'doc-land',
          type: DocumentType.landRecord,
          uploadedAt: DateTime.now(),
          verified: true,
        ),
      ];

      final report = engine.evaluate(
        service: farmerService,
        profile: farmerProfile,
        vault: vaultWithLandRecord,
      );

      expect(report.results.any((r) => r.rule.title.contains('farmer') && r.passed), isTrue);
      expect(report.results.any((r) => r.rule.title.contains('land') && r.passed), isTrue);
    });
  });
}
