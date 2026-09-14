---
name: plan-audit
description: Audit an experimental plan for scientific validity BEFORE any compute is spent. Use after EXPERIMENT_PLAN.md exists and before /experiment-bridge runs it, especially when the plan will consume cluster time. Checks falsifiability, circularity, declared thresholds, positive controls, census-vs-estimate, denominators, and whether the compute estimate came from a measured smoke test. Returns a verdict artifact. Triggers on experiment plan, pre-compute review, plan audit, before running experiments, circularity, positive control, declared threshold.
---

# Plan audit — scientific validity, before the compute

**This is NOT a lifecycle gate and does not replace ARIS's review.** ARIS owns reviewer
routing, the score threshold and the stop/continue/escalate transition
(ARIS's `review_gate.py`: positive requires `score >= 6` and verdict in `{ready, almost}`),
and `/experiment-bridge` already does a pre-deployment **code** review where CRITICAL
issues force revision.

This adds one thing neither covers: **an independent audit of the plan's *science*, before
the cluster time is spent.** A design that cannot return a negative costs the same GPU-hours
as one that can.

## When to run it

After `EXPERIMENT_PLAN.md` exists, before `/experiment-bridge` executes it. Skip it for
plans with no meaningful compute cost — the audit is worth its own latency only when a wrong
design would waste real hours.

## What the reviewer gets — and does not

**Give:** `EXPERIMENT_PLAN.md`, the launcher, `<project>/idea-stage/docs/research_contract.md`, real
schema probes of the inputs, and `general/agreements/EVIDENCE_STANDARDS.md`.

⛔ **Withhold:** the conversation, the author's justifications, its confidence, and any
earlier review that passed. A reviewer handed the argument grades the argument and agrees
with it.

Use ARIS's reviewer routing. **Do not substitute a same-family reviewer** (WA-A.5).

## The eleven questions

1. Could this plan return a **NEGATIVE**? If nothing could falsify it, it is a description.
2. Grade circularity `NONE/LOW/MEDIUM/HIGH` per method. Anything measured with the
   instrument that **defined** it is blocking.
3. Are thresholds declared in code **before** scoring? A cut chosen after seeing the outcome
   is the result, not a parameter.
4. Is every claimed independence **computed**, or assumed? A provenance-overlap score
   disqualifies a pair; it never certifies one (`EVIDENCE_STANDARDS` §4).
5. A positive control for every expected zero?
6. Is anything reported from a **sample** where a census was available?
7. Does every rate name the population its denominator equals, counted a second,
   independent way?
8. Were real field **values** probed, or a schema document trusted?
9. What already exists on disk that this would rebuild — and would a stale or wrongly
   computed artifact read as ready? **Absence is loud; wrongness is quiet.**
10. Is the compute estimate from a **measured** smoke test on a representative slice —
    not the head of a file, not uncontended?
11. Is the declared weight (LIGHT/FULL) right for what the number will be used for?

## The verdict artifact

Write `refine-logs/PLAN_AUDIT_<plan>.md`:

```
VERDICT: <ready | almost | not ready>
SCORE:   <1-10>

FINDINGS
- [BLOCKING|CONCERN|NIT] <one-line claim>
  WHY:  <the mechanism producing a wrong or unfalsifiable result>
  TEST: <the command or check that settles it>

CHECKED:     <what was verified, and how>
NOT CHECKED: <what could not be verified from this packet, and why>
```

## Reading the verdict — both conditions, not one

⚠️ **A plan does not pass on the top-level verdict alone.** It passes when
`score >= 6` **AND** `verdict ∈ {ready, almost}` **AND** *no finding is marked `BLOCKING`*.

That third condition is not pedantry. An earlier version of this check gated on the verdict
only, so a reply reading `VERDICT: almost` with a `[BLOCKING]` finding underneath opened the
gate — the reviewer had named the defect and the machine let it through anyway.

`NOT CHECKED` may not be empty: a review that verified everything did not understand the
plan, and one with no coverage statement is not a pass.

## Disposition

Every `BLOCKING` and `CONCERN` is answered in writing before the plan proceeds:

- `FIXED` — the diff, plus the command and output showing it works
- `REFUTED` — **an artifact, not an argument**: a command whose output would have
  *confirmed* the finding had it been right
- `ACCEPTED_RISK` — the operator's initials and date. Never self-granted.

Prose alone never closes a finding, and "out of scope" belongs in the launcher — declared
before the audit, not discovered after it.
