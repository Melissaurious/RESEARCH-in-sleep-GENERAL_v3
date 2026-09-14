#!/usr/bin/env python3
"""Build the schema-only view of a schema document, and prove it is clean.

A schema-only build is what gets staged into a BLIND stage: the field semantics
stay, every computed result goes. Doing that by hand is how `52,505 / 52,515`
survived into stage 0a (retro 2026-08-31_stage0a §3). This script makes the build
reproducible and self-checking.

    python tools/build_schema_only.py templates/input_format.md
    python tools/build_schema_only.py templates/input_format.md --check

Three transforms, in order:
  1. insert the SCHEMA ONLY banner after the H1;
  2. drop every trailing `[stage ...]` tag  — the declared strip point;
  3. apply the document's qualitative rewrites, for figures that live in prose
     rather than in a tag (see `<doc>.rewrites` sidecar / --rewrites).

Then it greps its OWN OUTPUT for surviving figures and fails if any is found.
That scan is the actual control: step 2 assumes no figure lives outside a tag,
and stage 0a's own §4 broke that assumption in one bullet of five. Never trust
the tags alone — retro 2026-08-31_stage0d_schema §2.

Figures inside a `<!-- STRIP EXEMPTION ... -->` / `<!-- /STRIP EXEMPTION -->`
block are waived: they are declared in the document, not hard-coded here.

Exit 0 = built (or, with --check, on disk and current). Exit 1 = something is
wrong and the file must not be staged. Exit 2 = bad usage.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

BANNER = (
    "> **SCHEMA ONLY.** Computed results have been removed so this file can be staged into\n"
    "> blind stages without leaking answers. For the full annotated version see\n"
    "> `{source}`.\n"
)

TAG_RE = re.compile(r"\n[ \t]*\[stage [^\]]*\]")
EXEMPT_RE = re.compile(r"<!--\s*STRIP EXEMPTION.*?<!--\s*/STRIP EXEMPTION\s*-->", re.S)

# The stage-0a §5.1 control: percentages and thousands-separated integers.
FIGURE_RES = [
    (re.compile(r"[0-9]+(?:\.[0-9]+)?\s*%"), "percentage"),
    (re.compile(r"[0-9]{1,3}(?:[,  ][0-9]{3})+"), "thousands-separated integer"),
    (re.compile(r"\[stage [^\]]*\]"), "unstripped [stage ...] tag"),
]


def fail(msg: str) -> None:
    print(f"FAIL  {msg}", file=sys.stderr)


def load_rewrites(src: Path, explicit: Path | None) -> list[dict]:
    path = explicit or src.with_name("schema_only_rewrites.json")
    if not path.exists():
        print(f"WARN  no rewrite table at {path} — tag-stripping only. "
              f"Any figure in prose will be caught by the scan below, not fixed.")
        return []
    return json.loads(path.read_text())["rewrites"]


def build(text: str, source_name: str, rewrites: list[dict]) -> tuple[str, list[str]]:
    """Return (schema_only_text, problems_found_while_building)."""
    problems: list[str] = []

    # 1. banner, immediately after the H1 and its blank line
    lines = text.split("\n")
    h1 = next((i for i, ln in enumerate(lines) if ln.startswith("# ")), None)
    if h1 is None:
        problems.append("no H1 found — cannot place the SCHEMA ONLY banner")
    else:
        at = h1 + 2 if h1 + 1 < len(lines) and not lines[h1 + 1].strip() else h1 + 1
        text = "\n".join(lines[:at]) + "\n" + BANNER.format(source=source_name) + "\n" + "\n".join(lines[at:])

    # 2. the declared strip point
    text, n_tags = TAG_RE.subn("", text)
    print(f"      stripped {n_tags} [stage ...] tag(s)")
    if n_tags == 0:
        problems.append("no [stage ...] tags found — is this the annotated source?")

    # 3. qualitative rewrites; each must land exactly once
    applied = 0
    for rw in rewrites:
        n = text.count(rw["old"])
        if n != 1:
            problems.append(f"rewrite matched {n}x, expected 1 — {rw['why']!r} "
                            f"(source drifted; update schema_only_rewrites.json)")
            continue
        text = text.replace(rw["old"], rw["new"])
        applied += 1
    print(f"      applied {applied}/{len(rewrites)} rewrite(s)")
    return text, problems


def scan(text: str) -> list[str]:
    """Grep the built output for surviving figures, honouring declared exemptions."""
    spans = [m.span() for m in EXEMPT_RE.finditer(text)]
    if spans:
        print(f"      {len(spans)} declared STRIP EXEMPTION block(s) waived")

    def exempt(pos: int) -> bool:
        return any(a <= pos < b for a, b in spans)

    problems = []
    for rx, label in FIGURE_RES:
        for m in rx.finditer(text):
            if exempt(m.start()):
                continue
            line = text.count("\n", 0, m.start()) + 1
            problems.append(f"SURVIVING FIGURE  line {line}: {m.group(0)!r} ({label})")
    return problems


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source", type=Path, help="the full annotated document")
    ap.add_argument("-o", "--out", type=Path,
                    help="output path (default: <source stem>_schema_only.md)")
    ap.add_argument("--rewrites", type=Path, help="rewrite table (default: sibling .json)")
    ap.add_argument("--check", action="store_true",
                    help="do not write; fail if the file on disk differs from a fresh build")
    args = ap.parse_args()

    if not args.source.is_file():
        fail(f"no such file: {args.source}")
        return 1
    out = args.out or args.source.with_name(args.source.stem + "_schema_only.md")

    print(f"\nbuilding {out.name} from {args.source.name}")
    built, problems = build(args.source.read_text(), str(args.source),
                            load_rewrites(args.source, args.rewrites))
    problems += scan(built)

    if problems:
        print(f"\n{len(problems)} problem(s):\n")
        for p in problems:
            print("  " + p)
        print("\nFAIL — not written. A schema-only file that still carries a computed\n"
              "figure is not schema-only: fix the source or declare an exemption.\n")
        return 1

    if args.check:
        if not out.exists():
            fail(f"{out} does not exist"); return 1
        if out.read_text() != built:
            fail(f"{out} is STALE — it differs from a fresh build. Re-run without --check.")
            return 1
        print(f"\nPASS — {out.name} is current and carries no computed figures.\n")
        return 0

    out.write_text(built)
    print(f"\nPASS — wrote {out} ({len(built.splitlines())} lines), no computed figures.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
