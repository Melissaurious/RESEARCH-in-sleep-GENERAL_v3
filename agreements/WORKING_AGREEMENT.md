# WORKING AGREEMENT — v6

The behaviour spec for every project governed by this layer. **Self-contained.** Nothing
here requires reading an earlier version of this document, an earlier project tree, or any
folder outside the project being worked on. Where a rule was earned by a real past failure,
the failure is described and dated in its `validated:` line — the description is the
evidence, and no path is given. `LINEAGE.md` is the single place where superseded trees are
named, and it is read only when a launcher or prompt explicitly sends you there.

Every rule has an ID, a scope, and a check.

    WA-x.y  [ALWAYS|WHEN <situation>]  <statement>
      check:     <script in checks/, or "manual">
      validated: <the real case it caught, dated. or "PROVISIONAL <date>">

**Budget: at most 25 ALWAYS rules.** They are paid on every turn of every session. Adding
one requires deleting one or demoting it to WHEN. There is no cap on WHEN rules — they are
paid only when their situation arises. *Currently **25 ALWAYS** — the budget is FULL. The next ALWAYS rule requires deleting one or demoting it to WHEN; that is the point of the cap, and 33 WHEN rules is not a problem.*

---

## L — Launchers and tracks: how work is scoped

**WA-L.1** [ALWAYS] Every track has a launcher, written before the track starts. The
launcher is the authority on scope for every session in that track: its write boundary, its
inputs and their trust grades, its gates, its out-of-scope list, and its stop conditions.
A session's own reading of what the work "obviously" needs does not override it.
Full spec: `agreements/LAUNCHER_SPEC.md`.
- check: `manual` — the track's launcher exists and names all six required sections
- validated: 2026-08 — an unlaunched stage line accumulated 43 output directories, 37 with a
  FINDINGS.md and only 12 with a PLAN.md: a tree recording what happened rather than what
  was intended

**WA-L.2** [WHEN a launcher declares LOOPED] Every gate declares a mode. **SINGLE-PASS**
(the default, and what an undeclared mode means) — do the task, write STATUS, halt.
**LOOPED** — iterate until a declared stop condition is met; permitted only when the
launcher's stop condition **contains a number**, and only for work that is LOW-STAKES under
WA-S.4.

> **A loop may DRIVE but may not ACQUIT.** It decides whether a step is complete. It never
> decides whether a result is correct or good enough. Quality verdicts come from an
> independent reader or from the operator (WA-I.1).

Every loop halts on any of: the stop condition met; two consecutive rounds with no change to
the measured quantity; the declared round budget exhausted. A loop that has halted on the
budget says so — a budget-halt and a condition-halt are different outcomes and are never
reported as the same one.
- check: `manual` — the launcher's stop condition contains a number, or the mode is not LOOPED
- validated: PROVISIONAL 2026-09-08

**WA-L.3** [WHEN a track declares its inputs] Every input carries a trust grade, assigned in
the launcher before the track starts: **RAW** (primary, unprocessed) · **FROZEN** (settled
here, names the bundle that settled it) · **RE-DERIVE** (a value exists but has not been
recomputed under current standards — usable only after WA-D.6) · **DO-NOT-USE** (known
defective; the launcher says why). An ungraded input is DO-NOT-USE by default.
- check: `manual` — the launcher's input table has a grade in every row
- validated: 2026-08 — a verification track was commissioned because two load-bearing
  numbers had never been re-derived and nothing recorded which ones those were

---

## R — The track and the gate: how work is shaped

**WA-R.1** [ALWAYS] Work is shaped by a **track**, containing one or more **gates**. A gate
names exactly one measurement and emits exactly one bundle. "Explore X" is a note, not a
gate. The track is the unit of scope; the gate is the unit of a number.
- check: `manual` — reading the launcher and ROADMAP
- validated: 2026-09-04 — nine stages ran with no stop condition and produced zero bundles

