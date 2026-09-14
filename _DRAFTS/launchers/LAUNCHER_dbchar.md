# LAUNCHER — dbchar

## 1. Objective and success criterion

**Objective.** Characterize the screening corpus exactly, on every unit, so that any
downstream dataset can be pulled by a traceable flag rather than by a filter — and produce
the first citable description of it: counts, redundancy, taxa overrepresentation,
per-family length distributions, and RT↔ncRNA geometry.

**Success criterion.** Four gates land as bundles that rerun and reproduce. Every reported
rate names the population its denominator equals and that population is counted a second,
independent way. A locus-level table exists carrying flags rather than having been
filtered, and a stated query pulls each of the three dataset asks from it.

## 2. Kill criteria

Abandon this track if the corpus cannot be parsed to a stable record count — if two
independent passes over the same 42 files disagree on the total, the corpus is not a
corpus and no characterization of it means anything.

Stop regardless of result at 2× the compute budget in §8 and report.

⚠️ This track is not expected to return a scientific negative: it is a census, and a census
returns what is there. The claims it settles (`C1`–`C4`) can each come back refuted, and
`REFUTED` lands like any other result.

## 3. Non-goals — out of scope

No phylogeny. No tree. No motif discovery. No structural work. No novelty assessment. No
co-evolution analysis. **No filtering of the corpus on any quality criterion** — this track
measures the population unconditionally and stratifies afterwards
(`EVIDENCE_STANDARDS` §3). Do not re-derive the RT or ncRNA calls themselves: this track
counts what the records assert, and says so.

`master_ncRNA-anchored_merged.jsonl` is **excluded** — it holds loci with an ncRNA and no RT.

## 4. Inputs

| path | what it is | trust grade |
|---|---|---|
| `RETRON-DB_V3/MELISSA_DATA/json_files_input_june/` | the corpus, 42 files | RAW |
| `RETRON-DB_V5/templates/input_format_schema_only.md` | schema description | RAW |
| `RETRON-DB_V3/MELISSA_SCRIPTS/database_analysis/utils_FOR_ALL_FILES.py` | `PipelineData` extraction helper | RAW, read-only |
| `RESEARCH-retron-db/results/` (15 bundles) | prior characterization | RE-DERIVE — 0.0% denominator coverage |
| `RETRON-DB_V3/ARIS_OUTPUT/stage1_db_analysis/` | generation-4 architecture | RE-DERIVE — reuse the shape, re-derive the numbers |
| `research-wClaude-PART1_v2` r01–r04 | stopped mid-flight | DO-NOT-USE — nothing landed |

⛔ Read-only, all of them. The schema document is a **hypothesis** about the data, not
ground truth — probe real values first (WA-D.4). The full known-wrong list is in
`idea-stage/docs/research_contract.md`; **read it before reusing any prior number.**

## 5. What might already exist

⭐ **Nearly every deliverable here has been implemented at least once.** In generation 4:
`sa1_genome_redundancy.py` and `sa2_dedup_ratio.py` are the redundancy ladder,
`sa4_orientation_qc.py` the strand check, `n2_clipping_audit.py` off-contig misannotation,
`s16_rt_ncrna_pairing.py` and `s10b_rt_ncrna_direction.py` the pairing and geometry, and
`retron_ncrna_absence.py` already asked the zero-ncRNA question.

⛔ **None of it is evidence here.** Generation 4 predates the current agreements and has no
bundle, and it predates all four corrections in the known-wrong list — pooled cross-family
rates, globs used as denominators, `system_subtypes` treated as one field, `full_lineage`
as one schema. **Reuse the architecture; re-derive every number.**

The architecture worth copying verbatim: one script per section, never a monolith ·
`helpers.py` centralising denominators and the PNG+SVG+EPS+TSV rule · `findings.py`
separating interpretation from computation · an assembler that **computes nothing** ·
streaming extraction with its `.log` kept beside the script.

## 6. Claims this task tests

| id | role in this task |
|---|---|
| C1 | primary |
| C2 | primary |
| C3 | primary |
| C4 | supporting |

Wording and status live in `<project>/idea-stage/docs/research_contract.md`.

## 7. Gates

| gate id | the ONE measurement | weight | settles | stop condition |
|---|---|---|---|---|
| dbchar-g1-census | exact record and system counts per RT family over all 42 files, on each of the three units | FULL | C1 | done when results/dbchar-g1-census/ exists and run.sh reproduces the counts from the hashed inputs |
| dbchar-g2-units | the locus→unique-RT→unique-pair ratio, per family | FULL | C1 | done when results/dbchar-g2-units/ exists and run.sh reproduces the ratios from the hashed inputs |
| dbchar-g3-ncrna | ncRNA presence rate on retron-labelled vs non-retron RT families, and the size of the zero-ncRNA class | FULL | C2, C3 | done when results/dbchar-g3-ncrna/ exists and run.sh reproduces the rates from the hashed inputs |
| dbchar-g4-geometry | RT↔ncRNA offset in bp and in CDS count, per family | FULL | C2 | done when results/dbchar-g4-geometry/ exists and run.sh reproduces the distributions from the hashed inputs |

FULL, not LIGHT: every one of these becomes a claim or a denominator that later stages
rest on. Each needs its denominator counted a second, independent way (WA-D.3) and a
positive control for every zero (`EVIDENCE_STANDARDS` §6).

⚠️ **`dbchar-g1-census` gates the other three.** Land it first; if two independent passes
disagree on the total, stop — that is the kill criterion in §2.

## 8. Compute

- Expected: borg, CPU only, streamed record-by-record. Estimated 3 hr across all four gates.
- Hard stop at 2× — report, do not push through.
- No GPU. The corpus is **mirrored on Ibex**, so a gate that outgrows local RAM moves there
  rather than sampling — **never downgrade a census to a sample to stay local** (WA-D.2).
- ⚠️ `foldseek` is **not** in `retron_tradicional` (it is in `esmologs`); InterProScan here
  ships a **stub** Pfam-A. Neither is needed by this track, but sweep before concluding
  anything is missing (WA-K.2).

## 9. Autonomy envelope

**Auto-proceed:** `true`.

| | budget |
|---|---|
| CPU-hours | 12 |
| GPU-hours | 0 |
| max single job | 2 hr |
| review rounds per gate | 3 |

**Decide alone and continue** (log in `docs/BLOCKED.md`): field-name mismatches and how
they were resolved · which files are malformed and how they were counted · the exact
predicate for "carries an RT call" · which prior script was read for its architecture ·
anything reversible inside the gate's scratch.

**Stop and wait:** any write outside the gate's scratch and `results/` · exceeding the
budget above · a total that disagrees between two independent passes · **any of the three
operator decisions in the research contract** (which key names "unique system"; metagenomic
vs isolate; what becomes the frozen reference dataset) · promoting any number to a paper claim.

---
_Rules quoted inline with their ids, per LAUNCHER_SPEC:_
**WA-A.4** measure and report counts; do not conclude — interpretation lands as `PROPOSED:`.
**WA-G.5** a null or refuting measurement is a result and lands like any other.
**WA-S.1** never guess silently and never stall; LOW-STAKES takes the default and continues.
