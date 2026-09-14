#!/usr/bin/env python3
"""Decide where a job runs: borg (local) or Ibex (SLURM).

The point of this module is to turn "should this run locally?" from a judgement
call the agent might get wrong into a function call with an auditable, stated
reason.  Nothing here submits anything -- it emits an sbatch script for you to
review and submit yourself.

Python
------
    from tools import dispatch

    d = dispatch.decide(est_minutes=180, needs_gpu=True, vram_gb=40)
    print(d.target, d.reason)      # 'ibex'  'needs 40 GB VRAM; borg GPUs have 24 GB'

CLI
---
    python tools/dispatch.py --est-minutes 180 --gpu --vram 40 --explain
    python tools/dispatch.py --est-minutes 360 --gpu --vram 40 \
        --emit-sbatch --job-name esmfold --command "python run.py" \
        --out ARIS_OUTPUT/stage4/scripts/run.slurm

Thresholds live in THRESHOLDS below and should match compute/resources.md.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from dataclasses import dataclass, asdict
from pathlib import Path

# --------------------------------------------------------------------------- #
# policy — keep in sync with compute/resources.md
# --------------------------------------------------------------------------- #
THRESHOLDS = {
    "max_local_minutes": 120,      # anything longer goes to Ibex
    "borg_vram_gb": 24,            # per RTX 4090
    "borg_ram_gb": 251,
    "gpu_busy_util_pct": 25,       # above this, treat the GPU as in use
    "gpu_busy_vram_gb": 4,         # or this much VRAM already allocated
    "ram_headroom_gb": 32,         # refuse local if less free than this
    "cpu_busy_load_per_core": 0.7, # 1-min loadavg / cores
}

IBEX = {
    "account": "pi-hohndor",
    "email": "melissa.rioszertuche@kaust.edu.sa",
    "logs": "/ibex/user/rioszemm/experiments/logs",
    "envs": "/ibex/user/rioszemm/conda-environments",
}

# (max_hours, partition) in ascending order; first fit wins.
PARTITION_LADDER = [
    (4, "gpu4"),
    (24, "gpu24"),
    (72, "gpu72"),
    (336, "gpu"),
]
CPU_PARTITION = "batch"
LARGEMEM_PARTITION = "largemem"


# --------------------------------------------------------------------------- #
# live state
# --------------------------------------------------------------------------- #
@dataclass
class GPUState:
    index: int
    name: str
    util_pct: int
    mem_used_gb: float
    mem_total_gb: float

    @property
    def free_gb(self) -> float:
        return self.mem_total_gb - self.mem_used_gb

    @property
    def busy(self) -> bool:
        return (
            self.util_pct > THRESHOLDS["gpu_busy_util_pct"]
            or self.mem_used_gb > THRESHOLDS["gpu_busy_vram_gb"]
        )


@dataclass
class HostState:
    gpus: list[GPUState]
    ram_free_gb: float
    cores: int
    load1: float

    @property
    def cpu_busy(self) -> bool:
        return (self.load1 / max(self.cores, 1)) > THRESHOLDS["cpu_busy_load_per_core"]

    @property
    def free_gpus(self) -> list[GPUState]:
        return [g for g in self.gpus if not g.busy]


def read_host_state() -> HostState:
    """Snapshot local GPU/RAM/CPU state.  Degrades gracefully if tools absent."""
    gpus: list[GPUState] = []
    if shutil.which("nvidia-smi"):
        try:
            out = subprocess.run(
                [
                    "nvidia-smi",
                    "--query-gpu=index,name,utilization.gpu,memory.used,memory.total",
                    "--format=csv,noheader,nounits",
                ],
                capture_output=True,
                text=True,
                timeout=15,
                check=True,
            ).stdout
            for line in out.strip().splitlines():
                idx, name, util, used, total = [p.strip() for p in line.split(",")]
                gpus.append(
                    GPUState(
                        index=int(idx),
                        name=name,
                        util_pct=int(util),
                        mem_used_gb=float(used) / 1024,
                        mem_total_gb=float(total) / 1024,
                    )
                )
        except (subprocess.SubprocessError, ValueError) as exc:
            print(f"warning: nvidia-smi unreadable ({exc})", file=sys.stderr)

    ram_free_gb, cores, load1 = 0.0, 1, 0.0
    try:
        import psutil

        ram_free_gb = psutil.virtual_memory().available / 1024**3
        cores = psutil.cpu_count(logical=True) or 1
        load1 = psutil.getloadavg()[0]
    except ImportError:
        import os

        cores = os.cpu_count() or 1
        try:
            load1 = os.getloadavg()[0]
            meminfo = dict(
                (k.strip(), v) for k, v in
                (l.split(":", 1) for l in Path("/proc/meminfo").read_text().splitlines())
            )
            ram_free_gb = int(meminfo["MemAvailable"].split()[0]) / 1024**2
        except (OSError, KeyError):
            pass

    return HostState(gpus=gpus, ram_free_gb=ram_free_gb, cores=cores, load1=load1)


# --------------------------------------------------------------------------- #
# decision
# --------------------------------------------------------------------------- #
@dataclass
class Decision:
    target: str                  # 'local' or 'ibex'
    reason: str
    cuda_visible_devices: str | None = None
    partition: str | None = None
    gres: str | None = None
    time_limit: str | None = None
    notes: list[str] | None = None

    def to_json(self) -> str:
        return json.dumps(asdict(self), indent=2)


def _pick_partition(est_minutes: int, needs_gpu: bool, ram_gb: float) -> tuple[str, str]:
    """Return (partition, time_limit) for an Ibex job, with 50% headroom."""
    hours = max(1, int((est_minutes * 1.5) // 60) + 1)
    if not needs_gpu:
        part = LARGEMEM_PARTITION if ram_gb > 400 else CPU_PARTITION
    else:
        part = next(
            (p for max_h, p in PARTITION_LADDER if hours <= max_h),
            PARTITION_LADDER[-1][1],
        )
    return part, f"{hours:02d}:00:00"


def decide(
    est_minutes: int,
    needs_gpu: bool = False,
    vram_gb: float = 0.0,
    ram_gb: float = 8.0,
    n_gpus: int = 1,
    host: HostState | None = None,
) -> Decision:
    """Choose local vs Ibex for a job with the declared resource profile.

    Parameters
    ----------
    est_minutes: expected wall time.
    needs_gpu:   whether the job requires a GPU at all.
    vram_gb:     peak VRAM needed on a single device.
    ram_gb:      peak host RAM needed.
    n_gpus:      number of GPUs required.
    host:        pre-read state (for testing); read live if omitted.

    Returns a Decision carrying a human-readable ``reason`` that belongs in
    PLAN.md.
    """
    host = host or read_host_state()
    notes: list[str] = []

    # --- hard reasons to go remote ------------------------------------------
    if est_minutes > THRESHOLDS["max_local_minutes"]:
        part, tl = _pick_partition(est_minutes, needs_gpu, ram_gb)
        return Decision(
            target="ibex",
            reason=(
                f"estimated {est_minutes} min exceeds the "
                f"{THRESHOLDS['max_local_minutes']} min local limit"
            ),
            partition=part,
            gres=f"gpu:a100:{n_gpus}" if needs_gpu else None,
            time_limit=tl,
            notes=notes,
        )

    if needs_gpu and vram_gb > THRESHOLDS["borg_vram_gb"]:
        part, tl = _pick_partition(est_minutes, needs_gpu, ram_gb)
        return Decision(
            target="ibex",
            reason=(
                f"needs {vram_gb:.0f} GB VRAM; borg GPUs have "
                f"{THRESHOLDS['borg_vram_gb']} GB"
            ),
            partition=part,
            gres=f"gpu:a100:{n_gpus}",
            time_limit=tl,
            notes=notes,
        )

    if ram_gb > THRESHOLDS["borg_ram_gb"]:
        part, tl = _pick_partition(est_minutes, needs_gpu, ram_gb)
        return Decision(
            target="ibex",
            reason=f"needs {ram_gb:.0f} GB RAM; borg has {THRESHOLDS['borg_ram_gb']} GB",
            partition=part,
            time_limit=tl,
            notes=notes,
        )

    # --- local, if there is room --------------------------------------------
    if needs_gpu:
        usable = [g for g in host.free_gpus if g.free_gb >= vram_gb]
        if len(usable) < n_gpus:
            busy = ", ".join(
                f"GPU{g.index} {g.util_pct}% {g.mem_used_gb:.1f}GB used"
                for g in host.gpus
            ) or "no GPUs detected"
            part, tl = _pick_partition(est_minutes, needs_gpu, ram_gb)
            return Decision(
                target="ibex",
                reason=f"no free local GPU with {vram_gb:.0f} GB ({busy})",
                partition=part,
                gres=f"gpu:a100:{n_gpus}",
                time_limit=tl,
                notes=notes,
            )
        devices = ",".join(str(g.index) for g in usable[:n_gpus])
        reason = (
            f"fits locally: {est_minutes} min, {vram_gb:.0f} GB VRAM, "
            f"GPU {devices} idle"
        )
    else:
        devices = None
        reason = f"CPU-only, {est_minutes} min — runs locally"

    if host.ram_free_gb < max(ram_gb, THRESHOLDS["ram_headroom_gb"]):
        notes.append(
            f"only {host.ram_free_gb:.0f} GB RAM free — consider waiting or going remote"
        )
    if host.cpu_busy:
        notes.append(f"borg load is high ({host.load1:.1f} over {host.cores} cores)")

    return Decision(
        target="local",
        reason=reason,
        cuda_visible_devices=devices,
        notes=notes,
    )


# --------------------------------------------------------------------------- #
# sbatch emission
# --------------------------------------------------------------------------- #
def emit_sbatch(
    decision: Decision,
    job_name: str,
    command: str,
    env: str,
    cpus: int = 8,
    mem_gb: int = 64,
) -> str:
    """Render an sbatch script for an Ibex decision.  Does not submit."""
    if decision.target != "ibex":
        raise ValueError("emit_sbatch called on a local decision")

    gres = f"#SBATCH --gres={decision.gres}\n" if decision.gres else ""
    return f"""#!/bin/bash