**WA-R.2** [ALWAYS] A gate's stop condition is written before the gate starts, in the form:
*done when `results/<GATE>/` exists and re-running `run.sh` from the hashed inputs reproduces
the number.* A stop condition rewritten after seeing a result is a new gate, and the retro
says so.
- check: `manual`
- validated: 2026-09-04 — as WA-R.1

**WA-R.3** [ALWAYS] A gate must fit in one session before the first compaction. If it does
not fit, it is two gates. Quality falls after compaction because the model then works from a
summary of a summary.
- check: `manual` — if you have compacted twice, stop and re-scope
- validated: PROVISIONAL 2026-09-08

**WA-R.4** [ALWAYS] The next gate starts from `origin/main`, never from the working tree.
Unpushed work does not carry forward.
- check: `manual` — `git status` clean and `git log origin/main..HEAD` empty at gate start
- validated: PROVISIONAL 2026-09-08

**WA-R.5** [ALWAYS] A gate that produces no provenanced artifact has produced no result. It
may be correct and necessary; it is not evidence and is not progress.
- check: `checks/bundle_valid.sh`
- validated: 2026-09-04 — 141 documents and nine stages, zero bundles

**WA-R.6** [WHEN landing a gate] A branch is pushed when the bundle is ACCEPTED:
`bundle_valid.sh` passes, `run.sh` has been rerun and reproduced the number, and the operator
has recognised the inputs. Not before. Scratch never enters git — a script that did not
produce the landed number is not "work in progress", it is scratch, and it dies with the
scratch directory.

**A null or refuting measurement is a result and lands like any other.** *Verified* means the
number is reproducible, not that it is the number you wanted. What is withheld is broken
intermediate work, never an unwelcome finding.

A gate abandoned without a measurement lands as `dropped` in ROADMAP.md with its reason, and
a retro. It does not land as code. Infrastructure commits — this layer, its checks, its
templates — are not gates and are not governed by this rule.
- check: `manual` — at push time `results/<GATE>/` exists and `bundle_valid.sh` passes
- validated: 2026-09-04 — *would have caught:* a tree that pushed 141 documents and nine
  stages with zero bundles, so the remote recorded process instead of results.
  *Would wrongly reject:* a gate whose measurement came back null or refuted the hypothesis.
  Without the second paragraph this rule suppresses exactly the negatives EVIDENCE_STANDARDS
  §6 requires — which is why it is scoped to reproducibility, never to whether a result is
  welcome.

---

## D — Data and measurement

**WA-D.1** [ALWAYS] Never modify source data or original scripts. Inputs are read-only,
enforced by file mode (`chmod a-w`), not by intention.
- check: `manual` — `find <data> -writable` returns nothing; `Bash(chmod:*)` denied in settings
- validated: 2026-09-04 — this was prose for months and was violated; it is now a file mode

**WA-D.2** [ALWAYS] A **census** is exact; an **estimate** declares itself.

*Census* — any count, percentage, total or rate over a corpus that lands in a table, figure,
cache or report is computed EXACTLY over all records, never extrapolated from a sample. If a
file exceeds memory, stream it record-by-record in bounded memory. If an exact pass is too
heavy for the local machine, move it to the cluster — never downgrade to sampling to stay
local.

*Estimate* — a statistical quantity (a bootstrap or analytic CI, a cross-validated score, a
permutation or null-model result, a subsampled benchmark) is not an approximation of a census
and is fully permitted. It declares its **estimator, its n, and its interval**, and carries
the word *estimate* wherever it appears — including in the column name, so a quoted value
carries the label with it.

A `--limit N` smoke test is neither: it is throwaway, labelled an estimate, and never
reported.
- check: `manual` — a reported figure is one or the other, and says which
- validated: 2026-09-04 — an earlier form said "never estimated from a sample", which
  outlawed every CI and null model the goals required. A rule can be followed literally and
  still be wrong.

