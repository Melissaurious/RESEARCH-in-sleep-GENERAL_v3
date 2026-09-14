# RESEARCH-in-sleep-GENERAL_v3

> ✅ **This folder is the canonical source of working agreements**, as of 2026-09-14.
> `RESEARCH-in-sleep-GENERAL` (no suffix), `_v2` and `_v5` are superseded. A launcher,
> script or `CLAUDE.md` pointing at any of those is stale and must be corrected, not
> followed. → `specs/ANCHORS.md`

Shared context, standards and enforcement for every sleep-research sub-project. Each
sub-project keeps a short `CLAUDE.md` declaring only its specifics and pointing back here.

## The loop

```
plan → ATTACK THE PLAN → execute → ATTACK THE RESULT → promote → retro
            │ gate 1                      │ gate 2         │
            └ no execution                └ no promotion   └ results/, by hand, at the end
```

Two directories, two jobs: **`ARIS_OUTPUT/<STAGE_ID>/` is the workshop** — work dirty
there, keep the dead ends, that mess is the audit trail. **`results/<STAGE_ID>/` is the
shipped record** — clean, documented, re-executed from a fresh checkout, and the only
thing that ever reaches GitHub. Promotion is a copy, never a move.

## Layout

| | |
|---|---|
| `CLAUDE.md` | AI-facing master context. Short; links to everything below. |
| **`specs/`** | **how work must be done** |
| `specs/ANCHORS.md` | ⭐ the one place a path is declared. Read first. |
| `specs/WORKING_AGREEMENT.md` | editing, debugging, sizing, verifying, context hygiene |
| `specs/EVIDENCE_STANDARDS.md` | ⭐ whether a number means what it appears to mean |
| `specs/ADVERSARIAL_REVIEW.md` | the two gates: packet, verdicts, dispositions |
| `specs/PROMOTION_STANDARDS.md` | workshop → shipped record |
| `specs/REPORTING_STANDARDS.md` | figures, report structure, interpretation |
| `specs/LAUNCHER_TEMPLATE.md` | ⭐ per-stage launcher. Part A is Melissa's alone. |
| `specs/LAUNCHERS_README.md` | the five things Melissa actually does |
| `specs/TOOLING.md` | models, the codex reviewer, env policy, ARIS |
| **`tools/`** | **the gates, as exit codes rather than good intentions** |
| `tools/check_launcher.py` | refuses to start on an incomplete launcher |
| `tools/adversary.py` | runs a review pass; probes the reviewer by execution |
| `tools/promote_stage.py` | refuses to promote uncleared or unreproducible work |
| `tools/dispatch.py` | decides borg vs Ibex, with a stated reason |
| `tools/cache.py` | `@cached` for expensive intermediates |
| `compute/` | borg + Ibex hardware, partitions, SSH, live snapshots |
| `templates/` | SLURM patterns, Ibex header, `.gitignore` for project repos |
| `projects/CLAUDE_STUB_TEMPLATE.md` | copy into each sub-project as its `CLAUDE.md` |
| `retros/` | one per stage. **A rule named in a retro but not landed in a spec does not exist.** |

## Starting a stage

```bash
export RSG="$HOME/RESEARCH-in-sleep-GENERAL_v3"
cp "$RSG/specs/LAUNCHER_TEMPLATE.md" "$PROJ/launchers/LAUNCHER_<STAGE_ID>.md"
# fill Part A — every field; there are no optional ones
python "$RSG/tools/check_launcher.py" "$PROJ/launchers/LAUNCHER_<STAGE_ID>.md"
```

Then follow `specs/LAUNCHERS_README.md`. The two fields that repay most are *the question
stated so it can fail* and *what might already exist*.

## Starting a new sub-project

1. `cp projects/CLAUDE_STUB_TEMPLATE.md <new-project>/CLAUDE.md` and fill the anchors.
2. `cp templates/gitignore_TEMPLATE <new-project>/.gitignore` — **before the first commit.**
3. Add a row to the Active Projects table in `compute/resources.md`.
4. Everything else is inherited by reference from this folder.

## Refresh live Ibex state

```bash
bash compute/refresh_resources_remote.sh   # from borg (recommended)
bash compute/refresh_resources.sh          # already on Ibex
```
