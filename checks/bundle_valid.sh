#!/usr/bin/env bash
# BS-1..BS-11 — the only door a number enters through. Spec: BUNDLE_SPEC.md
#
#   check a bundle:  bash agreements/checks/bundle_valid.sh results/<ROW-ID>
#   validate me:     SELFTEST=1 bash agreements/checks/bundle_valid.sh
#
# WA-A.3. The selftest below builds a known-good bundle, watches it ACCEPT, then
# breaks ONE rule at a time and watches each REJECT. A rule with no seeded-bad
# case in that list has not been validated and may not be trusted.
set -uo pipefail

MANIFEST_HEADER=$'artifact\tscript\tcommand\tunit\tdenominator'

validate() {
  local B="$1" fail=0
  local f path sha rest now n artifact script k want got badpaths

  for f in MANIFEST.tsv INPUTS.tsv OUTPUTS.tsv run.sh README.md PROVENANCE.md; do
    [ -s "$B/$f" ] || { echo "MISSING/EMPTY: $f"; fail=1; }
  done
  { [ -d "$B/scripts" ] && [ -n "$(ls -A "$B/scripts" 2>/dev/null)" ]; } \
    || { echo "BS-1: scripts/ missing or empty"; fail=1; }

  # BS-2 — every input hashed, and the hash still matches.
  # `|| [ -n "$path" ]` is load-bearing: without it a final line with no trailing
  # newline is silently skipped, leaving the most recently added input unhashed.
  if [ -s "$B/INPUTS.tsv" ]; then
    n=0
    while IFS=$'\t' read -r path sha rest || [ -n "${path:-}" ]; do
      [ -z "${path:-}" ] && continue
      [ "$path" = "path" ] && continue
      n=$((n+1))
      if [ "${#sha}" != 64 ] || [ -n "$(printf '%s' "$sha" | tr -d '0-9a-fA-F')" ]; then
        echo "BS-2: not a sha256: $path -> '$sha'"; fail=1; continue
      fi
      [ -e "$path" ] || { echo "BS-2: INPUT GONE: $path"; fail=1; continue; }
      now=$(sha256sum "$path" | cut -d' ' -f1)
      [ "$now" = "$sha" ] || { echo "BS-2: INPUT CHANGED: $path"; fail=1; }
    done < "$B/INPUTS.tsv"
    [ "$n" -gt 0 ] || { echo "BS-2: INPUTS.tsv lists no inputs"; fail=1; }
  fi

  # MANIFEST shape, and BS-1 — every script it names is in the bundle.
  if [ -s "$B/MANIFEST.tsv" ]; then
    [ "$(head -1 "$B/MANIFEST.tsv")" = "$MANIFEST_HEADER" ] \
      || { echo "MANIFEST.tsv header must be: artifact<TAB>script<TAB>command<TAB>unit<TAB>denominator"; fail=1; }
    awk -F'\t' 'NR>1 && NF!=5 {print "MANIFEST.tsv line " NR " has " NF " fields, want 5"; bad=1}
                END {exit bad?1:0}' "$B/MANIFEST.tsv" || fail=1
    # BS-17: unit and denominator must SAY something. Checking the field COUNT and not the
    # field CONTENT is how a production tree reached 15 bundles with 100% known producers
    # and 0.0% denominator coverage -- every number reproducible, none of them citable.
    # "n/a - <why>" is accepted, as for seed (BS-9): a stated absence is a decision, an
    # empty string is an oversight, and the two must not look alike.
    awk -F'\t' 'NR>1 && NF==5 {
        for (i=4; i<=5; i++) { v=$i; gsub(/^[ \t]+|[ \t]+$/, "", v)
          if (v == "" || v == "-" || v == "?") {
            what = (i==4 ? "unit" : "denominator")
            print "BS-17: MANIFEST row " NR " (" $1 ") has an empty " what "."
            print "       A rate with no " what " is not citable. State it, or write"
            print "       \"n/a - <why>\" if this artifact carries no rate."
            bad=1 } } }
      END {exit bad?1:0}' "$B/MANIFEST.tsv" || fail=1
    while IFS=$'\t' read -r artifact script rest || [ -n "${artifact:-}" ]; do
      [ -z "${script:-}" ] && continue
      [ "$script" = "script" ] && continue
      [ -e "$B/$script" ] || { echo "BS-1: MANIFEST names '$script'; not in the bundle"; fail=1; }
    done < "$B/MANIFEST.tsv"
  fi

  # BS-3 — the bundle states whether run.sh has actually been rerun.
  grep -qE '^STATUS: (VERIFIED|UNVERIFIED)([[:space:]]|$)' "$B/README.md" 2>/dev/null \
    || { echo "BS-3: README.md needs 'STATUS: VERIFIED' or 'STATUS: UNVERIFIED <why>'"; fail=1; }

  # BS-3 — and run.sh can FIND what the bundle ships with. A row develops in a scratch
  # directory where the scripts sit beside run.sh; the bundle puts them in scripts/. A
  # run.sh written against the scratch layout resolves every self-relative path one
  # directory too shallow and reruns NOWHERE — however many times the row reproduced
  # before assembly. r03a (2026-09-06) passed two independent full passes, was assembled,
  # and then died on `can't open file '.../s00_fixture.py'` before reading one record.
  # Nothing inside a row can catch this, because the row never runs the assembled layout.
  #
  # Find the variable run.sh sets from its own location, follow the variables derived
  # from it, and resolve every literal path built on them. A reference that stays inside
  # the bundle must exist. A reference that climbs out (r01's tables, the source data)
  # is not this bundle's to vouch for and is skipped.
  if [ -s "$B/run.sh" ]; then
    badpaths=$(awk -v B="$B" '
      function norm(p,  a,n,i,k,o,out) {
        n = split(p, a, "/"); k = 0
        for (i = 1; i <= n; i++) {
          if (a[i] == "" || a[i] == ".") continue
          if (a[i] == "..") { if (k == 0) return ""; k--; continue }   # climbs out
          o[++k] = a[i]
        }
        out = ""
        for (i = 1; i <= k; i++) out = out (i > 1 ? "/" : "") o[i]
        return out
      }
      { L[NR] = $0 }
      END {
        # pass 1 - collect the self-location variable and every simple assignment
        # derived from another variable. Resolved to a FIXPOINT, not in file order:
        # a shallow `S=$HERE` above the line that sets HERE is the same defect.
        for (i = 1; i <= NR; i++) {
          if (L[i] ~ /BASH_SOURCE/ && match(L[i], /^[ \t]*[A-Za-z_][A-Za-z0-9_]*=/)) {
            v = substr(L[i], RSTART, RLENGTH - 1); sub(/^[ \t]*/, "", v)
            rooted[v] = "."; done[i] = 1; continue
          }
          if (match(L[i], /^[ \t]*[A-Za-z_][A-Za-z0-9_]*="?\$\{?[A-Za-z_][A-Za-z0-9_]*\}?(\/[A-Za-z0-9_.\/-]*)?"?[ \t]*$/)) {
            line = L[i]; sub(/^[ \t]*/, "", line); sub(/[ \t]*$/, "", line)
            eq = index(line, "="); lhs[i] = substr(line, 1, eq - 1)
            rhs = substr(line, eq + 1); gsub(/"/, "", rhs); gsub(/[{}$]/, "", rhs)
            sl = index(rhs, "/")
            src[i] = (sl ? substr(rhs, 1, sl - 1) : rhs)
            tail[i] = (sl ? substr(rhs, sl) : "")
            done[i] = 1
          }
        }
        do {
          changed = 0
          for (i = 1; i <= NR; i++)
            if (lhs[i] != "" && !(lhs[i] in rooted) && (src[i] in rooted)) {
              rooted[lhs[i]] = rooted[src[i]] tail[i]; changed = 1
            }
        } while (changed)

        # pass 2 - every literal reference built on a rooted variable
        for (i = 1; i <= NR; i++) {
          if (done[i]) continue
          rest = L[i]
          while (match(rest, /\$\{?[A-Za-z_][A-Za-z0-9_]*\}?\/[A-Za-z0-9_.\/-]+/)) {
            tok = substr(rest, RSTART, RLENGTH); rest = substr(rest, RSTART + RLENGTH)
            t = tok; gsub(/[{}$]/, "", t)
            sl = index(t, "/"); v = substr(t, 1, sl - 1)
            if (!(v in rooted)) continue
            rel = norm(rooted[v] substr(t, sl))
            if (rel == "") continue                 # resolves outside the bundle
            if (system("test -e " "\"" B "/" rel "\"") != 0)
              print "BS-3: run.sh line " i " reads `" tok "` -> " B "/" rel ", which is not in the bundle"
          }
        }
      }
    ' "$B/run.sh")
    [ -z "$badpaths" ] || { printf '%s\n' "$badpaths"; fail=1; }
  fi

  # BS-12 — a proposed status must be for a claim that ALREADY EXISTS.
  #
  # A bundle's README ends with a paste-ready block of CLAIMS.md status lines. Nothing
  # ever checked that the ids in it are real, and twice now the same failure ran:
  # a row discovered a claim mid-flight, INVENTED an id for it (r01c's "C22"), nobody
  # transcribed it into the ledger, and a later session reused that number for a
  # different claim — with a row already executing against the second one.
  #
  # WA-L.1 says the claim exists as UNPROVEN BEFORE the row runs. WA-L.1 says the ledger is
  # the operator's. A row that hands itself a new id breaks both. A row that discovers a
  # new claim describes it in PROSE; the operator assigns the number. So: every claim id
  # the README proposes a status for must already be a row in CLAIMS.md.
  #
  # The ledger lives in the TRACK'S LAUNCHER, section 3b — claims are declared there and
  # nowhere else, so the operator writes one document per track (WA-L.1). Search order:
  # CLAIMS_MD, then every launcher in the project, then a standalone CLAIMS.md for a
  # project that still keeps one.
  #
  # Reading EVERY launcher rather than "the" launcher is deliberate: a bundle does not
  # record which track it belongs to, and inferring it from the gate id would make the
  # check fail open on any naming the guess did not anticipate. A grep over all of them
  # costs nothing and cannot miss a declared claim.
  # v7: the research contract is the ONE claim authority. Resolving against launchers or a
  # root CLAIMS.md kept a second claim architecture alive mechanically while the prose said
  # otherwise -- two authorities that disagree within a week.
  ledger="${CLAIMS_MD:-}"
  if [ -z "$ledger" ] && [ -n "$ROOT" ] && [ -f "$ROOT/idea-stage/docs/research_contract.md" ]; then
    ledger="$ROOT/idea-stage/docs/research_contract.md"
  fi
  _legacy_ledger=0
  LEDGER_TMP=""
  LEDGER_NAME=""
  if [ -z "$ledger" ]; then
    ROOT="$(git -C "$B" rev-parse --show-toplevel 2>/dev/null)"
    if [ "$_legacy_ledger" = 1 ] && [ -n "$ROOT" ] && ls "$ROOT"/launchers/*.md >/dev/null 2>&1; then
      LEDGER_TMP="$(mktemp)"
      cat "$ROOT"/launchers/*.md > "$LEDGER_TMP"
      ledger="$LEDGER_TMP"
      LEDGER_NAME="the claims tables in $ROOT/launchers/"
    fi
  fi
  if [ -z "$ledger" ]; then
    for k in ${_legacy_ledger:+"$B/../../CLAIMS.md" "$(git -C "$B" rev-parse --show-toplevel 2>/dev/null)/CLAIMS.md"}; do
      [ -f "$k" ] && { ledger="$k"; break; }
    done
  fi
  if [ -n "$ledger" ] && [ -f "$ledger" ] && [ -s "$B/README.md" ]; then
    while IFS= read -r cid; do
      [ -z "$cid" ] && continue
      grep -qE "^\|[[:space:]]*\`?(~~)?${cid}(~~)?\`?[[:space:]]*\|" "$ledger" \
        || { echo "BS-12: README proposes a status for $cid, which is not a declared claim in ${LEDGER_NAME:-$ledger}."
             echo "       A gate may PROPOSE a new claim in prose; it may not assign the id (WA-L.1, WA-L.1)."
             fail=1; }
    done < <(grep -oE '^\|[[:space:]]*`?(~~)?([a-z0-9][a-z0-9_-]*:)?C[0-9]+[^|`[:space:]]*' "$B/README.md" \
             | grep -oE '([a-z0-9][a-z0-9_-]*:)?C[0-9]+[^|`[:space:]]*' | sed 's/~~$//' | sort -u)
  fi
  [ -n "${LEDGER_TMP:-}" ] && { rm -f "$LEDGER_TMP" 2>/dev/null; LEDGER_TMP=""; }

  # BS-13 — a figure names the script that drew it, and ships what it plots.
  #
  # The Layout section of BUNDLE_SPEC.md has said both since the spec was written.
  # Neither was ever checked, and by the tenth bundle 16 of 35 figures had landed with
  # no table carrying their numbers. BS-11 hashes a figure perfectly whether or not
  # anyone can say where it came from, so nothing else notices.
  #
  # Traceability FAILS: an untraceable figure cannot be redrawn or defended.
  # Same-basename table WARNS: bundles are write-once (BS-6), so the ones that landed
  # before this check cannot be repaired in place. The warn count is the debt.
  if [ -d "$B/figures" ]; then
    # Per FIGURE, not per file. One figure ships as png + svg (+ eps), all drawn by one
    # script, and a rule that demanded a MANIFEST row per file failed nine landed
    # bundles for owning an svg. Non-image files in figures/ are not figures.
    while IFS= read -r stem; do
      [ -z "$stem" ] && continue
      cut -f1 "$B/MANIFEST.tsv" 2>/dev/null | grep -qE "^figures/${stem}\.[A-Za-z0-9]+$" \
        || { echo "BS-13: figures/$stem.* is in no MANIFEST.tsv row - no script claims it"
             fail=1; }
      [ -s "$B/tables/$stem.tsv" ] \
        || echo "BS-13 WARN: figures/$stem has no tables/$stem.tsv - a restyle needs a rerun"
    done < <(find "$B/figures" -maxdepth 1 -type f \
               \( -iname '*.png' -o -iname '*.svg' -o -iname '*.eps' -o -iname '*.pdf' \) \
               -printf '%f\n' 2>/dev/null | sed 's/\.[^.]*$//' | sort -u)
  fi

  # BS-4 — an sbatch that ran must be in the bundle.
  if grep -q 'sbatch' "$B/run.sh" 2>/dev/null; then
    { [ -d "$B/slurm" ] && [ -n "$(ls -A "$B/slurm" 2>/dev/null)" ]; } \
      || { echo "BS-4: run.sh calls sbatch but slurm/ is empty"; fail=1; }
  fi

  # BS-5 — counts that make defects visible.
  for k in attempted succeeded dropped; do
    grep -qiE "n_$k[[:space:]]*[:=]" "$B/README.md" 2>/dev/null \
      || { echo "BS-5: README.md has no 'n_$k:' count"; fail=1; }
  done

  # BS-8 — the environment is pinned by CONTENT. A conda env name is not a pin.
  if [ -s "$B/env.lock" ]; then
    want=$(grep -oE '^env_lock_sha256:[[:space:]]*[0-9a-f]{64}' "$B/PROVENANCE.md" 2>/dev/null \
           | grep -oE '[0-9a-f]{64}')
    got=$(sha256sum "$B/env.lock" | cut -d' ' -f1)
    if [ -z "$want" ]; then
      echo "BS-8: PROVENANCE.md has no 'env_lock_sha256: <sha>' line"; fail=1
    elif [ "$want" != "$got" ]; then
      echo "BS-8: env.lock does not match env_lock_sha256 in PROVENANCE.md"; fail=1
    fi
  else
    echo "BS-8: env.lock missing — record the environment, not its name"; fail=1
  fi

  # BS-9 — a seed is declared, even if only to say there is no RNG.
  grep -qE '^seed:[[:space:]]*\S' "$B/PROVENANCE.md" 2>/dev/null \
    || { echo "BS-9: PROVENANCE.md needs 'seed: <n>' or 'seed: n/a — <why>'"; fail=1; }

  # BS-10 — which agreements governed this run.
  grep -qE '^agreements:[[:space:]]*[0-9a-f]{7,40}' "$B/PROVENANCE.md" 2>/dev/null \
    || { echo "BS-10: PROVENANCE.md needs 'agreements: <sha>'"; fail=1; }

  # BS-11 — the bundle's OWN files are hashed, not just its inputs.
  # Without this the artifact that carries the number has no integrity check at all:
  # BS-2 hashes what went in, BS-8 hashes the environment, and the result TSV that the
  # paper will quote can be edited afterwards with every other rule still passing.
  # This is also what makes BS-6 (write-once) checkable instead of prose.
  if [ -s "$B/OUTPUTS.tsv" ]; then
    n=0
    while IFS=$'\t' read -r rel sha rest || [ -n "${rel:-}" ]; do
      [ -z "${rel:-}" ] && continue
      [ "$rel" = "path" ] && continue
      n=$((n+1))
      if [ "${#sha}" != 64 ] || [ -n "$(printf '%s' "$sha" | tr -d '0-9a-fA-F')" ]; then
        echo "BS-11: not a sha256: $rel -> '$sha'"; fail=1; continue
      fi
      [ -e "$B/$rel" ] || { echo "BS-11: BUNDLE FILE GONE: $rel"; fail=1; continue; }
      now=$(sha256sum "$B/$rel" | cut -d' ' -f1)
      [ "$now" = "$sha" ] || { echo "BS-11: BUNDLE FILE CHANGED SINCE IT LANDED: $rel"; fail=1; }
    done < "$B/OUTPUTS.tsv"
    [ "$n" -gt 0 ] || { echo "BS-11: OUTPUTS.tsv lists no files"; fail=1; }

    # The direction that actually matters: a file ADDED to a landed bundle is not
    # covered by any hash, so listing must be exhaustive, not merely accurate.
    while IFS= read -r f; do
      grep -qF "$(printf '%s\t' "$f")" "$B/OUTPUTS.tsv" \
        || { echo "BS-11: bundle file not listed in OUTPUTS.tsv: $f"; fail=1; }
    done < <(cd "$B" && find . -type f ! -name OUTPUTS.tsv -not -path './__pycache__/*' -not -path './*/__pycache__/*' -printf '%P\n' | sort)
  fi

  return $fail
}

# Write OUTPUTS.tsv over every file in the bundle except itself (BS-11). Written
# LAST, after README.md carries its final STATUS line — otherwise acceptance, which
# edits README, invalidates the hashes it just recorded.
outputs() {
  local B="$1" f
  { printf 'path\tsha256\tbytes\n'
    while IFS= read -r f; do
      printf '%s\t%s\t%s\n' "$f" "$(sha256sum "$B/$f" | cut -d' ' -f1)" "$(stat -c%s "$B/$f")"
    done < <(cd "$B" && find . -type f ! -name OUTPUTS.tsv -not -path './__pycache__/*' -not -path './*/__pycache__/*' -printf '%P\n' | sort)
  } > "$B/OUTPUTS.tsv"
}

if [ "${1:-}" = "--write-outputs" ]; then
  outputs "${2:?usage: bundle_valid.sh --write-outputs results/<ROW-ID>}"
  echo "wrote ${2}/OUTPUTS.tsv"; exit 0
fi

# --------------------------------------------------------------------------
if [ "${SELFTEST:-0}" = "1" ]; then
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  good="$T/good"; mkdir -p "$good/scripts"
  echo "real input" > "$T/in.txt"
  H=$(sha256sum "$T/in.txt" | cut -d' ' -f1)
  printf 'path\tsha256\tbytes\tmtime\n%s\t%s\t11\t2026-09-04\n' "$T/in.txt" "$H" > "$good/INPUTS.tsv"
  echo 'print("hi")' > "$good/scripts/count.py"
  { printf '%s\n' "$MANIFEST_HEADER"
    printf 'n.tsv\tscripts/count.py\tpython scripts/count.py\tper record\t100\n'
    printf 'figures/fig_counts.png\tscripts/count.py\tpython scripts/count.py\tper record\t100\n'
  } > "$good/MANIFEST.tsv"
  # A figure and the table it plots, so `expect accept` exercises BS-13's accept path.
  # Without one in the good fixture the rule is silent in every case and its two
  # reject/warn tests below would pass against a check that never ran.
  mkdir -p "$good/figures" "$good/tables"
  printf 'not really a png\n' > "$good/figures/fig_counts.png"
  printf 'bin\tn\n1\t98\n'  > "$good/tables/fig_counts.tsv"
  # run.sh in the shape every real row uses: self-locating, with a variable derived
  # from that location. A good bundle that never builds a self-relative path cannot
  # demonstrate the BS-3 path rule accepting anything.
  { echo 'HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"'
    echo 'S="$HERE/scripts"'
    echo 'python "$S/count.py"'; } > "$good/run.sh"
  { printf 'STATUS: VERIFIED\nn_attempted: 100\nn_succeeded: 98\nn_dropped: 2 (short reads)\n'
    printf '\n## For the operator - proposed, not applied\n\n'
    printf '| C1 | the claim | G1 | MEASURED | NONE | SUPPORTED | this-row | 2026-09-06 |\n'
  } > "$good/README.md"
  # A ledger for BS-12 to resolve against. The bundle in this selftest is not inside a
  # project tree, so CLAIMS_MD is how the rule is reached; the no-ledger case below
  # covers the other branch.
  printf '| ID | Claim | Serves | Grade | Circ. | Status | Settled by | Date |\n' > "$T/CLAIMS.md"
  printf '| C1 | the claim | G1 | - | NONE | UNPROVEN | - | |\n' >> "$T/CLAIMS.md"
  printf '| ~~C3~~ | withdrawn | G1 | - | NONE | WITHDRAWN | - | |\n' >> "$T/CLAIMS.md"
  export CLAIMS_MD="$T/CLAIMS.md"
  printf 'name: selftest-env\n' > "$good/env.lock"
  E=$(sha256sum "$good/env.lock" | cut -d' ' -f1)
  printf 'stage: selftest\ngit_sha: abc1234\nagreements: abc1234\nenv_lock_sha256: %s\nseed: 7\n' \
    "$E" > "$good/PROVENANCE.md"
  printf 'n\n98\n' > "$good/n.tsv"                    # the artifact the paper would quote
  outputs "$good"                                     # BS-11, written last

  ok=0; bad=0
  expect() { # expect <accept|reject> <label> <mutation>
    local want="$1" label="$2" mut="$3" got
    local C="$T/case"; rm -rf "$C"; cp -r "$good" "$C"
    # The BS-2 case tampers with the SHARED input file, which lives outside the bundle
    # and so is not restored by copying $good. Restore it here or every case after it
    # rejects for BS-2 rather than for its own rule — invisible while exactly one
    # `expect accept` existed, and it ran first. (Same class as the specs_exist.sh
    # harness bug: a selftest that leaks state tests the leak, not the rule.)
    echo "real input" > "$T/in.txt"
    ( cd "$C" && eval "$mut" ) >/dev/null 2>&1
    if validate "$C" >/dev/null 2>&1; then got=accept; else got=reject; fi
    if [ "$got" = "$want" ]; then printf '  ok    %-46s %s\n' "$label" "$want"; ok=$((ok+1))
    else printf '  FAIL  %-46s wanted %s, got %s\n' "$label" "$want" "$got"; bad=$((bad+1)); fi
  }

  echo "--- SELFTEST: bundle_valid.sh (WA-A.3) ---"
  expect accept "a known-good bundle"                    "true"
  expect reject "BS-2 last input, NO trailing newline"   "printf '/nope\tdeadbeefdeadbeef\t9\t2026-09-04' >> INPUTS.tsv"
  expect reject "BS-2 input file has changed"            "echo tampered > '$T/in.txt'"
  expect reject "BS-2 no inputs listed at all"           "printf 'path\tsha256\tbytes\tmtime\n' > INPUTS.tsv"
  expect reject "BS-1 MANIFEST names a missing script"   "mv scripts/count.py scripts/other.py"
  expect reject "BS-1 scripts/ is empty"                 "mv scripts/count.py ./count.py.bak"
  expect reject "MANIFEST header wrong"                  "printf 'a\tb\tc\td\te\n' > MANIFEST.tsv"
  expect reject "MANIFEST row has 4 fields not 5"        "printf 'n.tsv\tscripts/count.py\tcmd\tunit\n' >> MANIFEST.tsv"
  # BS-17 -- the field COUNT was checked and the field CONTENT never was, which is how a
  # production tree reached 0.0% denominator coverage with every bundle passing.
  expect reject "BS-17 empty denominator"                "printf 'n2.tsv\tscripts/count.py\tcmd\tper RT\t\n' >> MANIFEST.tsv; outputs ."
  expect reject "BS-17 empty unit"                       "printf 'n3.tsv\tscripts/count.py\tcmd\t\t6472 msr-msd pairs\n' >> MANIFEST.tsv; outputs ."
  expect reject "BS-17 a bare dash is not a denominator" "printf 'n4.tsv\tscripts/count.py\tcmd\tper RT\t-\n' >> MANIFEST.tsv; outputs ."
  expect accept "BS-17 'n/a - <why>' is a stated absence" "printf 'n5.tsv\tscripts/count.py\tcmd\tn/a - a figure\tn/a - carries no rate\n' >> MANIFEST.tsv; outputs ."
  expect reject "BS-13 a figure no MANIFEST row claims" \
    "grep -v '^figures/' MANIFEST.tsv > m && mv m MANIFEST.tsv; outputs ."
  expect accept "BS-13 figure with no data table WARNS only" \
    "rm tables/fig_counts.tsv; outputs ."
  expect reject "BS-3 README declares no STATUS"         "grep -v '^STATUS:' README.md > r && mv r README.md"
  # run.sh is itself a bundle file, so a mutation that edits it also breaks BS-11.
  # `outputs .` re-seals the bundle afterwards, so each case below rejects (or accepts)
  # for ITS OWN rule and not for a hash it invalidated on the way in.
  expect reject "BS-3 run.sh resolves scripts/ too shallow" \
    "{ echo 'S=\"\$HERE\"'; grep -v '^S=' run.sh; } > r && mv r run.sh; outputs ."
  expect reject "BS-3 run.sh calls a script not in scripts/" \
    "echo 'python \"\$S/absent.py\"' >> run.sh; outputs ."
  expect accept "BS-3 a path that climbs OUT of the bundle" \
    "echo 'cat \"\$HERE/../r01-census/tables/x.tsv\"' >> run.sh; outputs ."
  expect accept "BS-3 an unrooted var is not this rule's business" \
    "echo 'cat \"\$OUTDIR/whatever.tsv\"' >> run.sh; outputs ."
  expect reject "BS-12 README proposes an id NOT in the ledger" \
    "printf '| C99 | invented | G1 | MEASURED | NONE | SUPPORTED | this-row | 2026-09-06 |\n' >> README.md; outputs ."
  expect accept "BS-12 a WITHDRAWN claim is still a claim" \
    "printf '| ~~C3~~ | withdrawn | G1 | MEASURED | NONE | WITHDRAWN | this-row | 2026-09-06 |\n' >> README.md; outputs ."
  expect reject "BS-4 sbatch called, slurm/ absent"      "echo 'sbatch job.sh' >> run.sh; outputs ."
  expect reject "BS-5 no n_dropped count"                "grep -v n_dropped README.md > r && mv r README.md"
  expect reject "BS-8 env.lock absent"                   "mv env.lock env.lock.gone"
  expect reject "BS-8 env.lock does not match its sha"   "echo drifted >> env.lock"
  expect reject "BS-8 no env_lock_sha256 recorded"       "grep -v env_lock_sha256 PROVENANCE.md > p && mv p PROVENANCE.md"
  expect reject "BS-9 no seed declared"                  "grep -v '^seed:' PROVENANCE.md > p && mv p PROVENANCE.md"
  expect reject "BS-10 no agreements sha"                "grep -v '^agreements:' PROVENANCE.md > p && mv p PROVENANCE.md"
  expect reject "BS-11 a landed result file was EDITED"  "echo 99 >> n.tsv"
  expect reject "BS-11 a file was ADDED after landing"   "echo extra > sneaked_in.tsv"
  expect reject "BS-11 a listed bundle file is gone"     "mv n.tsv n.tsv.gone"
  expect reject "BS-11 OUTPUTS.tsv absent"               "mv OUTPUTS.tsv OUTPUTS.gone"
  expect reject "BS-11 OUTPUTS.tsv lists nothing"        "printf 'path\tsha256\tbytes\n' > OUTPUTS.tsv"
  # The other branch of BS-12, which `expect` cannot reach: the mutation runs in a
  # SUBSHELL, so an `export` inside it never reaches the `validate` that follows. A
  # project with no ledger must be accepted even with an invented id in its README.
  C="$T/noledger"; rm -rf "$C"; cp -r "$good" "$C"
  printf '| C99 | invented | G1 | MEASURED | NONE | SUPPORTED | r | 2026-09-06 |\n' >> "$C/README.md"
  ( cd "$C" && outputs . )
  if ( CLAIMS_MD="$T/no-such-ledger.md"; export CLAIMS_MD; validate "$C" ) >/dev/null 2>&1; then
    printf '  ok    %-46s %s\n' "BS-12 no ledger in this project - rule silent" "accept"; ok=$((ok+1))
  else
    printf '  FAIL  %-46s %s\n' "BS-12 no ledger in this project - rule silent" "wanted accept"; bad=$((bad+1))
  fi

  echo "--- $ok passed, $bad failed ---"
  [ "$bad" = 0 ] || { echo "SELFTEST FAILED"; exit 1; }
  echo "SELFTEST PASSED: every rule watched rejecting a seeded-bad bundle, and accepting a good one"
  exit 0
fi

B="${1:?usage: bundle_valid.sh results/<ROW-ID>}"
if validate "$B"; then
  echo "OK: $B passes BS-1..BS-10."
  echo "bundle_status: REPRODUCIBLE   human_input_audit: PENDING"
  echo "Downstream work may continue on this bundle now. The input audit is a separate,"
  echo "non-blocking state, required only before a number becomes a paper or thesis claim."
  exit 0
fi
exit 1
