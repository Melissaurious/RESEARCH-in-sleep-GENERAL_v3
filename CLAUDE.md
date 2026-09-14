# CLAUDE.md — GENERAL v7, the governance layer

Rules, checks and templates. **No science happens here, and no workflow either.**
A project consumes this as a submodule at `general/` and pins it by sha.

## ARIS owns the workflow. This layer constrains how it works.

**ARIS owns** the lifecycle — idea → contract → experiment plan → implementation →
execution → review → claims → paper — together with its artifacts (`.aris/`,
`idea-stage/`, `research-wiki/`, `paper/`, `EXPERIMENT_PLAN.md`, `EXPERIMENT_LOG.md`,
`findings.md`), its loops and round budgets, and its reviewer routing
(ARIS's `review_gate.py`, `/auto-review-loop`). Do not build a second one.

**This layer owns** data safety · evidence standards · provenance · reporting quality ·
Ibex execution policy · which decisions are reserved for the operator.

`AUTO_PROCEED = true` is `/research-pipeline`'s default and this project relies on it:
every selection checkpoint is informational — report the choice and continue.

## Read before acting

Always — **§1 of** `agreements/WORKING_AGREEMENT.md`: five rules, and stop there.

When the situation applies:
- `agreements/WORKING_AGREEMENT.md` §2 — the WHEN rules, each in its own situation
- `agreements/EVIDENCE_STANDARDS.md` — before grading a claim, designing a control, reporting a rate
- `agreements/BUNDLE_SPEC.md` — before packaging a number as evidence
- `agreements/REPORTING_STANDARDS.md` — before any figure or report
- `agreements/LAUNCHER_SPEC.md` — before starting a track
- `site/COMPUTE.md`, `site/IBEX.md` — before sizing or submitting a job
- `site/TOOLING.md` — before installing anything or changing models

## The one place this layer intervenes in execution

**Ibex.** ARIS's `/run-experiment` and `/experiment-queue` target local, vast and modal
hosts and use SSH + `screen`; neither speaks SLURM. On this installation every cluster job
routes to `/run-experiment-ibex` instead — see `skills/experiment-routing-ibex/SKILL.md`.
⛔ `/experiment-queue` must never touch Ibex.

## File safety

- Never modify source data or original scripts (WA-D.1). Enforced by file mode.
- Scratch to `ARIS_OUTPUT/` — gitignored, disposable, messy by design.
- Numbers are packaged into `results/<GATE>/` per `BUNDLE_SPEC.md`. ARIS's own artifacts
  live where ARIS puts them; this layer does not relocate them.
- Never install into the base conda environment.

## Measure, do not conclude

Report counts, including the ugly ones. An interpretation lands as `PROPOSED:` and becomes
the operator's by reading it — it never blocks the pipeline (WA-A.4).

A `REPRODUCIBLE` bundle is enough for ARIS to continue on, unattended. The operator's
input audit (`human_input_audit`) is required only before a number becomes a paper or
thesis claim.

## Before any negative or absence claim

A count of zero needs a positive control showing the same code returns non-zero on a case
known to be present (`EVIDENCE_STANDARDS` §6). Every measurement supplies its own.

## When blocked

Never guess silently and never stall (WA-S.1). Append to `docs/BLOCKED.md`: what is needed,
why, the options, your recommended default. **LOW-STAKES** — reversible, contained, inside
the declared compute budget, inside scratch: take the default, log it, **continue**.
**HIGH-STAKES** — ground truth, the scientific question, a frozen criterion, exceeding the
budget, promoting an interpretation to a paper claim, anything leaving this machine: stop.

## Amending this layer

A session may **propose**, never amend. A proposal names the case it would have caught
**and** a case it would wrongly reject. Removed rules go to the graveyard in `LINEAGE.md`.

    bash general/tools/general_sha.sh       # the revision a bundle records
    bash general/checks/specs_exist.sh      # must print OK
    bash general/checks/rules_current.sh    # EXPIRED / DUE / PROVISIONAL
