#!/usr/bin/env bash
# The gate. An independent model reviews the plan before execution and the result before
# landing, and its verdict decides. The operator is not in the critical path (WA-A.1).
#
#   bash general/tools/review.sh --plan   <GATE>
#   bash general/tools/review.sh --result <GATE>
#   bash general/tools/review.sh --check  <GATE>     # report readiness, run nothing
#
# Exit 0 = gate OPEN, proceed.  1 = gate CLOSED, fix and re-review.  2 = cannot review.
#
# Two defects in the previous adversary are fixed here by construction:
#   * it depended on a script that did not exist, so it could never run. This depends on
#     nothing outside the gate directory and this layer (WA-P: a rule pointing at a missing
#     file is silent).
#   * it hardcoded one project's paths inside the portable layer. Everything here is
#     derived from $GATE and the repo root.
set -uo pipefail

MODE=""; GATE=""
case "${1:-}" in
  --plan|--result|--check) MODE="${1#--}"; GATE="${2:-}" ;;
  *) echo "usage: $0 --plan|--result|--check <GATE>" >&2; exit 2 ;;
esac
[ -n "$GATE" ] || { echo "usage: $0 --$MODE <GATE>" >&2; exit 2; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
GENERAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH="ARIS_OUTPUT/$GATE"
BUNDLE="results/$GATE"
REVIEW="$SCRATCH/review"
LAUNCHER="$(ls launchers/LAUNCHER_*"${GATE%%_*}"*.md launchers/*"$GATE"*.md 2>/dev/null | head -1)"
ROUND_BUDGET="${REVIEW_ROUND_BUDGET:-3}"

# Reviewer: a DIFFERENT model family from the author (WA-A.5), running read-only.
REVIEW_CMD="${RSG_REVIEW_CMD:-codex exec --skip-git-repo-check -}"
REVIEWER_FAMILY="${RSG_REVIEWER_FAMILY:-openai}"
AUTHOR_FAMILY="${RSG_AUTHOR_FAMILY:-anthropic}"

say() { printf '  %s\n' "$*"; }
die() { printf '✗ %s\n' "$*" >&2; exit "${2:-2}"; }

[ -d "$SCRATCH" ] || die "no scratch directory: $SCRATCH"
[ -n "$LAUNCHER" ] || die "no launcher found for gate '$GATE' under launchers/ (WA-L.1)"
mkdir -p "$REVIEW"

# ── round accounting (WA-A.3): bounded, and the halt reason is named ──────────
ROUND=$(( $(ls -1 "$REVIEW/${MODE}_r"*.md 2>/dev/null | grep -cE "/${MODE}_r[0-9]+\.md$") + 1 ))
if [ "$MODE" != "check" ] && [ "$ROUND" -gt "$ROUND_BUDGET" ]; then
  die "HALT: round budget exhausted ($ROUND_BUDGET rounds of --$MODE).
  This is a BUDGET-halt, not a condition-halt, and must not be reported as success.
  The gate has not passed. Record it in docs/BLOCKED.md and stop (WA-A.3, WA-S.1)." 1
fi
OUT="$REVIEW/${MODE}_r${ROUND}.md"

# ── WA-A.5: the reviewer may not share the author's priors ───────────────────
if [ "$REVIEWER_FAMILY" = "$AUTHOR_FAMILY" ]; then
  die "reviewer family '$REVIEWER_FAMILY' == author family '$AUTHOR_FAMILY' (WA-A.5).
  Two methods agreeing is evidence only if they can disagree. Set RSG_REVIEW_CMD to a
  different provider's CLI, or set RSG_REVIEWER_FAMILY if this is genuinely a different one."
fi

# ── probe the reviewer by EXECUTION, never by presence (EVIDENCE_STANDARDS §2) ─
EXE="$(printf '%s' "$REVIEW_CMD" | awk '{print $1}')"
command -v "$EXE" >/dev/null 2>&1 || die "reviewer '$EXE' is ABSENT from PATH. A missing reviewer is never a pass."
PROBE="$(printf 'Reply with exactly: OK' | timeout 180 bash -c "$REVIEW_CMD" 2>/dev/null)"
[ -n "${PROBE// }" ] || die "reviewer is PRESENT_BUT_BROKEN: exited without output. Not a cleared gate."
say "reviewer   VERIFIED  ($EXE, family=$REVIEWER_FAMILY, $(printf '%s' "$PROBE" | wc -c) chars)"

if [ "$MODE" = "check" ]; then
  say "launcher   $LAUNCHER"
  say "round      would be $ROUND of $ROUND_BUDGET"
  say "gates MET — a review would run."
  exit 0
fi

# ── the packet: artefacts + standards. NEVER the author's reasoning (WA-A.1) ──
emit() { [ -f "$1" ] && { printf '\n### %s\n\n```\n' "$1"; head -c 60000 "$1"; printf '\n```\n'; } \
                     || printf '\n### %s\n_(absent)_\n' "$1"; }
list() { [ -d "$1" ] && { printf '\n### %s/\n\n```\n' "$1"; (cd "$1" && find . -type f -printf '%10s  %p\n' | sort); printf '```\n'; } \
                     || printf '\n### %s/\n_(absent)_\n' "$1"; }

{
printf '# ADVERSARIAL REVIEW — pass `%s`, round %s — gate `%s`\n\n' "$MODE" "$ROUND" "$GATE"
cat <<'HDR'
You are an adversarial reviewer. Find what is WRONG. Do not summarise.

You have deliberately NOT been given the author's reasoning, its confidence, or any earlier
review: a reviewer handed the argument grades the argument and agrees with it.

## Answer in EXACTLY this shape. The first line is parsed by a script.

VERDICT: <PASS | PASS_WITH_CONCERNS | FAIL | INSUFFICIENT_INFORMATION>

FINDINGS
- [BLOCKER|CONCERN|NIT] <one-line claim>
  WHY:  <the mechanism by which this produces a wrong or unfalsifiable result>
  TEST: <the command or check that would settle it>

CHECKED:     <what you verified, and how>
NOT CHECKED: <what you could not verify from this packet, and why>

Rules for you:
- BLOCKER means the gate would produce a wrong, circular, or unfalsifiable number.
- INSUFFICIENT_INFORMATION is a respectable answer. Use it rather than guessing.
- NOT CHECKED may NOT be empty. If you could verify everything, you did not understand
  the gate. A review with no coverage statement does not count as a pass.
- Do not propose scope the launcher explicitly excludes.
HDR
if [ "$MODE" = "plan" ]; then cat <<'Q'

## Work through these

1.  Could this plan return a NEGATIVE? If nothing could falsify it, it is a description.
2.  Grade circularity NONE/LOW/MEDIUM/HIGH per method. Anything measured with the
    instrument that DEFINED it is a BLOCKER.
3.  Are thresholds declared in code BEFORE scoring?
4.  Is every claimed independence COMPUTED, or assumed?
5.  A positive control for every expected zero?
6.  Is anything reported from a SAMPLE rather than an exact pass (census)?
7.  Does every rate name the population its denominator equals, counted a second,
    independent way?
8.  Were real field VALUES probed, or was a schema document trusted?
9.  What already exists on disk that this would rebuild — and would a stale or
    wrongly-computed artifact read as ready? Absence is loud; wrongness is quiet.
10. Is the compute estimate from a MEASURED smoke test on a representative slice?
11. Is the declared weight (LIGHT/FULL) right for what the number will be used for?
Q
else cat <<'Q'

## Work through these

1.  Walk EVIDENCE_STANDARDS §8 item by item against these artefacts. Mark each
    satisfied, violated, or unverifiable from this packet.
2.  Does EVERY number trace to a script here? A hand-copied or remembered number is a BLOCKER.
3.  Does every figure have its TSV, same basename, and does the TSV reproduce it?
4.  Is every artifact validated by CONTENT — bytes, parse, record count, an asserted
    invariant — rather than by exists() or exit code?
5.  Are exact statements EXACT? Check the arithmetic literally.
6.  Are claims scoped to what was actually examined?
7.  Are negative, null and surprising results stated plainly, or softened?
8.  Would run.sh reproduce this on a machine that is not this one?
9.  Is anything concluded that should only be counted (WA-A.4)?
Q
fi
printf '\n---\n# THE GATE\n'
emit "$LAUNCHER"
if [ "$MODE" = "plan" ]; then
  emit "$SCRATCH/PLAN.md"
else
  emit "$BUNDLE/README.md"; emit "$BUNDLE/run.sh"; emit "$BUNDLE/PROVENANCE.md"
  emit "$BUNDLE/INPUTS.tsv"; emit "$BUNDLE/MANIFEST.tsv"
  list "$BUNDLE/scripts"; list "$BUNDLE/tables"; list "$BUNDLE/figures"
fi
printf '\n---\n# THE STANDARDS\n'
emit "$GENERAL/agreements/EVIDENCE_STANDARDS.md"
emit "$GENERAL/agreements/WORKING_AGREEMENT.md"
} > "$REVIEW/${MODE}_r${ROUND}_PACKET.md"

say "packet     $REVIEW/${MODE}_r${ROUND}_PACKET.md ($(wc -c < "$REVIEW/${MODE}_r${ROUND}_PACKET.md") bytes)"

# ── run it ───────────────────────────────────────────────────────────────────
BODY="$(timeout 1800 bash -c "$REVIEW_CMD" < "$REVIEW/${MODE}_r${ROUND}_PACKET.md" 2>&1)"
{
  printf '# Review — pass `%s`, round %s of %s — gate `%s`\n\n' "$MODE" "$ROUND" "$ROUND_BUDGET" "$GATE"
  printf '_%s · reviewer `%s` (family %s) · author family %s_\n\n---\n\n' \
         "$(date -u '+%Y-%m-%d %H:%M UTC')" "$REVIEW_CMD" "$REVIEWER_FAMILY" "$AUTHOR_FAMILY"
  printf '%s\n' "$BODY"
} > "$OUT"
say "review     $OUT"

VERDICT="$(grep -m1 -oE '^[[:space:]]*VERDICT:[[:space:]]*[A-Z_]+' "$OUT" | grep -oE '[A-Z_]+$' || true)"
case "$VERDICT" in
  PASS|PASS_WITH_CONCERNS)
    printf '\n  VERDICT: %s  (round %s)\n' "$VERDICT" "$ROUND"
    grep -q 'NOT CHECKED:[[:space:]]*[^[:space:]]' "$OUT" || die "gate CLOSED — NOT CHECKED is empty.
  A review that verified everything did not understand the gate, and a review with no
  coverage statement is not a pass (WA-A.1). Re-review." 1
    [ "$MODE" = plan ] && echo "✓ gate OPEN — execute." || echo "✓ gate OPEN — land the bundle."
    exit 0 ;;
  FAIL|INSUFFICIENT_INFORMATION)
    printf '\n  VERDICT: %s  (round %s of %s)\n' "$VERDICT" "$ROUND" "$ROUND_BUDGET"
    die "gate CLOSED — no $([ "$MODE" = plan ] && echo execution || echo landing).
  Fix every BLOCKER, then re-run. The agent does not write its own verdict (WA-A.2)." 1 ;;
  *)
    die "no parseable VERDICT line in the review. Treat as INSUFFICIENT_INFORMATION." 1 ;;
esac
