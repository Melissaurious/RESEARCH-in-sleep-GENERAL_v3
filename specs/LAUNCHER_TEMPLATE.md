# LAUNCHER — [STAGE_ID]

> Copy to `$PROJ/launchers/LAUNCHER_<STAGE_ID>.md`, fill **every** field in Part A,
> then run `python "$RSG/tools/check_launcher.py" <path>` before pasting anything.
> An unfilled field is a blocker, not a default. There are no optional fields.

---

# PART A — only Melissa can supply this

_Nine of the ten worst stage failures start here, not in the code. Everything below is a
judgement the agent is not positioned to make. If a field is genuinely unknown, that is
the first thing to resolve — not a reason to start._

## STAGE_ID
`[stageN_slug]`  ← lowercase, `^stage[0-9]+_[a-z0-9_]+$`. One outdir per stage, this exact
name on both sides of the promotion (`ANCHORS.md` §3).

## Project
- Root: `[$HOME/RESEARCH-in-sleep-XXX/]`
- Conda env: `[env_name]` (never `base`)
- Machine: `[borg GPU 0 | borg GPU 1 | Ibex]`

## Objective
`[One sentence. What this stage produces — the artefact, not the aspiration.]`

## The question, stated so it can fail
`[What am I actually asking? And: what result would make me abandon this line?]`

⚠️ **This field is the whole point of the launcher.** `EVIDENCE_STANDARDS.md` §6: if
nothing could have returned a negative, the stage is a description, not a test. Writing
the falsifier **now**, before any number exists, is the only moment it is honest — and it
is yours alone. The agent cannot pre-register a hypothesis on your behalf.

## Success criterion
`[How I will know it is done AND correct — not "it ran", not "the file exists".]`

## Out of scope
`[What NOT to do. Be explicit and be generous — this prevents most drift.]`

Anything not listed here that the agent thinks is needed comes back as a question, not as
extra work. Scope discovered *after* a review finding is not out of scope.

## Inputs (read-only)
| Path | What it is | Schema known? |
|---|---|---|
| `[/abs/path]` | `[…]` | `[no — probe it]` |

⛔ These are never modified. **Treat any `input_format.md` as a hypothesis about the data,
not ground truth** — stage 1 found a lineage string filed under `ecosystem`, a "direction"
field 97.7% null and not a direction, and a structurally-always-false clip flag, all by
probing real values.

## What might already exist
`[Prior stages, artefacts on disk, scripts in MELISSA_SCRIPTS/ that may already answer
part of this. Say where to look, and say what would make them untrustworthy.]`

⚠️ **Absence is loud; wrongness is quiet.** B4 was recorded as "never started" and had in
fact been run with a pre-registered bar. B3's embeddings were on disk — 21.4 GB, computed
on unoriented sequence. Both read as ready. **Look for the artefact before building it,
and grade it before using it.**

## Compute budget
- Expected: `[local GPU 0 | Ibex gpu24 a100 ×1]`, estimated `[X]` hr, `[Y]` GPU-hours.
- ⛔ **Hard stop at `[2]`× the estimate.** Report, do not push through.
- Ibex jobs require `--account=pi-hohndor`. Size from a measured smoke test, never a guess
  (`WORKING_AGREEMENT.md` § Workflow).

## Gate — what I check before you execute
`[What I will look at in PLAN.md + the pass-1 review before approving. Name it, so the
plan is written to be checkable.]`

## Promotion — what must land in `results/<STAGE_ID>/`
`[The figures, tables and claims this stage owes the paper. If a negative, say so — a
negative promotes with the same care as a positive.]`

---

# PART B — inherited. Do not restate, do not paraphrase.

Read, in this order. Do not proceed without them.

1. `$RSG/CLAUDE.md` — master context and the four-phase loop
2. `$RSG/specs/WORKING_AGREEMENT.md` — how to edit, debug, size, verify
3. `$RSG/specs/EVIDENCE_STANDARDS.md` — whether a number means what it appears to
4. `$RSG/specs/ADVERSARIAL_REVIEW.md` — the two gates
5. `$RSG/specs/PROMOTION_STANDARDS.md` — workshop vs shipped record
6. `$RSG/specs/REPORTING_STANDARDS.md` — figures, report, interpretation

Compute: `$RSG/compute/resources.md` · SLURM: `$RSG/templates/slurm_templates.md`
Paths: `$RSG/specs/ANCHORS.md` · Tooling: `$RSG/specs/TOOLING.md`

## The loop you will follow

| # | Phase | Artefact | Gate |
|---|---|---|---|
| 1 | Plan | `ARIS_OUTPUT/<STAGE_ID>/PLAN.md` | — |
| 2 | **Attack the plan** | `review-stage/01_plan_review.md` | `BLOCKER` ⇒ no execution |
| — | Approval | Melissa | **stop here and wait** |
| 3 | Execute | Phase A compute, then Phase B interpret | — |
| 4 | **Attack the result** | `review-stage/02_result_review.md` | `BLOCKER` ⇒ no promotion |
| 5 | Promote | `results/<STAGE_ID>/` via `promote_stage.py` | verdict + rerun |
| 6 | Retro | `$RSG/retros/YYYY-MM-DD_<STAGE_ID>.md` | stage is not closed without it |

Write `STATUS.md` last. Then **stop. Do not loop.**

## Session setup

```bash
export RSG="$HOME/RESEARCH-in-sleep-GENERAL_v3"
[ -f "$RSG/specs/ANCHORS.md" ] || { echo "RSG is wrong: $RSG"; return 1; }
cd "[$PROJ]" && conda activate "[env_name]"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000
claude --dangerously-skip-permissions
```