**WA-D.3** [ALWAYS] Probe a field's actual values on real records before designing any
analysis, cache, or figure around it. A documented schema describes the data as *intended*,
not as it *is*. When values diverge from the contract, the values win, and the correction is
folded back into the contract.
- check: `manual`
- validated: 2026-08 — a lineage string filed under an `ecosystem` column; a "direction"
  field 97.7% null and not a direction; a clip flag structurally always false. Later, in the
  same corpus: one field pooling the output of two different tools, which agreed on only
  44.6% of shared cases, so any `groupby` on the pooled field was meaningless.

**WA-D.7** [ALWAYS] Every reported rate names the **population** its denominator equals —
not the file, not the glob, not the dataframe: the population, in words a reader can check.
The bundle carries a control measuring that population's size by a route sharing no code
with the producing script. Where no independent route exists, the bundle records *why*, and
the rate is graded `DERIVED` rather than `MEASURED`.
- check: `manual` — every rate in `tables/` has a named population and a second count
- validated: 2026-08-25 — *would have caught:* one glob idiom in three scripts swept a merged
  all-records table in alongside the 43 per-family tables it meant to read, inflating three
  claims' denominators. The arithmetic identity `423,286 + 501,561 = 924,847` is what
  eventually exposed it. **The defect reproduced perfectly on every rerun**, so no hash, no
  environment pin and no re-execution gate could have caught it — only a second count of a
  named population.
  *Would wrongly reject:* a denominator that has no second route by construction — e.g. a
  count of distinct sha256 values over a set of sequences, where the only other route is the
  same pass over the same strings. Forcing a control there manufactures a fake one, which is
  worse than none. Hence the recorded-exception clause.

**WA-D.4** [WHEN a corpus is too expensive to re-read] An extraction pass is maximally
retentive: it keeps every field it touches, not the subset today's questions need. The cost
of carrying a column is bytes; the cost of a missing one is a re-read.
- check: `manual`
- validated: 2026-09-06 — a carried column that no plan predicted turned out to be the most
  discriminating variable in the gate, and characterising two classes cost no second pass

**WA-D.5** [WHEN reusing an expensive intermediate] Never recompute. Intermediates go to the
gate's `cache/`, keyed by a hash of **inputs + parameters** — never by a name, a date, or a
stage number. Check cache before computing and log hit or miss. If a cached result cannot be
reused, say why.
- check: `manual`
- validated: 2026-08 — caches keyed by something other than their input were reused across
  changed inputs and produced wrong numbers rather than errors

**WA-D.6** [WHEN re-deriving a value that already exists] The prior value may not enter the
session's context before the derivation is written and run. Read scripts, schemas and method
sections freely; read result tables and prose only afterwards, as a comparison. If the two
agree, the bundle states whether it *could* have failed to agree — a shared input or a shared
instruction guaranteeing the match is not evidence.

> **A script containing the number it is trying to reproduce is not a derivation.**

**Scoped to re-derivation. Reconciliation is exempt and is the stronger design** — where the
prior value is an input to an *assertion* (the run fails if they disagree) rather than an
input to the *computation*.
- check: `manual` — the producing script does not contain the target value as a literal
- validated: 2026-09-06 — *would have caught:* a settled-baseline file several of whose rows
  were typed by hand, matched no script output, and were inherited as verified by a later
  track. *Would wrongly reject:* a gate that reads two prior bundles' tables at run time and
  exits non-zero on any disagreement — 173 reconciliation rows, 0 disagreements — which is
  better than blind re-derivation. The distinguishing test is whether the prior value is an
  input to the computation or a comparison after it.

---

## B — The bundle: how a number enters the repository

**WA-B.1** [ALWAYS] A number enters the repository only inside `results/<GATE>/`, with its
script verbatim, its inputs hashed, its environment locked by content, its seed declared, its
command recorded, and the revision of this layer it ran under. Full spec:
`agreements/BUNDLE_SPEC.md`.
- check: `checks/bundle_valid.sh`
- validated: PROVISIONAL 2026-09-08

