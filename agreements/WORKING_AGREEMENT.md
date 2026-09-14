# WORKING AGREEMENT — v7

The behaviour spec for every project governed by this layer. **Self-contained:** nothing here
requires reading an earlier version, an earlier project tree, or any folder outside the
project being worked on. Prior trees are named once in `LINEAGE.md`.

    WA-x.y  [ALWAYS | WHEN <situation>]  <statement>
      check:     <script in checks/, or "manual">
      validated: <the real case it caught, dated>

**Budget: at most 18 ALWAYS rules.** They are paid on every turn of every session. Adding one
requires deleting one. *Currently 18 — the budget is FULL.*

> **Every rule here was kept because it caught something real.** v6 carried 61 rules, 18 of
> them never validated against a case; those are gone. A rule that sounds prudent and has
> never fired is process cost, and process cost is what produced 75 stage directories and
> zero landed results.

---

## A — Autonomy: who holds the gate

_This section is why v7 exists. v6 required the operator at four points inside every single
measurement, in a system whose purpose is unattended work. Nothing finished._

**WA-A.1** [ALWAYS] **The reviewer holds the gate, not the operator.** An independent model
(`site/TOOLING.md`) reviews the plan before execution and the result before landing, and its
verdict gates. The operator is never in the critical path of a measurement.
- check: `tools/review.sh` — writes a machine-readable verdict; a missing review is not a pass
- validated: 2026-09-14 — twelve projects, 75 stage directories, 15 launchers, 19 retros and
  **zero landed results**. Every operator checkpoint was individually defensible; together
  they meant nothing could complete unattended.

**WA-A.2** [ALWAYS] **A loop may DRIVE but may not ACQUIT.** Iteration decides whether a step
is *complete*. It never decides whether a result is *correct or good enough* — that verdict
comes from the reviewer or the operator, never from the agent doing the work.
- check: `manual` — the agent never writes its own verdict line
- validated: 2026-08 (carried from v5) — a session reviewing its own night found four real
  defects and got the fifth backwards, naming 22 well-formed rows as the defect and 20
  broken ones as fine

**WA-A.3** [ALWAYS] **Iteration is bounded and the halt reason is named.** Every autonomous
loop halts on: the stop condition met, two consecutive rounds with no change to the measured
quantity, or the round budget exhausted (default 3). A budget-halt and a
condition-halt are different outcomes and are never reported as the same one.
- check: `tools/review.sh` records the round number and halt reason
- validated: 2026-09-14 — without a budget, a FAIL verdict the agent cannot satisfy becomes
  an unbounded retry loop overnight

