# How to run a stage (plan → approve → execute → retro)

Reusable flow for every stage. Copy the prompts below; swap the launcher filename.

## Setup (once per session)
```bash
cd ~/RESEARCH-in-sleep-RETRON-DB_V5
conda activate retron_tradicional
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000
claude
```

## Phase 1 — PLAN (approval gate; nothing heavy runs yet)
Paste as the first message (swap the launcher name per stage):

> Read @launchers/LAUNCHER_stage1_db_analysis.md and follow it. Also read @CLAUDE.md,
> @NARRATIVE_REPORT.md, @RESEARCH_BRIEF.md, @templates/input_format.md, @templates/paths.md,
> and @MELISSA_SCRIPTS/database_analysis/NOTES.md.
>
> Do Step 1 (recon) — actual counts, sizes, field completeness — then STOP at Step 2:
> propose the report's section structure and 2–4 additional analyses you'd recommend, each
> with a one-sentence justification and the files/fields it needs. Do NOT write or run any
> analysis scripts yet. Do NOT proceed past the plan. Wait for my approval.

→ You review the returned plan here. Cut, add, or correct. This is your checkpoint.

## Phase 2 — EXECUTE (after you approve)
> Approved with these changes: [ … or "none" … ]. Proceed: Step 3 compute all sections
> (Phase A — numbers + cached tables + figures with their TSVs), Step 4 interpretation
> (Phase B — three-sentence findings over all cached tables), Step 5 assemble REPORT.html
> (established style) + REPORT.md. One script per section (≤200 lines), run each after
> writing. Locate-then-patch when reusing old code. Write STATUS.md last, then stop.

## Phase 3 — RETRO (after it stops)
Write `../RESEARCH-in-sleep-GENERAL_v5/retros/YYYY-MM-DD.md`:
- Respected file-safety (no edits to MELISSA_SCRIPTS/DATA/supporting_material)?
- Patched vs. rewrote? Streamed big files vs. loaded them? Cached intermediates?
- Real numbers in interpretation? Stopped cleanly at Step 5?
- Anything to fold into GENERAL_v5/specs/WORKING_AGREEMENT.md or REPORTING_STANDARDS.md.

## Between unrelated stages
`/clear` before starting a different stage so stale context doesn't leak.

## Local vs Ibex
- Stage 1 (JSONL stats) → LOCAL on borg. No SLURM. Big files are streamed, not loaded.
- GPU stages (ESMFold, embeddings) → Ibex; size jobs from
  ARIS_OUTPUT/stage1_db_analysis/tables/resource_estimates.tsv, refine with `seff`.