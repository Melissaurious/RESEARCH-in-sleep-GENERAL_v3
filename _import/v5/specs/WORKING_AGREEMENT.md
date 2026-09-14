# WORKING AGREEMENT — How Claude Should Work in These Projects
_Global behavior spec. Loaded every session. Fold recurring retro lessons back in here._

## Editing & debugging code
- **Locate, then patch.** Use `grep -n` / `rg` to find exact lines, `sed -n 'A,Bp'` to
  view a range, then make a targeted edit to just those lines.
- **Patch, don't rewrite.** Never regenerate a whole file to fix a few lines. If a
  rewrite is truly needed, say why first and get a nod.
- **Avoid `sed -i`.** In-place rewrites are error-prone and hard to verify. Prefer
  explicit, reviewable edits. Enforced structurally: `Bash(sed -i:*)` is in the
  deny list of `.claude/settings.json`.
- **One script per task, ≤200 lines.** If a task needs more, split it by responsibility.
  Projects may override this in their own CLAUDE.md.
- **No function over 50 lines.** Type hints and a docstring on every public function.
- **Run each script after writing it.** Don't hand back untested code.
- **Smoke-test expensive scripts.** Every script touching real compute must accept
  `--limit N` or `--dry-run`. Run on a tiny subset first; only then launch full.
- **Never recompute.** Expensive intermediates go to `<stage>/cache/`, keyed by a hash
  of inputs + parameters. Check cache before computing; log hit or miss. If you cannot
  reuse a cached result, say why in FINDINGS.md.
- **Never modify source data or original scripts.** Inputs are read-only.
- **Use the tools.** Expensive computations go through `@cached` from
  `tools/cache.py`. Before any job >10 min, call `tools/dispatch.py` and paste
  its reason into PLAN.md. Never hand-write sbatch headers — emit them.
- **Never approximate a reported number.** Any count, percentage, or value that
  lands in a table, figure, cache, or report is computed EXACTLY over all records —
  never estimated from a sample. If a file is too large for memory, stream it
  (record-by-record, exact, bounded memory); do not sample. Sampling is allowed only
  for a throwaway `--limit N` smoke-test, never for a reported value, and such output
  must be labelled an estimate. If an exact pass is genuinely too heavy for borg
  (>2 hr or over RAM), move it to Ibex per the compute rule — never downgrade to
  sampling to stay local.
- **Probe field semantics before building on a field.** Inspect a field's actual
  values on real records before designing any analysis, cache, or figure around it.
  Treat `input_format.md` (and any data contract) as a starting hypothesis about the
  data, not ground truth — documented schemas describe the data as *intended*, not as
  it *is*. Stage 1 found three headline errors this way: a lineage string filed under
  an `ecosystem` column, a "direction" field that was 97.7% null and not a direction,
  and a clip flag that was structurally always false. When actual values diverge from
  the contract, the values win — and the correction gets folded back into the contract.
- **Extraction passes are maximally retentive.** A pass over a corpus too expensive to
  re-read retains every field it touches, not the subset the current questions need.
  The cost of carrying a column is bytes; the cost of a missing one is a re-read.

## Workflow
- **Plan first for non-trivial work.** Short numbered plan → approval → execute.
  In LOOPED mode the approval applies to the PLAN only; once approved, run to the
  stop condition without further gates.
- **State assumptions inline** instead of stopping on every ambiguity. Ask only when a
  wrong guess would waste real work. Full protocol: master CLAUDE.md § When blocked.
- **Choose the machine deliberately.** Before any job >10 min: check `nvidia-smi` and
  current borg load, consult `compute/resources.md`, and state in PLAN.md where it will
  run and why. Anything >2 hr or needing >24 GB VRAM goes to Ibex.
- **Size from measurement, and count queue economics.** Run the smoke test on the debug
  partition and RECORD its per-sequence (or per-unit) timing. Size the real job as
  measured-rate × N, and choose partition / GPU count from that — do not guess. Requesting
  more GPUs LOWERS queue priority, so "smoke-test-then-expand" includes queue economics, not
  just correctness: the fastest wall-clock is the fewest resources that still finish in the
  window, not the most you can request.
- **Validate the HARNESS in interactive debug BEFORE you queue it.** Before submitting any job to 
a queued partition (batch, gpu, Priority), validate the harness—interpreter path, module availability, 
entrypoint existence, and critical imports—in a short (~60s) interactive session. A trivial harness bug 
(bad quote, missing module, wrong python path) costs seconds of compute but hours of queue latency.
```bash
# Step 1: Spin up an interactive debug session
srun --cpus-per-task=4 --mem=8G --time=00:20:00 --partition=debug --pty bash -i

# Step 2: Confirm interpreter, imports, and entrypoint path
<install>/bin/python -c "import absl, jax; print('ok')"
ls <run_script>
```
> **Note on modules:** `module avail` can be empty even when software is installed, and conda dependencies usually live in an `envs/<name>` environment rather than the base install. Add a one-line dependency preflight (`python -c "import x, y"`) directly into your slurm batch script as well so any unexpected failure names itself immediately. **Control-first applies to the harness, not just the science.**

- **Submit cheap high-value jobs BEFORE large arrays.** Fairshare is consumed by what you already ran,
  so a big array launched first can price a small, gating job out of the queue behind `Priority`.
  Sequence matters, not just resource count.
  **The smoke sample must be representative:** draw it across the input's size/length
  distribution (random or length-stratified), never the head of the file, and run it under the
  same device contention as the real job. A head-sampled, uncontended smoke test under-estimates
  — measured once at 11.1 s/fold vs 28.3 s/fold actual (2.5x) for exactly these two reasons.
