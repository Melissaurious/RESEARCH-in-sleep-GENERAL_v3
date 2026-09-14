#!/usr/bin/env python3
"""Refuse to start a stage on an incomplete launcher.

The launcher is the one artefact only Melissa can write, and an unfilled field there is
the cheapest possible place to catch a problem -- a missing falsifier costs seconds now
and a whole stage later.  This turns "is the launcher ready?" from a judgement call into
an exit code, the same way ``tools/dispatch.py`` does for machine choice.

    python tools/check_launcher.py $PROJ/launchers/LAUNCHER_stage3_embeddings.md

Exit 0 = ready to launch.  Exit 1 = do not start; the reasons are printed.
Spec: ``specs/LAUNCHER_TEMPLATE.md`` (Part A) and ``specs/ANCHORS.md`` §3.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

STAGE_ID_RE = re.compile(r"^stage[0-9]+_[a-z0-9_]+$")

# Substring -> human name.  Matched case-insensitively against '##' headings, so small
# rewordings survive but a missing section does not.
REQUIRED_SECTIONS: dict[str, str] = {
    "stage_id": "STAGE_ID",
    "project": "Project (root, env, machine)",
    "objective": "Objective",
    "stated so it can fail": "The question, stated so it can fail",
    "success criterion": "Success criterion",
    "out of scope": "Out of scope",
    "inputs": "Inputs (read-only)",
    "already exist": "What might already exist",
    "compute budget": "Compute budget",
    "gate": "Gate - what I check before you execute",
    "promotion": "Promotion - what must land in results/",
}

# A bracketed span that is NOT a markdown link ([text](url)) and NOT shell test syntax.
# Discriminator: a real placeholder never has a space immediately inside its brackets,
# whereas `[ -f x ]` and a markdown checkbox `[ ]` always do.
PLACEHOLDER_RE = re.compile(r"\[(?!\s)([^\[\]\n]{0,118}[^\s\[\]])\](?!\()")


def read_headings(text: str) -> list[str]:
    """Return every ATX heading in the document, stripped of leading '#' and spaces."""
    return [ln.lstrip("#").strip() for ln in text.splitlines() if ln.lstrip().startswith("#")]


def missing_sections(text: str) -> list[str]:
    """Names of required Part A sections with no matching heading."""
    heads = " || ".join(h.lower() for h in read_headings(text))
    return [name for key, name in REQUIRED_SECTIONS.items() if key not in heads]


def find_placeholders(text: str) -> list[tuple[int, str]]:
    """Return (line number, line) for every line still holding a [bracketed] placeholder."""
    hits: list[tuple[int, str]] = []
    for i, line in enumerate(text.splitlines(), 1):
        if PLACEHOLDER_RE.search(line):
            hits.append((i, line.strip()))
    return hits


def extract_stage_id(text: str) -> str | None:
    """Pull the STAGE_ID value from the line following the '## STAGE_ID' heading."""
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if line.lstrip("#").strip().lower().startswith("stage_id"):
            for follow in lines[i + 1 : i + 5]:
                m = re.search(r"`([^`]+)`", follow)
                if m:
                    return m.group(1).strip()
    return None


def check(path: Path) -> list[str]:
    """Run every launcher check. Returns a list of problems; empty means ready."""
    problems: list[str] = []
    text = path.read_text(encoding="utf-8")

    for name in missing_sections(text):
        problems.append(f"MISSING SECTION   {name}")

    stage_id = extract_stage_id(text)
    if stage_id is None:
        problems.append("MISSING STAGE_ID  no `backticked` value under the STAGE_ID heading")
    elif not STAGE_ID_RE.match(stage_id):
        problems.append(
            f"BAD STAGE_ID      {stage_id!r} does not match ^stage[0-9]+_[a-z0-9_]+$"
        )
    else:
        expected = f"LAUNCHER_{stage_id}.md"
        if path.name != expected:
            problems.append(
                f"NAME MISMATCH     STAGE_ID is {stage_id!r} but the file is {path.name!r};"
                f" expected {expected}"
            )

    for lineno, line in find_placeholders(text):
        problems.append(f"UNFILLED  L{lineno:<4} {line[:96]}")

    return problems


def main() -> None:
    """CLI entry point."""
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("launcher", type=Path, help="path to LAUNCHER_<STAGE_ID>.md")
    args = ap.parse_args()

    if not args.launcher.is_file():
        print(f"✗ no such launcher: {args.launcher}", file=sys.stderr)
        sys.exit(2)

    problems = check(args.launcher)
    if not problems:
        print(f"✓ {args.launcher.name} is complete — ready to launch.")
        sys.exit(0)

    print(f"✗ {args.launcher.name} is not ready ({len(problems)} problems):\n", file=sys.stderr)
    for p in problems:
        print(f"   {p}", file=sys.stderr)
    print(
        "\nAn unfilled field is a blocker, not a default. The two that repay most:\n"
        "  · the question stated so it can fail  (nothing falsifiable ⇒ it is a description)\n"
        "  · what might already exist            (absence is loud; wrongness is quiet)",
        file=sys.stderr,
    )
    sys.exit(1)


if __name__ == "__main__":
    main()
