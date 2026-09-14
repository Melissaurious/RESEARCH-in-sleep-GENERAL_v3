# LAUNCHER — [Project]

## Read first
`../RESEARCH-in-sleep-GENERAL_v5/CLAUDE.md`, then `specs/WORKING_AGREEMENT.md`
and `specs/EVIDENCE_STANDARDS.md`. Reporting: `specs/REPORTING_STANDARDS.md`.

## Environment
export PATH=/home/borg/miniconda3/envs/[ENV]/bin:$PATH
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000

## Write boundary
Writable: `ARIS_OUTPUT/<stage>/` ONLY. Everything else read-only, including
prior project versions. Need a derived copy? Copy into `<stage>/cache/`.

## Objective
[One sentence. What this stage produces.]

## Success criterion
[How I will know it's done AND correct — not just "it ran".]

## Out of scope
[What NOT to do. Be explicit — this prevents most drift.]

## Input data
[2–3 specific hardcoded paths, with head/schema if non-obvious]

## Output
`ARIS_OUTPUT/stageX_<slug>/` — layout per master CLAUDE.md § Output layout.

## Compute
Expected: [local GPU 0 | Ibex gpu24 a100 ×1]. Estimated: [X hr].
If the estimate is off by >2×, stop and report.

## Checkpoint
Write PLAN.md and stop for approval before executing.

---
## Stage N — [name]
**Mode:** SINGLE-PASS | LOOPED
**Model:** Opus | Sonnet
**Objective.** [one sentence]
**Success criterion.** [how I know it's done AND correct]
**Stop condition (LOOPED only).** [a statement that can be false, with a number]
**Out of scope.** [explicit]
**Inputs.** [paths]
**Output.** `ARIS_OUTPUT/stageN_<slug>/`
**Compute.** [local GPU 0 | Ibex gpu24 a100 x1] — est. [X] hr. Off by >2x → stop.
**Review.** [which of the seven Codex verdicts gate this stage, if any]