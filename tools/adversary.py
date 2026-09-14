#!/usr/bin/env python3
"""Run an adversarial review pass against a stage, and record the verdict.

Two gates, per ``specs/ADVERSARIAL_REVIEW.md``:

    --pass plan     after PLAN.md exists, BEFORE anything heavy runs.  A BLOCKER here
                    stops execution.
    --pass result   after Phase B, BEFORE promotion.  A BLOCKER here stops promotion.

The packet handed to the reviewer deliberately contains the *artefacts and the standards*
and NOT the author's reasoning: no transcript, no justifications, no prior PASS.  A
reviewer given the argument grades the argument and agrees with it.

    python tools/adversary.py --stage stage3_embeddings --pass plan
    python tools/adversary.py --stage stage3_embeddings --pass plan --dry-run

Reviewer command comes from $RSG_REVIEW_CMD (see specs/TOOLING.md).  The reviewer is
probed by EXECUTION before it is trusted (EVIDENCE_STANDARDS.md §2) -- installed-but-
failing is PRESENT_BUT_BROKEN and does not count as a clear gate.
"""

from __future__ import annotations

import argparse
import os
import shlex
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

RSG = Path(__file__).resolve().parent.parent
DEFAULT_REVIEW_CMD = "codex exec --skip-git-repo-check -"
MAX_EMBED_BYTES = 60_000  # per included file; keeps the packet reviewable

VERDICTS = ("PASS", "PASS_WITH_CONCERNS", "FAIL", "INSUFFICIENT_INFORMATION")

PLAN_QUESTIONS = """\
1.  Could this plan return a NEGATIVE? If nothing could falsify it, it is a description,
    not a test -- say so as a BLOCKER.
2.  Grade circularity NONE/LOW/MEDIUM/HIGH for every method. Is anything measured with
    the instrument that DEFINED it? HIGH is a BLOCKER.
3.  Is every threshold declared in code BEFORE scoring? A cut chosen after seeing the
    outcome is the result, not a parameter.
4.  Is every claimed independence COMPUTED, or assumed?
5.  Is there a positive control for every intended negative claim?
6.  Does anything reported come from a SAMPLE rather than an exact pass over all records?
7.  Has the plan probed real field VALUES, or trusted a schema document?
8.  What already exists on disk that this plan would rebuild -- and would a stale or
    wrongly-computed existing artefact read as ready? Absence is loud; wrongness is quiet.
9.  Is the compute estimate derived from a MEASURED smoke test, or guessed?
10. What in this plan would you attack first if you wanted it to be wrong?"""

RESULT_QUESTIONS = """\
1.  Walk EVIDENCE_STANDARDS.md §8 item by item against these artefacts. Name each item
    as satisfied, violated, or unverifiable from the packet.
2.  Does EVERY number in REPORT.md trace to a script here? Any hand-copied, remembered or
    separately-recomputed number is a BLOCKER.
3.  Does every figure have its TSV, same basename, in tables/?
4.  Is every artefact validated by CONTENT -- bytes, parse, record count, an asserted
    invariant -- rather than by exists() or exit code?
5.  Are exact statements EXACT? Check arithmetic and identities literally; a percentage
    that rounds differently, or a size identity that ignores a file header, is a finding.
6.  Are claims scoped to what was actually examined?
7.  Are negative, null and surprising results stated plainly, or softened?
8.  Would REPRODUCE.sh run on a machine that is not this one?
9.  What here would you attack first if you wanted the conclusion to be wrong?"""


def stage_dir(project_root: Path, stage_id: str) -> Path:
    """Return ARIS_OUTPUT/<stage_id>/, erroring clearly if it is absent."""
    d = project_root / "ARIS_OUTPUT" / stage_id
    if not d.is_dir():
        sys.exit(f"✗ no such stage directory: {d}")
    return d


def embed(path: Path, label: str) -> str:
    """Render one file into the packet, truncated, or a clear note that it is missing."""
    if not path.is_file():
        return f"\n### {label}\n_(absent: {path})_\n"
    raw = path.read_text(encoding="utf-8", errors="replace")
    if len(raw) > MAX_EMBED_BYTES:
        raw = raw[:MAX_EMBED_BYTES] + f"\n\n…[truncated at {MAX_EMBED_BYTES} bytes]…\n"
    return f"\n### {label}  `{path}`\n\n```\n{raw}\n```\n"


