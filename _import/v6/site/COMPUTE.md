# SITE — compute

Parameters for **this installation**. Nothing here is an agreement: the rules that
use these values live in `agreements/WORKING_AGREEMENT.md` § K and do not name a
machine. A second installation replaces this file and changes no rule.

## Machines

| Name | Role | Notes |
|------|------|-------|
| `borg` | local workstation | interactive work, streaming passes over large files, smoke tests |
| Ibex | university cluster, SLURM | queued GPU work, anything long or large |

`borg` carries no SLURM client and does not mount `/ibex`: every scheduler command runs
on the cluster, over SSH. **How to reach it, submit, size, monitor and read a job back:
`site/IBEX.md`.** This file keeps the thresholds and the account; that one has the
mechanics.

## Escalation thresholds (WA-K.1)

A job goes to the cluster when **any** of these holds:

- expected wall-clock > 2 hr
- needs > 24 GB VRAM
- an exact pass (WA-D.2 census) does not fit in local RAM

Never downgrade a census to a sample in order to stay local. Moving the job is the
correct response; changing the measurement is not.

## Queue

    #SBATCH --account=pi-hohndor        # required on every Ibex job

Submit cheap gating jobs before large arrays (WA-K.5): fairshare is consumed by what
already ran, and requesting more GPUs lowers priority.

## Environments

**Never use the base conda environment.**

    # local
    conda activate <env>

    # cluster compute node
    export PATH=/ibex/user/<user>/conda-environments/<env>/bin:$PATH

Environment names in use, and what each is for, belong in this table. Fill it as
environments are actually used by a row — not in advance:

| Environment | Used for | First row that used it |
|-------------|----------|------------------------|
| `retron_tradicional` | Python 3.12.12. Streaming passes over D1 on `borg`; `matplotlib` 3.10.5 for figures; stdlib `gzip`/`hashlib`/`http.client` for the assembly reads on Ibex compute nodes. Present under the same name and the same interpreter version on **both** machines. | `r01e-cds-linkage-control` |

⚠ The name is not the pin (BS-8). `r01d-window-integrity` and `r01e-cds-linkage-control`
both landed `env_lock_sha256:`
`98562a8716556717ad34912b754307b10e186c6070c9d145b8861717265b2ad4` — the same content, so
the environment demonstrably did not drift between them. A future row that exports a
different hash under this name has a **different** environment, whatever the table says.

⚠ `borg`'s `/home/borg/miniconda3/envs/retron_tradicional` and Ibex's
`/ibex/user/rioszemm/conda-environments/retron_tradicional` are two installations that
happen to agree on the interpreter version. Only the `borg` one has been exported to an
`env.lock`; the Ibex side is pinned by nothing but this sentence.

## Recording the environment in a bundle (BS-8)

An environment **name** is not a pin. Every bundle carries the environment verbatim:

    conda env export --no-builds > results/<ROW>/env.lock
    sha256sum results/<ROW>/env.lock          # -> env_lock_sha256: in PROVENANCE.md

## Live resource state

Generated, not tracked — regenerate rather than trusting a stale copy:

    nvidia-smi                      # local accelerators
    sinfo -o '%P %a %l %D %G'       # cluster partitions
    squeue -u "$USER"               # own queue
    sacct -j <id> --format=Elapsed,MaxRSS,State    # after a run, for WA-K.3 sizing
