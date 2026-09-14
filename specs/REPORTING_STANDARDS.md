# REPORTING STANDARDS — figures, reports, interpretation

_Applies to every project/stage that produces figures or reports. Launchers reference
this instead of restating it. Keep high-signal._

## Figures
- Save each figure in **PNG + EPS + SVG** (SVG is vector and trivially recolorable).
- **Always save the underlying data as a TSV** next to every figure, same basename
  (e.g. `length_dist.png` → `length_dist.tsv`). This lets plots be regenerated or
  restyled (colors, fonts, size) later WITHOUT recomputing from raw data.
- Figures go in `figures/`, their data tables in `tables/`.

## Intermediate data
Build every figure/section from cached tables in `<stage>/cache/`, never by re-streaming
raw data per section. Note in STATUS.md which cache files exist for later stages.
Caching rules: `specs/WORKING_AGREEMENT.md`.

## Report structure
- `REPORT.md` — findings in readable form.
- `REPORT.html` — self-contained. **Reuse the project's established HTML style** (extract
  it once from the project's existing report template; don't invent a new look per stage).
- `STATUS.md` — what ran, what failed, what's cached, what's pending. Written last.

## Interpretation format (every finding)
1. The finding with the actual number.
2. What it means biologically or methodologically.
3. Implication for the paper or the next stage.
Real numbers. Nature Methods level. Flag surprises with ⚠️.
- **Report failures as prominently as successes.** If a result is weak, null, or
  contradicts the working hypothesis, say so plainly in FINDINGS.md. Never
  quietly drop a failed analysis or reframe a negative result as inconclusive.


## Two-phase reporting (compute, then interpret)
Required for any stage computation from interpretation:
- **Phase A** — compute all sections: numbers, figures, cached tables. No prose conclusions yet.
- **Phase B** — a single interpretation round: read all cached tables together and write the
  three-sentence findings. Seeing all numbers before concluding yields better analysis.
