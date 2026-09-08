#!/usr/bin/env bash
# Scaffold a project governed by this layer.
#
#   bash tools/new_project.sh /path/to/<project> [<layer-url>]
#
# Creates the tree, mounts this layer as a submodule at general/, copies the templates,
# installs .claude/settings.json, and proves the checkout is governed by running
# specs_exist.sh. It does NOT write GOALS, CLAIMS or a launcher — those are the operator's,
# and a scaffold that pre-fills them invites a gate to start against a template.
set -uo pipefail

DEST="${1:-}"
[ -n "$DEST" ] || { echo "usage: bash tools/new_project.sh /path/to/<project> [<layer-url>]" >&2; exit 2; }
LAYER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAYER_URL="${2:-$LAYER_DIR}"

[ -e "$DEST" ] && { echo "REFUSING: $DEST already exists. Renaming is reversible; overwriting is not (WA-C.5)." >&2; exit 1; }

say() { printf '  %s\n' "$*"; }

mkdir -p "$DEST"/{launchers,results,retros,docs/decisions,data,sidework,ARIS_OUTPUT,.claude}
cd "$DEST"
git init -q
say "tree created"

# The layer, pinned by sha. A project that cannot resolve it is not governed and no gate starts.
git -c protocol.file.allow=always submodule add -q "$LAYER_URL" general 2>/dev/null \
  || { echo "FAILED to add the layer as a submodule from $LAYER_URL" >&2; exit 1; }
say "layer mounted at general/ ($(git -C general rev-parse --short HEAD))"

cp general/templates/PROJECT_CLAUDE.md CLAUDE.md
cp general/templates/GOALS.md general/templates/CLAIMS.md general/templates/ROADMAP.md .
cp general/templates/gitignore .gitignore
cp general/templates/settings.json .claude/settings.json
printf '# BLOCKED\n\nOpen questions, timestamped: what is needed, why, the options, the\nrecommended default (WA-S.4).\n' > docs/BLOCKED.md
printf '# LOG\n\nNotes that are not gates (RM-2).\n' > docs/log.md
printf '# DATA REGISTER\n\nOne row per input: path, sha256, bytes, mode, and how it was obtained.\nInherited-baseline rows name their bundle or carry the `operator-supplied design\nfact` tag with a person and a date (WA-I.5).\n' > data/README.md
printf '# SIDEWORK\n\nNothing here is a number. No bundle, no acceptance. A finding earns one thing:\nthe right to become a gate, through CLAIMS.md and ROADMAP.md like any other.\n' > sidework/README.md
say "templates copied"

# README must list every agreements/ and site/ spec, or specs_exist.sh fails (by design).
{
  printf '# %s\n\n<one line: what this project measures>\n\n' "$(basename "$DEST")"
  printf 'Governed by `general/` at revision `%s`.\n\n' "$(git -C general rev-parse --short HEAD)"
  printf '## Layout\n\n'
  printf '| path | what it is |\n|---|---|\n'
  printf '| `CLAUDE.md` | project context; points at `general/` for every rule |\n'
  printf '| `GOALS.md` | what we are trying to be able to claim |\n'
  printf '| `CLAIMS.md` | the falsifiable statements and their status |\n'
  printf '| `ROADMAP.md` | the gates; exactly one is active |\n'
  printf '| `launchers/` | one per track — the authority on scope |\n'
  printf '| `results/` | bundles, and nothing else |\n'
  printf '| `retros/` | one per gate |\n'
  printf '| `docs/decisions/` | settled decisions, numbered |\n'
  printf '| `data/README.md` | the input register |\n'
  printf '| `ARIS_OUTPUT/` | scratch. Gitignored, disposable, allowed to be messy. |\n'
} > README.md
say "README written"

git add -A >/dev/null 2>&1
git commit -qm "Scaffold: governed by the general layer at $(git -C general rev-parse --short HEAD)" >/dev/null 2>&1
say "initial commit"

echo
if bash general/checks/specs_exist.sh; then
  echo
  say "GOVERNED. Next, in this order:"
  say "  1. CLAUDE.md      — subject, environment, paths"
  say "  2. GOALS.md       — what you want to be able to claim, and the kill criteria"
  say "  3. CLAIMS.md      — the falsifiable statements, born UNPROVEN"
  say "  4. launchers/     — the first track, from general/templates/LAUNCHER.md"
  say "A gate does not start before its claim exists as UNPROVEN (CL-1)."
else
  echo
  say "NOT GOVERNED — specs_exist.sh did not pass. Fix before starting any gate."
  exit 1
fi
