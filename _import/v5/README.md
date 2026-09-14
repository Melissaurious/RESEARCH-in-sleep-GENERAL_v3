# RESEARCH-in-sleep-GENERAL

Master source of shared context, resources, and conventions for all sleep-research
sub-projects. Each sub-project keeps a short `CLAUDE.md` that declares only its
specifics and points back here.

## Layout
- `CLAUDE.md` — AI-facing master context (short; links to everything below).
- `compute/` — hardware, partitions, SSH/remote how-to, live-snapshot scripts.
  - `resources.md` — borg + Ibex reference + active-projects table.
  - `REMOTE_IBEX.md` — how to run/submit on Ibex from borg over SSH.
  - `refresh_resources.sh` — run ON Ibex to snapshot live resources.
  - `refresh_resources_remote.sh` — run FROM borg; SSHes in and pulls the snapshot.
  - `ibex_resources.md` — *generated*, gitignored.
- `specs/` — how work should be done.
  - `WORKING_AGREEMENT.md` — editing/debugging/workflow/context rules.
  - `TOOLING.md` — Claude Code models, reviewer MCP, ARIS, env policy.
  - `LAUNCHER_TEMPLATE.md` — per-stage launcher scaffold.
- `templates/` — copy-and-fill boilerplate (SLURM patterns, header, working example).
- `projects/` → `CLAUDE_STUB_TEMPLATE.md` — copy into each sub-project as its CLAUDE.md.
- `retros/` — one `YYYY-MM-DD.md` per session; lessons get promoted into WORKING_AGREEMENT.
- `tools/` — helper scripts (e.g. `inspect_scripts.py`).

## Refresh live Ibex state
```bash
# from borg (recommended):
bash compute/refresh_resources_remote.sh
# or, already on Ibex:
bash compute/refresh_resources.sh
```

## Starting a new sub-project
1. Copy `projects/CLAUDE_STUB_TEMPLATE.md` → `<new-project>/CLAUDE.md`.
2. Fill in env name, project root, borg GPU, active task.
3. Everything else is inherited by reference from this folder.