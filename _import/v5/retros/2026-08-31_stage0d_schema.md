# Retro — 2026-08-31 · Stage 0d (RETRON-DB V5) · Schema document consolidation

**Outcome:** V5 now has its own canonical `templates/input_format.md` (V4's full annotated
version + the five stage-0a additions, tags intact), and
`templates/input_format_schema_only.md` is rebuilt from it by script rather than by hand.
Closes items 2 and 3 of the stage-0a retro §5. `ARIS_OUTPUT/stage0a_blind_repro/inputs/`
now symlinks the schema-only file, so that stage's inputs directory reflects what should
have been staged.
**Headline finding:** the strip-point convention proposed in stage-0a §4 does not hold as
written — one of its own five bullets leaks a figure through it. See §2.

---

## 1. What worked

**Diffing before writing, when the task premise was wrong.** The task named
`templates/input_format.md` as the file to edit. V5 has no such file — only the
schema-only build. Rather than create one from the nearest-looking candidate, I diffed the
three candidates against each other. `input_format_schema_only.md` turned out to be
*exactly* V4's `templates/input_format.md` plus a four-line banner and four stripped
passages — and the banner itself names V4 as the full version. That made the ancestry a
verified fact rather than a guess, and it made the reconstruction mechanical instead of
editorial. **The diff, not the filename, identified the canonical source.**

**Rebuilding the derived file by script instead of editing it.** Schema-only is a
*derived* artefact. Hand-editing it to add the five new notes would have let it drift from
its source silently — which is exactly how the residual `52,505 / 52,515` survived the
previous strip. The rebuild applies eight named replacements to the full file and asserts
each one matches exactly once; a stale or duplicated anchor fails loudly instead of
no-oping. Final check was a full diff of the two files, confirming *only* the intended
deltas.

**Grepping for the whole class, not the one instance named.** The task named the
`52,505 / 52,515` figure. Grepping the file for percentages and thousands-separated
integers surfaced the other eight numeric sites — which is what turned up the exemption
question in §3 and, separately, the prose leak in §2. Fixing only the figure that was
pointed at would have left both.

---

## 2. The strip-point hole (the important one)

Stage-0a §4 states the convention plainly: *"Each states the qualitative property first
and carries its count in a trailing `[stage 0a, 2026-08-31]` tag. That tag is the strip
point."* A schema-only build therefore strips bracketed tags and keeps the sentences.

**One of the five bullets violates its own convention.** The `rt_system_id` note ends:

```
  Deduplicate on `rt_system_id` before any per-system count, or state that you are
  counting records. Counting records as loci inflates by ~5 %.
  [stage 0a: 174,951 repeat rows over 3,358,182; RT rows exceed RT loci by 4.86 %]
```

The `~5 %` sits in the prose, outside the tag. **A build that strips tags and only tags
ships that figure into a blind stage** — and it is the stage's load-bearing structural
result, rounded. Schema-only now reads "inflates the count"; the full file keeps `~5 %`.

The general shape of the defect: *tag-stripping is a mechanism, not a guarantee.* It is
only sound if a separate check enforces the invariant it assumes — that no figure exists
outside a tag. Authoring the tag and enforcing emptiness outside it are two different
jobs, and §4 only did the first. Four of five bullets happened to comply; compliance by
authoring discipline is exactly the property that decays.

**This strengthens §5.1 rather than replacing it.** The proposed content-check (grep the
staged tree for percentages and thousands-separated integers) *would* have caught this,
because it does not trust the tag boundary. The lesson is that the grep is the actual
control and the tag is only a convenience for the author — so the grep cannot be treated
as a backstop to be skipped once the tags look right. **Strip by tag, verify by grep,
and let the grep be authoritative.**

---

## 3. The metadata-listing exemption

The § Taxonomy metadata-file listing carries eight file sizes (`gem_metadata.tsv` 52,516
lines, NCBI bacteria 2,864,739 lines, …). These were retained in schema-only, deliberately,
and the block is now marked with an HTML comment recording that decision.

