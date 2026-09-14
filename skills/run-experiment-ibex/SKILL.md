---
name: run-experiment-ibex
description: Run an experiment on the KAUST Ibex SLURM cluster. Use INSTEAD OF the generic run-experiment skill whenever work goes to Ibex — that one launches remote work over SSH + screen, which is wrong here: it bypasses the scheduler, holds no allocation, dies with the connection, and leaves no job ID to account against. Triggers on sbatch, srun, squeue, sacct, seff, SLURM, Ibex, array job, partition, gpu24, pi-hohndor, or any job expected to exceed 2 hours or 24 GB VRAM.
---

# Running an experiment on Ibex

⛔ **Never use SSH + `screen`, `nohup`, or a background process on a login node.** Ibex work
goes through SLURM. A screen session holds no allocation, dies with the connection, produces
no job ID, and cannot be sized from afterwards.

`borg` carries no SLURM client and does not mount `/ibex`: **every scheduler command runs on
the cluster over SSH.** Full reference, with what is verified and what is transcribed:
`general/site/IBEX.md`. Thresholds: `general/site/COMPUTE.md`.

    IBEX="rioszemm@ilogin.ibex.kaust.edu.sa"      # a STABLE login node, not the vscode pool

## The flow

    plan → preflight (interactive) → smoke job → size from sacct/seff
         → generate script → sbatch --parsable → capture ID → watch → collect
         → validate by CONTENT → EXPERIMENT_LOG.md → next gate

Do not skip to `sbatch`. Steps 1–3 cost minutes; skipping them costs a queue cycle, and
queue latency is the dominant cost on this cluster.

## 1 · Preflight — validate the HARNESS interactively, before queueing (WA-K.1)

A trivial harness bug — a bad quote, a missing module, the wrong python — costs seconds of
compute and hours of queue latency.

```bash
ssh $IBEX 'srun --account=pi-hohndor --cpus-per-task=4 --mem=8G \
  --time=00:20:00 --partition=debug --pty bash -i'
# then, inside:
/ibex/user/$USER/conda-environments/<env>/bin/python -c "import <pkg>; print('ok')"
ls <run_script>
```

⚠️ `module avail` can come back **empty even where the software is installed**, and
dependencies usually live under a named env rather than the base install. Put the import
preflight **inside the batch script too**, so an unexpected failure names itself.

## 2 · Smoke job — measure, never guess (WA-K.1)

Submit a small job on `debug` first. The sample must be **representative** — random or
length-stratified across the input's distribution, never the head of the file, and under the
same device contention as the real run. A head-sampled, uncontended smoke test once measured
11.1 s/fold against 28.3 s/fold actual: a 2.5× under-estimate, from exactly those two causes.

Then read the real cost off the finished job:

```bash
ssh $IBEX 'sacct -j <JOB_ID> --format=JobID,Elapsed,MaxRSS,State,ReqTRES%40'
ssh $IBEX 'seff <JOB_ID>'
```

`seff` gives what `sacct` alone does not — memory and CPU *efficiency*. A real run returned
`Memory Efficiency: 16.58% of 32.00 GB`, i.e. the request was 4× too large. **Size the real
job as measured-rate × N**, and put that arithmetic in `PLAN.md`.

⚠️ **Requesting more GPUs LOWERS queue priority.** The fastest wall-clock is the fewest
resources that still finish in the window, not the most you can request. And **submit cheap
gating jobs BEFORE large arrays** — fairshare is spent by what already ran, so a big array
launched first prices a small gating job out of the queue behind `Priority`.

## 3 · Generate the script

Write it to the gate's scratch (`ARIS_OUTPUT/<gate>/scripts/`), never hand-edit on the
cluster. **`mkdir -p logs/` first — SLURM will not create the `--output` path, and a missing
log directory is a silent failure.**

