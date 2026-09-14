# [stageN_slug]

> [One line: what this stage answered. If it closed as a NEGATIVE, say so here, first.]

**Question.** [the question, stated so it can fail]
**Answer.** [the answer, with its number]
**Status.** [SUPPORTED | REFUTED | UNDECIDED] · reviewed `[YYYY-MM-DD]` · verdict `[PASS]`

## What's here

| | |
|---|---|
| `REPORT.md` | the findings — start here |
| `CLAIMS.tsv` | every claim, its number, its evidentiary standing |
| `scripts/` | what produced everything below |
| `REPRODUCE.sh` | runs `scripts/` in order |
| `tables/` | the data behind every figure |
| `figures/` | PNG + SVG + EPS |
| `PROVENANCE.md` | env, machine, commit, input checksums |
| `MANIFEST.tsv` | every promoted file + sha256 |

## Rerun it

```bash
export DATA_ROOT=[/abs/path/to/read-only/inputs]
bash REPRODUCE.sh --quick     # [seconds] — regenerates tables + figures from cache
bash REPRODUCE.sh --full      # [X hr] on [machine] — from raw inputs
```

## Inputs

| path | sha256 | what |
|---|---|---|
| `[/abs/path]` | `[…]` | [read-only source] |

## Caveats

[What this stage does NOT establish. Scale ceilings. Unaudited subsets. Copy the
"What I could NOT check" section of REPORT.md — a reader arriving here from GitHub will
not read the report first.]

---
_Promoted from `ARIS_OUTPUT/[stageN_slug]/` — the workshop copy holds the full audit
trail, including the dead ends. Do not hand-edit anything in this directory._
