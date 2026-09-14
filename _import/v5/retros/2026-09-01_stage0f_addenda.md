# RETRO — 2026-09-01 · Stage 0f addenda (N3, HMM denominator, answer register)

Companion to `2026-08-31_stage0f.md`, which covers Phase 1. This one is about the four
coordinator questions that arrived after the halt, and what they exposed.

## The one lesson

**Every correction this session began as a negative claim whose scope I never recorded.**

- "the 1,928 reference residues are on disk nowhere" — I searched 819 FASTA files for
  reference **accessions**. The FAA that has them is keyed by `terminal_N`, a node index.
  It carried zero accessions and was invisible to my scan. The search was sound for the
  question it asked and I quoted it as an answer to a wider one.
- "117 loci where two databases disagree on domain" — I never computed a domain
  disagreement. I computed a *partition* disagreement and named it a domain one. Measured:
  117 partition-level, **0** value-level, corpus-wide.
- "all 501,561 were scored" — true, but the sentence I built on it implied the tblout
  tables held 501,561 rows. They hold 39–85 % of that, because a tool default I never
  looked at (`-E 10`) was doing the filtering.
- "9 of 29 thresholds do not separate" — read off a table by eye. It is 17.

Four different mistakes, one shape: **a claim whose evidence covers less than the claim
does, where the shortfall is invisible in the sentence.** EVIDENCE_STANDARDS §1c now
names this exactly — grade the claim, not the number; a negative is `INFERRED` unless the
search's scope is recorded and covers what the claim asserts; an unexamined tool default
is `INFERRED`. All four of mine would have been caught by writing the scope down. None
would have been caught by checking the arithmetic, which is what I was doing instead.

## What worked

**Building the answer register forced the fix.** Grading 26 answers by *how they were
known* is what turned "117 loci disagree on domain" from a confident bullet into a
measurement — I could not write `read-from-artifact` beside it, because no artifact
contained that quantity. The register was requested as documentation and functioned as an
audit. That is worth institutionalising: **grade before you report, not after.**

**Reproducing the corrections instead of accepting them.** The coordinator said the
`terminal_N` → `Node` join was verified. Reproducing it confirmed 1,926/1,926 — and found
that 21 of the 112 mismatches are not version drift but a different PATRIC genome, all
carrying a `|rescued` marker. Accepting a verified claim would have cost nothing today and
lost a real caveat for whoever runs the identity test.

**Superseding in place rather than editing.** Three deliverables now carry statements the
addenda contradict. Leaving them visible with a named superseding entry is more useful than
a clean file, because the pattern above is only legible if the wrong versions survive.

## What I would do differently

1. **Write the search key, not just the search, into every negative.** "No FASTA header in
   819 files contains a reference accession" is a fact. "The residues are nowhere" is a
   claim it does not support. One sentence apart, and I wrote the second.
2. **Read the tool's defaults into the record at invocation time**, not when someone asks.
   `-E 10` was in effect for the entire §3.6 run and appears nowhere in Round 10's
   provenance. It should have been in `params` the moment the script was written.
3. **When a claim is worth telling the coordinator twice, that is the signal to measure
   it.** I flagged the 117 loci in STATUS.md and again in the summary without ever
   computing it. Repetition felt like confirmation and was the opposite.

## What surprised me

- **`support.csv` was a decoy.** It genuinely holds 170 reference proteins, so finding it
  felt like the answer and stopped me looking. The real source has 1,926 and a different
  key. A partial hit is worse than a miss: it closes the search.
- **Two files one byte apart are the same table** — bodies byte-identical, differing only
  in `Clade`/`Retron_subsystem` vs `RT_Clade`/`Retron_subtype`. A positional read of either
  works and a named read of the wrong one raises. That is a good trap and belongs in the
  contract.
- **The reporting cut was harmless by fifty orders of magnitude** (worst E above any
  threshold 6.6 × 10⁻⁵¹ against a cut of 10). The defect was never the number; it was that
  nobody could tell from the record whether it was harmless.

## For the specs

§1c already landed and covers most of this. Two additions I would still make:

1. **`WORKING_AGREEMENT` § Editing & debugging** — *before any merge, list the column names
   both sides share and rename the collisions explicitly.* Carried over from the 08-31
   retro; the `family` rank-versus-label collision would have silently shifted every
   per-family count had it not also been a lookup key.
2. **`EVIDENCE_STANDARDS` §2** — the tool-grade table records the working invocation. It
   should also require **the defaults in force**: a `VERIFIED` grade on a run whose
   thresholds nobody looked at certifies that the tool ran, not that the numbers mean what
   they appear to. That is the same failure §1c describes, one layer down.

## State at stop

Phase 1 halted 2026-08-31 and is unchanged. Four addenda appended; 83 artifacts, all
provenanced, `check_prov` PASS. Register at 31 answers — 21 computed-now, 6
read-from-artifact, 4 inferred. **N3 = AVAILABLE.** Phase 2 unbegun.

Open for the coordinator: whether to reopen §3.6 with a direct sequence-identity test now
that 1,926 reference residues are usable, carrying the three declared caveats (2 nodes
without sequence, 21 rescued-from-another-genome, FAA inside the Phase 1 blind boundary).
