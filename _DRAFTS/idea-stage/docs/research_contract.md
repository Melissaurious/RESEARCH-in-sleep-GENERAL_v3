# RESEARCH CONTRACT — retron systems

_The standing science. Revised when the science changes, not when a task changes.
The per-task document is `launchers/LAUNCHER_<track>.md`, which references claim ids._

## The question

Retrons are reverse transcriptases transcribed in one operon with their own RNA substrate —
a trait that distinguishes them from other RT families. A large-scale mining pipeline has
assembled a corpus of RT systems from eight public databases using three independent
detectors, but **nobody has counted it exactly, resolved its misannotations, or fixed what
a "unique system" means.**

Three units — locus, unique RT, unique RT–ncRNA pair — are currently used interchangeably.
In prior work the locus→unique-RT factor ranged **1.74×–7.39× by family**, so a rate quoted
on one unit is not the same number on another, and **every downstream claim in this project
currently rests on a denominator nobody can name.**

What is unknown: what this corpus contains, on which unit, and which of its apparent
structure is biology rather than sequencing depth or annotation artefact.

## Claims

Born `UNPROVEN`. A claim reaches the paper only from `SUPPORTED` with circularity `NONE`
or `LOW`. **`REFUTED` is a result, not a failure.**

| id | claim | status | settled by | circularity |
|---|---|---|---|---|
| `C1` | The three uniqueness keys (RT sequence · locus · RT–ncRNA pair) are **not interchangeable**: the ratio between them varies by RT family by more than 2× | UNPROVEN | — | — |
| `C2` | A substantial fraction of retron-RT-labelled loci carry **no detected ncRNA**, such that "retron locus" and "retron system" name different populations | UNPROVEN | — | — |
| `C3` | The retron ncRNA CM match rate is **higher on retron-labelled RT families than on non-retron RT families** — the second rate being the control for the first | UNPROVEN | — | — |
| `C4` | The three detectors **disagree materially** on retron RT annotation, and the disagreement is structured rather than random | UNPROVEN | — | — |

⚠️ Scope every claim to what was audited — *"in this corpus"*, never *"in retrons"*.
Sharper claims are expected to come **out of** stage 1, not to be pre-registered before it.

## Datasets

| name | path | trust |
|---|---|---|
| corpus (42 files: 41 RT families + `MULTI`) | `RESEARCH-in-sleep-RETRON-DB_V3/MELISSA_DATA/json_files_input_june/` | **RAW** — mirrored on Ibex |
| schema description | `RETRON-DB_V5/templates/input_format_schema_only.md` | **RAW**, and a *hypothesis* — probe values (WA-D.4) |
| extraction helper | `RETRON-DB_V3/MELISSA_SCRIPTS/database_analysis/utils_FOR_ALL_FILES.py` | **RAW**, read-only. `PipelineData` is a starting point, not a contract |
| PADLOC retron CMs (21) | `RETRONS_january_2026/.../padloc/data/cm/padlocdb.cm` | **RAW** |
| myRT HMMs (~2,051 seeds / 47 families) | `.../myRT/Models/HMM/RVT-All.hmm` | **RAW** |
| DefenseFinder retron profiles (~39) | `~/.macsyfinder/models/defense-finder-models/profiles/*Retron*` | **RAW** |
| Mestre / Toro supplementary | `RETRON_CLAUDE_PART1/supplementary_material/`, `RETRON_CLAUDE_PART1/Toro_2026/` | **RAW** |
| **15 landed bundles** | `RESEARCH-retron-db/results/` | ⚠️ **RE-DERIVE** — see below |
| generation-4 analysis (38 scripts) | `RETRON-DB_V3/ARIS_OUTPUT/stage1_db_analysis/` | **RE-DERIVE** — reuse the *architecture*, re-derive every number |
| `research-wClaude-PART1_v2` `r01`–`r04` | — | **DO-NOT-USE** — stopped mid-flight, nothing landed |

⛔ **`MELISSA_SCRIPTS/` and `MELISSA_DATA/` are read-only.** Never modified, never re-run in place.

### Why the 15 bundles are RE-DERIVE, not FROZEN

