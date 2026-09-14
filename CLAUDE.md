# CLAUDE.md — MASTER (RESEARCH-in-sleep-GENERAL)
Shared context for all sleep-research projects. Each sub-project has its own short
`CLAUDE.md` declaring env + root + active task, pointing back here for mechanics.

## ⚠️ File safety (always)
- Never modify source data or original scripts.
- All work goes to `ARIS_OUTPUT/<STAGE_ID>/`. **Work dirty there — that is the instruction.**
- Only `tools/promote_stage.py` writes to `results/`. Never hand-edit inside it.
- Never `git add` `ARIS_OUTPUT/`. `results/` is committed **by Melissa, by hand, at the end.**
- Never install into the base conda environment.

## Read before acting
MUST read at session start:
- `specs/ANCHORS.md` — where everything lives. Never hardcode a path; use these names.
- `specs/WORKING_AGREEMENT.md` — how to edit, debug, size, verify
- `specs/EVIDENCE_STANDARDS.md` — whether a number means what it appears to mean
- `specs/ADVERSARIAL_REVIEW.md` — the two gates you must pass
Read when the situation applies:
- `specs/PROMOTION_STANDARDS.md` — before closing a stage
- `specs/REPORTING_STANDARDS.md` — before producing any figure or report
- `specs/TOOLING.md` — before installing anything or changing models
- `templates/slurm_templates.md` — before writing any sbatch script
- `compute/resources.md` — before deciding local vs Ibex

## The loop — every stage, no exceptions
| # | Phase | Artefact | Gate |
|---|---|---|---|
| 1 | Plan | `ARIS_OUTPUT/<STAGE_ID>/PLAN.md` | — |
| 2 | **Attack the plan** (codex) | `review-stage/01_plan_review.md` | `BLOCKER` ⇒ no execution |
| — | Approval | Melissa | **stop and wait** |
| 3 | Execute | Phase A compute → Phase B interpret | — |
| 4 | **Attack the result** (codex) | `review-stage/02_result_review.md` | `BLOCKER` ⇒ no promotion |
| 5 | Promote | `results/<STAGE_ID>/` | verdict + clean rerun |
| 6 | Retro | `retros/YYYY-MM-DD_<STAGE_ID>.md` + the spec PR | stage not closed without it |

Findings are dispositioned in writing: `FIXED` (diff + proof), `REFUTED` (**a command and
its output, never an argument**), `ACCEPTED_RISK` (Melissa only — never self-granted).

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
Before any task >30 min: write `<stage>/PLAN.md` (goal, success criterion, steps, files
touched, compute estimate, risks) and stop for approval.
On completion: append to `<stage>/FINDINGS.md` — what was done, what was found, what
surprised you, what you'd do differently. Append only; never rewrite history.

## Output layout — two directories, two jobs
**Workshop** — `ARIS_OUTPUT/<STAGE_ID>/`: PLAN.md, FINDINGS.md, CLAIMS.tsv, REPORT.md,
STATUS.md, plus `scripts/`, `figures/`, `tables/`, `cache/`, `review-stage/`. Scratch,
dead ends and failed attempts belong here and are never tidied away — the mess is the
audit trail. Gitignored.

**Shipped** — `results/<STAGE_ID>/`, same subfolder name: README.md, REPORT.md,
CLAIMS.tsv, REPRODUCE.sh, PROVENANCE.md, MANIFEST.tsv, `scripts/`, `figures/`, `tables/`.
A clean documented copy that reruns from a fresh checkout. Committed manually, at the end.

Four reporting artefacts, four jobs — never merged (`specs/REPORTING_STANDARDS.md`):
`FINDINGS.md` the journal, written **during** and appended, never rewritten · `CLAIMS.tsv`
the ledger, one row per claim with its circularity and falsifier · `REPORT.md` the
deliverable, assembled at the end · `STATUS.md` machine state, overwritten, written last.
**Markdown is the deliverable; `REPORT.html` only when the launcher asks for it.**

One outdir per stage. Never invent a different structure or a parallel top-level output dir.
→ `specs/PROMOTION_STANDARDS.md`

## Launchers
Every stage starts from `$PROJ/launchers/LAUNCHER_<STAGE_ID>.md`, built from
`specs/LAUNCHER_TEMPLATE.md` and validated by `tools/check_launcher.py`. Part A is
Melissa's alone — objective, falsifier, scope, inputs, budget, gate. If a Part A field is
unfilled, **stop and ask**; do not infer it. Part B is inherited from this repo and is
never restated in a launcher.

## Compute
→ `compute/resources.md` — borg + Ibex hardware, partitions, QOS, paths, conda envs,
  and the Active Projects table (single source of truth for what runs where).
→ `templates/slurm_templates.md` — SLURM patterns; `templates/ibex_header.sh` — header.
`--account=pi-hohndor` required on every Ibex job.
Refresh live state: `bash compute/refresh_resources_remote.sh` (from borg).