# SLURM Templates & Job Submission Guide (IBEX / KAUST)

**Account:** `pi-hohndor` · **User:** `rioszemm` · **QOS:** `normal` (max 1300 concurrent jobs)

## Ways I can submit work to Ibex (capability summary)

This cluster + my QOS supports all of these — pick based on the workload shape:

| Pattern | When to use | Section |
|---|---|---|
| **Single job** | One command, one resource block | §1 |
| **Parallel loop** | Many independent inputs, submit one `sbatch` each | §2 |
| **Job array** | Same script over N chunks, one submission, throttle with `%` | §5 |
| **Dependency chain** | Job B must wait for job A (`afterok`) | §3 |
| **Multi-stage pipeline** | Fan-out → fan-in across stages | §4 |
| **GPU job** | Request `--gres=gpu:TYPE:N` | §6 |

Up to **1300 concurrent jobs** means large parallel loops and wide arrays are fine.
Prefer **arrays** over loops when the script is identical per chunk (less scheduler load,
one job ID, easy throttling). Use **loops** when resources differ per input.

---

## 0 — Essentials: Every Script Starts Here

```bash
#!/bin/bash
set -euo pipefail          # stop on error, undefined var, or pipe failure

# ── Account & mail (required) ──
#SBATCH --account=pi-hohndor
#SBATCH --mail-type=END,FAIL,TIME_LIMIT_90
#SBATCH --mail-user=rioszemm@kaust.edu.sa

# ── Activate conda (NO `conda activate` on compute nodes) ──
CONDA_ENV="/ibex/user/$USER/conda-environments/YOUR_ENV"
export PATH="$CONDA_ENV/bin:$PATH"

# ── Or load a module instead ──
module purge
module load mmseqs2/14.7e284   # example
```

> `module avail <keyword>` to discover modules. Available CUDA: 11.7.1, 11.8, 12.1, 12.2, 12.4.1.

---

## 1 — Single Job (Simplest Case)

```bash
sbatch \
    --account=pi-hohndor \
    --job-name="my_job" \
    --cpus-per-task=4 \
    --mem=16G \
    --time=02:00:00 \
    --output="logs/%x_%j.out" \
    --error="logs/%x_%j.err" \
    --wrap="
export PATH=$CONDA_ENV/bin:\$PATH
python my_script.py --input data.fasta --output results/
"
```

`%x` = job name, `%j` = job ID, `%a` = array task ID.

---

## 2 — Parallel Loop: One Job per Input File

Independent jobs for every file, scaling resources by input size.

```bash
#!/bin/bash
set -euo pipefail

INPUT_DIR="/path/to/inputs"
CONDA_ENV="/ibex/user/$USER/conda-environments/YOUR_ENV"
LOG_DIR="logs"; mkdir -p "$LOG_DIR"

JOB_IDS=()

for INPUT in "$INPUT_DIR"/*.fasta; do
    [[ -f "$INPUT" ]] || continue
    SAMPLE=$(basename "$INPUT" .fasta)

    # ── Scale resources by input size ──
    N=$(grep -c "^>" "$INPUT" || echo 0)
    [[ "$N" -eq 0 ]] && echo "SKIP $SAMPLE (empty)" && continue

    if   [[ $N -le 500   ]]; then MEM="8G";  TIME="01:00:00"; CPUS=4
    elif [[ $N -le 5000  ]]; then MEM="32G"; TIME="04:00:00"; CPUS=8
    else                          MEM="64G"; TIME="12:00:00"; CPUS=16
    fi

    JOB_ID=$(sbatch --parsable \
        --account=pi-hohndor \
        --job-name="${SAMPLE}" \
        --cpus-per-task="$CPUS" \
        --mem="$MEM" \
        --time="$TIME" \
        --output="$LOG_DIR/${SAMPLE}_%j.out" \
        --error="$LOG_DIR/${SAMPLE}_%j.err" \
        --wrap="
export PATH=${CONDA_ENV}/bin:\$PATH
python process.py --input ${INPUT} --threads ${CPUS}
")
    JOB_IDS+=("$JOB_ID")
    echo "Submitted $SAMPLE (n=$N) → job $JOB_ID"
done

echo "All job IDs: ${JOB_IDS[*]}"
```

