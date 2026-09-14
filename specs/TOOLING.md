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

## Reviewer config
- MCP: `llm-chat` (Gemini `gemini-2.5-flash`)
- Use `/auto-review-loop-llm` (not `/auto-review-loop`)

## ARIS
- Repo: `~/aris_repo`
- Install / update: `bash ~/aris_repo/tools/install_aris.sh`
- Auto-generated project context is injected between these markers in a project CLAUDE.md:
  ```
  <!-- ARIS:BEGIN -->
  <!-- ARIS:END -->
  ```
  Do not hand-edit inside the markers — that region is managed by ARIS.
