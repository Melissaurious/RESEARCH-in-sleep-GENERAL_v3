# Running one gate — plan → approve → execute → accept → retro

One gate = one measurement = one session = one bundle = one branch. This is the shape of a
single session. The **track** it belongs to is defined by its launcher; this document is what
happens inside one gate of it.

## Before starting

```bash
git fetch origin && git checkout -b <gate-id> origin/main     # WA-R.4
bash general/checks/specs_exist.sh                            # must print OK
bash general/checks/rules_current.sh                          # sweep EXPIRED / DUE
```

The gate's stop condition is written in `ROADMAP.md` **before** the gate starts (WA-R.2), and
its claim exists in `CLAIMS.md` as UNPROVEN (CL-1).

## Phase 1 — PLAN (approval gate; nothing heavy runs yet)

**Enter plan mode first.** In plan mode the agent can read, search and run read-only commands
but **cannot write files or run mutating ones**. That converts "do not write scripts yet"
from an instruction the agent may drift past into something the harness refuses — the same
difference as `chmod a-w` versus intending not to edit the data (WA-D.1).

Ask for recon and a plan, and stop there. The plan must name:

- the measurement, and the exact scripts
- **the population each denominator equals, and the second, independent count of it** (WA-D.7)
- the declared thresholds, fixed in code before scoring (EVIDENCE_STANDARDS §5)
- the positive control for every expected zero (§6) — and the acknowledgement that a census's
  zeros cannot all be enumerated in advance, so extending the control after the first pass is
  a normal step, not an improvisation
- the circularity grade of every method (§3)
- where it runs and why (`general/site/COMPUTE.md`)

You review the plan. Cut, add, correct. **This is the checkpoint** — the one place where
redirection is cheap.

**On approval, the first action out of plan mode is to write the plan to
`ARIS_OUTPUT/<gate>/PLAN.md`** — before any script. A plan that exists only in the session is
not a record (WA-S.2): it dies with a compaction, a crash, or `/clear`. `PLAN.md` is what a
resumed session reads, and what the retro is written against. It is scratch, gitignored, and
dies with the gate. What survives is the bundle and the retro.

## Phase 2 — EXECUTE

**Phase A — compute only.** One script per task, run each immediately after writing it,
`--limit` first. Every declared control runs **before** the full pass and is watched FAILING
on a seeded-bad case before it is trusted (WA-A.3, §6). Smoke-test on a throwaway slice,
never on the control fixture (WA-E.3). No prose conclusions.

**Run `run.sh` as soon as it exists, not once at the end.** BS-3 means the assembled bundle's
layout, which is not the scratch layout; a `run.sh` written against scratch resolves every
self-relative path one level too shallow and reruns nowhere.

**Phase B — one interpretation round** over all tables together. Counts, not conclusions. A
refutation is a result and lands like any other (CL-3).

Then the bundle, per `general/agreements/BUNDLE_SPEC.md`:

```bash
conda env export --no-builds > results/<GATE>/env.lock       # BS-8
sha256sum results/<GATE>/env.lock                            # -> PROVENANCE.md
bash general/tools/general_sha.sh                            # -> agreements: (BS-10)
```

`PROVENANCE.md` also carries `seed:` — a number, or `n/a - <why>` (BS-9) — and `models:`,
the model or models that produced it (BS-15). Silence is not permitted for either.

The README carries STATUS, n_attempted/n_succeeded/n_dropped, the counts that look bad
(BS-5), what changed from the plan, **the six adversarial answers** (BS-14), and a paste-ready
block of the proposed `CLAIMS.md` and `ROADMAP.md` edits for the operator to apply.

## Phase 3 — ACCEPT

Rerun `run.sh` and confirm it reproduces the number. Then seal — `OUTPUTS.tsv` is written
**last**, after `README.md` carries its final `STATUS:` line, because acceptance edits the
README and would otherwise invalidate the hashes it just recorded:

```bash
bash general/checks/bundle_valid.sh --write-outputs results/<GATE>   # BS-11
bash general/checks/bundle_valid.sh results/<GATE>
```

**The rerun is the real gate.** The validator passing is not verification: it checks that
files exist and hashes match; only a rerun re-derives (WA-B.2). Then open `INPUTS.tsv`
yourself and recognise the inputs — that half is not automatable and is not optional.

## Phase 4 — RETRO

Write `retros/YYYY-MM-DD_<gate>.md`:

- Did the stop condition hold, or was it moved after seeing the result?
- Census or estimate — and did the report say which (WA-D.2)?
- Every claim graded MEASURED / DERIVED / INFERRED, per claim not per figure (§1c)?
- Did every rate name its population, and did the second count agree (WA-D.7)?
- Positive control present for every negative claim (§6)?
- Any check that fired — and any that should have and did not?
- What did the adversarial answers (BS-14) withdraw or weaken?
- Anything to fold into the agreements. A new rule needs the case it would have caught **and**
  a case it would wrongly reject (WA-A.1) — and a session proposes, never amends.

Sweep `rules_current.sh` while you are here (WA-A.2).

## Between gates

`/clear` at gate boundaries, never mid-gate (WA-S.1). If you have compacted twice, stop,
commit, and start fresh — the gate was too big and is two gates (WA-R.3).
