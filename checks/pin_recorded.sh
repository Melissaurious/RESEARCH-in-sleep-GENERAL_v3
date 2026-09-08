#!/usr/bin/env bash
# Every submodule pin this project is governed by must be NAMED in a decision record.
#
#   check:        bash agreements/checks/pin_recorded.sh
#   validate me:  SELFTEST=1 bash agreements/checks/pin_recorded.sh
#
# WHY THIS EXISTS
#
# `git commit -am` stages every modification to a tracked path, and a submodule gitlink IS
# a tracked path. On 2026-09-06 a commit whose subject was "r03a: STATUS VERIFIED; reseal
# without __pycache__" silently moved BOTH pins of research-wClaude-PART1_v2 — one of them
# to a branch tip that was explicitly meant to stay unpinned. The instruction at the time
# was "leave `M site` unstaged". The flag defeated it, nobody noticed for hours, and it was
# found by a human reading git history, not by anything automatic.
#
# The rule the project already had ("moving the pin is a deliberate commit with a decision
# record, never a drift") lived only in prose. A rule that lives only in prose is a rule a
# flag can sweep up. This makes it a gate.
#
# WHAT IT CHECKS, AND WHAT IT DELIBERATELY DOES NOT
#
# It does not inspect history, and it does not care which commit moved what. It asks one
# question of the CURRENT tree: for each submodule, does some decision record name the sha
# that is pinned right now? That is the property the prose rule was reaching for, it is
# true or false at any moment without a range, and it fails loudly the instant a pin moves
# to a value nobody has written down.
set -uo pipefail

# --------------------------------------------------------------------------
if [ "${SELFTEST:-0}" = "1" ]; then
  export SELFTEST=0
  ME="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  S="$T/sub"; P="$T/super"; mkdir -p "$S" "$P/docs/decisions"
  git -C "$S" init -q .; printf '# a\n' > "$S/A.md"
  git -C "$S" add -A; git -C "$S" -c user.email=t@t -c user.name=t commit -qm one
  SHA1=$(git -C "$S" rev-parse HEAD)
  printf '# b\n' > "$S/B.md"
  git -C "$S" add -A; git -C "$S" -c user.email=t@t -c user.name=t commit -qm two
  SHA2=$(git -C "$S" rev-parse HEAD)

  git -C "$P" init -q .
  printf 'x\n' > "$P/README.md"
  git -C "$P" add -A; git -C "$P" -c user.email=t@t -c user.name=t commit -qm init
  git -C "$P" -c protocol.file.allow=always submodule add -q "$S" layer 2>/dev/null
  git -C "$P" -C layer checkout -q "$SHA1" 2>/dev/null || git -C "$P/layer" checkout -q "$SHA1"
  git -C "$P" add layer
  printf '# 0001 - pin the layer\n\nPinned at `%s`.\n' "$SHA1" > "$P/docs/decisions/0001-pin.md"
  git -C "$P" add -A; git -C "$P" -c user.email=t@t -c user.name=t commit -qm pin

  BASE=$(git -C "$P" rev-parse HEAD)

  ok=0; bad=0
  expect() { # expect <pass|fail> <label> <mutation>
    local want="$1" label="$2" mut="$3" got
    # Every case COMMITS, so `checkout HEAD -- .` would carry the previous case's commit
    # forward and the cases would test each other. Reset to the baseline pin, and put the
    # submodule back too - a gitlink is not restored by resetting the superproject alone.
    ( cd "$P" && git reset -q --hard "$BASE" && git clean -qfd \
      && git -C layer checkout -q "$SHA1" && eval "$mut" ) >/dev/null 2>&1
    if ( cd "$P" && bash "$ME" ) >/dev/null 2>&1; then got=pass; else got=fail; fi
    if [ "$got" = "$want" ]; then printf '  ok    %-50s %s\n' "$label" "$want"; ok=$((ok+1))
    else printf '  FAIL  %-50s wanted %s, got %s\n' "$label" "$want" "$got"; bad=$((bad+1)); fi
  }

  echo "--- SELFTEST: pin_recorded.sh (WA-A.3) ---"
  expect pass "a pin that a decision record names"              "true"
  expect pass "the record may abbreviate the sha to 7"          "printf '# 0001\n\nPinned at \`%s\`.\n' \"\$(printf '%s' $SHA1 | cut -c1-7)\" > docs/decisions/0001-pin.md && git add -A && git -c user.email=t@t -c user.name=t commit -qm short"
  expect fail "the pin MOVED and no record names the new sha"   "git -C layer checkout -q $SHA2 && git add layer && git -c user.email=t@t -c user.name=t commit -qm 'unrelated subject'"
  expect fail "a record naming only the OLD sha does not count" "git -C layer checkout -q $SHA2 && git add layer && printf '# 0001\n\nPinned at \`%s\`.\n' $SHA1 > docs/decisions/0001-pin.md && git add -A && git -c user.email=t@t -c user.name=t commit -qm old"
  expect pass "the move IS recorded, in any record"             "git -C layer checkout -q $SHA2 && git add layer && printf '# 0002 - moved\n\nNow \`%s\`.\n' $SHA2 > docs/decisions/0002-move.md && git add -A && git -c user.email=t@t -c user.name=t commit -qm recorded"
  expect pass "no decisions dir - project does not use them"    "git rm -rq docs/decisions && git -c user.email=t@t -c user.name=t commit -qm nodocs"
  expect fail "a 6-char prefix is too short to satisfy it"      "git -C layer checkout -q $SHA2 && git add layer && printf '# 0001\n\n\`%s\`\n' \"\$(printf '%s' $SHA2 | cut -c1-6)\" > docs/decisions/0001-pin.md && git add -A && git -c user.email=t@t -c user.name=t commit -qm sixchar"

  echo "--- $ok passed, $bad failed ---"
  [ "$bad" = 0 ] || { echo "SELFTEST FAILED"; exit 1; }
  echo "SELFTEST PASSED: watched it reject an unrecorded pin move AND accept a recorded one"
  exit 0
fi

DECISIONS="${DECISIONS_DIR:-docs/decisions}"
fail=0
found_any=0

# No submodules, or a project that does not use decision records: out of scope, silent.
SUBS="$(git config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')"
[ -z "$SUBS" ] && { echo "OK: no submodules to pin"; exit 0; }
[ -d "$DECISIONS" ] || { echo "OK: no $DECISIONS/ — this project does not record decisions"; exit 0; }

for path in $SUBS; do
  sha=$(git ls-tree HEAD "$path" 2>/dev/null | awk '$2=="commit"{print $3}')
  [ -z "$sha" ] && { echo "SKIP: $path is not a gitlink in HEAD"; continue; }
  found_any=1
  # A record may name the sha in full or abbreviated; 7 is git's floor, so match on that
  # prefix and no shorter. Matching shorter would let an unrelated hex string satisfy it.
  short=$(printf '%s' "$sha" | cut -c1-7)
  if grep -rqE "\b${short}[0-9a-f]{0,33}\b" "$DECISIONS" 2>/dev/null; then
    echo "OK: $path pinned at $short, named in $DECISIONS/"
  else
    echo "UNRECORDED PIN: $path is pinned at $short and no record in $DECISIONS/ names it."
    echo "                Moving a pin is a deliberate commit with a decision record."
    echo "                If this move was intended, write the record. If it was not,"
    echo "                it is almost certainly 'git commit -a' staging the gitlink."
    fail=1
  fi
done

[ "$found_any" = 1 ] || { echo "OK: no gitlinks in HEAD"; exit 0; }
[ "$fail" = 0 ] && echo "OK: every pin is named in a decision record"

exit $fail
