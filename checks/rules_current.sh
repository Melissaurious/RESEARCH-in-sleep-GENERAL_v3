#!/usr/bin/env bash
# WA-A.2 — a PROVISIONAL rule expires unless a real case is named for it.
#
#   check:        bash agreements/checks/rules_current.sh [path/to/WORKING_AGREEMENT.md]
#   validate me:  SELFTEST=1 bash agreements/checks/rules_current.sh
#
# Reports three buckets so renewal is a decision, not a batch:
#   EXPIRED       past its window, still unvalidated  -> fails the check
#   DUE           expires within DUE_DAYS             -> visible before it bites
#   PROVISIONAL   proposed, still inside its window
#
# A rule's date is the day it was PROPOSED. WA-A.2 sets a rule's date forward only
# when a real case is named for it, so renewals stagger by when work actually
# exercised each rule, instead of all landing on the day the file was written.
set -uo pipefail

# In a consuming project the agreements are a submodule at agreements/; inside the
# layer's own repo they sit at the root. Resolve either, so the check runs in both.
if [ -n "${1:-}" ]; then WA="$1"
elif [ -f general/agreements/WORKING_AGREEMENT.md ]; then WA=general/agreements/WORKING_AGREEMENT.md
elif [ -f agreements/WORKING_AGREEMENT.md ]; then WA=agreements/WORKING_AGREEMENT.md
else WA=WORKING_AGREEMENT.md
fi
WINDOW_DAYS="${WINDOW_DAYS:-14}"
DUE_DAYS="${DUE_DAYS:-7}"
TODAY="${TODAY_OVERRIDE:-$(date +%F)}"

[ -f "$WA" ] || { echo "MISSING: $WA"; exit 1; }

now=$(date -d "$TODAY" +%s 2>/dev/null) || { echo "bad date: $TODAY"; exit 1; }
expired=0; due=0; prov=0; valid=0

# Pair each rule id with the validated: line that follows it.
while IFS=$'\t' read -r id line; do
  case "$line" in
    *PROVISIONAL*)
      d=$(printf '%s' "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
      if [ -z "$d" ]; then
        echo "EXPIRED     $id  PROVISIONAL with no date"; expired=$((expired+1)); continue
      fi
      age=$(( (now - $(date -d "$d" +%s)) / 86400 ))
      left=$(( WINDOW_DAYS - age ))
      if   [ "$left" -lt 0 ];          then echo "EXPIRED     $id  proposed $d, $(( -left ))d past its ${WINDOW_DAYS}d window"; expired=$((expired+1))
      elif [ "$left" -le "$DUE_DAYS" ]; then echo "DUE         $id  proposed $d, ${left}d left"; due=$((due+1))
      else prov=$((prov+1)); fi ;;
    *) valid=$((valid+1)) ;;
  esac
done < <(awk '
  /^\*\*WA-[A-Z]+\.[0-9]+\*\*/ { if (match($0, /WA-[A-Z]+\.[0-9]+/)) id = substr($0, RSTART, RLENGTH) }
  /^[[:space:]]*-?[[:space:]]*validated:/ { if (id != "") { print id "\t" $0; id = "" } }
' "$WA")

echo "---"
echo "validated: $valid   provisional: $prov   due within ${DUE_DAYS}d: $due   EXPIRED: $expired"
if [ "$expired" -gt 0 ]; then
  echo
  echo "WA-A.2: an expired rule is renewed only by naming a real case it caught."
  echo "A rule no row has ever exercised is DELETED or demoted to WHEN — never renewed in a batch."
  exit 1
fi
echo "OK: no expired rules"

# --------------------------------------------------------------------------
if [ "${SELFTEST:-0}" = "1" ]; then
  export SELFTEST=0
  ME="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  mk() { printf '**%s** [ALWAYS] x\n- check: manual\n- validated: %s\n\n' "$1" "$2" >> "$T/wa.md"; }
  ok=0; bad=0
  run() { TODAY_OVERRIDE="$1" bash "$ME" "$T/wa.md" 2>&1; }
  expect() { # expect <pass|fail> <label> <today> <grep-for>
    local want="$1" label="$2" today="$3" needle="$4" out got
    out=$(run "$today"); if [ $? = 0 ]; then got=pass; else got=fail; fi
    if [ "$got" = "$want" ] && printf '%s' "$out" | grep -q "$needle"; then
      printf '  ok    %-46s %s\n' "$label" "$want"; ok=$((ok+1))
    else printf '  FAIL  %-46s wanted %s/%s, got %s\n' "$label" "$want" "$needle" "$got"; bad=$((bad+1)); fi
  }
  : > "$T/wa.md"
  mk WA-Z.1 "2026-01-01 - caught a real thing"
  mk WA-Z.2 "PROVISIONAL 2026-09-04"
  mk WA-Z.3 "PROVISIONAL"
  echo "--- SELFTEST: rules_current.sh (WA-A.3) ---"
  expect fail "PROVISIONAL with no date is EXPIRED now"  "2026-09-05" "EXPIRED     WA-Z.3"
  expect fail "a rule 20d past its window is EXPIRED"    "2026-09-24" "EXPIRED     WA-Z.2"
  : > "$T/wa.md"; mk WA-Z.1 "2026-01-01 - real case"; mk WA-Z.2 "PROVISIONAL 2026-09-04"
  expect fail "still fails while any rule is expired"    "2026-09-30" "EXPIRED"
  : > "$T/wa.md"; mk WA-Z.2 "PROVISIONAL 2026-09-04"
  expect pass "flags DUE inside the warning window"      "2026-09-12" "DUE         WA-Z.2"
  expect pass "quiet while inside the window"            "2026-09-05" "provisional: 1"
  : > "$T/wa.md"; mk WA-Z.1 "2026-01-01 - real case"
  expect pass "a validated rule never expires"           "2027-01-01" "OK: no expired rules"
  echo "--- $ok passed, $bad failed ---"
  [ "$bad" = 0 ] || { echo "SELFTEST FAILED"; exit 1; }
  echo "SELFTEST PASSED: watched it reject expired rules AND accept validated ones (WA-A.3)"
  exit 0
fi
