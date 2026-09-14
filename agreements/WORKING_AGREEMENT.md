# WORKING AGREEMENT — v7

**ARIS owns the workflow. This file constrains how it works — it does not replace it.**

ARIS owns the lifecycle (idea → contract → experiment plan → implementation → execution →
review → claims → paper), its artifacts (`.aris/`, `idea-stage/`, `research-wiki/`,
`paper/`, `EXPERIMENT_PLAN.md`, `EXPERIMENT_LOG.md`, `findings.md`), its loops and their
round budgets, and its reviewer routing (ARIS's `review_gate.py`, `/auto-review-loop`).
This layer owns **data safety, evidence standards, provenance, reporting quality, Ibex
execution policy, and which decisions are reserved for the operator.**

    WA-x.y  [ALWAYS | WHEN <situation>]  <statement>
      check:     <script in checks/, or "manual">
      validated: <the real, dated case it caught — full story in retros/>

---

# §1 · ALWAYS — five rules, paid every turn

_Read these on every turn. **Stop here** unless a §2 situation applies._

**WA-A.1** [ALWAYS] **ARIS owns the lifecycle; this layer constrains it and never replaces
it.** Its stages, artifact paths, loops, round budgets and reviewer routing are authoritative.
Where a rule here would override one of those, the rule is wrong and gets fixed. This layer
adds requirements *about the science*; it does not add a second orchestrator.
- check: `manual` — no rule here defines a stage, a loop cadence, or an acceptance state
- validated: 2026-09-14 — an earlier form of this layer defined its own plan→review→execute→
  review→land lifecycle and its own gate script. Two independent reviews found it competing
  with ARIS's, and ARIS's `review_gate.py` already owned the transition it duplicated.

**WA-A.5** [ALWAYS] **Never weaken ARIS's independent-review requirements.** Reviewer
independence, score thresholds and the stop/continue/escalate transition are ARIS's
(ARIS's `review_gate.py`: positive requires `score >= 6` and verdict in {ready, almost}).
Add review; never route around it, never substitute a same-family reviewer, never lower a
threshold to get a pass.
- check: `manual`
- validated: 2026-09-14 — a previous layer replaced the canonical reviewer wholesale, and a
  still earlier one defaulted the adversary to the author's own model family.

**WA-D.1** [ALWAYS] **Containment, enforced mechanically — not by intention.** Source and
canonical inputs are read-only by file mode (`chmod a-w`). Writes are confined to the
project paths declared in `.claude/settings.json` — ARIS's artifact directories and this
layer's — and `permissions.allow` mirrors `sandbox.filesystem.allowWrite`, so a path the
sandbox permits never stalls on a prompt.
- check: `manual` — `find <data> -writable` empty; the two allowlists mirror each other
- validated: 2026-09-14 — an earlier form said "exactly one directory", which was false the
  moment ARIS's artifact paths were unblocked, and a rule contradicted by its own settings
  teaches an agent to ignore it
**WA-G.5** [ALWAYS] **Null and refuting results are never suppressed.** *Verified* means
reproducible, not welcome. What is withheld is broken intermediate work — never an
unwelcome finding.
- check: `manual`
- validated: 2026-09-04 — without this, the rule suppresses exactly the negatives
  `EVIDENCE_STANDARDS` §6 requires
---

## D — Data and measurement

**WA-S.1** [ALWAYS] **Never guess silently and never stall.** Append to `docs/BLOCKED.md`: what
is needed, why, the options, your recommended default. **LOW-STAKES** — reversible, contained,
inside the declared compute budget, inside scratch: take the default, log it, **continue.**
**HIGH-STAKES** — deleting or overwriting, large compute, changing a spec, publishing: stop.
- check: `manual`
- validated: 2026-08-31 — used correctly on a conflict over a sealed register

---

# §2 · WHEN — read on demand, not every turn

_Each applies only in its situation. None is paid when it does not._

## Launchers and scope

**WA-L.1** [WHEN writing or reading a launcher] Every track has a launcher, written before it starts, and it is the
authority on scope: objective, kill criteria, non-goals, inputs, gates, stop conditions. A
session's reading of what the work "obviously" needs does not override it. Standing scientific
claims live in `research_contract.md`; the launcher names which it settles. `INDEX.md` is
GENERATED, never hand-edited.
- check: `tools/check_launcher.py`
- validated: 2026-08 — 43 output dirs, 37 with FINDINGS.md, only 12 with a PLAN.md

**WA-L.2** [WHEN validating a launcher] **A launcher must be complete enough to run unattended.** A missing field
stops the gate; the agent neither infers it nor wakes the operator.
- check: `tools/check_launcher.py`
- validated: 2026-09-14 — the operator cannot be scheduled; a mid-gate question costs a night

**WA-L.3** [WHEN declaring inputs] Every input carries a trust grade: **RAW** · **FROZEN**
(names its bundle) · **RE-DERIVE** · **DO-NOT-USE** (says why). Ungraded means DO-NOT-USE.
- check: `tools/check_launcher.py`
- validated: 2026-08 — two load-bearing numbers never re-derived, nothing recorded which

---

## G — The gate

## Measurement and evidence

**WA-D.2** [WHEN reporting a count, rate or total] **A census is exact; an estimate declares itself.** Any count, rate or
total landing in a table or report is computed exactly over all records — stream it if it
exceeds memory, move it to the cluster if it exceeds the machine, never sample to stay local.
A statistical quantity (CI, CV score, permutation null) is not a census, is permitted, and
declares its estimator, n and interval.
- check: `manual` — every number labelled census or estimate
- validated: 2026-09-04 — a sampled count reported as a census

**WA-D.3** [WHEN reporting a rate] Every rate names the population its denominator equals, counted a second
time by an independent path. Two counts disagreeing is a finding, not a rounding error.
- check: `checks/bundle_valid.sh` — `unit` and `denominator` are required columns
- validated: 2026-09-04 — a rate whose denominator nobody had counted twice

**WA-D.4** [WHEN building an analysis on a field] Probe real values first. A schema describes data as
intended, not as it is; where they diverge the values win and the schema is corrected.
- check: `manual` — the plan shows actual values, not a schema quote
- validated: 2026-08 — a lineage string under `ecosystem`; a `direction` field 97.7% null

---

## B — The bundle

## Bundling a number

**WA-B.1** [WHEN producing a number] **Numbers** go to `results/<GATE>/` and nowhere else; **scratch** goes to
`ARIS_OUTPUT/<gate>/` — gitignored, disposable, expected to be messy. This governs *numbers
and scratch only*. **ARIS's control artifacts are not outputs and this rule does not touch
them**: `.aris/`, `research-wiki/`, `paper/`, `idea-stage/`, `refine-logs/`, `review-stage/`,
`EXPERIMENT_PLAN.md`, `EXPERIMENT_LOG.md`, `MANIFEST.md` are the interfaces ARIS skills use
to talk to each other, and they live where ARIS expects them.
- check: `checks/bundle_valid.sh`
- validated: 2026-09-14 — an earlier form said *all* outputs go to `ARIS_OUTPUT/` and named a
  parallel top-level dir a defect. Applied to ARIS that is not a tidiness rule, it is an
  outage: the sandbox blocked `refine-logs/` and the skills went inert with nothing to read.

**WA-B.2** [WHEN landing a bundle] A gate is done when `run.sh` **reruns and reproduces the number**, not when
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

**WA-G.1** [WHEN scoping a measurement] A gate names exactly one measurement and emits exactly one bundle.
"Explore X" is a note, not a gate.
- check: `manual`
- validated: 2026-09-04 — nine stages ran with no stop condition, zero bundles

**WA-G.2** [WHEN scoping a measurement] Its stop condition is written before it starts: *done when
`results/<GATE>/` exists and `run.sh` reproduces the number from hashed inputs.* Rewriting it
after seeing a result makes a new gate, and the retro says so.
- check: `tools/check_launcher.py`
- validated: 2026-09-04 — as WA-G.1

**WA-G.3** [WHEN a session is running long] A gate fits in one session before the first compaction. If not, it is two
gates — quality falls when the model works from a summary of a summary.
- check: `manual`
- validated: 2026-09-14 — the 45-directory tree is what unbounded gates look like

**WA-G.4** [WHEN judging whether a stage produced a result] A gate producing no provenanced artifact has produced no result. It may be
correct and necessary; it is not evidence and not progress.
- check: `checks/bundle_valid.sh`
- validated: 2026-09-04 — 141 documents, nine stages, zero bundles

## Compute, loops and sessions

**WA-K.1** [WHEN scheduling computation] **Choose the machine by measurement, not habit.** To the cluster when
wall-clock > 2 hr, VRAM > 24 GB, or an exact pass does not fit in RAM (`site/COMPUTE.md`).
Size from a measured smoke test on a representative slice — never the head of a file, never
uncontended — and validate the harness interactively before queueing.
- check: `tools/dispatch.py --explain`, pasted into PLAN.md
- validated: 2026-08 — a head-sampled smoke test measured 11.1 s/fold vs 28.3 s/fold actual

---

## S — Session

**WA-K.2** [WHEN a tool, package or module appears to be missing] **Sweep before
concluding ABSENT, and never install to work around a sweep you did not do.** A dependency
is usually present in a *different* environment on borg or Ibex, not missing. Sweep every
env on both machines, and on the cluster check modules too — remembering that `module avail`
comes back empty even where software is installed. Only after a full sweep is `ABSENT` a
finding; record the grade and the exact working invocation
(`EVIDENCE_STANDARDS` §2). Mechanics: `site/COMPUTE.md` § Finding a dependency.
⛔ Never install into the base environment, and never into a shared env to satisfy one gate
without saying so — a silent install makes every earlier result irreproducible.
- check: `manual` — the sweep output is in PLAN.md before any install
- validated: 2026-09-14 — a project standardised on one env and repeatedly re-derived tools
  that already existed elsewhere on the same machine

**WA-A.2** [WHEN a loop reports its own work complete] **A loop may DRIVE but may not ACQUIT.** Iteration decides whether a step
is complete, never whether a result is correct or good enough.
- check: `manual` — the agent never writes its own verdict line
- validated: 2026-08 — a session reviewing its own night got its fifth diagnosis backwards

**WA-A.3** [WHEN defining a loop this layer owns, not one of ARIS's] **Iteration is bounded and the halt reason is named.** Halt on: condition
met, two rounds with no change, or budget exhausted (default 3). A budget-halt is never
reported as a pass.
- check: `manual` — the loop names its halt reason; ARIS's own loops carry MAX_ROUNDS
- validated: 2026-09-14 — an unsatisfiable FAIL becomes an unbounded overnight retry loop

**WA-A.4** [WHEN writing up a result] **The agent measures and reports; it does not conclude.** Counts, including
the ugly ones. Interpretation lands as `PROPOSED:` and becomes the operator's by reading it.
- check: `manual`
- validated: 2026-09-14 — the previous form was right about authorship, wrong about timing

**WA-S.2** [WHEN closing a gate] Write `retros/YYYY-MM-DD_<gate>.md`. **A rule named in a retro
but not landed in a spec does not exist.** A session proposes, never amends; a proposal names
the case it would have caught **and** one it would wrongly reject.
- check: `checks/rules_current.sh`
- validated: 2026-09-14 — a retro named six rules to fold into specs/; weeks later, none were

---

## Graveyard

In `LINEAGE.md`, with reasons. Rules removed there are not re-proposed without new evidence.
