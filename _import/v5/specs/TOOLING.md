# TOOLING — Claude Code, Reviewer, ARIS

_Environment/tooling config extracted from the old CLAUDE_TEMPLATE. Referenced by the
master CLAUDE.md; not needed every turn._

## Environment policy
- **NEVER use the base conda environment.**
- Local (borg): `conda activate [ENV_NAME]`
- Ibex (compute nodes): `export PATH=/ibex/user/rioszemm/conda-environments/[ENV_NAME]/bin:$PATH`
- Common Ibex envs: retron_tradicional, retron_design, retron_engineering, progen3,
  progen3_clean, esm_ezy, rinalmo, rna_fm, diffab (full live list: `compute/ibex_resources.md`).


## Claude Code config
- Default model: `claude-sonnet-4-6`
- Overnight / heavy runs: `claude-opus-4-8`
- Reasoning effort (if supported by this build — verify with /model or /config):
  - Planning / stage design → high
  - Routine execution → medium
  - Simple mechanical edits → low
- Launch with: `--dangerously-skip-permissions`
- Before launch: `export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000`



## Reviewer (cross-model, load-bearing)
- MCP: `codex` (ChatGPT subscription, no API key). Register:
  `claude mcp add codex -- codex mcp-server`
- Reasoning effort pinned in `~/.codex/config.toml`: `model_reasoning_effort = "xhigh"`
- Use `/auto-review-loop` (NOT `-llm`, that path is for OpenAI-compatible APIs)
- The reviewer must be a different model family from the executor. If Codex is
  unreachable, a skill must FAIL, never self-review. A loop may DRIVE, it may
  never ACQUIT.
- Codex is for the seven heavyweight verdicts only: /kill-argument,
  /research-review, /experiment-audit, /result-to-claim, /paper-claim-audit,
  /citation-audit, /integrity-forensics. Routine work runs on Claude alone.

## ARIS
- Repo: `~/ARIS_CODE`
- Install into a project: `cd <project> && bash ~/ARIS_CODE/tools/install_aris.sh
  --groups lit-search,ideation,review-loop,experiments,paper-core,meta-utils`
- Update: `cd ~/ARIS_CODE && git pull && bash tools/smart_update.sh --apply`
- Skills are project-local (`<project>/.claude/skills`), not global.

## Model policy
- Planning, stage design, Phase B interpretation, reading results → **Opus 5** (high effort)
- Execution: scripts, running, patching, mechanical edits → **Sonnet 5**
- Declared per stage in the launcher's `Model:` field. Switch in-session with `/model`.
- Use plain Opus 5, not the 1M-context variant, unless a stage genuinely needs it.
- Re-verify names with `/model` after any Claude Code update.

## Reviewer (cross-model, load-bearing)
- MCP: `codex` (ChatGPT subscription). Registered globally:
  `claude mcp add codex -s user -- codex mcp-server`
- codex CLI installed user-level via nvm (Node 22). Requires Node >= 20 and
  codex-cli >= 0.144.1. NOT in a conda env — works from any shell.
- `~/.codex/config.toml`: model = "gpt-5.6-sol", model_reasoning_effort = "xhigh"
- Verify: `codex --version`, `codex login status`, then in Claude Code ask codex to
  identify itself. A GPT-family answer is the pass condition.
- Use `/auto-review-loop` (NOT `-llm`). If codex is unreachable a skill must FAIL,
  never self-review. A loop may DRIVE, it may never ACQUIT.
- Codex is reserved for seven verdicts: /kill-argument, /research-review,
  /experiment-audit, /result-to-claim, /paper-claim-audit, /citation-audit,
  /integrity-forensics. Everything else runs on Claude alone.

## ARIS
- Repo: `~/ARIS_CODE`
- Install into a project: `cd <project> && bash ~/ARIS_CODE/tools/install_aris.sh --groups ...`
- Update: `cd ~/ARIS_CODE && git pull && bash tools/smart_update.sh --apply`
- Skills are project-local (`<project>/.claude/skills`), not global.
- Auto-generated ARIS context sits between `<!-- ARIS:BEGIN -->` / `<!-- ARIS:END -->`
  in a project CLAUDE.md. Never hand-edit inside those markers.