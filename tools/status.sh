#!/usr/bin/env bash
# Where things stand, right now, on both machines. Read this before deciding what to
# start and where — by a session at the top of its turn, or by the operator.
#
# It answers the four questions that were previously answered by pasting terminal
# output into a chat window:
#
#   1. is anything running HERE, and does something hold this tree
#   2. is anything running on IBEX
#   3. which rows are approved, which have landed, which are waiting on acceptance
#   4. what did the last night actually do
#
# Read-only. It starts nothing, releases nothing, and writes nothing. Every remote call
# is wrapped in a timeout, so an unreachable cluster costs seconds and prints UNREACHABLE
# rather than hanging a session that only wanted to know where to put a job.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

IBEX_HOST="${IBEX_HOST:-ibex}"
SSH_TIMEOUT="${SSH_TIMEOUT:-8}"
hr() { printf '\n\033[1m%s\033[0m\n' "$1"; }

hr "1 · this checkout — $(pwd)"
printf '  branch      %s\n' "$(git rev-parse --abbrev-ref HEAD)"
printf '  origin/main %s\n' "$(git log --oneline -1 origin/main 2>/dev/null | cut -c1-64)"
UNPUSHED=$(git log --oneline @{u}.. 2>/dev/null | wc -l)
[ "$UNPUSHED" -gt 0 ] && printf '  \033[33m%s unpushed commit(s) on this branch\033[0m\n' "$UNPUSHED"

if [ -f .agent-lock ]; then
  LPID=$(sed -n 's/^pid=//p' .agent-lock); LKIND=$(sed -n 's/^pid_kind=//p' .agent-lock)
  LWHEN=$(sed -n 's/^since=//p' .agent-lock); LHOST=$(sed -n 's/^host=//p' .agent-lock)
  if kill -0 "$LPID" 2>/dev/null; then
    printf '  lock        HELD by live pid %s (%s) on %s since %s\n' \
      "$LPID" "${LKIND:-unknown}" "$LHOST" "$LWHEN"
  else
    printf '  lock        pid %s (%s) is NOT alive, since %s\n' "$LPID" "${LKIND:-unknown}" "$LWHEN"
    [ "${LKIND:-}" = unverified ] && printf '              (unverified pid — "not alive" proves nothing here)\n'
  fi
else
  printf '  lock        free\n'
fi

printf '  worktrees   %s (this one included)\n' "$(git worktree list 2>/dev/null | grep -c .)"

