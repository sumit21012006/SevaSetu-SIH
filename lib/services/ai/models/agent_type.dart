/// Specialized agent types in the SevaSetu AI multi-agent architecture.
enum AgentType {
  recommendation('Scheme Recommendation Agent', 'Recommends matching government schemes based on citizen profile'),
  eligibility('Eligibility Agent', 'Evaluates scheme eligibility deterministically with official citations'),
  guidance('Guidance Agent', 'Provides step-by-step application guidance, documents, and portals'),
  grSimplifier('GR Simplification Agent', 'Translates complex Government Resolutions into plain, actionable language'),
  router('Query Router', 'Routes user intent to the appropriate specialized agent');

  const AgentType(this.displayName, this.description);

  final String displayName;
  final String description;

  static AgentType fromString(String? val) {
    if (val == null) return AgentType.recommendation;
    switch (val.toLowerCase().trim()) {
      case 'recommendation':
      case 'scheme_recommendation':
      case 'schemerecommendation':
        return AgentType.recommendation;
      case 'eligibility':
      case 'eligibility_agent':
        return AgentType.eligibility;
      case 'guidance':
      case 'guidance_agent':
        return AgentType.guidance;
      case 'gr_simplifier':
      case 'grsimplifier':
      case 'simplification':
      case 'gr':
        return AgentType.grSimplifier;
      default:
        return AgentType.recommendation;
    }
  }
}
