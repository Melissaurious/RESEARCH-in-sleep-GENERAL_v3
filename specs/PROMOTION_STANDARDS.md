# PROMOTION STANDARDS — the workshop and the shipped record

_Read before closing any stage. Companion to `ADVERSARIAL_REVIEW.md` (what clears a
promotion) and `EVIDENCE_STANDARDS.md` (whether the numbers mean anything)._

Two directories, two different jobs. Confusing them is what makes a repo either
unreproducible or unusable.

| | `ARIS_OUTPUT/<STAGE_ID>/` | `results/<STAGE_ID>/` |
|---|---|---|
| **Is** | the workshop | the shipped record |
| **Contains** | everything — scratch, dead ends, 12 versions of a plot, caches, logs | the clean, documented thing that reproduces the finding |
| **Standard** | working fast is the point | a stranger can rerun it from a fresh checkout |
| **Git** | ⛔ gitignored, never committed | ✅ committed — **by hand, by Melissa, at the end** |
| **Written by** | the agent, freely | `tools/promote_stage.py` only |
| **Mutability** | append, churn, delete freely | append-only; supersede in place, never silently rewrite |

---

## 1. Work dirty. That is the instruction, not a concession.

Inside `ARIS_OUTPUT/<STAGE_ID>/` you are **expected** to leave failed attempts, throwaway
probes, half-finished plots and exploratory notebooks. Do not tidy as you go and do not
pre-optimise for presentation. **The mess is the audit trail** — it is how a wrong number
gets traced back to the moment it was introduced.

Nothing is ever deleted from `ARIS_OUTPUT/` to make a stage look cleaner.

## 2. Promotion is a COPY, never a MOVE. One direction, always.

`ARIS_OUTPUT/` → `results/`. Never the reverse.

- The workshop copy **stays intact** after promotion. It is the evidence that the clean
  version is faithful.
- ⛔ **Never edit `ARIS_OUTPUT/` to match `results/`.** If the clean script diverges from
  what actually ran, the clean script is wrong — fix it, rerun it, re-promote.
- ⛔ **Never hand-edit inside `results/`.** Edit the workshop, then re-promote. A file in
  `results/` that no `ARIS_OUTPUT/` file produced has no provenance, and that is the whole
  point of the directory.

## 3. Same subfolder name on both sides

`ARIS_OUTPUT/stage3_rinalmo_embeddings/` → `results/stage3_rinalmo_embeddings/`.
The `STAGE_ID` contract is in `ANCHORS.md` §3. One outdir per stage — never a second
top-level output directory, never a stage split across two.

## 4. What a promoted stage contains

```
results/<STAGE_ID>/
  README.md          the question, the answer, and the exact command to rerun
  PROVENANCE.md      env, commit, machine, wall time, input checksums, review verdict
  MANIFEST.tsv       every promoted file: path, bytes, sha256
  scripts/           clean documented scripts that reproduce everything below
  REPRODUCE.sh       runs scripts/ in order, from a fresh checkout, top to bottom
  figures/           PNG + SVG + EPS
  tables/            the TSV behind every single figure
  REPORT.md          findings, per REPORTING_STANDARDS.md
  REPORT.html        self-contained
```

**Excluded, always:** `cache/`, logs, SLURM stdout, raw or intermediate data, dead ends,
anything in the workshop that no promoted script reads or writes.

## 5. A promoted script is graded by EXECUTION, not by inspection

`EVIDENCE_STANDARDS.md` §1 — *validate the artefact, never its existence* — applies to
code. A script that was copied but never rerun is an unvalidated artefact.

**A promoted script must:**
- run **from a fresh checkout** of `results/`, not from inside `ARIS_OUTPUT/`
- take every path from `REPRODUCE.sh` or a declared config block — **no path that only
  resolves because of where the file happened to sit**
- carry a provenance header: what it produces, exact working invocation, env, measured
  runtime, input paths + sha256
- contain no credentials, no `/home/<user>/` absolutes outside declared anchors, no
  commented-out debris

`tools/promote_stage.py --rerun` executes `REPRODUCE.sh` and refuses to promote if it
fails. Waiving the rerun (`--rerun-waived "<reason>"`) is allowed for jobs too expensive
to repeat — the reason is **recorded in PROVENANCE.md and flagged in MANIFEST.tsv**, so an
unverified stage is visibly unverified rather than quietly so.

## 6. Negative results promote. Non-negotiable.

A stage that closed as a **negative**, a null, or a refutation is promoted with the same
care as a positive one, and `README.md` states the negative in its first paragraph.

`REPORTING_STANDARDS.md` already forbids quietly dropping a failed analysis. Promotion is
where that rule is actually tested: a `results/` tree containing only wins is a
publication-bias machine you built for yourself. The 2026-08-25 retro closed **B4 as a
negative** — RNAfold beating the RiNALMo dependency map by 0.25–0.27 AUROC is exactly the
kind of result that must survive into the record.

## 7. Promote at stage close, not at project close

`results/` is **continuously commit-ready**. Promote when a stage clears its second
adversarial pass — not in a scramble the week before submission, when nobody remembers
which of the four `plot_v3_FINAL.py` files made the figure.

Committing is still **manual and yours**, at the end. This rule is about the folder always
being *ready* to commit, not about committing early.

## 8. Size guard

Default refusal: **any single file > 5 MB**, or **any stage > 50 MB**.

GitHub is not a data store, and `results/` must stay clonable. Override with
`--allow-large` when a figure genuinely needs it; anything excluded is recorded in
`LARGE_ARTIFACTS.tsv` as `path · bytes · sha256 · where it actually lives` so the record
stays complete even when the bytes do not travel.

## 9. Gate

Nothing enters `results/` that has not cleared **pass 2** of `ADVERSARIAL_REVIEW.md`.
`tools/promote_stage.py` reads the verdict file and refuses otherwise. This is the point
where the review loop stops being advice and starts being a gate.

## 10. Checklist before promoting

- [ ] pass-2 verdict is `PASS` or `PASS_WITH_CONCERNS`, every `BLOCKER` disposed
- [ ] `REPRODUCE.sh` ran clean from a fresh checkout (or waiver recorded with a reason)
- [ ] every figure has its TSV, in `tables/`, same basename
- [ ] every reported number traced to a promoted script — none hand-copied
- [ ] negative and surprising results stated in `README.md`, not buried
- [ ] `PROVENANCE.md` complete: env, commit, machine, wall time, input checksums
- [ ] no secrets, no undeclared absolute paths, no `cache/`, no raw data
- [ ] size caps respected, or `LARGE_ARTIFACTS.tsv` written
- [ ] workshop copy left **intact**
