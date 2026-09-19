import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevasetu/models/document.dart';
import 'package:sevasetu/models/profile.dart';
import 'package:sevasetu/services/ai/context/prompt_context_builder.dart';

void main() {
  group('Privacy Whitelist Tests', () {
    const sensitiveName = 'Arjun Deshmukh';
    const sensitivePhone = '+91 98765 43210';
    const sensitiveId = 'usr-secret-999';
    const sensitiveFilePath = '/data/user/0/app/vault/aadhaar_original.pdf';
    const sensitiveDocNumber = '9876 5432 1098';

    final profile = const UserProfile(
      id: sensitiveId,
      name: sensitiveName,
      phone: sensitivePhone,
      age: 20,
      state: 'Maharashtra',
      district: 'Pune',
      occupation: Occupation.student,
      education: EducationLevel.undergrad,
      annualIncomeLakhs: 3.4,
      casteCategory: CasteCategory.obc,
      familySize: 4,
    );

    final vault = [
      CitizenDocument(
        id: 'doc-001',
        type: DocumentType.aadhaar,
        uploadedAt: DateTime(2024, 1, 1),
        docNumber: sensitiveDocNumber,
        filePath: sensitiveFilePath,
        note: 'Personal secret note',
      ),
    ];

    test('Safe profile map excludes all forbidden PII keys', () {
      final safeProfile = PromptContextBuilder.buildSafeProfileMap(profile);

      expect(safeProfile.containsKey('name'), isFalse);
      expect(safeProfile.containsKey('phone'), isFalse);
      expect(safeProfile.containsKey('id'), isFalse);

      final serialized = jsonEncode(safeProfile);
      expect(serialized.contains(sensitiveName), isFalse);
      expect(serialized.contains(sensitivePhone), isFalse);
      expect(serialized.contains(sensitiveId), isFalse);

      // Whitelisted fields must be present
      expect(safeProfile['age'], 20);
      expect(safeProfile['state'], 'Maharashtra');
      expect(safeProfile['occupation'], 'Student');
    });

    test('Safe vault list excludes file paths and document numbers', () {
      final safeVault = PromptContextBuilder.buildSafeVaultList(vault);
      final serialized = jsonEncode(safeVault);

      expect(serialized.contains(sensitiveFilePath), isFalse);
      expect(serialized.contains(sensitiveDocNumber), isFalse);
      expect(serialized.contains('filePath'), isFalse);
      expect(serialized.contains('docNumber'), isFalse);

      expect(safeVault.first['documentType'], 'aadhaar');
      expect(safeVault.first['title'], 'Aadhaar Card');
    });

    test('Full system context string satisfies assertPrivacySafety', () {
      final contextStr = PromptContextBuilder.buildSystemContext(
        profile: profile,
        vault: vault,
      );

      expect(contextStr.contains(sensitiveName), isFalse);
      expect(contextStr.contains(sensitivePhone), isFalse);
      expect(contextStr.contains(sensitiveId), isFalse);
      expect(contextStr.contains(sensitiveFilePath), isFalse);
      expect(contextStr.contains(sensitiveDocNumber), isFalse);
    });
  });
}
