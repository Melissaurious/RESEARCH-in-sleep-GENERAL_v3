#!/usr/bin/env python3
"""Content-hash keyed cache for expensive intermediates.

Usage
-----
    from tools.cache import cached

    @cached(stage="stage3_ncrna")
    def count_rt_families(jsonl_path: Path, min_len: int = 100) -> pd.DataFrame:
        ...

The cache key is a hash of: function name, function source code, the argument
values, and (for any Path argument) that file's size and mtime.  Editing the
function body therefore invalidates its cache automatically -- the failure mode
hand-rolled caching almost always gets wrong.

DataFrames are stored as parquet; everything else falls back to pickle.
Every write appends a row to ``<stage>/cache/MANIFEST.tsv`` recording what was
cached, from which inputs, how long it took, and how large it is.

CLI
---
    python tools/cache.py --list  <stage_dir>     show the manifest
    python tools/cache.py --clear <stage_dir>     delete all cached entries
    python tools/cache.py --clear <stage_dir> --func count_rt_families
"""

from __future__ import annotations

import argparse
import functools
import hashlib
import inspect
import json
import os
import pickle
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Callable

MANIFEST_NAME = "MANIFEST.tsv"
MANIFEST_HEADER = (
    "timestamp\tfunction\tkey\tformat\tseconds\tsize_bytes\tinputs\n"
)

# Where stage directories live.  Overridable for tests / odd layouts.
ARIS_OUTPUT = Path(os.environ.get("ARIS_OUTPUT", "ARIS_OUTPUT"))


# --------------------------------------------------------------------------- #
# key construction
# --------------------------------------------------------------------------- #
def _fingerprint(value: Any) -> str:
    """Return a stable string fingerprint for a single argument value.

    Path-like values are fingerprinted by size and mtime rather than content,
    so a 40 GB JSONL does not have to be read just to decide whether the cache
    is valid.  If the file is missing, the path alone is used.
    """
    if isinstance(value, Path) or (
        isinstance(value, str) and os.sep in value and Path(value).exists()
    ):
        p = Path(value)
        try:
            st = p.stat()
            return f"path:{p.resolve()}:{st.st_size}:{int(st.st_mtime)}"
        except OSError:
            return f"path:{p}:missing"
    if isinstance(value, (list, tuple, set)):
        return "[" + ",".join(_fingerprint(v) for v in value) + "]"
    if isinstance(value, dict):
        return (
            "{"
            + ",".join(f"{k}={_fingerprint(v)}" for k, v in sorted(value.items()))
            + "}"
        )
    return f"{type(value).__name__}:{value!r}"


def _make_key(func: Callable, args: tuple, kwargs: dict) -> tuple[str, str]:
    """Return (hex_key, human_readable_inputs) for this call."""
    try:
        source = inspect.getsource(func)
    except (OSError, TypeError):  # e.g. defined in a REPL
        source = func.__qualname__

    bound = inspect.signature(func).bind(*args, **kwargs)
    bound.apply_defaults()
    parts = [f"{name}={_fingerprint(val)}" for name, val in bound.arguments.items()]
    inputs = "; ".join(parts)

    blob = "\n".join([func.__qualname__, source, inputs])
    key = hashlib.sha256(blob.encode()).hexdigest()[:16]
    return key, inputs


# --------------------------------------------------------------------------- #
# storage
# --------------------------------------------------------------------------- #
def _cache_dir(stage: str) -> Path:
    """Return (and create) the cache directory for a stage."""
    stage_path = Path(stage)
    if not stage_path.is_absolute() and stage_path.parts[:1] != ARIS_OUTPUT.parts[:1]:
        stage_path = ARIS_OUTPUT / stage
    d = stage_path / "cache"
    d.mkdir(parents=True, exist_ok=True)
    return d


def _load(base: Path) -> tuple[Any, str] | None:
    """Load a cached value if present.  Returns (value, format) or None."""
    parquet = base.with_suffix(".parquet")
    if parquet.exists():
        import pandas as pd

        return pd.read_parquet(parquet), "parquet"
    pkl = base.with_suffix(".pkl")
    if pkl.exists():
        with pkl.open("rb") as fh:
            return pickle.load(fh), "pickle"
    return None


