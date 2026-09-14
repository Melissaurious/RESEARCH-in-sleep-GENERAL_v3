# CLAUDE.md — <project>

<One sentence: what this project measures, in what units, so that every downstream number
has a denominator that can be named.>

> ⚠ The sentence above is the only project-specific claim in this file. The operator owns
> it — rewrite it when the scope settles.

**One repo; git holds versions. Never create a version-numbered sibling directory.**

## Governed by

`general/` — the governance layer, a submodule pinned by sha. If it is empty this checkout
is not governed and no gate may start:

    git submodule update --init --recursive
    bash general/checks/specs_exist.sh      # must print OK

Read `general/CLAUDE.md` at session start. Every rule, every check and every template lives
there; nothing is restated here. The revision this project runs under:

    bash general/tools/general_sha.sh       # recorded in every bundle (BS-10)

Moving the pin is a deliberate commit with a decision record in `docs/decisions/`.

## Read before acting

- `GOALS.md` — what we are trying to be able to claim
- `CLAIMS.md` — the falsifiable statements and their status. The progress tracker.
- `ROADMAP.md` — the gates; exactly one is active
- `launchers/LAUNCHER_<track>.md` — the active track. The authority on scope (WA-L.1).
- `docs/decisions/` — settled decisions, numbered. Not re-argued in a session; superseded
  by a new record or not at all.
- `data/README.md` — the input register, and the inherited-baseline rows (WA-L.3)

Read when the situation applies:
- `IDEAS.md` — deferred work. A session may propose promotion; it may never promote.
- `sidework/README.md` — before opening or reading a side investigation
- `docs/BLOCKED.md` — the open questions, with their recommended defaults

## Environment

- **Env:** `<env-name>` (never base).
  Local `<local env path>`; cluster `<cluster env path>`.
- **Root:** `<project root>`

## Project conventions

<Only genuine overrides. Each names the rule it overrides and why. Delete this section if
there are none — an empty conventions list is better than an invented one.>

- **OVERRIDE — script length ≤ N lines** (default 200). <why>

## File safety

- Source data is read-only, enforced by file mode (WA-D.1).
- This track writes to exactly one directory (WA-D.1) — see the active launcher §0.1, and
  `.claude/settings.json`.
- All scratch goes to `ARIS_OUTPUT/` — gitignored, disposable, allowed to be messy.
- Numbers go to `results/<GATE>/` and nowhere else (WA-B.1).

## Before any negative or absence claim

A count of zero needs a positive control that the same code returns non-zero on a case known
to be present (EVIDENCE_STANDARDS §6). This project inherits none — every gate supplies its
own.
