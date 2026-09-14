# Running work on Ibex from borg

borg and Ibex are separate machines. SLURM (`sinfo`, `squeue`, `sbatch`) exists
**only on Ibex**. Anything scheduler-related must run there, reached over SSH.

Key-based auth is already set up, so no password prompts.

## Interactive session (you're "on" Ibex)
```bash
ssh rioszemm@ilogin.ibex.kaust.edu.sa
# now you're on the login node — sbatch / squeue / module all work here
```
Grab an interactive compute node:
```bash
srun --account=pi-hohndor --nodes=1 --ntasks-per-node=1 \
     --cpus-per-task=8 --time=01:00:00 --pty /bin/bash
# GPU interactive:
srun --account=pi-hohndor --gres=gpu:v100:1 --cpus-per-task=4 \
     --mem=48G --time=02:00:00 --partition=gpu4 --pty /bin/bash
```

## One-off remote command (stay on borg)
```bash
ssh rioszemm@ilogin.ibex.kaust.edu.sa 'squeue -u rioszemm'
ssh rioszemm@ilogin.ibex.kaust.edu.sa 'sinfo -p gpu24 -o "%N %G %t"'
```

## Run a local script on Ibex, get output back on borg
```bash
ssh rioszemm@ilogin.ibex.kaust.edu.sa 'bash -s' < local_script.sh > result.txt
# (this is exactly what refresh_resources_remote.sh does)
```

## Submit a job living on borg
Push it over, then submit remotely:
```bash
scp my_job.slurm rioszemm@ilogin.ibex.kaust.edu.sa:/ibex/user/rioszemm/experiments/
ssh  rioszemm@ilogin.ibex.kaust.edu.sa \
     'cd /ibex/user/rioszemm/experiments && sbatch my_job.slurm'
```

## Move data
```bash
# borg → Ibex
scp -r ./data rioszemm@ilogin.ibex.kaust.edu.sa:/ibex/user/rioszemm/experiments/
# Ibex → borg (results back)
scp -r rioszemm@ilogin.ibex.kaust.edu.sa:/ibex/user/rioszemm/experiments/results/ ./ARIS_OUTPUT/
# rsync is better for large/resumable transfers:
rsync -avP ./data/ rioszemm@ilogin.ibex.kaust.edu.sa:/ibex/user/rioszemm/experiments/data/
```

## Convenience: SSH alias (optional)
Add to `~/.ssh/config` on borg so you can type `ssh ibex`:
```
Host ibex
    HostName ilogin.ibex.kaust.edu.sa
    User rioszemm
    IdentityFile ~/.ssh/your_ibex_key
    ServerAliveInterval 60
```
Then: `ssh ibex`, `scp file ibex:/path/`, etc.

## Typical loop
1. `rsync` inputs borg → Ibex
2. `ssh ibex 'cd ... && sbatch job.slurm'`
3. `ssh ibex 'squeue -u rioszemm'` to watch
4. `rsync` results Ibex → borg `ARIS_OUTPUT/` when done