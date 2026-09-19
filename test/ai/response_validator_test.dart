import 'package:flutter_test/flutter_test.dart';
import 'package:sevasetu/data/seed_services.dart';
import 'package:sevasetu/services/ai/models/agent_type.dart';
import 'package:sevasetu/services/ai/models/ai_source.dart';
import 'package:sevasetu/services/ai/validation/response_validator.dart';

void main() {
  group('ResponseValidator Unit Tests', () {
    const validator = ResponseValidator();
    final catalog = buildSeedServices();
    final sources = [
      const AISource(id: 'src-test-1', title: 'Test 1', authority: 'Govt'),
    ];

    test('Strips markdown code fences and parses JSON object', () async {
      const raw = '''
Here is your answer:
```json
{
  "agent": "scheme_recommendation",
  "headline": "Scholarship Available",
  "answer": "You can apply for Post-Matric Scholarship.",
  "recommendations": [{"service_id": "svc-pms", "reason": "Fits profile"}],
  "points": [{"text": "Point 1"}, {"text": "Point 2"}],
  "actions": ["view_service:svc-pms"]
}
```
Hope this helps!
''';

      final result = await validator.validateAndParse(
        rawInput: raw,
        agentType: AgentType.recommendation,
        catalog: catalog,
        vault: [],
        sources: sources,
      );

      expect(result.agentType, AgentType.recommendation);
      expect(result.summary, 'You can apply for Post-Matric Scholarship.');
      expect(result.recommendedServiceIds, contains('svc-pms'));
      expect(result.steps.length, 2);
      expect(result.nextActions, contains('view_service:svc-pms'));
    });

    test('Drops unknown service IDs and invalid actions', () async {
      const raw = '''
{
  "agent": "guidance",
  "headline": "Guidance",
  "answer": "Guidance text",
  "recommendations": [{"service_id": "non-existent-fake-id", "reason": "fake"}],
  "actions": ["malicious_action:hack", "view_service:svc-pms", "unknown:test"],
  "sources": ["fake-source-id"]
}
''';

      final result = await validator.validateAndParse(
        rawInput: raw,
        agentType: AgentType.guidance,
        catalog: catalog,
        vault: [],
        sources: sources,
      );

      expect(result.recommendedServiceIds.contains('non-existent-fake-id'), isFalse);
      expect(result.nextActions.contains('malicious_action:hack'), isFalse);
      expect(result.nextActions.contains('view_service:svc-pms'), isTrue);
      expect(result.sources.isEmpty, isTrue); // fake-source-id dropped
    });

    test('Truncates list lengths according to contract limits (points <= 6)', () async {
      final points = List.generate(10, (i) => {'text': 'Point $i'});
      final raw = {
        'agent': 'eligibility',
        'headline': 'Eligible',
        'answer': 'Details',
        'points': points,
      };

      final result = await validator.validateAndParse(
        rawInput: raw,
        agentType: AgentType.eligibility,
        catalog: catalog,
        vault: [],
        sources: sources,
      );

      expect(result.steps.length, 6);
    });
  });
}
