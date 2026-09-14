# SITE — Ibex

Mechanics for **this installation's** cluster: how to reach it, submit, size, monitor,
and read a job afterwards. Nothing here is an agreement. The rules that use these
values live in `agreements/WORKING_AGREEMENT.md` § K and name no machine; a second
installation replaces this file and changes no rule.

Split with `site/COMPUTE.md`, which is the entry point and keeps:

- the **escalation thresholds** (WA-K.1) — when a job leaves `borg` at all;
- `--account=pi-hohndor`, and the WA-K.1 note on submission order;
- environment activation and `env.lock` for a bundle (BS-8);
- the live-state one-liners.

This file is the **how**. It does not restate those, and it does not restate § K —
where a rule governs a step, the step names the rule and stops there.

## Verification legend

| mark | meaning |
|---|---|
| ⚠ | **transcribed from GENERAL_v5, not re-verified.** Written down from `/home/borg/RESEARCH-in-sleep-GENERAL_v5/{compute,templates}/` on 2026-09-06. Not executed against the cluster from here. |
| ✔ | exercised on 2026-09-06 — either checked from `borg` by the command shown, or run on Ibex over SSH by `sidework/cds-linkage` (jobs 51398870, 51398871, 51399369, 51399374) |

`borg` has **no SLURM client at all** — `sbatch`, `squeue`, `sinfo`, `sacct`, `seff`,
`srun`, `scancel`, `sacctmgr` and `module` are all absent, and `/ibex` is not mounted (✔
`command -v`, `ls -d /ibex`). Every scheduler command below therefore runs **on Ibex**,
over SSH.

A first smoke test has now run — four jobs, described under *What would move the pin*.
It contradicted nothing and turned a number of ⚠ lines into ✔. A substantial ⚠ set
remains, and the submodule pin has still not been moved.

---

## 1 · Reaching the cluster

    ssh rioszemm@ilogin.ibex.kaust.edu.sa

✔ `ilogin.ibex.kaust.edu.sa` resolves from `borg` to **10.109.65.7** and **10.109.65.8**
(`getent hosts`). Two A records — the name is itself a small pool.
✔ Key-based auth works: `ssh -o BatchMode=yes rioszemm@ilogin.ibex.kaust.edu.sa`
succeeded on 2026-09-06 (login node `login509-02-l`). BatchMode disables password auth
outright, so a successful login proves the key. Exercised by `sidework/cds-linkage`.

⚠ **Do not use `vscode.ibex.kaust.edu.sa` for scripted access.** It is a load-balanced
round-robin pool and at least one member hangs at SSH userauth — TCP and key exchange
succeed, the host key matches, then the server never replies. It looks like an account
problem and is a sick node.
✔ Corroborated today: `vscode.ibex.kaust.edu.sa` resolves to **10.109.65.170** and
**10.109.65.13** — the same two addresses the GENERAL_v5 note names, with `.13` the one
recorded hanging on 2026-07-26 and `.170` healthy minutes later.

One-off remote command, staying on `borg`:

    ssh rioszemm@ilogin.ibex.kaust.edu.sa 'squeue -u rioszemm'
    ssh rioszemm@ilogin.ibex.kaust.edu.sa 'sinfo -p gpu24 -o "%N %G %t"'

Run a script that lives on `borg`, on Ibex, output back to `borg`:

    ssh rioszemm@ilogin.ibex.kaust.edu.sa 'bash -s' < local_script.sh > result.txt

⚠ Optional `~/.ssh/config` alias on `borg`, so `ssh ibex` / `scp file ibex:/path/` work:

    Host ibex
        HostName ilogin.ibex.kaust.edu.sa
        User rioszemm
        IdentityFile ~/.ssh/<key>
        ServerAliveInterval 60