**WA-A.4** [ALWAYS] **The agent measures and reports; it does not conclude.** Counts, including
the ugly ones. An interpretation lands as `PROPOSED:` in the bundle README and becomes the
operator's, asynchronously, by reading it. It never blocks the gate.
- check: `manual` — no bundle README asserts what a result *means* without the `PROPOSED:` prefix
- validated: 2026-09-14 — the previous form of this rule ("interpretation is the operator's
  call, always") was correct about authorship and wrong about timing, and it blocked

**WA-A.5** [ALWAYS] **The reviewer is a different model family from the author**, and runs
read-only. A reviewer sharing the author's priors agrees with them, which is
`EVIDENCE_STANDARDS` §4 applied to the review itself: two methods agreeing is evidence only
if they can disagree.
- check: `tools/review.sh` refuses when reviewer and author are the same family
- validated: 2026-09-14 — the previous adversary defaulted to the author's own model family
  and conceded in its own comments that the constraint was unenforceable

---

## L — The launcher: the only thing the operator writes

**WA-L.1** [ALWAYS] Every track has a launcher, written before it starts, and it is **the only
document the operator writes.** Objective, kill criteria, non-goals, inputs with trust grades,
claims, gates and stop conditions all live in it. There is no separate roadmap or claim
ledger — a cross-track view is GENERATED (`tools/index.sh`) and never hand-edited.
A session's reading of what the work "obviously" needs does not override it.
- check: `tools/check_launcher.py`
- validated: 2026-08 — an unlaunched stage line accumulated 43 output directories, 37 with a
  FINDINGS.md and only 12 with a PLAN.md: a tree recording what happened rather than what was
  intended

**WA-L.2** [ALWAYS] **A launcher must be complete enough to run unattended.** Every required
section filled, no placeholders. If a field is missing the gate does not start — the agent
does not infer it, and does not wake the operator to ask.
- check: `tools/check_launcher.py` — exits non-zero on any unfilled field
- validated: 2026-09-14 — the operator is the one resource that cannot be scheduled; every
  question asked mid-gate costs a night

**WA-L.3** [WHEN a track declares its inputs] Every input carries a trust grade: **RAW**
(primary, unprocessed) · **FROZEN** (settled here; names the bundle that settled it) ·
**RE-DERIVE** (a value exists, not recomputed under current standards) · **DO-NOT-USE** (known
defective; the launcher says why). An ungraded input is DO-NOT-USE.
- check: `tools/check_launcher.py` — a grade in every input row
- validated: 2026-08 — a verification track was commissioned because two load-bearing numbers
  had never been re-derived and nothing recorded which ones

---

## G — The gate: the unit of a number

**WA-G.1** [ALWAYS] A **gate** names exactly one measurement and emits exactly one bundle.
"Explore X" is a note, not a gate.
- check: `manual` — reading the launcher
- validated: 2026-09-04 — nine stages ran with no stop condition and produced zero bundles

**WA-G.2** [ALWAYS] A gate's stop condition is written before it starts: *done when
`results/<GATE>/` exists and re-running `run.sh` from the hashed inputs reproduces the number.*
A stop condition rewritten after seeing a result is a new gate, and the retro says so.
- check: `tools/check_launcher.py`
- validated: 2026-09-04 — as WA-G.1

**WA-G.3** [ALWAYS] A gate must fit in one session before the first compaction. If it does
not, it is two gates. Quality falls after compaction — the model then works from a summary of
a summary.
- check: `manual` — compacted twice means stop and re-scope
- validated: 2026-09-14 — carried from v6; the 45-directory tree is what unbounded gates look like

**WA-G.4** [ALWAYS] A gate that produces no provenanced artifact has produced no result. It
may be correct and necessary; it is not evidence and is not progress.
- check: `checks/bundle_valid.sh`
- validated: 2026-09-04 — 141 documents and nine stages, zero bundles

**WA-G.5** [WHEN a measurement comes back null or refuting] **A null or refuting measurement is a result and lands like any other.**
*Verified* means reproducible, not welcome. What is withheld is broken intermediate work,
never an unwelcome finding.
- check: `manual`
- validated: 2026-09-04 — *would wrongly reject, without this rule:* exactly the negatives
  `EVIDENCE_STANDARDS` §6 requires

---

## D — Data and measurement

**WA-D.1** [ALWAYS] Never modify source data or original scripts. Read-only, enforced by file
mode (`chmod a-w`), not by intention.
- check: `manual` — `find <data> -writable` returns nothing; `Bash(chmod:*)` denied in settings
- validated: 2026-09-04 — this was prose for months and was violated; it is now a file mode

**WA-D.2** [ALWAYS] **A census is exact; an estimate declares itself.** Any count, percentage,
total or rate landing in a table, figure or report is computed EXACTLY over all records, never
extrapolated from a sample; stream it if it exceeds memory, move it to the cluster if it
exceeds the machine — never downgrade a census to a sample to stay local. A *statistical*
quantity (CI, cross-validated score, permutation null) is not an approximation of a census, is
fully permitted, and declares its estimator, its n and its interval.
- check: `manual` — every reported number is labelled census or estimate
- validated: 2026-09-04

**WA-D.3** [ALWAYS] Every rate names the **population its denominator equals**, counted a
second time by an independent path. Two counts that disagree are a finding, not a rounding
error.
- check: `checks/bundle_valid.sh` — `unit` and `denominator` are required MANIFEST columns
- validated: 2026-09-04

**WA-D.4** [WHEN building an analysis on a field] **Probe real field values before building on a field.** A schema document
describes data as intended, not as it is. Where they diverge, the values win and the document
is corrected.
- check: `manual` — the plan shows actual values, not a schema quote
- validated: 2026-08 — a lineage string filed under an `ecosystem` column, a "direction" field
  97.7% null and not a direction, and a clip flag structurally always false

---

## B — The bundle

**WA-B.1** [ALWAYS] Numbers go to `results/<GATE>/` and nowhere else. All scratch goes to
`ARIS_OUTPUT/<gate>/` — gitignored, disposable, **allowed and expected to be messy.**
- check: `checks/bundle_valid.sh`
- validated: 2026-09-04

**WA-B.2** [ALWAYS] A gate is done when `run.sh` **reruns and reproduces the number** — not
when a document is written. The validator passing is not verification: it checks that files
exist and hashes match; only a rerun re-derives.
- check: `checks/bundle_valid.sh` + the rerun
- validated: 2026-09-04

**WA-B.3** [WHEN declaring a gate's weight] A gate is **LIGHT** or **FULL**, declared in the launcher. *LIGHT* — the
provenance skeleton only: inputs hashed, environment locked, scripts verbatim, `run.sh`
reproduces. No bespoke control fixture, no seeded positive control, no independent second
count. **A LIGHT number may not enter a claim, a figure, or the paper.** *FULL* — everything,
required the moment a number becomes a claim. Reproducibility is not negotiable at either
weight; only the control burden moves.
- check: `manual` — a weight in every gate row, and no LIGHT bundle cited by a claim
- validated: 2026-09-09 — a project applied census-grade control machinery to recon questions
  and spent days per measurement, *which the operator experienced as the method being slow
  rather than as a weight being mis-set*

---

## K — Compute

**WA-K.1** [ALWAYS] **Choose the machine by measurement, not habit.** A job goes to the
cluster when expected wall-clock > 2 hr, or it needs > 24 GB VRAM, or an exact pass does not
fit in local RAM. Thresholds: `site/COMPUTE.md`. Size from a **measured** smoke test on a
representative slice — never the head of a file, never uncontended — and validate the harness
interactively before queueing it.
- check: `tools/dispatch.py --explain`, pasted into PLAN.md
- validated: 2026-08 — a head-sampled, uncontended smoke test measured 11.1 s/fold against
  28.3 s/fold actual, a 2.5× under-estimate

---

## S — Session

**WA-S.1** [ALWAYS] **Never guess silently and never stall.** Append to `docs/BLOCKED.md`:
what is needed, why, the options, the recommended default. **LOW-STAKES** — reversible,
contained, no compute >10 min, nothing outside the gate's scratch: take the default, log it,
**continue**. **HIGH-STAKES** — deleting or overwriting anything, large compute, changing a
spec, publishing: stop and wait.
- check: `manual`
- validated: 2026-08-31 — used correctly on a conflict over a sealed register

**WA-S.2** [WHEN closing a gate] Write `retros/YYYY-MM-DD_<gate>.md`. **A rule named in a retro
but not landed in a spec does not exist** — a session proposes, never amends, and a proposal
names the case it would have caught **and** a case it would wrongly reject.
- check: `checks/rules_current.sh`
- validated: 2026-09-14 — a retro closed with six rules marked "to fold into specs/"; weeks
  later none of them were there

---

## Graveyard

Deleted rules and the reason. They are not re-proposed without new evidence. Entries
deliberately do not link the deleted thing: a dead reference in a live document is its own defect.

| removed | why |
|---|---|
| operator approves the plan; operator recognises `INPUTS.tsv`; operator grants ACCEPTED_RISK | three blocking human stops inside one measurement. Replaced by WA-A.1. |
| "interpretation is the operator's call, always" | right about authorship, wrong about timing. Now WA-A.4, asynchronous. |
| every operator-facing reply is also a file in `docs/responses/` | pure overhead per exchange; no case where it caught anything |
| per-artifact `prov.json` + `prov.py` + `check_prov.py` | a second provenance system for the same job. The bundle is the only one. |
| separate `ROADMAP.md` and `CLAIMS.md` | contradicted WA-L.1 in the same repo. The launcher holds both. |
| 18 PROVISIONAL rules | never validated against a real case |
| one row = one measurement = one session, as the unit of *scope* | right about the number, wrong about the session; it deferred every scientific goal a project had |
