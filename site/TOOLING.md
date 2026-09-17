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

### The roster — three families, assigned to different jobs

⚠️ **More reviewers is not more signal.** Two reviewers reading the same artifact and
answering the same questions mostly agree, cost two rounds, and teach you to skim both.
What raises independence is **different eyes on different questions**, never a bigger panel.

| job | reviewer | why that one |
|---|---|---|
| **plan audit**, before compute (`skills/plan-audit/`) | **Gemini** | the questions are about *design* — falsifiability, circularity, controls, whether a denominator is named. A long-context model can hold the launcher, the contract and the real schema probes at once. |
| **result review**, before landing | **codex** `gpt-5.6-sol` | the questions are about *arithmetic and provenance* — does every number trace to a script, does the TSV reproduce the figure, is the identity exact. |
| **gap analysis** (`REUSE → VERIFY → GAP ANALYSIS`) | **Gemini** | ⭐ the one job neither of the others can do: read the whole programme archive *and* every prior bundle README at once, and say what is genuinely missing rather than what is merely unfamiliar. |
| the work itself | **Opus 5** | — |

⭐ **Neither reviewer ever sees the other's verdict, or its own earlier one.** That is what
keeps the two gates independent rather than sequential.

⛔ Do **not** run both reviewers on the same gate hoping for a tie-break. A disagreement
between two models is not a measurement, and resolving it costs a round of attention you
owe the science instead. If a gate needs a tie-break, the launcher's question was unclear.

### Wiring Gemini

Gemini is reached **through MCP, not through a shell command** — the project declares an
`llm-chat` MCP server and ARIS calls `/auto-review-loop-llm` instead of `/auto-review-loop`:

```
## Reviewer Config
- MCP: llm-chat  (Gemini)
- Use /auto-review-loop-llm, not /auto-review-loop
```

That is a different transport from codex's, so the `RSG_PLAN_REVIEW_CMD` slot does not
apply to it — there is no command to export. What has to be true instead:

1. `llm-chat` is listed in the project's `.mcp.json`, and the session actually connects to
   it. An MCP server that fails to start is silent in a way a missing binary is not.
2. `generativelanguage.googleapis.com` (API) or `aiplatform.googleapis.com` (Vertex) is in
   `sandbox.network.allow` — already added to `templates/settings.json`.
3. The launcher's Reviewer Config block names the model actually served, not the one
   configured. Record what the probe returns.

Probe it **by execution** before trusting it (`EVIDENCE_STANDARDS` §2, WA-K.2) — the same
bar codex had to clear. Send one real review packet, not a ping, and read the answer: a
reviewer that returns fluent agreement to a plan with a known hole in it has failed the
probe even though it replied.

⚠️ **Until that returns a real verdict on a real packet, Gemini is `ABSENT`, not
configured** — and an absent reviewer is never a cleared gate.

#### Two things to settle before it counts as the plan auditor

**The model tier.** `gemini-2.5-flash` is the cheap tier. For the result review that would
be merely slower; for the **plan audit** it is a real risk, because a weak adversary does
not return "I found nothing" — it returns a fluent clearance, and a cleared gate is exactly
what this layer spends its rules trying not to hand out for free. The plan audit asks
whether a design is circular, whether a denominator is named, whether a control could come
back positive for the wrong reason. Use the **pro / thinking tier** for that job and leave
flash to bulk work where a wrong answer is visible immediately. If only flash is available,
say so in the launcher and treat its verdict as advisory, not as `plan-audit` cleared.

**Whether `/auto-review-loop-llm` still goes through the deterministic gate.** ARIS's
`/auto-review-loop` makes the transition with ARIS's own `review_gate.py`: positive requires
`score >= 6` **and** verdict in `{ready, almost}`. Check that the `-llm` variant gates the
same way rather than reading a verdict out of free text. If it does not, it is transport
with no gate, and routing the plan audit through it **weakens an ARIS review requirement —
WA-A.5 forbids that**. In that case keep `/auto-review-loop-llm` for the advisory read and
have `plan-audit` apply the threshold itself: score >= 6, positive verdict, and no finding
marked BLOCKING.

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
