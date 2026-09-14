# WORKING AGREEMENT — v7

The behaviour spec for every project governed by this layer. Self-contained; prior trees are
named only in `LINEAGE.md`, which also holds the graveyard of removed rules.

    WA-x.y  [ALWAYS | WHEN <situation>]  <statement>
      check:     <script in checks/, or "manual">
      validated: <the real, dated case it caught — the full story is in retros/>

**Budget: 18 ALWAYS rules** — paid on every turn. Adding one requires deleting one.
*Currently 18: FULL.* Every rule here fired on a real failure; nothing is kept because it
sounds prudent. That is what 61 rules, 75 scratch directories and zero results taught.

---

## A — Autonomy: who holds the gate

**WA-A.1** [ALWAYS] **The reviewer holds the gate, not the operator.** An independent model
reviews the plan before execution and the result before landing; its verdict gates. The
operator is never in the critical path of a measurement.
- check: `tools/review.sh` — a missing review is not a pass
- validated: 2026-09-14 — 12 projects, 75 scratch dirs, 19 retros, zero landed results

**WA-A.2** [ALWAYS] **A loop may DRIVE but may not ACQUIT.** Iteration decides whether a step
is complete, never whether a result is correct or good enough.
- check: `manual` — the agent never writes its own verdict line
- validated: 2026-08 — a session reviewing its own night got its fifth diagnosis backwards

**WA-A.3** [ALWAYS] **Iteration is bounded and the halt reason is named.** Halt on: condition
met, two rounds with no change, or budget exhausted (default 3). A budget-halt is never
reported as a pass.
- check: `tools/review.sh` records round and halt reason
- validated: 2026-09-14 — an unsatisfiable FAIL becomes an unbounded overnight retry loop

**WA-A.4** [ALWAYS] **The agent measures and reports; it does not conclude.** Counts, including
the ugly ones. Interpretation lands as `PROPOSED:` and becomes the operator's by reading it.
- check: `manual`
- validated: 2026-09-14 — the previous form was right about authorship, wrong about timing

**WA-A.5** [ALWAYS] **The reviewer is a different model family from the author**, and read-only.
`EVIDENCE_STANDARDS` §4 applied to the review itself: agreement is evidence only if
disagreement was possible. This governs **our two gates** (plan, result) and is **additional
to** ARIS's own reviewer routing — never a global replacement for it. More review, not less.
- check: `tools/review.sh` refuses a same-family reviewer
- validated: 2026-09-14 — the previous adversary defaulted to the author's own family

---

## L — The launcher

**WA-L.1** [ALWAYS] Every track has a launcher, written before it starts, and it is the
authority on scope: objective, kill criteria, non-goals, inputs, gates, stop conditions. A
session's reading of what the work "obviously" needs does not override it. Standing scientific
claims live in `research_contract.md`; the launcher names which it settles. `INDEX.md` is
GENERATED, never hand-edited.
- check: `tools/check_launcher.py`
- validated: 2026-08 — 43 output dirs, 37 with FINDINGS.md, only 12 with a PLAN.md

**WA-L.2** [ALWAYS] **A launcher must be complete enough to run unattended.** A missing field
stops the gate; the agent neither infers it nor wakes the operator.
- check: `tools/check_launcher.py`
- validated: 2026-09-14 — the operator cannot be scheduled; a mid-gate question costs a night

**WA-L.3** [WHEN declaring inputs] Every input carries a trust grade: **RAW** · **FROZEN**
(names its bundle) · **RE-DERIVE** · **DO-NOT-USE** (says why). Ungraded means DO-NOT-USE.
- check: `tools/check_launcher.py`
- validated: 2026-08 — two load-bearing numbers never re-derived, nothing recorded which

---

## G — The gate

**WA-G.1** [ALWAYS] A gate names exactly one measurement and emits exactly one bundle.
"Explore X" is a note, not a gate.
- check: `manual`
- validated: 2026-09-04 — nine stages ran with no stop condition, zero bundles

**WA-G.2** [ALWAYS] Its stop condition is written before it starts: *done when
`results/<GATE>/` exists and `run.sh` reproduces the number from hashed inputs.* Rewriting it
after seeing a result makes a new gate, and the retro says so.
- check: `tools/check_launcher.py`
- validated: 2026-09-04 — as WA-G.1

**WA-G.3** [ALWAYS] A gate fits in one session before the first compaction. If not, it is two
gates — quality falls when the model works from a summary of a summary.
- check: `manual`
- validated: 2026-09-14 — the 45-directory tree is what unbounded gates look like

**WA-G.4** [ALWAYS] A gate producing no provenanced artifact has produced no result. It may be
correct and necessary; it is not evidence and not progress.
- check: `checks/bundle_valid.sh`
- validated: 2026-09-04 — 141 documents, nine stages, zero bundles

