#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  refresh_resources_remote.sh  —  run FROM borg.
#  SSHes into Ibex, runs refresh_resources.sh there, writes the report
#  back to compute/ibex_resources.md on borg.
#
#  Usage:  bash compute/refresh_resources_remote.sh
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

# Use a STABLE login node, not the vscode.ibex round-robin pool. That pool is load balanced
# and at least one member (10.109.65.13, seen 2026-07-26) hangs at SSH userauth: TCP and key
# exchange succeed, the host key matches, then the server never replies. The same hostname
# returned a healthy 10.109.65.170 minutes later, so the failure is intermittent and looks
# like an account problem when it is a sick node.
IBEX="rioszemm@ilogin.ibex.kaust.edu.sa"   # or "ibex" if you set up ~/.ssh/config
HERE="$(cd "$(dirname "$0")" && pwd)"
LOCAL_SCRIPT="$HERE/refresh_resources.sh"
OUT="$HERE/ibex_resources.md"

# Run the script on Ibex, telling it to write the report to /dev/stdout.
# The script's status line goes to stderr; 2>/dev/null drops it here so the
# captured file contains ONLY the report.
#
# Write to a TEMP file and promote it only on success. Redirecting straight to "$OUT"
# truncates it before ssh even runs, so any failure (hung node, timeout, no network)
# destroys the previous snapshot — that is exactly how the 2026-07-26 snapshot was lost.
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

if ssh -o ConnectTimeout=20 -o ServerAliveInterval=15 -o ServerAliveCountMax=4 \
       "$IBEX" 'bash -s -- /dev/stdout' < "$LOCAL_SCRIPT" > "$TMP" 2>/dev/null \
   && grep -q "Ibex Resource Snapshot" "$TMP"; then
  mv "$TMP" "$OUT"
  echo "✓ Pulled live Ibex snapshot → $OUT"
else
  echo "✗ Refresh failed — previous snapshot at $OUT left INTACT." >&2
  echo "  First lines of the failed attempt:" >&2
  head -5 "$TMP" >&2
  echo "  Try interactively: ssh $IBEX 'bash refresh_resources.sh'" >&2
  exit 1
fi