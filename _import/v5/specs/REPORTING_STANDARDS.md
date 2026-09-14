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

## Provenance — mandatory for every artifact
Every file in `tables/` and `figures/` has a sibling `<basename>.prov.json`:

```json
{"artifact": "rt_family_counts.tsv",
 "script": "scripts/03_rt_family_counts.py",
 "git_commit": "5bd1d6a",
 "command": "python scripts/03_rt_family_counts.py --db gtdb_bacteria",
 "inputs": [{"path": "cache/systems_dedup.parquet", "sha256": "...", "n_records": 501561}],
 "params": {"min_len": 150},
 "unit": "per RT protein",
 "denominator": 501561,
 "created": "2026-08-31T14:22:03Z",
 "env": "retron_tradicional", "host": "borg", "runtime_s": 412}
```

An artifact without a valid `.prov.json` is NOT a result. It may not appear in
REPORT.md, FINDINGS.md, the research wiki, or the paper. Tag it `[UNVERIFIED]`
or delete it.

Scripts write artifacts only via `tools/prov.py: write_artifact()`.
`tools/check_prov.py <stage>` runs as the last step of every stage, before
STATUS.md. A stage with orphaned artifacts is not complete.

`unit` and `denominator` are required fields, per EVIDENCE_STANDARDS §8.

`git_commit` is **advisory, not a pin.** Where stages run concurrently against one working
tree it records HEAD at write time while other work is in flight. **The reproducibility pin
is `inputs[].sha256`** — content-addressed, and unaffected by concurrent writes. A stage may
report `DIRTY_ELSEWHERE` warnings from `check_prov.py` and still be complete; what it may not
do is leave its own artifacts unhashed.