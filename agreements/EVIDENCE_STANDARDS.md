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

## 1b. Blindness is enforced by content, never by path

A stage declared blind must have its staged inputs **content-checked**, not
path-checked. A read boundary drawn by directory cannot make a stage blind: schema
and contract documents accrete findings over time, because every correction to a
contract is discovered by computing something.

**Do:** before staging, grep the tree for percentages and thousands-separated
integers. A file that has them is stripped, or explicitly waived with the reason
recorded in the file itself.

**Do:** tag every computed figure in a living document with its source stage, e.g.
`[stage 0a, 2026-08-31]`. The tag is the strip point: a schema-only build removes
bracketed figures and keeps the sentences. The property is what a reader needs to
avoid a trap; the count is what makes a stage non-blind.

**Do:** keep every figure INSIDE its tag. A number in the surrounding prose survives
tag-stripping and leaks silently.

**Failure prevented:** an analysis anchored to a prior answer, where the analyst's
honesty is no longer checkable from the record.

---

## 1c. Grade the CLAIM, not the number

> ⚠️ **A table being open is not the same as having read it.**

A figure has no evidential state of its own. The same digits can be measured in one
sentence and inferred in the next, because what carries the grade is the **claim** — value,
unit, denominator and scope together — not the numeral. **A quantity read from a table that
does not contain it, or read by eye rather than computed, is `INFERRED`, even when a table
was open at the time.**

**Do:** grade every claim before it leaves a stage:

| grade | meaning |
|---|---|
| `MEASURED` | every element — value, unit, denominator, scope — is read from an artefact that contains it, by a selector that fails loudly on zero or more than one match |
| `DERIVED` | computed from `MEASURED` elements by a stated operation, and the operation is recorded beside the result |
| `INFERRED` | at least one element rests on reading, recall, a tool default, or a property the artefact does not record — **including when every other element is `MEASURED`** |

**Do:** attach the grade **once per claim, never per figure**. A claim with one `INFERRED`
element is `INFERRED`. A report that grades its numerals individually will certify a correct
numerator and lose the denominator that made the sentence false.

**Do:** treat a **negative** as a claim needing the same grade. *"X is not present"* is
`INFERRED` unless the search's scope is recorded and covers what the claim asserts. A sweep
that was sound for the question it asked is not evidence for a wider one, and the scope is
the part that goes missing when the result is quoted.

**Do:** treat an unexamined **tool default** as `INFERRED`. A threshold nobody passed is
still a threshold, and it belongs in the record beside the ones that were declared (§5).

**Do NOT:** rescue a claim by qualifying it. If an element is `INFERRED` and the claim
cannot carry that, **remove the claim** and record what would make it `MEASURED`. A removed
claim creates pressure to resolve; a qualified one releases it.

**Failure prevented:** a report whose numbers are each correct and whose sentence is not,
because a denominator, a scope or a threshold entered it from somewhere other than the
artefact — and no reader, the author included, can tell which sentence.

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


## 3b. Declare instrument lineage before claiming corroboration

Tools are not independent because they are different programs. Trace each
instrument's provenance to the work that built its models, and declare it.

**Do:** for every detector, model, or reference database, record the publication
lineage its profiles descend from. Two tools descending from one lineage cannot
corroborate each other, and "multiple tools agree" is not two-source evidence
when they share a parent.

**Do:** state the lineage in the methods, not only in analysis notes. A reader
cannot assess independence they cannot see.

**Failure prevented:** a corroboration claim that is true by construction.

---


## 4. Independence before agreement

Two methods agreeing is evidence **only if they can disagree**. Methods sharing a hidden
dependency agree whenever that dependency is wrong.

**Do:** declare each method's **evidence sources** as a set, then compute the Jaccard
distance between source sets as a **provenance-overlap indicator**. Assert it; do not assume it.

⚠️ **Do NOT treat that number as a validated measure of methodological independence.** It
detects *shared provenance*, which is one cause of correlated error and not the only one —
two methods with disjoint source sets can still share an assumption, a preprocessing step,
or an author. A high score is weak evidence of independence; a **low** score is strong
evidence of dependence, and that asymmetry is where its value lies. Use it to *disqualify*
pairs, never to certify them.

**Do:** declare the acceptance rule **before** computing the matrix — e.g. *"a claim is
admissible only if two methods agree whose provenance overlap is below X, at least one has
circularity NONE or LOW, and the shared-assumption check below has been answered in writing"*.

**Do:** answer in writing, for every pair you rely on: *what would make BOTH of these wrong
at once?* A pair with no such answer has not been shown independent, whatever the score.

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

**Do:** apply the asymmetry to **join and availability negatives**, not only to scientific
ones. *"No producing script exists"*, *"the residues are on disk nowhere"*, *"no overlap"* —
each is a negative claim, and each needs a positive control: an input **known to be present**
that the same search recovers. A search that returns zero and was never shown capable of
returning non-zero has not measured absence, it has failed silently.

**Do NOT:** accept a specificity control in place of one. Perturbing known inputs and
confirming they no longer match bounds false positives; it cannot reveal a wrong key, a wrong
file format, an unnormalised terminal character, or an unswept root — every one of which
returns a clean, convincing zero.

**Do:** validate the **check itself** on a case it must FAIL, never only on a case it must
pass. A sweep, lint, checksum, liveness probe or guard that has only ever run on inputs it
should accept has not been tested — it has been demonstrated. **Seed a known-bad input,
confirm the check fires, remove it, then run for real, and record that you did.**

**Failure prevented:** the most common error in corpus and provenance work, and the hardest
to see, because a negative that is wrong looks exactly like a negative that is right — and
because a self-blind harness reports success in the voice of a working one.

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
- [ ] **instrument lineage** declared for every detector; no corroboration claimed
      across tools sharing a parent
- [ ] every claim graded `MEASURED` / `DERIVED` / `INFERRED` — **per claim, not per
      figure** — with negatives and unexamined tool defaults graded on the same rule
- [ ] every **availability or join negative** carries a positive control that recovers a
      known-present case, and names the roots and keys swept
