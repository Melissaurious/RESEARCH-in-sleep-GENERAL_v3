#!/usr/bin/env bash
# Assemble a bundle from a gate's scratch directory — the FIXED cost of provenance,
# done by script so the session's effort goes to the controls instead of the paperwork.
#
#   bash general/tools/bundle.sh <gate-id> [--seed N] [--models "a,b"]
#
# It writes:  scripts/ (verbatim)  INPUTS.tsv  env.lock  PROVENANCE.md  README.md skeleton
# It does NOT write:  run.sh (the session writes it), OUTPUTS.tsv (sealed LAST, after the
# README's final STATUS line — sealing early records hashes that acceptance invalidates).
#
# Inputs come from `ARIS_OUTPUT/<gate>/INPUTS.list`, one absolute path per line, written by
# the session as it reads things. That file is the one piece this cannot infer: a script can
# see which files exist, never which ones the measurement actually depended on, and guessing
# would produce an INPUTS.tsv that looks complete and is not (BS-2).
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ROOT="$(pwd)"

GATE="${1:-}"; shift || true
[ -n "$GATE" ] || { echo "usage: bash general/tools/bundle.sh <gate-id> [--seed N] [--models \"a,b\"] [--scratch DIR]" >&2; exit 2; }
SEED=""; MODELS=""; SCRATCH_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --seed)    SEED="${2:-}"; shift 2 ;;
    --scratch) SCRATCH_OVERRIDE="${2:-}"; shift 2 ;;
    --models) MODELS="${2:-}"; shift 2 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

# A launcher's write boundary is per TRACK (ARIS_OUTPUT/<track>/), so a gate's scratch is
# usually NESTED: ARIS_OUTPUT/<track>/<gate>. Assuming a flat ARIS_OUTPUT/<gate> made this
# script miss the directory and forced a symlink workaround in a real gate. Resolve the flat
# path, then the nested one, then accept an explicit --scratch.
if [ -n "${SCRATCH_OVERRIDE:-}" ]; then
  SCRATCH="$SCRATCH_OVERRIDE"
elif [ -d "ARIS_OUTPUT/$GATE" ]; then
  SCRATCH="ARIS_OUTPUT/$GATE"
else
  # one level down: ARIS_OUTPUT/*/<gate>, or ARIS_OUTPUT/*/<gate-without-track-prefix>
  SHORT="${GATE#*-}"
  SCRATCH=""
  for c in ARIS_OUTPUT/*/"$GATE" ARIS_OUTPUT/*/"$SHORT"; do
    [ -d "$c" ] && { SCRATCH="$c"; break; }
  done
  [ -n "$SCRATCH" ] || SCRATCH="ARIS_OUTPUT/$GATE"   # report the flat path in the error
fi
B="results/$GATE"
[ -d "$SCRATCH" ] || { echo "no scratch directory: $SCRATCH" >&2; exit 1; }
[ -e "$B" ] && { echo "REFUSING: $B exists. Bundles are write-once (BS-6) — a correction is a NEW bundle id naming its predecessor." >&2; exit 1; }

say() { printf '  %s\n' "$*"; }
mkdir -p "$B/scripts" "$B/tables" "$B/figures"

