# LAUNCHER — <track name>

_Copy to `launchers/LAUNCHER_<track>.md` and fill._

**This is the only document the operator writes.** Goals, non-goals, kill criteria, claims
and gates all live here. There is no separate `GOALS.md`, `CLAIMS.md` or `ROADMAP.md` — one
track, one file, written once and frozen when the first gate starts.

Do not drop a section: a launcher that has dropped one has dropped the defect that section
prevents (`general/agreements/LAUNCHER_SPEC.md`).

**Mission, in one sentence.** <what this track produces, and why it runs now>

---

## 0 · NON-NEGOTIABLES — read before any tool call

### 0.1 The single write boundary (WA-C.6)

> **You may WRITE to exactly one place:**
> `<project>/ARIS_OUTPUT/<track>/`
>
> **Everything else is READ-ONLY.** Reading is expected and encouraged. Writing, moving,
> renaming or "fixing" anything outside the boundary is forbidden — other sessions depend
> on those files.
>
> **Copy-in rule.** A derived or filtered version of any external input goes in
> `<track>/cache/`, never beside the original.
>
> If a task appears to require modifying something outside the boundary: **STOP and report.**

Registered derived artifacts this track may write outside the boundary (the only exception —
each enters `data/README.md` with its hash, or this list is empty):

- _none_

⚠️ This boundary is also set in `.claude/settings.json` under `sandbox.filesystem.allowWrite`.
If the two disagree, **the settings win** and the launcher is the defect.

### 0.2 Anti-anchoring (WA-D.6)

> **Read their METHOD freely. Read their NUMBER only after computing your own.**
>
> If the target value is in your context before you compute, you cannot tell derivation from
> recognition. Write your decision rule to a timestamped file before computing anything.
>
> ⚠️ **A script containing the number it is trying to reproduce is not a derivation.**
>
> If you match: say whether you could have failed to match. A shared input or a shared
> instruction guaranteeing the match is **not** evidence.
> If you differ: yours stands until theirs is re-derived, and both go in the record.
>
> Exempt: *reconciliation*, where the prior value is an input to an assertion that fails the
> run on disagreement, rather than an input to the computation.

### 0.3 The denominator (WA-D.7)

> Every rate names the **population** its denominator equals — in words a reader can check,
> not "the file" or "the glob". A second count of that population, by code sharing nothing
> with the producing script, ships in the bundle. Where no independent route exists, say why,
> and grade the rate DERIVED rather than MEASURED.

### 0.4 Evidence rules

1. **A positive control before every negative claim.** An all-zero result is a broken-search
   signal until proven otherwise (EVIDENCE_STANDARDS §6).
2. **Declare every threshold in code, before scoring** (§5). A free parameter chosen after
   seeing the outcome is not a parameter, it is the result.
3. **Grade circularity before use** (§3). The instrument that DEFINES a property may not be
   the instrument that MEASURES it.
4. **Trace every number to the code that wrote it.** No producing script → `[UNVERIFIED]`.
5. **Census or estimate, and say which** (WA-D.2).
6. **Probe field semantics before building on a field** (WA-D.3). When the values disagree
   with the documented schema, the values win.
7. **State the unit** of every count and rate.

### 0.5 The self-adversarial gate — required before any gate is declared done (BS-14)

**You attack your own output before you present it.** Answer all six in the bundle README:

1. **Where is each headline claim overstated?** Name the specific word doing unearned work.
2. **What specific alternative explanation** would produce this exact number?
3. **Could this test have returned a negative?** If nothing could have falsified it, it is
   not a test — say so and redesign it.
4. **What is the UNIT of every rate?**
5. **Which numbers have no producing script?** Tag them `[UNVERIFIED]`.
6. **What did you withdraw or weaken?**

> ⚠️ **A gate with nothing withdrawn or weakened is a gate that was not attacked.** If
> genuinely nothing survived attack, say so and show what you tried. Record the attempt;
> never manufacture a withdrawal.

### 0.6 Interpretation (WA-I.1)

> Whether a result supports a claim, whether a goal is met, whether to keep going: the
> operator's call, always. Measure, record, and report the counts including the ugly ones.
> **Do not conclude.**

### 0.7 Autonomy and gates

Between gates, work autonomously — do not ask permission for ordinary reads or intermediate
calls. **At a gate: write the deliverable, update `STATUS.md`, and PAUSE for approval.**

**Stop and report** — do not improvise past any of these: a missing tool, or one that runs
and produces nothing usable on real data; a path that is not where this launcher says; a file
you would have to modify; a result that contradicts this launcher.

Everything else follows WA-S.4 — LOW-STAKES takes the default and logs it, HIGH-STAKES stops.

### 0.8 Environment and compute

```bash
cd <project root>
export PATH=<env bin>:$PATH        # never base
```

