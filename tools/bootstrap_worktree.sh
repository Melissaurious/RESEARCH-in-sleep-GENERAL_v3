#!/usr/bin/env bash
# Make a git worktree able to run Ibex. Run it once in every new worktree.
#
#   bash general/tools/bootstrap_worktree.sh           # diagnose and fix
#   bash general/tools/bootstrap_worktree.sh --check   # diagnose only, change nothing
#
# Why this exists: `git worktree add` copies TRACKED FILES ONLY. Submodules are not
# tracked files -- they are a gitlink plus a config entry -- so `general/` arrives as an
# EMPTY DIRECTORY in every new worktree. Everything this layer contributes hangs off it:
#
#   .claude/skills/run-experiment-ibex     -> ../../general/skills/run-experiment-ibex
#   .claude/skills/experiment-routing-ibex -> ../../general/skills/experiment-routing-ibex
#   .claude/skills/plan-audit              -> ../../general/skills/plan-audit
#
# Those symlinks ARE tracked, so they arrive intact and pointing at nothing. A dangling
# symlink is not an error anyone sees: the skill simply does not resolve, /experiment-bridge
# falls through to ARIS's own routing, and the job goes out over SSH + screen with no
# allocation and no job id -- the exact thing routing-ibex exists to prevent. The tree looks
# fine. The first symptom is a cluster job that was never a cluster job.
#
# Observed 2026-09-18: two worktrees reported
#   `SessionEnd hook [bash general/checks/no_concurrent_writer.sh --release] failed:
#    No such file or directory`
# which is the same missing submodule announcing itself through the one component that
# happens to be called by an absolute path instead of a symlink.
set -uo pipefail

CHECK_ONLY=0; [ "${1:-}" = "--check" ] && CHECK_ONLY=1
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"

fail=0
ok()   { printf '  \033[32mok\033[0m    %s\n' "$1"; }
bad()  { printf '  \033[31mBAD\033[0m   %s\n' "$1"; fail=1; }
info() { printf '        %s\n' "$1"; }

echo "--- worktree bootstrap: $ROOT"
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != true ]; then
  echo "not a git work tree" >&2; exit 1
fi
git rev-parse --git-common-dir >/dev/null 2>&1 &&
  [ "$(git rev-parse --git-dir)" != "$(git rev-parse --git-common-dir)" ] &&
  info "this IS a linked worktree (main tree: $(git rev-parse --git-common-dir | sed 's|/\.git$||'))"

# 1. the submodule itself
if [ -f general/CLAUDE.md ]; then
  ok "general/ is populated ($(git -C general rev-parse --short HEAD 2>/dev/null || echo '?'))"
else
  bad "general/ is EMPTY -- the submodule was never initialised in this worktree"
  if [ "$CHECK_ONLY" = 0 ]; then
    info "running: git submodule update --init --recursive"
    git submodule update --init --recursive || { echo "submodule init FAILED" >&2; exit 1; }
    [ -f general/CLAUDE.md ] && { ok "general/ now populated"; fail=0; }
  fi
fi

# 2. the skill symlinks -- tracked, so present, but dangling until general/ exists
for s in run-experiment-ibex experiment-routing-ibex plan-audit; do
  l=".claude/skills/$s"
  if [ -e "$l/SKILL.md" ]; then ok "$s resolves"
  elif [ -L "$l" ];        then bad "$s is a DANGLING symlink -> $(readlink "$l")"
  else                          bad "$s is missing entirely"
    [ "$CHECK_ONLY" = 0 ] && { mkdir -p .claude/skills
      ln -sfn "../../general/skills/$s" "$l"; ok "$s relinked"; fail=0; }
  fi
done

# 3. the experiment-bridge overlay -- DERIVED, so a worktree only has it if it was committed
if [ -f .claude/skills/experiment-bridge/SKILL.md ]; then
  if bash general/tools/install_ibex_overlay.sh --check >/dev/null 2>&1; then
    ok "experiment-bridge overlay present and matches the pinned upstream"
  else
    bad "experiment-bridge overlay is STALE or drifted from the pin"
    info "re-derive: bash general/tools/install_ibex_overlay.sh"
  fi
else
  bad "experiment-bridge overlay ABSENT -- /experiment-bridge will use ARIS's own routing,"
  info "which sends cluster work over SSH + screen. Ibex routing is not binding here."
  if [ "$CHECK_ONLY" = 0 ] && [ -f ARIS.lock ]; then
    info "deriving it now"
    bash general/tools/install_ibex_overlay.sh && fail=0
  else
    info "needs ARIS.lock (bash general/tools/pin_aris.sh) before it can be derived"
  fi
fi

# 4. the account every Ibex job must carry, and the login host the sandbox must allow
if [ -f .claude/settings.json ]; then
  grep -q 'ibex.kaust.edu.sa' .claude/settings.json \
    && ok "settings.json allows the Ibex login hosts" \
    || bad "settings.json does not allow ilogin.ibex.kaust.edu.sa -- the sandbox will block it"
else
  bad ".claude/settings.json missing"
fi

echo
if [ "$fail" = 0 ]; then
  echo "OK: this worktree can route to Ibex."
else
  [ "$CHECK_ONLY" = 1 ] && echo "NOT READY (--check made no changes; rerun without it to fix)" \
                        || echo "NOT READY: see BAD lines above -- some need a human."
  exit 1
fi
