#!/bin/bash
set -euo pipefail
# ═══════════════════════════════════════════════════════════════════
#  STANDARD IBEX HEADER  —  copy the #SBATCH lines into any job script
#  then add job-specific ones (--job-name, --time, --gres, etc.) below
# ═══════════════════════════════════════════════════════════════════

# ── Account & notifications (always required) ──
#SBATCH --account=pi-hohndor
#SBATCH --mail-type=END,FAIL,TIME_LIMIT_90
#SBATCH --mail-user=rioszemm@kaust.edu.sa

# ── Conda env — set per project, NEVER use base ──
#    Pick one of your envs (see refresh_resources.sh output for the full list):
#      retron_tradicional  retron_design  retron_engineering
#      diffab  esm_ezy  progen3  progen3_clean  rinalmo  rna_fm  ...
CONDA_ENV="/ibex/user/$USER/conda-environments/CHANGE_ME"
export PATH="$CONDA_ENV/bin:$PATH"

# ── Module loading (uncomment as needed; always purge first) ──
module purge
# module load mmseqs2/14.7e284
# module load cuda/12.2          # or 11.7.1 / 11.8 / 12.1 / 12.4.1
# module load esm/1.0.3          # verify exact name: module avail esm

# ── Sanity print (useful in logs) ──
echo "Host $(hostname) | Env $CONDA_ENV | Python $(which python)"