def listing(d: Path, label: str) -> str:
    """Render a directory listing with sizes, for artefacts too big or binary to embed."""
    if not d.is_dir():
        return f"\n### {label}\n_(absent: {d})_\n"
    rows = sorted(f"{p.stat().st_size:>12,}  {p.relative_to(d)}" for p in d.rglob("*") if p.is_file())
    body = "\n".join(rows) or "(empty)"
    return f"\n### {label}  `{d}`\n\n```\n{'bytes':>12}  path\n{body}\n```\n"


def build_packet(sd: Path, launcher: Path, which: str) -> str:
    """Assemble the reviewer packet. Artefacts and standards only -- never the transcript."""
    head = f"""# ADVERSARIAL REVIEW PACKET — pass `{which}` — `{sd.name}`

You are an adversarial reviewer. Your job is to find what is WRONG, not to summarise.
You have deliberately NOT been given the author's reasoning, its confidence, or any
earlier review. Judge the artefacts against the standards below, nothing else.

## Answer in exactly this shape

```
VERDICT: <PASS | PASS_WITH_CONCERNS | FAIL | INSUFFICIENT_INFORMATION>

FINDINGS
- [BLOCKER|CONCERN|NIT] <one-line claim>
  WHY:  <the specific mechanism by which this produces a wrong or unfalsifiable result>
  TEST: <the command, check or artefact that would settle it>

CHECKED:     <what you actually verified, and how>
NOT CHECKED: <what you could not verify from this packet, and why>
```

Rules for you:
- `INSUFFICIENT_INFORMATION` is a respectable answer. Use it rather than guessing.
- `NOT CHECKED` may NOT be empty. If you could verify everything, you have not understood
  the stage. A review with no coverage statement does not count as a pass.
- A `BLOCKER` means the stage would produce a wrong, circular, or unfalsifiable number.
- Do not suggest scope the launcher explicitly excludes.

## Questions to work through

{PLAN_QUESTIONS if which == "plan" else RESULT_QUESTIONS}

---
# THE STAGE
"""
    parts = [head, embed(launcher, "Launcher (objective, falsifier, scope, budget)")]
    if which == "plan":
        parts.append(embed(sd / "PLAN.md", "PLAN.md"))
        parts.append(embed(sd / "STATUS.md", "STATUS.md (recon so far)"))
    else:
        parts += [
            embed(sd / "REPORT.md", "REPORT.md"),
            embed(sd / "FINDINGS.md", "FINDINGS.md"),
            embed(sd / "STATUS.md", "STATUS.md"),
            embed(sd / "REPRODUCE.sh", "REPRODUCE.sh"),
            listing(sd / "scripts", "scripts/"),
            listing(sd / "tables", "tables/"),
            listing(sd / "figures", "figures/"),
        ]
    parts.append("\n---\n# THE STANDARDS\n")
    parts.append(embed(RSG / "specs" / "EVIDENCE_STANDARDS.md", "EVIDENCE_STANDARDS.md"))
    parts.append(embed(RSG / "specs" / "WORKING_AGREEMENT.md", "WORKING_AGREEMENT.md"))
    return "".join(parts)


def probe_reviewer(cmd: str) -> tuple[str, str]:
    """Grade the reviewer by EXECUTION, not presence (EVIDENCE_STANDARDS §2)."""
    exe = shlex.split(cmd)[0]
    if shutil.which(exe) is None:  # handles both bare names and absolute paths
        return "ABSENT", f"{exe!r} is not an executable on PATH"
    try:
        r = subprocess.run(cmd, shell=True, input="Reply with exactly: OK", text=True,
                           capture_output=True, timeout=180)
    except subprocess.TimeoutExpired:
        return "PRESENT_BUT_BROKEN", "probe timed out after 180s"
    if r.returncode != 0:
        return "PRESENT_BUT_BROKEN", f"probe exited {r.returncode}: {r.stderr.strip()[:300]}"
    if not r.stdout.strip():
        return "PRESENT_BUT_BROKEN", "probe exited 0 but wrote nothing (silent success)"
    return "VERIFIED", f"probe returned {len(r.stdout.strip())} chars"


def run_reviewer(cmd: str, packet: str) -> tuple[int, str, str]:
    """Send the packet to the reviewer on stdin. Returns (returncode, stdout, stderr)."""
    r = subprocess.run(cmd, shell=True, input=packet, text=True, capture_output=True)
    return r.returncode, r.stdout, r.stderr


