# EVIDENCE STANDARDS — measurement integrity

_Global spec. Project- and stage-agnostic: nothing here is about any particular organism,
molecule, tool or track. Companion to `WORKING_AGREEMENT.md` (how to work) and
`REPORTING_STANDARDS.md` (how to report). This file is about **whether a number means what
it appears to mean.**_

Every rule below was added because its absence produced a wrong or unfalsifiable number in
real work, not because it sounded prudent.

---

## 1. Validate the ARTEFACT, never its existence

> ⚠️ **This supersedes "confirm output exists / exit code 0, then report"**
> (`WORKING_AGREEMENT.md` § Workflow). That check is insufficient and has failed
> repeatedly.

A tool can exit **0** and write a **0-byte file**. A previous failed run can leave a
zero-length or truncated artefact that a later run then serves as valid, because the cache
check asked only whether the path existed.

**Do:**
- grade an output by its **content** — bytes, parseability, expected record count, an
  invariant you can assert — never by exit code and never by `Path.exists()`
- make cache checks `exists() AND non-empty AND parses`
- assert structural invariants, not just totals: partitions sum to the whole, intervals do
  not overlap, every record has the expected width
- delete or ignore artefacts that fail validation rather than repairing them in place

**Failure prevented:** silent success. The most expensive kind, because nothing looks wrong.

---

## 2. Probe capability by EXECUTION, not by presence

`command -v` is unreliable across environments. `test -x` across all environments is
better and is the current minimum. **Both are still insufficient**: a tool can be
installed, report a version, and fail on every real input — because of a broken default
path, a missing reference database, or an undocumented required flag.

**Do:** run the tool on **real project data** during planning, and record a grade:

| grade | meaning |
|---|---|
| `VERIFIED` | ran to completion on real data, output content checked |
| `WORKAROUND_VERIFIED` | fails by default; runs correctly with a **recorded** flag |
| `PRESENT_BUT_BROKEN` | executes, fails on real input |
| `DATA_INADEQUATE` | tool present, its reference database is a stub |
| `ABSENT` | not present, all environments swept |
| `NEEDS_NETWORK` | would require a download; not attempted |

**Do:** record the exact working invocation, including workaround flags, next to the grade.
**Do:** treat "no semantic version, commit hash only" as a provenance gap and tag it.

**Failure prevented:** discovering mid-stage that the method you committed to cannot run —
after the design depended on it.

---

## 3. Circularity — grade it, and never measure with the instrument that defined the thing

> ### The cardinal rule
> **The instrument that DEFINES a property may not be the instrument that MEASURES it.**

Conditioning a measurement on a label derived from the same model drives the measured
quantity toward its definition **by construction**. The result is not merely biased — it is
true regardless of the data, and therefore says nothing.

**Do:** grade every method against this rubric, declared before use:

| grade | meaning |
|---|---|
| `NONE` | output does not depend on any prior derived call |
| `LOW` | depends on a reference established by an **independent modality** |
| `MEDIUM` | depends on a model or alignment whose construction used the same landmarks |
| `HIGH` | output is conditioned on the property being measured (self-referential) |

**Do:** when selecting inputs — seeds, training sets, reference sets, tip sets — select on
evidence **independent** of the instrument under test. Selecting with the instrument's own
output guarantees the answer.

**Do:** measure populations **unconditionally** and stratify afterwards. Filter for a
result, never before one.

**Do:** if a circular quantity must be reported, **price the circularity**: compute the
same measurement conditionally and unconditionally and report the difference.

---

## 4. Independence before agreement

Two methods agreeing is evidence **only if they can disagree**. Methods sharing a hidden
dependency agree whenever that dependency is wrong.

**Do:** declare each method's **evidence sources** as a set, then compute independence as
the Jaccard distance between source sets. Assert it; do not assume it.

**Do:** declare the acceptance rule **before** computing the matrix — e.g. *"a claim is
admissible only if two methods with independence ≥ X agree, and at least one has
circularity NONE or LOW"*.

**Do:** state explicitly which pairs **cannot** cross-check each other, and why.

**Do:** record each method's **scale ceiling**. A pair is limited by the smaller of its
two, and a method validated on tens cannot license a claim about a population.

---

## 5. Declare thresholds before scoring; let controls bound them after

A free parameter chosen after seeing the outcome is not a parameter, it is the result.

**Do:** fix every threshold in code, with a comment marking it DECLARED, **before** the
data is scored.
**Do:** afterwards, use an **independent control** to bound it — the value at which the
rule starts rejecting things known to be true — and report where the declared value sits
against that bound.
**Do:** report a **sensitivity sweep**, so a reader sees whether the answer sits on a
plateau or on a cliff.
**Do NOT:** move the declared value to improve the result. Report the tension instead.

---

## 6. Controls are asymmetric — apply the asymmetry

**A positive control is required before every negative claim.** If the same test on a set
where the signal is known present does not fire, the negative means nothing.

**Do:** ask of every test, at DESIGN time, **"could this have returned a negative?"** If
nothing could have falsified it, it is a description, not a test — label it as such.

**Do:** respect the direction of evidence. For a rule that is supposed to accept known-true
cases:
- a **known-true case rejected** → **refutes** the rule
- a **known-false case rejected** → does **not** confirm it, if the negative has other
  explanations

**Do:** provide a **null model for your own criterion**, held to the same standard used to
reject someone else's. A criterion with no null cannot be defended by pointing at a rival
that also has none.

---

## 7. Scope claims to what was actually examined

**Do:** state the audited scope in the claim itself — "no X in the Y chain" not "no X".
A scoped claim that is later found false somewhere unexamined was simply overstated, and
overstatement is avoidable at zero cost.

**Do:** when a claim is corrected, amend it **in place** with both values and the date, and
keep the superseded version visible. Silent correction destroys the audit trail that makes
the rest of the record trustworthy.

---

## 8. Checklist before any number leaves a stage

- [ ] artefact validated by **content**, not existence or exit code
- [ ] every tool **executed** on real data and graded, working invocation recorded
- [ ] circularity graded; nothing measured with the instrument that defined it
- [ ] population measured **unconditionally**; stratified afterwards
- [ ] agreement backed by **declared, computed independence**
- [ ] thresholds **declared before** scoring, **bounded after** by an independent control
- [ ] a **positive control** for every negative claim
- [ ] "could this test have returned a negative?" answered in writing
- [ ] a **null** for every criterion of your own
- [ ] **unit and denominator** stated for every rate
- [ ] claims scoped to what was examined
