#!/usr/bin/env bash
# Open a SIDE INVESTIGATION in its own working directory, without a second clone.
#
#   bash tools/sidework.sh cds-linkage
#   bash tools/sidework.sh cds-linkage --open      # also print the session prompt
#
# WHY A WORKTREE AND NOT A CLONE
#
# `.agent-lock` is per working directory, so two agents in ONE checkout fight over it and
# over the same files. A second clone fixes that but duplicates the object store, needs
# its own fetches, and drifts. `git worktree` gives a separate directory that SHARES the
# object store: every branch, every commit, one `git fetch` for all of them. The lock is
# separate because the directory is separate. That is exactly the property we need.
#
# WHAT SIDEWORK IS FOR
#
# Investigations that are not yet a row: running the upstream pipeline on records that
# look wrong, pulling sequences to eyeball, arguing with a result, trying something that
# might not work. Free-form on purpose.
#
# WHAT SIDEWORK IS NOT
#
# It is not a door a number can enter through. Nothing in sidework/ may be cited, put in
# a figure, or written into CLAIMS.md. A sidework finding earns exactly one thing: the
# right to become a ROW, with a stop condition and a bundle, like everything else. That
# boundary is the whole reason this is safe to make messy.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
TOPIC="${1:?usage: bash tools/sidework.sh <topic> [--open]}"
case "$TOPIC" in *[!a-z0-9-]*) echo "topic: lowercase, digits and dashes only" >&2; exit 1;; esac

BRANCH="sidework/$TOPIC"
DIR="$ROOT/../$(basename "$ROOT")-sidework-$TOPIC"
NOTES="sidework/$TOPIC"

git fetch -q origin
if [ -d "$DIR" ]; then
  echo "worktree already exists: $DIR"
else
  git worktree add -q -b "$BRANCH" "$DIR" origin/main 2>/dev/null \
    || git worktree add -q "$DIR" "$BRANCH"
  # A worktree does not inherit the superproject's submodules; without this the new
  # directory is ungoverned and CLAUDE.md says no row may start there.
  ( cd "$DIR" && git submodule update --init --recursive -q )
  echo "worktree:  $DIR   (branch $BRANCH, from origin/main)"
fi

mkdir -p "$DIR/$NOTES"
if [ ! -f "$DIR/$NOTES/FINDINGS.md" ]; then
  cat > "$DIR/$NOTES/FINDINGS.md" <<TPL
# sidework/$TOPIC

**Opened:** $(date +%Y-%m-%d) · **Status:** OPEN · **Branch:** \`$BRANCH\`

Nothing on this page is a number. It may not be cited, plotted, or written into
CLAIMS.md. It exists to decide whether a ROW is worth a night.

## The question

_What would we know after this that we do not know now?_

## What was run

| what | where | command | when |
|---|---|---|---|

## What came back

_Counts and observations. No conclusions._

## Verdict

- [ ] **Becomes a row.** Proposed id, the one measurement, the stop condition, and the
      claim it would settle — which must be added to CLAIMS.md as UNPROVEN first (CL-1).
- [ ] **Answered here, no row needed.** Say what the answer was and why it needs no bundle.
- [ ] **Dead end.** Say what was ruled out. This is a result and is worth keeping.
TPL
  echo "notes:     $DIR/$NOTES/FINDINGS.md"
fi

[ "${2:-}" = "--open" ] || exit 0
cat <<PROMPT

--- paste this into a session started in $DIR ---

You are running SIDEWORK, not a row. Read CLAUDE.md, then sidework/$TOPIC/FINDINGS.md.

Sidework rules, which differ from a row's:
- Scratch freely in ARIS_OUTPUT/. No bundle, no INPUTS.tsv, no run.sh.
- Nothing you produce here is a number. It may not be cited or written into CLAIMS.md
  or ROADMAP.md. Its only possible promotion is to become a ROW the operator approves.
- Source data stays read-only (WA-D.1). Write outputs to a NEW directory you name.
- Keep FINDINGS.md current as you go: what you ran, where, and what came back. Counts,
  not conclusions (WA-I.1).
- Fill in the Verdict section at the end. "Dead end" is a legitimate verdict and is
  worth keeping.
- Commit to $BRANCH. Do not push without being asked, and never merge to main.
PROMPT
