#!/usr/bin/env bash
# WA-C.1 — one agent process writes to one checkout at a time.
#
#   acquire (SessionStart hook):  bash general/checks/no_concurrent_writer.sh
#   release (SessionEnd  hook):   bash general/checks/no_concurrent_writer.sh --release
#   validate me:                  SELFTEST=1 bash general/checks/no_concurrent_writer.sh
#
# Two properties this must have and the previous version did not:
#
#   1. Release is OWNERSHIP-CHECKED. It refuses to remove a lock whose recorded
#      process is still alive. The old `rm -f .agent-lock` deleted any lock,
#      including a live sibling's — and it was wired to `Stop`, which fires when
#      the agent finishes a RESPONSE, so protection lasted one turn.
#   2. Liveness is host-scoped. A pid written on another machine says nothing
#      about a process here, and shared home directories make that a real case.
#      A lock from another host is never judged dead: it blocks and asks (WA-C.3).
#
#   3. The recorded pid is the SESSION, not the hook's parent. `$PPID` inside a
#      SessionStart hook is the transient shell the harness spawned to run it; that
#      shell exits seconds later. Measured on a live session: the lock read
#      `pid=1364` while the session ran, and `kill -0 1364` already failed. Every
#      liveness test was therefore wrong in the PERMISSIVE direction - property 1
#      above was written, tested, and did not hold, because `alive "$pid"` was
#      being asked about a corpse. `--release` would delete a live sibling's lock.
#      So: walk the process ancestry for the long-lived `claude` process and record
#      THAT. When no such ancestor is found the pid is recorded as unverified and
#      liveness is never used to free the tree - it ages out via STALE_MIN instead.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# Per-task lock (0004): a task is isolated by its directory, so its lock lives there.
# AGENT_LOCK_SCOPE=task + TASK=<name> -> ARIS_OUTPUT/<task>/.lock ; otherwise checkout-wide.
if [ "${AGENT_LOCK_SCOPE:-checkout}" = "task" ] && [ -n "${TASK:-}" ]; then
  LOCK="${AGENT_LOCK:-$ROOT/ARIS_OUTPUT/$TASK/.lock}"
  mkdir -p "$(dirname "$LOCK")"
else
  LOCK="${AGENT_LOCK:-$ROOT/.agent-lock}"
fi
STALE_MIN="${STALE_MIN:-120}"
HOST="$(hostname 2>/dev/null || echo unknown-host)"

field() { sed -n "s/^$1=//p" "$LOCK" 2>/dev/null | head -1; }
alive() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }

