# CLAUDE.md — [PROJECT NAME]

Project-specific context. All shared mechanics live in
`/home/borg/RESEARCH-in-sleep-GENERAL/` — read that master CLAUDE.md for compute,
job submission, working agreement, and tooling. This file declares only specifics.

## This project
- **Conda env:** `[ENV_NAME]`  (local: `/home/borg/miniconda3/envs/[ENV_NAME]`,
  Ibex: `/ibex/user/rioszemm/conda-environments/[ENV_NAME]`)
- **Project root:** `/home/borg/RESEARCH-in-sleep-[PROJECT]/`
- **borg GPU assignment:** `CUDA_VISIBLE_DEVICES=[0|1]`
- **Outputs:** `ARIS_OUTPUT/`
- **Active stage / task:** [what's happening right now]

## Shared references (do not duplicate — link)
- Behavior rules → `../RESEARCH-in-sleep-GENERAL/specs/WORKING_AGREEMENT.md`
- Compute + partitions → `../RESEARCH-in-sleep-GENERAL/compute/resources.md`
- SLURM patterns → `../RESEARCH-in-sleep-GENERAL/templates/slurm_templates.md`
- Tooling / models / ARIS → `../RESEARCH-in-sleep-GENERAL/specs/TOOLING.md`

## Project notes
[Anything unique to this project: data locations, quirks, current blockers.]

<!-- ARIS:BEGIN -->
<!-- ARIS:END -->
