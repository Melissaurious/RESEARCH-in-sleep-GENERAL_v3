# ADVERSARIAL REVIEW — plan → attack → execute → attack

_Read at the start of every stage. The two review passes are **gates**, not advice:
pass 1 blocks execution, pass 2 blocks promotion to `results/`._

```
  ┌─ P1 PLAN ──────┐   ┌─ P2 ATTACK PLAN ─┐   ┌─ P3 EXECUTE ─┐   ┌─ P4 ATTACK RESULT ─┐
  │ agent writes   │ → │ codex, adversarial│ → │ Phase A: run │ → │ codex, adversarial │
  │ PLAN.md        │   │ 01_plan_review.md │   │ Phase B: read│   │ 02_result_review.md│
  └────────────────┘   └───────┬───────────┘   └──────────────┘   └────────┬───────────┘
                               │ BLOCKER ⇒ no execution                    │ BLOCKER ⇒ no promotion
                               ▼                                           ▼
                       Melissa approves                            promote_stage.py → results/
                                                                            ▼
                                                                      retro → specs/
```

All four artefacts live in `ARIS_OUTPUT/<STAGE_ID>/review-stage/`.

---

## 1. What the reviewer is given — and deliberately NOT given

The single most common way an adversarial review becomes theatre is handing the reviewer
the author's reasoning. It then grades the *argument*, agrees with it, and returns
"looks good."

**GIVE the reviewer:**
- the launcher (`LAUNCHER_<STAGE_ID>.md`) — the objective, scope and falsifier
- `PLAN.md` (pass 1) or the produced tables, figures, scripts and `REPORT.md` (pass 2)
- `specs/EVIDENCE_STANDARDS.md` and `specs/WORKING_AGREEMENT.md`
- real schema probes of the inputs — actual values, not `input_format.md`

**WITHHOLD:**
- ⛔ the conversation transcript, the agent's justifications, its confidence
- ⛔ any earlier review that returned `PASS`
- ⛔ what Melissa said she hoped to find

`tools/adversary.py` assembles the packet and enforces this split. It is a one-shot
`codex exec` with no conversational history, on purpose.

## 2. Verdict vocabulary — fixed, no synonyms

Every review ends with exactly one overall verdict:

| verdict | meaning | consequence |
|---|---|---|
| `PASS` | no blocking defect found, coverage stated | proceed |
| `PASS_WITH_CONCERNS` | non-blocking findings only | proceed; concerns disposed in writing |
| `FAIL` | ≥1 `BLOCKER` | **stop.** Fix and re-review |
| `INSUFFICIENT_INFORMATION` | the packet does not allow a judgement | **stop.** Name what is missing, resend |

`INSUFFICIENT_INFORMATION` is a first-class, respectable outcome. A reviewer forced to
choose between "pass" and "fail" on an inadequate packet will invent findings or wave it
through; both are worse than saying so.

Each finding is graded:

| grade | meaning |
|---|---|
| `BLOCKER` | the stage would produce a wrong, circular, or unfalsifiable number |
| `CONCERN` | real weakness, does not invalidate the result |
| `NIT` | style, naming, clarity |

## 3. A review with no findings is not finished

Every review **must** close with a coverage statement:

```
CHECKED:     <what the reviewer actually verified, and how>
NOT CHECKED: <what it could not verify, and why>
```

The `NOT CHECKED` block may not be empty. If the reviewer can verify everything, it has
not understood the stage.

> The 2026-08-25 retro: a load-bearing check reported `ran: False` on four of five sets
> and was read as fine. **A filename is not a verification, and a check that did not run
> is not a pass. Ask what a passing check covers, not only whether it passed.**

## 4. Disposition — the author does not get to dismiss its own findings

Every `BLOCKER` and `CONCERN` is dispositioned in `review-stage/03_dispositions.md`:

