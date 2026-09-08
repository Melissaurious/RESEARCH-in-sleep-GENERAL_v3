#!/usr/bin/env bash
# Every file the read-first documents point an agent at must resolve.
# A must-read that is missing is silent: the agent proceeds without it (WA-P.3).
#
#   check:        bash agreements/checks/specs_exist.sh
#   validate me:  SELFTEST=1 bash agreements/checks/specs_exist.sh
#
# Resolution is against GIT-TRACKED files only. That is the whole point: the
# previous version fell back to `find`, so an untracked copy anywhere in the tree
# — including disposable scratch — satisfied a reference to a spec that had been
# deleted. The selftest below seeds exactly that case.
#
# Only references that look like repo paths (containing "/") are checked. Bare
# names in prose are examples, not must-reads. Absolute and ~ paths are outside
# the repo and are the site layer's problem, not this check's.
set -uo pipefail

# The project's living documents, plus both inherited layers. `docs/decisions/` is
# deliberately NOT scanned: a decision record is a historical statement and may name
# a file that was later deleted on purpose (retiring a bundle, say). Holding history
# to the current tree would force records to be rewritten, which is the one thing a
# decision record must never be. (`docs/*.md` is one level deep, so
# `docs/decisions/*.md` is excluded by construction — not by an exception.)
# REQUIRED: absent is a failure. These two are how a session finds everything else.
SCAN_DEFAULT="CLAUDE.md README.md"
# OPTIONAL: scanned if present, silent if not. A young project has no IDEAS.md yet, and
# this layer's own repository has no GOALS.md — neither is an error, but both must be
# scanned once they exist, because that is where the dead references actually collect.
SCAN_OPTIONAL="GOALS.md CLAIMS.md ROADMAP.md IDEAS.md data/README.md docs/*.md \
agreements/*.md site/*.md general/agreements/*.md general/site/*.md"
PLACEHOLDER='<|>|\*|YYYY|MM-DD|ROW-ID|basename|stage[XN]'
BUNDLE_INTERNAL='^(INPUTS|MANIFEST|OUTPUTS)\.tsv$|^run\.sh$|^(PROVENANCE|README)\.md$|^env\.lock$'
# A reference whose FIRST segment is one of these is relative to a bundle
# (`results/<row>/tables/x.tsv`), not to the repository root. ROADMAP rows name the
# tables they will produce this way, which is the natural way to write a plan; every
# such name is an OUTPUT, owned by BS-1 and BS-11 inside its own bundle, and most do
# not exist yet because the row has not run. Requiring them here turns a check for
# vanished must-reads into a spell-checker for prose about future work.
BUNDLE_RELATIVE='^(tables|figures|scripts|control|slurm|summaries|shards|examples)/'
# This layer is not a project. Its documents necessarily describe the layout of a
# CONSUMING project — `general/checks/...` is how a project addresses this layer,
# `docs/BLOCKED.md` and `.claude/settings.json` are files a project has and the layer
# does not. Inside the layer's own repository those references are correct and
# unresolvable, and demanding them here would force the layer to carry a fake project
# tree just to satisfy its own check. They are skipped ONLY in layer mode; in a project
# every one of them resolves normally and a dead one still fails.
PROJECT_RELATIVE='^(general|docs|results|launchers|retros|data|sidework|paper)/|^\.claude/'
LAYER_MODE=0
[ -f VERSION ] && [ -f agreements/WORKING_AGREEMENT.md ] && [ ! -d general ] && LAYER_MODE=1

fail=0
# --recurse-submodules is load-bearing once this layer is consumed as a submodule:
# a plain `git ls-files` reports the submodule as ONE gitlink entry, so every
# reference into it would read as missing. Falls back for git < 2.11.
TRACKED="$(git ls-files --recurse-submodules 2>/dev/null || git ls-files 2>/dev/null)"