---

## 3 — Job Dependencies (Run B After A Finishes)

```bash
# JOB_IDS is a bash array from §2. Join with colons for the dependency string:
DEPENDENCY="afterok:$(IFS=:; echo "${JOB_IDS[*]}")"

sbatch \
    --account=pi-hohndor \
    --dependency="$DEPENDENCY" \
    --job-name="merge_results" \
    --mem=16G --time=00:30:00 \
    --output="$LOG_DIR/merge_%j.out" \
    --wrap="
export PATH=${CONDA_ENV}/bin:\$PATH
python merge.py --indir results/ --outdir merged/
"
```

| Dependency string | Meaning |
|---|---|
| `afterok:ID` | run only if job ID succeeded |
| `afterany:ID` | run regardless of exit status |
| `afterok:ID1:ID2:ID3` | wait for ALL listed jobs to succeed (**colon-separated**) |
| `afternotok:ID` | run only if job ID failed |
| `singleton` | one job of this name at a time |

> ⚠️ Job IDs in a dependency are joined with **colons** (`afterok:1:2:3`), never commas.
> Commas create separate independent dependency conditions, which is not what you want here.

---

## 4 — Multi-Stage Pipeline (Chained Dependencies)

Fan-out Stage 1 & 2 per sample, then a single fan-in merge.

```bash
#!/bin/bash
set -euo pipefail

CONDA_ENV="/ibex/user/$USER/conda-environments/YOUR_ENV"
LOG_DIR="logs"; mkdir -p "$LOG_DIR"

# ── Stage 1: fan out ──
STAGE1_JOBS=()
for INPUT in data/*.fasta; do
    SAMPLE=$(basename "$INPUT" .fasta)
    JOB=$(sbatch --parsable \
        --account=pi-hohndor \
        --job-name="s1_${SAMPLE}" \
        --mem=16G --time=02:00:00 \
        --output="$LOG_DIR/s1_${SAMPLE}_%j.out" \
        --wrap="export PATH=$CONDA_ENV/bin:\$PATH; python step1.py --input $INPUT")
    STAGE1_JOBS+=("$JOB")
done
S1=$(IFS=:; echo "${STAGE1_JOBS[*]}")   # colon-joined

# ── Stage 2: each waits on ALL of stage 1 ──
STAGE2_JOBS=()
for INPUT in data/*.fasta; do
    SAMPLE=$(basename "$INPUT" .fasta)
    JOB=$(sbatch --parsable \
        --account=pi-hohndor \
        --dependency=afterok:${S1} \
        --job-name="s2_${SAMPLE}" \
        --mem=32G --time=04:00:00 \
        --output="$LOG_DIR/s2_${SAMPLE}_%j.out" \
        --wrap="export PATH=$CONDA_ENV/bin:\$PATH; python step2.py --input results/$SAMPLE")
    STAGE2_JOBS+=("$JOB")
done
S2=$(IFS=:; echo "${STAGE2_JOBS[*]}")

# ── Stage 3: single fan-in merge ──
sbatch \
    --account=pi-hohndor \
    --dependency=afterok:${S2} \
    --job-name="merge" \
    --mem=64G --cpus-per-task=20 --time=06:00:00 \
    --output="$LOG_DIR/merge_%j.out" \
    --wrap="export PATH=$CONDA_ENV/bin:\$PATH; module load mmseqs2/14.7e284; python merge_and_cluster.py"
```

> Fixed vs. old version: job IDs are collected in bash **arrays** and joined with
> `IFS=:` into colon-separated strings — the previous `${VAR//:/,}` comma-substitution
> was incorrect for `afterok`.

---

## 5 — Job Arrays (Same Script, Many Chunks)

Best choice when one script splits work by `$SLURM_ARRAY_TASK_ID`.

