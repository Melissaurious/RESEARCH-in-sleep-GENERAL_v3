#!/usr/bin/env bash
# A second (third, fourth) governed checkout, so more than one session can work at once.
#
#   bash tools/worktree.sh rows           # make ../<repo>-rows, ready to run
#   bash tools/worktree.sh rows r11 r13   # ...and print the command to run those rows
#
# WA-C.1 is per WORKING DIRECTORY: `.agent-lock` lives at the tree root, and
# `no_concurrent_writer.sh` resolves it through `git rev-parse --show-toplevel`, which in a
# worktree returns the worktree. So a second tree is a second lock, a second index, a second
# HEAD, a second ARIS_OUTPUT/ and a second results/ — genuine isolation, not a convention.
#
# This exists because the alternative kept failing in the same way: an interactive session
# holds the lock in the main checkout, `tools/overnight.sh` correctly refuses to start, and
# the operator reads a working safety rule as "no autonomy". The recipe to get past it —
# worktree PLUS `git submodule update --init --recursive`, or the new tree is ungoverned and
# no row may start there (CLAUDE.md § Layers) — existed twice, hardcoded, inside
# sidework.sh and night.sh, and nowhere a person could call it.
#
# Three things that bite a hand-rolled `git worktree add`, all handled here:
#   * branch exclusivity — two worktrees may not check out the same branch. `git worktree
#     add <path> main` fails outright once main is checked out anywhere, so this always
#     creates a branch of its own.
#   * submodules — a fresh worktree has empty `agreements/` and `site/`. specs_exist.sh
#     fails, and every row in that tree is unstartable until they are initialised.
#   * settings — `.claude/settings.json` is tracked, so a worktree freezes the permission
#     and sandbox rules of the commit it was made from. Made from origin/main, it carries
#     current governance; made from a stale base, it silently carries stale governance.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ROOT="$(pwd)"

NAME="${1:-}"
[ -n "$NAME" ] || { echo "usage: bash tools/worktree.sh <name> [gate ...]"; exit 2; }
shift
ROWS="$*"

WT="$ROOT/../$(basename "$ROOT")-$NAME"
BRANCH="night/$NAME"
say() { printf '%s  %s\n' "$(date +%H:%M:%S)" "$*"; }

git fetch -q origin || { say "fetch failed"; exit 1; }

if [ -d "$WT" ]; then
  say "reusing $WT"
else
  # -B so a leftover branch from a previous run is reset rather than colliding, and always
  # a branch of this tree's own: origin/main is checked out in the main tree.
  git worktree add -q -B "$BRANCH" "$WT" origin/main || { say "could not create $WT"; exit 1; }
  say "created $WT on $BRANCH from origin/main"
fi

# Ungoverned is not a usable tree. CLAUDE.md § Layers: if the submodules are empty this
# checkout is not governed and no row may start.
say "initialising submodules"
git -C "$WT" submodule update --init --recursive -q || { say "submodule init FAILED"; exit 1; }

# cd INTO the tree, do not merely point at its script: specs_exist.sh resolves the paths
# it checks against the CURRENT directory, so running it by absolute path from the main
# checkout audits the main checkout and reports on the wrong tree - which is how the first
# version of this line reported FAILED while the very next line printed OK.
if ( cd "$WT" && bash general/checks/specs_exist.sh ) >/dev/null 2>&1; then
  say "specs_exist OK — the tree is governed"
else
  say "!! specs_exist FAILED in $WT — do not start a gate there"
  ( cd "$WT" && bash general/checks/specs_exist.sh ) 2>&1 | head -10
  exit 1
fi

if [ -f "$WT/.agent-lock" ]; then
  say "!! $WT/.agent-lock already exists — a session may be running there"
else
  say "lock free in the new tree"
fi

say "general $(bash "$WT/general/tools/general_sha.sh" 2>/dev/null) - base $(git -C "$WT" rev-parse --short HEAD)"
echo
echo "  cd $WT"
if [ -n "$ROWS" ]; then
  echo "  bash tools/overnight.sh $ROWS"
else
  echo "  claude          # or: bash tools/overnight.sh <row> ..."
fi
echo
echo "  # when it is finished and merged:"
echo "  git -C $ROOT worktree remove $WT"
