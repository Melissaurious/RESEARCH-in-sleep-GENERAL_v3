---
name: experiment-routing-ibex
description: Route experiment execution to SLURM on this installation. Use whenever /experiment-bridge is about to dispatch a milestone and the target is Ibex — it overrides the default job-count routing, which sends small batches to /run-experiment and large ones to /experiment-queue, neither of which speaks SLURM. Triggers on experiment-bridge, experiment-queue, run-experiment, dispatch a milestone, gpu target, batch of jobs, Ibex, SLURM, cluster execution.
---

# Experiment routing on this installation

## The problem this exists to fix

`/experiment-bridge` routes each milestone **by job count**, automatically:

    <= 5 jobs                        -> /run-experiment
    >= 10 jobs, or phase dependencies -> /experiment-queue

Neither knows about SLURM. `/run-experiment` targets local, vast and modal hosts;
`/experiment-queue` is built for SSH GPU servers and drives jobs with `screen`.

⛔ **On Ibex both are wrong, and `/experiment-queue` is the more dangerous of the two**: a
`screen` session on a login node holds no allocation, bypasses the scheduler, dies with the
connection, produces no job ID, and will get the account noticed by the cluster admins.

**Naming a skill `run-experiment-ibex` does not override `/run-experiment`.** It is a
different skill, and nothing calls it unless routing sends it there. That routing is this
skill's only job.

## The rule

    if the milestone's target is Ibex  (site/COMPUTE.md thresholds, or the plan says so):
        ALL execution  ->  /run-experiment-ibex     regardless of job count
            <= 5 jobs      -> individual sbatch submissions
            >= 10 jobs     -> a SLURM ARRAY  (--array=0-N%K), not a submit loop
            phase deps     -> --dependency=afterok:<ARRAY_JOB_ID>, colons never commas
    else:
        keep upstream ARIS behaviour unchanged

⛔ `/experiment-queue` never runs against Ibex. If routing would send it there, stop and
re-route; do not "just this once" it.

## Deciding the target

```bash
python general/tools/dispatch.py --est-minutes <n> [--gpu --vram <gb>] --explain
```

It prints an auditable reason. Paste that into `EXPERIMENT_PLAN.md`. Escalation thresholds
(> 2 hr wall-clock, > 24 GB VRAM, a census that will not fit in local RAM) are in
`general/site/COMPUTE.md`. **Never downgrade a census to a sample to stay local.**

## Why arrays rather than a submit loop at scale

One job ID instead of N, less scheduler load, and `%K` throttling so a sweep does not
consume the whole fairshare allocation at once. A submit loop is right only when resources
genuinely differ per input.

⚠️ **Requesting more GPUs lowers queue priority**, and **cheap gating jobs go in before
large arrays** — fairshare is spent by what already ran, so a big array launched first
prices a small gating job out of the queue behind `Priority`.

## Then hand back

`/run-experiment-ibex` reads `EXPERIMENT_PLAN.md`, runs the preflight and smoke sizing,
submits, validates outputs **by content**, and appends `EXPERIMENT_LOG.md`. After that the
milestone is ARIS's again — `/experiment-bridge` continues, and result acceptance stays with
ARIS's own review chain.