**WA-G.5** [WHEN a measurement is null or refuting] It is a result and lands like any other.
*Verified* means reproducible, not welcome. What is withheld is broken intermediate work,
never an unwelcome finding.
- check: `manual`
- validated: 2026-09-04 — without it this suppresses the negatives EVIDENCE_STANDARDS §6 requires

---

## D — Data and measurement

**WA-D.1** [ALWAYS] **Containment, enforced mechanically — not by intention.** Source data
and original scripts are read-only by file mode (`chmod a-w`). A track writes to exactly one
directory, enforced by `sandbox.filesystem.allowWrite` in `.claude/settings.json`; everything
else on the machine is read-only to it.
- check: `manual` — `find <data> -writable` empty; `Bash(chmod:*)` denied in settings
- validated: 2026-09-04 — prose for months, and violated; now a file mode

**WA-D.2** [ALWAYS] **A census is exact; an estimate declares itself.** Any count, rate or
total landing in a table or report is computed exactly over all records — stream it if it
exceeds memory, move it to the cluster if it exceeds the machine, never sample to stay local.
A statistical quantity (CI, CV score, permutation null) is not a census, is permitted, and
declares its estimator, n and interval.
- check: `manual` — every number labelled census or estimate
- validated: 2026-09-04 — a sampled count reported as a census

**WA-D.3** [ALWAYS] Every rate names the population its denominator equals, counted a second
time by an independent path. Two counts disagreeing is a finding, not a rounding error.
- check: `checks/bundle_valid.sh` — `unit` and `denominator` are required columns
- validated: 2026-09-04 — a rate whose denominator nobody had counted twice

**WA-D.4** [WHEN building on a field] Probe real values first. A schema describes data as
intended, not as it is; where they diverge the values win and the schema is corrected.
- check: `manual` — the plan shows actual values, not a schema quote
- validated: 2026-08 — a lineage string under `ecosystem`; a `direction` field 97.7% null

---

## B — The bundle

**WA-B.1** [ALWAYS] **Numbers** go to `results/<GATE>/` and nowhere else; **scratch** goes to
`ARIS_OUTPUT/<gate>/` — gitignored, disposable, expected to be messy. This governs *numbers
and scratch only*. **ARIS's control artifacts are not outputs and this rule does not touch
them**: `.aris/`, `research-wiki/`, `paper/`, `idea-stage/`, `refine-logs/`, `review-stage/`,
`EXPERIMENT_PLAN.md`, `EXPERIMENT_LOG.md`, `MANIFEST.md` are the interfaces ARIS skills use
to talk to each other, and they live where ARIS expects them.
- check: `checks/bundle_valid.sh`
- validated: 2026-09-14 — an earlier form said *all* outputs go to `ARIS_OUTPUT/` and named a
  parallel top-level dir a defect. Applied to ARIS that is not a tidiness rule, it is an
  outage: the sandbox blocked `refine-logs/` and the skills went inert with nothing to read.

**WA-B.2** [ALWAYS] A gate is done when `run.sh` **reruns and reproduces the number**, not when
a document is written. The validator checks that files exist and hashes match; only a rerun
re-derives.
- check: `checks/bundle_valid.sh` + the rerun
- validated: 2026-09-04 — a bundle that validated but had never been rerun

**WA-B.3** [WHEN declaring weight] A gate is **LIGHT** (provenance skeleton only; may not enter
a claim, figure or paper) or **FULL** (controls, declared thresholds, the denominator's second
count). Reproducibility is non-negotiable at both; only the control burden moves.
- check: `manual` — a weight per gate row; no LIGHT bundle cited by a claim
- validated: 2026-09-09 — census-grade controls on recon questions cost days per measurement

---

## K — Compute

**WA-K.1** [ALWAYS] **Choose the machine by measurement, not habit.** To the cluster when
wall-clock > 2 hr, VRAM > 24 GB, or an exact pass does not fit in RAM (`site/COMPUTE.md`).
Size from a measured smoke test on a representative slice — never the head of a file, never
uncontended — and validate the harness interactively before queueing.
- check: `tools/dispatch.py --explain`, pasted into PLAN.md
- validated: 2026-08 — a head-sampled smoke test measured 11.1 s/fold vs 28.3 s/fold actual

---

## S — Session

**WA-S.1** [ALWAYS] **Never guess silently and never stall.** Append to `docs/BLOCKED.md`: what
is needed, why, the options, your recommended default. **LOW-STAKES** — reversible, contained,
<10 min compute, inside the gate's scratch: take the default, log it, **continue.**
**HIGH-STAKES** — deleting or overwriting, large compute, changing a spec, publishing: stop.
- check: `manual`
- validated: 2026-08-31 — used correctly on a conflict over a sealed register

**WA-S.2** [WHEN closing a gate] Write `retros/YYYY-MM-DD_<gate>.md`. **A rule named in a retro
but not landed in a spec does not exist.** A session proposes, never amends; a proposal names
the case it would have caught **and** one it would wrongly reject.
- check: `checks/rules_current.sh`
- validated: 2026-09-14 — a retro named six rules to fold into specs/; weeks later, none were
