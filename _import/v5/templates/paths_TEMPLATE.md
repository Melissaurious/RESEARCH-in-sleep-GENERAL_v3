# Canonical Paths — Retron DB Project

## Local (borg)
| Name | Path |
|---|---|
| Project root | `/home/borg/RESEARCH-in-sleep-RETRON-DB/` |
| Input data (canonical, DO NOT MODIFY) | `/home/borg/RESEARCH-in-sleep-RETRON-DB/MELISSA_DATA/json_files_input_june/` |
| Existing scripts (DO NOT MODIFY) | `/home/borg/RESEARCH-in-sleep-RETRON-DB/MELISSA_SCRIPTS/` |
| All ARIS outputs go here | `/home/borg/RESEARCH-in-sleep-RETRON-DB/ARIS_OUTPUT/` |
| Papers | `/home/borg/RESEARCH-in-sleep-RETRON-DB/papers/` |
| Templates | `/home/borg/RESEARCH-in-sleep-RETRON-DB/templates/` |
| Conda env | `/home/borg/miniconda3/envs/retron_tradicional` |
| GPUs | 2× RTX 4090, CUDA 12.2 |

## Ibex (HPC)
| Name | Path |
|---|---|
| Home | `/ibex/user/rioszemm/` |
| Experiments | `/ibex/user/rioszemm/experiments/` |
| Conda env | `/ibex/user/rioszemm/conda-environments/retron_tradicional` |
| SLURM account | `pi-hohndor` |
| SSH | `rioszemm@vscode.ibex.kaust.edu.sa` |
| Logs | `/ibex/user/rioszemm/experiments/logs/` |

## Key Scripts (read-only reference)
| Script | What it does |
|---|---|
| `MELISSA_SCRIPTS/utils_FOR_ALL_FILES.py` | Extract metadata from JSON system records |
| `MELISSA_SCRIPTS/phylogenetic_tree/` | Initial phylogenetic analysis (needs revision) |
| `MELISSA_SCRIPTS/annotate_RT_domains/` | Domain boundary pipeline (DSSP + FoldSeek + ESMFold) |
| `MELISSA_SCRIPTS/OPERON_function_benchmark/` | Operon boundary extraction (RegulonDB benchmark) |
| `MELISSA_SCRIPTS/database_analysis/` | Per-database initial analysis |
| `MELISSA_SCRIPTS/co_variation_analysis/` | RT–ncRNA covariation (early stage) |

## Pipeline Source Tools (READ-ONLY)
| Tool | Borg path | Ibex path |
|---|---|---|
| PADLOC | `/home/borg/RETRONS_january_2026/the-retron-project/src/padloc` | `/ibex/user/rioszemm/the-retron-project/src/padloc` |
| MyRT HMMs | `/home/borg/RETRONS_january_2026/the-retron-project/src/myRT/Models/HMM/`| `/ibex/user/rioszemm/the-retron-project/src/myRT/Models/HMM/` |
| DefenseFinder | `/home/borg/RETRONS_january_2026/the-retron-project/src/defense-finder` | `/ibex/user/rioszemm/the-retron-project/src/defense-finder` |
| PADLOC CM db | `/home/borg/RETRONS_january_2026/the-retron-project/src/padloc/data/cm/padlocdb.cm` | `/ibex/user/rioszemm/the-retron-project/src/padloc/data/cm/padlocdb.cm` |
| MyRT all RTs HMM | `/home/borg/RETRONS_january_2026/the-retron-project/src/myRT/Models/HMM/RVT-All.hmm` | `/ibex/user/rioszemm/the-retron-project/src/myRT/Models/HMM/RVT-All.hmm` |
| MyRT Retrons HMM | — | `/ibex/user/rioszemm/the-retron-project/src/myRT/Models/HMM/RVT-Retrons.hmm` |

## Mestre et al. Reference Data
| File | Path |
|---|---|
| 166/171 experimental RT+ncRNA sequences | `/home/borg/RETRONS_january_2026/the-retron-project/PHYLOGENETIC_TREE/support.csv` |
| Supplementary T1 (systematic predictions) | `/home/borg/RETRONS_january_2026/the-retron-project/PHYLOGENETIC_TREE/IBEX_TESTS/Supp_material_T1_R1_systematic_prediction.csv` |
| Mestre sequence IDs traced to your pool | `MELISSA_SCRIPTS/` (locate exact script — describe below) |
GEM metadata: /home/borg/RESEARCH-in-sleep-RETRON-DB/MELISSA_DATA/gem_metadata.tsv 
