# How to run a stage — Melissa's side

_The five things you actually do. Everything else is inherited by the agent from
`$RSG/specs/`. Project-agnostic: nothing here names a project or an env._

---

## 0. Write the launcher (the only part that takes thought)

```bash
cp "$RSG/specs/LAUNCHER_TEMPLATE.md" "$PROJ/launchers/LAUNCHER_<STAGE_ID>.md"
# fill Part A — every field
python "$RSG/tools/check_launcher.py" "$PROJ/launchers/LAUNCHER_<STAGE_ID>.md"
```

The checker exits non-zero on any unfilled placeholder, missing section, or malformed
`STAGE_ID`. **Do not start a session on a launcher that does not pass** — every minute
spent here is repaid several times, and the two fields that repay most are
*the question stated so it can fail* and *what might already exist*.

## 1. Session setup

```bash
export RSG="$HOME/RESEARCH-in-sleep-GENERAL_v3"
[ -f "$RSG/specs/ANCHORS.md" ] || { echo "RSG is wrong: $RSG"; return 1; }
cd "$PROJ" && conda activate "$ENV"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=100000
claude --dangerously-skip-permissions
```

## 2. Phase 1–2 — PLAN, then ATTACK THE PLAN

Paste as the first message:

> Read `@launchers/LAUNCHER_<STAGE_ID>.md` and follow it, including everything it tells
> you to read first.
>
> Do recon only — actual counts, sizes, field completeness, and **what already exists on
> disk that this stage would rebuild**. Probe real field values; do not trust a schema
> doc. Then write `ARIS_OUTPUT/<STAGE_ID>/PLAN.md` and run
> `python "$RSG/tools/adversary.py" --stage <STAGE_ID> --pass plan`.
>
> Disposition every `BLOCKER` and `CONCERN` in `review-stage/03_dispositions.md` —
> `REFUTED` needs a command and its output, never an argument. Then **STOP**.
> Do not write or run analysis scripts. Do not proceed past the plan.

→ **Your checkpoint.** You read `PLAN.md`, `01_plan_review.md` and `03_dispositions.md`
together. Cut, add, correct. Only you can grant `ACCEPTED_RISK` — and only in writing.

## 3. Phase 3–4 — EXECUTE, then ATTACK THE RESULT

> Approved with these changes: `[… or "none" …]`. Proceed:
>
> Phase A — compute all sections: numbers, cached tables, figures with their TSVs. No
> prose conclusions yet.
> Phase B — one interpretation round over all cached tables together; three-sentence
> findings, real numbers, negatives stated plainly.
> Then assemble `REPORT.md` + `REPORT.html` (established style), write `STATUS.md`, and
> run `python "$RSG/tools/adversary.py" --stage <STAGE_ID> --pass result`.
>
> Disposition every finding. If the verdict is `FAIL`, fix and re-review — do not
> promote. Then stop.

## 4. Phase 5 — PROMOTE

```bash
python "$RSG/tools/promote_stage.py" --stage <STAGE_ID> --rerun
```

Copies the clean, documented, re-executed version into `results/<STAGE_ID>/` and refuses
if pass 2 did not clear. The workshop copy stays intact.

⛔ **Still no `git commit`.** `results/` is committed by hand, by you, at the end.
This step only keeps it permanently *ready* to be.

## 5. Phase 6 — RETRO

> Write `$RSG/retros/$(date +%F)_<STAGE_ID>.md`: what worked · what you misunderstood ·
> what surprised you · what you would do differently · which rules to fold into
> `$RSG/specs/`. Then open a PR against `$RSG` applying them. A rule named in a retro and
> not landed in a spec does not exist.

⚠️ The last clause is earned. `retros/2026-08-25` ends with six rules marked "to fold into
`specs/`" — and for weeks, none of them were in `WORKING_AGREEMENT.md`. **Naming a lesson
is not learning it.**

---

## Between stages

`/clear` at task boundaries, never mid-task. Use `@path/to/file` instead of pasting.

## Where things run

Decided by measurement, not by habit — `python "$RSG/tools/dispatch.py" --explain` and
paste its reason into `PLAN.md`. Rough shape: streaming stats and CPU work stay local on
borg; >2 hr or >24 GB VRAM goes to Ibex; **submit cheap gating jobs before large arrays**,
because fairshare spent on a big array prices the small job out of the queue behind it.