#SBATCH --job-name={job_name}
#SBATCH --account={IBEX['account']}
#SBATCH --partition={decision.partition}
#SBATCH --time={decision.time_limit}
#SBATCH --cpus-per-task={cpus}
#SBATCH --mem={mem_gb}G
{gres}#SBATCH --output={IBEX['logs']}/{job_name}_%j.out
#SBATCH --error={IBEX['logs']}/{job_name}_%j.err
#SBATCH --mail-type=END,FAIL,TIME_LIMIT_90
#SBATCH --mail-user={IBEX['email']}

# Dispatch reason: {decision.reason}
set -euo pipefail
module purge
export PATH={IBEX['envs']}/{env}/bin:$PATH

{command}
"""


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #
def main() -> None:
    ap = argparse.ArgumentParser(description="Decide local vs Ibex for a job.")
    ap.add_argument("--est-minutes", type=int, required=True)
    ap.add_argument("--gpu", action="store_true", help="job needs a GPU")
    ap.add_argument("--vram", type=float, default=0.0, help="peak VRAM in GB")
    ap.add_argument("--ram", type=float, default=8.0, help="peak host RAM in GB")
    ap.add_argument("--n-gpus", type=int, default=1)
    ap.add_argument("--explain", action="store_true", help="print live host state too")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument("--emit-sbatch", action="store_true")
    ap.add_argument("--job-name", default="job")
    ap.add_argument("--command", default="python script.py")
    ap.add_argument("--env", default="retron_tradicional")
    ap.add_argument("--cpus", type=int, default=8)
    ap.add_argument("--mem-gb", type=int, default=64)
    ap.add_argument("--out", type=Path, help="write the sbatch script here")
    args = ap.parse_args()

    host = read_host_state()
    d = decide(
        est_minutes=args.est_minutes,
        needs_gpu=args.gpu,
        vram_gb=args.vram,
        ram_gb=args.ram,
        n_gpus=args.n_gpus,
        host=host,
    )

    if args.json:
        print(d.to_json())
    else:
        if args.explain:
            print("--- live host state ---")
            for g in host.gpus:
                print(
                    f"  GPU{g.index} {g.name}: {g.util_pct}% util, "
                    f"{g.mem_used_gb:.1f}/{g.mem_total_gb:.0f} GB used"
                    f"{'  [BUSY]' if g.busy else '  [free]'}"
                )
            print(
                f"  RAM free: {host.ram_free_gb:.0f} GB | "
                f"load {host.load1:.2f} over {host.cores} cores"
            )
            print("--- decision ---")
        print(f"TARGET: {d.target.upper()}")
        print(f"REASON: {d.reason}")
        if d.cuda_visible_devices is not None:
            print(f"  CUDA_VISIBLE_DEVICES={d.cuda_visible_devices}")
        if d.partition:
            print(f"  partition={d.partition} time={d.time_limit} gres={d.gres}")
        for n in d.notes or []:
            print(f"  NOTE: {n}")

    if args.emit_sbatch:
        if d.target != "ibex":
            print("\n(no sbatch emitted — job runs locally)", file=sys.stderr)
            return
        script = emit_sbatch(
            d, args.job_name, args.command, args.env, args.cpus, args.mem_gb
        )
        if args.out:
            args.out.parent.mkdir(parents=True, exist_ok=True)
            args.out.write_text(script)
            print(f"\nWrote {args.out} — review it, then: sbatch {args.out}")
        else:
            print("\n" + script)


if __name__ == "__main__":
    main()