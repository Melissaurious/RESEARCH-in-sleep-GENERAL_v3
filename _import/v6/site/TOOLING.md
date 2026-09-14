# SITE — tooling

Agent, reviewer and editor configuration for **this installation**. Not an agreement;
a second installation replaces this file.

## Permissions posture

Sessions run **with the permission system enabled**. `.claude/settings.json` is the
configuration; the deny list is an accident guard, and the real write boundary is the
sandbox `filesystem.allowWrite` list plus read-only file modes on source data.

**Do not launch with `--dangerously-skip-permissions`.** An earlier version of this
file told you to, while `WA-C.5` and `WA-D.1` named the permission rules as their
check — so two rules claimed enforcement that the launch flag removed. If unattended
overnight runs later make prompts impractical, the honest fix is to change those two
rules' `check:` lines in the same commit, never to quietly disable the mechanism they
cite.

`git push` is **allowed**, because the gate on pushing is a rule, not a permission:
`WA-R.6` says a branch is pushed when the row's bundle is accepted. A deny rule on top
of that was redundant with the agreement and added a prompt to every row, so the
agreement is the single place the policy lives. The deny list keeps what it is actually
good at — guarding against accidents (`rm`, `chmod`, `sed -i`, `git reset --hard`,
package installs).

Before launch:

    export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000

## Model policy

Tiers, not model names — exact identifiers drift between releases and a stale ID in a
spec is worse than none:

| Work | Tier | Reasoning effort |
|------|------|------------------|
| planning, stage design, Phase B interpretation, reading results | most capable available | high |
| execution: writing scripts, running them, patching, mechanical edits | mid tier | medium |
| trivial mechanical edits | mid tier | low |

Confirm the current identifiers with `/model` after any update and record the ones you
actually used in the row's `PROVENANCE.md` — that is where a model belongs, beside the
run it produced. Declare the tier per row in the launcher's `Model:` field.

## Reviewer — cross-model, load-bearing

The reviewer must be a **different model family** from the executor. If the reviewer is
unreachable, a skill must FAIL rather than self-review. A loop may DRIVE, it may never
ACQUIT.

    claude mcp add codex -s user -- codex mcp-server

- Installed user-level via nvm (Node ≥ 20); not inside a conda env, so it works from
  any shell. Verify with `codex --version` and `codex login status`.
- Reasoning effort is pinned in the codex config; set it there, not per call.
- Pass condition for "the reviewer is really a different family": ask it to identify
  itself and get a non-Claude answer.
- Reserved for the heavyweight verdicts only — kill-argument, research-review,
  experiment-audit, result-to-claim, paper-claim-audit, citation-audit,
  integrity-forensics. Routine work runs on the executor alone.

## Skills

Project-local (`<project>/.claude/skills`), never bulk-symlinked (SH-4). Every skill's
name and description is loaded into every session, so an unused skill is a standing tax
on every prompt (`agreements/SESSION_HYGIENE.md`).
