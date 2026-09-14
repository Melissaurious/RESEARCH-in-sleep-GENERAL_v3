#!/usr/bin/env bash
# Print the revision of the agreements layer, for BS-10 (`agreements: <sha>`).
#
#   bash general/tools/general_sha.sh
#
# Works whether this directory is a git submodule (its own HEAD), a subtree, or a
# plain directory in the host repo (the host's last commit that touched it).
# Appends "-dirty" when the layer has uncommitted changes, because a run governed
# by uncommitted rules is not governed by a revision anyone else can fetch.
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"

if [ -e "$D/.git" ]; then
  sha=$(git -C "$D" rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "$D" status --porcelain 2>/dev/null)
else
  # Plain directory in the host repo: the layer's revision IS the host's revision.
  sha=$(git -C "$D" rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "$D" status --porcelain -- "$D" 2>/dev/null)
fi

[ -n "${sha:-}" ] || { echo "UNKNOWN (not a git checkout)" >&2; exit 1; }
[ -n "$dirty" ] && sha="$sha-dirty"
printf '%s\n' "$sha"
