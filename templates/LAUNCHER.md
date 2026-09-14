# LAUNCHER — [track_slug]

> The **only** document you write. Fill every field, then run
> `python general/tools/check_launcher.py launchers/LAUNCHER_[track_slug].md`.
> There are no optional fields: an unfilled one stops the gate (WA-L.2), because the agent
> must never wake you to ask something this document should have answered.

## 1. Objective and success criterion

**Objective.** [One sentence. The artefact this track produces, not the aspiration.]

**Success criterion.** [How you will know it is done AND correct — not "it ran", not
"the file exists".]

## 2. Kill criteria

[**What result makes you abandon this line?** Written now, before any number exists, because
this is the only moment it is honest. `EVIDENCE_STANDARDS` §6: if nothing could return a
negative, this is a description and not a test.]

[Also: what cost makes you stop regardless of result — e.g. "more than 2× the estimate".]

## 3. Non-goals — out of scope

[Be explicit and generous. Anything not listed that the agent thinks is needed gets logged
in `docs/BLOCKED.md` with a recommended default, not built. Scope discovered after a review
finding is not out of scope.]

## 4. Inputs

| path | what it is | trust grade |
|---|---|---|
| `[/abs/path]` | `[…]` | `[RAW \| FROZEN:<bundle> \| RE-DERIVE \| DO-NOT-USE:<why>]` |

⛔ Read-only, always. An ungraded input is `DO-NOT-USE` (WA-L.3). Treat any schema document
as a hypothesis about the data, not ground truth — **probe real values** (WA-D.4).

## 5. What might already exist

[Prior bundles, artefacts on disk, scripts that may already answer part of this. Say where
to look, **and say what would make them untrustworthy.**]

⚠️ Absence is loud; wrongness is quiet. A stage recorded as "never started" had in fact been
run; 21.4 GB of embeddings existed and were computed on unoriented sequence. Both read as ready.

## 6. Claims this track settles

| id | claim | status |
|---|---|---|
| `[C1]` | `[one sentence, scoped to what will actually be examined]` | `UNPROVEN` |

Every claim is born `UNPROVEN` here, before its gate runs. A claim reaches the paper only
from `SUPPORTED` with circularity `NONE` or `LOW`. **`REFUTED` is a result, not a failure.**

## 7. Gates

| gate id | the ONE measurement | weight | settles | stop condition |
|---|---|---|---|---|
| `[g1_slug]` | `[exactly one measurement]` | `[LIGHT\|FULL]` | `[C1]` | `[done when results/g1_slug/ exists and run.sh reproduces the number]` |

**LIGHT** — provenance skeleton only; may not enter a claim, a figure, or the paper.
**FULL** — controls, declared thresholds, the denominator's independent second count.
Required the moment a number becomes a claim (WA-B.3). Start LIGHT unless it is a claim.

## 8. Compute

- Expected: `[borg GPU 1 | Ibex gpu24 a100 ×1]`, estimated `[X]` hr.
- Hard stop at `[2]`× the estimate — report, do not push through.
- Size from a **measured** smoke test on a representative slice, never the head of a file
  (WA-K.1). Thresholds: `general/site/COMPUTE.md`.

## 9. Autonomy

**Decide alone and continue** (log in `docs/BLOCKED.md`): `[anything reversible, contained,
under 10 min of compute, inside the gate's scratch]`

**Stop and wait**: `[deleting or overwriting anything, compute over the budget, changing a
spec, publishing]`

**Review rounds before halting:** `[3]`. A budget-halt is reported as a budget-halt, never
as a pass (WA-A.3).
