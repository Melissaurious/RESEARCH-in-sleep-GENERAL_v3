#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  refresh_resources.sh  —  LIVE snapshot of Ibex resources.
#
#  MUST RUN ON IBEX (sinfo/squeue only exist there, not on borg).
#    On Ibex:      bash refresh_resources.sh
#    From borg:    use compute/refresh_resources_remote.sh  (SSH wrapper)
#
#  GPU availability changes constantly — regenerate before planning jobs.
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Guard: bail early with a helpful message if SLURM isn't here ──
if ! command -v sinfo >/dev/null 2>&1; then
  echo "ERROR: 'sinfo' not found — this must run ON IBEX, not on borg." >&2
  echo "From borg run instead:  bash compute/refresh_resources_remote.sh" >&2
  exit 1
fi

OUT="${1:-ibex_resources.md}"

{
  echo "# Ibex Resource Snapshot"
  echo "_Generated: $(date '+%Y-%m-%d %H:%M') on $(hostname)_"
  echo

  echo "## GPU partitions (Partition | GRES | #nodes | state)"
  echo '```'
  sinfo -o "%P %G %D %t" --noheader | grep -i gpu | sort
  echo '```'
  echo

  echo "## Idle GPU nodes right now"
  echo '```'
  sinfo -o "%P %G %D %t" --noheader | grep -i gpu | awk '$4 ~ /idle/' || echo "(none idle)"
  echo '```'
  echo

  echo "## My QOS & limits"
  echo '```'
  sacctmgr show assoc where user="$USER" format=Account,QOS,MaxJobs,MaxSubmit --noheader
  echo '```'
  echo

  echo "## My running / pending jobs"
  echo '```'
  squeue -u "$USER" -o "%.10i %.14j %.10P %.5D %.4C %.10m %.11l %.11M %.8T %R"
  echo '```'
  echo

  echo "## My conda envs"
  echo '```'
  ls -1 "/ibex/user/$USER/conda-environments/" 2>/dev/null || conda env list
  echo '```'
} > "$OUT"

# Only print the "Wrote" line to stderr so stdout stays clean for piping.
echo "Wrote $OUT" >&2