**WA-B.2** [ALWAYS] A gate is done when `run.sh` reruns and reproduces its number. A
validator passing is not verification — `bundle_valid.sh` checks that files exist and hashes
match; only a rerun re-derives.
- check: `manual`, and it is the real gate
- validated: 2026-09-06 — the validator passed a bundle that could not reproduce its own
  table, because a wall-clock timing was a column inside a census table and every rerun
  therefore differed

**WA-B.3** [WHEN landing or correcting a bundle] Bundles are write-once. A correction is a
new bundle with a new id naming its predecessor. Never edit a landed bundle.
- check: `checks/bundle_valid.sh` (BS-11) + `Edit(results/*/MANIFEST.tsv)` denied in settings
- validated: 2026-09-05 — *would have caught:* a period in which only four bundle files were
  protected, and the README, `run.sh`, `scripts/` and **every result TSV** were freely
  editable; the validator hashed inputs and environment but nothing the bundle produced, and
  passed a bundle whose number had been changed after it landed.
  *Would wrongly reject:* EVIDENCE_STANDARDS §7, which requires a correction to amend in
  place with both values visible. The two do not collide: §7 governs living documents and the
  claim ledger, where the audit trail IS the file; this rule governs bundles, where the audit
  trail is a new bundle naming its predecessor.

**WA-B.4** [WHEN writing a bundle README] Counts are reported so defects are visible:
n attempted, n succeeded, n dropped and why. Never footnote a failure. A non-zero "missing
provenance" or "scripts ABSENT" count is fixed before publishing, never explained away.
- check: `manual` — reading the bundle README
- validated: PROVISIONAL 2026-09-08

---

## C — Concurrency and execution safety

**WA-C.1** [ALWAYS] One agent process writes to one checkout at a time. A second reader may
think, review, and pair on design at any time; it may not hold open file handles on a tree
another agent is writing.
- check: `checks/no_concurrent_writer.sh` (SessionStart hook)
- validated: 2026-08-31 — files appeared mid-run during a stage and were recorded as blocked

**WA-C.2** [ALWAYS] One writer per output directory. A directory is owned by the run that
created it; a second run gets a NEW path, never a reused one — no exception for "the old one
is dead". A directory two writers touched is renamed `*_CONTAMINATED_<date>` and quarantined,
never repaired in place.
- check: `manual`
- validated: 2026-08-31 — as WA-C.1

**WA-C.5** [ALWAYS] Never `rm` inside a directory you did not create this session. To discard
a run, **rename** it. Renaming is reversible and preserves evidence. Relaunching into an
existing path, and killing a process you did not start, are HIGH-STAKES: stop and ask.
Never kill by pattern — a pattern match includes the matching process's own invocation.
- check: `Bash(rm:*)` denied in `.claude/settings.json`
- validated: 2026-08 — a pattern kill matched and terminated the tool call issuing it

**WA-C.6** [ALWAYS] A track declares exactly one writable directory. Everything else is
read-only for its sessions, enforced by `sandbox.filesystem.allowWrite` in settings, not by
instruction. The single exception is a **registered derived artifact** whose path is named in
the launcher before the track starts and which enters the data register with its hash.
- check: `manual` — settings' allowWrite matches the launcher's write boundary
- validated: 2026-08 — *would have caught:* writes into a neighbouring stage's tree, which
  produced wrong numbers rather than errors because the reader could not tell which run had
  written what. *Would wrongly reject:* a gate that legitimately materialises a large derived
  view for later gates to read instead of re-streaming the raw corpus — which is now standard
  practice. Hence the registered-artifact exception.

**WA-C.3** [WHEN judging whether a run is alive] Liveness is a claim and carries a grade.
"That run is dead" is INFERRED unless both the process table AND the directory's newest mtime
have been checked and recorded. A job that has written nothing for ten minutes is not dead.
An exit code in 128–160 is a signal, not an error.
- check: `manual`
- validated: PROVISIONAL 2026-09-08

