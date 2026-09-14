# Ibex Resource Snapshot
_Generated: 2026-07-27 11:41 on login509-02-r_

## GPU partitions (Partition | GRES | #nodes | state)
```
debug gpu:p6000:2(S:0-1) 1 idle
debug gpu:v100:2(S:0) 1 mix
gpu24 gpu:a100:4(S:0-1) 11 mix
gpu24 gpu:a100:4(S:0-1) 19 mix-
gpu24 gpu:a100:4(S:0-3) 2 mix-
gpu24 gpu:v100:4(S:0) 1 mix
gpu24 gpu:v100:8(S:0-1) 1 alloc
gpu24 gpu:v100:8(S:0-1) 3 mix-
gpu24 gpu:v100:8(S:0-1) 9 mix
gpu4 gpu:a100:4(S:0-1) 11 mix
gpu4 gpu:a100:4(S:0-1) 32 mix-
gpu4 gpu:a100:4(S:0-3) 3 mix-
gpu4 gpu:a100:4(S:1) 1 resv
gpu4 gpu:a100:8(S:0-1) 1 drain*
gpu4 gpu:a100:8(S:0-3) 3 mix-
gpu4 gpu:a100:8(S:0-3) 4 mix
gpu4 gpu:gtx_1080_ti:3(S:0-1) 2 mix
gpu4 gpu:gtx_1080_ti:4(S:0-1) 3 mix
gpu4 gpu:gtx_1080_ti:8(S:0-1) 1 alloc
gpu4 gpu:gtx_1080_ti:8(S:0-1) 3 mix
gpu4 gpu:p100:4(S:0-1) 5 mix
gpu4 gpu:p6000:2(S:0-1) 1 mix
gpu4 gpu:rtx_2080_ti:8(S:0-1) 1 idle
gpu4 gpu:rtx_2080_ti:8(S:0-1) 1 mix
gpu4 gpu:v100:3(S:0-1) 1 mix-
gpu4 gpu:v100:4(S:0-1) 1 mix-
gpu4 gpu:v100:4(S:0-1) 4 mix
gpu4 gpu:v100:4(S:0) 1 mix
gpu4 gpu:v100:8(S:0-1) 11 mix
gpu4 gpu:v100:8(S:0-1) 5 idle
gpu72 gpu:a100:4(S:0-1) 10 mix
gpu72 gpu:a100:4(S:0-1) 7 mix-
gpu72 gpu:a100:4(S:0-3) 1 mix-
gpu72 gpu:v100:8(S:0-1) 1 alloc
gpu72 gpu:v100:8(S:0-1) 3 mix-
gpu72 gpu:v100:8(S:0-1) 9 mix
gpu gpu:a100:4(S:0-1) 15 mix-
gpu gpu:a100:4(S:0-3) 1 mix-
gpu gpu:a100:4(S:1) 1 resv
gpu gpu:gtx_1080_ti:3(S:0-1) 2 mix
gpu gpu:gtx_1080_ti:4(S:0-1) 4 mix
gpu gpu:gtx_1080_ti:8(S:0-1) 1 alloc
gpu gpu:gtx_1080_ti:8(S:0-1) 3 mix
gpu gpu:p100:4(S:0-1) 5 mix
gpu gpu:p6000:2(S:0-1) 1 mix
gpu gpu:rtx_2080_ti:8(S:0-1) 1 idle
gpu gpu:rtx_2080_ti:8(S:0-1) 1 mix
gpu gpu:v100:3(S:0-1) 1 mix-
gpu gpu:v100:4(S:0-1) 1 mix-
gpu gpu:v100:4(S:0-1) 5 mix
gpu gpu:v100:4(S:0) 1 mix
gpu gpu:v100:8(S:0-1) 11 mix
gpu gpu:v100:8(S:0-1) 1 alloc
gpu gpu:v100:8(S:0-1) 3 mix-
gpu_wide24 gpu:a100:8(S:0-1) 1 drain*
gpu_wide24 gpu:a100:8(S:0-3) 2 mix
gpu_wide24 gpu:a100:8(S:0-3) 3 mix-
gpu_wide24 gpu:v100:8(S:0-1) 10 mix
gpu_wide24 gpu:v100:8(S:0-1) 5 idle
gpu_wide72 gpu:a100:8(S:0-3) 1 mix
gpu_wide72 gpu:a100:8(S:0-3) 1 mix-
gpu_wide gpu:a100:4(S:0-1) 2 mix-
gpu_wide gpu:a100:8(S:0-1) 1 drain*
gpu_wide gpu:a100:8(S:0-3) 2 mix-
gpu_wide gpu:a100:8(S:0-3) 3 mix
gpu_wide gpu:v100:8(S:0-1) 9 mix
```

## Idle GPU nodes right now
```
debug gpu:p6000:2(S:0-1) 1 idle
gpu gpu:rtx_2080_ti:8(S:0-1) 1 idle
gpu4 gpu:v100:8(S:0-1) 5 idle
gpu4 gpu:rtx_2080_ti:8(S:0-1) 1 idle
gpu_wide24 gpu:v100:8(S:0-1) 5 idle
```

## My QOS & limits
```
pi-hohndor               normal                   
```

## My running / pending jobs
```
     JOBID           NAME  PARTITION NODES CPUS MIN_MEMORY  TIME_LIMIT        TIME    STATE NODELIST(REASON)
  49441175        c60_b1b      batch     1   32       128G  3-00:00:00    18:21:17  RUNNING cn504-14
  49485726           bash        gpu     1    3        50G       40:00       29:41  RUNNING gpu202-16-l
```

## My conda envs
```
boltzgen
dep_maps
diffab
dymean
esm_ezy
esmologs
eva_env
fastani_env
ml-gpu-env
padloc2
progen3
progen3_clean
progen3-dev
retron_design
retron_engineering
retron_tradicional
rinalmo
rna_fm
rnaseq
zhmolgraph
```
