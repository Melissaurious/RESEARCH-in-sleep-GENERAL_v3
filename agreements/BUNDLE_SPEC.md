# BUNDLE SPEC

A bundle is the only way a number enters the repository. The scratch directory
is disposable, gitignored, allowed to be messy. `results/` holds bundles and
nothing else.

This is the ONLY provenance mechanism in the system. A number is provenanced
because it entered through here — not because a sidecar file sits beside it.

## Layout

    results/<GATE-ID>/
      scripts/        producing scripts, verbatim, unedited
      slurm/          the batch files that ran them, if any
      tables/         the numbers themselves — TSV
      figures/        PNG + SVG, each with its data TSV of the same basename in tables/
      MANIFEST.tsv    artifact | script | command | unit | denominator
      INPUTS.tsv      path | sha256 | bytes | mtime
      OUTPUTS.tsv     path | sha256 | bytes   — every file in the bundle but itself
      env.lock        the environment, verbatim (e.g. `conda env export`)
      run.sh          recorded commands, in creation order
      README.md       STATUS line, and counts including the ones that look bad
      PROVENANCE.md   scratch dir it came from, git sha, agreements sha,
                      env_lock_sha256, seed, date, operator

## Rules

BS-1  Scripts are copied verbatim. A cleaned-up rewrite is a different script
      and did not produce the number.
BS-2  Every input is hashed. An unhashed input means the bundle is incomplete,
      not "mostly fine".
BS-3  `run.sh` must run end to end on a clean checkout given the hashed inputs.
      If it has never been run that way, the bundle is UNVERIFIED and says so
      in README.md.
      "On a clean checkout" means FROM THE ASSEMBLED BUNDLE, not from the scratch
      directory the gate was developed in. Those are different layouts: in scratch the
      scripts sit beside `run.sh`; in the bundle they are in `scripts/`. A `run.sh`
      written against the scratch layout resolves every self-relative path one level
      too shallow and reruns nowhere - however many times the gate reproduced before
      assembly, because none of those runs used the shipped entry point. `run.sh` is
      the LAST thing a gate runs, not the first thing it stops testing.
      Partly checked: `bundle_valid.sh` resolves every literal path `run.sh` builds on
      its own location and requires the ones that stay inside the bundle to exist. That
      catches the layout error statically, before any compute; it does not replace the
      rerun, which is the only thing that re-derives the number (WA-B.2).
BS-4  A bundle whose `run.sh` calls sbatch must contain the sbatch file.
BS-5  README.md reports counts that make defects visible: n attempted, n
      succeeded, n dropped and why. Never footnote a failure.
BS-6  Bundles are write-once. A correction is a new bundle with a new id that
      names its predecessor. Never edit a landed bundle. Checked by BS-11: an edited
      bundle no longer matches the hashes it landed with.
BS-7  Nothing enters `paper/` without a bundle id.
      ⚠ **Unchecked.** No script enforces this, and `paper/` does not exist yet. It is
      inert prose until it does — which by means it is silent. The check is
      written when the directory is created, not before, and this line is the record
      that the gap is known rather than overlooked.
BS-8  The environment is pinned by CONTENT, not by name. `env.lock` is in the
      bundle verbatim and `PROVENANCE.md` carries `env_lock_sha256: <sha>`
      matching it. An environment NAME is a label, not a pin: it does not
      survive a package upgrade, and BS-3 cannot hold without this.
BS-9  `PROVENANCE.md` carries `seed: <n>`, or `seed: n/a - <why>` when the
      computation has no RNG. Silence is not permitted: an unrecorded seed makes
      a rerun that returns a different number indistinguishable from a bug.
BS-10 `PROVENANCE.md` carries `agreements: <sha>` — the revision of the working
      agreements this run was governed by. Without it, "we followed our
      standards" is unfalsifiable once the standards change.
BS-12 Every claim id whose status the README proposes must ALREADY be a row in
      the claims table in `idea-stage/docs/research_contract.md`. A gate that discovers a new claim mid-flight
      describes it in PROSE; the operator assigns the number.
      WA-L.1 says the claim exists as UNPROVEN before the gate runs, and WA-L.1 says the
      ledger is the operator's. A gate that hands itself an id breaks both - and the
      id it invents is then free for a later session to reuse for something else,
      while a gate is already executing against the second meaning. Checked; a
      project with no ledger is out of scope and the rule stays silent.
