# Editorial fact safety

Shared copy must distinguish five classes:

- Confirmed facts: exact organization facts supplied in `intake.json.facts`.
- Approved policies: operator-supplied shipping, returns, guarantee,
  donation-impact, and service-level language.
- Neutral defaults: descriptions of page purpose or product taxonomy that make
  no promise about ownership, fulfillment, impact, timing, or service.
- Draft placeholders: visibly labeled prelaunch text requiring review.
- Prohibited assumptions: guarantees, free-shipping thresholds, production or
  response times, return/refund windows, charitable impact, program names,
  cultural review, ownership/origin claims, or vendors absent from intake.

Agent-authored copy may use confirmed facts and neutral defaults. It must use a
visible draft marker for missing policy language and must never turn a draft
into a factual claim. Launch certification reads rendered pages back and fails
closed on unresolved drafts or prohibited assumptions.
