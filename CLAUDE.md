# CLAUDE.md — GENERAL v6, the governance layer

This repository is **rules, checks and templates**. No science happens here. A project
consumes it as a submodule at `general/` and pins it by sha.

**Self-contained.** Nothing in this layer requires reading an earlier version of it, an
earlier project tree, or any folder outside the project being worked on. Superseded trees
are named in `LINEAGE.md` and nowhere else, and that file is read only when a launcher or
prompt explicitly sends you there.

## Read before acting

Always:
- `agreements/WORKING_AGREEMENT.md` — the ALWAYS rules. WHEN rules are read on demand.

When the situation applies:
- `agreements/LAUNCHER_SPEC.md` — before starting a track or writing a launcher
- `agreements/BUNDLE_SPEC.md` — before producing any number
- `agreements/EVIDENCE_STANDARDS.md` — before grading a claim, designing a control, or
  reporting a rate
- `agreements/REPORTING_STANDARDS.md` — before any figure or report
- `agreements/SESSION_HYGIENE.md` — at a retro
- `site/COMPUTE.md` — before sizing or submitting a job
- `site/TOOLING.md` — before installing anything or changing models
- `PROMPTS.md` — the session prompts. Not read by a session; read by the operator.

## The shape of work

    launchers/<track>.md  the ONLY document the operator writes (WA-L.1):
                          §1 objective, success criterion, KILL CRITERIA
                          §2 out of scope and NON-GOALS
                          §3 inputs, each with a trust grade
                          §3b CLAIMS this track settles, born UNPROVEN
                          §4 GATES — measurement, weight, mode, stop condition
    results/<GATE>/       the evidence. A bundle, or it did not happen.
    INDEX.md              GENERATED rollup (tools/index.sh). Never hand-edited.
    paper/                assembled from SUPPORTED claims only (BS-7)

A **track** is the unit of scope; a **gate** is the unit of a number. One gate = one
measurement = one session = one bundle = one DIRECTORY (WA-R.1).

**Progress is not how much you have done.** It is how many claims left UNPROVEN, and whether
any went to REFUTED. A week with three REFUTED claims and no SUPPORTED ones is a good week;
a week with ten documents and no claim movement is not a week of work.

## The loop

0. **Start in plan mode.** Recon and a plan only — no scripts, no writes. The harness
   refuses the write; the instruction alone would drift. On approval the first action out of
   plan mode is `ARIS_OUTPUT/<gate>/PLAN.md`.
1. One gate is active. It names one measurement and its stop condition (WA-R.1, WA-R.2), and
   the claim it settles is declared UNPROVEN in its launcher §3b **before** it runs (CL-1).
   Its **weight** is declared too — LIGHT or FULL (WA-B.5).
2. Work happens in `ARIS_OUTPUT/<gate>/`. Scratch is free.
3. The gate is done when `results/<GATE>/` exists and `run.sh` reruns and reproduces the
   number (WA-B.2). Not when a document is written.
4. `bash general/checks/bundle_valid.sh results/<GATE>`, then the operator opens `INPUTS.tsv`
   and recognises the inputs. The second half is not automatable and not optional.
5. Commit and retro. **Push when the bundle is accepted, not before** (WA-R.6).

A gate must fit in one session before the first compaction. If it does not, it is two gates.

## File safety

- Never modify source data or original scripts (WA-D.1). Enforced by file mode.
- A track writes to exactly one directory, enforced by `sandbox.filesystem.allowWrite`
  (WA-C.6). Everything else is read-only.
- All scratch goes to `ARIS_OUTPUT/` — gitignored, disposable, allowed to be messy.
- Numbers go to `results/<GATE>/` and nowhere else (WA-B.1).
- Never install into the base environment.

## Before any negative or absence claim

A count of zero needs a positive control showing the same code returns non-zero on a case
known to be present (`agreements/EVIDENCE_STANDARDS.md` §6). A project inherits no positive
control; every gate supplies its own.

## When blocked

Never guess silently and never stall (WA-S.4). Append to `docs/BLOCKED.md`: what is needed,
why, the options, your recommended default.
- **LOW-STAKES** — reversible, contained, no compute >10 min, nothing written outside the
  gate's scratch directory: take the default, log it, continue.
- **HIGH-STAKES** — deleting or overwriting anything, large compute, changing a spec, moving
  the pin, publishing, anything ambiguous about scientific interpretation: stop and wait.

## Interpretation

Whether a result supports a claim, whether a goal is met, whether to keep going: the
operator's call, always (WA-I.1). Measure, record, and report the counts including the ugly
ones. Do not conclude.

## Amending this layer

A session may **propose**, never amend. A proposed rule names the case it would have caught
AND a case it would wrongly reject (WA-A.1). Moving a project's pin is a deliberate commit
with a decision record, never a drift.

    bash general/tools/general_sha.sh          # the revision a bundle records (BS-10)
    bash general/checks/specs_exist.sh         # must print OK
    bash general/checks/rules_current.sh       # EXPIRED / DUE / PROVISIONAL
