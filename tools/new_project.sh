#!/usr/bin/env bash
# Scaffold a project governed by this layer.
#
#   bash tools/new_project.sh /path/to/<project> [<layer-url>]
#
# Creates the tree, mounts this layer as a submodule at general/, copies the templates,
# installs .claude/settings.json, and proves the checkout is governed by running
# specs_exist.sh. It does NOT fill the research contract or a launcher — those are yours,
# and a scaffold that pre-fills them invites a gate to start against a template.
set -uo pipefail

DEST="${1:-}"
[ -n "$DEST" ] || { echo "usage: bash tools/new_project.sh /path/to/<project> [<layer-url>]" >&2; exit 2; }
LAYER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAYER_URL="${2:-$LAYER_DIR}"

[ -e "$DEST" ] && { echo "REFUSING: $DEST already exists. Renaming is reversible; overwriting is not (WA-S.1)." >&2; exit 1; }

say() { printf '  %s\n' "$*"; }

mkdir -p "$DEST"/{launchers,results,retros,docs/decisions,data,sidework,ARIS_OUTPUT,.claude}
mkdir -p "$DEST"/idea-stage/docs   # ARIS's canonical home for the research contract
cd "$DEST"
# -b main explicitly: the whole workflow branches gates from origin/main, and a repo whose
# default branch is master silently has no such ref. Fallback for git < 2.28.
git init -q -b main 2>/dev/null || { git init -q; git symbolic-ref HEAD refs/heads/main; }
say "tree created (default branch: $(git symbolic-ref --short HEAD))"

# The layer, pinned by sha. A project that cannot resolve it is not governed and no gate starts.
git -c protocol.file.allow=always submodule add -q "$LAYER_URL" general 2>/dev/null \
  || { echo "FAILED to add the layer as a submodule from $LAYER_URL" >&2; exit 1; }
say "layer mounted at general/ ($(git -C general rev-parse --short HEAD))"

cp general/templates/PROJECT_CLAUDE.md     CLAUDE.md
cp general/templates/RESEARCH_CONTRACT.md  idea-stage/docs/research_contract.md
cp general/templates/LAUNCHER.md           launchers/LAUNCHER_TEMPLATE.md
cp general/templates/LAUNCHER_EXAMPLE.md   launchers/LAUNCHER_EXAMPLE.md
# __SCRATCH__ is a placeholder in the templates; substitute the project's scratch dir name.
# Left unsubstituted, allowWrite names a directory that does not exist and the first gate
# cannot write anything - which is how it shipped once, and the failure looked like a
# permissions mystery rather than a template bug.
sed 's|__SCRATCH__|ARIS_OUTPUT|g' general/templates/gitignore     > .gitignore
sed 's|__SCRATCH__|ARIS_OUTPUT|g' general/templates/settings.json > .claude/settings.json
python3 -c "import json,sys; json.load(open('.claude/settings.json'))" \
  || { echo "settings.json does not parse after substitution" >&2; exit 1; }
grep -q '__SCRATCH__' .gitignore .claude/settings.json \
  && { echo "__SCRATCH__ survived substitution" >&2; exit 1; }
printf '# BLOCKED\n\nOpen questions, timestamped: what is needed, why, the options, the\nrecommended default (WA-S.1).\n' > docs/BLOCKED.md
printf '# LOG\n\nNotes that are not gates (WA-G.1).\n' > docs/log.md
printf '# DATA REGISTER\n\nOne row per input: path, sha256, bytes, mode, and how it was obtained.\nInherited-baseline rows name their bundle or carry the `operator-supplied design\nfact` tag with a person and a date (WA-L.3).\n' > data/README.md
printf '# SIDEWORK\n\nNothing here is a number. No bundle, no acceptance. A finding earns one thing:\nthe right to become a gate, through research_contract.md like any other.\n' > sidework/README.md
# The Ibex skill OVERRIDES ARIS's generic run-experiment, which launches remote work over
# SSH + screen -- no allocation, no job id, dies with the connection. Symlinked into the
# submodule so it moves with the pin.
mkdir -p .claude/skills
for s in run-experiment-ibex experiment-routing-ibex plan-audit; do
  ln -sfn "../../general/skills/$s" ".claude/skills/$s"
done
say "templates copied; 3 skills linked (routing override + Ibex executor + plan audit)"

# README must list every agreements/ and site/ spec, or specs_exist.sh fails (by design).
{
  printf '# %s\n\n<one line: what this project measures>\n\n' "$(basename "$DEST")"
  printf 'Governed by `general/` at revision `%s`.\n\n' "$(git -C general rev-parse --short HEAD)"
  printf '## Layout\n\n'
  printf '| path | what it is |\n|---|---|\n'
  printf '| `CLAUDE.md` | project context; points at `general/` for every rule |\n'
  printf '| `idea-stage/docs/research_contract.md` | the standing science and the ONE claim authority. Written by hand. |\n'
  printf '| `launchers/` | one per track — objective, kill criteria, inputs, gates. Written by hand. |\n'
  printf '| `INDEX.md` | GENERATED rollup of claims and bundles (`bash general/tools/index.sh`). Never hand-edited. |\n'
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
  say "  1. CLAUDE.md            — subject, environment, paths, budget   (~60 lines)"
  say "  2. idea-stage/docs/research_contract.md — the standing science: question,"
  say "                            datasets, baselines, kill criteria     (~60 lines)"
  say "  3. launchers/LAUNCHER_<track>.md — the task now; see LAUNCHER_EXAMPLE.md (~100)"
  say ""
  say "Those three are everything you write by hand, ever. INDEX.md is GENERATED"
  say "(bash general/tools/index.sh) and never hand-edited."
  say ""
  say "Validate before any gate starts:"
  say "  python3 general/tools/check_launcher.py launchers/LAUNCHER_<track>.md"
  say ""
  say "A gate does not start before its claim is declared UNPROVEN in research_contract.md (WA-L.1)."
else
  echo
  say "NOT GOVERNED — specs_exist.sh did not pass. Fix before starting any gate."
  exit 1
fi
