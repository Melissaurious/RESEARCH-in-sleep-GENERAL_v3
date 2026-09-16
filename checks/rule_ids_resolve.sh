#!/usr/bin/env bash
# Every rule id cited anywhere in this layer resolves to a rule that exists.
#
#   bash checks/rule_ids_resolve.sh       # must print OK
#   SELFTEST=1 bash checks/rule_ids_resolve.sh
#
# Written because cutting 43 rules from the previous layer left 21 dangling citations --
# documents and scripts pointing at rule ids that no longer existed. specs_exist.sh did not
# catch them: it validates PATHS, not rule ids, and passed clean the whole time. A citation
# to a deleted rule is silent in exactly the way a reference to a deleted file is.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

ID_RE='\b(WA-[A-Y]\.[0-9]+|BS-[0-9]+|CL-[0-9]+|RM-[0-9]+)\b'

defined() {   # ids DEFINED by the agreements: **WA-x.y** or a leading "BS-n"
  { grep -ohE "^\*\*(WA-[A-Z]\.[0-9]+)\*\*" agreements/*.md | tr -d '*'
    grep -ohE "^(BS-[0-9]+)\b"              agreements/*.md; } | sort -u
}
cited() {     # ids CITED anywhere, excluding retros (historical) and this check's own
              # selftest fixtures -- which it would otherwise read as real citations.
              # RETRON_STAGES/ is imported historical prose carrying v6-era ids; its own README
              # says it is "source material, not an authority" -- excluded like retros/. RETRON_STAGES/
              # is imported historical prose carrying v6-era ids; its own README says it is
              # "source material, not an authority" -- excluded on the same grounds as retros/.
  grep -rohE "$ID_RE" --include='*.md' --include='*.sh' --include='*.py' \
       --exclude-dir=retros --exclude-dir=RETRON_STAGES --exclude-dir=.git \
       --exclude='rule_ids_resolve.sh' . 2>/dev/null \
    | grep -vE '^WA-Z\.' | sort -u
}

run() {
  local missing
  missing="$(comm -23 <(cited) <(defined))"
  if [ -n "$missing" ]; then
    echo "DEAD RULE IDS — cited but not defined in agreements/:"
    while read -r id; do
      [ -n "$id" ] || continue
      printf '  %-10s cited in: %s\n' "$id" \
        "$(grep -rlE "\b$id\b" --include='*.md' --include='*.sh' --include='*.py' . \
           | grep -v './retros/' | grep -v './RETRON_STAGES/' | grep -v 'rule_ids_resolve' | tr '\n' ' ')"
    done <<< "$missing"
    return 1
  fi
  echo "OK: every cited rule id resolves to a defined rule ($(defined | wc -l) defined, $(cited | wc -l) cited)"
}

if [ "${SELFTEST:-0}" = 1 ]; then
  T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
  pass=0; fail=0
  chk() { # chk <expect pass|fail> <label> <file-content-to-add-or-empty>
    local want="$1" label="$2" body="${3:-}"
    local tmpf=""
    [ -n "$body" ] && { tmpf="./__selftest_$$.md"; printf '%s\n' "$body" > "$tmpf"; }
    run >/dev/null 2>&1 && got=pass || got=fail
    [ -n "$tmpf" ] && rm -f "$tmpf"
    if [ "$got" = "$want" ]; then printf '  ok    %-44s %s\n' "$label" "$got"; pass=$((pass+1))
    else printf '  FAIL  %-44s want %s got %s\n' "$label" "$want" "$got"; fail=$((fail+1)); fi
  }
  chk pass "the layer as it stands resolves"            ""
  chk fail "a citation to a DELETED rule is rejected"   'see WA-Q.9 for the rule'
  chk fail "a second dead id is also rejected"          'governed by CL-7 and BS-99'
  chk pass "a citation to a LIVE rule is accepted"      'this follows WA-D.1 and BS-1'
  chk pass "an id inside retros/ is ignored (historical)" ''
  printf -- '--- %s passed, %s failed ---\n' "$pass" "$fail"
  [ "$fail" = 0 ] || { echo "SELFTEST FAILED"; exit 1; }
  echo "SELFTEST PASSED: watched it reject dead ids AND accept live ones"
  exit 0
fi
run
