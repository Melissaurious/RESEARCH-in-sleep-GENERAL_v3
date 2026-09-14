# RESEARCH-in-sleep-GENERAL — v7

The governance layer: **rules, checks, templates and tools.** No science happens here. A
project consumes this as a submodule at `general/` and pins it by sha.

> ✅ **This repository is the canonical source of working agreements.** v1, v2, v3, v5 and v6
> are superseded and named once, in `LINEAGE.md`. Prior work is *reusable* — after a smoke
> test that grades it by execution, never because it looks finished.

## ARIS owns the workflow. This layer constrains how it works.

**ARIS owns** the lifecycle — idea → contract → experiment plan → implementation →
execution → review → claims → paper — with its artifacts, its loops and round budgets, and
its reviewer routing (ARIS's `review_gate.py`). **This layer owns** data safety, evidence
standards, provenance, reporting quality, Ibex execution policy, and which decisions are
reserved for the operator.

**Why v7 exists.** v6 was rigorous and required the operator at four points inside every
measurement. Twelve projects, 75 scratch directories, 19 retros, **zero landed results.**
v7 keeps the rigor and hands the loop back to ARIS.

**The one place it intervenes in execution is Ibex**, because ARIS's `/run-experiment` and
`/experiment-queue` speak to local, vast and modal hosts over SSH + `screen`, and neither
speaks SLURM.

## Layout

| path | what it is |
|---|---|
| `CLAUDE.md` | master context, loaded every session. 95 lines by design. |
| `VERSION` · `LINEAGE.md` | this layer's version; the prior trees and how to reuse them |
| `agreements/WORKING_AGREEMENT.md` | 18 ALWAYS rules, each with an id, a check, and the real case it caught |
| `agreements/EVIDENCE_STANDARDS.md` | whether a number means what it appears to mean |
| `agreements/LAUNCHER_SPEC.md` · `BUNDLE_SPEC.md` | the operator's one document; how a number enters the repo |
| `agreements/REPORTING_STANDARDS.md` · `SESSION_HYGIENE.md` | figures and findings; what actually degrades a session |
| `site/` | this installation: `COMPUTE.md`, `IBEX.md`, `TOOLING.md` |
| `checks/` | the runnable half of the rules — every one ships a `SELFTEST=1` target |
| `templates/LAUNCHER.md` · `LAUNCHER_EXAMPLE.md` | the scaffold, and a filled one that passes |
| `skills/run-experiment-ibex/` | SLURM skill for Ibex — **overrides ARIS's generic `run-experiment`**, which uses SSH + screen |
| `skills/plan-audit/` | audits a plan's **science** before compute — additional to ARIS's review, never a replacement |
| `skills/experiment-routing-ibex/` | forces Ibex milestones to `/run-experiment-ibex`; `/experiment-queue` must never touch the cluster |
| `tools/check_launcher.py` | refuses a launcher that cannot run unattended |
| `tools/bundle.sh` · `index.sh` · `dispatch.py` · `cache.py` | bundle assembly, rollup, machine choice, caching |

## Checks

Every check is validated by watching it **fail on a case it must reject and accept a case it
must accept**. Passing on a good case alone proves nothing.

```bash
SELFTEST=1 bash checks/<name>.sh        # 75 assertions across the five
bash checks/specs_exist.sh              # every referenced path resolves. Must print OK.
bash checks/rules_current.sh            # EXPIRED / DUE / PROVISIONAL
bash checks/bundle_valid.sh results/<GATE>
```

## Starting a project

```bash
bash tools/new_project.sh /path/to/<project>
```

Then fill in exactly two things: the project's `CLAUDE.md` (subject, environment, paths) and
`launchers/LAUNCHER_<track>.md`. **A gate does not start before its claim is declared
UNPROVEN in the launcher**, and `check_launcher.py` must exit 0 — an unfilled field stops the
gate at 3am waiting for someone who is asleep.

## Amending

A session may **propose**, never amend. A proposal names the case it would have caught **and**
a case it would wrongly reject — the second is what fixes the scope. Removed rules go to the
graveyard in `agreements/WORKING_AGREEMENT.md` with a reason.
