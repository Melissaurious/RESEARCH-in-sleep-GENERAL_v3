"""Artifact provenance writer.

Every file in tables/ or figures/ must have a sibling <basename>.prov.json.
Analysis scripts call write_artifact() instead of writing artifacts directly.

Usage:
    from prov import write_artifact

    write_artifact(
        artifact="tables/q1_corpus_counts.tsv",
        script=__file__,
        inputs=["/path/to/master_Retron_merged_oriented.jsonl"],
        params={"min_len": 150},
        unit="unique RT protein (rt_hash)",
        denominator=501561,
        runtime_s=412.3,
    )
"""

from __future__ import annotations

import getpass
import hashlib
import json
import os
import socket
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

_HASH_MAX_BYTES = 2 * 1024**3  # files above this are size+mtime stamped, not hashed


def _git_commit(start: Path) -> str:
    """Return the current commit of the repo containing `start`, or 'UNVERSIONED'."""
    try:
        out = subprocess.run(
            ["git", "-C", str(start), "rev-parse", "HEAD"],
            capture_output=True, text=True, timeout=10,
        )
        return out.stdout.strip() if out.returncode == 0 else "UNVERSIONED"
    except (OSError, subprocess.SubprocessError):
        return "UNVERSIONED"


_DIRTY_PATHS_MAX = 200  # keep the record small; the count is always exact


def _git_root(start: Path) -> str | None:
    """Absolute root of the repo containing `start`, or None if it is not in one."""
    try:
        out = subprocess.run(
            ["git", "-C", str(start), "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=10,
        )
        return out.stdout.strip() or None if out.returncode == 0 else None
    except (OSError, subprocess.SubprocessError):
        return None


def _git_dirty(start: Path) -> tuple[bool | None, list[str], int]:
    """(dirty, paths, total) for the repo containing `start`.

    `dirty` is None when `start` is not in a git repo at all — which is NOT the
    same as clean, and must not be allowed to read as clean. `paths` are
    repo-root-relative, so a checker can tell the stage's own outputs apart from
    somebody else's uncommitted work (retro 2026-08-31_stage0d_schema §5).
    """
    try:
        out = subprocess.run(
            ["git", "-C", str(start), "status", "--porcelain", "-uall"],
            capture_output=True, text=True, timeout=10,
        )
        if out.returncode != 0:
            return None, [], 0
    except (OSError, subprocess.SubprocessError):
        return None, [], 0

    paths = []
    for line in out.stdout.splitlines():
        if not line.strip():
            continue
        status, rel = line[:2], line[3:].strip()
        if " -> " in rel:                            # renames: record the destination
            rel = rel.split(" -> ", 1)[1]
        # The status code matters: "??" is a NEW file (every artifact is untracked
        # at the moment it is written), while a tracked modification means something
        # that was committed has since changed. A checker must tell them apart.
        paths.append({"status": status, "path": rel.strip('"')})
    paths.sort(key=lambda d: d["path"])
    return bool(paths), paths[:_DIRTY_PATHS_MAX], len(paths)


def _sha256(path: Path) -> str:
    """Stream a sha256. Large files get a cheap size+mtime stamp instead."""
    size = path.stat().st_size
    if size > _HASH_MAX_BYTES:
        return f"SKIPPED_LARGE:size={size}:mtime={int(path.stat().st_mtime)}"
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def _describe_input(spec: Any) -> dict:
    """Accept a path, or a dict with path plus caller-supplied extras (n_records...)."""
    extras: dict = {}
    if isinstance(spec, dict):
        extras = {k: v for k, v in spec.items() if k != "path"}
        spec = spec["path"]
    p = Path(spec)
    rec = {"path": str(p)}
    if p.exists():
        rec["sha256"] = _sha256(p)
        rec["bytes"] = p.stat().st_size
    else:
        rec["sha256"] = "MISSING"
    rec.update(extras)
    return rec


def write_artifact(
    artifact: str | Path,
    script: str | Path,
    inputs: Iterable[Any],
    unit: str,
    denominator: Any,
    params: dict | None = None,
    command: str | None = None,
    runtime_s: float | None = None,
) -> Path:
    """Write <artifact>.prov.json next to `artifact`. Returns the prov path.

    `unit` and `denominator` are REQUIRED (EVIDENCE_STANDARDS §8): every rate states
    what it is a rate of, and over what. Raises if the artifact does not exist or is
    empty — an artifact is validated by content, never by exit code (§1).
    """
    art = Path(artifact).resolve()
    if not art.exists():
        raise FileNotFoundError(f"artifact does not exist: {art}")
    if art.stat().st_size == 0:
        raise ValueError(f"artifact is 0 bytes: {art}")
    if not unit:
        raise ValueError("unit is required")
    if denominator is None:
        raise ValueError("denominator is required")

    script_path = Path(script).resolve()
    repo_anchor = script_path.parent if script_path.exists() else Path.cwd()
    _dirty, _dirty_paths, _dirty_n = _git_dirty(repo_anchor)

    rec = {
        "artifact": art.name,
        "artifact_path": str(art),
        "artifact_bytes": art.stat().st_size,
        "script": str(script_path),
        "git_commit": _git_commit(repo_anchor),
        "git_dirty": _dirty,
        "git_dirty_paths": _dirty_paths,
        "git_dirty_count": _dirty_n,
        "git_repo_root": _git_root(repo_anchor),
        "command": command or " ".join([sys.executable] + sys.argv),
        "inputs": [_describe_input(i) for i in inputs],
        "params": params or {},
        "unit": unit,
        "denominator": denominator,
        "created": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "env": os.environ.get("CONDA_DEFAULT_ENV", "UNKNOWN"),
        "host": socket.gethostname(),
        "user": getpass.getuser(),
        "python": sys.version.split()[0],
        "runtime_s": runtime_s,
    }

    prov = art.with_suffix(art.suffix + ".prov.json")
    prov.write_text(json.dumps(rec, indent=2, ensure_ascii=False) + "\n")
    return prov