- **Verify before claiming done.** → `specs/EVIDENCE_STANDARDS.md` §1. Exit code
  and file existence are NOT sufficient. Validate content.
- **Bounded iteration.** Every stage declares a mode in its launcher.

  SINGLE-PASS (default) — do the task, write STATUS.md, halt.

  LOOPED — iterate until a declared stop condition is met. Permitted only when
  the launcher declares a stop condition containing a number, and only for work
  that is low-stakes per master CLAUDE.md § When blocked.

  A loop may DRIVE but may not ACQUIT. It decides whether a step is complete;
  it never decides whether a result is correct or good enough. Quality verdicts
  come from the cross-model reviewer or from me.

  Every loop halts on any of: stop condition met; two consecutive rounds
  producing nothing new (log it, change direction); four such rounds (stop,
  escalate to me); any high-stakes decision per CLAUDE.md; compute estimate
  exceeded by >2x.

  STATUS.md is written at every halt, whichever the mode.

## Execution safety — one writer, and liveness is a claim

- **One writer per output directory, always.** A directory is owned by the run that created
  it. A second run gets a NEW path, never a reused one — no exception for "the old one is
  dead".
- **Liveness is a claim and carries a grade** (`EVIDENCE_STANDARDS` §1c). *"That run is
  dead"* is `INFERRED` unless you have checked **both** the process table **and** the
  directory's newest mtime, and recorded both. A job that has written nothing for ten
  minutes is not thereby dead.
- **Validate the liveness check on a live case before trusting it** (`EVIDENCE_STANDARDS`
  §6). A check that has only ever said "dead" has not been tested.
- **Never `rm` inside a directory you did not create in this session.** To discard a run,
  **rename** it. Renaming is reversible and preserves the evidence; `rm -f` on a path a live
  process holds destroys both runs and leaves no way to tell which bytes came from where.
- **Relaunching into an existing path is HIGH-STAKES** (master `CLAUDE.md` § When blocked):
  stop and ask. So is killing any process you did not start.
- **A directory two writers touched is never repaired.** Rename it `*_CONTAMINATED_<date>`,
  record what happened inside it, and re-run into a fresh path.

## Effort budget — measurement over prose

- **A stage that produces no provenanced artifact has produced no result.** It may still be
  correct and necessary; it is not evidence, and it does not count as progress.
- **Answer a problem with a measurement before answering it with a document.** Process
  accumulates because it is cheap to write and feels like progress. If a stage's markdown
  count exceeds its `.prov.json` count, say so in `STATUS.md` and say why that was right.
- **Before adding a rule, name the case it would have caught, and the case it would wrongly
  reject.** A rule shipped without the second is untested — the same defect as an unvalidated
  check, one level up.

## Publishing a completed goal

When an objective is met, extract the reproduction bundle and publish **only that**:

```bash
python3 ../RESEARCH-in-sleep-GENERAL_v5/tools/extract_reproduce.py ARIS_OUTPUT/<stage>
```

It emits `scripts/`, `MANIFEST.tsv` (artifact -> script, command, unit, denominator),
`INPUTS.tsv` (path + sha256 — **the real reproducibility pin**), `run.sh`, and a README whose
counts make defects visible. **A non-zero "no `.prov.json`" or "scripts ABSENT" count is
fixed before publishing, never footnoted.** Working notes, caches and superseded drafts stay
out.

## Context hygiene
- **`/clear` at task boundaries** (not mid-task).
- **Use `@path/to/file`** to reference files instead of pasting contents.

## Reporting
→ `specs/REPORTING_STANDARDS.md` — figures, report structure, interpretation format.

## Research record (research-wiki/)
Every project keeps a wiki. Four node types, and nothing skips a layer:

- paper    — anything read. Enters via `ingest_paper`, never freehand.
- claim    — a statement that could be false. Born UNPROVEN. Carries its scope
             (EVIDENCE_STANDARDS §7) and its circularity grade (§3) at birth.
- experiment — what was run. Links to the stage dir and its .prov.json files.
- idea     — a proposed direction, ranked, with the claims it would test.

Status rules:
- A claim becomes VERIFIED only after an audit verdict (/result-to-claim or
  /experiment-audit) AND my explicit sign-off. Never by a session's own judgment.
- A claim becomes REFUTED on the same evidence standard. Refutation is a result.
- Corrections amend in place, both values and dates, superseded version visible.
- Claims inherited from a previous session or project enter as UNPROVEN with
  provenance, regardless of how confident that session sounded.

### Inheriting artifacts from a previous project version
An artifact from a previous version (V1–V4) is not evidence in this project. It enters
only when a stage needs it, and only in one of three states:
- RE-DERIVED — recomputed here under current standards, with .prov.json. Usable.
- BLIND-CONFIRMED — independently recomputed without sight of the prior value, and
  the two agree. Usable, and stronger than re-derived.
- [UNVERIFIED] — carried forward for orientation only. May not appear in a figure,
  a table, the wiki as VERIFIED, or the paper.
Auditing a previous version wholesale is out of scope. Verification is paid per
artifact, at the point of use.

### Before a result enters the paper — the coordinator's obligation

A result that has passed every gate is still not a finding until **I can state, in my own
words and in one paragraph, why it is true.** Not the session's summary — mine. If I cannot,
it does not enter the paper, however many reviewers passed it.

This is not a quality check on the session. It is the check that the coordinator still
understands the object, and it is the one thing no automated gate can supply.

## After each session
Write `retros/YYYY-MM-DD_<stage>.md`: what worked, what Claude misunderstood, what to
fix. A session without a retro is unfinished. Promote recurring lessons into this file.