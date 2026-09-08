# LAUNCHER SPEC

A **launcher** is the authority on scope for a track. It is written before the track starts
and it is what a session reads to know what it may do. `ROADMAP.md` says what the gates are;
the launcher says what the track *is*, and constrains every session in it.

One launcher per track, at `launchers/LAUNCHER_<track>.md`. A track without one does not
start (WA-L.1).

A launcher exists because an instruction a session can drift past is not a boundary. Each
section below became mandatory after its absence produced a defect, and the six are the
minimum set: a launcher missing any one of them is incomplete, and `specs_exist.sh` reports
which.

---

## The six required sections

### 1 · Write boundary

> **You may WRITE to exactly one place:** `<project>/ARIS_OUTPUT/<track>/`
> Everything else is READ-ONLY. Reading is expected and encouraged; writing, moving,
> renaming or "fixing" anything outside the boundary is forbidden.
> **Copy-in rule.** A derived or filtered version of any external input goes in
> `<track>/cache/`, never beside the original.
> If a task appears to require modifying something outside the boundary: **STOP and report.**

Declared here **and** enforced in `.claude/settings.json` under
`sandbox.filesystem.allowWrite` (WA-C.6). The prose is for the reader; the settings entry is
what actually holds. A launcher whose boundary and settings disagree is a defect, and the
settings win.

**Exception, and the only one:** a *registered derived artifact* — a materialised view that
later gates read instead of re-streaming the raw corpus. Its path is named in this section
before the track starts, and it enters the project's data register with its hash.

### 2 · Objective and success criterion

One sentence for the objective. The success criterion says how the operator will know the
track is done **and correct** — never "it ran".

### 3 · Out of scope

Explicit, and the section that prevents most drift. Name the adjacent work a session will be
tempted into, and say it is not this track. "Everything not mentioned above" is not an
out-of-scope list.

Include here any question the project has already settled and that the track may not
re-litigate, with the decision record that settled it.

### 4 · Inputs, each with a trust grade

A table, one row per input, every row graded (WA-L.3):

| grade | meaning | may a gate build on it? |
|---|---|---|
| **RAW** | primary, unprocessed | yes |
| **FROZEN** | settled here; **names the bundle that settled it** | yes |
| **RE-DERIVE** | a value exists but has not been recomputed under current standards | only after WA-D.6 |
| **DO-NOT-USE** | known defective; this section says why | no |

An ungraded input is DO-NOT-USE. A FROZEN row with no bundle id is not FROZEN — it is
RE-DERIVE, or it carries the `operator-supplied design fact` tag with a person and a date
(WA-I.5).

### 5 · Gates

One row per gate: its id, its measurement, its **mode** (SINGLE-PASS or LOOPED), its stop
condition, and what it is gated on. A LOOPED gate's stop condition contains a number and a
round budget (WA-L.2).

Where gates are independent, say so and draw the dependency graph. Independent gates are the
whole reason a track exists rather than a queue — they can run in parallel sessions, on
different machines, or overnight.

### 6 · Compute

Where each gate runs and why, with an estimate. *If the estimate is off by more than 2×,
stop and report* — an estimate nobody checks is a guess with a number on it.

---

## The three standing rules a launcher restates

These are quoted **in full** in every launcher, with their rule ids, because a track may be
run by someone who has not read the agreements — and because each one is violated silently
rather than loudly. Quoting with the id keeps the copy traceable to the original instead of
competing with it (WA-P.4).

### Anti-anchoring (WA-D.6)

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

### The denominator (WA-D.7)

> Every rate names the **population** its denominator equals — in words a reader can check,
> not "the file" or "the glob". A second count of that population, by code sharing nothing
> with the producing script, ships in the bundle. Where no independent route exists, say why,
> and grade the rate DERIVED rather than MEASURED.

### Interpretation (WA-I.1)

> Whether a result supports a claim, whether a goal is met, whether to keep going: the
> operator's call, always. Measure, record, and report the counts including the ugly ones.
> Do not conclude.

---

## The self-adversarial gate (BS-14)

**Answered in writing, in the bundle README, before the bundle is offered for acceptance.**
This runs *before* an external reader is spent on the work — a second reader is expensive and
should not be spending its attention on what the author could have found alone.

1. **Where is each headline claim overstated?** Name the specific word doing unearned work.
2. **What specific alternative explanation would produce this exact number?** Not "this may
   be confounded" — *what else* produces it.
3. **Could this test have returned a negative?** If nothing could have falsified it, it is a
   description, not a test. Say so, and say whether it should be redesigned.
4. **What is the unit of every rate?** Per record · per locus · per sequence · per fold.
5. **Which numbers have no producing script?** Tag them `[UNVERIFIED]`.
6. **What did you withdraw or weaken?**

> ⚠️ **A gate with nothing withdrawn or weakened is a gate that was not attacked, and it will
> be read that way.** If genuinely nothing survived attack, say so explicitly and show what
> you tried.

The rule requires *recording what was tried*, never producing a withdrawal. A manufactured
withdrawal is worse than none, because it makes the section unreadable as a signal.

---

## Autonomy between gates

Between gates, work autonomously — do not ask permission for ordinary reads or intermediate
calls. **At a gate: write the deliverable, update STATUS, and pause for approval.**

**Stop and report** — not a gate, but do not improvise past it:

- a tool that is missing, or that runs and produces nothing usable on real data
- a path that is not where this launcher says it is
- a file you would have to modify to proceed
- a result that contradicts this launcher

Anything else follows WA-S.4: LOW-STAKES takes the recommended default and logs it,
HIGH-STAKES stops and waits.

---

## Template

`templates/LAUNCHER.md` is the copy-and-fill scaffold. It carries all six sections, the three
standing rules already quoted with their ids, and the six adversarial questions. Fill it; do
not rewrite it — a launcher that has dropped a section has dropped the defect that section
prevents.