Interactive compute node — CPU, then GPU:

    srun --account=pi-hohndor --nodes=1 --ntasks-per-node=1 \
         --cpus-per-task=8 --time=01:00:00 --pty /bin/bash

    srun --account=pi-hohndor --gres=gpu:v100:1 --cpus-per-task=4 \
         --mem=48G --time=02:00:00 --partition=gpu4 --pty /bin/bash

## 2 · Where things live ⚠

⚠ Paths not marked ✔ are still transcribed. `/ibex` is not mounted on `borg`; the ✔
marks were earned over SSH on 2026-09-06 by `sidework/cds-linkage`, which used the
**project** tree (`/ibex/project/c2366/RETRONS/...`) and so did not touch
`/ibex/user/rioszemm/experiments/` or its `logs/`.

| what | path |
|---|---|
| user | `rioszemm` ✔ |
| account | `pi-hohndor` (COMPUTE.md) ✔ — four jobs accepted 2026-09-06 |
| mail | `rioszemm@kaust.edu.sa` |
| conda environments | `/ibex/user/rioszemm/conda-environments/` ✔ |
| experiments base | `/ibex/user/rioszemm/experiments/` |
| logs base | `/ibex/user/rioszemm/experiments/logs/` |
| QOS | `normal` — ⚠ max 1300 concurrent jobs, no per-user CPU/GPU/time cap |

⚠ Environments reported present on Ibex on 2026-07-27: `boltzgen`, `dep_maps`, `diffab`,
`dymean`, `esm_ezy`, `esmologs`, `eva_env`, `fastani_env`, `ml-gpu-env`, `padloc2`,
`progen3`, `progen3_clean`, `progen3-dev`, `retron_design`, `retron_engineering`,
`retron_tradicional`, `rinalmo`, `rna_fm`, `rnaseq`, `zhmolgraph`. That list is a
snapshot, not a contract — re-list it (§8) rather than trusting it. Which environment a
row uses, and its `env.lock`, are COMPUTE.md's table and BS-8, not this file's.

**Create the log directory before submitting.** SLURM does not `mkdir` its own output
path, and a missing directory fails the job silently:

    ssh rioszemm@ilogin.ibex.kaust.edu.sa 'mkdir -p /ibex/user/rioszemm/experiments/logs/<row>'

## 3 · The job header

⚠ Transcribed from `/home/borg/RESEARCH-in-sleep-GENERAL_v5/templates/ibex_header.sh`
(external to this repository, named and not copied) — except the `export PATH` line, which
is ✔: a compute node in job 51398871 reported
`python=/ibex/user/rioszemm/conda-environments/retron_tradicional/bin/python`.
No `module` line has been exercised. Copy the `#SBATCH` block, then add the
job-specific lines under it.

    #!/bin/bash
    set -euo pipefail

    #SBATCH --account=pi-hohndor
    #SBATCH --mail-type=END,FAIL,TIME_LIMIT_90
    #SBATCH --mail-user=rioszemm@kaust.edu.sa

    # Environment: export PATH, never `conda activate` on a compute node.
    CONDA_ENV="/ibex/user/$USER/conda-environments/<env>"
    export PATH="$CONDA_ENV/bin:$PATH"

    module purge                       # always purge first
    # module load cuda/12.2
    # module load mmseqs2/14.7e284

    # Name the harness in the log, and fail loudly if an import is missing (WA-K.1).
    echo "Host $(hostname) | Env $CONDA_ENV | Python $(which python)"
    python -c "import <pkg1>, <pkg2>; print('imports ok')"

⚠ Modules seen available: `gcc/12.2.0`, `gcc/15.2.0`, `mmseqs2/14.7e284`, `esm/1.0.3`;
CUDA `11.7.1`, `11.8`, `12.1`, `12.2`, `12.4.1`. Discover with `module avail <keyword>`,
and verify the exact string before loading it — a version that has moved fails the job
at the top.

## 4 · Submitting

⚠ All four shapes transcribed from
`/home/borg/RESEARCH-in-sleep-GENERAL_v5/templates/slurm_templates.md` (external to this
repository, named and not copied).

