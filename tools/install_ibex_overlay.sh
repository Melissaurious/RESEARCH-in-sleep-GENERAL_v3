#!/usr/bin/env bash
# Make Ibex routing BINDING, by deriving a project-local override of ARIS's
# experiment-bridge from the pinned upstream copy.
#
#   bash general/tools/install_ibex_overlay.sh            # install/refresh
#   bash general/tools/install_ibex_overlay.sh --check    # verify, change nothing
#
# Why this exists: /experiment-bridge routes each milestone BY JOB COUNT (<=5 ->
# /run-experiment, >=10 or phase deps -> /experiment-queue) and says no manual override is
# needed. A sibling skill saying "intercept this" is not a hook, an alias, or a dispatch
# rule -- an already-running skill that names another skill will call that skill. The only
# binding override is a skill at the SAME NAME, earlier on the resolution path.
#
# It is DERIVED, never hand-written: upstream's body is copied verbatim and a precedence
# block is prepended. Hand-writing a replacement would silently drop everything upstream
# does that we did not think to restate.
set -uo pipefail

CHECK_ONLY=0; [ "${1:-}" = "--check" ] && CHECK_ONLY=1
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
LOCK="ARIS.lock"
DEST=".claude/skills/experiment-bridge/SKILL.md"

[ -f "$LOCK" ] || { echo "✗ no $LOCK. Run tools/pin_aris.sh first — an unpinned ARIS can change" \
                         "its routing under you and this overlay would silently go stale." >&2; exit 1; }
# shellcheck disable=SC1090
ARIS_REPO="$(sed -n 's/^path=//p' "$LOCK")"
WANT_SHA="$(sed -n 's/^commit=//p' "$LOCK")"
SRC="$ARIS_REPO/skills/experiment-bridge/SKILL.md"

[ -d "$ARIS_REPO" ] || { echo "✗ ARIS not found at $ARIS_REPO (from $LOCK)" >&2; exit 1; }
HAVE_SHA="$(git -C "$ARIS_REPO" rev-parse HEAD 2>/dev/null || echo unknown)"
if [ "$HAVE_SHA" != "$WANT_SHA" ]; then
  echo "✗ ARIS is at ${HAVE_SHA:0:12}, $LOCK pins ${WANT_SHA:0:12}."
  echo "  Its routing or artifact contract may have changed. Re-pin deliberately"
  echo "  (tools/pin_aris.sh) and re-derive this overlay — do not run against a drifted ARIS."
  exit 1
fi
[ -f "$SRC" ] || { echo "✗ upstream $SRC not found — cannot derive the overlay, and a" \
                        "hand-written one would drop what upstream does." >&2; exit 1; }

PRECEDENCE=$(cat <<'BLOCK'

---

# ⛔ SITE OVERRIDE — Ibex routing. Read this BEFORE any routing decision below.

This installation runs on **KAUST Ibex (SLURM)**. The job-count routing described later in
this document is **overridden** for every milestone whose execution target is Ibex:

    if target is Ibex  (general/site/COMPUTE.md thresholds, or the plan says so):
            ALL execution  ->  /run-experiment-ibex     regardless of job count
                <= 5 jobs      -> individual sbatch submissions
                >= 10 jobs     -> a SLURM ARRAY (--array=0-N%K), never a submit loop
                phase deps     -> --dependency=afterok:<ARRAY_JOB_ID>, colons never commas
    else:
            follow the upstream routing below, unchanged.

⛔ **`/experiment-queue` must never run against Ibex.** It drives jobs with `screen` over
SSH. On a login node that holds no allocation, bypasses the scheduler, dies with the
connection, produces no job id to size from or account against, and gets the account
noticed by the cluster admins.

⛔ **`/run-experiment` must never run against Ibex** either — it targets local, vast and
modal hosts and does not speak SLURM.

Decide the target with `python general/tools/dispatch.py --explain` and paste its reason
into `EXPERIMENT_PLAN.md`.

**Expensive or scientifically consequential milestone?** Run `/plan-audit` before
deployment — a design that cannot return a negative costs the same GPU-hours as one that can.

Everything below this line is upstream ARIS, verbatim.

---
BLOCK
)

if [ "$CHECK_ONLY" = 1 ]; then
  [ -f "$DEST" ] || { echo "✗ overlay not installed at $DEST"; exit 1; }
  grep -q "SITE OVERRIDE — Ibex routing" "$DEST" || { echo "✗ $DEST exists but carries no override block"; exit 1; }
  # Compare the upstream hash recorded at derivation time against upstream now. Hashes,
  # not extracted regions: the previous form guessed at file layout with sed and fired on
  # an overlay it had just derived correctly, which is worse than no check.
  RECORDED="$(sed -n 's/^<!-- derived-from-sha256: \([0-9a-f]*\).*/\1/p' "$DEST" | head -1)"
  CURRENT="$(sha256sum "$SRC" | cut -d' ' -f1)"
  if [ -z "$RECORDED" ]; then
    echo "⚠ $DEST carries no derived-from marker — derived by an older version. Re-derive."; exit 1
  fi
  if [ "$RECORDED" != "$CURRENT" ]; then
    echo "⚠ upstream experiment-bridge has changed since this overlay was derived."
    echo "  recorded ${RECORDED:0:12}, current ${CURRENT:0:12} — re-derive it."; exit 1
  fi
  echo "OK: Ibex routing override installed, derived from upstream ${CURRENT:0:12} at ARIS ${WANT_SHA:0:12}"
  exit 0
fi

mkdir -p "$(dirname "$DEST")"
SRC_SHA="$(sha256sum "$SRC" | cut -d' ' -f1)"
{
  awk '/^---$/{n++; print; if(n==2) exit; next} {print}' "$SRC"   # upstream frontmatter
  printf '\n<!-- derived-from-sha256: %s  (ARIS %s, %s) -->\n' \
         "$SRC_SHA" "${WANT_SHA:0:12}" "$(date -u +%Y-%m-%d)"
  printf '%s\n' "$PRECEDENCE"
  awk 'BEGIN{n=0} /^---$/{n++; if(n<=2) next} n>=2{print}' "$SRC" # upstream body, verbatim
} > "$DEST"

echo "✓ derived $DEST from ARIS ${WANT_SHA:0:12}"
echo "  upstream body copied verbatim; the Ibex override is prepended, so it is read first."
echo "  Re-run this after every ARIS re-pin."
