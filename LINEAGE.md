# LINEAGE — the prior trees, and how to reuse them

**The only file in this layer that names a folder outside the project being worked on.**
It exists so a path can be chased when a launcher asks for one, and so that six years of
prior work stays *reusable* rather than merely superseded.

## The two rules

> **1. Not read by default.** A session does not read, cite, load or inherit from any tree
> below unless a launcher or an operator prompt names it explicitly and says what to take.
> Auditing one of these trees wholesale is out of scope, always.
>
> **2. Reuse is allowed and encouraged — after a smoke test.** Anything taken is *executed
> on real input* and graded before it is trusted (`EVIDENCE_STANDARDS` §2), never adopted
> because it looks finished. Record the grade where the thing is used.

An absence of a result in this layer is **not** evidence it was never computed. It is
evidence it has not been re-derived here.

⚠️ **Wrongness is quiet.** These trees contain artefacts that exist and are *wrong* — a stage
recorded as never started that had in fact been run, 21.4 GB of embeddings computed on
unoriented sequence. Both read as ready. Absence announces itself; a stale artefact does not.

## The trees

| tree | period | what it was | status |
|---|---|---|---|
| `GENERAL_v1` | to 2026-07 | first shared-context folder | superseded |
| `GENERAL_v2` | 2026-07 | shared context + launcher flow | superseded |
| `GENERAL_v3` | 2026-07→08 | added `EVIDENCE_STANDARDS` | superseded — the standards live on here |
| `GENERAL_v5` | 2026-08→09 | forked from v3; bounded iteration, `tools/` | superseded — bounded iteration is now WA-A.3 |
| `GENERAL_v6` | 2026-09 | rules with ids, checks with selftests, bundles | **superseded by this layer, which reuses most of it** |
| `RETRON-DB` → `_V5` | 2026-07→09 | projects. 75 scratch dirs, 15 launchers, 0 bundles | prior projects |
| `~/aris_repo` (ARIS) | ongoing | the upstream methodology: 82 skills, the `codex-exec` MCP bridge, cross-model verdict gates | **installed tool, not a governance tree** |

## What v7 took, and what it left

**Reused verbatim from v6, each re-smoke-tested here before adoption:** `EVIDENCE_STANDARDS`,
`BUNDLE_SPEC`, `SESSION_HYGIENE`, `site/COMPUTE.md`, `site/IBEX.md`, all five `checks/`
(75 selftest assertions, every one watched rejecting a bad case *and* accepting a good one),
`cache.py`, `dispatch.py`, `bundle.sh`, `index.sh`, `new_project.sh`, `general_sha.sh`.

**Reused from ARIS:** the autonomous loop, and the principle that a *different model* holds
the gate so the operator does not have to. ARIS stays installed at `~/aris_repo` and is not
vendored here — pulling it in would make a seventh governance tree, which is the failure this
file exists to prevent. Take its `codex-exec` bridge and ~8 skills; leave the other 74
unlinked, because every skill description is loaded into every session
(`agreements/SESSION_HYGIENE.md`).

**Left deliberately — do not rebuild:**

- **The four blocking operator stops** inside every measurement. Individually defensible,
  collectively the reason twelve projects produced zero landed results. Now WA-A.1.
- **`prov.py` / `check_prov.py` / per-artifact `prov.json`** — a second provenance system for
  the same job. The bundle is the only one.
- **Separate `ROADMAP.md` and `CLAIMS.md`** — they contradicted the rule that the launcher is
  the only operator document.
- **`adversary.sh`** — depended on a script that did not exist, so the adversarial pass had
  never once run. Replaced by `tools/review.sh`, which depends on nothing outside this layer.
- **The retroactive correction apparatus** that grew to sixteen registers in `RETRON-DB_V4`.
  All of it is downstream of having no gate at production time. With a gate it is unnecessary.
- **43 of v6's 61 rules** — 18 never validated against a real case, the rest folded or cut.

---

## Graveyard — rules removed, and why

_Not re-proposed without new evidence. Entries do not link the deleted thing: a dead reference in a live document is its own defect._
| removed | why |
|---|---|
| operator approves the plan; operator recognises `INPUTS.tsv`; operator grants ACCEPTED_RISK | three blocking human stops inside one measurement. Replaced by WA-A.1. |
| "interpretation is the operator's call, always" | right about authorship, wrong about timing. Now WA-A.4, asynchronous. |
| every operator-facing reply is also a file in `docs/responses/` | pure overhead per exchange; no case where it caught anything |
| per-artifact `prov.json` + `prov.py` + `check_prov.py` | a second provenance system for the same job. The bundle is the only one. |
| separate `ROADMAP.md` and `CLAIMS.md` | contradicted WA-L.1 in the same repo. The launcher holds both. |
| 18 PROVISIONAL rules | never validated against a real case |
| one row = one measurement = one session, as the unit of *scope* | right about the number, wrong about the session; it deferred every scientific goal a project had |
