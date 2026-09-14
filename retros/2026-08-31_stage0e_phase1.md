# Retro — 2026-08-31 · Stage 0e Phase 1 (evidence dossier for V4's proposed paper)

**Mode:** LOOPED · **Elapsed ≈ 3 h** against a 6–10 h estimate · 423 claims, all gates green.

## What worked

**Declaring the decomposition rule before reading the material, then reporting the deviation
when it changed.** `R1`–`R5` were fixed in PLAN.md §2. On contact with the paper, `R1` (one
claim per results-table row) produced ~320 rows that were mostly one stratum of one
distribution. Narrowing it to `R1'` was a rule change made *after* seeing the data — exactly
what `EVIDENCE_STANDARDS` §5 warns about — so it is recorded as deviation 1 with both counts,
and the full per-row superset stays on disk in `cache/candidates.tsv`. The plan having
anticipated this is what made it a recorded deviation rather than a silent one.

**Writing the verifier before finishing the first section.** `05_verify.py` re-reads the
manuscript and asserts each `statement` is still at its recorded line. It caught, on §2
alone, that hand-recorded line numbers had drifted on **81 of 81 rows**, that four
table-derived statements had silently **dropped a column**, and that four others crossed a
paragraph boundary. Had it been written at round 14 as planned, eight sections' worth of that
would have needed redoing.

**Quoting by anchor, not by line range** (`scripts/quote.py`). The first §5 attempt used
hand-guessed line ranges and produced 14 statements that were verbatim nowhere. Locating a
paragraph by a distinctive substring the author has actually read makes the statement a real
span of the file by construction, and the failure mode becomes a loud `KeyError` instead of a
quiet paraphrase.

**Checking the inventory rather than trusting it.** `V4_INVENTORY.tsv` says
`d1f_dyad_control.tsv` was produced by `d1d2_block_mechanism.py`. It was not — three
D_instrument tables sampled by hand all resolved to a script that merely *names* the file.
Writing `08_producer.py` to rank candidates by whether the mention sits on a **write line**
turned a hunch into a measurement: 180 agreements, 32 disagreements, 26 of them in the one
stage with no header-comment provenance. §6 OPEN 8 turned out to record the same defect class
from inside V4, which is corroboration the dossier could not have manufactured.

## What I misunderstood

**I asserted counts from memory in FINDINGS.md and had to correct them twice.** The round-5
column distribution was typed from recall; computing it gave different numbers in six of nine
rows. Later, the nine reciprocal section pairs in the dependency map were listed from memory
and three of nine were wrong. **Fix, now folded into the stage: every number in a deliverable
comes from a script.** `07_counts.py` and `11_structure.py` exist because of this, and the
FINDINGS text now says "emitted by `scripts/07_counts.py`, not typed."

**I under-estimated how much of the paper's evidence is prose.** The plan assumed citations
would resolve to tables. The manuscript names 42 distinct paths, of which **7 are `tables/*.tsv`**;
everything else is a stage directory, a `FINDINGS.md`, a `PREREG`, or a review document. The
number-grep tier had to carry most of the resolution, and it needed two fixes discovered only
by use — one grep per root instead of one per token (a 2-minute timeout on `D_instrument`),
and folding `51.52%`/`51.52` and `44,983`/`44983` onto the token the paper actually wrote.

**The two `FROZEN_DENOMINATORS.tsv` paths the launcher seals are one file.** One is a symlink
to the other. A path-level exclusion would have treated them as two and could have been routed
around; the realpath rule collapses them. Worth carrying forward as the default for any seal.

## What to fix next time

- **Write the counting script with the first deliverable, not the last.** Two rounds of
  corrected numbers is two rounds too many for a stage whose product is counts.
- **`cd` explicitly in every shell call.** The working directory reset between calls several
  times mid-stage, silently writing a heredoc to the wrong path twice and costing a re-paste
  of a ~10k-token authoring file. Saving authoring data to `cache/authoring/*.py` before
  executing it — which I started doing at §5 — made every later section cheap to re-run.
- **`06_repair_lines.py` was non-idempotent for two revisions** because it returned the first
  line of whatever *window* contained a fragment rather than the line the fragment *starts*
  on. Building the haystack with a collapsed-string offset table fixed it. The general lesson:
  a locator that is not idempotent is not a locator, and the cheapest test is to run it twice.

## For the working agreement

**A verifier for the stage's own product belongs in the same round as the first product, not
in the last.** `EVIDENCE_STANDARDS` §1 says to validate the artefact rather than its
existence; this stage is the case where the artefact is *text this session wrote about
someone else's text*, and the only content check that means anything is "is it still there,
verbatim, where I said it was". That check found a real defect in every one of its first four
runs. Proposed for `WORKING_AGREEMENT.md` § Workflow, beside "Verify before claiming done".
