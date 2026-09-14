# CLAUDE.md — FINAL_RETRON_PROJECT_v7

Bacterial retron systems: what a large-scale mining corpus of RT systems actually contains,
on which unit, and how much of its apparent structure is biology rather than sequencing
depth or annotation artefact.

## Governed by

`general/` — pinned by sha. **ARIS owns the lifecycle**; `general/` constrains the science.
This file declares only what neither can know: subject, environment, paths.
⛔ It restates no rule. If something here contradicts `general/`, this file is wrong.

    bash general/checks/specs_exist.sh                   # must print OK before any gate
    bash general/tools/install_ibex_overlay.sh --check   # Ibex routing still bound?

## Environment

| | |
|---|---|
| Conda env | `retron_tradicional` |
| Local env | `/home/borg/miniconda3/envs/retron_tradicional` |
| Ibex env | `/ibex/user/rioszemm/conda-environments/retron_tradicional` |
| Project root | `/home/borg/RESEARCH-in-sleep-FINAL_RETRON_PROJECT_v7` |
| Ibex experiments | `/ibex/user/rioszemm/experiments/` |
| Ibex account | `pi-hohndor` — required on every job |
| borg GPUs | 2 × RTX 4090, 24 GB — `CUDA_VISIBLE_DEVICES=0` or `1` |

### In `retron_tradicional`

`hmmsearch` `hmmbuild` `hmmalign` · `mafft` `muscle` · `cd-hit` `mmseqs` · `blastp` ·
`trimal` · `cmsearch` `cmbuild` `cmfinder.pl` · `mkdssp`

### ⚠️ NOT in `retron_tradicional` — sweep before concluding anything is missing (WA-K.2)

| tool | where it actually is |
|---|---|
| `foldseek` | `/home/borg/miniconda3/envs/esmologs/bin/foldseek`; Ibex `module load foldseek/10-941cd33` |
| `foldmason` | `/home/borg/miniconda3/envs/foldmason/bin/foldmason` — prefer the env over the pkgs copy |
| `RNAfold` | `/home/borg/.local/bin/RNAfold` |
| Pfam-A 37.0 (21,979 models) | **Ibex only** — `/ibex/user/rioszemm/the-retron-project/src/interproscan/interproscan-5.70-102.0/data/pfam/37.0/pfam_a.hmm` |

⛔ **InterProScan on borg ships a stub database** — Pfam-A holds 3–4 profiles, TIGRFAM 1.
A result from it is `DATA_INADEQUATE`, not a negative.

⛔ Prefer a **new** env over mutating `retron_tradicional` — earlier results depend on it.
Never the base environment.

## Read before acting

1. `general/agreements/WORKING_AGREEMENT.md` **§1** — five rules, stop there
2. `idea-stage/docs/research_contract.md` — the question, the claims, the known-wrong list.
   **The single claim authority.** No `GOALS.md`, no `CLAIMS.md`, no `ROADMAP.md`.
3. the active `launchers/LAUNCHER_*.md` — the task now
4. `data/README.md` — the input register: path, sha256, mode, how obtained

`idea-stage/programme/` holds the 12 stage documents and the ideas brainstorm. **Source
material, not an authority** — nothing cites a number from there.

## Data

| | |
|---|---|
| Corpus (42 files) | `/home/borg/RESEARCH-in-sleep-RETRON-DB_V3/MELISSA_DATA/json_files_input_june/` |
| Corpus, Ibex mirror | `[confirm path]` — a gate that outgrows local RAM moves there rather than sampling |
| Schema description | `/home/borg/RESEARCH-in-sleep-RETRON-DB_V5/templates/input_format_schema_only.md` |
| Extraction helper | `.../RETRON-DB_V3/MELISSA_SCRIPTS/database_analysis/utils_FOR_ALL_FILES.py` (`PipelineData`) |
| House report style | `.../MELISSA_SCRIPTS/database_analysis/PREVIOUS_ARIS_WORK/REPORT.html` |

⛔ **`MELISSA_DATA/` and `MELISSA_SCRIPTS/` are read-only** — never modified, never re-run
in place (WA-D.1, enforced by file mode).

## ARIS pipeline state

| | |
|---|---|
| Research direction | Retron system discovery, classification, and RT–ncRNA relationships |
| Current stage | `experiment-plan` — track `dbchar` |
| Target venue | PhD thesis chapter `[N]` / manuscript |
| `AUTO_PROCEED` | `true` — `/research-pipeline`'s default; this project runs unattended |
| Executor / reviewer | Opus 5 High / ARIS reviewer routing (+ codex `gpt-5.6-sol`) |
| Compute budget | per track, in the active launcher §9 |

## Known-wrong

Full list with its evidence: `idea-stage/docs/research_contract.md` § Known-wrong.
⚠️ Read it before reusing any prior number. Absence is loud; wrongness is quiet.

The two that bite first: **coordinates are contig-based** (1 in 6 records has `start == 1`,
where every arithmetic check passes anyway — verify by RT back-translation), and
**`system_subtypes` is two tools on one locus** agreeing on 44.6% — carry it, never
`groupby` it.