hr "2 · worktrees — every tree, not just this one"
#
# A worktree is how this repo runs two sessions at once, and the isolation that makes it
# safe is exactly what makes it invisible: its own results/, its own branches, its own
# ARIS_OUTPUT/, its own lock. A chain finished a row, its rerun reproduced, and from the
# main checkout there was no sign anything had happened at all - the operator reasonably
# asked how to re-run rows that had in fact just passed their hardest gate.
#
# So: report every tree. Same class of failure as the night log dying in gitignored
# scratch, one directory over.
HERE_TOP="$(git rev-parse --show-toplevel)"
git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | while read -r WT; do
  [ -d "$WT" ] || continue
  MARK="  "; [ "$WT" = "$HERE_TOP" ] && MARK="* "
  BR=$(git -C "$WT" rev-parse --abbrev-ref HEAD 2>/dev/null)
  printf '%s\033[1m%s\033[0m  [%s]\n' "$MARK" "$(basename "$WT")" "$BR"

  # lock: held by a live process, or stale, or free
  if [ -f "$WT/.agent-lock" ]; then
    LP=$(sed -n 's/^pid=//p' "$WT/.agent-lock"); LK=$(sed -n 's/^pid_kind=//p' "$WT/.agent-lock")
    if kill -0 "$LP" 2>/dev/null; then printf '      lock     HELD by live pid %s (%s)\n' "$LP" "${LK:-unknown}"
    else printf '      lock     pid %s not alive (%s)\n' "$LP" "${LK:-unknown}"; fi
  else
    printf '      lock     free\n'
  fi

  # a chain running IN this tree, found by its cwd rather than by its command line
  CH=""
  for pid in $(pgrep -f 'tools/overnight.sh|tools/night.sh' 2>/dev/null); do
    [ "$(readlink -f /proc/$pid/cwd 2>/dev/null)" = "$(readlink -f "$WT")" ] && CH="$CH $pid"
  done
  [ -n "$CH" ] && printf '      RUNNING  chain pid(s)%s\n' "$CH"

  # bundles here that main does not have yet - the reason to look in this tree at all
  for d in "$WT"/results/*/; do
    [ -d "$d" ] || continue
    R=$(basename "$d")
    [ -d "$HERE_TOP/results/$R" ] && continue
    ST=$(sed -n 's/^STATUS:[[:space:]]*//p' "$d/README.md" 2>/dev/null | head -1)
    PU=$(git -C "$WT" rev-parse --verify -q "origin/$R" >/dev/null 2>&1 && echo "on origin" || echo "UNPUSHED")
    printf '      \033[33mbundle   %s — %s, %s\033[0m\n' "$R" "${ST:-no STATUS}" "$PU"
  done

  # last chain log in this tree, and whether it stopped early
  L=$(ls -1dt "$WT"/ARIS_OUTPUT/overnight/*/ 2>/dev/null | head -1)
  if [ -n "$L" ]; then
    [ -f "$L/RESUME.sh" ] && printf '      \033[33mSTOPPED EARLY — bash %sRESUME.sh\033[0m\n' "$L"
    printf '      last     %s\n' "$(tail -1 "$L/SUMMARY.txt" 2>/dev/null | cut -c1-84)"
  fi
done

hr "3 · running here"
FOUND=0
for pat in 'tools/overnight.sh' 'tools/night.sh'; do
  # shellcheck disable=SC2009
  ps -eo pid=,etime=,args= 2>/dev/null | grep -F "$pat" | grep -v grep | while read -r line; do
    printf '    %s\n' "$(printf '%s' "$line" | cut -c1-110)"; done
  ps -eo args= 2>/dev/null | grep -qF "$pat" && FOUND=1
done
pgrep -x claude >/dev/null 2>&1 && { printf '    %s claude process(es)\n' "$(pgrep -cx claude)"; FOUND=1; }
[ "$FOUND" = 0 ] && printf '    nothing\n'

hr "4 · ibex"
if timeout "$SSH_TIMEOUT" ssh -o BatchMode=yes -o ConnectTimeout=5 "$IBEX_HOST" true 2>/dev/null; then
  Q=$(timeout "$SSH_TIMEOUT" ssh -o BatchMode=yes "$IBEX_HOST" 'squeue --me --noheader' 2>/dev/null)
  if [ -z "$Q" ]; then printf '    reachable, queue EMPTY\n'
  else printf '%s\n' "$Q" | sed 's/^/    /'
       printf '    (%s job(s))\n' "$(printf '%s\n' "$Q" | grep -c .)"
  fi
else
  printf '    \033[33mUNREACHABLE as "%s"\033[0m — check `ssh %s true`; without it no row can be dispatched there\n' \
    "$IBEX_HOST" "$IBEX_HOST"
fi

hr "5 · rows"
printf '  %-32s %-9s %-9s %s\n' ROW BUNDLE BRANCH 'WHERE IT RUNS'
git fetch -q origin 2>/dev/null
for R in $(grep -oE '^## r[0-9a-z-]+' ROADMAP.md | sed 's/^## //'); do
  B="-"; [ -d "results/$R" ] && B="landed"
  BR="-"; git rev-parse --verify -q "origin/$R" >/dev/null 2>&1 && BR="on origin"
  W=$(awk -v row="## $R" '
        $0 ~ "^"row {f=1; next} f && /^## / {exit}
        f && /Where it runs/ {
          line=$0
          if (line ~ /^#/) { while ((getline nx) > 0) if (nx ~ /[^[:space:]]/) { line=nx; break } }
          print line; exit
        }' ROADMAP.md | sed 's/\*\*//g; s/^Where it runs\.* *//' | cut -c1-34)
  printf '  %-32s %-9s %-9s %s\n' "$R" "$B" "$BR" "${W:-<unparseable>}"
done

hr "6 · waiting on you"
printf '  claims UNPROVEN            %s of %s\n' \
  "$(grep -E '^\|[[:space:]]*(~~)?C[0-9]+' CLAIMS.md | awk -F'|' 'NF>=9{s=$(NF-3); gsub(/[ *]/,"",s); if(s=="UNPROVEN") n++} END{print n+0}')" \
  "$(grep -cE '^\|[[:space:]]*(~~)?C[0-9]+' CLAIMS.md)"
printf '  branches unmerged to main  %s\n' "$(git branch -r --no-merged origin/main 2>/dev/null | grep -c 'origin/')"
printf '  decisions awaiting you     %s\n' "$(grep -lE 'PROPOSED|awaiting operator' docs/decisions/*.md 2>/dev/null | wc -l)"
printf '  BLOCKED entries pending    %s\n' "$(grep -cE '^\*\*Decided:\*\*[[:space:]]*_?pending' docs/BLOCKED.md 2>/dev/null)"

hr "7 · last night"
LAST=$(ls -1dt ARIS_OUTPUT/overnight/*/ ARIS_OUTPUT/night/*/ 2>/dev/null | head -1)
if [ -n "$LAST" ]; then
  printf '  %s\n' "$LAST"
  [ -f "$LAST/RESUME.sh" ] && printf '  \033[33mSTOPPED EARLY — resume with: bash %sRESUME.sh\033[0m\n' "$LAST"
  tail -12 "$LAST/SUMMARY.txt" 2>/dev/null | sed 's/^/    /' \
    || printf '    no SUMMARY.txt — the chain died before writing one\n'
  # The account limit ends more nights than any bug, and it leaves no error behind.
  if grep -rqiE "hit your (session|usage|account) limit" "$LAST" 2>/dev/null; then
    printf '  \033[33mACCOUNT LIMIT was hit during this run:\033[0m\n'
    grep -rhoiE "hit your (session|usage|account) limit[^\"]*" "$LAST" 2>/dev/null | sort -u | sed 's/^/    /'
  fi
else
  printf '    no overnight run recorded\n'
fi
echo