def _store(base: Path, value: Any) -> tuple[Path, str]:
    """Write a value to the cache.  Returns (path_written, format)."""
    try:
        import pandas as pd

        if isinstance(value, pd.DataFrame):
            out = base.with_suffix(".parquet")
            value.to_parquet(out, index=False)
            return out, "parquet"
    except ImportError:
        pass

    out = base.with_suffix(".pkl")
    with out.open("wb") as fh:
        pickle.dump(value, fh, protocol=pickle.HIGHEST_PROTOCOL)
    return out, "pickle"


def _append_manifest(
    cache_dir: Path,
    func_name: str,
    key: str,
    fmt: str,
    seconds: float,
    size: int,
    inputs: str,
) -> None:
    """Append one row to the stage's cache manifest."""
    manifest = cache_dir / MANIFEST_NAME
    if not manifest.exists():
        manifest.write_text(MANIFEST_HEADER)
    row = "\t".join(
        [
            datetime.now().isoformat(timespec="seconds"),
            func_name,
            key,
            fmt,
            f"{seconds:.1f}",
            str(size),
            inputs.replace("\t", " ").replace("\n", " "),
        ]
    )
    with manifest.open("a") as fh:
        fh.write(row + "\n")


# --------------------------------------------------------------------------- #
# decorator
# --------------------------------------------------------------------------- #
def cached(stage: str, enabled: bool = True) -> Callable:
    """Cache a function's return value under ``<stage>/cache/``.

    Parameters
    ----------
    stage:
        Stage directory name (e.g. ``"stage3_ncrna"``) or a full path.  Bare
        names are resolved under ``$ARIS_OUTPUT`` (default ``ARIS_OUTPUT/``).
    enabled:
        Set False to bypass the cache entirely without removing the decorator.

    The wrapped function gains a ``.clear_cache()`` attribute and accepts a
    ``force_recompute=True`` keyword to ignore an existing entry.
    """

    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, force_recompute: bool = False, **kwargs):
            if not enabled:
                return func(*args, **kwargs)

            cache_dir = _cache_dir(stage)
            key, inputs = _make_key(func, args, kwargs)
            base = cache_dir / f"{func.__name__}_{key}"

            if not force_recompute:
                hit = _load(base)
                if hit is not None:
                    value, fmt = hit
                    print(
                        f"CACHE HIT  {func.__name__} [{key}] ({fmt})",
                        file=sys.stderr,
                    )
                    return value

            print(f"CACHE MISS {func.__name__} [{key}] — computing", file=sys.stderr)
            t0 = time.time()
            value = func(*args, **kwargs)
            seconds = time.time() - t0

            out, fmt = _store(base, value)
            _append_manifest(
                cache_dir, func.__name__, key, fmt, seconds, out.stat().st_size, inputs
            )
            print(
                f"CACHE WROTE {func.__name__} [{key}] "
                f"{out.name} in {seconds:.1f}s",
                file=sys.stderr,
            )
            return value

        def clear_cache() -> int:
            """Delete every cached entry for this function.  Returns count."""
            cache_dir = _cache_dir(stage)
            n = 0
            for p in cache_dir.glob(f"{func.__name__}_*"):
                if p.suffix in {".parquet", ".pkl"}:
                    p.unlink()
                    n += 1
            return n

        wrapper.clear_cache = clear_cache  # type: ignore[attr-defined]
        return wrapper

    return decorator


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #
def _cli_list(stage: str) -> None:
    manifest = _cache_dir(stage) / MANIFEST_NAME
    if not manifest.exists():
        print(f"No manifest at {manifest}")
        return
    print(manifest.read_text())


def _cli_clear(stage: str, func: str | None) -> None:
    cache_dir = _cache_dir(stage)
    pattern = f"{func}_*" if func else "*"
    n = 0
    for p in cache_dir.glob(pattern):
        if p.suffix in {".parquet", ".pkl"}:
            p.unlink()
            n += 1
    print(f"Removed {n} cached entries from {cache_dir}")


def main() -> None:
    ap = argparse.ArgumentParser(description="Inspect or clear a stage cache.")
    ap.add_argument("stage", help="stage dir name or path, e.g. stage3_ncrna")
    ap.add_argument("--list", action="store_true", help="print the cache manifest")
    ap.add_argument("--clear", action="store_true", help="delete cached entries")
    ap.add_argument("--func", help="restrict --clear to one function name")
    args = ap.parse_args()

    if args.clear:
        _cli_clear(args.stage, args.func)
    else:
        _cli_list(args.stage)


if __name__ == "__main__":
    main()