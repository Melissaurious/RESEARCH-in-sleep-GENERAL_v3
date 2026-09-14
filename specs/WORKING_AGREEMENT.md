# WORKING AGREEMENT — How Claude Should Work in These Projects
_Global behavior spec. Loaded every session. Fold recurring retro lessons back in here._

## Editing & debugging code
- **Locate, then patch.** Use `grep -n` / `rg` to find exact lines, `sed -n 'A,Bp'` to
  view a range, then make a targeted edit to just those lines.
- **Patch, don't rewrite.** Never regenerate a whole file to fix a few lines. If a
  rewrite is truly needed, say why first and get a nod.
- **Avoid `sed -i`.** In-place rewrites are error-prone and hard to verify. Prefer
  explicit, reviewable edits.
- **One script per task, ≤200 lines.** If a task needs more, split it by responsibility.
  Projects may override this in their own CLAUDE.md. Shared infrastructure under
  `tools/` is exempt (≤400). _An earlier LAUNCHERS_README said ≤500; that was wrong and
  is gone. 200 is the number._
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

## Verifying — six rules, each earned by a failure
_Promoted from `retros/2026-08-25_ncrna_representation_probes.md`. Every one of these cost
real work before it became a rule._

- ⛔ **A FILENAME IS NOT A VERIFICATION**, and `ran: False` is not a pass. A name asserting
  a property invites nothing — a document at least invites reading. **Ask what a passing
  check covers, not only whether it passed.** Four of five delivered sets once rode on a
  filename, guarded by a check that never ran and was read as fine.
- ⭐ **To verify an artefact you did not build, choose an instrument that shares NO
  derivation with it.** A re-derivation that disagrees is ambiguous between their defect
  and your bug — and your incentives resolve that ambiguity the wrong way.
- ⭐ **A defect charged to ANOTHER stage's artefact requires a control that could
  EXONERATE it, run before the claim is written.** Without one, a defect report is a
  hypothesis wearing a verdict's clothes. ⚠️ Finding defects in inherited work gets
  rewarded, and that is exactly the condition under which a false positive becomes likely.
- ⭐ **When a guard fires on a continuum, ask whether the STATISTIC is a correlate before
  touching the cut.** A relative max over 1280×L values turned out to be a correlate of
  length (r = +0.32); replacing the statistic, not moving the threshold, was the fix.
  **And a range measured on a sample is not the population's range** — 200 smoke records
  gave a band 8× too narrow.
- ⭐ **When a check fails on a subset, the first hypothesis is that it is pointed at the
  wrong input** — and the second is that a `.get()` default would have hidden it. Fourth
  instance across two trees; it is now a diagnosis, not a caution.
- ⭐ **Assert the identity, not the round number that resembles it**, and **read back what
  you just wrote.** "Reconciles to `total_nt × 1280 × 2`" was off by a 128-byte `.npy`
  header × 28,431 files. "A 57% excess" was 56.4%. Both figures were right; the
  *statements* were not. Reading back also catches a partial writer that leaves a
  syntactically valid file.
- ⛔ **The vantage point does not exempt the vantage point.** A stage positioned to audit
  others' artefacts is biased toward finding defects and least positioned to doubt its
  own. Apply every rule above to your own output first.

## Workflow
- **Four phases, two gates.** Plan → **attack the plan** → execute → **attack the result**
  → promote → retro. Pass 1 blocks execution; pass 2 blocks promotion to `results/`.
  Full protocol and verdict vocabulary: `specs/ADVERSARIAL_REVIEW.md`. Never skip a gate
  because the stage "looks simple" — simple stages are where unfalsifiable numbers hide.
- **Work dirty in `ARIS_OUTPUT/`, ship clean to `results/`.** Dead ends and scratch belong
  in the workshop and are never tidied away; the promoted copy must rerun from a fresh
  checkout. Promotion is a COPY, never a move, and never runs before pass 2 clears:
  `specs/PROMOTION_STANDARDS.md`.
- **Respect the declared compute budget.** The launcher states an estimate and a hard
  stop (default 2× ). At the stop, report — do not push through and do not silently
  re-scope. Blowing a budget is information about the plan, not an obstacle to it.
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
- **Verify before claiming done.** ⚠️ **Exit code 0 and "the file exists" are NOT enough** —
  tools exit 0 while writing 0 bytes, and a failed earlier run leaves artefacts a later run
  will happily reuse. Validate the output's **content** (bytes, parseability, expected record
  count, an asserted invariant). Full rule: `specs/EVIDENCE_STANDARDS.md` §1.
- **Do the task, then stop. Do not loop.** Write STATUS.md last, then halt.

## Context hygiene
- **`/clear` at task boundaries** (not mid-task).
- **Use `@path/to/file`** to reference files instead of pasting contents.

## Reporting
→ `specs/REPORTING_STANDARDS.md` — figures, report structure, interpretation format.

## After each session
Write `retros/YYYY-MM-DD_<STAGE_ID>.md`: what worked, what Claude misunderstood, what
surprised you, what to fix. **A session without a retro is unfinished.**

⚠️ **And a rule named in a retro but not landed in a spec does not exist.** The
2026-08-25 retro closed with six rules marked "to fold into `specs/`"; for weeks none of
them were here. Folding them in is part of the retro, not a follow-up to it — open the
PR against `$RSG` in the same session.