#!/usr/bin/env bash
# REPRODUCE.sh — the executable definition of "this stage reproduces".
#
# Two tiers, because a stage that cost 14 GPU-hours on Ibex cannot be re-run at a gate:
#
#   bash REPRODUCE.sh --quick   regenerate every table and figure from cached
#                               intermediates. Seconds to minutes. CPU only.
#                               ** This is what tools/promote_stage.py --rerun runs. **
#   bash REPRODUCE.sh --full    from raw inputs, including the expensive compute.
#                               State the cost below so nobody starts it by accident.
#
# The point of --quick is not to save time. It is that it runs in a THROWAWAY COPY of
# results/, so a script that only worked because of where it happened to sit fails here
# instead of failing for the next person a year from now.
set -euo pipefail

MODE="${1:---quick}"

# ── Inputs ────────────────────────────────────────────────────────────────────
# Every path the stage reads, declared HERE and nowhere else. Scripts take them from
# the environment; a script that hardcodes an absolute path is refused at promotion.
export STAGE_ID="[stageN_slug]"
export DATA_ROOT="${DATA_ROOT:?set DATA_ROOT to the read-only input directory}"
export CACHE_DIR="${CACHE_DIR:-cache}"

# Input checksums — recorded so a silently changed input announces itself.
#   sha256sum "$DATA_ROOT/[input_file]"
# [expected sha256]  [input_file]

# ── Cost of --full ────────────────────────────────────────────────────────────
# Machine:  [borg GPU 1 | Ibex gpu24 a100 x1]
# Wall:     [X hr]        GPU-hours: [Y]
# Smoke:    [the --limit N invocation that measured the per-unit rate]

case "$MODE" in
  --quick)
    echo "== quick: tables + figures from cached intermediates =="
    python3 scripts/s02_tables.py  --cache "$CACHE_DIR"
    python3 scripts/s03_figures.py --tables tables --out figures
    ;;
  --full)
    echo "== full: from raw inputs. See cost above. =="
    python3 scripts/s01_compute.py --data "$DATA_ROOT" --cache "$CACHE_DIR"
    python3 scripts/s02_tables.py  --cache "$CACHE_DIR"
    python3 scripts/s03_figures.py --tables tables --out figures
    ;;
  *) echo "usage: $0 [--quick|--full]" >&2; exit 2 ;;
esac

# ── Validate by CONTENT, never by existence ───────────────────────────────────
# EVIDENCE_STANDARDS §1: a tool can exit 0 and write a 0-byte file.
python3 - <<'PY'
from pathlib import Path
import sys
bad = []
for f in sorted(Path("tables").glob("*.tsv")):
    rows = f.read_text().strip().splitlines()
    if len(rows) < 2:
        bad.append(f"{f}: {len(rows)} lines — empty or header-only")
for f in sorted(Path("figures").glob("*")):
    if f.stat().st_size < 256:
        bad.append(f"{f}: {f.stat().st_size} bytes — too small to be a real figure")
    if not (Path("tables") / f"{f.stem}.tsv").is_file():
        bad.append(f"{f}: no tables/{f.stem}.tsv")
if bad:
    print("\n".join("  ✗ " + b for b in bad), file=sys.stderr); sys.exit(1)
print(f"  ✓ content-validated")
PY

echo "== REPRODUCE.sh $MODE OK =="