# --- scripts, verbatim (BS-1) --------------------------------------------------------
n=0
for f in "$SCRATCH"/*.py "$SCRATCH"/*.sh "$SCRATCH"/*.R "$SCRATCH"/scripts/*; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in run.sh) continue ;; esac
  cp "$f" "$B/scripts/" && n=$((n+1))
done
say "scripts copied verbatim: $n"
[ "$n" -gt 0 ] || say "!! no scripts found in $SCRATCH — a bundle with no producing script is not evidence"

# --- inputs, hashed (BS-2) -----------------------------------------------------------
LIST="$SCRATCH/INPUTS.list"
printf 'path\tsha256\tbytes\tmtime\n' > "$B/INPUTS.tsv"
if [ -f "$LIST" ]; then
  ni=0; missing=0
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    case "$p" in \#*) continue ;; esac
    if [ -f "$p" ]; then
      printf '%s\t%s\t%s\t%s\n' "$p" "$(sha256sum "$p" | cut -d' ' -f1)" \
        "$(stat -c%s "$p")" "$(stat -c%y "$p" | cut -d'.' -f1)" >> "$B/INPUTS.tsv"
      ni=$((ni+1))
    else
      echo "  !! INPUT MISSING: $p" >&2; missing=$((missing+1))
    fi
  done < "$LIST"
  say "inputs hashed: $ni${missing:+, MISSING $missing}"
  [ "${missing:-0}" -eq 0 ] || { echo "REFUSING to continue: an unhashed input means the bundle is incomplete, not mostly fine (BS-2)." >&2; exit 1; }
else
  say "!! $LIST absent — INPUTS.tsv is EMPTY and this bundle is incomplete (BS-2)"
  say "   write one absolute path per line as you read things, then re-run"
fi

# --- environment, by content not by name (BS-8) --------------------------------------
if command -v conda >/dev/null 2>&1 && conda env export --no-builds > "$B/env.lock" 2>/dev/null; then
  say "env.lock written by conda env export"
elif command -v pip >/dev/null 2>&1 && pip freeze > "$B/env.lock" 2>/dev/null; then
  say "env.lock written by pip freeze (conda unavailable)"
else
  echo "!! could not capture the environment — BS-8 unmet, BS-3 cannot hold without it" >&2
fi
ENVSHA="$( [ -s "$B/env.lock" ] && sha256sum "$B/env.lock" | cut -d' ' -f1 || echo MISSING )"

# --- provenance (BS-9, BS-10, BS-15) -------------------------------------------------
{
  printf 'gate: %s\n' "$GATE"
  printf 'scratch: %s\n' "$SCRATCH"
  printf 'git_sha: %s\n' "$(git rev-parse --short HEAD 2>/dev/null || echo UNKNOWN)"
  printf 'agreements: %s\n' "$(bash "$ROOT/general/tools/general_sha.sh" 2>/dev/null || echo UNKNOWN)"
  printf 'env_lock_sha256: %s\n' "$ENVSHA"
  printf 'seed: %s\n' "${SEED:-n/a - REPLACE: a number, or 'n/a - <why>' when there is no RNG (BS-9)}"
  printf 'models: %s\n' "${MODELS:-REPLACE: the model(s) that produced this bundle (BS-15)}"
  printf 'date: %s\n' "$(date +%F)"
  printf 'operator: %s\n' "$(git config user.name 2>/dev/null || echo UNKNOWN)"
} > "$B/PROVENANCE.md"
say "PROVENANCE.md written"

# --- README skeleton, with the six adversarial questions already in it (BS-14) --------
cat > "$B/README.md" <<READMEEOF
# $GATE

STATUS: UNVERIFIED — \`run.sh\` has not yet been rerun from this assembled bundle (BS-3).

## 1 · What was measured

<the number, its unit, and the population its denominator equals (WA-D.3)>

## 2 · Counts, including the ones that look bad (BS-5)

| | n |
|---|---|
| attempted | |
| succeeded | |
| dropped | |

Dropped, and why: <never footnote a failure>

## 3 · The denominator's second count (WA-D.3)

Population: <in words a reader can check>
Independent route: <the code that shares nothing with the producing script>
Agreement: <or: no independent route exists, because …, so the rate is graded DERIVED>

## 4 · Claims proposed (paste-ready for the launcher's section 3b)

| ID | Claim | Grade | Circ. | Status | Settled by | Date |
|----|-------|-------|-------|--------|-----------|------|

Every id here must ALREADY be declared in its launcher (BS-12). A claim discovered mid-gate
is described in prose below; the operator assigns the id.

## 5 · The self-adversarial pass (BS-14)

1. **Where is each headline claim overstated?**
2. **What alternative explanation produces this exact number?**
3. **Could this test have returned a negative?**
4. **What is the unit of every rate?**
5. **Which numbers have no producing script?**
6. **What did you withdraw or weaken?**

> A gate with nothing withdrawn was not attacked. If nothing survived attack, say so and
> show what was tried.

## 6 · What changed from the plan
READMEEOF
say "README.md skeleton written"

echo
say "NEXT, in this order:"
say "  1. write $B/run.sh so it runs END TO END FROM THIS BUNDLE, not from scratch (BS-3)"
say "  2. rerun it and confirm it reproduces the number — this is the real gate (WA-B.2)"
say "  3. fill README §1-6, set the STATUS line"
say "  4. seal LAST:  bash general/checks/bundle_valid.sh --write-outputs $B"
say "  5. verify:     bash general/checks/bundle_valid.sh $B"
