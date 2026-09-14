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

## Reviewer — codex. **A different provider, and that is the point.**

`tools/review.sh` refuses to run when the reviewer and author share a family (WA-A.5).

```bash
export RSG_REVIEW_CMD="codex exec --skip-git-repo-check -"
export RSG_REVIEWER_FAMILY=openai        # author family defaults to anthropic
export REVIEW_ROUND_BUDGET=3
```

**Verified on borg, 2026-09-14** — `codex exec` v0.151.0 answered the probe:

| property | observed | why it matters |
|---|---|---|
| model | `gpt-5.6-sol` (openai) | ⭐ shares no training, priors or failure modes with the author. `EVIDENCE_STANDARDS` §4 applied to the review itself. |
| reasoning | `xhigh` | the gate is the wrong place to economise |
| sandbox | `read-only` | ⭐ **cannot edit what it reviews.** A reviewer that can "just fix it" stops being a reviewer. |
| approval | `never` | runs unattended, as a gate must |

If the model changes, record it here. A reviewer silently swapped to the author's family is a
gate that has quietly stopped being one.

`review.sh` probes the reviewer **by execution** before trusting it: absent, or present and
returning nothing, is never a pass.

## ARIS

Upstream methodology at `~/aris_repo` — *auto-research-in-sleep*. Installed, not vendored
(`LINEAGE.md`).

- **`mcp-servers/codex-exec/`** — the cross-model review bridge. This is the amenity worth
  taking; it does what `review.sh` shells out to, as an MCP server.
- **Skills** — link the ~8 you use. Every skill's name and description is loaded into every
  session, so 82 linked skills is a standing tax on every prompt
  (`agreements/SESSION_HYGIENE.md`).

## Environment policy

**Never use the base conda environment.**

```bash
conda activate <env>                                              # borg
export PATH=/ibex/user/<user>/conda-environments/<env>/bin:$PATH  # cluster compute node
```