# Paths of any submodules. Their contents are owned and documented by the layer they
# come from, not by this project, so the "documented in README" rule below does not
# apply to them — a project should not have to enumerate an inherited layer's files.
SUBMODULES="$(git config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')"
in_submodule() {
  local p
  [ -z "$SUBMODULES" ] && return 1
  for p in $SUBMODULES; do case "$1" in "$p"/*) return 0 ;; esac; done
  return 1
}

# A reference is often written as a COMMAND, not as a bare path:
#   `bash tools/hygiene.sh`   `bash agreements/checks/bundle_valid.sh results/<ROW>`
# The previous pattern anchored on a backtick immediately followed by the path, so the
# space after `bash` made every one of those invisible — and `tools/hygiene.sh`, step 1
# of SESSION_HYGIENE's weekly ritual, was dead in all three layers while this check
# reported OK. So: take each backtick span, then every path-like token inside it.
extract_refs() {
  grep -oE '`[^`]+`' "$1" 2>/dev/null | tr -d '`' | tr ' \t' '\n\n' \
    | grep -oE '^[A-Za-z0-9_./~-]+\.(md|sh|py|json|tsv|toml|lock)$' | sort -u
}

resolve() {
  # Exact tracked path only. A basename fallback would let a reference to a file
  # that has MOVED keep resolving against its old name at a new location, which is
  # the drift this check exists to catch.
  printf '%s\n' "$TRACKED" | grep -qxF "$1"
}

REQUIRED_SET=" ${SCAN:-$SCAN_DEFAULT} "
for src in ${SCAN:-$SCAN_DEFAULT} ${SCAN_OPTIONAL:-}; do
  if [ ! -f "$src" ]; then
    # An unmatched glob is a layer this project does not have, and is legal.
    case "$src" in *'*'*) continue ;; esac
    # So is an optional document this project has not written yet.
    case "$REQUIRED_SET" in *" $src "*) echo "MISSING: $src itself"; fail=1 ;; esac
    continue
  fi
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    case "$ref" in /*|'~'*) continue ;; esac          # outside the repo
    printf '%s' "$ref" | grep -qE "$PLACEHOLDER" && continue
    basename "$ref" | grep -qE "$BUNDLE_INTERNAL" && continue   # bundle_valid.sh owns these
    printf '%s' "$ref" | grep -qE "$BUNDLE_RELATIVE" && continue # relative to results/<row>/
    [ "$LAYER_MODE" = 1 ] && printf '%s' "$ref" | grep -qE "$PROJECT_RELATIVE" && continue
    # ARIS_OUTPUT/ is gitignored scratch by definition (CLAUDE.md). Requiring a
    # reference into it to be TRACKED is a contradiction the project can never satisfy:
    # BLOCKED.md records where a session put a working file, and must stay free to.
    case "$ref" in ARIS_OUTPUT/*) continue ;; esac
    case "$ref" in */*) ;; *) continue ;; esac        # bare names in prose are examples
    resolve "$ref" || { echo "MISSING: $src references $ref (not a tracked file)"; fail=1; }
  done < <(extract_refs "$src")
done

