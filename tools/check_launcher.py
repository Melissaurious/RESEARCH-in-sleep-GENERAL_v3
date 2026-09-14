#!/usr/bin/env python3
"""Refuse to start a track on a launcher that cannot run unattended.

The launcher is the only document the operator writes, and the only human stop in the loop
(WA-L.1). An unfilled field there does not degrade the run -- it stops it, at 3am, waiting
for someone who is asleep (WA-L.2).

    python general/tools/check_launcher.py launchers/LAUNCHER_<track>.md

Exit 0 = can run unattended.  Exit 1 = do not start; reasons are printed.
Spec: agreements/LAUNCHER_SPEC.md.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# heading substring -> human name. Matched case-insensitively, so rewording survives but a
# missing section does not.
REQUIRED: dict[str, str] = {
    "objective": "1. Objective and success criterion",
    "kill criteria": "2. Kill criteria",
    "non-goals": "3. Non-goals / out of scope",
    "inputs": "4. Inputs (with trust grades)",
    "already exist": "5. What might already exist",
    "claims": "6. Claims this track settles",
    "gates": "7. Gates",
    "compute": "8. Compute",
    "autonomy": "9. Autonomy: decide-alone vs stop-and-wait",
}

TRUST = ("RAW", "FROZEN", "RE-DERIVE", "DO-NOT-USE")
WEIGHTS = ("LIGHT", "FULL")

# A real placeholder never has whitespace just inside its brackets; `[ -f x ]` and a
# markdown checkbox `[ ]` always do. Markdown links `[text](url)` are excluded too.
PLACEHOLDER = re.compile(r"\[(?!\s)([^\[\]\n]{0,118}[^\s\[\]])\](?!\()")


def sections(text: str) -> str:
    """All ATX headings, lowercased and joined, for substring matching."""
    return " || ".join(
        ln.lstrip("#").strip().lower() for ln in text.splitlines() if ln.lstrip().startswith("#")
    )


def table_rows(text: str, after: str) -> list[str]:
    """Body rows of the first markdown table following a heading containing `after`."""
    lines, rows, seen, in_table = text.splitlines(), [], False, False
    for ln in lines:
        low = ln.lstrip("#").strip().lower()
        if ln.lstrip().startswith("#"):
            if seen and in_table:
                break
            seen = after in low
            in_table = False
            continue
        if seen and ln.strip().startswith("|"):
            if set(ln.strip()) <= set("|-: "):
                in_table = True
                continue
            if in_table:
                rows.append(ln.strip())
    return rows


def check(path: Path) -> list[str]:
    """Every launcher check. Empty list means it can run unattended."""
    problems: list[str] = []
    text = path.read_text(encoding="utf-8")
    heads = sections(text)

    for key, name in REQUIRED.items():
        if key not in heads:
            problems.append(f"MISSING SECTION  {name}")

    for lineno, line in enumerate(text.splitlines(), 1):
        if PLACEHOLDER.search(line):
            problems.append(f"UNFILLED  L{lineno:<4} {line.strip()[:92]}")

    for row in table_rows(text, "inputs"):
        if not any(g in row.upper() for g in TRUST):
            problems.append(
                f"NO TRUST GRADE   {row[:72]}\n"
                f"                   an ungraded input is DO-NOT-USE (WA-L.3)")

    for row in table_rows(text, "gates"):
        if not any(w in row.upper() for w in WEIGHTS):
            problems.append(f"NO WEIGHT        {row[:72]}  — LIGHT or FULL (WA-B.3)")
        if "run.sh" not in row and "reproduc" not in row.lower():
            problems.append(
                f"WEAK STOP COND.  {row[:72]}\n"
                f"                   must be 'results/<gate>/ exists and run.sh reproduces "
                f"the number' (WA-G.2)")

    claims = table_rows(text, "claims")
    for row in claims:
        if "UNPROVEN" not in row.upper():
            problems.append(
                f"CLAIM NOT UNPROVEN  {row[:66]}\n"
                f"                   every claim is born UNPROVEN, before its gate runs")
    if not claims:
        problems.append("NO CLAIMS        section 6 has no claim rows")

    return problems


def main() -> None:
    """CLI entry point."""
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("launcher", type=Path)
    args = ap.parse_args()

    if not args.launcher.is_file():
        print(f"✗ no such launcher: {args.launcher}", file=sys.stderr)
        sys.exit(2)

    problems = check(args.launcher)
    if not problems:
        print(f"✓ {args.launcher.name} — complete. This track can run unattended.")
        sys.exit(0)

    print(f"✗ {args.launcher.name} cannot run unattended ({len(problems)} problems):\n",
          file=sys.stderr)
    for p in problems:
        print(f"   {p}", file=sys.stderr)
    print("\nThe operator is the one resource that cannot be scheduled: a question asked\n"
          "mid-gate costs a night. The two fields that repay most:\n"
          "  · kill criteria            — only honest before a number exists\n"
          "  · what might already exist — absence is loud; wrongness is quiet",
          file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
