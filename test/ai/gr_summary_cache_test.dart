import 'package:flutter_test/flutter_test.dart';
import 'package:sevasetu/services/ai/cache/gr_summary_cache.dart';
import 'package:sevasetu/services/ai/models/agent_result.dart';
import 'package:sevasetu/services/ai/models/agent_type.dart';

void main() {
  group('GRSummaryCache Unit Tests', () {
    final cache = GRSummaryCache();
    const grText = 'GOVERNMENT RESOLUTION NO. WCD-2024. All women aged 21-65 eligible.';

    test('Computes deterministic sha256 hash key per text and language', () {
      final key1 = cache.computeKey(grText, 'en');
      final key2 = cache.computeKey(grText, 'en');
      final keyMr = cache.computeKey(grText, 'mr');

      expect(key1, equals(key2));
      expect(key1, isNot(equals(keyMr)));
      expect(key1.length, 64); // SHA-256 hex length
    });

    test('Puts and gets result from in-memory cache', () async {
      final key = cache.computeKey(grText, 'en');
      const testResult = AgentResult(
        agentType: AgentType.grSimplifier,
        summary: 'Cached resolution summary',
      );

      await cache.put(key, testResult);
      final retrieved = await cache.get(key);

      expect(retrieved, isNotNull);
      expect(retrieved!.summary, 'Cached resolution summary');
      expect(retrieved.fromCache, isTrue);
    });
  });
}
