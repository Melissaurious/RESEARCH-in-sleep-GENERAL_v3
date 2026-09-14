# REPORTING STANDARDS — the journal, the report, the ledger

_Read before producing any figure or report. Markdown is the default and the requirement;
HTML is opt-in, per launcher. A stage's report must be **self-contained**: readable without
reading the five stages before it._

## Four artefacts, four jobs — do not merge them

| file | written | mutability | job |
|---|---|---|---|
| `FINDINGS.md` | **during** the session, as things happen | append-only, **never rewritten** | the journal: what you found, when, what surprised you, what you got wrong |
| `CLAIMS.tsv` | as each claim is settled | append | the ledger: every claim, its number, its evidentiary standing |
| `REPORT.md` | at the end, assembled | rewritten freely until promoted | the deliverable a human reads |
| `STATUS.md` | **last** | overwritten each run | machine state: what ran, what failed, what's cached, what's pending |

`FINDINGS.md` is the audit trail and is never tidied — including the entries that turned
out to be wrong. A corrected entry is **amended in place with both values and the date**,
with the superseded text left visible. Silent correction destroys the trail that makes
everything else trustworthy.

---

## REPORT.md — the structure

The order is deliberate: the answer first, the evidence for it second, the reasons to
doubt it third. A report that buries its caveats has not reported them.

```markdown
# <STAGE_ID> — <the answer, in one line>

## Answer                  ← one screen, no more
The question. The answer. The number. The one caveat that would change it.
If a reader stops here, they should not be misled.

## Claims ledger           ← table, mirrors CLAIMS.tsv

## Findings                ← one block per finding
### <finding>
**Number.** The actual value, with its unit and denominator.
**Means.** What it means biologically or methodologically.
**Implication.** For the paper, or for the next stage.
**Would be wrong if.** The specific thing that would falsify it — and what you did
to check. A finding with no falsifier is a description.
→ `scripts/sNN_x.py` · `tables/x.tsv` · `figures/x.png`

## Negative & null results   ← its own section. Never a footnote, never softened.

## What surprised me         ← mandatory, and may not be empty

## What I could NOT check    ← mandatory, and may not be empty
The report's own coverage statement. Same rule as the reviewer's: if you could verify
everything, you did not understand the stage.

## Reproduce
`bash REPRODUCE.sh --quick`   (and what the full run costs)

## Provenance
Env, machine, inputs + checksums, wall time, date.
```

### Rules that make it enriching rather than decorative

- **Every number carries its provenance inline** — the script and the table that produced
  it, on the same line. A number a reader cannot trace is a number they must take on
  faith, and this project does not run on faith.
- **Every number carries its unit and denominator.** "42%" of what, over how many.
- **Every finding carries its own falsifier.** This is the single change that turns a
  report into evidence. Writing *"would be wrong if…"* forces the check while there is
  still time to run it — the 2026-08-25 retro found a coordinate defect in another stage
  precisely because a disclaimer was being drafted. ⚠️ **The caveat written to weaken a
  result is what found the defect.**
- **"What surprised me" may not be empty.** Nothing surprising means either nothing was
  learned or nothing was looked at.
- **Negative and null results get a section, not a sentence.** Never quietly dropped,
  never reframed as "inconclusive". A stage that closes as a negative is a finished
  stage, not a failed one.
- **Real numbers, Nature Methods level.** Flag surprises with ⚠️. No "approximately" on
  a value that was computed exactly, and no exact-sounding statement of a rounded one —
  *assert the identity, not the round number that resembles it.*

---

## CLAIMS.tsv — the ledger

One row per claim the stage makes. Tiny — usually 3–10 rows — and it accumulates across
stages into the project's evidentiary record. It is what makes `EVIDENCE_STANDARDS.md`
operational in the report instead of only in the reviewer's head.

```
claim	value	unit_denominator	scope	circularity	independence	falsifier	status
```

| column | meaning |
|---|---|
| `claim` | one sentence, scoped to what was actually examined |
| `value` | the number, exact |
| `unit_denominator` | of what, over how many |
| `scope` | what was audited — "no X in the Y chain", never "no X" |
| `circularity` | `NONE`/`LOW`/`MEDIUM`/`HIGH` (`EVIDENCE_STANDARDS` §3) |
| `independence` | which methods agree, and their computed independence (§4) |
| `falsifier` | what result would refute this |
| `status` | `SUPPORTED` · `REFUTED` · `UNDECIDED` · `SUPERSEDED` |

A claim may be promoted to the paper only from a `SUPPORTED` row whose `circularity` is
`NONE` or `LOW`. `SUPERSEDED` rows stay in the file with the date and the superseding row.

---

## Figures

- Save each figure in **PNG + SVG + EPS** (SVG is vector and trivially recolorable).
- **Always save the underlying data as a TSV** next to it, same basename —
  `length_dist.png` → `length_dist.tsv`. This lets a plot be regenerated or restyled
  later **without recomputing from raw data**, and it is what lets a reviewer check the
  figure against its numbers. `promote_stage.py` refuses a figure with no TSV.
- Figures go in `figures/`, their data in `tables/`.

## Intermediate data

Build every figure and section from cached tables in `<STAGE_ID>/cache/`, never by
re-streaming raw data per section. Note in `STATUS.md` which cache files later stages can
use. Caching rules: `WORKING_AGREEMENT.md`.

## Two-phase reporting — compute, then interpret

Required for every stage:

- **Phase A** — compute all sections: numbers, figures, cached tables. **No prose
  conclusions yet.**
- **Phase B** — a single interpretation round: read all cached tables *together*, then
  write the findings. Seeing every number before concluding yields better analysis than
  concluding section by section, and it is the only way to notice that two sections
  disagree.

## REPORT.html — opt-in only

Markdown is the deliverable. Produce `REPORT.html` **only when the launcher asks for it**,
and when it does, the launcher names the existing report to copy the style from. Do not
invent a look per stage, and do not generate HTML by default — it is a presentation
format for a specific audience, not a reporting standard.
