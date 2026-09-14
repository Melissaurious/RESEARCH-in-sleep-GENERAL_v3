# Compute Resources

## Local Machine (borg)
- **GPUs:** 2× NVIDIA RTX 4090 (24 GB VRAM each)
- **Driver:** 535.309.01, CUDA 12.2
- **CPU:** 48 cores
- **RAM:** 252 GB (typically ~238 GB available)
- **Conda envs:** `/home/borg/miniconda3/envs/` (project-specific — see Active Projects below)
- **GPU selection:** `CUDA_VISIBLE_DEVICES=0` or `CUDA_VISIBLE_DEVICES=1`
- **Background jobs:** `screen -dmS jobname bash -c '...'` / monitor with `screen -ls`
- **Outputs:** always write to `ARIS_OUTPUT/` subdirectories

---

## Ibex HPC (KAUST)
- **SSH:** `ssh rioszemm@ilogin.ibex.kaust.edu.sa`
- **Scheduler:** SLURM
- **Account:** `--account=pi-hohndor` (required on every job)
- **Email:** `--mail-type=END,FAIL,TIME_LIMIT_90 --mail-user=rioszemm@kaust.edu.sa`
- **Conda envs:** `/ibex/user/rioszemm/conda-environments/` (project-specific — see Active Projects below)
- **Experiments base:** `/ibex/user/rioszemm/experiments/`
- **Logs base:** `/ibex/user/rioszemm/experiments/logs/` (create per-project before submitting)
- **Results to borg:** `scp rioszemm@ilogin.ibex.kaust.edu.sa:/ibex/user/rioszemm/experiments/results/ ./ARIS_OUTPUT/`

### GPU Partitions

| Partition    | Max time | Key GPU types          | Best for                    |
|--------------|----------|------------------------|-----------------------------|
| `debug`      | 2 hr     | v100, p6000            | Testing/debugging only      |
| `gpu4`       | 4 hr     | a100 ×4/×8, v100, p100 | Quick tests, short jobs     |
| `gpu24`      | 24 hr    | a100 ×4, v100 ×8       | Most experiment runs        |
| `gpu72`      | 3 days   | a100 ×4, v100 ×8       | Multi-day jobs              |
| `gpu`        | 14 days  | a100, v100, h200, p100 | Long runs                   |
| `gpu_wide`   | 14 days  | a100 ×8, v100 ×8       | Multi-node / multi-GPU      |
| `gpu_wide24` | 24 hr    | a100 ×8, v100 ×8       | Short multi-GPU             |
| `gpu_wide72` | 3 days   | a100 ×8                | Mid-length multi-GPU        |
| `largemem`   | 14 days  | CPU only (up to 16 TB) | Large memory CPU jobs       |
| `batch`      | 14 days  | CPU only               | General CPU jobs            |

### Notable GPU Counts on Ibex
- **A100 nodes:** ~50+ nodes (4-GPU) + ~8 nodes (8-GPU)
- **V100 nodes:** ~15 nodes (8-GPU), ~6 nodes (4-GPU)
- **H200:** 1 node with 8× H200 (partition `gpu`, feature `gpu_h200`)
- **Older:** GTX 1080 Ti, P100, P6000, RTX 2080 Ti (limited)

### Recommended Allocations
- **ESMFold / heavy GPU:** `--partition=gpu24 --gres=gpu:a100:1`
- **Quick tests:** `--partition=gpu4 --gres=gpu:v100:1`
- **Interactive:** `srun --nodes=1 --ntasks-per-node=1 --cpus-per-task=8 --time=01:00:00 --pty /bin/bash`

### Modules
```bash
module purge   # always purge first
# Compilers: gcc/12.2.0, gcc/15.2.0
# CUDA: check with `module avail cuda`
# Also available: mmseqs2/14.7e284, esm/1.0.3
# Discover: `module avail <keyword>`
```

### QOS
- **QOS:** `normal` — max 1300 concurrent jobs, no per-user CPU/GPU/time restrictions

---

## Active Projects

<!-- Update this table as projects start/stop. It's the single source of truth for what's running where. -->

| Project | Machine | GPU(s) | Conda env | Project root | Ibex partition | Status |
|---------|---------|--------|-----------|--------------|----------------|--------|
| RETRON-DB | borg GPU 0 | RTX 4090 | `retron_tradicional` | `/home/borg/RESEARCH-in-sleep-RETRON-DB/` | `gpu24` / a100 | active |
| *(template)* | borg GPU 1 | RTX 4090 | `env_name` | `/home/borg/PROJECT/` | — | — |

### Resource Allocation — borg (local)

| GPU | Device | Currently assigned to |
|-----|--------|----------------------|
| 0   | RTX 4090 (24 GB) | RETRON-DB |
| 1   | RTX 4090 (24 GB) | *free* |

### Resource Allocation — Ibex

Ibex is shared/queued so there's no static assignment — but plan jobs by estimating:

| Project | GPU type × count | Partition | Est. runtime | Est. jobs |
|---------|-----------------|-----------|-------------|-----------|
| RETRON-DB | a100 ×1 | gpu24 | ~6 hr | 5–10 |
| *(template)* | — | — | — | — |

### Quick Commands — Check What's Running
```bash
# Borg: which GPUs are busy
nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used --format=csv
# Borg: what's in each screen session
screen -ls

# Ibex: your running/pending jobs
squeue -u rioszemm -o "%.8i %.12j %.10P %.6D %.4C %.10m %.12M %.8T %.20R"
# Ibex: GPU usage summary
squeue -u rioszemm -o "%i %j %P %b %T" | grep -i gpu
```

---