**WA-C.4** [WHEN a check may kill a process] A liveness check must be validated on a live
process before it may kill anything. A check that has only ever said "dead" has not been
tested.
- check: `SELFTEST=1 bash checks/no_concurrent_writer.sh`
- validated: 2026-09-04 — watched rejecting a tree held by a live pid, and acquiring a free one

---

## K — Compute

**WA-K.1** [WHEN a job will exceed 10 min] Choose the machine deliberately: check current
load and free accelerators, and state in the plan where the job runs and why. The escalation
thresholds, queue account and environment activation for this installation are site
parameters and live in `site/COMPUTE.md`. Everything else in section K is general.
- check: `manual` — the plan names the machine and the reason
- validated: PROVISIONAL 2026-09-08

**WA-K.2** [WHEN submitting to a queued partition] Validate the harness in a short (~60 s)
interactive session first — interpreter path, module availability, entrypoint existence,
critical imports. A trivial harness bug costs seconds of compute but hours of queue latency.
A module listing can be empty even when the software is installed, and dependencies usually
live under a named environment, not the base one. Put a one-line import preflight in the
batch script too.
- check: `manual`
- validated: 2026-08 — repeated queue-latency losses to harness bugs

**WA-K.3** [WHEN sizing a real job] Size from measurement, not from guessing: run the smoke
test, RECORD its per-unit timing, and size as measured-rate × N.
- check: `manual`
- validated: PROVISIONAL 2026-09-08

**WA-K.4** [WHEN running a smoke test] The smoke sample must be representative — drawn across
the input's size/length distribution (random or length-stratified), never the head of the
file, and run under the same device contention as the real job.
- check: `manual`
- validated: 2026-08 — a head-sampled, uncontended smoke measured 11.1 s/unit against
  28.3 s/unit actual, a 2.5× under-estimate, for exactly those two reasons

**WA-K.5** [WHEN queuing more than one job] Submit cheap high-value jobs BEFORE large arrays.
Fairshare is consumed by what you already ran, so a big array launched first can price a
small gating job out of the queue. Requesting more accelerators LOWERS priority: the fastest
wall-clock is the fewest resources that still finish in the window.
- check: `manual`
- validated: PROVISIONAL 2026-09-08

**WA-K.6** [WHEN a standard algorithm is needed] Check what already exists before
implementing: the project's own earlier gates, the installed binaries, and the source
repository of any tool already in use. State explicitly which part of what you deliver was
ported and which was written new.
- check: `manual` — the plan names what was searched and what was found
- validated: 2026-09-01 — a tool reported absent had in fact been installed; the "absent"
  claim was scoped to two environments and never re-checked

---

## E — Editing, debugging, and tool trust

**WA-E.4** [ALWAYS] Verify before claiming done. Exit code and file existence are NOT
sufficient; validate content — bytes, parseability, expected record count, an asserted
invariant. Ask what a passing check actually COVERS. → `agreements/EVIDENCE_STANDARDS.md` §1.
- check: `manual`
- validated: 2026-08 — a filename was treated as a verification for four of five input sets,
  and a manifest recording `ran: False` was read as a pass

**WA-E.1** [WHEN editing code] Locate, then patch. Use `grep -n` / `rg` to find exact lines,
`sed -n 'A,Bp'` to view a range, then edit just those lines. Never regenerate a whole file to
fix a few lines; if a rewrite is truly needed, say why first.
- check: `Bash(sed -i:*)` denied in `.claude/settings.json`
- validated: PROVISIONAL 2026-09-08

**WA-E.2** [WHEN writing a script] One script per task, ≤200 lines; no function over 50
lines; type hints and a docstring on every public function. Run each script after writing it
— never hand back untested code. A project may raise the line limit in its own CLAUDE.md,
and an overrun is stated in the bundle README rather than fixed by fragmenting a file.
- check: `manual`
- validated: 2026-09-06 — a census script landed 15 lines over; splitting it would have
  separated the declared thresholds from the code walking them, and the honest move was to
  state the overrun

