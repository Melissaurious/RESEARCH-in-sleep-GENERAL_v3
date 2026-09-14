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

Submit cheap gating jobs before large arrays (WA-K.1): fairshare is consumed by what
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
    sacct -j <id> --format=Elapsed,MaxRSS,State    # after a run, for WA-K.1 sizing

---

## Finding a dependency — sweep both machines before concluding it is missing (WA-K.2)

A package is far more often in *another* environment than genuinely absent. Installing to
work around a sweep you did not do is how an env drifts and earlier results stop reproducing.

```bash
# ── borg: what environments exist, and which hold the package ────────────────
conda env list
for e in $(conda env list | awk '/^[a-zA-Z]/{print $1}' | grep -v '^base$'); do
  p="$HOME/miniconda3/envs/$e/bin/python"
  [ -x "$p" ] && out=$("$p" -c "import <pkg>; print(getattr(<pkg>,'__version__','?'))" 2>/dev/null) \
    && printf '  %-24s %s\n' "$e" "$out"
done

# ── borg: a command-line tool, not a python package ──────────────────────────
for e in $HOME/miniconda3/envs/*/bin/<tool>; do [ -x "$e" ] && echo "$e"; done

# ── Ibex: the same sweep over the cluster's envs ─────────────────────────────
ssh $IBEX 'ls -1 /ibex/user/$USER/conda-environments/'
ssh $IBEX 'for e in /ibex/user/$USER/conda-environments/*/bin/python; do
             printf "%-60s " "$e"; "$e" -c "import <pkg>; print(\"ok\")" 2>/dev/null || echo "-" ; done'

# ── Ibex: modules ────────────────────────────────────────────────────────────
ssh $IBEX 'module avail <keyword> 2>&1 | head -40'
ssh $IBEX 'module spider <keyword> 2>&1 | head -40'    # finds what `avail` hides
```

⚠️ **`module avail` can come back empty where the software is installed** — it reflects the
modules visible to the current hierarchy, not what exists. `module spider` searches all of
them. And conda dependencies usually live under a named env rather than the base install.

⚠️ **Presence is not capability.** A package that imports can still fail on real input
(`EVIDENCE_STANDARDS` §2): run it on real project data and record the grade — `VERIFIED`,
`WORKAROUND_VERIFIED` (with the flag), `PRESENT_BUT_BROKEN`, `DATA_INADEQUATE`, or `ABSENT`.
**`ABSENT` is only honest after the full sweep above.**

### If it really is absent

1. Say so in `PLAN.md`, with the sweep output.
2. Prefer a **new** env over mutating a shared one. `retron_tradicional` is used by earlier
   results; adding to it silently changes what those results would reproduce as.
3. Never the base environment.
4. Record the env name and the exact install command in the bundle's `env.lock`.
