#!/usr/bin/env bash
# Stage 4 — the adversarial pass, with its gates enforced instead of described.
#
#   bash tools/adversary.sh              # run it, if the gates are met
#   bash tools/adversary.sh --check      # report on the gates and run nothing
#
# `docs/PROMPTS.md` § Gates has specified this pass for two days and nothing ran it:
# there was no script, `docs/reviews/` did not exist, and the one pass that ever
# happened was a session reviewing its own night. That pass found four defects no check
# could — and got its diagnosis backwards on the fifth, naming the 22 well-formed ledger
# rows as the defect and the 20 broken ones as fine. Both halves of that are why this
# exists: the pass is worth running, and its output is a lead, never a verdict.
#
# What this enforces that a pasted prompt cannot:
#
#   * the entry gates actually gate. A pass over one bundle, or over a ledger that does
#     not parse, produces findings nobody reads, and an adversary nobody reads is a cost
#     with no signal.
#   * it writes exactly ONE file. The gates say it may not edit CLAIMS.md, ROADMAP.md,
#     any bundle, or any check — it reports, it does not repair. That is checked after
#     the session returns, and anything else it touched is reverted, not trusted.
#   * it reads commits it did not write. A different model, in a separate invocation.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

MODEL="${ADVERSARY_MODEL:-claude-sonnet-5}"
REVIEWS="docs/reviews"
TODAY="$(date +%Y-%m-%d)"
OUT="$REVIEWS/${TODAY}-${MODEL}.md"
CHECK_ONLY=0; [ "${1:-}" = "--check" ] && CHECK_ONLY=1

say() { printf '%s  %s\n' "$(date +%H:%M:%S)" "$*"; }
fail=0

