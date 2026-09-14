#!/usr/bin/env python3
"""Extract a self-contained reproduction bundle from a completed stage.

Reads every <artifact>.prov.json in a stage directory and emits:

    <out>/scripts/       the producing scripts, verbatim
    <out>/MANIFEST.tsv   artifact -> script, command, unit, denominator, sha256
    <out>/INPUTS.tsv     every input path with its recorded sha256, deduplicated
    <out>/run.sh         the recorded commands, in creation order
    <out>/README.md      what this bundle is and what it does NOT contain

This is the ONLY thing that should be published when a goal is reached: the
scripts that produced reported numbers, not the working tree.

An artifact with no .prov.json is not a result (REPORTING_STANDARDS) and is
reported here as UNPROVENANCED so it is visible rather than silently dropped.

Usage:
    extract_reproduce.py <stage_dir> [--out DIR] [--copy-scripts]
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path


def load_provs(stage: Path) -> tuple[list[dict], list[str]]:
    """Every parseable .prov.json under stage, plus a list of unparseable ones."""
    provs, bad = [], []
    for p in sorted(stage.rglob("*.prov.json")):
        try:
            d = json.loads(p.read_text(encoding="utf-8"))
        except Exception as e:  # a prov that does not parse is a defect, not a skip
            bad.append(f"{p}\t{type(e).__name__}: {e}")
            continue
        d["_prov_path"] = str(p)
        provs.append(d)
    return provs, bad


def unprovenanced(stage: Path) -> list[Path]:
    """Artifacts in tables/ or figures/ with no sibling .prov.json."""
    out = []
    for sub in ("tables", "figures"):
        for f in sorted((stage / sub).rglob("*")) if (stage / sub).is_dir() else []:
            if f.is_file() and not f.name.endswith(".prov.json"):
                if not f.with_name(f.name + ".prov.json").exists():
                    out.append(f)
    return out


def write_bundle(stage: Path, out: Path, copy_scripts: bool) -> dict:
    provs, bad = load_provs(stage)
    orphans = unprovenanced(stage)
    (out / "scripts").mkdir(parents=True, exist_ok=True)

    rows, inputs, cmds, missing_scripts, copied = [], {}, [], [], set()
    for d in sorted(provs, key=lambda x: x.get("created", "")):
        art = d.get("artifact", "?")
        script = d.get("script", "ABSENT")
        cmd = d.get("command", "")
        rows.append("\t".join(str(x) for x in [
            art, script, cmd, d.get("unit", ""), d.get("denominator", ""),
            d.get("created", ""), d.get("git_commit", ""), d.get("_prov_path", "")]))
        if cmd:
            cmds.append((d.get("created", ""), cmd))
        for i in d.get("inputs", []) or []:
            if isinstance(i, dict) and i.get("path"):
                inputs.setdefault(i["path"], i.get("sha256", "NOT_RECORDED"))
        if script and script != "ABSENT":
            src = Path(script) if Path(script).is_absolute() else stage / script
            if src.is_file():
                if copy_scripts and src.name not in copied:
                    shutil.copy2(src, out / "scripts" / src.name)
                    copied.add(src.name)
            else:
                missing_scripts.append(script)

    (out / "MANIFEST.tsv").write_text(
        "artifact\tscript\tcommand\tunit\tdenominator\tcreated\tgit_commit\tprov_path\n"
        + "\n".join(rows) + "\n", encoding="utf-8")
    (out / "INPUTS.tsv").write_text(
        "path\tsha256\n" + "\n".join(f"{k}\t{v}" for k, v in sorted(inputs.items())) + "\n",
        encoding="utf-8")
    (out / "run.sh").write_text(
        "#!/usr/bin/env bash\n# Regenerates every provenanced artifact, in creation order.\n"
        "# Verify inputs against INPUTS.tsv BEFORE running: a changed input invalidates every\n"
        "# number below. Paths are as recorded; edit the roots, never the commands.\nset -euo pipefail\n\n"
        + "\n".join(f"# {ts}\n{c}" for ts, c in cmds) + "\n", encoding="utf-8")
    (out / "run.sh").chmod(0o755)

    stats = dict(provenanced=len(provs), unparseable=len(bad), unprovenanced=len(orphans),
                 scripts_copied=len(copied), scripts_missing=len(set(missing_scripts)),
                 inputs=len(inputs), commands=len(cmds))
    (out / "README.md").write_text(f"""# Reproduction bundle — `{stage.name}`

Extracted by `tools/extract_reproduce.py`. **This is not the working tree.** It is the
subset that produced reported numbers.

| | count |
|---|---:|
| provenanced artifacts | {stats['provenanced']} |
| distinct inputs, with recorded sha256 | {stats['inputs']} |
| commands in `run.sh` | {stats['commands']} |
| scripts copied | {stats['scripts_copied']} |
| **scripts named but ABSENT from disk** | **{stats['scripts_missing']}** |
| **artifacts with NO `.prov.json`** | **{stats['unprovenanced']}** |
| `.prov.json` files that do not parse | {stats['unparseable']} |

## What is NOT here, deliberately

Working notes, intermediate caches, superseded drafts, and any artifact without a
`.prov.json` — which, per `REPORTING_STANDARDS`, is not a result. The counts above make
those visible rather than silently dropping them: **a non-zero "no `.prov.json`" or
"scripts ABSENT" row is a defect to fix before publishing, not a footnote.**

## To reproduce

1. Verify every input in `INPUTS.tsv` against its recorded `sha256`. A changed input
   invalidates every number in `MANIFEST.tsv`.
2. Run `run.sh`. Compare outputs against `MANIFEST.tsv`'s `unit` and `denominator`.

`git_commit` in the manifest is **advisory, not a pin** (`REPORTING_STANDARDS`). The pin
is `INPUTS.tsv`.
""" + (("\n## Unparseable `.prov.json`\n\n```\n" + "\n".join(bad) + "\n```\n") if bad else "")
      + (("\n## Artifacts with no `.prov.json`\n\n```\n"
          + "\n".join(str(o.relative_to(stage)) for o in orphans) + "\n```\n") if orphans else ""),
        encoding="utf-8")
    return stats


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("stage_dir")
    ap.add_argument("--out", default=None, help="default: <stage_dir>/reproduce")
    ap.add_argument("--copy-scripts", action="store_true", default=True)
    a = ap.parse_args()
    stage = Path(a.stage_dir).resolve()
    if not stage.is_dir():
        print(f"not a directory: {stage}", file=sys.stderr)
        return 2
    out = Path(a.out).resolve() if a.out else stage / "reproduce"
    s = write_bundle(stage, out, a.copy_scripts)
    print(f"{stage.name} -> {out}")
    for k, v in s.items():
        flag = "  <-- FIX BEFORE PUBLISHING" if k in ("scripts_missing", "unprovenanced", "unparseable") and v else ""
        print(f"  {k:22s} {v}{flag}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