def parse_verdict(review: str) -> str | None:
    """Extract the single VERDICT token from a review body."""
    for line in review.splitlines():
        if line.strip().upper().startswith("VERDICT:"):
            token = line.split(":", 1)[1].strip().strip("`*").upper()
            return token if token in VERDICTS else None
    return None


def write_dispositions_stub(path: Path, review: str, which: str) -> None:
    """Pre-seed 03_dispositions.md with every finding, so none can be quietly dropped."""
    if path.exists():
        return
    findings = [ln.strip() for ln in review.splitlines()
                if ln.strip().lstrip("-* ").upper().startswith(("[BLOCKER", "[CONCERN"))]
    body = "\n\n".join(
        f"## {f.lstrip('-* ')}\n\n"
        "**Disposition:** `FIXED` | `REFUTED` | `ACCEPTED_RISK`  ← pick one, delete the rest\n\n"
        "**Evidence:**\n```\n<the command and its output. Prose alone never closes a finding.\n"
        "REFUTED requires a test that would have CONFIRMED the finding had it been right.\n"
        "ACCEPTED_RISK requires Melissa's initials + date — never self-granted.>\n```"
        for f in findings) or "_No BLOCKER or CONCERN findings returned._"
    path.write_text(f"# Dispositions — pass `{which}`\n\n"
                    f"_Spec: `specs/ADVERSARIAL_REVIEW.md` §4._\n\n{body}\n", encoding="utf-8")


def main() -> None:
    """CLI entry point."""
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--stage", required=True, help="STAGE_ID, e.g. stage3_embeddings")
    ap.add_argument("--pass", dest="which", required=True, choices=("plan", "result"))
    ap.add_argument("--project-root", type=Path, default=Path.cwd())
    ap.add_argument("--launcher", type=Path, default=None, help="default: launchers/LAUNCHER_<stage>.md")
    ap.add_argument("--dry-run", action="store_true", help="build the packet, do not call the reviewer")
    a = ap.parse_args()

    sd = stage_dir(a.project_root, a.stage)
    launcher = a.launcher or (a.project_root / "launchers" / f"LAUNCHER_{a.stage}.md")
    rev = sd / "review-stage"
    rev.mkdir(exist_ok=True)
    n = "01_plan" if a.which == "plan" else "02_result"

    packet = build_packet(sd, launcher, a.which)
    (rev / f"{n}_PACKET.md").write_text(packet, encoding="utf-8")
    print(f"  packet  → {rev / f'{n}_PACKET.md'}  ({len(packet):,} bytes)")
    if a.dry_run:
        print("  --dry-run: reviewer not called.")
        return

    cmd = os.environ.get("RSG_REVIEW_CMD", DEFAULT_REVIEW_CMD)
    grade, note = probe_reviewer(cmd)
    print(f"  reviewer → {grade}  ({note})")
    if grade != "VERIFIED":
        sys.exit(
            f"\n✗ reviewer is {grade}. This is NOT a cleared gate.\n"
            f"  Fix the reviewer, or run the packet through one by hand and save the reply as\n"
            f"  {rev / f'{n}_review.md'} — a missing reviewer never counts as a pass.")

    rc, out, err = run_reviewer(cmd, packet)
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    header = (f"# Adversarial review — pass `{a.which}` — `{a.stage}`\n\n"
              f"_{stamp} · reviewer `{cmd}` · grade `{grade}` ({note}) · exit {rc}_\n\n---\n\n")
    (rev / f"{n}_review.md").write_text(header + (out or f"(no stdout)\n\n{err}"), encoding="utf-8")
    print(f"  review  → {rev / f'{n}_review.md'}")

    verdict = parse_verdict(out)
    write_dispositions_stub(rev / "03_dispositions.md", out, a.which)
    if verdict is None:
        sys.exit("\n✗ no parseable VERDICT line. Treat as INSUFFICIENT_INFORMATION and re-run.")
    print(f"\n  VERDICT: {verdict}")
    if verdict in ("FAIL", "INSUFFICIENT_INFORMATION"):
        gate = "execution" if a.which == "plan" else "promotion"
        sys.exit(f"✗ gate closed — no {gate}. Disposition every finding in "
                 f"{rev / '03_dispositions.md'}, fix, and re-review.")
    print(f"✓ gate open. Still disposition every CONCERN in {rev / '03_dispositions.md'}.")


if __name__ == "__main__":
    main()
