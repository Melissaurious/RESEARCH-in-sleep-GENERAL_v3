#!/usr/bin/env python3
"""Stage provenance gate.

Walks a stage directory and fails if any artifact in tables/ or figures/ lacks a
valid sibling .prov.json. Run as the LAST step of every stage, before STATUS.md.

    python tools/check_prov.py ARIS_OUTPUT/stage0a_blind_repro

An unversioned write fails unless it predates the repo's git init.
A dirty tree fails only for the stage's own outputs or its producing code;
uncommitted work elsewhere in the repo is a warning (retro 0b/0d).

Exit 0 = every artifact accounted for. Exit 1 = the stage is not complete.
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

# V5's git init (first commit fd46b8c, 2026-08-31T19:14:21+03:00). A record written
# BEFORE this could not have been versioned — the repo did not exist yet — so it is
# grandfathered to a warning. Anything written after must be versioned: a provenance
# record whose commit does not identify the code that ran looks authoritative and is
# not. Fail closed; failing open is what let this through (retro 0d, 2026-08-31).
GRANDFATHER_UNVERSIONED_BEFORE = datetime(2026, 8, 31, 16, 14, 21, tzinfo=timezone.utc)

ARTIFACT_DIRS = ("tables", "figures")
ARTIFACT_EXTS = {".tsv", ".csv", ".png", ".eps", ".svg", ".pdf", ".parquet"}
REQUIRED_FIELDS = ("artifact", "script", "git_commit", "inputs",
                   "unit", "denominator", "created")


def predates_version_control(rec: dict) -> bool:
    """True if this record was written before the repo existed.

    Unparseable or absent timestamps are NOT grandfathered: a record that cannot
    say when it was written cannot claim the exemption.
    """
    raw = rec.get("created", "")
    try:
        ts = datetime.fromisoformat(raw)
    except (TypeError, ValueError):
        return False
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    return ts < GRANDFATHER_UNVERSIONED_BEFORE


def classify_dirty(rec: dict, art: Path, stage: Path, problems: list[str]) -> list[str]:
    """Split a dirty tree into what the stage is answerable for and what it is not.

    A stage cannot commit another session's files, and must not be failed for
    refusing to (retro 2026-08-31_stage0b). But a dirty tree still voids
    provenance when it touches this stage's own evidence or the code that made
    it. Status codes matter: every artifact is untracked ("??") at the instant it
    is written, so untracked output is normal, while a MODIFIED tracked file is a
    committed thing that has since changed.

      producing script / tools/, any status -> FAIL  commit does not identify the code
      stage's own tree, tracked modification-> FAIL  a committed artifact was altered
      stage's own tree, untracked (new)     -> ok    this is the stage writing itself
      anywhere else in the repo            -> WARN  somebody else's work in progress
    """
    if not rec.get("git_dirty"):
        return []

    entries = rec.get("git_dirty_paths")
    if entries is None:
        return [f"DIRTY_LEGACY   {art}  dirty at write time, but the record predates "
                f"path capture — cannot tell whose files. Not failing on it."]

    root = Path(rec.get("git_repo_root") or ".")
    script = Path(rec.get("script", ""))
    code, altered, other = [], [], []
    for e in entries:
        # tolerate the older shape, where an entry was a bare path string
        rel = e["path"] if isinstance(e, dict) else e
        status = e.get("status", "??") if isinstance(e, dict) else "??"
        untracked = status.strip() == "??"
        p = (root / rel).resolve()

        if p == script or "tools" in p.parts:
            code.append(rel)
        elif p == stage or stage in p.parents or p in stage.parents:
            if not untracked:
                altered.append(f"{status.strip()} {rel}")
        else:
            other.append(rel)

    for rel in code:
        problems.append(f"DIRTY_CODE     {art}  producing code was uncommitted at "
                        f"write time, so git_commit does not identify it: {rel}")
    for rel in altered:
        problems.append(f"DIRTY_OUTPUT   {art}  a committed file in this stage was "
                        f"modified, not newly written: {rel}")

    warns = []
    if other:
        n = rec.get("git_dirty_count", len(entries))
        shown = ", ".join(other[:3]) + (f", +{len(other) - 3} more" if len(other) > 3 else "")
        warns.append(f"DIRTY_ELSEWHERE {art}  {len(other)} of {n} uncommitted path(s) are "
                     f"outside this stage and its code: {shown}")
    return warns


def check_stage(stage: Path) -> int:
    if not stage.is_dir():
        print(f"FAIL  not a directory: {stage}")
        return 1

    artifacts: list[Path] = []
    for sub in ARTIFACT_DIRS:
        d = stage / sub
        if d.is_dir():
            artifacts += [
                p for p in sorted(d.rglob("*"))
                if p.is_file()
                and p.suffix.lower() in ARTIFACT_EXTS
                and not p.name.endswith(".prov.json")
            ]

    if not artifacts:
        print(f"WARN  no artifacts found under {stage}/{{{','.join(ARTIFACT_DIRS)}}}")
        return 0

    problems: list[str] = []
    warnings: list[str] = []
    for art in artifacts:
        prov = art.with_suffix(art.suffix + ".prov.json")

        if not prov.exists():
            problems.append(f"ORPHAN         {art}  (no {prov.name})")
            continue
        if art.stat().st_size == 0:
            problems.append(f"EMPTY          {art}  (0 bytes)")
            continue

        try:
            rec = json.loads(prov.read_text())
        except json.JSONDecodeError as e:
            problems.append(f"UNPARSEABLE    {prov}  ({e})")
            continue

        missing = [f for f in REQUIRED_FIELDS if f not in rec or rec[f] in (None, "")]
        if missing:
            problems.append(f"INCOMPLETE     {prov}  missing: {', '.join(missing)}")
            continue

        script = rec.get("script", "")
        if script and not Path(script).exists():
            problems.append(f"SCRIPT_ABSENT  {art}  script not on disk: {script}")

        for inp in rec.get("inputs", []):
            if inp.get("sha256") == "MISSING":
                problems.append(f"INPUT_MISSING  {art}  input absent: {inp.get('path')}")

        if rec.get("git_commit") == "UNVERSIONED":
            if predates_version_control(rec):
                warnings.append(
                    f"UNVERSIONED    {art}  no git repo at write time — predates V5's "
                    f"git init ({GRANDFATHER_UNVERSIONED_BEFORE.date()}), grandfathered. "
                    f"The numbers are fine; the version control was not there yet.")
            else:
                problems.append(
                    f"UNVERSIONED    {art}  no git repo at write time — the commit does "
                    f"not identify the code that ran, and this was written after V5's "
                    f"git init. Commit the tree and re-run the producing script.")

        warnings += classify_dirty(rec, art, stage.resolve(), problems)

    print(f"\n{len(artifacts)} artifact(s) under {stage}")
    if warnings:
        print(f"{len(warnings)} warning(s):\n")
        for w in warnings:
            print("  " + w)
        print()
    if problems:
        print(f"{len(problems)} problem(s):\n")
        for p in problems:
            print("  " + p)
        print("\nFAIL — stage is not complete. An artifact without valid provenance "
              "is not a result: tag it [UNVERIFIED] or delete it.")
        return 1

    print("PASS — every artifact has valid provenance"
          + (" (with warnings).\n" if warnings else ".\n"))
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(check_stage(Path(sys.argv[1])))