**The reasoning:** these are sizes of the *staged input files*, recoverable by `wc -l` on
the staged data itself. They describe what the reader was handed, not what the corpus
turned out to contain. Stripping them removes information the analyst legitimately needs
for sizing (stage 0a's own §1 makes measuring-before-sizing the thing that worked) while
leaking nothing, because the reader can trivially recompute them.

**The honest qualification, recorded because it weakens the exemption:** the retained
`52,516 lines` makes the stripped `52,515 rows` inferable by subtracting a header. Only
`52,505` — how many rows carry a real lineage — was a genuine result, and that is gone.
So the exemption is not perfectly clean; it narrows a stripped ratio to its numerator.
That was judged acceptable, but it is the general hazard worth naming: **a retained figure
and a stripped figure can be arithmetically related, so exemptions must be reasoned about
jointly, not one line at a time.**

The comment is in *both* files. Schema-only is generated, so a marker living only there
would be erased by the next rebuild.

---

## 4. What I assumed, and what is still open

1. **I did not re-verify the five stage-0a figures against the artefacts.** They were
   copied verbatim from retro §4 into the full file. If any is wrong, it is now wrong in
   the canonical schema document.
2. **The rebuild script was not persisted.** The task constrained writes to `templates/`
   and one inputs path, so the script ran inline. The rebuild is therefore reproducible
   in principle but not in practice — the eight replacements would have to be re-derived.
   **This is the main loose end**: a derived file with no committed generator drifts, which
   is the failure this stage existed to repair. It wants a `tools/build_schema_only.py`.
3. **No automated staging control exists yet.** §5.1 of stage 0a is still open. Nothing
   currently prevents the next blind stage from staging the full file again; the symlink
   fixes stage 0a's directory specifically, not the class.
4. **The banner pointer now reads `templates/input_format.md`** (was: V4's). Correct for
   V5, but it means V4 and V5 banners now differ — a diff between the two versions' files
   will show it.

---

## 5. What to fix

1. **Write `tools/build_schema_only.py`** and make it the only way schema-only is
   produced. It should assert each replacement matches exactly once, then run the §5.1
   grep over its own output and fail on any unexempted figure. That collapses §2's lesson
   and item 2 of §4 into one artefact.
2. **Amend the strip-point convention in the working agreement**: a `[stage …]` tag is
   where figures *go*, and the grep over the stripped output is what makes the build
   valid. Never ship a strip on the strength of the tags alone.
3. **Exemptions get a machine-readable marker.** The `<!-- STRIP EXEMPTION … -->` comment
   added here is prose. If the grep control lands, it should read the marker rather than
   have its exemptions hard-coded, so waivers live next to what they waive.
4. **When exempting a figure, check what it makes inferable** (§3). One line at a time is
   not sufficient reasoning.
5. **Promote to WORKING_AGREEMENT:** when a task names a file that does not exist, diff
   the candidates to establish ancestry before creating it. Here it converted an editorial
   guess into a mechanical copy, and the wrong guess (the `ARIS_OUTPUT` copy, which looks
   like the obvious source) would have silently dropped every figure from the canonical
   document.

---

## Resolution — appended 2026-08-31

*Appended, not edited in place: everything above is the record as written, including
the items this note closes (EVIDENCE_STANDARDS §7 — keep the superseded version
visible). Read §4 and §5 above as the state at the time of writing, and this section
as what has since landed.*

**Closed.**

- **§5.1 — build the generator.** `GENERAL_v5/tools/build_schema_only.py`, committed
  `0056d17`. Banner → strip `[stage ...]` tags → apply the document's qualitative
  rewrites, each asserted to match exactly once → grep its own output → fail. `--check`
  fails when the file on disk differs from a fresh build, which is the drift guard §4.2
  asked for. Document-specific rewrites live in
  `RETRON-DB_V5/templates/schema_only_rewrites.json`, beside the document rather than in
  the shared tool; if the sidecar goes missing the build does not silently ship figures,
  because the scan still fails. Tested on four cases: novel figure in prose → FAIL,
  source drift breaking a rewrite → FAIL *and* the surviving figure reported, stale
  output → FAIL, clean → PASS.
- **§5.2 — amend the strip-point convention.** Landed in EVIDENCE_STANDARDS §1b, which
  now carries "keep every figure INSIDE its tag. A number in the surrounding prose
  survives tag-stripping and leaks silently." The spec states it; the builder's scan
  enforces it.
- **§5.3 — machine-readable exemption marker.** The exemption block is now closed with
  `<!-- /STRIP EXEMPTION -->` and the builder reads the span from the document. No
  exemption is hard-coded in the tool.
- **§4.2 — the unpersisted script.** Closed by §5.1 above.

**Still open.**

- **§5.4 — check what a retained figure makes inferable.** Guidance only; nothing
  mechanizes it. The `52,516 lines` / `52,515 rows` adjacency in §3 is still the
  worked example.
- **§5.5 — promote the diff-ancestry rule to WORKING_AGREEMENT.** Not done.
- **§4.3 — no automated staging control.** Partly closed: the builder verifies its own
  output, but nothing yet blocks a stage from staging the full annotated file instead
  of the schema-only one. The check exists; the gate does not.
- **§4.1 — the five stage-0a figures were never re-verified** against the artefacts.
  Still true, and now committed into the canonical schema document.

**Work this retro did not anticipate, arising from the same review.**

The provenance gate was relaxed and tightened in the same pass (committed `0056d17`),
after `check_prov.py` failed stage 0b for a dirty tree that was another session's work:

- **The dirty-tree flag could not be classified at all.** `git_dirty` was a bare
  boolean; the paths were discarded at write time. Fixing this required `prov.py`, not
  just the checker — and stage 0b's existing record can never be reclassified, because
  its paths do not exist. Legacy records now warn rather than fail.
- **`_git_dirty` anchored on the producing script's directory** and resolved to the
  enclosing repo — the whole of RETRON-DB_V5. Any uncommitted file anywhere in that
  tree, from any session, flipped the flag. The gate was not noisy, it was uninformative.
- **"The stage's own outputs are dirty" is structurally always true.** An artifact and
  its `.prov.json` are untracked at the instant they are written. A rule failing on that
  would fail every stage forever. The signal is the porcelain status code: `??` (new,
  normal) versus a tracked modification (a committed artifact has since changed).
- **Uncommitted producing code is the more serious half**, and was missing from the
  original gate. A provenance record naming a commit that does not contain the code that
  ran is worse than no record, because it looks authoritative. Now a hard failure.
- **The gate failed open where it mattered most.** With no git repo at the anchor,
  `_git_commit` returned `UNVERSIONED` and `_git_dirty` returned `False` — so the check
  passed *because* version control was absent. All 19 stage-0a artefacts passed that way.
  `UNVERSIONED` is now a hard failure, grandfathered to a warning for records written
  before V5's git init (2026-08-31T16:14:21Z, commit `fd46b8c`); 0a's numbers are fine,
  its version control was not there yet. Records with no parseable timestamp do not get
  the exemption — a record that cannot say when it was written cannot claim it.

**The pattern worth keeping from both halves of this session:** every one of these was
found by a mechanism that *checked its own output* rather than trusting the step that
produced it — the grep that does not trust the tags, the `--check` that does not trust
the last build, the test that caught the builder printing `applied 6` when it had
applied fewer. §1 of the stage-0a retro made the same point about validating the cache.
It keeps being the thing that works.
