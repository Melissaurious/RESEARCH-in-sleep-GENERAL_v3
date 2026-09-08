# Session prompts

`CLAUDE.md` is read automatically at the start of every session, so a prompt does not need to
repeat it. What a prompt supplies is the one thing `CLAUDE.md` cannot know: **which job this
session is doing.** Everything below is short on purpose — anything that belongs in every
session belongs in `CLAUDE.md`, not here.

Copy one block. Do not edit it to be friendlier; the terse clauses are rule ids.

---

## 1 · Run a gate  (the common case)

> Read `CLAUDE.md` and everything under "Read before acting", then the active track's
> launcher.
>
> Active gate: **`<gate-id>`**. Its approved plan is the `## <gate-id>` section of
> `ROADMAP.md`, and its scope is the launcher — those are the authority, not this message.
>
> Start in **plan mode**: recon and a plan only, no scripts, no writes. Your first action
> after I approve is `ARIS_OUTPUT/<gate-id>/PLAN.md`.
>
> Phase A — compute only. One script per task, run each immediately after writing it,
> `--limit` first. Every declared control runs **before** the full pass and is watched
> FAILING on a seeded-bad case before it is trusted (WA-A.3, EVIDENCE_STANDARDS §6). Every
> count of zero needs a positive control returning non-zero on a known-present case. Every
> rate names the population its denominator equals and ships a second, independent count of
> it (WA-D.7). No prose conclusions.
>
> Phase B — one interpretation round over all tables together. Counts, not conclusions. A
> refutation is a result and lands like any other (CL-3).
>
> Then the bundle per `general/agreements/BUNDLE_SPEC.md`. **Test `run.sh` from the assembled
> bundle, not from your scratch directory** (BS-3). `README.md` carries STATUS,
> n_attempted/n_succeeded/n_dropped, the counts that look bad (BS-5), the six adversarial
> answers (BS-14), what changed from the plan, and a paste-ready block of the proposed
> `CLAIMS.md` and `ROADMAP.md` edits for me to apply.
>
> Commit. Do not push. Do not edit `CLAIMS.md` or `ROADMAP.md` — those are mine (CL-2, WA-I.1).
>
> Blocked: append to `docs/BLOCKED.md` (WA-S.4). LOW-STAKES — take your recommended default,
> log it, continue. HIGH-STAKES — stop and leave the work in scratch.

## 2 · Open a track  (write the launcher)

> Read `CLAUDE.md`, `GOALS.md`, `CLAIMS.md`, and `general/agreements/LAUNCHER_SPEC.md`.
>
> Draft `launchers/LAUNCHER_<track>.md` from `general/templates/LAUNCHER.md`. Fill all six
> required sections. In particular:
>
> - §0.1 the write boundary, and the matching `sandbox.filesystem.allowWrite` entry
> - §3 every input graded RAW / FROZEN / RE-DERIVE / DO-NOT-USE, with FROZEN naming its bundle
> - §4 the gates, each with a mode and a stop condition, and the dependency graph showing
>   which can run in parallel
>
> Propose the gates; do not run any. Do not write to `CLAIMS.md` or `ROADMAP.md`.

## 3 · Side investigation  (not a gate)

> Read `CLAUDE.md`, then `sidework/README.md` and `sidework/<topic>/FINDINGS.md`.
>
> You are running **sidework**, not a gate. Scratch freely in `ARIS_OUTPUT/`. No bundle, no
> `INPUTS.tsv`, no `run.sh`.
>
> **Nothing you produce here is a number.** It may not be cited, plotted, or written into
> `CLAIMS.md` or `ROADMAP.md`. Its only possible promotion is to become a gate I approve.
>
> Source data stays read-only (WA-D.1). Keep `FINDINGS.md` current as you go — what you ran,
> where, what came back. Counts, not conclusions (WA-I.1). Fill in **Verdict** at the end;
> "dead end" is a real verdict and is worth keeping.

