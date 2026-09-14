# ANCHORS — the one place a path is declared

_Read by: everything. Written by: Melissa, rarely._

Every other file in this repo refers to the **names** below, never to a literal path.
If you find a hardcoded absolute path, a version suffix, or a home directory anywhere
else in this repo, that is a bug: fix it by pointing the offender here.

This file exists because the same folder was spelled five different ways across
`CLAUDE.md`, `LAUNCHER_TEMPLATE.md`, `CLAUDE_STUB_TEMPLATE.md`, `LAUNCHERS_README.md`
and `FROZEN.md` — which is why launchers drifted.

---

## 1. The shared root

| Name | What it is |
|---|---|
| `$RSG` | The absolute path of **this** folder (the shared agreements repo). |

**Never hardcode it.** Every launcher resolves it at session start:

```bash
export RSG="$HOME/RESEARCH-in-sleep-GENERAL_v3"   # the ONE line you edit per machine
[ -f "$RSG/specs/ANCHORS.md" ] || { echo "RSG is wrong: $RSG"; return 1; }
```

The guard is the point. A wrong `$RSG` that fails loudly costs a second; a wrong `$RSG`
that silently resolves to a stale copy costs a stage.

### Superseded spellings — if you see these, they are stale

`RESEARCH-in-sleep-GENERAL` (no suffix) · `..._v2` · `..._v5`

As of **2026-09-14**, `RESEARCH-in-sleep-GENERAL_v3` is the live source of working
agreements. A launcher, script, or `CLAUDE.md` pointing at any other spelling is out of
date and must be corrected, not followed.

---

## 2. Per-project anchors

Declared once in each project's own `CLAUDE.md` (from `projects/CLAUDE_STUB_TEMPLATE.md`),
never restated in a launcher:

| Name | What it is | Writable? |
|---|---|---|
| `$PROJ` | Project root, e.g. `$HOME/RESEARCH-in-sleep-RETRON-DB/` | — |
| `$PROJ/DATA/`, `$PROJ/MELISSA_SCRIPTS/` | Source data and original scripts | ⛔ **read-only, always** |
| `$PROJ/ARIS_OUTPUT/` | **The workshop.** All work happens here. Gitignored. | ✅ freely |
| `$PROJ/results/` | **The shipped record.** Promoted, reviewed, committed by hand. | ✅ via `promote_stage.py` only |
| `$ENV` | Conda env name — never `base` | — |

---

## 3. The stage ID is a contract

One string, declared in the launcher, used **verbatim** everywhere:

```
STAGE_ID = stage<N>_<slug>        e.g.  stage3_rinalmo_embeddings
```

| Where it appears | Form |
|---|---|
| Workshop dir | `$PROJ/ARIS_OUTPUT/<STAGE_ID>/` |
| Promoted dir | `$PROJ/results/<STAGE_ID>/` |
| Launcher file | `$PROJ/launchers/LAUNCHER_<STAGE_ID>.md` |
| Retro file | `$RSG/retros/YYYY-MM-DD_<STAGE_ID>.md` |
| SLURM job name | `--job-name=<STAGE_ID>` |
| Ibex logs | `/ibex/user/rioszemm/experiments/logs/<STAGE_ID>/` |

Slug rule: `^stage[0-9]+_[a-z0-9_]+$`. Lowercase, underscores, no dates, no spaces.
`tools/check_launcher.py` enforces it. **Same name on both sides of the promotion** is
what makes `results/` navigable a year later.
