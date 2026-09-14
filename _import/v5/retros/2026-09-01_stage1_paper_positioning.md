# Retro — 2026-09-01 · stage1_paper_positioning (RETRON-DB_V5)

## What worked

**The verdict-document read the coordinator gated on.** Reading `x1_neighbourhood/VERDICT.md`,
the `rt0_rt7_claim_ledger`, and V3's `METHOD_AUDIT_VS_MESTRE.md` *before* pricing anything
changed four ledger rows and prevented two whole categories of error: pricing a settled question
as open (C14 — Mestre's types are effector-defined, stated in his own Table 1) and pricing a
dead modality as live (C8/C13 — the neighbourhood was graded DEAD at a pre-registered band).
**Two hours of reading moved more than any measurement in the stage.**

**Probe controls that fire.** Every §4 negative carried a paired assertion that had to succeed
for the negative to mean anything. All four fired on the §4.3 probe, which is why its "Infernal
never appears" is a result rather than a guess.

**The gate did its job by failing.** Round 1's `FAIL` was correct and found something real.

## What I misunderstood

**I wrote a contradiction into my own documents while being careful.** I recorded the
extraction-comparability caveat honestly, wrote "the claim must not be made until it is
verified", and then — one section away — called that leg "the strongest" and made its row
HEADLINE. **Disclosure sat next to the claim the disclosure forbade, and I did not see it.** The
adjudicator's sentence is the lesson: *"mere limitation disclosure should not coexist with 'the
claim may not be made'."* **A caveat is not a mitigation.**

**My controls tested that the parser RAN, not that it MATCHED.** Two probes returned clean,
plausible zeros for reasons that had nothing to do with the data: a UTF-8 BOM on a column name,
and a UniProt-vs-PATRIC namespace mismatch. **Neither of my declared controls would have caught
either.** They were caught only because the probes happened to print their column lists and
sample identifiers.

**I scoped a negative to `/home/borg` and stated it about "on disk".** "No full Pfam-A exists"
was false — it was on Ibex. This is the fourth instance of this failure in this project, and I
committed it inside the PLAN whose own §2 promised not to.

## To fix — promote into the specs

1. **A control must test the MATCH, not the RUN.** "The parser found records" is nearly
   worthless. The control is: *the parser found the specific record I hand-verified, via the key
   I claim to be using.* → EVIDENCE_STANDARDS §6.
2. **Lint a document against its own stated rules before any external review.** If a document
   says "a leg whose input is unverified is a candidate leg", a five-line script should check
   every leg's input grade against its stated force. **The reviewer should not be the first
   reader to hold the document to its own rules.**
3. **Every negative states its search scope AND its claim scope, and they must match.**
   The scope must name every root swept (V3/V4/V5) and every machine (borg/Ibex). Four instances
   in one project is a pattern, not bad luck.
4. **When a conditional is load-bearing, state the conjunction explicitly.** Round 2's entire
   attack was the misreading that "negative Δ" alone was fatal, when the disclosed contingency
   was "negative Δ AND empty C13". One sentence removed it.

## Cost

Well under the 4–8 h estimate. The gate cost 4 codex calls (~5 min wall). The most expensive
thing was reading ~5,000 lines of V3/V4 verdict documents, and it was the highest-return.
