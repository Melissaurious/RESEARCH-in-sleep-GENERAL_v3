# CLAUDE.md — GENERAL v7, the governance layer

Rules, checks and templates. **No science happens here.** A project consumes this as a
submodule at `general/` and pins it by sha, so "we followed our standards" stays falsifiable
after the standards change.

**Self-contained.** Nothing here requires reading an earlier version, an earlier project
tree, or any folder outside the project being worked on. Prior trees are named once, in
`LINEAGE.md`, and read only when a launcher sends you there.

## The shape of work — one human stop, at the start

```
launchers/<track>.md   ← the operator writes this ONCE, then sleeps
        ↓
   PLAN.md   →  review.sh --plan     → an independent model's verdict GATES execution
        ↓
   execute   →  review.sh --result   → its verdict GATES landing
        ↓
   results/<GATE>/  lands
        ↓
   the operator reads it in the morning    ← asynchronous, never blocking
```

**The reviewer holds the gate, not the operator** (WA-A.1). Never wake the operator to ask
something the launcher should have answered; if the launcher did not answer it, that is a
launcher defect to log, not a reason to stall (WA-S.1).

## Read before acting

Always:
- `agreements/WORKING_AGREEMENT.md` — 18 ALWAYS rules. WHEN rules are read on demand.

When the situation applies:
- `agreements/EVIDENCE_STANDARDS.md` — before grading a claim, designing a control, reporting a rate
- `agreements/BUNDLE_SPEC.md` — before producing any number
- `agreements/REPORTING_STANDARDS.md` — before any figure or report
- `agreements/LAUNCHER_SPEC.md` — before starting a track
- `site/COMPUTE.md`, `site/IBEX.md` — before sizing or submitting a job
- `site/TOOLING.md` — before installing anything or changing models

## The loop

0. **Plan mode first.** Recon and a plan only. The harness refuses writes; an instruction
   alone would drift. On approval the first action out of plan mode is `ARIS_OUTPUT/<gate>/PLAN.md`.
1. One gate is active: one measurement, one stop condition, one bundle (WA-G.1). Its weight —
   **LIGHT** or **FULL** — is declared in the launcher before it runs (WA-B.3).
2. `bash general/tools/review.sh --plan <gate>` — **a BLOCKER here means no execution.**
   Fix and re-review, up to 3 rounds, then halt and say it was a budget-halt (WA-A.3).
3. Work in `ARIS_OUTPUT/<gate>/`. Scratch is free and expected to be messy.
4. Land the bundle per `agreements/BUNDLE_SPEC.md`. The gate is done when `run.sh` **reruns
   and reproduces the number** — not when a document is written (WA-B.2).
5. `bash general/tools/review.sh --result <gate>` — **a BLOCKER here means no landing.**
6. `bash general/checks/bundle_valid.sh results/<GATE>`, commit, retro, push.

A gate must fit in one session before the first compaction. If it does not, it is two gates.

## File safety

- Never modify source data or original scripts (WA-D.1). Enforced by file mode.
- All scratch to `ARIS_OUTPUT/` — gitignored, disposable, messy by design.
- Numbers to `results/<GATE>/` and nowhere else (WA-B.1).
- Never install into the base conda environment.

## Measure, do not conclude

Report counts, including the ugly ones. An interpretation lands as `PROPOSED:` in the bundle
README and becomes the operator's by reading it — it never blocks the gate (WA-A.4).

**Progress is not how much you have done.** It is how many claims left UNPROVEN, and whether
any went to REFUTED. A week with three REFUTED claims and no SUPPORTED ones is a good week;
a week with ten documents and no claim movement is not a week of work.

## Before any negative or absence claim

A count of zero needs a positive control showing the same code returns non-zero on a case
known to be present (`EVIDENCE_STANDARDS` §6). Every gate supplies its own.

## When blocked

Never guess silently and never stall (WA-S.1). Append to `docs/BLOCKED.md`: what is needed,
why, the options, your recommended default. **LOW-STAKES** — reversible, contained, no compute
>10 min, nothing outside the gate's scratch: take the default, log it, **continue**.
**HIGH-STAKES** — deleting or overwriting anything, large compute, changing a spec,
publishing: stop and wait.

## Amending this layer

A session may **propose**, never amend. A proposal names the case it would have caught **and**
a case it would wrongly reject — the second is what fixes the scope. Removed rules go to the
graveyard with a reason.

    bash general/tools/general_sha.sh       # the revision a bundle records
    bash general/checks/specs_exist.sh      # must print OK
    bash general/checks/rules_current.sh    # EXPIRED / DUE / PROVISIONAL
