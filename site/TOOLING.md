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

1. `llm-chat` is reachable from **every** working tree, not just one. `.mcp.json` is
   per-directory, so a project and its detached workbench
   (`..._v7` and `..._v7-dbchar-workbench`) are two separate scopes and a per-project entry
   has to be repeated in each. Register it **once at user scope instead** —
   `claude mcp add --scope user llm-chat -- <cmd>` — and every tree inherits it, including
   trees that do not exist yet. Then confirm the session actually connects (`/mcp`): an MCP
   server that fails to start is silent in a way a missing binary is not.
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

#### Verified on borg, 2026-09-18 — registered, probed, and **advisory only**

```bash
claude mcp add --scope user gemini \
  -e LLM_API_KEY=<key> \
  -e LLM_BASE_URL=https://generativelanguage.googleapis.com/v1beta/openai/ \
  -e LLM_MODEL=gemini-3.6-flash \
  -e LLM_FALLBACK_MODEL=gemini-3.6-flash \
  -e LLM_SERVER_NAME=gemini \
  -- /home/borg/miniconda3/envs/retron_tradicional/bin/python \
     /home/borg/aris_repo/mcp-servers/llm-chat/server.py
```

ARIS's `llm-chat` server is provider-generic (it needs only `httpx` and talks to whatever
`LLM_BASE_URL` names), so `LLM_SERVER_NAME` lets one file be registered twice under two
names. Registering as **`gemini`** rather than `llm-chat` is deliberate: it leaves the name
ARIS's converted skills call (`mcp__llm-chat__chat`) free, so adding a conversational
reviewer changes nothing about how a gate is cleared.

**What the probe established, and what it cost to learn:**

| probe | result |
|---|---|
| `gemini-2.5-pro` | `404 — no longer available to new users` |
| `gemini-2.5-flash` | `404 — no longer available to new users` |
| `gemini-3.1-pro-preview` | `429 RESOURCE_EXHAUSTED`, `limit: 0` — free tier grants pro **zero** requests |
| `gemini-3.6-flash` | ✅ `{"content":"OK"}` |

Two of those are only visible by execution. A 404 on a retired model id and a 429 whose
limit is `0` both come back from a key that is perfectly valid — `claude mcp list` reported
**✔ Connected** at every step above, including with the API key set to the literal string
`PASTE_YOUR_KEY`. For a stdio server "connected" means the process started and answered the
handshake; it never touches the provider. ⛔ **Connected is not configured. Probe with a
real call or you have not checked anything.**

**Therefore Gemini is the breadth pass, not the gate.** The free tier grants pro `limit: 0`,
so the tier is not a choice here. A fast model reading a launcher cold is genuinely good at
*generating* the questions — an unstated denominator, a control that could come back
positive for the wrong reason. What it is unreliable at is *holding a line*: returning "not
ready" on something plausible. So it runs **before** codex and produces questions; codex
`gpt-5.6-sol` decides. Record it in the launcher as advisory, never as `plan-audit` cleared.
Making Gemini a gate reviewer is a billing decision, not a config one.

⚠️ `gemini-3.6-flash` is itself a dated name — 2.5 was retired mid-project, and the same
will happen to this one. The launcher records the **exact id served**, so that when a
reviewer disappears you can still say which bundles it graded. `LLM_FALLBACK_MODEL` is
pinned to the same value for that reason: a retirement must fail loudly rather than
silently reroute a plan audit to a different grader under a launcher naming the first one.
The free-tier daily cap is small enough that a gap analysis over the whole archive can hit
`429` mid-run — one more reason nothing gates on it.

**~~Whether `/auto-review-loop-llm` still goes through the deterministic gate.~~ Settled —
it does.** Verified on borg, 2026-09-17, in `~/aris_repo/skills/auto-review-loop-llm/SKILL.md`:

```
:27   POSITIVE_THRESHOLD: score >= 6/10 AND verdict in {ready, almost} -- both must hold
:166  STOP: If score >= 6 AND verdict in {ready, almost} (exact -- "not ready" does NOT qualify)
```

Same threshold as `/auto-review-loop`, and line 27 records that an earlier wording used
`or` and a stale verdict set — the `AND` form is authoritative. So routing the plan audit
through the `-llm` variant does **not** weaken an ARIS review requirement; WA-A.5 is
satisfied. `plan-audit` therefore does not re-apply the threshold itself and keeps only its
own addition: no finding marked BLOCKING.

⚠️ That skill carries its own warning (its lines 15–17) about firing a verdict on
**wall-clock time** rather than on the artifact that should precede it. A loop that times
out and returns is not a review. If a round ends on the clock, the gate is not cleared —
it is unreviewed, and unreviewed is `ABSENT`, not `almost`.

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