for f in agreements/*.md site/*.md general/agreements/*.md general/site/*.md; do
  [ -e "$f" ] || continue
  in_submodule "$f" && continue            # inherited layer; documented at its source
  grep -q "$(basename "$f")" README.md 2>/dev/null \
    || { echo "UNDOCUMENTED: $f is not listed in README.md"; fail=1; }
done

[ "$fail" = 0 ] && echo "OK: every referenced repo path is a tracked file; every spec is documented"

# --------------------------------------------------------------------------
if [ "${SELFTEST:-0}" = "1" ]; then
  export SELFTEST=0                     # never let a child re-enter this block
  ME="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  mkdir -p "$T/agreements"
  printf 'read `agreements/A.md` before acting.\n' > "$T/CLAUDE.md"
  printf '# r\n\n| `agreements/A.md` | rules |\n' > "$T/README.md"
  printf '# A\n' > "$T/agreements/A.md"
  ( cd "$T" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm x )

  ok=0; bad=0
  expect() { # expect <pass|fail> <label> <mutation>
    local want="$1" label="$2" mut="$3" got
    # `git checkout HEAD -- .` resets index AND worktree. Plain `git checkout -- .`
    # restores the worktree from the INDEX, so a staged `git mv` in an earlier case
    # survives the reset and silently poisons every case after it.
    ( cd "$T" && git checkout -q HEAD -- . && git clean -qfd && eval "$mut" ) >/dev/null 2>&1
    if ( cd "$T" && bash "$ME" ) >/dev/null 2>&1; then got=pass; else got=fail; fi
    if [ "$got" = "$want" ]; then printf '  ok    %-48s %s\n' "$label" "$want"; ok=$((ok+1))
    else printf '  FAIL  %-48s wanted %s, got %s\n' "$label" "$want" "$got"; bad=$((bad+1)); fi
  }

  echo "--- SELFTEST: specs_exist.sh (WA-A.3) ---"
  expect pass "a clean tree"                                "true"
  expect fail "a referenced spec is deleted"                "git rm -q agreements/A.md"
  expect fail "deleted spec MASKED by an untracked copy"    "mkdir -p ARIS_OUTPUT && cp agreements/A.md ARIS_OUTPUT/A.md && git rm -q agreements/A.md"
  expect fail "spec exists but is undocumented in README"   "printf '# r\n' > README.md"
  expect fail "a read-first document is itself missing"     "git rm -q CLAUDE.md"
  expect fail "a reference to a MOVED file (stale path)"    "mkdir -p site && git mv agreements/A.md site/A.md && printf '# r\\n\\n| \`site/A.md\` | rules |\\n' > README.md"
  # The class the previous pattern could not see: a path written as a COMMAND.
  expect fail "COMMAND-FORM reference to a missing file"    "printf 'weekly: \`bash tools/hygiene.sh\`\\n' >> CLAUDE.md"
  expect pass "COMMAND-FORM reference that resolves"        "printf 'see \`cat agreements/A.md\` first\\n' >> CLAUDE.md"
  # ...and the two cases it must NOT reject (WA-A.1's second half).
  expect pass "a bare name a FUTURE row will create"        "printf 'the row writes \`s01_census.py\`\\n' >> ROADMAP.md"
  expect pass "docs/decisions may name a DELETED file"      "mkdir -p docs/decisions && printf 'retired \`results/R0/n.tsv\`\\n' > docs/decisions/0001-x.md"
  # The two classes the widened extractor started rejecting when it began reading
  # ROADMAP.md and BLOCKED.md: a bundle-relative OUTPUT, and a path into scratch.
  expect pass "a ROADMAP row names a table it WILL write"   "printf 'the row writes \`tables/census.tsv\`\\n' >> ROADMAP.md"
  expect pass "BLOCKED.md names a file in gitignored scratch" "mkdir -p docs && printf 'left at \`ARIS_OUTPUT/r01/scripts/probe.py\`\\n' > docs/BLOCKED.md"
  # ...and the class that must STILL be caught, so the two skips above did not
  # simply switch the check off for anything with a slash in it.
  expect fail "a REPO-ROOT path that does not exist"        "printf 'weekly: \`bash tools/hygiene.sh\`\\n' >> ROADMAP.md"
  # A must-read that lives inside a SUBMODULE must still resolve — this is how the
  # agreements layer is consumed by a subproject.
  S="$T/sub"; P="$T/super"; mkdir -p "$S" "$P"
  git -C "$S" init -q . && printf '# A\n' > "$S/A.md"
  git -C "$S" add -A && git -C "$S" -c user.email=t@t -c user.name=t commit -qm i
  git -C "$P" init -q .
  printf 'read `agreements/A.md` before acting.\n' > "$P/CLAUDE.md"
  printf '# r\n\n| `agreements/A.md` | rules |\n' > "$P/README.md"
  git -C "$P" add -A && git -C "$P" -c user.email=t@t -c user.name=t commit -qm i
  git -C "$P" -c protocol.file.allow=always submodule add -q "$S" agreements 2>/dev/null
  git -C "$P" -c user.email=t@t -c user.name=t commit -qm sub >/dev/null 2>&1
  if ( cd "$P" && bash "$ME" ) >/dev/null 2>&1; then
    printf '  ok    %-48s %s\n' "a must-read inside a SUBMODULE resolves" "pass"; ok=$((ok+1))
  else
    printf '  FAIL  %-48s %s\n' "a must-read inside a SUBMODULE resolves" "wanted pass"; bad=$((bad+1))
  fi

  # A project must not have to enumerate an inherited layer's files in its README.
  printf '# r\n\nno spec list here at all\n' > "$P/README.md"
  if ( cd "$P" && bash "$ME" ) >/dev/null 2>&1; then
    printf '  ok    %-48s %s\n' "submodule specs need no README entry" "pass"; ok=$((ok+1))
  else
    printf '  FAIL  %-48s %s\n' "submodule specs need no README entry" "wanted pass"; bad=$((bad+1))
  fi

  echo "--- $ok passed, $bad failed ---"
  [ "$bad" = 0 ] || { echo "SELFTEST FAILED"; exit 1; }
  echo "SELFTEST PASSED: rejects deleted, masked-deleted and MOVED must-reads; accepts a clean tree and a submodule"
  exit 0
fi
exit $fail
