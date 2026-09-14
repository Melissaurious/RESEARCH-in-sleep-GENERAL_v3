#!/bin/bash
#SBATCH --job-name=esmfold_retron
#SBATCH --account=pi-hohndor
#SBATCH --mail-type=END,FAIL,TIME_LIMIT_90
#SBATCH --mail-user=rioszemm@kaust.edu.sa
#SBATCH --array=0-15%4
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --time=08:00:00
#SBATCH --gres=gpu:v100:1
#SBATCH --output=logs/esmfold_%a_%j.out
#SBATCH --error=logs/esmfold_%a_%j.err

module purge
# module load esm/1.0.3   # uncomment if ESMFold needs it; verify with: module avail esm

CONDA_ENV="/ibex/user/rioszemm/conda-environments/retron_tradicional"
export PATH="$CONDA_ENV/bin:$PATH"

echo "Task ${SLURM_ARRAY_TASK_ID} | Node ${SLURMD_NODENAME} | GPU ${CUDA_VISIBLE_DEVICES}"

python /ibex/user/rioszemm/experiments/run_esmfold.py \
    --input        /ibex/user/rioszemm/experiments/sequences.fasta \
    --outdir       /ibex/user/rioszemm/experiments/structures/ \
    --chunk        ${SLURM_ARRAY_TASK_ID} \
    --total-chunks ${SLURM_ARRAY_TASK_COUNT}