| disposition | requires |
|---|---|
| `FIXED` | the diff, plus the command and output showing the fix works |
| `REFUTED` | **an artefact**, not an argument: a command and its output that would have *confirmed* the finding had it been right |
| `ACCEPTED_RISK` | Melissa's initials + date. ⛔ The agent may never self-grant this. |

> The same retro, inverted: *a defect attributed to another stage requires a control that
> could exonerate it, run before the claim is written.* A **dismissal** is the mirror
> image — a hypothesis wearing a verdict's clothes. Refuting a finding needs a test that
> could have gone the other way.

Prose alone never closes a finding. Neither does "this is out of scope" — out-of-scope
belongs in the launcher, declared before the review, not discovered after it.

## 5. Pass 1 — attack the PLAN (before any compute)

The reviewer is asked, in order:

1. **Could this plan return a negative?** If nothing could falsify it, it is a
   description, not a test. (`EVIDENCE_STANDARDS` §6)
2. **What is measured with the instrument that defined it?** Grade circularity
   `NONE/LOW/MEDIUM/HIGH` for every method. `HIGH` is a `BLOCKER`. (§3)
3. **Are thresholds declared before scoring, in code?** A cut chosen after seeing the
   outcome is the result, not a parameter. (§5)
4. **Is every claimed independence computed, or assumed?** (§4)
5. **Is there a positive control for every intended negative claim?** (§6)
6. **Does the plan report anything estimated from a sample?** (`WORKING_AGREEMENT`)
7. **Has the plan probed field semantics on real values, or trusted a schema doc?**
8. **What already exists on disk that this plan would rebuild?** ⚠️ The retro's most
   expensive lesson: *absence is loud; wrongness is quiet.* B4 was recorded as never
   started and had in fact been run; B3's embeddings existed and were computed on
   unoriented sequence. Both read as ready.
9. **Is the compute estimate derived from a measured smoke test, or guessed?**

## 6. Pass 2 — attack the RESULT (before promotion)

1. Walk `EVIDENCE_STANDARDS.md` §8, item by item, against the actual artefacts.
2. **Does every number in `REPORT.md` trace to a promoted script?** Any hand-copied,
   recomputed, or remembered number is a `BLOCKER`.
3. **Does every figure have its TSV**, and does the TSV reproduce the figure?
4. **Is every artefact validated by content** — bytes, parse, record count, an asserted
   invariant — rather than by `exists()` or exit code? (§1)
5. **Are exact statements exact?** Not "reconciles to `total_nt × 1280 × 2`" when a
   128-byte `.npy` header × 28,431 files says otherwise; not "a 57% excess" for 56.4%.
   ⚠️ **Assert the identity, not the round number that resembles it.**
6. **Are claims scoped to what was examined?** (§7)
7. **Are negative and surprising results stated plainly**, or softened? (`REPORTING_STANDARDS`)
8. **Would `REPRODUCE.sh` run on a machine that is not this one?**

## 7. Running it

```bash
# pass 1 — after PLAN.md exists, before anything heavy runs
python "$RSG/tools/adversary.py" --stage <STAGE_ID> --pass plan

# pass 2 — after Phase B, before promotion
python "$RSG/tools/adversary.py" --stage <STAGE_ID> --pass result

# then, only if the verdict allows:
python "$RSG/tools/promote_stage.py" --stage <STAGE_ID> --rerun
```

Reviewer model and invocation: `specs/TOOLING.md` § Adversarial reviewer.

`adversary.py` **probes codex by execution before trusting it** (`EVIDENCE_STANDARDS` §2)
and records the grade in the review file. A reviewer that is installed but fails on real
input is `PRESENT_BUT_BROKEN` and does **not** count as a pass.

## 8. When the reviewer is wrong

It will be. It has less context than you by design, and that is what makes it useful.

- A wrong `BLOCKER` costs one `REFUTED` disposition with a command and its output. Cheap.
- A missed `BLOCKER` costs a stage. Expensive.

**Do not tune the reviewer toward agreement.** If it stops finding anything, the packet
has probably grown to include the author's reasoning — check §1 first.
