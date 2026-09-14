#!/usr/bin/env python3
"""Copy a cleared stage from the workshop into the shipped record.

    ARIS_OUTPUT/<STAGE_ID>/   ->   results/<STAGE_ID>/

Promotion is a COPY, never a move: the workshop copy stays intact as the audit trail.
Nothing is promoted that has not cleared pass 2 of specs/ADVERSARIAL_REVIEW.md, and
nothing is trusted that has not been RE-EXECUTED from a fresh tree -- a script that was
copied but never rerun is an unvalidated artefact (EVIDENCE_STANDARDS.md §1).

    python tools/promote_stage.py --stage stage3_embeddings --rerun
    python tools/promote_stage.py --stage stage3_embeddings --rerun-waived "14 GPU-hours"

Spec: specs/PROMOTION_STANDARDS.md.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

PROMOTE = ["README.md", "REPORT.md", "REPORT.html", "CLAIMS.tsv", "REPRODUCE.sh",
           "scripts", "figures", "tables"]
# REPORT.html is deliberately absent: markdown is the deliverable, HTML is opt-in
# per launcher (specs/REPORTING_STANDARDS.md).
REQUIRED = ["README.md", "REPORT.md", "CLAIMS.tsv", "REPRODUCE.sh", "scripts"]
FILE_CAP, STAGE_CAP = 5 * 1024**2, 50 * 1024**2
FIGURE_EXT = {".png", ".svg", ".eps", ".pdf"}
OK_VERDICTS = ("PASS", "PASS_WITH_CONCERNS")

UNRESOLVED = ("← pick one, delete the rest", "<the command and its output")
SECRET_RE = re.compile(
    r"(api[_-]?key|secret[_-]?key|password\s*=|BEGIN (RSA|OPENSSH) PRIVATE KEY|ghp_[A-Za-z0-9]{20})",
    re.IGNORECASE)
ABSPATH_RE = re.compile(r"(?<![\w/])/(?:home|Users)/[A-Za-z0-9._-]+/")


def sha256(p: Path) -> str:
    """Hash a file in bounded memory."""
    h = hashlib.sha256()
    with p.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def check_verdict(rev: Path) -> tuple[str, list[str]]:
    """Read the pass-2 verdict. Returns (verdict, problems)."""
    f = rev / "02_result_review.md"
    if not f.is_file():
        return "", [f"no pass-2 review at {f} — run adversary.py --pass result first"]
    for line in f.read_text(encoding="utf-8").splitlines():
        if line.strip().upper().startswith("VERDICT:"):
            v = line.split(":", 1)[1].strip().strip("`*").upper()
            if v in OK_VERDICTS:
                return v, []
            return v, [f"pass-2 verdict is {v} — gate closed, nothing promotes"]
    return "", ["pass-2 review has no parseable VERDICT line"]


def check_dispositions(rev: Path) -> list[str]:
    """Every BLOCKER/CONCERN must be dispositioned, with evidence, before promotion."""
    f = rev / "03_dispositions.md"
    if not f.is_file():
        return [f"no dispositions file at {f}"]
    text = f.read_text(encoding="utf-8")
    problems = [f"{f.name}: a finding is still unresolved ({m!r} remains)"
                for m in UNRESOLVED if m in text]
    for block in text.split("\n## ")[1:]:
        if UNRESOLVED[0] in block:
            continue  # already reported as unresolved; do not double-report
        if "ACCEPTED_RISK" in block and not re.search(r"\d{4}-\d{2}-\d{2}", block):
            problems.append(
                f"{f.name}: an ACCEPTED_RISK has no initials + date — "
                "only Melissa grants this, in writing")
    return problems


def check_figures(sd: Path) -> list[str]:
    """REPORTING_STANDARDS: every figure carries the TSV it was drawn from."""
    figs, tables = sd / "figures", sd / "tables"
    if not figs.is_dir():
        return []
    return [f"figure {f.name} has no tables/{f.stem}.tsv — it cannot be restyled or checked"
            for f in sorted(figs.iterdir())
            if f.suffix.lower() in FIGURE_EXT and not (tables / f"{f.stem}.tsv").is_file()]


def check_content(files: list[Path], root: Path) -> list[str]:
    """Scan promoted text for secrets and undeclared absolute paths."""
    problems: list[str] = []
    for f in files:
        if f.suffix.lower() in {".png", ".eps", ".pdf", ".npy", ".gz"}:
            continue
        try:
            text = f.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        rel = f.relative_to(root)
        if SECRET_RE.search(text):
            problems.append(f"{rel}: looks like it contains a credential")
        if f.suffix == ".py" and (m := ABSPATH_RE.search(text)):
            problems.append(
                f"{rel}: hardcodes {m.group(0)!r} — take paths from REPRODUCE.sh or a "
                "config block, or it will not run from a fresh checkout")
    return problems


def check_sizes(files: list[Path], root: Path, allow_large: bool) -> tuple[list[str], list[Path]]:
    """Enforce the size guard. Returns (problems, oversized files)."""
    big = [f for f in files if f.stat().st_size > FILE_CAP]
    total = sum(f.stat().st_size for f in files)
    if allow_large:
        return ([] if total - sum(f.stat().st_size for f in big) <= STAGE_CAP else
                [f"stage is {total/1024**2:.1f} MB even after excluding large files"]), big
    problems = [f"{f.relative_to(root)} is {f.stat().st_size/1024**2:.1f} MB (cap {FILE_CAP//1024**2} MB)"
                for f in big]
    if total > STAGE_CAP:
        problems.append(f"stage total is {total/1024**2:.1f} MB (cap {STAGE_CAP//1024**2} MB)")
    if problems:
        problems.append("→ trim, or re-run with --allow-large to record them in LARGE_ARTIFACTS.tsv")
    return problems, big


def stage_files(sd: Path) -> list[Path]:
    """The promotable files in the workshop, per PROMOTE. Excludes cache/, logs, review-stage/."""
    out: list[Path] = []
    for name in PROMOTE:
        p = sd / name
        if p.is_file():
            out.append(p)
        elif p.is_dir():
            out += [f for f in sorted(p.rglob("*"))
                    if f.is_file() and not f.name.startswith(".")
                    and f.suffix not in {".pyc", ".log"} and "__pycache__" not in f.parts]
    return out


def rerun(tmp: Path) -> tuple[bool, str]:
    """Execute REPRODUCE.sh in an isolated copy — the fresh-checkout test."""
    script = tmp / "REPRODUCE.sh"
    if not script.is_file():
        return False, "no REPRODUCE.sh"
    # --quick: regenerate tables and figures from cached intermediates. The expensive
    # --full path cannot run at a gate, and does not need to -- what is being tested is
    # that nothing depends on where the files happened to sit.
    r = subprocess.run(["bash", str(script), "--quick"], cwd=tmp, capture_output=True, text=True)
    tail = (r.stdout + r.stderr)[-1500:]
    return r.returncode == 0, f"exit {r.returncode}\n{tail}"


def write_provenance(dest: Path, stage: str, proj: Path, verdict: str, rerun_note: str) -> None:
    """Record what produced this, where, and whether it was re-verified."""
    try:
        commit = subprocess.run(["git", "-C", str(proj), "rev-parse", "HEAD"],
                                capture_output=True, text=True).stdout.strip() or "(not a git repo)"
    except OSError:
        commit = "(git unavailable)"
    (dest / "PROVENANCE.md").write_text(f"""# Provenance — `{stage}`

