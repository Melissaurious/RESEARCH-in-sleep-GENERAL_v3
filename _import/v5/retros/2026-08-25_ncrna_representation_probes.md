# Retro — `ncrna_representation_probes` (B11, B3, B4)

**2026-08-25 → 26.** Parallel track to the V5 detector session. All three tasks closed.
**Ibex jobs submitted: 0. GPU spent: ~15 minutes, all local.**

---

## What the stage produced

| task | outcome |
|---|---|
| **B11** RT-protein conditioning pre-check | ⭐ **YES.** 97.2% of separable-fold eval reps have an RT-protein relative in training vs **0.0%** on the RNA side (n_eff 1,198 clusters). All 9 folds land 8.0–126.3× above their own null. |
| **B4** dependency maps | ⛔ **Closed as a NEGATIVE.** RNAfold beats the RiNALMo dependency map by **0.25–0.27 AUROC** on msr-msd base-pair recovery, on all three references. **Zero GPU** — the maps were already on disk. |
| **B3** RiNALMo embeddings on oriented input | ✅ **28,431 arrays, 42.86 GB**, five sets, all verified oriented. |

## What worked

**1. Looking for the artifact before building it — twice, decisively.**
B4 was recorded as "never started" and had in fact been run, with an implementation control
(Archive II 0.9994) and a pre-registered bar. B3's "embeddings already on disk" was true — 21.4 GB
of them — but computed on unoriented sequence. **Both defects were artifacts that EXISTED and
were WRONG, not artifacts that were missing.** Absence is loud; wrongness is quiet, because its
presence reads as readiness and nothing prompts a check.

**2. Refusing a number my own geometry forbade.**
RNAfold scored 0.9055 forward and 0.5265 revcomp. Canonical WC pairs are *exactly*
revcomp-symmetric, so both could not be RNAfold. Testing instead of reporting found a coordinate
defect in another stage's base-pair truth — a minus-strand projection walking `lo + pi` where the
aligned row runs 3'→5'. ⚠️ **The caveat I wrote to weaken my own result is what found it.** Had I
not worked out the symmetry while drafting a class-B disclaimer, I would have reported a strand
split as confirming orientation: right number, wrong cause, and a fix that would have done nothing.

**3. Asking what a passing check covered.**
`s14`'s load-bearing check reported `ran: False` on four of five sets and that was read as fine.
**A filename is not a verification, and a check that did not run is not a pass.** Two CPU checks
closed it at 28,431/28,431.

**4. Choosing an instrument that shares no derivation with the artifact under test.**
To verify `secondbest_*` — sets I did not build — I declined to re-derive their cut. A
re-derivation that disagreed would have been ambiguous between *their* defect and *my*
reimplementation, and this project's incentives resolve that ambiguity the wrong way. A
containment test needs no offsets and cannot fall into it.

## What I got wrong, and what it cost

**1. I nearly charged a false defect to another stage.** Sub-ulp bf16 variation across batchings
has X130's shape, the pattern was familiar, and I had the sentence half-written. What stopped it
was a control that could **exonerate**: batching a sequence *with itself* — zero padding — differs
as much as a 2562-nt pad-mate, so padding cannot be the cause. ⚠️ **Finding defects in inherited
work had been rewarded for two weeks. That is exactly the condition under which a false positive
becomes likely.**

**2. I measured a threshold's range on 200 smoke records; the population's was 8× wider.** The cut
then fired on 9 of 6,472. The fix was not to move it — the statistic (relative max|Δ|, a max over
1280×L values) was a **correlate of length**, r = +0.32. Replacing the statistic with mean
per-position cosine widened the band from 1.53× to an absolute 0.334.

**3. Loose statements of exact facts.** "Reconciles to `total_nt × 1280 × 2`" was off by the
128-byte `.npy` header × 28,431 = 3.6 MB. "A 57% excess" for 288 vs 184.1, which is 56.4%.
Both figures were right; the *statements* were not.

**4. A per-invocation manifest silently narrowed to the last run.** Caught only by reading back
what had just been written.

**5. My first positive control was itself class B** — zero across all 21 folds, because it
measured the LOCO purge rather than separability.

## To fold into `specs/` — six rules, each earned by a failure above

1. ⛔ **A FILENAME IS NOT A VERIFICATION**, and `ran: False` is not a pass. A name asserting a
   property is class D at its most insidious: a document at least invites reading; a filename
   invites nothing. **Ask what a passing check covers, not only whether it passed.**
2. ⭐ **To verify an artifact you did not build, choose an instrument that shares NO derivation
   with it.** A re-derivation that disagrees is ambiguous between their defect and your bug.
3. ⭐ **A defect attributed to ANOTHER stage's artifact requires a control that could EXONERATE
   it, run before the claim is written.** Without one, a defect report is a hypothesis wearing a
   verdict's clothes. Belongs beside class D: where D is a *document* asserting a state the
   artifacts lack, this is a *report* asserting a defect they do not have.
4. ⭐ **When a guard fires on a continuum, ask whether the STATISTIC is a correlate before
   touching the cut.** And: a range measured on a sample is not the population's range.
5. ⭐ **When a check fails on a subset, the first hypothesis is that it is pointed at the wrong
   input** — and the second is that a `.get()` default would have hidden it. Fourth instance
   across two trees; it has stopped being a caution and become a diagnosis.
6. ⭐ **Assert the identity, not the round number that resembles it**, and **read back what you
   just wrote** — it catches a partial writer that leaves a syntactically valid file.

## ⭐ The position, in its correct form — amended 2026-08-26

The first version of this claim, and the owner's, was half of it: *a read-only parallel stage
owning nothing is structurally positioned to ask "is this what it says it is?" about work that,
from inside, simply looks done.* True — it is how B4-already-run, the base-pair defect and the
`_oriented` coverage gap were all found. **But stated alone it is an advertisement, and the risk
is not a caution attached to it, it is its inseparable half:**

> **The same vantage that makes foreign artifacts findable makes finding them rewarding.** The
> four exonerating controls — the self-batching test, the containment test, the strand split, the
> port gate — were not prudence. They were **necessary**, and they are why the defects that were
> reported are believable.

⛔ **And the half I would otherwise have missed: the worst coverage gap in this stage was in MY
OWN check.** Four of five delivered sets rode on a filename, guarded by a check that reported
`ran: False` and was read as fine. **The vantage point does not exempt the vantage point** — a
parallel stage sees more, is biased toward seeing defects, *and is least positioned to doubt its
own artifacts.*

⚠️ Confirmed once more on the stage's last action: verifying that these rules had landed, a
line-oriented grep reported one of six missing. It was present — the heading wrapped. Reporting
"5 of 6" to the person who had just applied them was available and tempting at the smallest
possible scale, which is the evidence that the trap needs no stakes.

## Process notes

- **File-first replies worked exactly as intended.** 15 numbered exchanges, none garbled.
- **Declining the launch brief's Ibex remit was the remit working, not a departure from it** —
  the brief said *heavy jobs to Ibex*, and measuring showed none of them was heavy: B4 needed no
  GPU at all, and B3 was ~14 minutes locally against ~63 minutes of transfer at 10.6 MB/s.
- ⚠️ **One self-reported breach:** a 300 MB link-throughput test file written outside the path the
  brief restricted me to. Deleted, verified absent, reported rather than left to be found.
- **Cross-tree corrections were staged, never applied.** Three landed via the owner (ROADMAP B11,
  ROADMAP B4, KNOWN_WRONG 24) with superseded text kept visible.
