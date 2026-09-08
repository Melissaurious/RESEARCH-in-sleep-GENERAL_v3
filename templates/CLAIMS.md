# CLAIMS

The progress tracker. Falsifiable statements, each serving a goal, each settled by a bundle.

## The chain — nothing skips a layer

    GOALS.md          G1..Gn    what you want to be able to claim at the end
    CLAIMS.md         C1..Cn    falsifiable statements, each serving a goal. This file.
    launchers/                  one per track — the authority on scope
    ROADMAP.md        one GATE per row, each settling one or more claims
    results/<GATE>/             the evidence. A bundle, or it did not happen.
    paper/                      assembled from SUPPORTED claims only (BS-7)

**Progress is not how much you have done.** It is how many claims left UNPROVEN, and whether
any went to REFUTED. A week with three REFUTED claims and no SUPPORTED ones is a good week.

## Rules

CL-1  The claim exists here as UNPROVEN **before** the gate that settles it runs.
CL-2  This ledger is the operator's. A session proposes a paste-ready block in its bundle
      README; it never edits this file.
CL-3  A refutation is a result and lands like any other.
CL-4  A claim carries its unit, its denominator, its scope, and its circularity grade at
      birth — not after the measurement comes back.
CL-5  A claim is VERIFIED only after an audit verdict AND the operator's sign-off in their
      own words (WA-I.2). Never by a session's judgment.
CL-6  A claim is never rescued by qualification. If the measurement splits it, both halves
      are reported and the claim settles as the weaker one.

## The ledger

| ID | Claim — value, unit, denominator, scope | Serves | Grade | Circ. | Status | Settled by | Date |
|----|------------------------------------------|--------|-------|-------|--------|-----------|------|
| C1 | | G1 | — | | UNPROVEN | — | |

Grade: `MEASURED` · `DERIVED` · `INFERRED`. One INFERRED element makes the whole claim
INFERRED (EVIDENCE_STANDARDS §1c).
Circularity: `NONE` · `LOW` · `MEDIUM` · `HIGH` (§3).
Status: `UNPROVEN` · `SUPPORTED` · `REFUTED` · `WITHDRAWN`.