| | |
|---|---|
| Promoted | {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')} |
| Pass-2 verdict | `{verdict}` |
| Reproduction | {rerun_note} |
| Conda env | `{os.environ.get('CONDA_DEFAULT_ENV', '(unset)')}` |
| Python | {platform.python_version()} |
| Machine | {platform.node()} · {platform.platform()} |
| Project commit | `{commit}` |
| Workshop copy | `ARIS_OUTPUT/{stage}/` (intact — this is a copy, not a move) |

Input data paths and their checksums are declared in `REPRODUCE.sh` and `README.md`.
Promoted file checksums: `MANIFEST.tsv`.

⛔ Do not hand-edit anything in this directory. Edit the workshop copy and re-promote.
""", encoding="utf-8")


def main() -> None:
    """CLI entry point."""
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--stage", required=True)
    ap.add_argument("--project-root", type=Path, default=Path.cwd())
    ap.add_argument("--rerun", action="store_true", help="execute REPRODUCE.sh in a fresh tree")
    ap.add_argument("--rerun-waived", metavar="REASON", help="skip the rerun; reason is recorded")
    ap.add_argument("--allow-large", action="store_true")
    ap.add_argument("--dry-run", action="store_true", help="run every check, copy nothing")
    a = ap.parse_args()

    sd = a.project_root / "ARIS_OUTPUT" / a.stage
    if not sd.is_dir():
        sys.exit(f"✗ no such stage: {sd}")
    if not (a.rerun or a.rerun_waived):
        sys.exit("✗ choose --rerun (verify it reproduces) or --rerun-waived \"<reason>\".\n"
                 "  A promoted script that was never rerun is an unvalidated artefact.")

    problems: list[str] = [f"missing required {r}" for r in REQUIRED if not (sd / r).exists()]
    verdict, vp = check_verdict(sd / "review-stage")
    problems += vp + check_dispositions(sd / "review-stage") + check_figures(sd)
    files = stage_files(sd)
    if not files:
        problems.append("nothing promotable found")
    size_problems, big = check_sizes(files, sd, a.allow_large)
    problems += size_problems + check_content(files, sd)

    if problems:
        print(f"✗ {a.stage} does not promote ({len(problems)} problems):\n", file=sys.stderr)
        for p in problems:
            print(f"   · {p}", file=sys.stderr)
        sys.exit(1)

    keep = [f for f in files if f not in big]
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td) / a.stage
        for f in keep:
            (tmp / f.relative_to(sd)).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, tmp / f.relative_to(sd))
        if a.rerun:
            ok, note = rerun(tmp)
            print(f"  rerun (fresh tree) → {'OK' if ok else 'FAILED'}")
            if not ok:
                sys.exit(f"✗ REPRODUCE.sh does not run from a fresh checkout:\n{note}\n"
                         "  Fix it in the WORKSHOP, then re-promote. Never patch results/.")
            rerun_note = "✅ re-executed clean from a fresh tree at promotion time"
        else:
            rerun_note = f"⚠️ **NOT re-executed.** Waived: {a.rerun_waived}"
            print(f"  rerun → WAIVED ({a.rerun_waived})")

        rows = [f"{f.relative_to(tmp)}\t{f.stat().st_size}\t{sha256(f)}"
                for f in sorted(tmp.rglob('*')) if f.is_file()]
        (tmp / "MANIFEST.tsv").write_text("path\tbytes\tsha256\n" + "\n".join(rows) + "\n",
                                          encoding="utf-8")
        write_provenance(tmp, a.stage, a.project_root, verdict, rerun_note)
        if big:
            (tmp / "LARGE_ARTIFACTS.tsv").write_text(
                "path\tbytes\tsha256\tlives_at\n" + "\n".join(
                    f"{f.relative_to(sd)}\t{f.stat().st_size}\t{sha256(f)}\t{f}" for f in big) + "\n",
                encoding="utf-8")
            print(f"  {len(big)} file(s) over cap → LARGE_ARTIFACTS.tsv (bytes stay in the workshop)")

        dest = a.project_root / "results" / a.stage
        if a.dry_run:
            print(f"\n✓ every check passed. --dry-run: nothing written to {dest}")
            return
        if dest.exists():
            shutil.rmtree(dest)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(tmp, dest)

    print(f"\n✓ promoted → {dest}  ({len(keep)} files, verdict {verdict})")
    print(f"  workshop copy left intact at {sd}")
    print("\n⛔ Do NOT commit yet. results/ is committed by hand, by Melissa, at the end.")


if __name__ == "__main__":
    main()
