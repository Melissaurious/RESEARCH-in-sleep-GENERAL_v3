# Session Retros

One file per stage: `YYYY-MM-DD_<STAGE_ID>.md`. **A stage is not closed without one.**

Capture: what worked · what Claude misunderstood · what surprised you · what it cost ·
what you would do differently · which rules to fold into `specs/`.

## The promotion rule

⚠️ **A rule named in a retro but not landed in a spec does not exist.**

`2026-08-25_ncrna_representation_probes.md` closed with six rules marked "to fold into
`specs/`" — and for weeks, none of them were in `WORKING_AGREEMENT.md`. Naming a lesson is
not learning it.

So: folding is **part of** the retro, in the same session, not a follow-up to it.

1. Write the retro here.
2. Open the PR against this repo applying the rules to `specs/`.
3. Each promoted rule keeps its origin — *"earned by X on YYYY-MM-DD"* — so a future
   reader can tell a rule that cost something from a rule that sounded prudent.

Every rule in `specs/EVIDENCE_STANDARDS.md` exists because its absence produced a wrong or
unfalsifiable number in real work. Keep it that way: do not add rules that merely sound
sensible, and do not delete one without saying which failure it no longer prevents.
