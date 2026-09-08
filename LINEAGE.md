# LINEAGE — the superseded trees, and the rule about them

**This is the only file in this layer that names a folder outside the project being worked
on.** It exists so that a path can be chased when a launcher or prompt explicitly asks for
one, and for no other reason.

## The rule

> A session does **not** read, cite, load, or inherit from any tree listed below unless a
> launcher or an operator prompt names it explicitly and says what to take from it.
>
> Anything taken enters under WA-I.3 — as RE-DERIVED, BLIND-CONFIRMED, or [UNVERIFIED] —
> and is verified at the point of use, per artifact. Auditing one of these trees wholesale
> is out of scope, always.

An absence of a result in this layer is **not** evidence that it was never computed. It is
evidence that it has not been re-derived here (WA-I.3).

## Why a lineage file exists at all

The failure this layer is built against is not a wrong number. It is **rules living in more
than one place** (WA-P.4). Before v6 there were four governance trees on disk simultaneously,
one of which declared itself superseded and was still named as the master by 19 files across
a live project — including that project's own CLAUDE.md. Every one of those pointers was
written in good faith by someone who had read a real document.

Naming the ancestors in exactly one file, with a rule attached, is the fix. Adding a fifth
place for a rule to live is what created the problem.

## The trees

| tree | period | what it was | status |
|---|---|---|---|
| `RESEARCH-in-sleep-GENERAL_v1` | to 2026-07 | first shared-context folder | superseded |
| `RESEARCH-in-sleep-GENERAL_v2` | 2026-07 | shared context + launcher flow | superseded |
| `RESEARCH-in-sleep-GENERAL_v3` | 2026-07 to 08 | added EVIDENCE_STANDARDS; carries its own FROZEN marker | superseded |
| `RESEARCH-in-sleep-GENERAL_v5` | 2026-08 to 09 | forked from v3; added bounded iteration and `tools/`. Local only, no remote. | superseded — its bounded-iteration rule is now WA-L.2 and its tools ship in `tools/` |
| `research-agreements` (repo) + `research-site-kaust` (repo) | 2026-09 | the two-submodule split: portable rules + site facts, rules given ids, checks, a graveyard | **superseded by this layer, which merges both** |
| `RESEARCH-in-sleep-RETRON-DB_V4` | 2026-08 to 09 | a project, not a governance tree. 43 stage directories, no bundles. | prior project |
| `research-wClaude-PART1_v2` | 2026-09 | a project. 20 bundles, 19 of them verified by rerun. | prior project |

## What v6 took from each, and what it left

**Taken from `research-agreements`:** the rule form (id · scope · check · validated), the
ALWAYS/WHEN split and its budget, the graveyard, expiry dates, the bundle as the single
provenance mechanism, `EVIDENCE_STANDARDS` unchanged, and all five checks — copied verbatim
and re-selftested here, not rewritten.

**Taken from `GENERAL_v5`:** bounded iteration, now WA-L.2, including *a loop may DRIVE but
may not ACQUIT*; and `tools/`, whose absence from one project had caused the mandate that
required it to be deleted as a dead reference.

**Taken from `RETRON-DB_V4`:** the launcher apparatus — write boundary, input trust grades,
anti-anchoring, the six self-adversarial questions — now `agreements/LAUNCHER_SPEC.md`,
WA-L.1, WA-L.3, WA-D.6 and BS-14.

**Left deliberately:** the retroactive correction apparatus that grew in `RETRON-DB_V4` —
sixteen correction, void, recheck, concern and audit registers. All of it is downstream of
having no gate at production time. With bundles it is unnecessary, and EVIDENCE_STANDARDS §7
covers the legitimate remainder. **Do not rebuild it.**

**Left deliberately:** "one row = one measurement = one session" as the unit of *scope*. It
was correct about the number and wrong about the session, and it deferred every scientific
goal a project had. See the graveyard in `agreements/WORKING_AGREEMENT.md`.
