# RESEARCH-in-sleep-GENERAL v6

The governance layer for these research projects: **rules, checks, templates and tools.**
No science happens here. A project consumes this repository as a submodule at `general/`
and pins it by sha, so that "we followed our standards" stays falsifiable after the
standards change.

Self-contained: nothing here sends a reader to an earlier version of itself or to another
project tree. Superseded trees are named once, in `LINEAGE.md`, with the rule that they are
not read unless a launcher explicitly says to.

## Layout

| path | what it is |
|---|---|
| `CLAUDE.md` | the master context, loaded every session. Short by design. |
| `VERSION` | this layer's semantic version. |
| `LINEAGE.md` | the superseded trees, and the rule about them. Read only when a launcher sends you there. |
| `PROMPTS.md` | the session prompts the operator pastes. Not read by a session. |
| `agreements/WORKING_AGREEMENT.md` | the rules: id · scope · check · validated. At most 25 ALWAYS. |
| `agreements/LAUNCHER_SPEC.md` | what a launcher must contain, and the three rules every launcher restates. |
| `agreements/BUNDLE_SPEC.md` | how a number enters a repository. The only provenance mechanism. |
| `agreements/EVIDENCE_STANDARDS.md` | whether a number means what it appears to mean. |
| `agreements/REPORTING_STANDARDS.md` | figures, reports, interpretation format. |
| `agreements/SESSION_HYGIENE.md` | what actually degrades session quality, and the weekly ritual. |
| `site/COMPUTE.md` | this installation's machines, partitions, thresholds. |
| `site/IBEX.md` | running and submitting on the cluster. |
| `site/TOOLING.md` | models, reviewer config, environment policy. |
| `checks/` | the runnable half of the rules. Every one carries a `SELFTEST=1` target. |
| `templates/` | copy-and-fill scaffolds for a new project, launcher, ledger and roadmap. |
| `tools/` | `adversary.sh`, `general_sha.sh`, `new_project.sh`, `status.sh`, `worktree.sh`, `sidework.sh`, and the python helpers. |

## Checks

Each check is validated by watching it **fail on a case it must reject and accept a case it
must accept** (WA-A.3). Passing on a good case alone proves nothing, so every check ships a
selftest that asserts both directions.

```bash
bash checks/specs_exist.sh            # every referenced path resolves. Must print OK.
bash checks/rules_current.sh          # buckets rules as EXPIRED / DUE / PROVISIONAL
bash checks/bundle_valid.sh results/<GATE>
bash checks/bundle_valid.sh --write-outputs results/<GATE>   # seal, last (BS-11)
bash checks/no_concurrent_writer.sh   # SessionStart hook; --release at SessionEnd
bash checks/pin_recorded.sh           # a pin nobody wrote down is not a pin

SELFTEST=1 bash checks/<name>.sh      # watch it reject AND accept
```

At the time of writing, the three document-facing checks pass 51 selftest assertions
between them.

## Starting a project

```bash
bash tools/new_project.sh /path/to/<project>
```

It creates the tree, adds this layer as a submodule at `general/`, copies the templates,
installs `.claude/settings.json` with the deny list and sandbox boundary, and runs
`specs_exist.sh` to prove the checkout is governed.

Then fill in, in this order: `CLAUDE.md` (subject, environment, paths), `GOALS.md` (what you
want to be able to claim), `CLAIMS.md` (the falsifiable statements), and a launcher for the
first track. A gate does not start before its claim exists as UNPROVEN.

## Amending this layer

A session may **propose**, never amend. A proposed rule names the case it would have caught
**and** a case it would wrongly reject (WA-A.1) — the second case is what fixes the scope,
and a rule with only the first is usually too broad.

Removed rules go to the graveyard in `agreements/WORKING_AGREEMENT.md` with a reason, and are
not re-proposed without new evidence.

Moving a project's pin to a new revision of this layer is a deliberate commit with a decision
record in that project, never a drift.
