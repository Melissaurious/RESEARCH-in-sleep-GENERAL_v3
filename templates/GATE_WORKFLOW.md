# Running one gate — unattended

One gate = one measurement = one bundle = one branch. **The operator is not in this loop**
(WA-A.1): they wrote the launcher, and they read the bundle in the morning.

## Preflight

```bash
git fetch origin && git checkout -b <gate> origin/main
bash general/checks/specs_exist.sh                                   # must print OK
python general/tools/check_launcher.py launchers/LAUNCHER_<track>.md # must exit 0
bash general/tools/review.sh --check <gate>                          # reviewer reachable?
```

If `check_launcher.py` fails, **stop — do not infer the missing field and do not wake the
operator.** Log it in `docs/BLOCKED.md` as a launcher defect and halt (WA-L.2, WA-S.1).

## 1 — PLAN, then the first gate

Enter plan mode: read, search, run read-only commands, write nothing. The harness refuses the
write, so "no scripts yet" is enforced rather than intended.

The plan must name: the measurement and the exact scripts · the population each denominator
equals and its independent second count (WA-D.3) · thresholds fixed in code before scoring ·
the positive control for every expected zero · each method's circularity grade · where it
runs and why (`tools/dispatch.py --explain`, output pasted in) · the declared weight.

First action out of plan mode is `ARIS_OUTPUT/<gate>/PLAN.md`. Then:

```bash
bash general/tools/review.sh --plan <gate>
```

**Exit 0 → execute. Exit 1 → fix every BLOCKER and re-run.** Three rounds, then halt and say
it was a budget-halt, never a pass (WA-A.3). The agent never writes its own verdict (WA-A.2).

## 2 — EXECUTE

**Phase A — compute only.** One script per task, run each immediately after writing it,
`--limit` first. Every declared control runs **before** the full pass and is watched FAILING
on a seeded-bad case before it is trusted. Smoke-test on a throwaway slice, never on the
control fixture. No prose conclusions.

**Run `run.sh` as soon as it exists**, not once at the end — it must resolve paths against the
*bundle* layout, not the scratch layout, or it reruns nowhere.

**Phase B — one interpretation round** over all tables together. Counts, not conclusions. A
refutation is a result and lands like any other (WA-G.5).

## 3 — LAND

Per `agreements/BUNDLE_SPEC.md`:

```bash
conda env export --no-builds > results/<GATE>/env.lock
sha256sum results/<GATE>/env.lock            # -> PROVENANCE.md
bash general/tools/general_sha.sh            # -> the governance revision this recorded
```

`PROVENANCE.md` carries `seed:` (a number, or `n/a - <why>`) and `models:`. Silence is not
permitted for either. The bundle README carries n_attempted / n_succeeded / n_dropped and why
— **never footnote a failure** — what changed from the plan, and the two mandatory non-empty
sections from `REPORTING_STANDARDS`.

## 4 — the second gate

```bash
bash general/tools/review.sh --result <gate>
```

**Exit 0 → seal and push. Exit 1 → fix and re-run**, same three-round budget.

```bash
bash general/checks/bundle_valid.sh --write-outputs results/<GATE>   # seal, LAST
bash general/checks/bundle_valid.sh results/<GATE>
```

Then **rerun `run.sh` and confirm it reproduces the number.** The validator passing is not
verification: it checks that files exist and hashes match; only a rerun re-derives (WA-B.2).

Push when the bundle is accepted, not before. Scratch never enters git.

## 5 — RETRO

`retros/YYYY-MM-DD_<gate>.md`: did the stop condition hold, or move after seeing the result?
Census or estimate — did the report say which? Did every rate name its population, and did the
second count agree? A positive control for every negative claim? Which checks fired, and which
should have and did not? What did the reviewer withdraw or weaken?

Anything to fold into the agreements needs the case it would have caught **and** a case it
would wrongly reject. **A session proposes, never amends.** A rule named in a retro and not
landed in a spec does not exist (WA-S.2).

`/clear` at gate boundaries, never mid-gate. Compacted twice means the gate was two gates.
