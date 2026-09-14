# [stageN_slug] — [the answer, in one line]

_[YYYY-MM-DD] · `[env]` · [borg GPU 1 | Ibex gpu24] · [wall time]_

## Answer

**Question.** [from the launcher's *stated so it can fail* field]
**Answer.** [the answer, with the number]
**Caveat that would change it.** [the one thing a reader must know]

> If a reader stops here, they must not be misled.

## Claims ledger

| claim | value | unit / denominator | scope | circularity | falsifier | status |
|---|---|---|---|---|---|---|
| [claim] | [n] | [of what, over how many] | [what was audited] | [NONE\|LOW\|MEDIUM\|HIGH] | [what would refute it] | [SUPPORTED] |

_Full ledger: `CLAIMS.tsv`. A claim reaches the paper only from a `SUPPORTED` row with
circularity `NONE` or `LOW`._

## Findings

### [finding]

**Number.** [exact value, with unit and denominator]
**Means.** [biologically or methodologically]
**Implication.** [for the paper, or the next stage]
**Would be wrong if.** [the specific falsifier — and what you did to check it]

→ `scripts/[sNN_x.py]` · `tables/[x.tsv]` · `figures/[x.png]`

## Negative & null results

[Its own section. State them plainly. A negative is a finished result, not a failed one.
If there were none, say so explicitly — do not delete the heading.]

## What surprised me

[Mandatory. May not be empty. ⚠️ mark anything that changed how you read the rest.]

## What I could NOT check

[Mandatory. May not be empty. What this stage does not establish, and why — scale
ceilings, unaudited subsets, methods that could not cross-check each other.]

## Reproduce

```bash
bash REPRODUCE.sh --quick     # tables + figures from cache, [seconds]
bash REPRODUCE.sh --full      # from raw: [X hr], [Y] GPU-hours on [machine]
```

## Provenance

| | |
|---|---|
| Inputs | `[path]` · sha256 `[…]` |
| Env | `[env_name]` |
| Machine | [borg / Ibex partition + GPU] |
| Wall time | [X] |
| Review verdict | `[PASS]` — `review-stage/02_result_review.md` |