**Single job** ✔ (job 51399374, via `sbatch --wrap`). `%x` = job name, `%j` = job ID,
`%a` = array task index; `%A_%a` ✔ produced `diag_51398871_0.out`.

    sbatch --account=pi-hohndor --job-name="<row>_<step>" \
        --cpus-per-task=4 --mem=16G --time=02:00:00 \
        --output="logs/%x_%j.out" --error="logs/%x_%j.err" \
        --wrap="
    export PATH=$CONDA_ENV/bin:\$PATH
    python my_script.py --input data.fasta --output results/
    "

**Array** ✔ (`--array=0-2`, job 51398871). The right shape when one script splits work by task index. Preferred over a
submit loop when the script is identical per chunk: less scheduler load, one job ID, and
`%` throttling.

    #SBATCH --array=0-15%4            # 16 tasks, at most 4 running at once
    #SBATCH --output=logs/task_%A_%a.out   # %A = array job ID, %a = task index

    python predict.py --chunk ${SLURM_ARRAY_TASK_ID} \
                      --total-chunks ${SLURM_ARRAY_TASK_COUNT}

    #SBATCH --array=0-99        #SBATCH --array=0-99%10
    #SBATCH --array=1,3,5,7     #SBATCH --array=0-15:2      # step of 2

**Submit loop** — use instead of an array when resources differ per input. Collect IDs
with `--parsable` ✔ (returned bare `51398871`), which returns the job ID and nothing else:

    JOB_IDS=()
    JOB_ID=$(sbatch --parsable --account=pi-hohndor ... --wrap="...")
    JOB_IDS+=("$JOB_ID")

**Dependency.** Job IDs are joined with **colons**, never commas — a comma creates
separate independent conditions, which is not the same thing:

    DEPENDENCY="afterok:$(IFS=:; echo "${JOB_IDS[*]}")"
    sbatch --account=pi-hohndor --dependency="$DEPENDENCY" ... --wrap="..."

| string | meaning |
|---|---|
| `afterok:ID` | run only if that job succeeded |
| `afterany:ID` | run regardless of exit status |
| `afterok:ID1:ID2:ID3` | wait for **all** listed jobs to succeed |
| `afternotok:ID` | run only if that job failed |
| `singleton` | one job of this name at a time |

⚠ Depend on a whole array with `--dependency=afterok:<ARRAY_JOB_ID>`, no task suffix.

**Escaping in `--wrap`:** submit-time variables expand as `$VAR`; runtime variables must
be escaped, `\$VAR` — e.g. `\$SLURM_ARRAY_TASK_ID`.

## 5 · Partitions ⚠

⚠ Transcribed. Times are the stated maxima, not measured.

| partition | max time | GPU types | for |
|---|---|---|---|
| `debug` | 2 hr | v100, p6000 | the WA-K.1 harness check — ✔ schedules; ⚠ **not CPU-only**: it allocated the GPU node `gpu510-32` on 2026-09-06 |
| `gpu4` | 4 hr | a100 ×4/×8, v100, p100, gtx_1080_ti | quick tests, short jobs |
| `gpu24` | 24 hr | a100 ×4, v100 ×8 ✔ (`sinfo -p gpu24`) | most runs |
| `gpu72` | 3 days | a100 ×4, v100 ×8 | multi-day |
| `gpu` | 14 days | a100, v100, h200, p100, p6000, gtx | long runs |
| `gpu_wide` | 14 days | a100 ×8, v100 ×8 | multi-node / multi-GPU |
| `gpu_wide24` | 24 hr | a100 ×8, v100 ×8 | short multi-GPU |
| `gpu_wide72` | 3 days | a100 ×8 | mid-length multi-GPU |
| `largemem` | 14 days | CPU only, up to 16 TB | large-memory CPU |
| `batch` | 14 days ✔ (`sinfo -p batch -o "%P %l"` → `14-00:00:00`) | CPU only | general CPU |