Anything >10 min states where it runs and why. Validate the harness in a ~60 s interactive
session before queueing (WA-K.2). Size from a measured smoke rate on a representative sample
(WA-K.3, WA-K.4). Submit cheap gating jobs before large arrays (WA-K.5).
Details: `general/site/COMPUTE.md`.

---

## 1 · Objective, success criterion, kill criteria

**Objective.** <one sentence: what this track produces>

**Success criterion.** <how you will know it is done AND correct — never "it ran">

**Kill criteria.** What would make you abandon this track — written now, while you are not
invested. A track with no kill criterion cannot fail; it can only be extended.

- <the measurement result that means stop>
- <the cost or time that means stop>

---

## 2 · Out of scope, and non-goals

Explicit, and the section that prevents most drift. "Everything not mentioned above" is not
a list.

**Not this track** — adjacent work a session will be tempted into:

- <…>

**Non-goals — declined permanently, not deferred.** A sentence you can point at when a
session proposes it:

- <…>

**Settled and not to be re-litigated here:**

- <question> — settled by `docs/decisions/<nnnn>-<slug>.md`

---

## 3 · Inputs, with trust grades (WA-L.3)

An ungraded input is DO-NOT-USE. A FROZEN row with no bundle id is not FROZEN.

| input | path | grade | note |
|---|---|---|---|
| | | RAW / FROZEN / RE-DERIVE / DO-NOT-USE | FROZEN names its bundle; a design fact carries the `operator-supplied design fact` tag with a person and a date |

---

## 3b · Claims this track settles

The ledger for this track. **A claim exists here as UNPROVEN before the gate that settles it
runs** (CL-1). Ids are scoped to the track — `<track>:C1` — so they cannot collide with
another launcher's.

This table is the operator's (CL-2). A session proposes a paste-ready block in its bundle
README; it never edits this file.

| ID | Claim — value, unit, denominator, scope | Grade | Circ. | Status | Settled by | Date |
|----|------------------------------------------|-------|-------|--------|-----------|------|
| `<track>:C1` | | — | | UNPROVEN | — | |

Grade: `MEASURED` · `DERIVED` · `INFERRED`. One INFERRED element makes the whole claim
INFERRED (EVIDENCE_STANDARDS §1c). Circularity: `NONE` · `LOW` · `MEDIUM` · `HIGH` (§3).
Status: `UNPROVEN` · `SUPPORTED` · `REFUTED` · `WITHDRAWN`.

**A refutation is a result and lands like any other** (CL-3). A claim is never rescued by
qualification: if the measurement splits it, both halves are reported and it settles as the
weaker one (CL-6). A claim becomes SUPPORTED only after the operator signs off in their own
words (CL-5, WA-I.2).

---

## 4 · Gates

| gate | measurement | weight | mode | stop condition | claim | gated on |
|---|---|---|---|---|---|---|
| `<track>-g1` | | LIGHT / FULL | SINGLE-PASS / LOOPED | done when `results/<gate>/` exists and re-running `run.sh` from the hashed inputs reproduces <the number> | `<track>:C1` | — |

**Weight** (WA-B.5) — pay for controls where a claim rests on the number:

- **LIGHT** — the provenance skeleton only: inputs hashed, environment locked, scripts
  verbatim, `run.sh` reruns. No bespoke control fixture. For recon, feasibility, "how many
  are there", "does this tool run on real data". **A LIGHT number may not enter a claim, a
  figure, or the paper** — it is orientation, and promoting it means a new FULL bundle.
- **FULL** — everything: declared thresholds, positive control per zero, the denominator's
  independent second count, the hand-checked fixture. Required the moment a number becomes a
  claim, a figure, or paper text.

**Mode** (WA-L.2) — a LOOPED gate's stop condition contains a number and a round budget. A
loop may DRIVE but may not ACQUIT: it decides whether a step is complete, never whether a
result is correct.

**Dependency graph** — independent gates may run in parallel sessions or on different
machines, and that is why this is a track rather than a queue:

```
  <g1> ──► <g2> ──► <g4>
  <g3> ─────────────┘
```

---

## 5 · Compute

| gate | where | why | estimate |
|---|---|---|---|

⚠️ If an estimate is off by more than 2×, **stop and report**.

---

## 6 · Deliverables

Per gate: a bundle at `results/<gate>/` per `general/agreements/BUNDLE_SPEC.md`, and a retro
at `retros/YYYY-MM-DD_<gate>.md`. Nothing else is a deliverable.

Assemble a bundle with `bash general/tools/bundle.sh <gate>`; it does the fixed work — hashes
inputs, locks the environment, copies scripts verbatim, writes `PROVENANCE.md` — so the
session's effort goes to the controls, not the paperwork.
