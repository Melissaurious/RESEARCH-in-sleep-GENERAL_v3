#!/usr/bin/env bash
# Pin the ARIS revision a project runs against, the way the governance layer is pinned.
#
#   bash general/tools/pin_aris.sh [/path/to/aris_repo]
#
# Without this, a project can say "general @ abc123" and run against a future ARIS whose
# lifecycle or artifact contract changed -- which is how the sandbox went stale twice.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
ARIS_REPO="${1:-${ARIS_REPO:-$HOME/aris_repo}}"
[ -d "$ARIS_REPO/.git" ] || { echo "✗ not a git checkout: $ARIS_REPO" >&2; exit 1; }
SHA="$(git -C "$ARIS_REPO" rev-parse HEAD)"
URL="$(git -C "$ARIS_REPO" remote get-url origin 2>/dev/null || echo 'unknown')"
cat > ARIS.lock <<LOCK
# The ARIS revision this project runs against. Moving it is a deliberate commit with a
# decision record, never a drift -- re-derive the Ibex overlay afterwards.
repo=$URL
path=$ARIS_REPO
commit=$SHA
pinned=$(date -u +%Y-%m-%d)
LOCK
echo "✓ ARIS pinned at ${SHA:0:12}  ($URL)"
echo "  next: bash general/tools/install_ibex_overlay.sh"