# ---- gate 1: at least two bundles landed since the last review -------------
# One bundle is not a pattern, and a pass that finds nothing teaches you to skip the
# next one. The previous review records the bundles it saw, so "since" is a set
# difference and not a timestamp — a bundle that landed and was reviewed does not
# become new again because a later commit touched the tree.
LANDED=$(ls -1d results/*/ 2>/dev/null | sed 's|results/||; s|/$||' | sort)
LAST=$(ls -1 "$REVIEWS"/*.md 2>/dev/null | grep -v README | sort | tail -1)
if [ -n "$LAST" ]; then
  SEEN=$(sed -n 's/^- reviewed: //p' "$LAST" | tr ' ' '\n' | sort)
  NEW=$(comm -23 <(printf '%s\n' "$LANDED") <(printf '%s\n' "$SEEN"))
else
  NEW="$LANDED"
fi
N_NEW=$(printf '%s\n' "$NEW" | grep -c . || true)
if [ "$N_NEW" -ge 2 ]; then
  say "gate 1 OK   $N_NEW bundle(s) not yet reviewed"
else
  say "gate 1 FAIL only $N_NEW bundle(s) since ${LAST:-the beginning}; needs 2"
  fail=1
fi

# ---- gate 2: the ledger parses --------------------------------------------
# It cannot audit a table it cannot read, and the ragged ledger it once found had been
# unreadable for two days before anyone noticed.
if bash tools/checks/ledger_parses.sh >/dev/null 2>&1; then
  say "gate 2 OK   ledger parses"
else
  say "gate 2 FAIL tools/checks/ledger_parses.sh does not print OK"
  fail=1
fi

# ---- gate 3: a clean tree, so 'what it changed' is unambiguous -------------
if [ -z "$(git status --porcelain)" ]; then
  say "gate 3 OK   working tree clean"
else
  say "gate 3 FAIL working tree is dirty — commit or stash first, or its diff is not its own"
  fail=1
fi

# ---- gate 4: a different reader -------------------------------------------
# Not enforceable from here: nothing records which model wrote each bundle. So it is
# declared, recorded in the review, and stated as the operator's to honour.
say "gate 4 note  reading as '$MODEL' — this must NOT be the model that wrote the bundles"

if [ "$CHECK_ONLY" = 1 ]; then
  [ "$fail" = 0 ] && say "gates MET — bash tools/adversary.sh would run" \
                  || say "gates NOT met — nothing would run"
  exit "$fail"
fi
[ "$fail" = 0 ] || { say "STOPPED: a gate is unmet. An adversary over noise is a cost with no signal."; exit 1; }

mkdir -p "$REVIEWS"
BRANCH="claude/review-${TODAY}"
git checkout -q -B "$BRANCH" origin/main || { say "could not branch from origin/main"; exit 1; }

PROMPT="You are running an ADVERSARIAL READ of a research repository. You did not write any
of this. Your job is to try to break it, not to summarise it.

Read \`CLAIMS.md\`, \`general/agreements/EVIDENCE_STANDARDS.md\`, \`general/agreements/BUNDLE_SPEC.md\`, and
every bundle under \`results/\`. These bundles are new since the last review and are where
to concentrate: $(printf '%s ' $NEW)

Job 1 — adversarially read each bundle. For every claim a README proposes a status for:
is the denominator named and correct; was every threshold declared BEFORE scoring (§5);
is any count of zero backed by a positive control that returned non-zero on a
known-present case (§6); does the grade match what was measured, MEASURED vs DERIVED vs
INFERRED (§1c); does any figure show a number no landed table contains; does run.sh
reference anything not in the bundle; is every input run.sh reads listed in INPUTS.tsv
(BS-2); does every figure have the table it plots (BS-13).

Job 2 — one paste-ready block of status lines, ordered by claim id, each naming the TABLE
that carries its number. A claim you cannot tie to a table stays UNPROVEN and you say why.

Job 3 — every claim id a README proposes that is not a row in CLAIMS.md (BS-12). Describe
each in prose and propose the next genuinely free id — git grep it across all bundles
first, because ids have collided here before. Renumber nothing.

Job 4 — check the governance, not just the science. Does git log show a submodule gitlink
moved in a commit whose subject is about something else? Does every landed
'STATUS: VERIFIED' correspond to a commit that actually touched that README.md? Both have
been false here.

EVERY finding must name a file and a line. 'The denominator looks wrong' is not
actionable and will be discarded.

Write your findings to exactly one file: \`$OUT\`. Begin it with these two lines verbatim,
then your findings:

    - model: $MODEL
    - reviewed: $(printf '%s ' $LANDED)

You may not edit CLAIMS.md, ROADMAP.md, any bundle under results/, or any check. You
report; you do not repair. Do not commit. Write only that one file."

LOG="ARIS_OUTPUT/reviews/${TODAY}-${MODEL}.log"; mkdir -p "$(dirname "$LOG")"
say "running the adversary as $MODEL on branch $BRANCH -> $LOG"
claude --model "$MODEL" --permission-mode acceptEdits -p "$PROMPT" >"$LOG" 2>&1
tail -15 "$LOG"

# The account limit does not fail loudly - it writes a line and returns, and a review
# that never ran looks exactly like a review that found nothing. Say which it was.
if grep -qiE "hit your (session|usage|account) limit|usage limit reached" "$LOG"; then
  say "!! the ACCOUNT LIMIT stopped this review before it ran:"
  grep -hoiE "hit your (session|usage|account) limit[^\"]*" "$LOG" | sort -u | sed 's/^/     /'
  say "   nothing committed. Re-run after the reset; the gates are unchanged."
  git checkout -q main; exit 3
fi

# ---- enforce "it writes ONE file" -----------------------------------------
# The gates say it may not repair. A prompt asks; this checks. Anything outside
# docs/reviews/ is reverted rather than reviewed, because a reader that edited the thing
# it was reviewing has invalidated its own report.
STRAY=$(git status --porcelain | awk '{print $2}' | grep -v "^$REVIEWS/" || true)
if [ -n "$STRAY" ]; then
  say "!! the adversary touched files it may not. Reverting:"
  printf '%s\n' "$STRAY" | sed 's/^/     /'
  printf '%s\n' "$STRAY" | xargs -r git checkout -- 2>/dev/null
  printf '%s\n' "$STRAY" | xargs -r rm -f 2>/dev/null
fi

if [ ! -s "$OUT" ]; then
  say "no review written — see the output above. Nothing committed."
  git checkout -q main; exit 1
fi

git add "$REVIEWS" && git commit -q -m "Adversarial read $TODAY ($MODEL)

Findings only. Changes nothing, accepts nothing, repairs nothing — the ledger is the
operator's (CL-2, WA-I.2) and interpretation is the operator's (WA-I.1).

Read its findings as LEADS and its diagnoses as HYPOTHESES: the one prior pass was right
that the ledger was ragged and backwards about which rows were broken. Verify each
finding against the file before acting on the explanation."
git push -q -u origin "$BRANCH" && say "pushed $BRANCH — review is $OUT"
git checkout -q main
say "done. $(grep -c '^' "$OUT" 2>/dev/null || echo 0) lines written."