```bash
#!/bin/bash
#SBATCH --account=pi-hohndor
#SBATCH --mail-type=END,FAIL,TIME_LIMIT_90
#SBATCH --mail-user=rioszemm@kaust.edu.sa
#SBATCH --job-name=predict
#SBATCH --array=0-15%4             # 16 tasks, max 4 running at once
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --time=04:00:00
#SBATCH --gres=gpu:v100:1          # 1 GPU per task
#SBATCH --output=logs/task_%A_%a.out   # %A = array job ID, %a = task index
#SBATCH --error=logs/task_%A_%a.err

module purge
module load esm/1.0.3
CONDA_ENV="/ibex/user/$USER/conda-environments/YOUR_ENV"
export PATH="$CONDA_ENV/bin:$PATH"

echo "Task ${SLURM_ARRAY_TASK_ID}/${SLURM_ARRAY_TASK_COUNT} | Node ${SLURMD_NODENAME} | GPU ${CUDA_VISIBLE_DEVICES}"

python predict.py \
    --input  data/sequences.fasta \
    --outdir results/ \
    --chunk  ${SLURM_ARRAY_TASK_ID} \
    --total-chunks ${SLURM_ARRAY_TASK_COUNT}
```

Submit: `sbatch my_array_job.sh`

**Array index patterns:**

```bash
#SBATCH --array=0-99          # 100 tasks
#SBATCH --array=0-99%10       # 100 tasks, max 10 concurrent (throttle)
#SBATCH --array=1,3,5,7       # specific indices
#SBATCH --array=0-15:2        # step of 2 → 0,2,4,...
```

> Depend on a whole array with `--dependency=afterok:<ARRAY_JOB_ID>` (no task suffix).

---

## 6 — GPU Jobs

```bash
sbatch \
    --account=pi-hohndor \
    --gres=gpu:v100:1 \
    --cpus-per-task=4 \
    --mem=48G \
    --time=04:00:00 \
    --job-name="gpu_job" \
    --output="logs/%x_%j.out" \
    --wrap="
module purge
module load cuda/12.2
export PATH=$CONDA_ENV/bin:\$PATH
python train.py --device cuda
"
```

**GPU types & partitions** (verify live with `refresh_resources.sh`):

| Partition | Max time | GPU types |
|---|---|---|
| `debug` | 2 hr | v100, p6000 |
| `gpu4` | 4 hr | a100, v100, p100, gtx_1080_ti |
| `gpu24` | 24 hr | a100, v100 |
| `gpu72` | 3 days | a100, v100 |
| `gpu` | 14 days | a100, v100, h200, p100, p6000, gtx |
| `gpu_wide` / `gpu_wide24` / `gpu_wide72` | up to 14 days | a100 ×8, v100 ×8 |

Request multiple GPUs on one node: `--gres=gpu:a100:4`.
There's **1× h200 ×8 node** on `gpu` — the strongest GPU available.

---

## 7 — Useful SLURM Commands

```bash
squeue -u $USER                  # your running/pending jobs
squeue -u $USER -t PENDING       # only pending
squeue -u $USER -o "%.10i %.14j %.8T %.10M %R"   # readable custom format
scancel <JOB_ID>                 # cancel one job
scancel -u $USER                 # cancel ALL your jobs
scancel <JOB_ID>_[0-15]          # cancel array tasks 0–15
sacct -j <JOB_ID> --format=JobID,Elapsed,MaxRSS,State,ReqTRES%40   # finished job
seff <JOB_ID>                    # efficiency report (right-size next run)
sinfo -p gpu24 -o "%N %G %t"     # node/GPU state for a partition
```

---

## Gotchas & Tips

1. **Conda on compute nodes:** `export PATH=.../bin:$PATH`, not `conda activate`.
2. **Escaping in `--wrap`:** submit-time vars `$VAR`; runtime vars `\$VAR` (e.g. `\$SLURM_ARRAY_TASK_ID`).
3. **Create log dirs first:** SLURM won't `mkdir` — missing dir = silent fail. `mkdir -p logs`.
4. **`--parsable`:** returns only the job ID — essential for dependency chains.
5. **Dependencies use colons:** `afterok:1:2:3`, never commas.
6. **Right-size with `seff`:** check a finished job, then trim `--mem`/`--time` next time.
7. **Array throttling:** `%N` caps concurrent tasks — polite on shared GPU partitions.
8. **Always set `--account=pi-hohndor`** or the job is rejected.
