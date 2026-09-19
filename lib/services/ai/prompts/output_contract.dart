/// Verbatim Output Contract for SevaSetu AI as specified in Section 6.2 of the architecture spec.
class OutputContract {
  static const String text = '''
OUTPUT CONTRACT:
Return ONLY a single valid JSON object with the following schema:
{
  "agent": "scheme_recommendation | eligibility | guidance | gr_simplification | out_of_scope",
  "language": "en | hi | mr",
  "headline": "one short line summarising the answer, max 90 characters",
  "answer": "2-6 short plain sentences, no markdown",
  "points": [ { "type": "ready | warning | problem | info | step", "text": "one short line" } ],
  "recommendations": [ { "service_id": "id from catalog", "reason": "one sentence tying this service to THIS citizen's need and profile" } ],
  "service_ids": [ "ids the answer is about" ],
  "document_ids": [ "ids the answer is about" ],
  "actions": [ "view_service:<service_id>", "check_eligibility:<service_id>", "view_documents:<service_id>", "download_zip:<service_id>", "upload_document:<document_id>", "open_document:<document_id>", "open_gr_guide" ],
  "sources": [ "source_id" ],
  "follow_up_questions": [ "max 3 short questions the citizen may ask next" ],
  "clarifying_question": null,
  "gr_summary": null
}

For GR Simplification Agent only, fill "gr_summary" (otherwise keep it null):
{
  "title": "...",
  "what_it_is": "2 short sentences",
  "who_is_eligible": ["..."],
  "documents_required": [ { "document": "...", "why": "only if the text says why, else empty string" } ],
  "key_dates_and_amounts": [ { "label": "...", "value": "exactly as in the text" } ],
  "what_you_need_to_do": ["numbered-style steps as short lines"],
  "watch_out_for": ["only warnings the text actually contains"],
  "hard_terms": [ { "term": "...", "meaning": "..." } ],
  "not_mentioned": ["items a citizen would expect (deadline, income limit, documents, where to apply) that the text does not state"]
}

Rules:
- Only include "recommendations" for the Scheme Recommendation Agent.
- Include only fields relevant to the agent; unused fields must be empty arrays or null.
- All actions must be from the allowed prefixes: view_service, check_eligibility, view_documents, download_zip, upload_document, open_document, open_gr_guide.
- Do NOT output any markdown ticks (```json) or commentary. Return raw valid JSON.
''';
}
