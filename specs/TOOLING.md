# TOOLING — Claude Code, Reviewer, ARIS

_Environment/tooling config extracted from the old CLAUDE_TEMPLATE. Referenced by the
master CLAUDE.md; not needed every turn._

## Environment policy
- **NEVER use the base conda environment.**
- Local (borg): `conda activate $ENV`
- Ibex (compute nodes): `export PATH=/ibex/user/rioszemm/conda-environments/$ENV/bin:$PATH`
- ⚠️ On Ibex, `module avail` can be empty even when software is installed, and conda deps
  usually live under `envs/<name>` rather than the base install. Put a one-line import
  preflight in every sbatch script so a failure names itself.
- Common Ibex envs: retron_tradicional, retron_design, retron_engineering, progen3,
  progen3_clean, esm_ezy, rinalmo, rna_fm, diffab (full live list: `compute/ibex_resources.md`).


## Claude Code config
_Model line as of 2026-09-14. ⚠️ Verify against `/model` before trusting this list — it is
the field most likely to go stale, and the previous version pinned models that no longer
exist (`claude-sonnet-4-6`, `claude-opus-4-8`)._

| Use | Model | ID |
|---|---|---|
| Planning, stage design, adversarial work | Opus 5 | `claude-opus-5` |
| Routine execution | Sonnet 5 | `claude-sonnet-5` |
| Cheap mechanical passes | Haiku 4.5 | `claude-haiku-4-5-20251001` |

- Reasoning effort (if this build supports it — check `/model` or `/config`):
  planning → high · routine execution → medium · mechanical edits → low
- Launch with: `--dangerously-skip-permissions`
- Before launch: `export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000`

## Adversarial reviewer — codex
The reviewer for both gates in `specs/ADVERSARIAL_REVIEW.md`. It must be a **different
model family** from the author: a reviewer sharing the author's priors agrees with them,
which is the code equivalent of `EVIDENCE_STANDARDS.md` §4 — *two methods agreeing is
evidence only if they can disagree.*

```bash
# invocation used by tools/adversary.py — one line, edit here and nowhere else
export RSG_REVIEW_CMD="codex exec --skip-git-repo-check -"
```

- Driver: `tools/adversary.py` — assembles the packet, calls the reviewer, writes the
  verdict into `ARIS_OUTPUT/<STAGE_ID>/review-stage/`.
- The packet **withholds** the conversation, the agent's justifications, and any prior
  `PASS`. See `ADVERSARIAL_REVIEW.md` §1.
- `adversary.py` **probes the reviewer by execution** before trusting it
  (`EVIDENCE_STANDARDS.md` §2). Installed-but-failing is `PRESENT_BUT_BROKEN` and does not
  count as a pass. Record the grade; never treat a missing reviewer as a clear gate.

_(The old `llm-chat` MCP / `gemini-2.5-flash` / `/auto-review-loop-llm` setup is
superseded. A different reviewer is fine — the spec is reviewer-agnostic — but it must be
recorded here, and it must not be the model that wrote the work.)_

## ARIS
- Repo: `~/aris_repo`
- Install / update: `bash ~/aris_repo/tools/install_aris.sh`
- Auto-generated project context is injected between these markers in a project CLAUDE.md:
  ```
  <!-- ARIS:BEGIN -->
  <!-- ARIS:END -->
  ```
  Do not hand-edit inside the markers — that region is managed by ARIS.