**WA-E.3** [WHEN a script touches real compute] It must accept `--limit N` or `--dry-run`,
and be run on a tiny subset before the full launch. **Smoke-test on a throwaway slice, never
on a control fixture** — the fixture is an instrument, and using it to debug the thing it
measures turns a blind control into a confirmatory one.
- check: `manual`
- validated: 2026-09-06 — a census was debugged against its own control fixture, exposing
  seven counters before the hand tally was written

**WA-E.5** [WHEN a script emits counters] A counter that can only be created by a branch is
initialised to zero before the pass. A zero absent from a table is not a zero, it is a
silence.
- check: `manual`
- validated: 2026-09-06 — a strand-mismatch counter would not have appeared in the output at
  all, and an invisible zero is indistinguishable from an unasked question

**WA-E.6** [WHEN using an external tool] Open its flags before trusting its defaults, and ask
what object its output actually contains. Grade the tool by execution on real project data,
never by presence. → `agreements/EVIDENCE_STANDARDS.md` §2.
- check: `manual` — the grade and the exact working invocation are recorded
- validated: 2026-09 — an installed annotation suite shipped a stub reference database of
  3–4 profiles where thousands were expected; it ran, exited 0, and produced almost nothing.
  Only counting the profiles detected it.

---

## P — Process budget

**WA-P.1** [ALWAYS] Answer a problem with a measurement before answering it with a document.
Process accumulates because it is cheap to write and feels like progress.
- check: `manual` — if a gate's markdown count exceeds its bundle count, say so and why
- validated: 2026-09-04 — 141 documents, 0 bundles

**WA-P.2** [ALWAYS] Per week: at most one new process document, at least one bundle. Two
consecutive weeks below the floor means the roadmap is wrong — stop and rewrite it rather
than trying harder.
- check: `manual` — count `results/*/` against `git log`
- validated: PROVISIONAL 2026-09-08

**WA-P.3** [ALWAYS] A rule that could be a script must be a script. A paragraph is an
intention, not a check.
- check: `manual`
- validated: 2026-09-04 — "never modify source data" was prose for months; it is now a file
  mode (WA-D.1)

**WA-P.4** [ALWAYS] Rules live in exactly one place. A rule restated in a second document is
a rule with two versions and no owner. A project's own CLAUDE.md declares only what this
layer cannot know — its subject, its environment, its paths, its overrides — and points here
for everything else.
- check: `checks/specs_exist.sh` — every referenced path resolves
- validated: 2026-09-08 — *would have caught:* a governance tree that declared itself
  superseded and was still named as the master by 19 files across a live project, including
  that project's own CLAUDE.md. *Would wrongly reject:* a launcher that deliberately quotes a
  rule inline so a track can be run by someone who has not read this file — which is
  legitimate and is why LAUNCHER_SPEC requires quoted rules to carry their rule id, so the
  copy is traceable to the original rather than competing with it.

---

## A — Amendments

**WA-A.3** [ALWAYS] A check is validated only by watching it FAIL on a case it must reject,
AND accept a case it must accept. Passing on a good case alone proves nothing.
- check: `manual`
- validated: 2026-09-04 — a path check rejected 12 valid references; it had only ever been
  watched failing, never accepting

**WA-A.1** [WHEN proposing a rule] A proposed rule must name the case it would have caught
AND a case it would wrongly reject. No second case, no rule. The second case is the one that
fixes the scope; a rule with only the first is usually too broad.
- check: `manual`
- validated: 2026-09-08 — every rule added in this revision was narrowed by its second case,
  and two were narrowed enough to change what they forbid

**WA-A.2** [WHEN sweeping this file at a retro] A rule marked PROVISIONAL expires 14 days
after its date unless a `validated:` line naming a real case is added. A rule's date moves
forward only when a real case is named for it — so renewals stagger by when work actually
exercised each rule, instead of every rule falling due on the day it was written.

**A rule no gate has ever exercised is deleted or demoted to WHEN — never renewed.** Renewal
in a batch is the failure mode: it converts an expiry date into a formality.
- check: `checks/rules_current.sh` — buckets rules as EXPIRED / DUE / PROVISIONAL
- validated: PROVISIONAL 2026-09-08