BS-13 Every figure is traceable to the script that drew it, and ships the numbers it
      plots. The Layout section above has said both since the spec was written; nothing
      checked either, and by the tenth bundle 16 of 35 figures shipped with no table
      carrying their data.
      Two halves, enforced differently because they cost differently when absent:
      - **Traceable - checked, FAILS.** Every file in `figures/` is a row in
        `MANIFEST.tsv` naming its producing script. A figure whose script is unknown
        is a picture, not a result: it cannot be redrawn, corrected or defended, and no
        other rule notices, because BS-11 hashes it perfectly either way.
      - **Plottable - checked, WARNS.** Every figure has `tables/<same-basename>.tsv`.
        Absent, a restyle - a colour, a font, a journal's column width - costs a rerun
        over the whole corpus instead of a read of one TSV, and the figure's numbers
        exist nowhere a reader can check them against.
      The second half warns rather than fails because bundles that landed before the
      check existed are write-once (BS-6) and may not be repaired in place. The warn
      count is the debt, and it is meant to be read, not silenced.

BS-11 The bundle's OWN files are hashed, in `OUTPUTS.tsv`, exhaustively: every file
      in the bundle except `OUTPUTS.tsv` itself. BS-2 hashes what went IN and BS-8
      hashes the environment; without BS-11 the artifact the paper will quote has no
      integrity check at all, and a landed result can be edited afterwards with every
      other rule still passing.

      Write it LAST, after `README.md` carries its final `STATUS:` line:

          bash checks/bundle_valid.sh --write-outputs results/<GATE-ID>

      Exhaustiveness is the half that matters. Hashing only what is listed lets a file
      be *added* to a landed bundle uncovered; the check therefore also asserts that
      every file present is listed.

BS-14 The README answers the six adversarial questions in writing, before the
      bundle is offered for acceptance: where each headline claim is overstated
      (name the word); what specific alternative explanation produces this exact
      number; could this test have returned a negative; the unit of every rate;
      which numbers have no producing script; what was withdrawn or weakened.
      Full text: `agreements/LAUNCHER_SPEC.md`.

      This runs BEFORE an external reader is spent on the work. A second reader is
      expensive and should not spend its attention on what the author could have
      found alone.

      A section with nothing withdrawn records what was TRIED and states that
      nothing survived attack. The rule requires the attempt, never the withdrawal:
      a manufactured withdrawal is worse than none, because it makes the section
      unreadable as a signal.

BS-15 `PROVENANCE.md` carries `models:` - the model or models that produced the
      bundle, as a list. An adversarial pass asserts its own model is DISJOINT from
      that set (WA-A.1).

      A list and disjointness, not a single value and inequality: a bundle planned
      by one model and executed by another is the normal case, and forcing a choice
      about which one "really" wrote it invites a false answer. Without this field
      the independence gate is declared and unenforceable - which is how a pass once
      came to review a night it had written itself.


## What lands here, and what does not

The bundle carries **the scripts, the provenance, and the numbers** — not the pipeline.

| | Where it goes |
|---|---|
| producing scripts, verbatim | `scripts/` (BS-1) |
| the result tables | `tables/` — these are the deliverable |
| figures | `figures/`, PNG **and** SVG, each with its data TSV in `tables/` (REPORTING_STANDARDS) |
| a multi-GB intermediate that re-derives in minutes | **nowhere.** Regenerated by `run.sh`, never committed |
| a costly intermediate — an alignment, an HMM, a tree, structures | a registered `derived` artifact with its own hash, in the data register — not in the bundle |
| scratch: drafts, failed attempts, exploratory notebooks | **nowhere.** Dies with the scratch directory (WA-B.2) |

A figure without its TSV is not restylable and is not in the bundle. A table with no
script that produced it is not evidence, whatever it says.

The test is BS-3: `run.sh` runs end to end on a clean checkout given the hashed inputs.
Anything `run.sh` can regenerate does not need to be committed; anything it cannot must
be, or the bundle is not reproducible.

## Acceptance

A bundle is accepted when `checks/bundle_valid.sh results/<GATE-ID>` passes and
a human has opened INPUTS.tsv and recognised the inputs.

⚠️ **These are two different states, and conflating them put the operator back in the
critical path.** A bundle that reruns and reproduces is `REPRODUCIBLE`, and ARIS may
continue on it immediately — overnight, unattended. The human input audit is a separate
field that starts `PENDING`:

    bundle_status:     REPRODUCIBLE      <- machine, gates nothing downstream
    human_input_audit: PENDING | DONE    <- morning review

`human_input_audit: DONE` is required before a number is promoted to a paper or thesis
claim, and for nothing else. Recognising the inputs is not automatable; **blocking the
pipeline on it is not what makes it valuable.**