⚠ Rough inventory as of 2026-07-27: ~50+ A100 4-GPU nodes and ~8 A100 8-GPU nodes;
~15 V100 8-GPU and ~6 V100 4-GPU nodes; **one** 8× H200 node on `gpu` (feature
`gpu_h200`); older P100 / P6000 / GTX 1080 Ti / RTX 2080 Ti in limited numbers.
Multiple GPUs on one node: `--gres=gpu:a100:4`.

⚠ Starting points, to be replaced by a measurement (WA-K.1), not used as an answer:
heavy GPU `--partition=gpu24 --gres=gpu:a100:1`; quick test
`--partition=gpu4 --gres=gpu:v100:1`.

## 6 · Preflight and sizing — the mechanics

The rules are WA-K.1 (validate the harness interactively before queuing), WA-K.1 (size
from measured per-unit rate × N), WA-K.1 (representative smoke sample) and WA-K.1
(cheap gating jobs before large arrays). They are not restated here. What this
installation runs to satisfy them:

    # WA-K.1 — ~60 s on debug, before anything is queued
    srun --account=pi-hohndor --cpus-per-task=4 --mem=8G \
         --time=00:20:00 --partition=debug --pty bash -i
    /ibex/user/$USER/conda-environments/<env>/bin/python -c "import <pkg>; print('ok')"
    ls <run_script>

    # WA-K.1 — after the smoke job, read the real per-unit cost off the finished job
    sacct -j <JOB_ID> --format=JobID,Elapsed,MaxRSS,State,ReqTRES%40
    seff <JOB_ID>

✔ Both run. `seff 51398871_1` on 2026-09-06 returned `Memory Utilized: 5.31 GB`,
`Memory Efficiency: 16.58% of 32.00 GB`, `CPU Efficiency: 20.28%` — i.e. the request was
4x too large on memory, which is the number WA-K.1 wants and `sacct` alone does not give.
✔ The `srun --partition=debug` preflight above ran as job 51398870.

⚠ The GENERAL_v5 source pairs WA-K.1 with a note that a module listing can come back
empty even when the software is installed, and that dependencies usually live under a
named environment rather than the base install — which is why the import preflight goes
**inside** the batch script as well as in the interactive session.

## 7 · Watching a job, and reading it afterwards

    squeue -u rioszemm
    squeue -u rioszemm -t PENDING
    squeue -u rioszemm -o "%.10i %.14j %.10P %.5D %.4C %.10m %.11l %.11M %.8T %R"
    squeue -u rioszemm -o "%i %j %P %b %T" | grep -i gpu

    scancel <JOB_ID>
    scancel <JOB_ID>_[0-15]           # array tasks 0–15
    scancel -u rioszemm               # everything you have queued

    sacct -j <JOB_ID> --format=JobID,Elapsed,MaxRSS,State,ReqTRES%40
    seff <JOB_ID>
    sinfo -p gpu24 -o "%N %G %t"

`sacct`/`seff` after the run are what WA-K.1 sizes the next job from, and COMPUTE.md
already names `sacct -j <id> --format=Elapsed,MaxRSS,State` for that purpose.

## 8 · Live resource state

⚠ Two scripts exist in GENERAL_v5. They are **not** in this repository and are named,
not copied — a snapshot regenerated on demand beats a stale one committed here:

    /home/borg/RESEARCH-in-sleep-GENERAL_v5/compute/refresh_resources.sh          # runs ON Ibex
    /home/borg/RESEARCH-in-sleep-GENERAL_v5/compute/refresh_resources_remote.sh   # runs FROM borg

⚠ `refresh_resources.sh` guards on `command -v sinfo` and exits with a message if run
anywhere but Ibex. `refresh_resources_remote.sh` SSHes in, runs it there, and writes the
report back — writing to a **temp file and promoting only on success**, because
redirecting straight at the output file truncates it before `ssh` even runs, and any
failure then destroys the previous snapshot. That is how the 2026-07-26 snapshot was
lost. If a refresh fails, the previous one is left intact.

