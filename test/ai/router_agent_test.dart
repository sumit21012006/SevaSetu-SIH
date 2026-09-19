import 'package:flutter_test/flutter_test.dart';
import 'package:sevasetu/data/seed_services.dart';
import 'package:sevasetu/services/ai/agents/router_agent.dart';
import 'package:sevasetu/services/ai/groq_client.dart';
import 'package:sevasetu/services/ai/models/agent_type.dart';

void main() {
  group('RouterAgent Keyword Fallback Tests', () {
    final catalog = buildSeedServices();
    final router = RouterAgent(
      groqClient: GroqClient(),
      catalog: catalog,
    );

    test('Routes scheme search queries correctly in English, Hindi & Marathi', () {
      final q1 = router.fallbackKeywordRoute('I need a college scholarship');
      expect(q1.agentType, AgentType.recommendation);

      final q2 = router.fallbackKeywordRoute('माझ्यासाठी कोणती शासकीय योजना उपलब्ध आहे');
      expect(q2.agentType, AgentType.recommendation);
    });

    test('Routes eligibility queries correctly', () {
      final q1 = router.fallbackKeywordRoute('Am I eligible for this service?');
      expect(q1.agentType, AgentType.eligibility);

      final q2 = router.fallbackKeywordRoute('मी या योजनेसाठी पात्र आहे का?');
      expect(q2.agentType, AgentType.eligibility);
    });

    test('Routes document and guidance queries correctly', () {
      final q1 = router.fallbackKeywordRoute('What documents are required to apply?');
      expect(q1.agentType, AgentType.guidance);

      final q2 = router.fallbackKeywordRoute('मला कोणती कागदपत्रे लागतील?');
      expect(q2.agentType, AgentType.guidance);
    });

    test('Routes Government Resolution (GR) queries correctly', () {
      final q1 = router.fallbackKeywordRoute('Can you explain this GR to me?');
      expect(q1.agentType, AgentType.grSimplifier);

      final q2 = router.fallbackKeywordRoute('हा नवीन शासन निर्णय समजवून सांगा');
      expect(q2.agentType, AgentType.grSimplifier);
    });
  });
}
