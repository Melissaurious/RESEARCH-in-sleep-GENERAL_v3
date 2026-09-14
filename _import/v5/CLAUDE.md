# CLAUDE.md — MASTER (RESEARCH-in-sleep-GENERAL)
Shared context for all sleep-research projects. Each sub-project has its own short
`CLAUDE.md` declaring env + root + active task, pointing back here for mechanics.

## ⚠️ File safety (always)
- Never modify source data or original scripts.
- All outputs go to `ARIS_OUTPUT/` subdirectories.
- Never install into the base conda environment.

## Read before acting
MUST read at session start:
- `specs/WORKING_AGREEMENT.md`
- `specs/EVIDENCE_STANDARDS.md`
Read when the situation applies:
- `specs/REPORTING_STANDARDS.md` — before producing any figure or report
- `specs/TOOLING.md` — before installing anything or changing models
- `templates/slurm_templates.md` — before writing any sbatch script
- `compute/resources.md` — before deciding local vs Ibex

## When blocked or uncertain
Never guess silently and never stall waiting for me.
1. Append the question to `ARIS_OUTPUT/BLOCKED.md`, timestamped: what you need, why,
   the options, and your recommended default.
2. LOW-STAKES (reversible, contained, no compute >10 min, nothing written outside
   ARIS_OUTPUT): take your recommended default, log it, continue.
3. HIGH-STAKES (deleting/overwriting anything, >100 GPU-min, changing an agreed spec,
   publishing results, anything ambiguous about scientific interpretation): stop and wait.
Scientific-interpretation calls are always mine, never yours.

## Checkpoints
SINGLE-PASS stages: before any task >30 min, write `<stage>/PLAN.md` (goal, success
criterion, steps, files touched, compute estimate, risks) and stop for approval.
LOOPED stages: write PLAN.md and stop for approval on the PLAN, then run to the
declared stop condition without further gates. Append each round to FINDINGS.md.
Mode is declared in the launcher; undeclared means SINGLE-PASS.
On completion: append to `<stage>/FINDINGS.md` — what was done, what was found, what
surprised you, what you'd do differently. Append only; never rewrite history.

## Output layout
One directory per stage: `ARIS_OUTPUT/stage<N>_<slug>/` containing PLAN.md, STATUS.md,
FINDINGS.md, plus `scripts/`, `figures/`, `tables/`, `cache/`, `review-stage/` as needed.
Reports as REPORT.md (+ REPORT.html). STATUS.md is overwritten; FINDINGS.md is appended.
Never invent a different structure or a parallel top-level output dir.
`research-wiki/` is project-level, not per-stage: papers, claims, experiments, ideas.

## Compute
→ `compute/resources.md` — borg + Ibex hardware, partitions, QOS, paths, conda envs,
  and the Active Projects table (single source of truth for what runs where).
→ `templates/slurm_templates.md` — SLURM patterns; `templates/ibex_header.sh` — header.
`--account=pi-hohndor` required on every Ibex job.
Refresh live state: `bash compute/refresh_resources_remote.sh` (from borg).