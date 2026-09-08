# SESSION HYGIENE

## What actually affects performance

Old sessions sitting on disk do **not** degrade model quality. A session only
sees its own context window. Deleting six months of transcripts will not make
answers better.

Three things do degrade quality, in order of impact:

1. **Skill and MCP surface.** Every skill's name and description is loaded into
   every session. 61 symlinked skills of which ~8 are used is a standing tax on
   every prompt, paid forever. Unlink what you do not use.
2. **Long single sessions.** Quality falls after compaction, because the model
   is then working from a summary of a summary. One session per gate,
   ended when the gate is done, is the fix. If you have compacted twice, stop and
   start a fresh session from the committed state.
3. **CLAUDE.md and spec bloat.** Read-at-start files are paid on every turn.
   Master CLAUDE.md target: under 100 lines.

Two things affect *startup and disk*, not quality:

4. `~/.claude/projects/` grows with transcripts and can reach GBs.
5. `~/.claude.json` accumulates per-project entries, including orphans for
   directories that no longer exist.

## Retention

Claude Code deletes files older than `cleanupPeriodDays` (default 30) at
startup, covering `projects/<project>/<session>.jsonl`, `tool-results/`,
`file-history/`, `plans/`, `debug/`, `paste-cache/`, `image-cache/` and
`session-env/`; recent versions extended the sweep to `tasks/`,
`shell-snapshots/` and `backups/`.

Reference: https://code.claude.com/docs/en/claude-directory

**This deletes transcripts silently.** If a session contains reasoning you have
not yet promoted to a retro or a bundle, it is not backed up anywhere. That is
the argument for the discipline below, not for raising the retention period.

Set explicitly rather than relying on the default:

    // ~/.claude/settings.json
    { "cleanupPeriodDays": 45 }

## Weekly ritual - 5 minutes, Friday

1. Check the four numbers below by hand: transcript disk under `~/.claude/projects/`,
   the skill count, orphan entries in `~/.claude.json`, and `cleanupPeriodDays`.
   An installation that wants this scripted puts the script in its **site layer** —
   it reads `~/.claude`, which is a per-machine fact and so may not live here.
2. Promote anything worth keeping out of a session and into
   `retros/YYYY-MM-DD.md` or a bundle. Nothing else survives.
3. Delete `~/.claude/projects/` entries for directories that no longer exist.
4. Re-check the skill count. If it grew and you did not deliberately add one,
   something installed itself.

## Rules

SH-1  One session per gate. Close it when the gate closes.
SH-2  Two compactions in one session means stop, commit, start fresh.
SH-3  A session is not a record. If it is not in git, it did not happen.
SH-4  Skills are opt-in per project, never bulk-symlinked.
SH-5  Never `--resume` a session older than the current gate.
