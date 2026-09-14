# SITE — tooling

Parameters for **this installation**. Nothing here is an agreement: the rules that use these
values live in `agreements/WORKING_AGREEMENT.md` and name no model.

## Author — Claude Code

**Default: Opus 5 (1M context), High effort.** Confirmed from `/model` on borg, 2026-09-14.

| use | `/model` entry |
|---|---|
| **default — everything unless stated** | **Opus (1M context)** — Opus 5, High effort |
| hardest / longest-running gates | Fable — Fable 5.1 |
| routine, mechanical | Sonnet 5 / Haiku 4.5 — only when the launcher says so |

Lowering effort is a decision recorded in `PLAN.md`, not a convenience: a gate planned badly
costs GPU-hours, not tokens.

```bash
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000
claude --dangerously-skip-permissions
```

## Reviewer — ARIS owns the routing

**Reviewer independence, score thresholds and the stop/continue/escalate transition belong
to ARIS** (ARIS's `review_gate.py`, `/auto-review-loop`): positive requires `score >= 6` and
verdict in `{ready, almost}`. This layer adds review; it never routes around it, substitutes
a same-family reviewer, or lowers a threshold to get a pass (WA-A.5).

Codex is available as an additional reviewer, and is a genuinely independent one:

```bash
codex exec --skip-git-repo-check -
```

**Verified on borg, 2026-09-14** — `codex exec` v0.151.0 answered the probe:

| property | observed | why it matters |
|---|---|---|
| model | `gpt-5.6-sol` (openai) | ⭐ a different provider — shares no training, priors or failure modes with the author |
| reasoning | `xhigh` | a review is the wrong place to economise |
| sandbox | `read-only` | ⭐ **cannot edit what it reviews.** A reviewer that can "just fix it" stops being one. |
| approval | `never` | runs unattended |

Reaching it needs `api.openai.com` in `sandbox.network.allow` — the scaffolded
`settings.json` has it.


## ARIS

Upstream methodology at `~/aris_repo` — *auto-research-in-sleep*. Installed, not vendored
(`LINEAGE.md`).

- **`mcp-servers/codex-exec/`** — the cross-model review bridge, as an MCP server.
- **ARIS's `review_gate.py`** — the deterministic stop/continue/escalate transition. This is
  what an earlier version of this layer wrongly duplicated in a shell script.
- **`skills/run-experiment-ibex/`** (in this layer) **overrides ARIS's generic
  `run-experiment`.** That one launches remote work over SSH + `screen`: no SLURM
  allocation, no job id to size from or account against, and it dies with the connection.
  Wrong for every job on this cluster. `new_project.sh` links it into `.claude/skills/`.
- **Other ARIS skills** — link the ~8 you use. Every skill's name and description is loaded into every
  session, so 82 linked skills is a standing tax on every prompt
  (`agreements/SESSION_HYGIENE.md`).

## Environment policy

**Never use the base conda environment.**

```bash
conda activate <env>                                              # borg
export PATH=/ibex/user/<user>/conda-environments/<env>/bin:$PATH  # cluster compute node
```