**WA-A.4** [WHEN removing a rule] Deleted rules go to the graveyard with a reason, and are
not re-proposed without new evidence. A rule deleted because it referenced a missing file may
be re-proposed once that file exists — that is new evidence.
- check: `manual`
- validated: 2026-09-08 — a mandate was deleted for referencing tools absent from one
  project; the tools existed and were simply never carried across, which is precisely the
  new evidence this clause admits

---

## I — Record and interpretation

**WA-I.1** [ALWAYS] Whether a result supports a claim, whether a goal is met, whether to keep
going: the operator's call, always. Never delegated. Measure, record, and report the counts
including the ugly ones. Do not conclude.
- check: `manual`, and it is not automatable
- validated: PROVISIONAL 2026-09-08

**WA-I.2** [WHEN a result enters the paper] A result that has passed every gate is not a
finding until the operator can state, in their own words and in one paragraph, why it is
true. Not the session's summary — theirs. If they cannot, it does not enter the paper,
however many reviewers passed it.
- check: `manual` — the paragraph is written in the bundle README
- validated: PROVISIONAL 2026-09-08

**WA-I.3** [WHEN an artifact comes from outside this project] It is not evidence here. It
enters only when a gate needs it, in one of three states: **RE-DERIVED** (recomputed here
under current standards — usable); **BLIND-CONFIRMED** (independently recomputed without
sight of the prior value, and the two agree — usable, and stronger); or **[UNVERIFIED]**
(carried for orientation only — may not appear in a figure, a table, or the paper). Auditing
a foreign tree wholesale is out of scope; verification is paid per artifact, at the point of
use.
- check: `manual`
- validated: PROVISIONAL 2026-09-08

**WA-I.5** [WHEN a value is inherited as settled] The project's inherited-baseline register
has one row per value, and every row either **names the bundle that produced it** or carries
the tag `operator-supplied design fact` with the person and the date. The two kinds never sit
in one table untagged.
- check: `manual` — every row of the register has a bundle id or the tag
- validated: 2026-09-06 — *would have caught:* a baseline file instructing readers to take
  its numbers without recomputing, several of whose rows were hand-typed literals matching no
  script output, with a later track resting on them. *Would wrongly reject:* a genuine design
  fact with no producing script and never any — e.g. which detection tools were run over
  which subset of a corpus, which is load-bearing for every tool-comparison and is the
  operator's knowledge, not a measurement. Forcing a bundle id on it would lose it or
  fabricate one.

**WA-I.4** [WHEN keeping the research record] Four node types, nothing skips a layer: **paper**
(enters via ingest, never freehand), **claim** (born UNPROVEN, carries its scope and
circularity grade at birth), **experiment** (links to its bundle), **idea** (ranked, with the
claims it would test). A claim becomes VERIFIED only after an audit verdict AND the
operator's explicit sign-off — never by a session's own judgment. REFUTED meets the same
standard; refutation is a result. Corrections amend in place with the superseded version
visible. Log paper → idea → experiment at the moment of reading; a bibliography is not a
provenance register and reconstruction after the fact is inference.
- check: `manual`
- validated: PROVISIONAL 2026-09-08

---

## V — Verification by a second reader

**WA-V.1** [WHEN two or more bundles have landed since the last pass] An adversarial read is
run by a **different model in a separate invocation**, reading commits it did not write. It
writes exactly one file, reports findings, and repairs nothing. Entry gates and the full
protocol: `tools/adversary.sh`, which enforces them rather than describing them.

> **Treat its findings as leads and its diagnoses as hypotheses.** The characteristic failure
> of an adversarial reader is *correct alarm, inverted diagnosis*. Verify the finding against
> the file before acting on the explanation.

