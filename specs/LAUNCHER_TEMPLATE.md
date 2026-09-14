# [Project] — Stage X Launcher

## Read first
`../RESEARCH-in-sleep-GENERAL_v3/CLAUDE.md`, then `specs/WORKING_AGREEMENT.md`.
Reporting: `specs/REPORTING_STANDARDS.md`. Do not proceed without reading these.

## Environment
export PATH=/home/borg/miniconda3/envs/[ENV_NAME]/bin:$PATH
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000

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