# The pid whose lifetime IS the session. A hook runs several processes below it -
# the harness spawns a shell, the shell runs this script - so $PPID is a process
# that dies immediately. Walk up until a `claude` ancestor appears; bounded, so a
# strange tree costs a few ps calls and not a hang.
# Echoes "<pid> <kind>" on one line. It must NOT report the kind by setting a global:
# every caller reads it through $( ), which is a subshell, so an assignment inside would
# be discarded and every lock would record `unverified` even when the walk succeeded.
# That is exactly what the first version of this fix did, and the symptom was identical
# to the bug it was fixing - a lock that looks wrong for a reason you cannot see.
session_pid() {
  local p="$PPID" n=0 comm exe
  while [ -n "$p" ] && [ "$p" -gt 1 ] 2>/dev/null && [ "$n" -lt 12 ]; do
    # Match the EXECUTABLE, never a substring of the command line. Matching args
    # matched the harness's own parent shell, whose line carries
    # `/root/.claude/shell-snapshots/...`, and the walk then recorded a shell that
    # exits in milliseconds while reporting kind=session - a lock that is confidently
    # wrong, which is worse than one that admits it does not know.
    comm=$(ps -o comm= -p "$p" 2>/dev/null)
    exe=$(ps -o args= -p "$p" 2>/dev/null); exe=${exe%% *}; exe=${exe##*/}
    if [ "$comm" = claude ] || [ "$exe" = claude ] || [ "$exe" = claude-code ]; then
      echo "$p session"; return 0
    fi
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
    n=$((n + 1))
  done
  echo "$PPID unverified"
}

acquire() {
  if [ -f "$LOCK" ]; then
    local pid host who when
    pid=$(field pid); host=$(field host); who=$(field agent); when=$(field since)

    if [ -z "$pid" ] || [ -z "$host" ]; then
      echo "BLOCKED (WA-C.1): $LOCK exists but is not parseable (no pid=/host= line)." >&2
      echo "  An unreadable lock is treated as HELD, never as absent. Inspect it, then:" >&2
      echo "  bash general/checks/no_concurrent_writer.sh --release" >&2
      return 1
    fi
    if [ "$host" != "$HOST" ]; then
      echo "BLOCKED (WA-C.1): lock held by $who on host '$host' since $when." >&2
      echo "  This host is '$HOST'. A pid from another machine cannot be tested here," >&2
      echo "  so liveness is UNKNOWN, not dead (WA-C.3). Check that session, then release it there." >&2
      return 1
    fi
    if alive "$pid"; then
      echo "BLOCKED (WA-C.1): tree held by live pid $pid ($who) on $host since $when" >&2
      return 1
    fi
    # A lock whose writer could not identify its own session process is never judged
    # dead by liveness - the pid it holds was never the session's. Only STALE_MIN frees it.
    if [ "$(field pid_kind)" = unverified ]; then
      echo "BLOCKED (WA-C.1): lock from $who ($when) records an UNVERIFIED pid ($pid)." >&2
      echo "  That pid was the hook's shell, not a session, so 'not alive' proves nothing." >&2
      echo "  Confirm no session is running here, then: $0 --release" >&2
      return 1
    fi
    if [ -z "$(find "$LOCK" -mmin +"$STALE_MIN" 2>/dev/null)" ]; then
      echo "BLOCKED (WA-C.1): lock from pid $pid ($who) is not alive but is recent (<${STALE_MIN}m)." >&2
      echo "  Confirm no session is running, then: bash general/checks/no_concurrent_writer.sh --release" >&2
      return 1
    fi
    echo "WARN: stale lock from pid $pid ($who, $when) older than ${STALE_MIN}m; taking over." >&2
  fi

  local mypid mykind; read -r mypid mykind <<<"$(session_pid)"
  printf 'pid=%s\nhost=%s\nagent=%s\nsince=%s\npid_kind=%s\n' \
    "$mypid" "$HOST" "${AGENT_NAME:-claude-code}" "$(date -Is)" "$mykind" > "$LOCK"
  echo "lock acquired: $LOCK (pid $mypid on $HOST, $mykind)"
}

release() {
  [ -f "$LOCK" ] || { echo "no lock to release"; return 0; }
  local pid host; pid=$(field pid); host=$(field host)
  if [ -z "$pid" ] || [ -z "$host" ]; then
    rm -f "$LOCK"; echo "released an unparseable lock: $LOCK"; return 0
  fi
  if [ "$host" != "$HOST" ]; then
    echo "REFUSING to release: lock belongs to host '$host', this is '$HOST'." >&2
    return 1
  fi
  # Ownership is IDENTITY first, liveness second. SessionEnd releasing its own lock is
  # the normal path and must always work; everything else is a sibling's tree.
  local mypid mykind; read -r mypid mykind <<<"$(session_pid)"
  if [ "$pid" != "$mypid" ]; then
    if alive "$pid"; then
      echo "REFUSING to release: pid $pid is still alive - another session holds this tree." >&2
      return 1
    fi
    # Not mine, and 'dead' is not trustworthy when the pid was never a session.
    if [ "$(field pid_kind)" = unverified ] \
       && [ -z "$(find "$LOCK" -mmin +"$STALE_MIN" 2>/dev/null)" ]; then
      echo "REFUSING to release: lock records an UNVERIFIED pid ($pid) and is under ${STALE_MIN}m old." >&2
      echo "  Releasing it could hand this tree to a second writer. Confirm no session is" >&2
      echo "  running here, then remove $LOCK by hand." >&2
      return 1
    fi
  fi
  rm -f "$LOCK"
  echo "lock released: $LOCK"
}

# --------------------------------------------------------------------------
if [ "${SELFTEST:-0}" = "1" ]; then
  # SELFTEST is inherited by every child `bash $0` below. Clearing it here is
  # load-bearing: without it each child re-enters this block and forks again.
  export SELFTEST=0
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  export AGENT_LOCK="$T/.agent-lock"          # never touches the real tree
  ok=0; bad=0
  expect() { # expect <pass|fail> <label> <command>
    local want="$1" label="$2" cmd="$3" got
    if eval "$cmd" >/dev/null 2>&1; then got=pass; else got=fail; fi
    if [ "$got" = "$want" ]; then printf '  ok    %-46s %s\n' "$label" "$want"; ok=$((ok+1))
    else printf '  FAIL  %-46s wanted %s, got %s\n' "$label" "$want" "$got"; bad=$((bad+1)); fi
  }
  self="bash $0"

  echo "--- SELFTEST: no_concurrent_writer.sh (WA-A.3) ---"
  expect pass "acquires a free tree"                    "$self"
  expect fail "rejects the tree it just acquired"       "$self"

  sleep 45 & held=$!
  printf 'pid=%s\nhost=%s\nagent=other\nsince=%s\n' "$held" "$HOST" "$(date -Is)" > "$AGENT_LOCK"
  expect fail "rejects a tree held by a LIVE pid"       "$self"
  expect fail "refuses to release a LIVE sibling's lock" "$self --release"
  kill "$held" 2>/dev/null

  printf 'pid=%s\nhost=%s\nagent=other\nsince=%s\n' "$held" "$HOST" "$(date -Is)" > "$AGENT_LOCK"
  expect fail "rejects a dead-but-recent lock"          "$self"
  expect pass "releases a lock whose pid is dead"       "$self --release"
  expect pass "acquires again once released"            "$self"

  printf 'pid=1\nhost=some-other-machine\nagent=other\nsince=%s\n' "$(date -Is)" > "$AGENT_LOCK"
  expect fail "never judges a FOREIGN-HOST lock dead"   "$self"
  expect fail "refuses to release a foreign-host lock"  "$self --release"

  printf 'garbage not a lock\n' > "$AGENT_LOCK"
  expect fail "treats an UNPARSEABLE lock as held"      "$self"

  # The bug this version exists for: a lock whose pid was never a session process.
  # `alive` says dead, and the old code took that as permission to steal or release.
  rm -f "$AGENT_LOCK"
  printf 'pid=%s\nhost=%s\nagent=other\nsince=%s\npid_kind=unverified\n' \
    99999 "$HOST" "$(date -Is)" > "$AGENT_LOCK"
  expect fail "never STEALS on an unverified dead pid"  "$self"
  expect fail "never RELEASES an unverified dead pid"   "$self --release"

  # ...and the same lock, aged past STALE_MIN, must become releasable, or an
  # abandoned tree stays locked forever and the rule becomes something to work around.
  touch -d '3 hours ago' "$AGENT_LOCK" 2>/dev/null || touch -A -030000 "$AGENT_LOCK" 2>/dev/null
  expect pass "an AGED unverified lock can be released" "$self --release"

  # A session releasing its OWN lock is the normal SessionEnd path and must always work,
  # whether or not the ancestry walk found a claude process.
  rm -f "$AGENT_LOCK"
  $self >/dev/null 2>&1
  expect pass "a session releases its OWN lock"         "$self --release"

  # The matcher must key on the EXECUTABLE, not on a substring of the command line.
  # A shell whose args merely mention a claude path is not a session; calling it one
  # records a pid that dies in milliseconds and labels it kind=session.
  rm -f "$AGENT_LOCK"
  bash -c "cd '$(dirname "$0")/..' && AGENT_LOCK='$AGENT_LOCK' bash checks/$(basename "$0")" \
    /root/.claude/shell-snapshots/snapshot-bash >/dev/null 2>&1
  kind=$(sed -n 's/^pid_kind=//p' "$AGENT_LOCK")
  parent_comm=$(ps -o comm= -p "$(sed -n 's/^pid=//p' "$AGENT_LOCK")" 2>/dev/null)
  if [ "$kind" = session ] && [ "$parent_comm" != claude ]; then
    printf '  FAIL  %-46s %s\n' "matcher must not match a .claude PATH" "claimed session"; bad=$((bad+1))
  else
    printf '  ok    %-46s %s\n' "matcher must not match a .claude PATH" "$kind"; ok=$((ok+1))
  fi
  rm -f "$AGENT_LOCK"

  echo "--- $ok passed, $bad failed ---"
  [ "$bad" = 0 ] || { echo "SELFTEST FAILED"; exit 1; }
  echo "SELFTEST PASSED: watched it accept a free tree AND reject every way of losing one (WA-A.3)"
  exit 0
fi

case "${1:-}" in
  --release) release ;;
  "")        acquire ;;
  *)         echo "usage: $0 [--release]" >&2; exit 2 ;;
esac