```bash
#!/bin/bash
set -euo pipefail
#SBATCH --account=pi-hohndor            # required on EVERY job, or it is rejected
#SBATCH --job-name=<gate>
#SBATCH --partition=<from COMPUTE.md>
#SBATCH --cpus-per-task=<measured>
#SBATCH --mem=<measured>
#SBATCH --time=<measured × safety>
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err
#SBATCH --array=0-N%K                   # K = max concurrent
#SBATCH --mail-type=END,FAIL,TIME_LIMIT_90
#SBATCH --mail-user=rioszemm@kaust.edu.sa

CONDA_ENV="/ibex/user/$USER/conda-environments/<env>"
export PATH="$CONDA_ENV/bin:$PATH"      # NEVER `conda activate` on a compute node
module purge

echo "Host $(hostname) | Env $CONDA_ENV | Python $(which python)"
python -c "import <pkg1>, <pkg2>; print('imports ok')"   # fail loudly, in the log

python run.py --chunk "${SLURM_ARRAY_TASK_ID}" --total "${SLURM_ARRAY_TASK_COUNT}"
```

`%x` job name · `%j` job ID · `%A` array job ID · `%a` task index.

## 4 · Submit, and capture the ID

```bash
JOB_ID=$(ssh $IBEX "cd <dir> && sbatch --parsable run.slurm")
echo "$JOB_ID"    # --parsable returns the bare id and nothing else
```

Record the job ID in `PLAN.md` and later in `PROVENANCE.md`. **A run with no job ID cannot
be sized from, accounted for, or reproduced.**

**Dependencies join with COLONS, never commas** — a comma creates separate independent
conditions, which is not "all of these":

```bash
DEPENDENCY="afterok:$(IFS=:; echo "${JOB_IDS[*]}")"
```

`afterok:ID` succeeded · `afterany:ID` regardless · `afternotok:ID` failed · `singleton` one
at a time. Depend on a whole array with `afterok:<ARRAY_JOB_ID>`, **no task suffix**.

⚠️ **`--wrap` escaping:** submit-time variables expand as `$VAR`; runtime variables must be
escaped `\$VAR`. An unescaped `$SLURM_ARRAY_TASK_ID` expands to empty at submit time and
**every task silently runs chunk 0.**

## 5 · Watch

```bash
ssh $IBEX 'squeue -u rioszemm -o "%.10i %.14j %.10P %.4C %.10m %.11M %.8T %R"'
ssh $IBEX 'scancel <JOB_ID>'          # or <JOB_ID>_[0-15] for array tasks
```

⛔ **Do not poll in a loop from a session.** Submit, record the ID, and end the turn. Check
on the next wake or when the mail arrives.

## 6 · Collect and validate by CONTENT (EVIDENCE_STANDARDS §1)

```bash
scp -r $IBEX:/ibex/user/rioszemm/experiments/<gate>/results ./ARIS_OUTPUT/<gate>/
```

⚠️ **Exit code 0 and "the file exists" are NOT enough.** A tool exits 0 while writing 0
bytes, and a failed earlier run leaves artefacts a later run happily reuses. Check bytes,
parseability, expected record count, and an asserted invariant. **Then count the array tasks
that actually produced output** — a partially failed array looks like a successful one from
`squeue`, and `n_attempted / n_succeeded / n_dropped` is required in the bundle README.

## 7 · Record

Append to the gate's `EXPERIMENT_LOG.md`: job ID, partition, requested vs used
(`seff`), wall time, n_attempted/n_succeeded/n_dropped, and what the next job should request
instead. That last field is what makes the next gate cheaper.

## Known failure modes — all seen on this cluster

1. Missing log directory → **silent failure.** SLURM will not create it.
2. `conda activate` on a compute node → does not work. Export `PATH`.
3. Missing `--account=pi-hohndor` → **rejected, every time.**
4. Commas in a dependency string → independent conditions, not "all of these".
5. Unescaped `$SLURM_ARRAY_TASK_ID` in `--wrap` → every task runs chunk 0.
6. The `vscode.ibex` round-robin pool hangs at userauth → use a stable login node.
7. `module avail` empty where software is installed → preflight imports instead.
