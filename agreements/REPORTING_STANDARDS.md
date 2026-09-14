# REPORTING STANDARDS — figures, reports, interpretation

_Applies to every project/stage that produces figures or reports. Launchers reference
this instead of restating it. Keep high-signal._

## Figures
- Save each figure in **PNG + SVG** (SVG is vector and trivially recolorable). Add EPS
  or PDF only when a target venue actually requires it — carrying a third format by
  default is process cost with no reader.
- **Always save the underlying data as a TSV** next to every figure, same basename
  (e.g. `length_dist.png` → `length_dist.tsv`). This lets plots be regenerated or
  restyled (colors, fonts, size) later WITHOUT recomputing from raw data.
- Figures go in `figures/`, their data tables in `tables/`.

## Figures are a view over a landed table

Everything a gate produces may end up in a thesis or a paper, so figures are expected —
but a figure is **a view over a table that already landed**, never a second measurement.

**The rule that makes this safe:** a figure script reads from the bundle's `tables/` and
**nothing else** — never the source data. A script that consumes only landed tables adds
no measurement, so it cannot widen the gate past WA-R.3, and it satisfies the
figure-plus-TSV rule above automatically: the figure's data *is* a landed table.

Consequences worth stating, because each is a way gates go wrong:

- A figure that needs a number no table carries means the **table** is incomplete. Add
  the column to the measuring script and re-run the gate — never compute it in the
  plotting script, where it would land unhashed and unprovenanced.
- A figure spanning several gates' tables is **its own gate**, taking those bundles'
  tables as hashed inputs (BS-2) and emitting `(figure, tsv)` pairs. Its stop condition
  is that `run.sh` regenerates byte-identical TSVs.
- Restyling for a venue re-runs the figure script against unchanged tables. It is never
  a reason to touch a landed bundle (BS-6).

## Intermediate data
Build every figure/section from cached tables in `<stage>/cache/`, never by re-streaming
raw data per section. Note in STATUS.md which cache files exist for later stages.
Caching rules: `agreements/WORKING_AGREEMENT.md`.

## Report structure

**Markdown is the deliverable.** `REPORT.html` is produced only when a launcher asks for it,
and that launcher names the existing report to copy the style from. Generating HTML by
default is a presentation format masquerading as a reporting standard.

- `README.md` in the bundle — the findings. Self-contained: readable without the five gates
  before it.
- `FINDINGS.md` in scratch — the journal, written **during** the session and appended, never
  rewritten, including the entries that turned out wrong. A corrected entry is amended in
  place with both values and the date, superseded text left visible.
- `STATUS.md` — what ran, what failed, what's cached, what's pending. Written last.

## Interpretation format (every finding)
1. **Number.** The actual value, with its unit and denominator.
2. **Means.** What it means biologically or methodologically, prefixed `PROPOSED:` — the
   agent measures and reports; it does not conclude (WA-A.4).
3. **Implication.** For the paper, or the next gate.
4. **Would be wrong if.** The specific thing that would falsify it, and what was done to
   check. **A finding with no falsifier is a description.**
5. Provenance inline: `→ scripts/sNN.py · tables/x.tsv`. A number a reader cannot trace is
   one they must take on faith.

⭐ Rule 4 is the one that turns a report into evidence: writing *"would be wrong if…"* forces
the check while there is still time to run it. A prior stage found a coordinate defect in
another stage's base-pair truth **because a disclaimer was being drafted** — the caveat
written to weaken a result is what found the defect.

Real numbers. Nature Methods level. Flag surprises with ⚠️.

## Two sections that are mandatory and may not be empty

- **What surprised me.** Nothing surprising means either nothing was learned or nothing
  was looked at.
- **What I could NOT check.** The report's own coverage statement — the same rule the
  reviewer is held to. If you could verify everything, you did not understand the gate.
- **Report failures as prominently as successes.** If a result is weak, null, or
  contradicts the working hypothesis, say so plainly in FINDINGS.md. Never
  quietly drop a failed analysis or reframe a negative result as inconclusive.


## Two-phase reporting (compute, then interpret)
Required for any stage computation from interpretation:
- **Phase A** — compute all sections: numbers, figures, cached tables. No prose conclusions yet.
- **Phase B** — a single interpretation round: read all cached tables together and write the
  three-sentence findings. Seeing all numbers before concluding yields better analysis.

## Provenance — carried by the bundle, and only there

There is ONE provenance mechanism in this system: the bundle (`agreements/BUNDLE_SPEC.md`).
A number is provenanced because it entered through `results/<GATE>/` with its scripts
verbatim, its inputs hashed, its environment locked by content, its seed declared and
its command recorded — not because a sidecar file sits next to it.

`unit` and `denominator` are required for every rate (EVIDENCE_STANDARDS §8). They are
required **columns of `MANIFEST.tsv`**, so the bundle already carries them and
`checks/bundle_valid.sh` already enforces them.

**Withdrawn:** earlier versions of this spec mandated a per-artifact
`<basename>.prov.json` written by a `prov.py` helper and swept by a `check_prov.py`.
That was a second provenance system for the same job, and it named two tools this repo
does not contain — a rule pointing at a missing file is silent (WA-P.3), and two
mechanisms for one job is exactly what a single source of agreements is for. See the
graveyard in `agreements/WORKING_AGREEMENT.md`.

Inside scratch, per-artifact sidecars remain a reasonable working habit and a project
may keep them. They are **not evidence**, no rule depends on them, and nothing may cite
them. What makes an artifact citable is the bundle it landed in.