`ARIS_OUTPUT/qa/register/coverage.tsv` reports **100% known-producer and 0.0% denominator
coverage** across every bundle. They reproduce; their numbers cannot be cited, because no
table says what its rate is a rate *of*. `BS-17` now fails that condition at landing time.
**One rerun per bundle makes them citable — that is not a re-investigation.**

## Baselines

| claim | compared against | what would make BOTH wrong at once |
|---|---|---|
| `C1` | the three keys against each other | a shared extraction defect — all three derive from the same JSON parse, so a coordinate error moves all three together. ⭐ This is the pair with the *least* independence and it must be said. |
| `C2` | `has_ncrna` flag vs the `ncrnas` array | ⚠️ the schema records that `has_ncrna` can be true while `ncrnas` is empty — the two must be reconciled per record, not assumed to agree |
| `C3` | retron-labelled vs non-retron RT families | the CMs were built on retron ncRNAs, so a low non-retron rate is partly true by construction. **Circularity MEDIUM at best; price it** (`EVIDENCE_STANDARDS` §3) |
| `C4` | DefenseFinder · PADLOC · myRT pairwise | all three were run by one pipeline over one window definition; a windowing error disagrees with nothing |

## Kill criteria for the project

`[OPERATOR — the one field nothing in RETRON_STAGES contains. What result would make you
abandon this line entirely, as opposed to abandoning one stage?]`

## Operator decisions outstanding

From `01_database_characterization.md` §5 and §6 — scientific calls, not agent calls:

1. **Which uniqueness key carries the phrase "unique system" in the paper.** All three get
   measured; one gets the name.
2. **Metagenomic versus isolate records — together or separately?** Currently undeclared,
   and it moves every diversity and saturation number downstream.
3. **What becomes the frozen reference dataset.** Recommendation on record: freeze the
   locus-level table *with flags*, and freeze views by declared query rather than by
   copying rows, so a downstream stage cites a view definition plus a table hash.

## Known-wrong — read before reusing anything

⚠️ Absence is loud; wrongness is quiet. From `01_database_characterization.md` §4, each
already paid for once:

- ⛔ **Coordinates are contig-based.** `intergenic_regions[].start/end` and `rt_gene.start/end`
  are contig coordinates; `genomic_context.full_sequence` is a window. **1 in 6 records has
  `start == 1`**, where both frames coincide and every arithmetic check passes. Generalising
  from one such record once excluded **97.2%** of regions. Verify by **RT back-translation**.
- ⛔ **"Complete" means ORF-complete.** **69.2%** of previously-admitted proteins do not fill
  the RT window; three live "complete" rules reach the same ~70% on sets agreeing at only
  **Jaccard 0.728**. Equal rates are not equal sets.
- ⛔ **Never glob a cache directory that also holds an aggregate file.** One such glob swept a
  merged table into a "non-retron" denominator: n = 924,847 against a real 423,274, and
  99.65% of the "non-retron" hits were retrons.
- ⚠️ **`full_lineage` is two schemas** keyed by `taxonomy_system` — gtdb 7-field, ncbi 3-field
  with no phylum. Count per system, never pooled.
- ⚠️ **`system_subtypes` is two tools on one locus** (capital-initial = DefenseFinder,
  lowercase = PADLOC), agreeing on **44.6%**. Carry it; never `groupby` it.
- ⚠️ **Pooling hides the distribution.** `PQG[GA]` read **41.78% pooled vs 0.373%
  median-family** — a 112× gap.
- ⚠️ **`rt_hash` is not a sequence hash** and no `rt_hash → locus` link exists. Compute `sha256`.
- ⚠️ **`VOID_DO_NOT_CITE.md` has not been consulted.** `00_INDEX` says to check it before
  quoting any figure. Locate it before any prior number is cited.

## Key decisions

| date | decision | why | supersedes |
|---|---|---|---|
| 2026-09-14 | The 15 `RESEARCH-retron-db` bundles are `RE-DERIVE`, not `FROZEN` | `coverage.tsv`: 0.0% denominator coverage. Reproducible, not citable. | — |
| 2026-09-14 | `research-wClaude-PART1_v2` is `DO-NOT-USE` | stopped mid-flight; nothing landed | — |