## 4 · Accept a bundle  (the morning after)

> Read `CLAUDE.md` and `general/agreements/BUNDLE_SPEC.md` (Acceptance).
>
> Bundle: `results/<gate-id>`. Do the mechanical half and report, do not decide:
> `bundle_valid.sh`, then rerun `run.sh` into a scratch dir **from the assembled bundle** and
> diff `tables/` byte for byte. Then show me `INPUTS.tsv` in full, the counts in `README.md`
> that look bad, and the six adversarial answers.
>
> Do not touch `CLAIMS.md` or `ROADMAP.md`, and do not write `OUTPUTS.tsv` until I say the
> STATUS line is final — sealing before acceptance records hashes that acceptance invalidates.

## 5 · Adversarial read  (a second opinion, no writes)

Run after two or three bundles have landed. **Run it as a separate invocation with a different
model** (BS-15, WA-V.1) — a session that reviews its own night reviews its own reasoning.

> Read `CLAIMS.md`, `general/agreements/EVIDENCE_STANDARDS.md`, and every bundle in
> `results/`. You did not write any of this. Try to break it, not to summarise it.
>
> **Job 1 — adversarially read each bundle.** For every claim a README proposes a status for:
> is the denominator named as a **population**, and does its second count agree (WA-D.7); was
> every threshold declared **before** scoring (§5); is any count of zero backed by a positive
> control that returned non-zero on a known-present case (§6); does the grade match what was
> measured, MEASURED vs DERIVED vs INFERRED (§1c); does any figure show a number no landed
> table contains; does `run.sh` reference anything not in the bundle; is every input `run.sh`
> reads listed in `INPUTS.tsv` (BS-2); does every figure have the table it plots (BS-13).
>
> **Job 2 — one paste-ready block** of status lines, ordered by claim id, each naming the
> **table** that carries its number. A claim you cannot tie to a table stays UNPROVEN and you
> say why.
>
> **Job 3 — every claim id a README proposes that is not a row in `CLAIMS.md`** (BS-12).
> Describe each in prose and propose the next genuinely free id — `git grep` it across all
> bundles first, because ids collide. Renumber nothing.
>
> **Job 4 — check the governance, not just the science.** Does `git log` show a submodule
> gitlink moved in a commit whose subject is about something else? Does every landed
> `STATUS: VERIFIED` correspond to a commit that actually touched that `README.md`?
>
> EVERY finding must name a file and a line. "The denominator looks wrong" is not actionable
> and will be discarded.
>
> Report only. **Change nothing, commit nothing** — the ledger is mine (CL-2, WA-I.1).

`bash general/tools/adversary.sh` enforces the entry gates rather than describing them, and
writes exactly one file. `--check` reports on the gates and runs nothing.

### Calibration — read this before acting on a finding

An adversarial pass once found the claim ledger was ragged. **It was right, and its
explanation was backwards** — it read the well-formed rows as the defect and named a row that
was fine. It also found four defects no check could.

**That is the characteristic failure of an adversarial reader: correct alarm, inverted
diagnosis.** Treat its findings as leads and its diagnoses as hypotheses. Verify the finding
against the file before acting on the explanation.

If two consecutive passes produce no finding that survives verification, the gates are too
loose or the loop has stopped producing the kind of defect it catches. Say so, and widen or
stop — a reader that always agrees is a cost with no signal.

---

## Autonomy: what may be decided without a round-trip

**May be decided:** sequencing, parallelism, priority, what to propose as a new gate, what a
second reader should be pointed at. All reversible, all cheap to be wrong about.

**May not be decided:** what counts as approved (CL-1, CL-2), and what a number means
(WA-I.1). Autonomy grows where being wrong is cheap and stops at the two places where it is
expensive.

A loop may DRIVE but may not ACQUIT (WA-L.2): it decides whether a step is complete, never
whether a result is correct or good enough.