If two consecutive passes produce no finding that survives verification, the gates are too
loose or the loop has stopped producing the kind of defect the pass catches. Say so, and
widen or stop — a reader that always agrees is a cost with no signal.
- check: `bash tools/adversary.sh --check`
- validated: 2026-09-07 — a pass found four defects no check could, and got its diagnosis
  backwards on a fifth, naming the well-formed rows as the defect and the broken ones as fine

**WA-V.2** [WHEN verifying another party's artifact] Pick an instrument that shares no
derivation with the artifact under test, and run an **exonerating control** — a case where
the artifact should pass — before writing any defect report. Two methods agreeing is evidence
only if they could have disagreed.
- check: `manual` — the report names the instrument's independence and the exonerating control
- validated: 2026-08 — defect reports were filed on the strength of instruments sharing the
  artifact's own derivation, so agreement was guaranteed and disagreement impossible

---

## S — Session hygiene

**WA-S.1** [ALWAYS] One session per gate. Close it when the gate closes. `/clear` at gate
boundaries, never mid-gate. Two compactions in one session means stop, commit, start fresh —
the gate was too big and is two gates.
- check: `manual`
- validated: PROVISIONAL 2026-09-08

**WA-S.2** [ALWAYS] A session is not a record. If it is not in git, it did not happen.
Transcripts are swept on a retention timer with no backup.
- check: `manual`
- validated: 2026-09-04 — a session containing unrecorded reasoning was already unrecoverable

**WA-S.3** [WHEN a gate closes] Write `retros/YYYY-MM-DD_<gate>.md`: what worked, what was
misunderstood, what to fix. Promote recurring lessons into this file — and sweep the
graveyard while you are here. A gate without a retro is unfinished.
- check: `manual`
- validated: PROVISIONAL 2026-09-08

**WA-S.4** [WHEN blocked or uncertain] Never guess silently and never stall. Append to
`docs/BLOCKED.md`, timestamped: what is needed, why, the options, the recommended default.
**LOW-STAKES** — reversible, contained, no compute >10 min, nothing written outside the
gate's scratch directory: take the default, log it, continue. **HIGH-STAKES** — deleting or
overwriting anything, large compute, changing a spec, moving a pin, publishing, anything
ambiguous about scientific interpretation: stop and wait.
- check: `manual`
- validated: 2026-08-31 — used correctly on a conflict over a sealed register

**WA-S.5** [WHEN writing a reply the operator will act on] Every operator-facing reply is
also a file, written under `responses/` or the gate directory. A reply that exists only in a
terminal cannot be quoted, diffed, or handed to another session intact.
- check: `manual`
- validated: 2026-09 — pasted terminal text arrived garbled at a parallel session and had to
  be reconstructed

---

## Graveyard

Rules removed, with the reason. Not re-proposed without new evidence (WA-A.4).

| Rule | Deleted | Why |
|------|---------|-----|
| "≤25 numbered rules" as a flat cap | 2026-09-04 | Counted rules read only situationally. Replaced by the ALWAYS/WHEN split: the cap applies to ALWAYS rules only. |
| per-artifact sidecar provenance mandate | 2026-09-04 | A second provenance system for the job the bundle already does. One mechanism, one check: the bundle. |
| a hygiene script named in a weekly ritual | 2026-09-05 | Named a script existing in no layer. It survived because the path check could not see a reference written in command form. The check now reads command-form references. |
| "one row = one measurement = one session" as the unit of scope | 2026-09-08 | Correct about the *number* and wrong about the *session*: it capped a session's ambition at one measurement, and every downstream scientific goal was deferred as a consequence. Replaced by the track/gate split (WA-R.1) — the gate keeps the property, the track carries the scope. |
| the dispatch/cache tooling mandate | 2026-09-04, **readmitted 2026-09-08** | Deleted for referencing tools absent from the project it was written in. The tools existed and had simply never been carried across; they now ship in `tools/`. Readmission is WA-A.4's new-evidence clause working as intended, and is recorded here rather than silently reversed. |

Graveyard entries name deleted things and deliberately do not link them: a dead reference in
a live document is what WA-P.3 is about.
