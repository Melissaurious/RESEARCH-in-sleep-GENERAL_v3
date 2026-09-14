# v6 audit — why it didn't feel efficient, and what to do

_2026-09-14. Written against `_import/v6` (VERSION 6.1.0). Every claim below was checked by
running something, not by reading. This document is deliberately short: the problem under
audit is document bloat, and a 400-line audit of it would be the same mistake._

---

## Verdict

**v6 is sound and should be adopted.** The rules are well-earned, the checks genuinely work
(75 selftest assertions, all passing, all validated in both directions), and the layer is
more rigorous than anything in v1–v5 or anything I wrote this session.

**It did not feel efficient for a reason that is already diagnosed inside v6 itself — and the
fix landed five days ago, probably after the experience that produced the complaint.**

Three real defects remain. One of them means **the adversarial pass has never been able to
run.**

---

## 1. Why it didn't feel efficient

`WA-B.5`, validated **2026-09-09**:

> *would have caught:* a project that applied census-grade control machinery to recon
> questions and spent days per measurement, **which the operator experienced as the method
> being slow rather than as a weight being mis-set**.

That is the complaint, named exactly, by the layer, before I got here.

Until 6.1.0 every gate paid the full control burden — positive control for every zero, the
denominator's independent second count, the hand-checked fixture — whether the number was a
throwaway recon count or the paper's denominator. `WA-B.5` splits that into **LIGHT**
(provenance skeleton only: inputs hashed, env locked, scripts verbatim, `run.sh` reproduces)
and **FULL** (the controls). Reproducibility stays non-negotiable at both weights; only the
control burden moves.

**So the efficiency fix exists and is five days old.** The open question is not whether v6
is too heavy — it is whether LIGHT was ever actually used. If every gate since 09-09 still
declared FULL, the rule is on paper only.

### The second-order problem, which is not yet fixed

v6 diagnosed "141 documents, 0 bundles" and responded with **61 rules, 5 checks, 2 spec
layers, a bundle format, tracks, gates, a generated index, and a rule that every operator
reply is also a file** (`WA-S.5`).

`WA-P.1` says *answer a problem with a measurement before answering it with a document.*
v6 is the document answer to the document problem. That is not fatal — the rules are good —
but it is why the layer feels heavy, and it is worth naming out loud.

**18 of 61 rules (30%) are `PROVISIONAL`** — never validated against a real case. By v6's own
standard, that a rule earns its place through a failure it caught, nearly a third are unearned.

---

## 2. Three defects

### 2a. ⛔ The adversarial pass cannot run. At all.

`tools/adversary.sh` gate 2 calls `tools/checks/ledger_parses.sh`. **That file does not
exist in v6.** The gate therefore always fails, and the script exits before doing anything:

    say "STOPPED: a gate is unmet. An adversary over noise is a cost with no signal."

This is precisely the failure `WA-P.3` is about — *a rule pointing at a missing file is
silent.* The script's own header says the adversarial pass "has been specified for two days
and nothing ran it." It still cannot.

`checks/specs_exist.sh` passes clean on v6, because it verifies **markdown** references and
not shell dependencies. Its coverage gap is the whole defect. Your own rule: *ask what a
passing check covers, not only whether it passed.*

### 2b. The layer contradicts itself on the operator's documents

`WA-L.1`: the launcher *"is the only document the operator writes. Goals, claims and gates
live in it; there is **no separate goals file, claim ledger or roadmap**."*

`templates/GATE_WORKFLOW.md` then instructs the operator to maintain `ROADMAP.md` **and**
`CLAIMS.md`, in three places. Two documents that `WA-L.1` says must not exist.

This is `WA-P.4` — rules living in more than one place — inside the layer written to prevent it.

### 2c. `adversary.sh` is project-specific code in a portable layer

It hardcodes `docs/PROMPTS.md`, `CLAIMS.md`, `ROADMAP.md`, `docs/reviews/`. The same defect
v3 had, where a RETRON-DB launcher lived in the general spec folder.

---

## 3. What v6 does NOT do that you asked for

You asked for: **plan → adversarial check of the plan → execute → second adversarial pass.**

v6's adversary is **a periodic sweep, not a gate**. It requires ≥2 landed bundles since the
last review, and it reads *bundles that already exist*. It never sees a plan. There is no
adversarial step anywhere in `GATE_WORKFLOW.md`.

So the thing you most want is the thing v6 has least of — and what it does have is broken (2a).

Two smaller points:

- `ADVERSARY_MODEL` defaults to **`claude-sonnet-5`** — the same family as the author. Gate 4
  concedes this is unenforceable and "the operator's to honour." Your codex setup
  (`gpt-5.6-sol`, different provider, `xhigh`, **`sandbox: read-only`** so it cannot edit what
  it reviews) is strictly better and should be the default.
- **Ibex encouragement is adequate**, not weak: `site/COMPUTE.md` escalates on >2 hr, >24 GB
  VRAM, or a census that doesn't fit in RAM, with *never downgrade a census to a sample to
  stay local*, plus cheap-gating-jobs-before-large-arrays. `WA-K` covers smoke tests. This
  needs no work.

---

## 4. What v6 dropped that was worth keeping

- **Nothing from v3.** Its `EVIDENCE_STANDARDS` survives in v6, improved.
- **`prov.py` / `check_prov.py` (v5)** were dropped **deliberately and correctly** — v6's
  `REPORTING_STANDARDS` graveyards them as "a second provenance system for the same job."
  This also means my `PROVENANCE.md` + `MANIFEST.tsv` work this session rebuilt something
  v6 had already rejected with reasons.
- **No launcher validator exists** in any version. `LAUNCHER_SPEC.md` defines six required
  sections and nothing checks them. Given launchers now carry kill criteria and claims born
  UNPROVEN, this is the one thing I built that v6 lacks.

---

## 5. Recommendation — five changes, not a rewrite

Adopt v6 as-is and make these. Everything else stays untouched.

| # | change | why |
|---|---|---|
| 1 | Write `tools/checks/ledger_parses.sh`, or drop gate 2 | unblocks the adversarial pass — nothing else matters until this works |
| 2 | Add a **plan-stage** adversarial gate to `GATE_WORKFLOW.md` | the thing you actually asked for; the current sweep only sees landed bundles |
| 3 | `ADVERSARY_MODEL` → codex `gpt-5.6-sol` | independence by different provider, read-only sandbox |
| 4 | Resolve `WA-L.1` vs `GATE_WORKFLOW` on ROADMAP/CLAIMS | a contradiction in the anti-contradiction layer |
| 5 | Port `check_launcher.py` as a `LAUNCHER_SPEC` check | six required sections, currently unenforced |

**Before any of it, one measurement** — `WA-P.1`, applied to this decision:

> How many bundles have landed since 2026-09-09, and how many declared LIGHT?

If the answer is "several, mostly LIGHT," v6 is working and these five changes finish it.
If it is "zero bundles," the problem is not the rules and adding a sixth change would be
the same mistake for the third time.

```bash
for p in /home/borg/RESEARCH-in-sleep-*/; do
  n=$(ls -1d "$p"results/*/ 2>/dev/null | wc -l)
  [ "$n" -gt 0 ] && { echo "$p -> $n bundles"; grep -rho 'WEIGHT: *[A-Z]*' "$p"results/ 2>/dev/null | sort | uniq -c; }
done
```
