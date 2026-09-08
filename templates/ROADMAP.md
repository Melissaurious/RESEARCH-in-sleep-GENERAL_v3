# ROADMAP

One gate = one measurement = one session = one bundle = one branch (WA-R.1, WA-R.3).
**Exactly one gate is active.** A gate's stop condition is written here *before* the gate
starts (WA-R.2), in the form: *done when `results/<GATE>/` exists and re-running `run.sh`
from the hashed inputs reproduces the number.*

Gates belong to a track, and the track's launcher is the authority on scope (WA-L.1).

| gate | track | goal | claim | bundle | state |
|---|---|---|---|---|---|
| | | | | | queued |

States: `queued` → `ACTIVE` → `bundled` → `merged`. Or `dropped`, with a reason.

## Rules

RM-1  A gate names exactly one measurement. "Explore X" is not a gate (WA-R.1).
RM-2  A gate with no measurement is a note; it goes in `docs/log.md`, not here.
RM-3  The bundle id is filled by the operator after `bundle_valid.sh` passes AND `run.sh`
      has been rerun (WA-B.2). Never by a session.
RM-4  A gate open more than 2 weeks is rewritten, not retried.
RM-5  A gate that will produce any count of zero declares its positive control in its
      "Declared before the run" block (EVIDENCE_STANDARDS §6).
RM-6  The claim column is filled **before** the gate starts (CL-1).

---

## Source data (read-only, never modified — WA-D.1)

<paths, sizes, modes>

### Schema as observed, not as documented (WA-D.3)

<probed on real records, with the date>

---

## <gate-id>

**Measurement.** <one sentence>
**Mode.** SINGLE-PASS
**Stop condition.** done when `results/<gate-id>/` exists and re-running `run.sh` from the
hashed inputs reproduces <the number>.

**Declared before the run** (EVIDENCE_STANDARDS §5, §6):
- thresholds: <value, and why that value>
- the population each denominator equals, and its second count (WA-D.7)
- positive control for every expected zero: <how it is seeded>
