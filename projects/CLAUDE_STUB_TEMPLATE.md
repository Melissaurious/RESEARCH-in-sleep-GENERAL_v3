# CLAUDE.md — [PROJECT NAME]

Project-specific context only. **All shared mechanics are inherited** from the agreements
repo — read its `CLAUDE.md` first for the loop, compute, working agreement and tooling.
Nothing in this file may restate, paraphrase or contradict a shared spec; if it needs to,
the shared spec is what changes.

## Anchors
```bash
export RSG="$HOME/RESEARCH-in-sleep-GENERAL_v3"   # the agreements repo — edit per machine
[ -f "$RSG/specs/ANCHORS.md" ] || { echo "RSG is wrong: $RSG"; return 1; }
```

| Name | Value | Writable? |
|---|---|---|
| `$PROJ` | `[$HOME/RESEARCH-in-sleep-XXX/]` | — |
| `$ENV` | `[env_name]` — local `[/home/borg/miniconda3/envs/…]`, Ibex `[/ibex/user/rioszemm/conda-environments/…]` | — |
| borg GPU | `CUDA_VISIBLE_DEVICES=[0|1]` | — |
| Source data | `[$PROJ/DATA/]`, `[$PROJ/MELISSA_SCRIPTS/]` | ⛔ read-only, always |
| Workshop | `$PROJ/ARIS_OUTPUT/<STAGE_ID>/` | ✅ freely — **work dirty here** |
| Shipped record | `$PROJ/results/<STAGE_ID>/` | ✅ `promote_stage.py` only |

⛔ `ARIS_OUTPUT/` is never committed. `results/` is committed **by Melissa, by hand, at the
end**. Copy `$RSG/templates/gitignore_TEMPLATE` → `.gitignore` before the first commit.

## Active stage
- **STAGE_ID:** `[stageN_slug]`
- **Launcher:** `launchers/LAUNCHER_[stageN_slug].md`
- **Phase:** `[plan | plan-review | execute | result-review | promote | retro]`
- **Blocked on:** `[nothing | what]`

## Inherited — read, do not duplicate
| | |
|---|---|
| Master context + the loop | `$RSG/CLAUDE.md` |
| Paths and the STAGE_ID contract | `$RSG/specs/ANCHORS.md` |
| How to edit, debug, size, verify | `$RSG/specs/WORKING_AGREEMENT.md` |
| Whether a number means anything | `$RSG/specs/EVIDENCE_STANDARDS.md` |
| The two gates | `$RSG/specs/ADVERSARIAL_REVIEW.md` |
| Workshop → shipped record | `$RSG/specs/PROMOTION_STANDARDS.md` |
| Figures, reports, interpretation | `$RSG/specs/REPORTING_STANDARDS.md` |
| Compute, partitions, SLURM | `$RSG/compute/resources.md`, `$RSG/templates/slurm_templates.md` |
| Models, reviewer, ARIS | `$RSG/specs/TOOLING.md` |

## Project notes
`[Data quirks, known-wrong artefacts, current blockers. Anything that would make an
existing artefact untrustworthy belongs here — absence is loud, wrongness is quiet.]`

<!-- ARIS:BEGIN -->
<!-- ARIS:END -->