What it collects, if you want the commands without the script:

    sinfo -o "%P %G %D %t" --noheader | grep -i gpu | sort
    sinfo -o "%P %G %D %t" --noheader | grep -i gpu | awk '$4 ~ /idle/'
    sacctmgr show assoc where user="$USER" format=Account,QOS,MaxJobs,MaxSubmit --noheader
    squeue -u "$USER" -o "%.10i %.14j %.10P %.5D %.4C %.10m %.11l %.11M %.8T %R"
    ls -1 "/ibex/user/$USER/conda-environments/"

## 9 · Moving data

⚠ Transcribed.

    # borg → Ibex
    rsync -avP ./data/ rioszemm@ilogin.ibex.kaust.edu.sa:/ibex/user/rioszemm/experiments/data/
    scp my_job.slurm rioszemm@ilogin.ibex.kaust.edu.sa:/ibex/user/rioszemm/experiments/

    # submit it there
    ssh rioszemm@ilogin.ibex.kaust.edu.sa \
        'cd /ibex/user/rioszemm/experiments && sbatch my_job.slurm'

    # Ibex → borg
    rsync -avP rioszemm@ilogin.ibex.kaust.edu.sa:/ibex/user/rioszemm/experiments/results/ \
          ./ARIS_OUTPUT/<row>/

`rsync` over `scp` for anything large: it resumes. Results land in `ARIS_OUTPUT/<row>/`
(scratch, gitignored) — what becomes a number moves to `results/<ROW>/` through the
bundle, per WA-B.1, and not directly off the cluster.

## 10 · Known failure modes ⚠

⚠ All transcribed from GENERAL_v5; none reproduced from here.

1. **Missing log directory = silent failure.** SLURM will not create the `--output`
   path. `mkdir -p` it first (§2).
2. **`conda activate` does not work on a compute node.** Export `PATH` (§3).
3. **`--account=pi-hohndor` missing = job rejected**, every time (COMPUTE.md).
4. **Commas in a dependency string** create independent conditions instead of "all of
   these" (§4).
5. **`--wrap` escaping**: an unescaped `$SLURM_ARRAY_TASK_ID` expands at submit time to
   empty, and every task runs chunk 0.
6. **The `vscode.ibex` pool hangs at userauth** on at least one member (§1).
7. **A truncating refresh destroys the snapshot it failed to replace** (§8).
8. **`module avail` can come back empty** even where the software is installed (§6).

## What would move the pin

**Partly proven, 2026-09-06.** `sidework/cds-linkage` ran four real jobs through this
file: a `debug` preflight (51398870), a 3-task array (51398871), a resubmit (51399369)
and a single `--wrap` job (51399374). That exercised §1 login, §2 the conda path and the
account, §3 `export PATH`, §4 all three submission shapes plus `--parsable` and `%A_%a`,
§5 `batch`/`debug`/`gpu24`, §6 the WA-K.1 preflight and `seff`, §7 `squeue`/`sacct`/`seff`,
and §9 `scp` in both directions. **Nothing in this file was contradicted.**

Still unproven, and still ⚠: `/ibex/user/rioszemm/experiments/` and its `logs/` (that run
used the project tree); every `module` claim including the CUDA and mmseqs2 versions; job
dependencies; `rsync`; array `%` throttling; the QOS 1300-job cap; the `vscode.ibex` hang;
the `~/.ssh/config` alias; and every GPU partition beyond `gpu24`'s listed types.

One correction found, folded in above: **`debug` is not CPU-only** — it allocated a GPU
node.

Moving the `site/` pin in the superproject is still a deliberate commit with a decision
record. It is now defensible for the paths marked ✔; the operator decides whether the
remaining ⚠ set is small enough.
